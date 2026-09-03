# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## Commands

```sh
bundle config set --local path vendor/bundle && bundle install  # Install dependencies
bundle exec rake        # Run the test suite (default task)
bundle exec rake server # Start visual preview server at http://localhost:9292
ruby preview.rb         # Terminal preview using Github theme
DEBUG=1 ruby preview.rb # Print each token and its type
```

To check for error tokens via the preview server:

```sh
curl -s http://localhost:9292 | grep 'class="err"'
```

## Architecture

This is a Rouge lexer plugin gem for the Caddyfile configuration format used by
the Caddy web server. Rouge is the default syntax highlighter used by
Jekyll/GitHub Pages.

**Key files:**

- [lib/rouge/lexers/caddyfile.rb](lib/rouge/lexers/caddyfile.rb) — The lexer implementation (`Rouge::Lexers::Caddyfile < RegexLexer`)
- [lib/rouge/lexer/caddyfile.rb](lib/rouge/lexer/caddyfile.rb) — Entry point that `require`s the lexer; this is what consumers load
- [spec/rouge_lexer_caddyfile_spec.rb](spec/rouge_lexer_caddyfile_spec.rb) — Minitest test suite
- [spec/demos/caddyfile](spec/demos/caddyfile) — Short demo snippet used in tests and Rouge's demo pages
- [spec/visual/samples/caddyfile](spec/visual/samples/caddyfile) — Comprehensive sample used for visual testing and error-token checks

**Lexer structure:** The lexer uses class-level `Set` caches for keyword
classification. The `:root` state matches tokens in priority order; a catch-all
`\w+` rule does set-membership lookups to assign the correct token type. Sub-states
handle comments, strings, and any other paired constructs.

## Design notes

Why the lexer is built the way it is. Read this before changing states or
token assignments so the reasoning survives the change.

### Line-oriented states instead of a flat rule list

- A Caddyfile is line oriented: the first token on a line is a directive,
  option, subdirective or matcher name, and everything after it is arguments.
  Which set the first word belongs to depends on the enclosing block, so the
  lexer tracks block kind with states: `:root` (site, snippet and directive
  blocks), `:global_block` (the `{ }` options block) and `:matcher_block`
  (`@name { }`, `not { }`, `file { }`, `match { }`). Each has a matching
  argument state (`:args`, `:gargs`, `:margs`) that pops on newline.
- Rouge's `StringScanner` treats the scan pointer as the start of the string,
  so `^` and lookbehind cannot detect "start of line". That is why line starts
  are handled by dedicated states rather than anchors.
- `:root` never pops on `}` because a single-site Caddyfile may omit braces
  entirely; only the global and matcher block states track their own `}`.
- A line-start word is looked up in this order: directives, `match`,
  subdirectives, global options, then the address heuristic. Directives win
  because `header`, `root`, `log`, `tls` and `dns` are also matcher, option or
  sub-option names; the block states flip the order where the context is
  unambiguous (matchers first inside matcher blocks, options first inside the
  global block).
- Site addresses are recognised by shape, not by a word list: a first word
  containing `.`, `:`, `/` or `*`, or equal to `localhost`, is an address.
  Anything else unknown is `Name`, so an unrecognised plugin directive renders
  as plain text and never as an error.

### Token choices that override the template table

- Directives are `Keyword`, global options `Keyword::Declaration`, and
  subdirectives `Name::Attribute`, so the three levels of the config get three
  colours in most themes while all still read as configuration keys.
- Matcher names are `Name::Builtin` because they behave like predicates, and
  `not` is `Keyword::Pseudo` because it is the language's only operator word.
- Site addresses are `Name::Namespace`, named matchers `Name::Label`, and
  snippets, named routes and `import` / `invoke` targets `Name::Function`,
  matching how Rouge's INI and Nginx lexers treat section headers and macros.
- The Caddyfile has no single-quoted strings; backticks take that role and are
  `Str::Backtick`. Heredocs are one `Str::Heredoc` token, matched with a
  backreference so the closing marker must equal the opener.
- Inside double quotes only `\"` is an escape and `\\` is two literal
  backslashes, mirroring `caddyconfig/caddyfile/lexer.go`.
- Numbers only match whole tokens (`10s`, `5MB`, `2xx` are `Num::Other`), so
  IP addresses and CIDRs stay single `Name` tokens. `host:port` splits into
  `Name`, `Punctuation`, `Num::Integer`.
- A `#` starts a comment only at token start, because Caddy allows `#` inside
  URLs and other unquoted values.

### Plugin vocabulary is a deliberate middle ground

- Colouring every unknown first word as a keyword would also colour typos and
  lose the "unknown means uncoloured" signal. Leaving plugins uncoloured left
  common real-world configs looking flat. The compromise is explicit sets for
  the twenty most downloaded packages, sourced from each plugin's own docs and
  mapped to the same tokens as core syntax. Plugins outside the top twenty are
  added only on request (so far: coraza-caddy and caddy-waf).
- Plugin sets are kept separate from core sets so provenance stays auditable;
  the lookup code checks both.
- Known limits: generic words from caddy-security's grammar (`set`, `default`,
  `enable`, `match`) are coloured wherever they start a line in a block, and
  its inline words (`with`, `roles`, `verify`) are left plain on purpose.

## Caddyfile references

Use *ONLY* official documentation, *NOT* from memory, training, or inference.

### Documentation

**MANDATORY: Before writing or modifying the lexer, you MUST fetch and read every
URL in this list.** This is not background reading — it is a required prerequisite
step. Fetch each page, extract the keywords or function names, and verify them
against the lexer before declaring any work complete.

https://caddyserver.com/docs/caddyfile
https://caddyserver.com/docs/caddyfile/concepts
https://caddyserver.com/docs/caddyfile/options
https://caddyserver.com/docs/caddyfile/directives
https://caddyserver.com/docs/caddyfile/matchers
https://caddyserver.com/docs/caddyfile/response-matchers
https://caddyserver.com/docs/caddyfile/patterns

Or the Caddy source code at https://github.com/caddyserver/caddy

### Plugin documentation

The `plugin_*` sets in the lexer cover the twenty most downloaded packages on
https://caddyserver.com/download, ranked by the `downloads` field of
https://caddyserver.com/api/packages. Every plugin keyword must trace to one of
these pages; re-rank the packages and refresh the list when adding plugins.

https://github.com/authcrunch/authcrunch.github.io/blob/main/docs/authorize/syntax.md
https://github.com/authcrunch/authcrunch.github.io/blob/main/assets/conf/local/Caddyfile
https://github.com/caddy-dns/route53
https://github.com/caddy-dns/cloudflare
https://github.com/dunglas/vulcain/blob/main/docs/gateway/caddy.md
https://mercure.rocks/docs/hub/config
https://github.com/caddyserver/replace-response
https://github.com/sjtug/caddy2-filter
https://github.com/caddyserver/transform-encoder
https://github.com/caddy-dns/duckdns
https://github.com/mastercactapus/caddy2-proxyprotocol
https://github.com/mholt/caddy-webdav
https://github.com/mholt/caddy-l4/blob/master/docs/servers.md
https://github.com/mholt/caddy-l4/blob/master/docs/routes.md
https://github.com/mholt/caddy-l4/blob/master/docs/matchers.md
https://github.com/mholt/caddy-l4/blob/master/docs/handlers.md
https://github.com/greenpau/caddy-trace
https://github.com/mholt/caddy-ratelimit
https://github.com/darkweak/souin/blob/master/plugins/caddy/README.md
https://github.com/mholt/caddy-dynamicdns
https://github.com/caddy-dns/rfc2136
https://github.com/abiosoft/caddy-exec
https://github.com/WeidiDeng/caddy-cloudflare-ip
https://github.com/hslatman/caddy-crowdsec-bouncer

Two web application firewalls were added on request outside the top twenty:

https://github.com/corazawaf/coraza-caddy
https://github.com/fabriziosalmi/caddy-waf
https://github.com/fabriziosalmi/caddy-waf/tree/main/docs (every page; configuration.md lists the directives, ratelimit.md and dashboard.md add sub-options)
https://github.com/fabriziosalmi/caddy-waf/blob/main/config.go (the `directiveHandlers` map is the authoritative directive list)

## Rouge references

- Lexer development guide: <https://github.com/rouge-ruby/rouge/blob/main/docs/LexerDevelopment.md>
- Existing lexers for reference: <https://github.com/rouge-ruby/rouge/tree/main/lib/rouge/lexers>
- JSON lexer (simple example): <https://github.com/rouge-ruby/rouge/blob/main/lib/rouge/lexers/json.rb>
- SQL lexer (keyword-heavy analog): <https://github.com/rouge-ruby/rouge/blob/main/lib/rouge/lexers/sql.rb>
- Token types: <https://github.com/rouge-ruby/rouge/blob/main/lib/rouge/token.rb>

## Verification workflow (MANDATORY — do this BEFORE adding anything)

Before writing or modifying the lexer, fetch **every URL in the documentation
list** above. Do not begin implementation until all pages have been read.

Before adding ANY individual keyword, function, or syntax element:

1. **Fetch the relevant documentation page** using the WebFetch tool or curl.
2. **Extract and confirm** the element exists in the fetched content. Do not rely
   on training data, memory, or assumptions about what "should" exist.
3. **Only add** elements that appear in the fetched content. **Only remove**
   elements confirmed absent.

### What NOT to do

- **Do NOT add keywords or syntax from training data or memory.** Every addition
  must be traced to a specific URL from the reference list in this file.
- **Do NOT use preview/beta features** unless explicitly asked. Only add GA
  (generally available) features.
- **Do NOT fabricate or modify reference URLs.** Use ONLY the exact URLs listed
  in this file. If a URL doesn't work, say so — do not guess an alternative.
- **Do NOT assume a function exists because a similar one does.**

### Self-verification

After making changes, verify correctness by **re-fetching the source documentation**
and confirming every added element appears in the fetched HTML. Do not verify by
re-reading your own changes.

### Constraints (applies to all work)

- **No hallucinated syntax.** Every keyword, function, operator, and language
  construct in the lexer must come from the official documentation listed above.
- **Follow Rouge conventions exactly.** Study existing lexers (especially JSON and
  SQL) for patterns. Don't invent novel approaches.
- **The Error token count is the ground truth.** The visual preview server is the
  authoritative test. `bundle exec rake` passing is necessary but not sufficient —
  you must also have zero `class="err"` spans.
- **Iterate until clean.** Do not declare the task complete until both
  `bundle exec rake` passes AND the Error token count is zero for both demo and
  visual sample.
- **Update the visual sample** (`spec/visual/samples/caddyfile`)
  whenever new tokens are added to the lexer, so every token type has coverage.

The markdownlint configuration in [.vscode/settings.json](.vscode/settings.json)
sets `MD024` to `siblings_only: true`, allowing repeated heading text under
different parent headings (e.g. `### Added` appearing under multiple version
sections in the changelog).

## Project notes

Facts that are not derivable from the code and are easy to lose when the
shared `rouge-lexer-<lang>` template is copied to another language.

- The entry point must stay at `lib/rouge/lexer/caddyfile.rb`. Bundler's
  auto-require of a gem named `rouge-lexer-caddyfile` falls back to
  `rouge/lexer/caddyfile` when the dashed name fails, which is how
  `group :jekyll_plugins` loads the lexer. No `lib/rouge-lexer-caddyfile.rb`
  shim is needed.
- `Rouge::Lexer.find` returns the lexer class, so `config.ru` must call
  `lexer.tag` and `lexer.title`, not `lexer.class.tag`. The template originally
  had the latter and raised `NoMethodError` under rackup.
- Rack 3 (rackup 2.x with puma) rejects a string status; `config.ru` must
  return the integer `200` or `Rack::Lint` fails the request.
- The demo must stay 5-15 lines and the visual sample 50-200 lines. The tests
  only check input reconstruction and zero error tokens, so check line counts
  with `wc -l` by hand.
- Plugin coverage is the top twenty packages by the `downloads` field of
  https://caddyserver.com/api/packages, which is the download page's data
  source, ranked on 2026-09-03. Re-rank from that endpoint when refreshing.
- Rouge 3.4.0 is the oldest release with `Name::Variable::Magic`, which the
  placeholder token uses; the gemspec minimum is `>= 3.4` for that reason and
  the suite passes on 3.4.0, 3.30.0, 4.7.0 and 5.1.0.
- The Mercure config page renders its directive table as HTML; a text dump
  runs the cells together, so verify its keywords against the raw HTML.

## Continuous integration and releases

GitHub Actions workflows live in [.github/workflows/](.github/workflows/):

- [test.yml](.github/workflows/test.yml) runs `bundle exec rake` on every Ruby
  from 3.0 to 3.4 against Rouge `~> 3.4`, `~> 4.0` and `>= 5.0`, then fails if
  the demo or visual sample produce any error tokens. The Gemfile reads
  `ROUGE_VERSION` to pin Rouge; unset locally, it installs the newest.
- [markdownlint.yml](.github/workflows/markdownlint.yml) lints every Markdown
  file with the rules in [.markdownlint.json](.markdownlint.json) (line length
  off, duplicate headings allowed under different parents).
- [release.yml](.github/workflows/release.yml) runs on tags matching `v*`. It
  checks the tag against the gemspec version, runs the tests, publishes to
  RubyGems with trusted publishing (OIDC, no API key secret) and creates a
  GitHub release with the built gem attached. The repository and workflow must
  be registered once as a trusted publisher on rubygems.org.
- [dependabot.yml](.github/dependabot.yml) keeps gems and action versions
  current with weekly pull requests.

To release: bump `s.version` in the gemspec, add the version section to the
changelog, commit, then `git tag vX.Y.Z && git push --tags`.

## Changelog

The changelog ([CHANGELOG.md](CHANGELOG.md)) follows the
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). When updating the
changelog:

- Use `## [version] - YYYY-MM-DD` for release headings
- Use `### Added`, `### Changed`, `### Removed` as second-level section headings
- Use `#### Category name` as optional third-level headings within a section
- Ensure blank lines surround all headings to satisfy markdownlint
