# frozen_string_literal: true

RSpec.describe FLGen::CLI do
  let(:cli) do
    described_class.new
  end

  let(:files) do
    [
      'foo.sv',
      'bar/bar.sv',
      'bar/baz/baz.sv'
    ].map do |file|
      File.join(FLGEN_ROOT, 'sample', file)
    end
  end

  let(:macros) do
    ['BAR_0', 'BAR_1=1', 'NO_BAZ']
  end

  let(:include_directories) do
    [
      'bar',
      'bar/baz',
      'foo'
    ].map do |dir|
      File.join(FLGEN_ROOT, 'sample', dir)
    end
  end

  let(:compile_arguments) do
    ['-foo_0', '-bar_0', '-baz_0']
  end

  let(:runtime_arguments) do
    ['-foo_1', '-bar_1', '-baz_1']
  end

  let(:file_list) do
    File.join(FLGEN_ROOT, 'sample', 'foo.list.rb')
  end

  let(:io) do
    StringIO.new(+'')
  end

  describe 'ファイルリスト出力' do
    context '出力先が未指定の場合' do
      it '標準出力にファイルリストを出力する' do
        expect { cli.run(['--print-header', file_list]) }.to output(<<~OUT).to_stdout
          +define+#{macros[0]}
          +define+#{macros[1]}
          +incdir+#{include_directories[0]}
          +incdir+#{include_directories[1]}
          #{compile_arguments[0]}
          #{files[0]}
          #{files[1]}
          #{files[2]}
        OUT
      end
    end

    context '出力先が指定されている場合' do
      let(:output) do
        'out.f'
      end

      before do
        allow(File).to receive(:open).with(output, 'w').and_yield(io)
      end

      it 'filelist形式でファイルリストを書き出す' do
        cli.run(["--output=#{output}", file_list])
        expect(io.string).to eq(<<~OUT)
          //  flgen version #{FLGen::VERSION}
          //  applied arguments
          //    --output=#{output}
          //    #{file_list}
          +define+#{macros[0]}
          +define+#{macros[1]}
          +incdir+#{include_directories[0]}
          +incdir+#{include_directories[1]}
          #{compile_arguments[0]}
          #{files[0]}
          #{files[1]}
          #{files[2]}
        OUT
      end
    end

    context '--format=vivado-tclが指定された場合' do
      let(:output) do
        'out.tcl'
      end

      before do
        allow(File).to receive(:open).with(output, 'w').and_yield(io)
      end

      it 'vivadoで読み込み可能なTCLを書き出す' do
        cli.run(["--output=#{output}", '--format=vivado-tcl', file_list])
        expect(io.string).to eq(<<~TCL)
          #  flgen version #{FLGen::VERSION}
          #  applied arguments
          #    --output=#{output}
          #    --format=vivado-tcl
          #    #{file_list}
          set flgen_defines {}
          lappend flgen_defines "#{macros[0]}"
          lappend flgen_defines "#{macros[1]}"
          set_property verilog_define $flgen_defines [current_fileset]
          set flgen_include_directories {}
          lappend flgen_include_directories "#{include_directories[0]}"
          lappend flgen_include_directories "#{include_directories[1]}"
          set_property include_dirs $flgen_include_directories [current_fileset]

          set flgen_source_files {}
          lappend flgen_source_files "#{files[0]}"
          lappend flgen_source_files "#{files[1]}"
          lappend flgen_source_files "#{files[2]}"
          add_files -fileset [current_fileset] $flgen_source_files
        TCL
      end
    end

    context '--format=filelist-xsimが指定された場合' do
      let(:output) do
        'out.f'
      end

      before do
        allow(File).to receive(:open).with(output, 'w').and_yield(io)
      end

      it 'xsim対応のfilelist形式でファイルリストを書き出す' do
        cli.run(["--output=#{output}", '--format=filelist-xsim', file_list])
        expect(io.string).to eq(<<~OUT)
          //  flgen version #{FLGen::VERSION}
          //  applied arguments
          //    --output=#{output}
          //    --format=filelist-xsim
          //    #{file_list}
          -d #{macros[0]}
          -d #{macros[1]}
          -i #{include_directories[0]}
          -i #{include_directories[1]}
          #{compile_arguments[0]}
          #{files[0]}
          #{files[1]}
          #{files[2]}
        OUT
      end
    end

    context '--no-print-headerが指定された場合' do
      let(:output) do
        'out.f'
      end

      before do
        allow(File).to receive(:open).with(output, 'w').and_yield(io)
      end

      it 'ヘッダーを出力しない' do
        cli.run(['--no-print-header', "--output=#{output}", file_list])
        expect(io.string).to eq(<<~OUT)
          +define+#{macros[0]}
          +define+#{macros[1]}
          +incdir+#{include_directories[0]}
          +incdir+#{include_directories[1]}
          #{compile_arguments[0]}
          #{files[0]}
          #{files[1]}
          #{files[2]}
        OUT
      end
    end
  end

  context '--compileが指定された場合' do
    it 'コンパイル引数およびソースファイルを出力する' do
      expect { cli.run(['--compile', file_list]) }.to output(<<~OUT).to_stdout
        +define+#{macros[0]}
        +define+#{macros[1]}
        +incdir+#{include_directories[0]}
        +incdir+#{include_directories[1]}
        #{compile_arguments[0]}
        #{files[0]}
        #{files[1]}
        #{files[2]}
      OUT
    end
  end

  context '--runtimeが指定された場合' do
    it 'ランタイム引数のみを出力する' do
      expect {
        cli.run(['--runtime', file_list])
      }.to output(<<~OUT).to_stdout
        #{runtime_arguments[0]}
      OUT
    end
  end

  context '--toolが指定された場合' do
    it '指定されたツールに対応する引数を含むファイルリストを出力する' do
      expect {
        cli.run(['--compile', '--tool=vcs', file_list])
      }.to output(<<~OUT).to_stdout
        +define+#{macros[0]}
        +define+#{macros[1]}
        +incdir+#{include_directories[0]}
        +incdir+#{include_directories[1]}
        #{compile_arguments[0]}
        #{compile_arguments[1]}
        #{files[0]}
        #{files[1]}
        #{files[2]}
      OUT

      expect {
        cli.run(['--compile', '--tool=xcelium', file_list])
      }.to output(<<~OUT).to_stdout
        +define+#{macros[0]}
        +define+#{macros[1]}
        +incdir+#{include_directories[0]}
        +incdir+#{include_directories[1]}
        #{compile_arguments[0]}
        #{compile_arguments[2]}
        #{files[0]}
        #{files[1]}
        #{files[2]}
      OUT

      expect {
        cli.run(['--compile', '--tool=vcs', file_list])
      }.to output(<<~OUT).to_stdout
        +define+#{macros[0]}
        +define+#{macros[1]}
        +incdir+#{include_directories[0]}
        +incdir+#{include_directories[1]}
        #{compile_arguments[0]}
        #{compile_arguments[1]}
        #{files[0]}
        #{files[1]}
        #{files[2]}
      OUT

      expect {
        cli.run(['--runtime', '--tool=vcs', file_list])
      }.to output(<<~OUT).to_stdout
        #{runtime_arguments[0]}
        #{runtime_arguments[1]}
      OUT

      expect {
        cli.run(['--runtime', '--tool=xcelium', file_list])
      }.to output(<<~OUT).to_stdout
        #{runtime_arguments[0]}
        #{runtime_arguments[2]}
      OUT
    end
  end

  context '--source-file-onlyが指定された場合' do
    it 'ソースファイル部のみを出力する' do
      expect { cli.run(['--source-file-only', file_list]) }.to output(<<~OUT).to_stdout
        #{files[0]}
        #{files[1]}
        #{files[2]}
      OUT
    end
  end

  describe '--define-macroオプション' do
    it 'マクロを定義する' do
      expect { cli.run(['--define-macro=NO_BAZ', file_list]) }.to output(<<~OUT).to_stdout
        +define+#{macros[2]}
        +define+#{macros[0]}
        +define+#{macros[1]}
        +incdir+#{include_directories[0]}
        +incdir+#{include_directories[1]}
        #{compile_arguments[0]}
        #{files[0]}
        #{files[1]}
      OUT
    end
  end

  describe '--include-directoryオプション' do
    it 'インクルードディレクトリを追加する' do
      expect {
        cli.run(["--include-directory=#{include_directories[2]}", file_list])
      }.to output(<<~OUT).to_stdout
        +define+#{macros[0]}
        +define+#{macros[1]}
        +incdir+#{include_directories[2]}
        +incdir+#{include_directories[0]}
        +incdir+#{include_directories[1]}
        #{compile_arguments[0]}
        #{files[0]}
        #{files[1]}
        #{files[2]}
      OUT
    end
  end
end
