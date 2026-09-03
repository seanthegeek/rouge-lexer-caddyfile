# frozen_string_literal: true

require 'rouge'
require_relative 'lib/rouge/lexer/caddyfile'

lexer = Rouge::Lexer.find('caddyfile')

sample_path = File.join(__dir__, 'spec', 'visual', 'samples', 'caddyfile')
sample = File.read(sample_path)

if ENV['DEBUG']
  lexer.lex(sample) { |tok, val| puts "#{tok.qualname.ljust(30)} #{val.inspect}" }
else
  formatter = Rouge::Formatters::Terminal256.new(Rouge::Themes::Github.new)
  puts formatter.format(lexer.lex(sample))
end
