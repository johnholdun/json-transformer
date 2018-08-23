require 'json'
require './json-transformer'

Dir.glob('./test-*.json').each do |filename|
  test = JSON.parse(File.read(filename))
  print "Testing #{filename}..."
  result = JSONTransformer.call(test['input'], test['rules'])
  success = result == test['expected']
  puts success ? 'Success!' : 'Failure!'
end
