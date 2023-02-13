# frozen_string_literal: true

RSpec.describe FLGen::FileList do
  let(:path) do
    '/foo/bar/baz/fizz/buzz/list.rb'
  end

  let(:directories) do
    Pathname
      .new(path).dirname
      .descend.map(&:to_s)
  end

  let(:root_directories) do
    [
      '/foo/bar',
      '/foo/bar/baz/fizz'
    ]
  end

  let(:non_root_directories) do
    directories - root_directories
  end

  let(:context) do
    double('context', loaded_file_lists: [], options: {}, macros: [])
  end

  before do
    [
      '/',
      '/foo',
      '/foo/bar',
      '/foo/bar/baz',
      '/foo/bar/baz/fizz',
      '/foo/bar/baz/fizz/buzz'
    ].each do |dir|
      git_dir = File.join(dir, '.git')
      return_value = root_directories.include?(dir)
      allow(File).to receive(:exist?).with(git_dir).and_return(return_value)
    end
  end

  before do
    allow(File).to receive(:realpath) { |path| path }
  end

  describe '#file_list' do
    let(:list_name) do
      'hoge/fuga.rb'
    end

    let(:file_list_content) do
      <<~'FILE_LIST'
        source_file 'piyo.sv'
      FILE_LIST
    end

    let(:source_file_name) do
      'piyo.sv'
    end

    def setup_expectation(list_path)
      new_list = double('file list')
      allow(File).to receive(:file?).with(list_path).and_return(true)
      allow(File).to receive(:read).with(list_path).and_return(file_list_content)

      expect(described_class).to receive(:new).with(equal(context), list_path).once.and_return(new_list)
      expect(new_list).to receive(:source_file).with(source_file_name)

      block_given? && yield(new_list)
    end

    it 'ルートディレクトリ中を検索し、指定されたファイルリストを読み出す' do
      file_list = described_class.new(context, path)
      list_paths = root_directories.map { |dir| File.join(dir, list_name) }

      setup_expectation(list_paths[0])
      file_list.file_list(list_name)

      setup_expectation(list_paths[1]) do
        allow(File).to receive(:file?).with(list_paths[0]).and_return(false)
      end
      file_list.file_list(list_name)
    end

    context '絶対パスで指定された場合' do
      it '指定されたファイルリストをそのまま読み出す' do
        file_list = described_class.new(context, '')
        list_path = File.join(root_directories[0], list_name)

        setup_expectation(list_path)
        file_list.file_list(list_path)
      end
    end

    context 'from: :rootが指定された場合' do
      it 'ルートディレクトリ中を検索し、指定されたファイルリストを読み出す' do
        file_list = described_class.new(context, path)
        list_paths = root_directories.map { |dir| File.join(dir, list_name) }

        setup_expectation(list_paths[0])
        file_list.file_list(list_name)

        setup_expectation(list_paths[1]) do
          allow(File).to receive(:file?).with(list_paths[0]).and_return(false)
        end
        file_list.file_list(list_name)
      end
    end

    context 'from: :local_rootが指定された場合' do
      it '直近のリポジトリルートから検索を行う' do
        file_list = described_class.new(context, path)
        list_path = File.join(root_directories.last, list_name)
        setup_expectation(list_path)
        file_list.file_list(list_name, from: :local_root)
      end
    end

    context 'from: :currentが指定された場合' do
      it '呼び出し元を起点として、指定されたファイルリストを読み出す' do
        file_list = described_class.new(context, path)
        list_path = File.join(__dir__, list_name)
        setup_expectation(list_path)
        file_list.file_list(list_name, from: :current)
      end
    end

    context 'base: でベースディレクトリが指定された場合' do
      it '指定されたファイルリストをベースディレクトリから読み出す' do
        base = non_root_directories.sample
        file_list = described_class.new(context, path)
        list_path = File.join(base, list_name)
        setup_expectation(list_path)
        file_list.file_list(list_name, base: base)
      end

      it 'fromオプションは無視する' do
        base = non_root_directories.sample
        from_option = [:root, :local_root, :current].sample
        file_list = described_class.new(context, path)
        list_path = File.join(base, list_name)
        setup_expectation(list_path)
        file_list.file_list(list_name, base: base, from: from_option)
      end
    end

    context '複数回同じファイルリストが指定された場合' do
      specify '２回目以降は読み込まない' do
        file_list = described_class.new(context, path)

        paths = [
          root_directories[0], __dir__
        ].map { |path| File.join(path, list_name) }

        setup_expectation(paths[0])
        file_list.file_list(list_name)
        file_list.file_list(list_name)

        setup_expectation(paths[1])
        file_list.file_list(list_name, from: :current)
        file_list.file_list(list_name, from: :current)

        expect(context.loaded_file_lists).to match(paths)
      end
    end

    context '指定したファイルリストが存在しない場合' do
      it 'LoadErrorを起こす' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |root|
          allow(File).to receive(:file?).with(File.join(root, list_name)).and_return(false)
        end

        expect {
          file_list.file_list(list_name)
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{list_name} @#{__FILE__}:#{__LINE__ - 1}"

        expect {
          file_list.file_list(list_name, from: :current)
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{list_name} @#{__FILE__}:#{__LINE__ - 1}"
      end
    end

    context '指定したファイルリストが存在せず、raise_error:falseが指定されている場合' do
      it 'エラーは起こさない' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |root|
          allow(File).to receive(:file?).with(File.join(root, list_name)).and_return(false)
        end

        expect {
          file_list.file_list(list_name, raise_error: false)
        }.not_to raise_error

        expect {
          file_list.file_list(list_name, from: :current, raise_error: false)
        }.not_to raise_error
      end
    end
  end

  describe '#source_file' do
    let(:source_file_name) do
      'piyo.sv'
    end

    it '呼び出し元を起点として、contextにソースファイルを追加する' do
      file_list = described_class.new(context, path)

      allow(File).to receive(:file?).with(File.join(__dir__, source_file_name)).and_return(true)
      expect(context).to receive(:add_source_file).with(__dir__, source_file_name)
      file_list.source_file(source_file_name)
    end

    context '絶対パスで指定された場合' do
      it '指定されたソースファイルをcontextにそのまま追加する' do
        file_list = described_class.new(context, '')
        path = File.join(__dir__, source_file_name)

        allow(File).to receive(:file?).with(path).and_return(true)
        expect(context).to receive(:add_source_file).with('', path)
        file_list.source_file(path)
      end
    end

    context 'from: :rootが指定された場合' do
      it 'ルートディレクトリ中を検索し、contextにソースファイルを追加する' do
        file_list = described_class.new(context, path)
        file_paths = root_directories.map { |root| File.join(root, source_file_name) }

        allow(File).to receive(:file?).with(file_paths[0]).and_return(true)
        expect(context).to receive(:add_source_file).with(root_directories[0], source_file_name)
        file_list.source_file(source_file_name, from: :root)

        allow(File).to receive(:file?).with(file_paths[0]).and_return(false)
        allow(File).to receive(:file?).with(file_paths[1]).and_return(true)
        expect(context).to receive(:add_source_file).with(root_directories[1], source_file_name)
        file_list.source_file(source_file_name, from: :root)
      end
    end

    context 'from: :local_rootが指定された場合' do
      it '直近のリポジトリルートから検索を行う' do
        file_path = File.join(root_directories.last, source_file_name)
        file_list = described_class.new(context, path)

        allow(File).to receive(:file?).with(file_path).and_return(true)
        expect(context).to receive(:add_source_file).with(root_directories.last, source_file_name)
        file_list.source_file(source_file_name, from: :local_root)
      end
    end

    context 'from: currentが指定された場合' do
      it '呼び出し元を起点として、contextにソースファイルを追加する' do
        file_list = described_class.new(context, path)

        allow(File).to receive(:file?).with(File.join(__dir__, source_file_name)).and_return(true)
        expect(context).to receive(:add_source_file).with(__dir__, source_file_name)
        file_list.source_file(source_file_name, from: :current)
      end
    end

    context 'baseでベースディレクトリが指定された場合' do
      it '指定されたベースディレクトリから、contextにソースファイルを追加する' do
        file_list = described_class.new(context, path)

        base = non_root_directories.sample
        allow(File).to receive(:file?).with(File.join(base, source_file_name)).and_return(true)
        expect(context).to receive(:add_source_file).with(base, source_file_name)
        file_list.source_file(source_file_name, base: base)
      end

      it 'fromオプションは無視する' do
        file_list = described_class.new(context, path)

        base = non_root_directories.sample
        from_option = [:root, :local_root, :current].sample
        allow(File).to receive(:file?).with(File.join(base, source_file_name)).and_return(true)
        expect(context).to receive(:add_source_file).with(base, source_file_name)
        file_list.source_file(source_file_name, base: base, from: from_option)
      end
    end

    context '指定したソースファイルが存在しない場合' do
      it 'LoadErrorを起こす' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |root|
          allow(File).to receive(:file?).with(File.join(root, source_file_name)).and_return(false)
        end

        expect {
          file_list.source_file(source_file_name)
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{source_file_name} @#{__FILE__}:#{__LINE__ - 1}"

        expect {
          file_list.source_file(source_file_name, from: :root)
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{source_file_name} @#{__FILE__}:#{__LINE__ - 1}"
      end
    end

    context '指定したソースファイルが存在せず、raise_error:falseが指定されている場合' do
      it 'エラーを起こさない' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |root|
          allow(File).to receive(:file?).with(File.join(root, source_file_name)).and_return(false)
        end

        expect {
          file_list.source_file(source_file_name, raise_error: false)
        }.not_to raise_error

        expect {
          file_list.source_file(source_file_name, from: :root, raise_error: false)
        }.not_to raise_error
      end
    end
  end

  describe '#library_file' do
    let(:library_file_name) do
      'piyo.sv'
    end

    it '呼び出し元を起点に、contextにライブラリファイルを追加する' do
      file_list = described_class.new(context, path)

      allow(File).to receive(:file?).with(File.join(__dir__, library_file_name)).and_return(true)
      expect(context).to receive(:add_library_file).with(__dir__, library_file_name)
      file_list.library_file(library_file_name)
    end

    context '絶対パスで指定された場合' do
      it '指定されたライブラリファイルをcontextにそのまま追加する' do
        file_list = described_class.new(context, '')
        file_path = File.join(__dir__, library_file_name)

        allow(File).to receive(:file?).with(file_path).and_return(true)
        expect(context).to receive(:add_library_file).with('', file_path)
        file_list.library_file(file_path)
      end
    end

    context 'from: :rootが指定された場合' do
      it 'ルートディレクトリ中を検索し、contextにライブラリファイルを追加する' do
        file_list = described_class.new(context, path)
        file_paths = root_directories.map { |root| File.join(root, library_file_name) }

        allow(File).to receive(:file?).with(file_paths[0]).and_return(true)
        expect(context).to receive(:add_library_file).with(root_directories[0], library_file_name)
        file_list.library_file(library_file_name, from: :root)

        allow(File).to receive(:file?).with(file_paths[0]).and_return(false)
        allow(File).to receive(:file?).with(file_paths[1]).and_return(true)
        expect(context).to receive(:add_library_file).with(root_directories[1], library_file_name)
        file_list.library_file(library_file_name, from: :root)
      end
    end

    context 'from: :local_rootが指定された場合' do
      it '直近のリポジトリルートから検索を行う' do
        file_path = File.join(root_directories.last, library_file_name)
        file_list = described_class.new(context, path)

        allow(File).to receive(:file?).with(file_path).and_return(true)
        expect(context).to receive(:add_library_file).with(root_directories.last, library_file_name)
        file_list.library_file(library_file_name, from: :local_root)
      end
    end

    context 'from: currentが指定された場合' do
      it '呼び出し元を起点として、contextにライブラリファイルを追加する' do
        file_list = described_class.new(context, path)

        allow(File).to receive(:file?).with(File.join(__dir__, library_file_name)).and_return(true)
        expect(context).to receive(:add_library_file).with(__dir__, library_file_name)
        file_list.library_file(library_file_name, from: :current)
      end
    end

    context 'baseでベースディレクトリが指定された場合' do
      it '指定されたベースディレクトリから、contextにライブラリファイルを追加する' do
        file_list = described_class.new(context, path)

        base = non_root_directories.sample
        allow(File).to receive(:file?).with(File.join(base, library_file_name)).and_return(true)
        expect(context).to receive(:add_library_file).with(base, library_file_name)
        file_list.library_file(library_file_name, base: base)
      end

      it 'fromオプションは無視する' do
        file_list = described_class.new(context, path)

        base = non_root_directories.sample
        from_option = [:root, :local_root, :current].sample
        allow(File).to receive(:file?).with(File.join(base, library_file_name)).and_return(true)
        expect(context).to receive(:add_library_file).with(base, library_file_name)
        file_list.library_file(library_file_name, base: base, from: from_option)
      end
    end

    context '指定したライブラリファイルが存在しない場合' do
      it 'LoadErrorを起こす' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |root|
          allow(File).to receive(:file?).with(File.join(root, library_file_name)).and_return(false)
        end

        expect {
          file_list.library_file(library_file_name)
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{library_file_name} @#{__FILE__}:#{__LINE__ - 1}"

        expect {
          file_list.library_file(library_file_name, from: :root)
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{library_file_name} @#{__FILE__}:#{__LINE__ - 1}"
      end
    end

    context '指定したライブラリファイルが存在せず、raise_error:falseが指定されている場合' do
      it 'エラーを起こさない' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |root|
          allow(File).to receive(:file?).with(File.join(root, library_file_name)).and_return(false)
        end

        expect {
          file_list.library_file(library_file_name, raise_error: false)
        }.not_to raise_error

        expect {
          file_list.library_file(library_file_name, from: :root, raise_error: false)
        }.not_to raise_error
      end
    end
  end

  describe '#define_macro' do
    it 'マクロを定義する' do
      file_list = described_class.new(context, path)

      expect(context).to receive(:define_macro).with(:FOO, nil)
      expect(context).to receive(:define_macro).with(:BAR, 1)

      file_list.define_macro(:FOO)
      file_list.define_macro(:BAR, 1)
    end
  end

  describe '#macro?/#macro_defined?' do
    let(:macros) do
      [:FOO, :BAR]
    end

    it '定義済みマクロかどうかを示す' do
      file_list = described_class.new(context, path)
      context.macros << macros[0]
      context.macros << macros[1]

      expect(file_list.macro?(:FOO)).to be true
      expect(file_list.macro?('FOO')).to be true
      expect(file_list.macro?(:BAR)).to be true
      expect(file_list.macro?('BAR')).to be true
      expect(file_list.macro?(:BAZ)).to be false
      expect(file_list.macro?('BAZ')).to be false

      expect(file_list.macro_defined?(:FOO)).to be true
      expect(file_list.macro_defined?('FOO')).to be true
      expect(file_list.macro_defined?(:BAR)).to be true
      expect(file_list.macro_defined?('BAR')).to be true
      expect(file_list.macro_defined?(:BAZ)).to be false
      expect(file_list.macro_defined?('BAZ')).to be false
    end
  end

  describe '#include_directory' do
    let(:include_directories) do
      ['foo', 'bar/baz']
    end

    it '呼び出し元を起点に、指定されたディレクトリをcontextに追加する' do
      file_list = described_class.new(context, path)
      directory_paths = include_directories.map { |dir| File.join(__dir__, dir) }

      allow(File).to receive(:directory?).with(File.join(directory_paths[0])).and_return(true)
      allow(File).to receive(:directory?).with(File.join(directory_paths[1])).and_return(true)

      expect(context).to receive(:add_include_directory).with(directory_paths[0])
      expect(context).to receive(:add_include_directory).with(directory_paths[1])

      file_list.include_directory(include_directories[0])
      file_list.include_directory(include_directories[1])
    end

    context '絶対パスで指定された場合' do
      it '指定されたディレクトリを、そのままcontexに追加する' do
        file_list = described_class.new(context, path)
        directory_paths = include_directories.map { |dir| File.join('/', dir) }

        allow(File).to receive(:directory?).with(File.join(directory_paths[0])).and_return(true)
        allow(File).to receive(:directory?).with(File.join(directory_paths[1])).and_return(true)

        expect(context).to receive(:add_include_directory).with(directory_paths[0])
        expect(context).to receive(:add_include_directory).with(directory_paths[1])

        file_list.include_directory(directory_paths[0])
        file_list.include_directory(directory_paths[1])
      end
    end

    context 'from: :rootが指定された場合' do
      it 'ルートディレクトリ中を検索し、contextに指定されたディレクトリを追加する' do
        file_list = described_class.new(context, path)

        directory_paths = [
          File.join(root_directories[0], include_directories[0]),
          File.join(root_directories[0], include_directories[1]),
          File.join(root_directories[1], include_directories[1])
        ]

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(false)
        allow(File).to receive(:directory?).with(directory_paths[2]).and_return(true)

        expect(context).to receive(:add_include_directory).with(directory_paths[0])
        expect(context).to receive(:add_include_directory).with(directory_paths[2])

        file_list.include_directory(include_directories[0], from: :root)
        file_list.include_directory(include_directories[1], from: :root)
      end
    end

    context 'from: :local_rootが指定された場合' do
      it '直近のリポジトリルートから検索を行う' do
        file_list = described_class.new(context, path)
        directory_paths = include_directories.map { |dir| File.join(root_directories.last, dir) }

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(true)

        expect(context).to receive(:add_include_directory).with(directory_paths[0])
        expect(context).to receive(:add_include_directory).with(directory_paths[1])

        file_list.include_directory(include_directories[0], from: :local_root)
        file_list.include_directory(include_directories[1], from: :local_root)
      end
    end

    context 'from: :currentが指定された場合' do
      it '呼び出し元を起点に、指定されたディレクトリをcontextに追加する' do
        file_list = described_class.new(context, path)
        directory_paths = include_directories.map { |dir| File.join(__dir__, dir) }

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(true)

        expect(context).to receive(:add_include_directory).with(directory_paths[0])
        expect(context).to receive(:add_include_directory).with(directory_paths[1])

        file_list.include_directory(include_directories[0], from: :current)
        file_list.include_directory(include_directories[1], from: :current)
      end
    end

    context 'baseでベースディレクトリが指定された場合' do
      it 'ベースディレクトリから、指定されたディレクトリをcontextに追加する' do
        file_list = described_class.new(context, path)
        base = non_root_directories.sample
        directory_paths = include_directories.map { |dir| File.join(base, dir) }

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(true)

        expect(context).to receive(:add_include_directory).with(directory_paths[0])
        expect(context).to receive(:add_include_directory).with(directory_paths[1])

        file_list.include_directory(include_directories[0], base: base)
        file_list.include_directory(include_directories[1], base: base)
      end

      it 'fromオプションは無視する' do
        file_list = described_class.new(context, path)
        base = non_root_directories.sample
        directory_paths = include_directories.map { |dir| File.join(base, dir) }

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(true)

        expect(context).to receive(:add_include_directory).with(directory_paths[0])
        expect(context).to receive(:add_include_directory).with(directory_paths[1])

        from_option = [:root, :local_root, :current].sample
        file_list.include_directory(include_directories[0], base: base, from: from_option)

        from_option = [:root, :local_root, :current].sample
        file_list.include_directory(include_directories[1], base: base, from: from_option)
      end
    end

    context '指定したディレクトリが存在しない場合' do
      it 'NoEntryErrorを起こす' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |dir|
          allow(File).to receive(:directory?).with(File.join(dir, include_directories[0])).and_return(false)
        end

        expect {
          file_list.include_directory(include_directories[0])
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{include_directories[0]} @#{__FILE__}:#{__LINE__ - 1}"

        expect {
          file_list.include_directory(include_directories[0], from: :root)
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{include_directories[0]} @#{__FILE__}:#{__LINE__ - 1}"
      end
    end

    context '指定したディレクトリが存在せず、raise_error:f  alseが指定されている場合' do
      it 'エラーを起こさない' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |dir|
          allow(File).to receive(:directory?).with(File.join(dir, include_directories[0])).and_return(false)
        end

        expect {
          file_list.include_directory(include_directories[0], raise_error: false)
        }.not_to raise_error

        expect {
          file_list.include_directory(include_directories[0], from: :root, raise_error: false)
        }.not_to raise_error
      end
    end
  end

  describe '#library_directory' do
    let(:library_directories) do
      ['foo', 'bar/baz']
    end

    it '呼び出し元を起点に、指定されたディレクトリをcontextに追加する' do
      file_list = described_class.new(context, path)
      directory_paths = library_directories.map { |dir| File.join(__dir__, dir) }

      allow(File).to receive(:directory?).with(File.join(directory_paths[0])).and_return(true)
      allow(File).to receive(:directory?).with(File.join(directory_paths[1])).and_return(true)

      expect(context).to receive(:add_library_directory).with(directory_paths[0])
      expect(context).to receive(:add_library_directory).with(directory_paths[1])

      file_list.library_directory(library_directories[0])
      file_list.library_directory(library_directories[1])
    end

    context '絶対パスで指定された場合' do
      it '指定されたディレクトリを、そのままcontexに追加する' do
        file_list = described_class.new(context, path)
        directory_paths = library_directories.map { |dir| File.join('/', dir) }

        allow(File).to receive(:directory?).with(File.join(directory_paths[0])).and_return(true)
        allow(File).to receive(:directory?).with(File.join(directory_paths[1])).and_return(true)

        expect(context).to receive(:add_library_directory).with(directory_paths[0])
        expect(context).to receive(:add_library_directory).with(directory_paths[1])

        file_list.library_directory(directory_paths[0])
        file_list.library_directory(directory_paths[1])
      end
    end

    context 'from: :rootが指定された場合' do
      it 'ルートディレクトリ中を検索し、contextに指定されたディレクトリを追加する' do
        file_list = described_class.new(context, path)

        directory_paths = [
          File.join(root_directories[0], library_directories[0]),
          File.join(root_directories[0], library_directories[1]),
          File.join(root_directories[1], library_directories[1])
        ]

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(false)
        allow(File).to receive(:directory?).with(directory_paths[2]).and_return(true)

        expect(context).to receive(:add_library_directory).with(directory_paths[0])
        expect(context).to receive(:add_library_directory).with(directory_paths[2])

        file_list.library_directory(library_directories[0], from: :root)
        file_list.library_directory(library_directories[1], from: :root)
      end
    end

    context 'from: :local_rootが指定された場合' do
      it '直近のリポジトリルートから検索を行う' do
        file_list = described_class.new(context, path)
        directory_paths = library_directories.map { |dir| File.join(root_directories.last, dir) }

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(true)

        expect(context).to receive(:add_library_directory).with(directory_paths[0])
        expect(context).to receive(:add_library_directory).with(directory_paths[1])

        file_list.library_directory(library_directories[0], from: :local_root)
        file_list.library_directory(library_directories[1], from: :local_root)
      end
    end

    context 'from: :currentが指定された場合' do
      it '呼び出し元を起点に、指定されたディレクトリをcontextに追加する' do
        file_list = described_class.new(context, path)
        directory_paths = library_directories.map { |dir| File.join(__dir__, dir) }

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(true)

        expect(context).to receive(:add_library_directory).with(directory_paths[0])
        expect(context).to receive(:add_library_directory).with(directory_paths[1])

        file_list.library_directory(library_directories[0], from: :current)
        file_list.library_directory(library_directories[1], from: :current)
      end
    end

    context 'baseでベースディレクトリが指定された場合' do
      it 'ベースディレクトリから、指定されたディレクトリをcontextに追加する' do
        file_list = described_class.new(context, path)
        base = non_root_directories.sample
        directory_paths = library_directories.map { |dir| File.join(base, dir) }

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(true)

        expect(context).to receive(:add_library_directory).with(directory_paths[0])
        expect(context).to receive(:add_library_directory).with(directory_paths[1])

        file_list.library_directory(library_directories[0], base: base)
        file_list.library_directory(library_directories[1], base: base)
      end

      it 'fromオプションは無視する' do
        file_list = described_class.new(context, path)
        base = non_root_directories.sample
        directory_paths = library_directories.map { |dir| File.join(base, dir) }

        allow(File).to receive(:directory?).with(directory_paths[0]).and_return(true)
        allow(File).to receive(:directory?).with(directory_paths[1]).and_return(true)

        expect(context).to receive(:add_library_directory).with(directory_paths[0])
        expect(context).to receive(:add_library_directory).with(directory_paths[1])

        from_option = [:root, :local_root, :current].sample
        file_list.library_directory(library_directories[0], base: base, from: from_option)

        from_option = [:root, :local_root, :current].sample
        file_list.library_directory(library_directories[1], base: base, from: from_option)
      end
    end

    context '指定したディレクトリが存在しない場合' do
      it 'NoEntryErrorを起こす' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |dir|
          allow(File).to receive(:directory?).with(File.join(dir, library_directories[0])).and_return(false)
        end

        expect {
          file_list.library_directory(library_directories[0])
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{library_directories[0]} @#{__FILE__}:#{__LINE__ - 1}"

        expect {
          file_list.library_directory(library_directories[0], from: :root)
        }.to raise_error FLGen::NoEntryError, "no such file or directory -- #{library_directories[0]} @#{__FILE__}:#{__LINE__ - 1}"
      end
    end

    context '指定したディレクトリが存在せず、raise_error:f  alseが指定されている場合' do
      it 'エラーを起こさない' do
        file_list = described_class.new(context, path)
        [*root_directories, __dir__].each do |dir|
          allow(File).to receive(:directory?).with(File.join(dir, library_directories[0])).and_return(false)
        end

        expect {
          file_list.library_directory(library_directories[0], raise_error: false)
        }.not_to raise_error

        expect {
          file_list.library_directory(library_directories[0], from: :root, raise_error: false)
        }.not_to raise_error
      end
    end
  end

  describe '#file?' do
    let(:file_names) do
      ['foo.sv', 'bar.sv', 'baz.sv']
    end

    it '呼び出し元を起点として、指定されたファイルの有無を返す' do
      file_list = described_class.new(context, path)

      allow(File).to receive(:file?).with(File.join(__dir__, file_names[0])).and_return(true)
      expect(file_list.file?(file_names[0])).to eq true

      allow(File).to receive(:file?).with(File.join(__dir__, file_names[1])).and_return(false)
      expect(file_list.file?(file_names[1])).to eq false
    end

    context '絶対パスで指定された場合' do
      it '指定されたファイルの有無を返す' do
        file_list = described_class.new(context, path)

        path = File.join(__dir__, file_names[0])
        allow(File).to receive(:file?).with(path).and_return(true)
        expect(file_list.file?(path)).to eq true

        path = File.join(__dir__, file_names[1])
        allow(File).to receive(:file?).with(path).and_return(false)
        expect(file_list.file?(path)).to eq false
      end
    end

    context 'from: :rootが指定された場合' do
      it 'ルートディレクトリを起点として、指定されたファイルの有無を返す' do
        file_list = described_class.new(context, path)

        allow(File).to receive(:file?).with(File.join(root_directories[0], file_names[0])).and_return(true)
        expect(file_list.file?(file_names[0], from: :root)).to eq true

        allow(File).to receive(:file?).with(File.join(root_directories[0], file_names[1])).and_return(false)
        allow(File).to receive(:file?).with(File.join(root_directories[1], file_names[1])).and_return(true)
        expect(file_list.file?(file_names[1], from: :root)).to eq true

        allow(File).to receive(:file?).with(File.join(root_directories[0], file_names[2])).and_return(false)
        allow(File).to receive(:file?).with(File.join(root_directories[1], file_names[2])).and_return(false)
        expect(file_list.file?(file_names[2], from: :root)).to eq false
      end
    end

    context 'from: :local_rootが指定された場合' do
      it '直近のルートディレクトリを起点として、指定されたファイルの有無を返す' do
        file_list = described_class.new(context, path)

        allow(File).to receive(:file?).with(File.join(root_directories.last, file_names[0])).and_return(true)
        expect(file_list.file?(file_names[0], from: :local_root)).to eq true

        allow(File).to receive(:file?).with(File.join(root_directories.last, file_names[1])).and_return(false)
        expect(file_list.file?(file_names[1], from: :local_root)).to eq false
      end
    end

    context 'from: :currentが指定された場合' do
      it '呼び出し元を起点として、指定されたファイルの有無を返す' do
        file_list = described_class.new(context, path)

        allow(File).to receive(:file?).with(File.join(__dir__, file_names[0])).and_return(true)
        expect(file_list.file?(file_names[0], from: :current)).to eq true

        allow(File).to receive(:file?).with(File.join(__dir__, file_names[1])).and_return(false)
        expect(file_list.file?(file_names[1], from: :current)).to eq false
      end
    end

    context 'baseでベースディレクトリが指定された場合' do
      it 'ベースディレクトリを起点として、指定されたファイルの有無を返す' do
        file_list = described_class.new(context, path)
        base = non_root_directories.sample

        allow(File).to receive(:file?).with(File.join(base, file_names[0])).and_return(true)
        expect(file_list.file?(file_names[0], base: base)).to eq true

        allow(File).to receive(:file?).with(File.join(base, file_names[1])).and_return(false)
        expect(file_list.file?(file_names[1], base: base)).to eq false
      end

      it 'fromオプションは無視する' do
        file_list = described_class.new(context, path)
        base = non_root_directories.sample
        from_option = [:root, :local_root, :current]

        allow(File).to receive(:file?).with(File.join(base, file_names[0])).and_return(true)
        expect(file_list.file?(file_names[0], base: base, from: from_option)).to eq true

        allow(File).to receive(:file?).with(File.join(base, file_names[1])).and_return(false)
        expect(file_list.file?(file_names[1], base: base, from: from_option)).to eq false
      end
    end
  end

  describe '#directory?' do
    let(:directory_names) do
      ['foo', 'bar/baz', 'qux']
    end

    it '呼び出し元を起点として、指定されたディレクトリの有無を返す' do
      file_list = described_class.new(context, path)

      allow(File).to receive(:directory?).with(File.join(__dir__, directory_names[0])).and_return(true)
      expect(file_list.directory?(directory_names[0])).to eq true

      allow(File).to receive(:directory?).with(File.join(__dir__, directory_names[1])).and_return(false)
      expect(file_list.directory?(directory_names[1])).to eq false
    end

    context '絶対パスで指定された場合' do
      it '指定されたディレクトリ有無を返す' do
        file_list = described_class.new(context, path)

        path = File.join(__dir__, directory_names[0])
        allow(File).to receive(:directory?).with(path).and_return(true)
        expect(file_list.directory?(path)).to eq true

        path = File.join(__dir__, directory_names[1])
        allow(File).to receive(:directory?).with(path).and_return(false)
        expect(file_list.directory?(path)).to eq false
      end
    end

    context 'from: :rootが指定された場合' do
      it 'ルートディレクトリを起点として、指定されたディレクトリの有無を返す' do
        file_list = described_class.new(context, path)

        allow(File).to receive(:directory?).with(File.join(root_directories[0], directory_names[0])).and_return(true)
        expect(file_list.directory?(directory_names[0], from: :root)).to eq true

        allow(File).to receive(:directory?).with(File.join(root_directories[0], directory_names[1])).and_return(false)
        allow(File).to receive(:directory?).with(File.join(root_directories[1], directory_names[1])).and_return(true)
        expect(file_list.directory?(directory_names[1], from: :root)).to eq true

        allow(File).to receive(:directory?).with(File.join(root_directories[0], directory_names[2])).and_return(false)
        allow(File).to receive(:directory?).with(File.join(root_directories[1], directory_names[2])).and_return(false)
        expect(file_list.directory?(directory_names[2], from: :root)).to eq false
      end
    end

    context 'from: :local_rootが指定された場合' do
      it '直近のルートディレクトリを起点として、指定されたディレクトリの有無を返す' do
        file_list = described_class.new(context, path)

        allow(File).to receive(:directory?).with(File.join(root_directories.last, directory_names[0])).and_return(true)
        expect(file_list.directory?(directory_names[0], from: :local_root)).to eq true

        allow(File).to receive(:directory?).with(File.join(root_directories.last, directory_names[1])).and_return(false)
        expect(file_list.directory?(directory_names[1], from: :local_root)).to eq false
      end
    end

    context 'from: :currentが指定された場合' do
      it '呼び出し元を起点として、指定されたディレクトリの有無を返す' do
        file_list = described_class.new(context, path)

        allow(File).to receive(:directory?).with(File.join(__dir__, directory_names[0])).and_return(true)
        expect(file_list.directory?(directory_names[0], from: :current)).to eq true

        allow(File).to receive(:directory?).with(File.join(__dir__, directory_names[1])).and_return(false)
        expect(file_list.directory?(directory_names[1], from: :current)).to eq false
      end
    end

    context 'baseでベースディレクトリが指定された場合' do
      it 'ベースディレクトリを起点として、指定されたディレクトリの有無を返す' do
        file_list = described_class.new(context, path)
        base = non_root_directories.sample

        allow(File).to receive(:directory?).with(File.join(base, directory_names[0])).and_return(true)
        expect(file_list.directory?(directory_names[0], base: base)).to eq true

        allow(File).to receive(:directory?).with(File.join(base, directory_names[1])).and_return(false)
        expect(file_list.directory?(directory_names[1], base: base)).to eq false
      end

      it 'fromオプションは無視する' do
        file_list = described_class.new(context, path)
        base = non_root_directories.sample
        from_option = [:root, :local_root, :current]

        allow(File).to receive(:directory?).with(File.join(base, directory_names[0])).and_return(true)
        expect(file_list.directory?(directory_names[0], base: base, from: from_option)).to eq true

        allow(File).to receive(:directory?).with(File.join(base, directory_names[1])).and_return(false)
        expect(file_list.directory?(directory_names[1], base: base, from: from_option)).to eq false
      end
    end
  end

  describe '#env?' do
    it '指定された環境変数が定義されているかを返す' do
      file_list = described_class.new(context, path)

      expect(file_list.env?('FOO')).to eq false
      expect(file_list.env?(:FOO)).to eq false

      ENV['FOO'] = 'FOO'
      expect(file_list.env?('FOO')).to eq true
      expect(file_list.env?(:FOO)).to eq true
    end
  end

  describe '#env' do
    it '指定された環境変数の値を取り出す' do
      file_list = described_class.new(context, path)
      ENV['FOO'] = 'FOO'

      expect(file_list.env('FOO')).to eq 'FOO'
      expect(file_list.env(:FOO)).to eq 'FOO'

      expect(file_list.env('BAR')).to be_nil
      expect(file_list.env(:BAR)).to be_nil
    end
  end

  describe '#target_tool?' do
    context '対象ツールの指定がない場合' do
      it 'falseを返す' do
        file_list = described_class.new(context, path)
        expect(file_list.target_tool?(:vcs)).to be false
        expect(file_list.target_tool?(:xcelium)).to be false
      end
    end

    context '対象ツールの指定がある場合' do
      it '比較結果を返す' do
        file_list = described_class.new(context, path)

        context.options[:tool] = :vcs
        expect(file_list.target_tool?(:vcs)).to be true
        expect(file_list.target_tool?(:xcelium)).to be false

        context.options[:tool] = :xcelium
        expect(file_list.target_tool?(:vcs)).to be false
        expect(file_list.target_tool?(:xcelium)).to be true
      end
    end
  end

  describe '#compile_argument' do
    it 'contextにコンパイル引数を追加する' do
      file_list = described_class.new(context, path)

      expect(context).to receive(:add_compile_argument).with(have_attributes(type: :generic, argument: '-foo', tool: nil))
      expect(context).to receive(:add_compile_argument).with(have_attributes(type: :generic, argument: '-bar=1', tool: nil))
      expect(context).to receive(:add_compile_argument).with(have_attributes(type: :generic, argument: '-fizz', tool: :vcs))
      expect(context).to receive(:add_compile_argument).with(have_attributes(type: :generic, argument: '-bazz=2', tool: :xcelium))

      file_list.compile_argument('-foo')
      file_list.compile_argument('-bar=1')
      file_list.compile_argument('-fizz', tool: :vcs)
      file_list.compile_argument('-bazz=2', tool: :xcelium)
    end
  end

  describe '#runtime_argument' do
    it 'contextに実行時引数を追加する' do
      file_list = described_class.new(context, path)

      expect(context).to receive(:add_runtime_argument).with(have_attributes(type: :generic, argument: '-foo', tool: nil))
      expect(context).to receive(:add_runtime_argument).with(have_attributes(type: :generic, argument: '-bar=1', tool: nil))
      expect(context).to receive(:add_runtime_argument).with(have_attributes(type: :generic, argument: '-fizz', tool: :vcs))
      expect(context).to receive(:add_runtime_argument).with(have_attributes(type: :generic, argument: '-bazz=2', tool: :xcelium))

      file_list.runtime_argument('-foo')
      file_list.runtime_argument('-bar=1')
      file_list.runtime_argument('-fizz', tool: :vcs)
      file_list.runtime_argument('-bazz=2', tool: :xcelium)
    end
  end
end
