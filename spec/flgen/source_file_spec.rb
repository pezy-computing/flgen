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

  def create_soruce_file(root, path)
    described_class.new(root, path)
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
      it '当該拡張子を削除したパスを返す' do
        expect(source_file.remove_ext(['gz']).path).to match_path(root_directory, path)
        expect(source_file.remove_ext(['.gz']).path).to match_path(root_directory, path)
        expect(source_file.remove_ext(['.bz2', 'gz']).path).to match_path(root_directory, path)
        expect(source_file.remove_ext(['bz2', '.gz']).path).to match_path(root_directory, path)
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
    let(:file_content) do
      <<~'CODE'
        module foo;
        endmodule
      CODE
    end

    let(:checksum) do
      Digest::MD5.digest(file_content)
    end

    let(:source_file) do
      create_soruce_file(root_directory, path)
    end

    it 'ソースファイルのチェックサムを求める' do
      allow(File).to receive(:read).with(match_path(source_file)).and_return(file_content)
      expect(source_file.checksum).to eq checksum
    end
  end
end
