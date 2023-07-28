# frozen_string_literal: true

RSpec.describe FLGen::SourceFile do
  let(:root_directory) do
    '/fizz/buzz'
  end

  let(:paths) do
    ['foo/bar.sv', 'foo/bar.sv.gz']
  end

  let(:path) do
    paths[0]
  end

  let(:file_content) do
    <<~'CODE'
      module foo;
      endmodule
    CODE
  end

  def create_soruce_file(root, path, checksum = nil)
    if checksum
      described_class.new(File.join(root, path), checksum)
    else
      described_class.new(File.join(root, path))
    end
  end

  def match_path(*path)
    if path.size == 1 && path[0].is_a?(described_class)
      eq(path[0].path)
    else
      eq(File.join(*path))
    end
  end

  describe '#path' do
    it '指定されたルートからのソースファイルのパスを返す' do
      source_file = create_soruce_file(root_directory, path)
      expect(source_file.path).to match_path(root_directory, path)
    end
  end

  describe '#==' do
    let(:file_contents) do
      contents = []
      contents << <<~'CODE'
        module foo;
        endmodule
      CODE
      contents << <<~'CODE'
        module bar;
        endmodule
      CODE
      contents
    end

    context '右辺がSourceFileオブジェクトの場合' do
      it '#pathまたは#checksumが一致するかを返す' do
        lhs = create_soruce_file(root_directory, path)
        rhs = create_soruce_file(root_directory, path)
        expect(lhs).to eq(rhs)

        lhs = create_soruce_file(root_directory, path)
        rhs = create_soruce_file('/', path)
        allow(File).to receive(:read).with(lhs.path).and_return(file_contents[0])
        allow(File).to receive(:read).with(rhs.path).and_return(file_contents[0])
        expect(lhs).to eq(rhs)

        lhs = create_soruce_file(root_directory, paths[0])
        rhs = create_soruce_file(root_directory, paths[1])
        allow(File).to receive(:read).with(lhs.path).and_return(file_contents[0])
        allow(File).to receive(:read).with(rhs.path).and_return(file_contents[1])
        expect(lhs).not_to eq(rhs)
      end
    end

    context '右辺が文字列の場合' do
      it '#pathと一致するかを返す' do
        lhs = create_soruce_file(root_directory, path)
        rhs = File.join(root_directory, path)
        expect(lhs).to eq(rhs)

        lhs = create_soruce_file(root_directory, paths[0])
        rhs = File.join(root_directory, paths[1])
        expect(lhs).not_to eq(rhs)
      end
    end
  end

  describe '#match_ext?' do
    let(:source_file) do
      create_soruce_file(root_directory, path)
    end

    context '検索対象の拡張子が未指定の場合' do
      it 'falseを返す' do
        expect(source_file.match_ext?(nil)).to be false
        expect(source_file.match_ext?([])).to be false
      end
    end

    context 'ソースファイルの拡張子が、指定された拡張子中に存在する場合' do
      it 'trueを返す' do
        expect(source_file.match_ext?(['sv'])).to be true
        expect(source_file.match_ext?(['.sv'])).to be true
        expect(source_file.match_ext?(['.v', 'sv'])).to be true
        expect(source_file.match_ext?(['v', '.sv'])).to be true
      end
    end

    context 'ソースファイルの拡張子が、指定された拡張子中に存在しない場合' do
      it 'falseを返す' do
        expect(source_file.match_ext?(['v'])).to be false
        expect(source_file.match_ext?(['.v'])).to be false
        expect(source_file.match_ext?(['.c', 'v'])).to be false
        expect(source_file.match_ext?(['c', '.v'])).to be false
      end
    end
  end

  describe '#remove_ext' do
    let(:source_file) do
      create_soruce_file(root_directory, paths[1])
    end

    context '削除対象の拡張子が未指定の場合' do
      it '元のパスを返す' do
        expect(source_file.remove_ext(nil).path).to match_path(source_file)
        expect(source_file.remove_ext([]).path).to match_path(source_file)
      end
    end

    context 'ソースファイルの拡張子が、削除対象の拡張子に含まれる場合' do
      before do
        allow(File).to receive(:read).with(source_file.path).and_return(file_content)
      end

      it '当該拡張子を削除したパスを返す' do
        expect(source_file.remove_ext(['gz']).path).to match_path(root_directory, path)
        expect(source_file.remove_ext(['.gz']).path).to match_path(root_directory, path)
        expect(source_file.remove_ext(['.bz2', 'gz']).path).to match_path(root_directory, path)
        expect(source_file.remove_ext(['bz2', '.gz']).path).to match_path(root_directory, path)
      end

      specify 'チェックサムは元のファイルのチェックサムを返す' do
        expect(source_file.remove_ext(['gz']).checksum) == source_file.checksum
      end
    end

    context 'ソースファイルの拡張子が、削除対象の拡張子に含まれない場合' do
      it '元のパスを返す' do
        expect(source_file.remove_ext(['bz2']).path).to match_path(source_file)
        expect(source_file.remove_ext(['.bz2']).path).to match_path(source_file)
        expect(source_file.remove_ext(['.zip', 'bz2']).path).to match_path(source_file)
        expect(source_file.remove_ext(['zip', '.bz2']).path).to match_path(source_file)
      end
    end
  end

  describe '#checksum' do
    let(:checksum) do
      Digest::MD5.digest(file_content)
    end

    it 'ソースファイルのチェックサムを求める' do
      source_file = create_soruce_file(root_directory, path)
      allow(File).to receive(:read).with(match_path(source_file)).and_return(file_content)
      expect(source_file.checksum).to eq checksum
    end

    context '生成時にチェックサムの指定がある場合' do
      it '指定されたチェックサムを返す' do
        source_file = create_soruce_file(root_directory, paths[1], checksum)
        expect(source_file.checksum).to eq checksum
      end
    end
  end
end
