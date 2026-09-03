# rouge-lexer-caddyfile

[![Test](https://github.com/seanthegeek/rouge-lexer-caddyfile/actions/workflows/test.yml/badge.svg)](https://github.com/seanthegeek/rouge-lexer-caddyfile/actions/workflows/test.yml)
[![Gem Version](https://badge.fury.io/rb/rouge-lexer-caddyfile.svg)](https://rubygems.org/gems/rouge-lexer-caddyfile)

A Rouge lexer plugin for the Caddyfile configuration format used by the
[Caddy](https://caddyserver.com/) web server. Rouge is the default syntax
highlighter for Jekyll (and therefore GitHub Pages). This gem adds
Caddyfile support to Rouge.

## Installation

The gem requires Ruby 3.0 or newer and Rouge 3.4 or newer.

Install the gem directly:

```sh
gem install rouge-lexer-caddyfile
```

Or add it to your `Gemfile`:

```ruby
gem 'rouge-lexer-caddyfile'
```

Then run:

```sh
bundle install
```

## Usage

Once installed, Rouge will automatically discover the lexer. You can use
`caddyfile` (or the alias `caddy`) as the language tag in fenced code blocks:

````markdown
```caddyfile
example.com {
	root * /var/www
	encode zstd gzip
	reverse_proxy /api/* localhost:9000
	file_server
}
```
````

The lexer is also selected automatically for files named `Caddyfile` or ending
in `.caddyfile`, and for the MIME type `text/x-caddyfile`.

### Jekyll / GitHub Pages

Add the gem to your site's `Gemfile` inside the `:jekyll_plugins` group:

```ruby
group :jekyll_plugins do
  gem "rouge-lexer-caddyfile"
end
```

Run `bundle install`, then use the language tag in fenced code blocks. Jekyll
will pick up the lexer automatically via Rouge's plugin discovery.

### Colors

The lexer tells Rouge how to identify tokens. Rouge wraps each token in a `span` tag
with a `class` related to that token type. If you want to change how the tokens are
highlighted, change themes or add custom CSS.

The Caddyfile constructs map to Rouge tokens as follows (plugin vocabulary
uses the same tokens, see [Plugin support](#plugin-support)):

| Construct | Example | Token |
| --- | --- | --- |
| Directives | `reverse_proxy`, `file_server` | `Keyword` |
| Global options | `email`, `servers` | `Keyword::Declaration` |
| Subdirectives and sub-options | `lb_policy`, `output`, `timeouts` | `Name::Attribute` |
| Request and response matcher names | `path`, `header`, `status` | `Name::Builtin` |
| The `not` matcher | `not path /css/*` | `Keyword::Pseudo` |
| Site addresses | `example.com`, `:8080`, `*.example.com` | `Name::Namespace` |
| Named matchers | `@post` | `Name::Label` |
| Snippets, named routes and references | `(logging)`, `&(app-proxy)`, `import logging` | `Name::Function` |
| Placeholders | `{uri}`, `{http.request.host}` | `Name::Variable::Magic` |
| Environment variables | `{$DOMAIN:localhost}` | `Name::Variable` |
| Boolean-like values | `on`, `off`, `true`, `false` | `Keyword::Constant` |
| HTTP methods and enumerated values | `POST`, `first`, `h2c`, `json` | `Name::Constant` |
| Double-quoted tokens | `"abc def"` | `Str::Double` |
| Escaped quotes and braces | `\"`, `\{` | `Str::Escape` |
| Backtick-quoted tokens | `` `{"foo": "bar"}` `` | `Str::Backtick` |
| Heredocs | `<<HTML ... HTML` | `Str::Heredoc` |
| Integers and ratios | `200`, `0.1` | `Num::Integer`, `Num::Float` |
| Durations, sizes and status classes | `10s`, `5MB`, `2xx` | `Num::Other` |
| Wildcards, header prefixes and `=404` | `*`, `!Foo`, `+foo`, `-Server` | `Operator` |
| Braces and commas | `{`, `}`, `,` | `Punctuation` |
| Comments | `# comment` | `Comment::Single` |
| Other arguments | `localhost`, `/var/www` | `Name` |

### Plugin support

Plugin vocabulary is highlighted with the same tokens as the core syntax.
The lexer knows the directives, options and values documented by the twenty
most downloaded packages on the [Caddy download page](https://caddyserver.com/download)
(ranked by the download counts reported by `https://caddyserver.com/api/packages`
on 2026-09-03), plus the Coraza and caddy-waf web application firewalls:

| Package | Highlighted vocabulary |
| --- | --- |
| [caddy-security](https://github.com/greenpau/caddy-security) | `security`, `authenticate`, `authorize`, policy and portal sub-options |
| [caddy-dns/route53](https://github.com/caddy-dns/route53) | `dns route53` and its options |
| [caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare) | `dns cloudflare`, `api_token`, `zone_token` |
| [vulcain](https://github.com/dunglas/vulcain) | `vulcain`, `openapi_file`, `max_pushes`, `early_hints` |
| [mercure](https://mercure.rocks/docs/hub/config) | `mercure` and its options |
| [replace-response](https://github.com/caddyserver/replace-response) | `replace`, `re`, `stream`, `match` |
| [caddy2-filter](https://github.com/sjtug/caddy2-filter) | `filter`, `search_pattern`, `replacement`, `content_type` |
| [transform-encoder](https://github.com/caddyserver/transform-encoder) | `format transform`, `placeholder`, `unescape_strings` |
| [caddy-dns/duckdns](https://github.com/caddy-dns/duckdns) | `dns duckdns`, `override_domain`, `resolver` |
| [caddy2-proxyprotocol](https://github.com/mastercactapus/caddy2-proxyprotocol) | `proxy_protocol` listener wrapper options |
| [caddy-webdav](https://github.com/mholt/caddy-webdav) | `webdav`, `prefix` |
| [caddy-l4](https://github.com/mholt/caddy-l4) | `layer4`, connection matchers and handlers |
| [caddy-trace](https://github.com/greenpau/caddy-trace) | `trace` |
| [caddy-ratelimit](https://github.com/mholt/caddy-ratelimit) | `rate_limit`, `zone`, `window`, `events` and friends |
| [souin cache-handler](https://github.com/darkweak/souin/tree/master/plugins/caddy) | `cache` and its storage, key and CDN options |
| [caddy-dynamicdns](https://github.com/mholt/caddy-dynamicdns) | `dynamic_dns`, `provider`, `ip_source`, `versions` |
| [caddy-dns/rfc2136](https://github.com/caddy-dns/rfc2136) | `dns rfc2136`, `key_name`, `key_alg`, `server` |
| [caddy-exec](https://github.com/abiosoft/caddy-exec) | `exec`, `command`, `startup`, `shutdown` |
| [caddy-cloudflare-ip](https://github.com/WeidiDeng/caddy-cloudflare-ip) | `trusted_proxies cloudflare`, `interval` |
| [caddy-crowdsec-bouncer](https://github.com/hslatman/caddy-crowdsec-bouncer) | `crowdsec`, `appsec`, `api_url`, `api_key` |
| [coraza-caddy](https://github.com/corazawaf/coraza-caddy) | `coraza_waf`, `directives`, `load_owasp_crs`, `tx_id_req_header` |
| [caddy-waf](https://github.com/fabriziosalmi/caddy-waf) | `waf`, `rule_file`, `anomaly_threshold`, `rate_limit`, `tor` and friends |

Directives and options from other plugins are lexed safely as plain `Name`
tokens; they render as normal text and never produce error tokens.

## Development

Install dependencies:

```sh
bundle install
```

Run the test suite:

```sh
bundle exec rake
```

Start the visual preview server (available at http://localhost:9292):

```sh
bundle exec rake server
```

Run the terminal preview script:

```sh
ruby preview.rb
```

Enable debug mode to print each token and its value:

```sh
DEBUG=1 ruby preview.rb
```

### Iterative testing workflow

1. Run `bundle exec rake` to check for test failures and error tokens.
2. Start the server with `bundle exec rake server`.
3. In another terminal, check for error tokens in the rendered output:

   ```sh
   curl -s http://localhost:9292 | grep 'class="err"'
   ```

4. Fix any error tokens in `lib/rouge/lexers/caddyfile.rb`.
5. Repeat until no error tokens remain.

## License

MIT
