# frozen_string_literal: true

RSpec.describe FLGen::Context do
  let(:options) do
    {}
  end

  let(:context) do
    described_class.new(options)
  end

  def match_source_file(path)
    have_attributes(path: path)
  end

  def match_argument(type, **attributes)
    have_attributes(type: type, **attributes)
  end

  describe '#add_source_file' do
    let(:file_contents) do
      contents = []
      contents << <<~'CODE'
        module hoge;
        endmodule
      CODE
      contents << <<~'CODE'
        module fuga;
        endmodule
      CODE
      contents << <<~'CODE'
        module piyo;
        endmodule
      CODE
      contents
    end

    it '指定したソースファイルを追加する' do
      allow(File).to receive(:read).with('/foo/bar/hoge.sv').and_return(file_contents[0])
      allow(File).to receive(:read).with('/baz/qux/fuga.sv').and_return(file_contents[1])

      context.add_source_file('/foo/bar/hoge.sv')
      context.add_source_file('/baz/qux/fuga.sv')

      expect(context.source_files).to match([
        match_source_file('/foo/bar/hoge.sv'),
        match_source_file('/baz/qux/fuga.sv')
      ])
    end

    context 'options[:runtime]がtrueの場合' do
      specify 'ソースファイルの追加は行わない' do
        options[:runtime] = true

        expect {
          context.add_source_file('/foo/bar/hoge.sv')
          context.add_source_file('/baz/qux/fuga.sv')
        }.not_to change { context.source_files.size }
      end
    end

    context 'options[:collect_ext]が指定されている場合' do
      it '指定した拡張子を持つファイルだけを追加する' do
        options[:collect_ext] = ['gz', 'bz2']

        allow(File).to receive(:read).with('/foo/bar/hoge.sv.gz').and_return(file_contents[0])
        allow(File).to receive(:read).with('/foo/bar/fuga.sv.bz2').and_return(file_contents[1])

        context.add_source_file('/foo/bar/hoge.sv.gz')
        context.add_source_file('/foo/bar/hoge.sv')
        context.add_source_file('/foo/bar/fuga.sv.bz2')
        context.add_source_file('/foo/bar/fuga.sv')

        expect(context.source_files).to match([
          match_source_file('/foo/bar/hoge.sv.gz'),
          match_source_file('/foo/bar/fuga.sv.bz2')
        ])
      end
    end

    context 'options[:rm_ext]が指定されている場合' do
      it '指定された拡張子を削除して、追加する' do
        options[:rm_ext] = ['gz', 'bz2']

        allow(File).to receive(:read).with('/foo/bar/hoge.sv.gz').and_return(file_contents[0])
        allow(File).to receive(:read).with('/foo/bar/fuga.sv.bz2').and_return(file_contents[1])
        allow(File).to receive(:read).with('/foo/bar/piyo.sv').and_return(file_contents[2])

        context.add_source_file('/foo/bar/hoge.sv.gz')
        context.add_source_file('/foo/bar/fuga.sv.bz2')
        context.add_source_file('/foo/bar/piyo.sv')

        expect(context.source_files).to match([
          match_source_file('/foo/bar/hoge.sv'),
          match_source_file('/foo/bar/fuga.sv'),
          match_source_file('/foo/bar/piyo.sv')
        ])
      end
    end

    context '同一のファイルが既に追加されている場合' do
      it '当該ファイルは追加しない' do
        allow(File).to receive(:read).with('/foo/bar/fizz/buzz/hoge.sv').and_return(file_contents[0])
        allow(File).to receive(:read).with('/foo/bar/fizz/buzz/fuga.sv').and_return(file_contents[1])
        allow(File).to receive(:read).with('/baz/qux/fizz/buzz/hoge.sv').and_return(file_contents[0])
        allow(File).to receive(:read).with('/baz/qux/fizz/buzz/fuga.sv').and_return(file_contents[2])
        allow(File).to receive(:read).with('/foo/bar/fizz/buzz/hoge.sv').and_return(file_contents[0])

        context.add_source_file('/foo/bar/fizz/buzz/hoge.sv')
        context.add_source_file('/foo/bar/fizz/buzz/fuga.sv')
        context.add_source_file('/baz/qux/fizz/buzz/hoge.sv')
        context.add_source_file('/baz/qux/fizz/buzz/fuga.sv')
        context.add_source_file('/foo/bar/fizz/buzz/hoge.sv')

        expect(context.source_files).to match([
          match_source_file('/foo/bar/fizz/buzz/hoge.sv'),
          match_source_file('/foo/bar/fizz/buzz/fuga.sv'),
          match_source_file('/baz/qux/fizz/buzz/fuga.sv')
        ])
      end
    end
  end

  describe '#add_library_file' do
    let(:file_contents) do
      contents = []
      contents << <<~'CODE'
        module hoge;
        endmodule
      CODE
      contents << <<~'CODE'
        module fuga;
        endmodule
      CODE
      contents << <<~'CODE'
        module piyo;
        endmodule
      CODE
      contents
    end

    it '指定したライブラリファイルを追加する' do
      allow(File).to receive(:read).with('/foo/bar/hoge.sv').and_return(file_contents[0])
      allow(File).to receive(:read).with('/baz/qux/fuga.sv').and_return(file_contents[1])

      context.add_library_file('/foo/bar/hoge.sv')
      context.add_library_file('/baz/qux/fuga.sv')

      expect(context.arguments).to match([
        match_argument(:library_file, path: match_source_file('/foo/bar/hoge.sv')),
        match_argument(:library_file, path: match_source_file('/baz/qux/fuga.sv'))
      ])
    end

    context 'options[:runtime]がtrueの場合' do
      specify 'ライブラリファイルの追加は行わない' do
        options[:runtime] = true

        expect {
          context.add_library_file('/foo/bar/hoge.sv')
          context.add_library_file('/baz/qux/fuga.sv')
        }.not_to change { context.arguments.size }
      end
    end

    context '同一のファイルが既に追加されている場合' do
      it '当該ファイルは追加しない' do
        allow(File).to receive(:read).with('/foo/bar/fizz/buzz/hoge.sv').and_return(file_contents[0])
        allow(File).to receive(:read).with('/foo/bar/fizz/buzz/fuga.sv').and_return(file_contents[1])
        allow(File).to receive(:read).with('/baz/qux/fizz/buzz/hoge.sv').and_return(file_contents[0])
        allow(File).to receive(:read).with('/baz/qux/fizz/buzz/fuga.sv').and_return(file_contents[2])
        allow(File).to receive(:read).with('/foo/bar/fizz/buzz/hoge.sv').and_return(file_contents[0])

        context.add_library_file('/foo/bar/fizz/buzz/hoge.sv')
        context.add_library_file('/foo/bar/fizz/buzz/fuga.sv')
        context.add_library_file('/baz/qux/fizz/buzz/hoge.sv')
        context.add_library_file('/baz/qux/fizz/buzz/fuga.sv')
        context.add_library_file('/foo/bar/fizz/buzz/hoge.sv')

        expect(context.arguments).to match([
          match_argument(:library_file, path: match_source_file('/foo/bar/fizz/buzz/hoge.sv')),
          match_argument(:library_file, path: match_source_file('/foo/bar/fizz/buzz/fuga.sv')),
          match_argument(:library_file, path: match_source_file('/baz/qux/fizz/buzz/fuga.sv'))
        ])
      end
    end
  end

  describe '#define_macro' do
    it 'マクロを定義する' do
      context.define_macro(:FOO)
      context.define_macro('BAR=1')
      expect(context.macros).to match(FOO: true, BAR: '1')
    end

    it 'コンパイル引数として追加する' do
      context.define_macro(:FOO)
      context.define_macro('BAR=1')

      expect(context.arguments).to match([
        match_argument(:define, name: :FOO, value: be_nil),
        match_argument(:define, name: :BAR, value: '1')
      ])
    end

    context 'options[:runtme]がtrueの場合' do
      specify 'マクロ名の追加のみ行う' do
        options[:runtime] = true

        expect {
          context.define_macro(:FOO)
          context.define_macro('BAR=1')
        }.not_to change { context.arguments.size }
        expect(context.macros).to match(FOO: true, BAR: '1')
      end
    end

    context '同名のマクロが再定義された場合' do
      it '値を上書きする' do
        context.define_macro(:FOO)
        context.define_macro('BAR=1')
        expect(context.macros).to match(FOO: true, BAR: '1')
        expect(context.arguments).to match([
          match_argument(:define, name: :FOO, value: be_nil),
          match_argument(:define, name: :BAR, value: '1')
        ])

        context.define_macro('FOO=2')
        expect(context.macros).to match(FOO: '2', BAR: '1')
        expect(context.arguments).to match([
          match_argument(:define, name: :BAR, value: '1'),
          match_argument(:define, name: :FOO, value: '2')
        ])

        context.define_macro('BAR')
        expect(context.macros).to match(FOO: '2', BAR: true)
        expect(context.arguments).to match([
          match_argument(:define, name: :FOO, value: '2'),
          match_argument(:define, name: :BAR, value: be_nil)
        ])
      end
    end
  end

  describe '事前定義済みマクロ' do
    context '対象ツールがVCSの場合' do
      specify ':VCSが定義される' do
        options[:tool] = :vcs
        expect(context.macros).to match(VCS: true)
      end
    end

    context '対象ツールがDesign Compilerの場合' do
      specify 'SYNTHESISが定義される' do
        options[:tool] = :design_compiler
        expect(context.macros).to match(SYNTHESIS: true)
      end
    end

    context '対象ツールがFormalityの場合' do
      specify 'SYNTHESISが定義される' do
        options[:tool] = :formality
        expect(context.macros).to match(SYNTHESIS: true)
      end
    end

    context '対象ツールがXceliumの場合' do
      specify ':XCELIUMが定義される' do
        options[:tool] = :xcelium
        expect(context.macros).to match(XCELIUM: true)
      end
    end

    context '対象ツールがVivadoの場合' do
      specify 'SYNTHESISが定義される' do
        options[:tool] = :vivado
        expect(context.macros).to match(SYNTHESIS: true)
      end
    end

    context '対象ツールがVivado simulatorの場合' do
      specify 'SYNTHESISが定義される' do
        options[:tool] = :vivado_simulator
        expect(context.macros).to match(XILINX_SIMULATOR: true)
      end
    end
  end

  describe '#add_include_directory' do
    let(:directories) do
      ['/foo/bar', '/fizz/buzz']
    end

    it 'インクルードパスをコンパイル引数として追加する' do
      context.add_include_directory(directories[0])
      context.add_include_directory(directories[1])

      expect(context.arguments).to match([
        match_argument(:include, path: directories[0]),
        match_argument(:include, path: directories[1])
      ])
    end

    context 'options[:runtme]がtrueの場合' do
      specify 'インクルードパスの追加は行わない' do
        options[:runtime] = true

        expect {
          context.add_include_directory(directories[0])
          context.add_include_directory(directories[1])
        }.not_to change { context.arguments.size }
      end
    end

    context '追加済みのディレクトリが再度指定された場合' do
      specify '追加済みのディレクトリは再度追加しない' do
        context.add_include_directory(directories[0])
        context.add_include_directory(directories[0])
        context.add_include_directory(directories[1])

        expect(context.arguments).to match([
          match_argument(:include, path: directories[0]),
          match_argument(:include, path: directories[1])
        ])
      end
    end
  end

  describe '#add_library_directory' do
    let(:directories) do
      ['/foo/bar', '/fizz/buzz']
    end

    it 'ライブラリパスをコンパイル引数として追加する' do
      context.add_library_directory(directories[0])
      context.add_library_directory(directories[1])

      expect(context.arguments).to match([
        match_argument(:library_directory, path: directories[0]),
        match_argument(:library_directory, path: directories[1])
      ])
    end

    context 'options[:runtme]がtrueの場合' do
      specify 'ライブラリパスの追加は行わない' do
        options[:runtime] = true

        expect {
          context.add_library_directory(directories[0])
          context.add_library_directory(directories[1])
        }.not_to change { context.arguments.size }
      end
    end

    context '追加済みのディレクトリが再度指定された場合' do
      specify '追加済みのディレクトリは再度追加しない' do
        context.add_library_directory(directories[0])
        context.add_library_directory(directories[0])
        context.add_library_directory(directories[1])

        expect(context.arguments).to match([
          match_argument(:library_directory, path: directories[0]),
          match_argument(:library_directory, path: directories[1])
        ])
      end
    end
  end

  describe '#add_compile_argument' do
    let(:compile_arguments) do
      [
        FLGen::Arguments::Generic.new('-foo', nil),
        FLGen::Arguments::Generic.new('-bar', nil),
        FLGen::Arguments::Generic.new('-baz', :vcs),
        FLGen::Arguments::Generic.new('-qux', :xcelium)
      ]
    end

    it 'ツール指定がない引数を追加する' do
      context.add_compile_argument(compile_arguments[0])
      context.add_compile_argument(compile_arguments[1])
      context.add_compile_argument(compile_arguments[2])
      context.add_compile_argument(compile_arguments[3])

      expect(context.arguments).to match([
        have_attributes(argument: '-foo', tool: be_nil),
        have_attributes(argument: '-bar', tool: be_nil)
      ])
    end

    context 'options[:runtime]がtrueの場合' do
      specify '引数の追加は行わない' do
        options[:runtime] = true

        expect {
          context.add_compile_argument(compile_arguments[0])
          context.add_compile_argument(compile_arguments[1])
          context.add_compile_argument(compile_arguments[2])
          context.add_compile_argument(compile_arguments[3])
        }.not_to change { context.arguments.size }
      end
    end

    context 'options[:tool]の指定がある場合' do
      it 'ツール指定がない引数と、指定されたツールに対応する引数を追加する' do
        options[:tool] = :vcs

        context.add_compile_argument(compile_arguments[0])
        context.add_compile_argument(compile_arguments[1])
        context.add_compile_argument(compile_arguments[2])
        context.add_compile_argument(compile_arguments[3])

        expect(context.arguments).to match([
          have_attributes(argument: '-foo', tool: be_nil),
          have_attributes(argument: '-bar', tool: be_nil),
          have_attributes(argument: '-baz', tool: :vcs)
        ])
      end
    end
  end

  describe '#add_runtime_argument' do
    let(:runtime_arguments) do
      [
        FLGen::Arguments::Generic.new('-foo', nil),
        FLGen::Arguments::Generic.new('-bar', nil),
        FLGen::Arguments::Generic.new('-baz', :vcs),
        FLGen::Arguments::Generic.new('-qux', :xcelium)
      ]
    end

    it 'ツール指定のない引数を追加する' do
      options[:runtime] = true

      context.add_runtime_argument(runtime_arguments[0])
      context.add_runtime_argument(runtime_arguments[1])
      context.add_runtime_argument(runtime_arguments[2])
      context.add_runtime_argument(runtime_arguments[3])

      expect(context.arguments).to match([
        have_attributes(argument: '-foo', tool: be_nil),
        have_attributes(argument: '-bar', tool: be_nil)
      ])
    end

    context 'options[:runtime]が未指定の場合' do
      specify '引数の追加は行わない' do
        expect {
          context.add_runtime_argument(runtime_arguments[0])
          context.add_runtime_argument(runtime_arguments[1])
          context.add_runtime_argument(runtime_arguments[2])
          context.add_runtime_argument(runtime_arguments[3])
        }.not_to change { context.arguments.size }
      end
    end

    context 'options[:runtime]がfalseの場合' do
      specify '引数の追加は行わない' do
        options[:runtime] = false

        expect {
          context.add_runtime_argument(runtime_arguments[0])
          context.add_runtime_argument(runtime_arguments[1])
          context.add_runtime_argument(runtime_arguments[2])
          context.add_runtime_argument(runtime_arguments[3])
        }.not_to change { context.arguments.size }
      end
    end

    context 'options[:tool]の指定がある場合' do
      it 'ツール指定がないと、指定されたツールに対応する引数を追加する' do
        options[:runtime] = true
        options[:tool] = :xcelium

        context.add_runtime_argument(runtime_arguments[0])
        context.add_runtime_argument(runtime_arguments[1])
        context.add_runtime_argument(runtime_arguments[2])
        context.add_runtime_argument(runtime_arguments[3])

        expect(context.arguments).to match([
          have_attributes(argument: '-foo', tool: be_nil),
          have_attributes(argument: '-bar', tool: be_nil),
          have_attributes(argument: '-qux', tool: :xcelium)
        ])
      end
    end
  end
end
