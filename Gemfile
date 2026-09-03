# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# CI sets ROUGE_VERSION to test every Rouge release line the gemspec allows
gem 'rouge', ENV['ROUGE_VERSION'] if ENV['ROUGE_VERSION']

gem 'minitest', '~> 5.0'
gem 'rake', '~> 13.0'

# Visual preview server
gem 'rackup'
gem 'puma'
