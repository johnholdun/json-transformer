require 'json'
require './json-transformer'

test_file_paths =
  Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/test-*.json")

test_file_paths.each do |filename|
  test = JSON.parse(File.read(filename))

  puts "Testing #{filename}..."

  # TODO: Capture exceptions and mark as failure
  result = JSONTransformer.call(test['input'], test['rules'])

  if result == test['expected']
    puts 'Success!'
  else
    # TODO: Render diffs on failure? Maybe use `gron`?
    puts 'Failure! Unexpected result:'
    puts JSON.pretty_generate(result)
  end
end
