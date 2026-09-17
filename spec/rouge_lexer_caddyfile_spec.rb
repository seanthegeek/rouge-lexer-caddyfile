# frozen_string_literal: true

require 'minitest/autorun'
require 'rouge'
require 'rouge/lexer/caddyfile'

class RougeLexerCaddyfileTest < Minitest::Test
  def setup
    @lexer = Rouge::Lexers::Caddyfile.new
  end

  def test_finds_by_tag
    assert_equal Rouge::Lexers::Caddyfile, Rouge::Lexer.find('caddyfile')
  end

  def test_finds_by_alias_caddy
    assert_equal Rouge::Lexers::Caddyfile, Rouge::Lexer.find('caddy')
  end

  def test_guesses_by_filename
    assert_equal Rouge::Lexers::Caddyfile, Rouge::Lexer.guess(filename: 'Caddyfile')
    assert_equal Rouge::Lexers::Caddyfile, Rouge::Lexer.guess(filename: 'site.caddyfile')
    assert_equal Rouge::Lexers::Caddyfile, Rouge::Lexer.guess(filename: 'site.Caddyfile')
  end

  def test_guesses_by_mimetype
    assert_equal Rouge::Lexers::Caddyfile, Rouge::Lexer.guess(mimetype: 'text/x-caddyfile')
  end

  def test_guesses_by_source
    assert_equal Rouge::Lexers::Caddyfile, Rouge::Lexer.guess(source: load_demo)
  end

  def test_demo_preserves_input
    demo = load_demo
    output = @lexer.lex(demo).map { |_, val| val }.join
    assert_equal demo, output, 'Lexer output does not reconstruct the demo input'
  end

  def test_sample_preserves_input
    sample = load_sample
    output = @lexer.lex(sample).map { |_, val| val }.join
    assert_equal sample, output, 'Lexer output does not reconstruct the sample input'
  end

  def test_no_error_tokens_in_demo
    demo = load_demo
    errors = collect_errors(demo)
    assert_empty errors, "Demo produced error tokens:\n#{format_errors(errors)}"
  end

  def test_no_error_tokens_in_sample
    sample = load_sample
    errors = collect_errors(sample)
    assert_empty errors, "Visual sample produced error tokens:\n#{format_errors(errors)}"
  end

  def test_directive_is_keyword
    assert_includes tokens("example.com {\n\tfile_server\n}\n"),
                    [Rouge::Token::Tokens::Keyword, 'file_server']
  end

  def test_site_address_is_namespace
    assert_includes tokens("example.com {\n}\n"),
                    [Rouge::Token::Tokens::Name::Namespace, 'example.com']
  end

  def test_global_option_is_declaration
    assert_includes tokens("{\n\temail admin@example.com\n}\n"),
                    [Rouge::Token::Tokens::Keyword::Declaration, 'email']
  end

  def test_named_matcher_and_matcher_name
    toks = tokens("example.com {\n\t@post method POST\n}\n")
    assert_includes toks, [Rouge::Token::Tokens::Name::Label, '@post']
    assert_includes toks, [Rouge::Token::Tokens::Name::Builtin, 'method']
    assert_includes toks, [Rouge::Token::Tokens::Name::Constant, 'POST']
  end

  def test_placeholder_and_env_var
    toks = tokens("{$DOMAIN:localhost} {\n\tredir https://example.com{uri}\n}\n")
    assert_includes toks, [Rouge::Token::Tokens::Name::Variable, '{$DOMAIN:localhost}']
    assert_includes toks, [Rouge::Token::Tokens::Name::Variable::Magic, '{uri}']
  end

  def test_heredoc_is_single_token
    src = "example.com {\n\trespond <<HTML\n\t\t<html></html>\n\t\tHTML 200\n}\n"
    toks = tokens(src)
    assert_includes toks, [Rouge::Token::Tokens::Str::Heredoc, "<<HTML\n\t\t<html></html>\n\t\tHTML"]
    assert_includes toks, [Rouge::Token::Tokens::Num::Integer, '200']
  end

  def test_double_quoted_escape
    toks = tokens("example.com {\n\trespond \"\\\"abc def\\\"\"\n}\n")
    assert_includes toks, [Rouge::Token::Tokens::Str::Escape, '\\"']
  end

  def test_comment_hash_inside_token_is_not_a_comment
    toks = tokens("example.com {\n\tredir https://example.com/#anchor # real comment\n}\n")
    assert_includes toks, [Rouge::Token::Tokens::Name, 'https://example.com/#anchor']
    assert_includes toks, [Rouge::Token::Tokens::Comment::Single, '# real comment']
  end

  # Overlap-sensitive classifications: a word from one vocabulary that also
  # appears in another (subdirective vs. matcher, subdirective vs. lb_policy
  # value, subdirective vs. response matcher, subdirective vs. plugin
  # directive) must resolve to the token for its actual role, in context.
  def test_lb_retry_match_inline_matcher
    toks = tokens("example.com {\n\treverse_proxy backend {\n\t\tlb_retry_match method GET\n\t}\n}\n")
    assert_includes toks, [Rouge::Token::Tokens::Name::Attribute, 'lb_retry_match']
    assert_includes toks, [Rouge::Token::Tokens::Name::Builtin, 'method']
    assert_includes toks, [Rouge::Token::Tokens::Name::Constant, 'GET']
  end

  def test_lb_retry_match_block_matcher
    src = "example.com {\n\treverse_proxy backend {\n\t\tlb_retry_match {\n\t\t\tmethod GET\n\t\t}\n\t}\n}\n"
    toks = tokens(src)
    assert_includes toks, [Rouge::Token::Tokens::Name::Attribute, 'lb_retry_match']
    assert_includes toks, [Rouge::Token::Tokens::Name::Builtin, 'method']
  end

  def test_first_as_sampling_subdirective
    src = "example.com {\n\tlog {\n\t\tsampling {\n\t\t\tfirst 10\n\t\t}\n\t}\n}\n"
    toks = tokens(src)
    assert_includes toks, [Rouge::Token::Tokens::Name::Attribute, 'first']
  end

  def test_first_as_lb_policy_value
    toks = tokens("example.com {\n\treverse_proxy backend {\n\t\tlb_policy first\n\t}\n}\n")
    assert_includes toks, [Rouge::Token::Tokens::Name::Constant, 'first']
  end

  def test_status_as_file_server_subdirective
    toks = tokens("example.com {\n\tfile_server {\n\t\tstatus 404 410\n\t}\n}\n")
    assert_includes toks, [Rouge::Token::Tokens::Name::Attribute, 'status']
  end

  def test_status_as_response_matcher
    src = "example.com {\n\thandle_response {\n\t\t@bad status 500\n\t}\n}\n"
    toks = tokens(src)
    assert_includes toks, [Rouge::Token::Tokens::Name::Builtin, 'status']
  end

  def test_filter_action_in_argument_position
    # <field> ip_mask ... — the filter action word is the *second* word on
    # the line (argument position, via classify_argument/values), not the
    # line-start word covered by the cookie/query block tests below.
    src = "example.com {\n\tlog {\n\t\tformat filter {\n\t\t\trequest>remote_ip ip_mask 16 32\n\t\t}\n\t}\n}\n"
    toks = tokens(src)
    assert_includes toks, [Rouge::Token::Tokens::Name::Constant, 'ip_mask']
  end

  def test_log_filter_actions_in_cookie_block
    src = "example.com {\n\tlog {\n\t\tformat filter {\n\t\t\tfields {\n\t\t\t\tset_cookie cookie {\n" \
          "\t\t\t\t\tdelete session_id\n\t\t\t\t\treplace csrf_token REDACTED\n\t\t\t\t\thash user_id\n" \
          "\t\t\t\t}\n\t\t\t}\n\t\t}\n\t}\n}\n"
    toks = tokens(src)
    assert_includes toks, [Rouge::Token::Tokens::Name::Constant, 'cookie']
    assert_includes toks, [Rouge::Token::Tokens::Name::Attribute, 'delete']
    assert_includes toks, [Rouge::Token::Tokens::Name::Attribute, 'replace']
    assert_includes toks, [Rouge::Token::Tokens::Name::Attribute, 'hash']
    refute_includes toks, [Rouge::Token::Tokens::Keyword, 'replace']
  end

  def test_log_filter_actions_in_query_block
    src = "example.com {\n\tlog {\n\t\tformat filter {\n\t\t\tfields {\n\t\t\t\turi query {\n" \
          "\t\t\t\t\treplace token REDACTED\n\t\t\t\t}\n\t\t\t}\n\t\t}\n\t}\n}\n"
    toks = tokens(src)
    assert_includes toks, [Rouge::Token::Tokens::Name::Constant, 'query']
    assert_includes toks, [Rouge::Token::Tokens::Name::Attribute, 'replace']
    refute_includes toks, [Rouge::Token::Tokens::Keyword, 'replace']
  end

  def test_replace_directive_outside_filter_block_is_still_keyword
    toks = tokens("example.com {\n\treplace {\n\t\tregex .* \"\" \"\"\n\t}\n}\n")
    assert_includes toks, [Rouge::Token::Tokens::Keyword, 'replace']
  end

  private

  def tokens(text)
    @lexer.lex(text).map { |tok, val| [tok, val] }
  end

  def load_demo
    File.read(File.join(__dir__, 'demos', 'caddyfile'))
  end

  def load_sample
    File.read(File.join(__dir__, 'visual', 'samples', 'caddyfile'))
  end

  def collect_errors(text)
    @lexer.lex(text).select { |tok, _| tok == Rouge::Token::Tokens::Error }
  end

  def format_errors(errors)
    errors.map { |_, val| "  #{val.inspect}" }.join("\n")
  end
end
