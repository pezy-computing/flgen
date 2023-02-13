define_macro :BAR_0
define_macro :BAR_1, 1
compile_argument '-bar_0', tool: :vcs
runtime_argument '-bar_1', tool: :vcs

library_directory 'bar_lib'
source_file       'sample/bar/bar.sv', from: :root
file_list         'baz/baz.list.rb', from: :current
