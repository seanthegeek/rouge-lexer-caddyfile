# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-09-18

### Added

#### Directives and options

- `log` subdirectives `hostnames`, `no_hostname` and `sampling` (with
  `interval`, `first` and `thereafter`); the file output options `mode`,
  `roll_disabled`, `roll_size`, `roll_interval`, `roll_minutes`, `roll_at`,
  `roll_uncompressed`, `roll_local_time`, `roll_keep`, `roll_keep_for` and
  `backup_time_format`; the `net` output options `dial_timeout` and
  `soft_start`; the `filter` and `append` format modules with `fields`,
  `wrap` and the filter actions `delete`, `rename`, `replace`, `ip_mask`,
  `ipv4`, `ipv6`, `cookie`, `regexp`, `hash` and `query`; and the encoder
  options `message_key`, `level_key`, `time_key`, `name_key`, `caller_key`,
  `stacktrace_key`, `line_ending`, `time_local`, `duration_format` and
  `level_format`
- `tls` subdirectives `ciphers`, `curves`, `alpn`, `load`, `ca_root`,
  `propagation_timeout`, `propagation_delay`, `dns_ttl`,
  `dns_challenge_override_domain`, `eab`, `reuse_private_keys`,
  `client_auth`, `get_certificate`, `insecure_secrets_log`,
  `force_automate` and `protocols`, plus the trust pool, verifier and ACME
  issuer sub-options such as `trust_pool`, `verifier`, `trust_der`,
  `authority`, `keys`, `endpoints`, `insecure_skip_verify`,
  `handshake_timeout`, `server_name`, `renegotiation`, `dir`, `test_dir`,
  `disable_http_challenge`, `disable_tlsalpn_challenge`, `alt_http_port`,
  `alt_tlsalpn_port`, `trusted_roots`, `profile`, `validity_days`,
  `lifetime`, `sign_with_root`, `pem_file`, `file`, `folder`, `pem` and
  `storage`
- `reverse_proxy` subdirectives `to`, `dynamic`, `lb_retries`,
  `lb_try_duration`, `lb_try_interval` and `lb_retry_match`; the active and
  passive health check options (`health_uri`, `health_upstream`,
  `health_port`, `health_interval`, `health_passes`, `health_fails`,
  `health_timeout`, `health_method`, `health_status`,
  `health_request_body`, `health_body`, `health_follow_redirects`,
  `health_headers`, `fail_duration`, `max_fails`, `unhealthy_status`,
  `unhealthy_latency` and `unhealthy_request_count`); the streaming options
  `flush_interval`, `request_buffers`, `response_buffers`, `stream_timeout`
  and `stream_close_delay`; `header_up`, `header_down` and
  `replace_status`; and the full `transport http` block (`read_buffer`,
  `write_buffer`, `max_response_header`, `proxy_protocol`, `dial_timeout`,
  `dial_fallback_delay`, `response_header_timeout`,
  `expect_continue_timeout`, `resolvers`, `tls_client_auth`,
  `tls_insecure_skip_verify`, `tls_curves`, `tls_timeout`,
  `tls_trust_pool`, `tls_server_name`, `tls_renegotiation`,
  `tls_except_ports`, `keepalive`, `keepalive_idle_conns`,
  `keepalive_idle_conns_per_host`, `versions`, `compression`,
  `max_conns_per_host` and `network_proxy`)
- `file_server` subdirectives `browse`, `precompressed`,
  `disable_canonical_uris`, `reveal_symlinks`, `sort`, `file_limit` and
  `status`
- `php_fastcgi` subdirectives `split`, `index`, `env`,
  `resolve_root_symlink`, `capture_stderr`, `dial_timeout`, `read_timeout`
  and `write_timeout`
- `encode` subdirective `minimum_length` and `header` subdirective `defer`

#### Values

- `log` output and format module names `stderr`, `discard`, `net`,
  `console`, `filter` and `append`, and the filter action words in argument
  position
- `tls` client authentication modes `request`, `require_and_verify` and
  `verify_if_given`; renegotiation modes `never`, `once` and `freely`; trust
  pool providers `inline`, `pki_root`, `pki_intermediate` and `storage`; the
  `leaf` verifier; the `internal` and `tailscale` issuer and certificate
  getter modules; and the protocol versions `tls1.2` and `tls1.3`
- `reverse_proxy` `network_proxy` modules `none` and `url`, and
  `proxy_protocol` versions `v1` and `v2`
- `file_server` sort keys `asc`, `desc`, `size`, `time`, `namedirfirst` and
  `name`
- `basic_auth` hash algorithms `argon2id` and `bcrypt`

#### Tests

- Regression tests for the overlap-sensitive words `first`, `status`,
  `method` and `replace`, for nested `log` block scoping, and for the
  `fields { }` wrapper and its shortcut form classifying identically

### Changed

- The `log` directive and the global `log` option now lex their blocks with
  dedicated states, so nested `output`, `sampling`, encoder and
  `format filter` / `format append` blocks close at the right depth and the
  filter action words only take precedence inside a real `log` block
- `lb_retry_match` blocks are lexed as matcher blocks, so `method` and other
  matcher names inside them resolve as matchers rather than directives
- The visual sample now covers the new `log`, `tls` and `reverse_proxy`
  syntax, and the documented line limit for it was raised to 300 lines

#### Continuous integration

- The test, markdownlint and release workflows use `actions/checkout` v7
  instead of v4

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

[0.2.0]: https://github.com/seanthegeek/rouge-lexer-caddyfile/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/seanthegeek/rouge-lexer-caddyfile/releases/tag/v0.1.0
