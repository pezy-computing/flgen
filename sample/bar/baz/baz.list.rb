include_directory '.'
if target_tool? :xcelium
  compile_argument '-baz_0'
  runtime_argument '-baz_1'
end
unless macro_defined? :NO_BAZ
  source_file 'baz.sv'
end
