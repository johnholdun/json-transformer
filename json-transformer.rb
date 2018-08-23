require 'json'
require 'yaml'

class JSONTransformer
  def initialize(input, rules)
    @input = input
    @rules = rules
  end

  def call
    rules.each_with_object({}) do |(key, rule), obj|
      obj[key] = parse(rule)
    end
  end

  def self.call(*args)
    new(*args).call
  end

  private

  attr_reader :input, :rules

  def parse(rule, doc = input, captures = {})
    if rule.is_a?(String)
      value = fetch(rule, doc)
      value ||= rule unless rule =~ /^\$/
      return replace_captures(value, captures)
    end

    unless rule.is_a?(Hash)
      raise ArgumentError, "unexpected rule of type #{rule.class.name}"
    end

    unless rule.key?('$each')
      # This is not a repeating object; just parse each value

      return \
        rule.each_with_object({}) do |(key, value), obj|
          parsed_value = parse(value, doc, captures)
          obj[key] = replace_captures(parsed_value, captures)
        end
    end

    items =
      fetch_with_captures(rule.delete('$each')).map do |item, captures|
        parse(rule, item, captures)
      end

    if rule.key?('$key')
      items
        .each_with_object({}) do |item, obj|
          obj[item['$key']] = item.reject { |k, _| k.start_with?('$') }
        end
    else
      items
        .each_with_index
        .sort_by { |item, index| item['$index'] || index }
        .map { |item, _| item.reject { |k, _| k.start_with?('$') } }
    end
  end

  def fetch(path, doc = input)
    # If this isn't a path, return nothing
    return nil unless path.start_with?('$')

    # If we're just asking for the root, return the root
    return doc if path == '$'

    doc.dig(*path_to_tokens(path).map { |t| t =~ /\A\d+\Z/ ? t.to_i : t }) rescue ''
  end

  def path_to_tokens(path)
    unless path =~ /\A\$(\.:?[^\s]+)*\Z/
      raise ArgumentError, "invalid path #{path}"
    end

    path.sub(/^\$\./, '').split('.')
  end

  def tokens_to_path(tokens)
    "$#{tokens.map { |t| ".#{t}" }.join}"
  end

  def fetch_with_captures(path, doc = input)
    tokens = path_to_tokens(path)

    calculate_valid_paths(tokens)
      .map do |captures|
        new_path = tokens_to_path(replace_captures(tokens, captures))
        value = fetch(new_path)
        if value.is_a?(Hash)
          value.map do |key, value|
            [{ '$key' => key, '$value' => value }, captures]
          end
        elsif value.is_a?(Array)
          value.map { |v| [v, captures] }
        else
          [[value, captures]]
        end
      end
      .flatten(1)
  end

  # Iterate over tokens in path; for every capture, find every valid value and
  # continue, making note of the capture value. The end result should be an
  # array of paths along with the captures that created them.
  def calculate_valid_paths(tokens, doc = input)
    token, index = tokens.each_with_index.find { |t, i| t.start_with?(':') }

    return [{}] unless token

    sub_doc = tokens[0 .. index - 1].inject(doc) { |o, t| o[t] }

    items =
      case sub_doc
      when Array
        0...sub_doc.size
      when Hash
        sub_doc.keys
      else
        [sub_doc]
      end

    items.map { |value| { token => value } }
  end

  # Recursively replace strings that match a capture with the value of that
  # capture. For example, this returns 'bar':
  #
  #     replace_captures(':foo', foo: 'bar')
  def replace_captures(object, captures)
    case object
    when String
      object.start_with?(':') ? captures[object] : object
    when Array
      object.map { |o| replace_captures(o, captures) }
    when Hash
      object.each_with_object({}) do |(key, value), o|
        o[replace_captures(key, captures)] = replace_captures(value, captures)
      end
    else
      object
    end
  end
end
