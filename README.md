# FLGen

ファイルリストを記述するための DSL と、ファイルリストを生成するための実行コマンドを提供します。

## インストール

### Ruby

FLGen は [Ruby](https://www.ruby-lang.org) で実装されているので、実行には Ruby のインストールが必要です。
サポートする Ruby のバージョンは 3.0 以上です。インストール方法については、[こちら](https://www.ruby-lang.org/en/downloads/)を参照ください。

### インストールコマンド

FLGen をインストールするには、以下のコマンドを実行します。

```
$ gem install flgen
```

## DSL

ファイルリストを記述するための DSL として以下の構文が定義されています。

* `source_file(path, from: :current)`
    * 指定したファイルをファイルリストに追加します
* `file_list(path, from: :root)`
    * 指定したファイルリストを読み込みます
* `define_macro(name, value = nil)`
    * マクロを定義します
* `macro_defined?(name)`
    * 指定したマクロが定義されているかどうかを返します
* `include_directory(path, from: :current)`
    * 指定したパスをインクルードパスとして追加します
* `target_tool?(tool)`
    * `tool` が対象ツールかどうかを返します
* `compile_argument(argument, tool: nil)`
    * コンパイル引数を追加します
    * `tool` が指定されている場合は、対象ツールの場合にのみ、引数を追加します
* `runtime_argument(argument, tool: nil)`
    * 実行時引数を追加します
    * `tool` が指定されている場合は、対象ツールの場合にのみ、引数を追加します

Ruby の言語内 DSL として実装されているので、以下の様に `if` など Ruby の構文も使用することができます。

```ruby
if target_tool? :vcs
  compile_argument '-sverilog'
end

10.times do |i|
  source_file "foo_#{i}.sv"
end
```

### `from` オプション引数について

`from` は指定されたファイルやディレクトリの基準ディレクトリを指定する引数で、`:current`/`root`/`local_root` を指定することができます。

* `:current`
    * 現在のファイルリストがある場所を基準とします
* `:root`
    * `.git` があるリポジトリのルートディレクトリを基準ディレクトリとします
    * あるリポジトリのサブモジュール (上位階層にも `.git` がある) 場合、上位リポジトリのルートディレクトリから順に検索を行います
* `:local_root`
    * 自身が含まれるリポジトリのルートディレクトリを基準ディレクトリとします

ただし、与えられたファイルやディレクトリが絶対パスで指定されている場合は、`from` に関係なく、そのまま追加されます。

#### 例

以下のディレクトリ構造になっていたとします。

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

* `bar.list.rb` で `source_file 'bar.sv', from: :current` とある場合
    * `foo_project/bar_project/src/bar.sv` が追加される
* `bar.list.rb` で `source_file 'common/common.sv', from: :root` とある場合
    * `foo_project/common/common.sv` が追加される
* `bar.list.rb` で `source_file 'common/common.sv', from: :local_root` とある場合
    * `foo_project/bar_project/common/common.sv` が追加される

## 実行コマンド

`flgen` が実行コマンドです。`flgen` に DSL で記述されたファイルリストを与えると、EDA ツールに与えるためのファイルリストを出力します。
また、以下のオプションがあります。

* `--define-macro=MACRO[,MACRO]`
    * マクロ定義を追加します
* `--include-directory=DIR[,DIR]`
    * インクルードディレクトリを追加します
* `--compile`
    * 出力されるファイルリストは `runtime_argument` で指定された実行時引数を含みません
* `--runtime`
    * 出力されるファイルリストは `runtime_argument` で指定された実行時引数だけを含みます
* `--tool=TOOL`
    * 対象となる EDA ツールを指定します
    * `compile_argument`/`runtime_argument` でツールの指定がある場合、一致する引数がファイルリストに出力されます
* `--rm-ext=EXT[,EXT]`
    * 指定された拡張子をソースファイルから削除します
* `--collect-ext=EXT[,EXT]`
    * 指定された拡張子を持つソースファイルのみがファイルリストに出力されます
* `--output=FILE`
    * 出力するファイルリストのファイル名を指定します
    * 指定がない場合は、標準出力に出力されます
* `--[no-]print-header`
    * ヘッダーを出力するかどうかを指定します。
* `--source-file-only`
    * ソースファイルのみがファイルリストに出力されます

## サンプル

https://github.com/pezy-computing/flgen/sample

にサンプルがあります。

## ライセンス

Apache-2.0 ライセンスの元で公開しています。詳しくは、下記及び [LICENSE](LICENSE) を参照ください。

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
