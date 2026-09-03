# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-03

### Added

- Initial release of the `rouge-lexer-caddyfile` gem, requiring Ruby 3.0 and
  Rouge 3.4 or newer
- `Rouge::Lexers::Caddyfile` lexer with tag `caddyfile`, alias `caddy`,
  filenames `Caddyfile`, `*.caddyfile` and `*.Caddyfile`, and MIME type
  `text/x-caddyfile`
- Auto-detection heuristics based on common Caddyfile patterns
- Token classification for the following categories

#### Directives and options

- Standard HTTP handler directives such as `reverse_proxy` and `file_server`
- Global options such as `email`, `servers` and `pki`
- Subdirectives and sub-options such as `lb_policy`, `output` and `timeouts`

#### Matchers

- Request matchers such as `path`, `header` and `expression`
- Response matchers `status` and `header`
- The `not` matcher and named matcher definitions and references (`@name`)

#### Structure

- Site addresses, including comma-separated lists, wildcards, schemes and ports
- Snippets `(name)`, named routes `&(name)` and `import` / `invoke` references
- Global options block, site blocks, directive blocks and matcher blocks

#### Values

- Placeholders `{...}` and environment variables `{$VAR:default}`
- Double-quoted tokens with `\"` escapes, backtick-quoted tokens and heredocs
- Integers, ratios, durations, sizes and status code classes such as `2xx`
- Boolean-like values, HTTP methods and enumerated option values
- Wildcard matcher `*`, header field prefixes and the `=404` fallback
- Line comments and escaped newlines

#### Plugins

- Directives, global options, subdirectives, matchers and values documented by
  the twenty most downloaded plugins on the Caddy download page, including
  caddy-security, the caddy-dns providers, mercure, vulcain, replace-response,
  caddy-l4, caddy-ratelimit, souin, caddy-dynamicdns, caddy-exec and the
  CrowdSec bouncer
- The `coraza_waf` and `waf` directives and sub-options of the coraza-caddy
  and caddy-waf web application firewalls

[0.1.0]: https://github.com/seanthegeek/rouge-lexer-caddyfile/releases/tag/v0.1.0
