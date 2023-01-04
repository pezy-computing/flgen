[![Gem Version](https://badge.fury.io/rb/flgen.svg)](https://badge.fury.io/rb/flgen)
[![CI](https://github.com/pezy-computing/flgen/actions/workflows/ci.yml/badge.svg)](https://github.com/pezy-computing/flgen/actions/workflows/ci.yml)
[![codecov](https://codecov.io/github/pezy-computing/flgen/branch/master/graph/badge.svg?token=P5JSMPRV3J)](https://codecov.io/github/pezy-computing/flgen)

# FLGen

FLGen provides a DSL to write filelists and generator tool to generate a filelist which is given to EDA tools.

## Install

### Ruby

FLGen is written in [Ruby](https://www.ruby-lang.org) programing language and its required version is 3.0 or later. Before using FLGen, you need to install Ruby before using FLGen. See [this page](https://www.ruby-lang.org/en/downloads/) for further details.

### Install FLGen

Use the command below to isntall FLGen.

```
$ gem install flgen
```

## Filelist

FLGen prives APIs listed below to describe your filelists.

* `source_file(path, from: :current, base: nil)`
    * Add the given source file to the current filelist.
* `file_list(path, from: :root, base: nil)`
    * Load the given filelist.
* `include_directory(path, from: :current, base: nil)`
    * Add the given directory to the list of include direcotries.
* `define_macro(name, value = nil)`
    * Define a text macro.
* `macro_defined?(name)`
    * Return `true` if the given macro is defined.
* `file?(path, from: :current, base: nil)`
    * Return `treu` if the given file exists.
* `directory?(path, from: :current, base: nil)`
    * Return `true` if the given directory exists.
* `env?(name)`
    * Return `true` if the givne environment variable is defined.
* `env(name)`
    * Retunr the value of the given environment variable.
* `compile_argument(argument, tool: nil)`
    * Add the given argument to the list of compile arguments.
    * If `tool` is specified the given argument is added only when `tool` is matched with the targe tool.
* `runtime_argumetn(argument, tool: nil)`
    * Add the given argument to the list of runtime arguments.
    * If `tool` is specified the given argument is added only when `tool` is matched with the targe tool.
* `target_tool?(tool)`
    * Return `true` if the given tool is matched with the targe tool.

FLGen's filelist is designed as an inernal DSL with Ruby. Therefore you can use Ruby's syntax. For example:

```ruby
if macro_defined? :GATE_SIM
  source_file 'foo_top.v.gz' # synthsized netlist
else
  source_file 'foo_top.sv' # RTL
end
```

### About `from`/`base` arguments

The `from` argument is to specify how to search the given file or directory. You can specify one of three below.

* `:current`
    * Search the given file or directory from the directory where the current filelist is.
* `:root`
    * Search the given file or directory from the repository root directories where the `.git` directory is.
    * Serch order is descending order.
        * from upper root direcotries to local root direcoty
* `:local_root`
    * Search the given file or directory from the repository root directory where the current filelist belongs to.

The `from` argument is ignored if the given path is an absolute path or the `base` argument is specified.

The `base` argument is to specify the serach direcotry for the given file or directory.

#### Example

This is an exmaple directory structure.

```
foo_project
+-- .git
+-- bar_project
|   +-- .git
|   +-- common
|   |   `-- common.sv
|   `-- src
|       + bar.list.rb
|       ` bar.sv
`-- common
    `-- common.sv
```

* `source_file 'bar.sv', from: :current` @ `bar.list.rb`
    * `foo_project/bar_project/bar.sv` is added.
* `source_file 'common/common.sv', from: :root` @ `bar.list.rb`
    * `foo_project/common/common.sv` is added
* `source_file 'common/bar_common.sv', from: :local_root` @ `bar.list.rb`
    * `foo_project/bar_project/common/common.sv` is added

## Generator command

`flgen` is the generator command and generate a filelist which is given to EDA tools from the given filelists. Command line options are listed below.

* `--define-macro=MACRO[,MACRO]`
    * Define the given macros
* `--include-directory=DIR[,DIR]`
    * Specify include directories
* `--compile`
    * If this option is specified the generated filelist contains source file path, arguments to define macros, arguments to specify include directories and arguments specified by `compile_argument` API.
* `--runtime`
    * If this option is specified the generated filelist contains arguments specified by `runtime_argumetn`
* `--tool=TOOL`
    * Specify the target tool.
* `--rm-ext=EXT[,EXT]`
    * Remove specifyed file extentions from source file path.
* `--collect-ext=EXT[,EXT]`
    * The generated filelist contains source file pash which has the specified file extentions.
* `--format=FORMAT`
    * Specify the format of the generated filelist.
    * If no format is specified the generated filelist is for major EDA tools.
    * If `filelist-xsim` is specified the generated filelist is for Vivado Simulator.
* `--output=FILE`
    * Specify the path of the generated filelist
    * The generated fileslist is output to STDOUT if no path is specified.
* `--[no-]print-header`
    * Specify whether or not the output filelist includes its file header or not.
* `--source-file-only`
    * The generated filelist contains source file path only if this option is specified.

## Example

You can find an exmpale from [here](https://github.com/pezy-computing/flgen/tree/master/sample).

```
$ flgen --output=filelist.f sample/foo.list.rb
$ cat filelist.f
//  flgen version 0.14.0
//  applied arguments
//    --output=filelist.f
//    sample/foo.list.rb
+define+BAR_0
+define+BAR_1=1
+incdir+/home/taichi/workspace/pezy/flgen/sample/bar
+incdir+/home/taichi/workspace/pezy/flgen/sample/bar/baz
-foo_0
/home/taichi/workspace/pezy/flgen/sample/foo.sv
/home/taichi/workspace/pezy/flgen/sample/bar/bar.sv
/home/taichi/workspace/pezy/flgen/sample/bar/baz/baz.sv
```

[rggen-sample-testbench](https://github.com/rggen/rggen-sample-testbench) uses FLGen. This can be a practical example.

* https://github.com/rggen/rggen-sample-testbench/blob/master/env/compile.rb
* https://github.com/rggen/rggen-sample-testbench/blob/master/rtl/compile.rb

## License

FLGen is licensed under the Apache-2.0 license. See [LICNESE](LICENSE) and below for further details.

```
Copyright 2022 PEZY Computing K.K.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
