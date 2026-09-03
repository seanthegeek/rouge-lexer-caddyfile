# frozen_string_literal: true

require 'rouge'
require_relative 'lib/rouge/lexer/caddyfile'

app = proc do |_env|
  lexer     = Rouge::Lexer.find('caddyfile')
  formatter = Rouge::Formatters::HTML.new
  theme_css = Rouge::Themes::Github.render(scope: '.highlight')

  sample_path = File.join(__dir__, 'spec', 'visual', 'samples', 'caddyfile')
  sample = File.exist?(sample_path) ? File.read(sample_path) : '(no visual sample found)'

  demo_path = File.join(__dir__, 'spec', 'demos', 'caddyfile')
  demo = File.exist?(demo_path) ? File.read(demo_path) : '(no demo found)'

  highlighted_sample = formatter.format(lexer.lex(sample))
  highlighted_demo   = formatter.format(lexer.lex(demo))

  body = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>Rouge Lexer Preview: #{lexer.tag}</title>
      <style>#{theme_css} body { font-family: sans-serif; margin: 2em; }</style>
    </head>
    <body>
      <h1>#{lexer.title} Lexer Preview</h1>
      <h2>Demo</h2>
      <div class="highlight"><pre>#{highlighted_demo}</pre></div>
      <h2>Visual Sample</h2>
      <div class="highlight"><pre>#{highlighted_sample}</pre></div>
    </body>
    </html>
  HTML

  [200, { 'content-type' => 'text/html' }, [body]]
end

run app
