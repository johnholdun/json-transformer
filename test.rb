require 'json'
require './json-transformer'

Dir.glob('./test-*.json').each do |filename|
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
