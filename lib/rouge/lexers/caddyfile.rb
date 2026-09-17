# -*- coding: utf-8 -*- #
# frozen_string_literal: true

require 'set'

module Rouge
  module Lexers
    # Lexer for the Caddyfile, the configuration format used by the Caddy web
    # server (https://caddyserver.com/docs/caddyfile).
    #
    # A Caddyfile is line oriented: the first token on a line is a directive,
    # global option, subdirective or matcher name, and the remaining tokens on
    # the line are its arguments. Blocks are delimited by curly braces, with the
    # opening brace at the end of a line and the closing brace on a line by
    # itself. This lexer tracks that structure with a small set of states:
    #
    # * +:root+             - line starts inside site blocks, snippets and
    #                         directive blocks
    # * +:global_block+     - line starts inside the global options block
    # * +:matcher_block+    - line starts inside a named matcher block, and
    #                         (like +:log_block+ below) nests properly: each
    #                         block it opens (e.g. "not { }") pushes another
    #                         +:matcher_block+ frame rather than popping out
    # * +:log_block+        - line starts inside the log directive/option's
    #                         own block, at any nesting depth (its own top
    #                         level, or inside a nested "output { }" /
    #                         "sampling { }") — kept separate from +:root+,
    #                         which every *other* directive's block reuses
    #                         flatly, so that log's "format" subdirective
    #                         (see below) only gets special treatment inside
    #                         an actual log block, never a same-named
    #                         subdirective some other directive or plugin has
    # * +:log_format_block+, +:log_fields_block+, +:log_filter_block+ - line
    #                         starts inside log's "format filter { }" /
    #                         "format append { }", its nested "fields { }",
    #                         and a filter action's own "{ }" sub-block
    #                         (ip_mask's, cookie's, query's), respectively —
    #                         so their filter-action words only take
    #                         precedence there, not in every directive's
    #                         arguments
    # * +:address+          - the remainder of a site address line
    # * +:args+, +:gargs+, +:margs+, +:log_args+, +:format_args+,
    #   +:log_field_args+  - the arguments of a line in each block kind above
    #
    # Keywords come from the official Caddyfile documentation, plus the
    # documentation of the twenty most downloaded plugins on
    # https://caddyserver.com/download (see the +plugin_*+ sets).
    class Caddyfile < RegexLexer
      title 'Caddyfile'
      desc 'Caddyfile, the configuration format used by the Caddy web server (caddyserver.com)'
      tag 'caddyfile'
      aliases 'caddy'
      filenames 'Caddyfile', '*.caddyfile', '*.Caddyfile'
      mimetypes 'text/x-caddyfile'

      def self.detect?(text)
        return true if text =~ /^\s*(?:reverse_proxy|file_server|php_fastcgi|handle_path|acme_server|forward_auth|log_skip|basic_auth)\b/
        return true if text =~ /^\s*@[\w.-]+\s+(?:host|path|method|header|not|expression|client_ip|remote_ip|path_regexp)\b/

        false
      end

      # Standard HTTP handler directives.
      # Sources: https://caddyserver.com/docs/caddyfile/directives
      #          https://caddyserver.com/docs/caddyfile/concepts (invoke)
      #          https://caddyserver.com/docs/caddyfile (basicauth, skip_log)
      def self.directives
        @directives ||= Set.new %w(
          abort acme_server basic_auth basicauth bind copy_response
          copy_response_headers encode error file_server forward_auth fs
          handle handle_errors handle_path header import intercept invoke
          log log_append log_name log_skip map method metrics php_fastcgi
          push redir request_body request_header respond reverse_proxy
          rewrite root route skip_log templates tls tracing try_files uri
          vars
        )
      end

      # Options that may appear in the global options block.
      # Source: https://caddyserver.com/docs/caddyfile/options
      def self.global_options
        @global_options ||= Set.new %w(
          acme_ca acme_ca_root acme_dns acme_eab admin auto_https
          cert_issuer cert_lifetime debug default_bind default_sni dns ech
          email events fallback_sni filesystem grace_period http_port
          https_port key_type local_certs log metrics ocsp_interval
          ocsp_stapling on_demand_tls order persist_config pki
          preferred_chains renew_interval renewal_window_ratio servers
          shutdown_delay skip_install_trust storage storage_clean_interval
        )
      end

      # Subdirectives and sub-options that appear inside directive, option and
      # matcher blocks.
      # Sources: https://caddyserver.com/docs/caddyfile/options
      #          https://caddyserver.com/docs/caddyfile/matchers (file matcher)
      #          https://caddyserver.com/docs/caddyfile/concepts (lb_policy)
      #          https://caddyserver.com/docs/caddyfile/directives (handle_response)
      #          https://caddyserver.com/docs/caddyfile/directives/log
      #          https://caddyserver.com/docs/caddyfile/directives/tls
      #          https://caddyserver.com/docs/caddyfile/directives/reverse_proxy
      #          https://caddyserver.com/docs/caddyfile/directives/encode
      #          https://caddyserver.com/docs/caddyfile/directives/header
      #          https://caddyserver.com/docs/caddyfile/directives/file_server
      #          https://caddyserver.com/docs/caddyfile/directives/php_fastcgi
      def self.subdirectives
        @subdirectives ||= Set.new %w(
          0rtt allow alpn alt_http_port alt_tlsalpn_port any_common_name ask authority
          backup_time_format browse ca ca_root caller_key capture_stderr cert ciphers
          client_auth client_ip_headers compression cookie curves defer delete deny
          dial_fallback_delay dial_timeout dir disable_canonical_uris
          disable_http_challenge disable_tlsalpn_challenge dns
          dns_challenge_override_domain dns_ttl duration_format dynamic eab
          enable_full_duplex endpoints enforce_origin env exclude
          expect_continue_timeout fail_duration fallback_policy fields file file_limit
          filter first flush_interval folder force_automate format get_certificate
          handle_response handshake_timeout hash header_down header_up health_body
          health_fails health_follow_redirects health_headers health_interval
          health_method health_passes health_port health_request_body health_status
          health_timeout health_upstream health_uri hostnames http_redirect idle include
          index insecure_secrets_log insecure_skip_verify intermediate intermediate_cn
          intermediate_lifetime interval ip_mask ipv4 ipv6 issuer keepalive
          keepalive_count keepalive_idle keepalive_idle_conns keepalive_idle_conns_per_host
          keepalive_interval key key_id keys lb_policy lb_retries lb_retry_match
          lb_try_duration lb_try_interval level level_format level_key lifetime
          line_ending listener_wrappers load log_credentials mac_key
          maintenance_interval max_conns_per_host max_fails max_header_size
          max_response_header message_key minimum_length mode name name_key
          network_proxy no_hostname observe_catchall_hosts on on_demand origins otlp
          output pem pem_file per_host permission precompressed profile
          propagation_delay propagation_timeout protocols proxy_protocol query read_body
          read_buffer read_header read_timeout regexp rename renegotiation
          renewal_window_ratio replace replace_status request_buffers
          resolve_root_symlink resolvers response_buffers response_header_timeout
          reuse_private_keys reveal_symlinks roll_at roll_disabled roll_interval
          roll_keep roll_keep_for roll_local_time roll_minutes roll_size
          roll_uncompressed root root_cn root_common_name sampling server_name
          sign_with_root soft_start sort split split_path stacktrace_key status storage
          stream_close_delay stream_timeout strict_sni_host test_dir thereafter time_key
          time_local timeout timeouts tls tls_client_auth tls_curves tls_except_ports
          tls_insecure_skip_verify tls_renegotiation tls_server_name tls_timeout
          tls_trust_pool to trace transport trust_der trust_pool trusted_proxies
          trusted_proxies_strict trusted_proxies_unix trusted_roots try_files try_policy
          unhealthy_latency unhealthy_request_count unhealthy_status validity_days
          verifier versions wrap write write_buffer write_timeout
        )
      end

      # Request and response matcher names.
      # Sources: https://caddyserver.com/docs/caddyfile/matchers
      #          https://caddyserver.com/docs/caddyfile/response-matchers
      def self.matchers
        @matchers ||= Set.new %w(
          client_ip expression file header header_regexp host method path
          path_regexp protocol query remote_ip status vars vars_regexp
        )
      end

      # Boolean-like option values.
      # Sources: https://caddyserver.com/docs/caddyfile/options
      #          https://caddyserver.com/docs/caddyfile/matchers
      def self.constants
        @constants ||= Set.new %w(on off true false)
      end

      # HTTP methods used with the method matcher.
      # Source: https://caddyserver.com/docs/caddyfile/matchers
      def self.http_methods
        @http_methods ||= Set.new %w(DELETE GET HEAD OPTIONS POST PUT)
      end

      # Enumerated option and argument values.
      # Sources: https://caddyserver.com/docs/caddyfile/options
      #          https://caddyserver.com/docs/caddyfile/matchers
      #          https://caddyserver.com/docs/caddyfile/patterns (encode)
      #          https://caddyserver.com/docs/caddyfile/directives/log
      #          https://caddyserver.com/docs/caddyfile/directives/file_server
      #          https://caddyserver.com/docs/caddyfile/directives/basic_auth
      #          https://caddyserver.com/docs/caddyfile/directives/tls (client_auth,
      #          renegotiation, tls directive argument, trust pool providers, verifier
      #          loaders, issuer modules)
      #          https://caddyserver.com/docs/caddyfile/directives/reverse_proxy
      #          (network_proxy, proxy_protocol)
      def self.values
        @values ||= Set.new %w(
          DEBUG ERROR FATAL INFO PANIC WARN acme after append argon2id asc bcrypt before
          br console cookie delete desc disable_certs disable_redirects discard ed25519
          file file_system filter first first_exist first_exist_fallback folder freely
          grpc gzip h1 h2 h2c h3 hash http http_redirect https ignore
          ignore_loaded_certs inline insecure_off internal ip_mask json largest_size
          last leaf local most_recently_modified name namedirfirst net never none once
          p256 p384 pem pem_file pki_intermediate pki_root private_ranges proxy_protocol
          query regexp reject rename replace request require require_and_verify rsa2048
          rsa4096 size skip smallest smallest_size static stderr stdout storage
          tailscale time tls tls1.2 tls1.3 url use v1 v2 verify_if_given zerossl zstd
        )
      end

      # ----------------------------------------------------------------------
      # Plugin vocabulary. Each entry comes from the documentation of one of
      # the twenty most downloaded packages listed on
      # https://caddyserver.com/download (https://caddyserver.com/api/packages),
      # ranked by download count on 2026-09-03:
      #
      #  1. github.com/greenpau/caddy-security
      #     https://github.com/authcrunch/authcrunch.github.io (docs/authorize/syntax.md, assets/conf/local/Caddyfile)
      #  2. github.com/caddy-dns/route53          https://github.com/caddy-dns/route53
      #  3. github.com/caddy-dns/cloudflare       https://github.com/caddy-dns/cloudflare
      #  4. github.com/dunglas/vulcain/caddy      https://github.com/dunglas/vulcain/blob/main/docs/gateway/caddy.md
      #  5. github.com/dunglas/mercure/caddy      https://mercure.rocks/docs/hub/config
      #  6. github.com/caddyserver/replace-response https://github.com/caddyserver/replace-response
      #  7. github.com/sjtug/caddy2-filter        https://github.com/sjtug/caddy2-filter
      #  8. github.com/caddyserver/transform-encoder https://github.com/caddyserver/transform-encoder
      #  9. github.com/caddy-dns/duckdns          https://github.com/caddy-dns/duckdns
      # 10. github.com/mastercactapus/caddy2-proxyprotocol https://github.com/mastercactapus/caddy2-proxyprotocol
      # 11. github.com/mholt/caddy-webdav         https://github.com/mholt/caddy-webdav
      # 12. github.com/mholt/caddy-l4             https://github.com/mholt/caddy-l4/tree/master/docs
      # 13. github.com/greenpau/caddy-trace       https://github.com/greenpau/caddy-trace
      # 14. github.com/mholt/caddy-ratelimit      https://github.com/mholt/caddy-ratelimit
      # 15. github.com/darkweak/souin/plugins/caddy https://github.com/darkweak/souin/blob/master/plugins/caddy/README.md
      # 16. github.com/mholt/caddy-dynamicdns     https://github.com/mholt/caddy-dynamicdns
      # 17. github.com/caddy-dns/rfc2136          https://github.com/caddy-dns/rfc2136
      # 18. github.com/abiosoft/caddy-exec        https://github.com/abiosoft/caddy-exec
      # 19. github.com/WeidiDeng/caddy-cloudflare-ip https://github.com/WeidiDeng/caddy-cloudflare-ip
      # 20. github.com/hslatman/caddy-crowdsec-bouncer https://github.com/hslatman/caddy-crowdsec-bouncer
      #
      # Two web application firewalls were added on request (ranks 33 and
      # unranked on the same date):
      #
      #  *  github.com/corazawaf/coraza-caddy/v2    https://github.com/corazawaf/coraza-caddy
      #  *  github.com/fabriziosalmi/caddy-waf      https://github.com/fabriziosalmi/caddy-waf/tree/main/docs (all pages) and config.go
      # ----------------------------------------------------------------------

      # HTTP handler directives registered by plugins.
      def self.plugin_directives
        @plugin_directives ||= Set.new %w(
          appsec authenticate authorize cache coraza_waf crowdsec exec filter
          mercure rate_limit replace trace vulcain waf webdav
        )
      end

      # Global options (Caddy apps) registered by plugins.
      def self.plugin_global_options
        @plugin_global_options ||= Set.new %w(
          cache crowdsec dynamic_dns exec layer4 security
        )
      end

      # Subdirectives and sub-options documented by plugins.
      def self.plugin_subdirectives
        @plugin_subdirectives ||= Set.new %w(
          access_key_id acl action allowed_additional_status_codes
          allowed_http_verbs anomaly_threshold anonymous api api_key api_token
          api_url appsec_fail_open appsec_max_body_bytes appsec_max_timeout
          appsec_url args authentication authorization backend badger basepath
          block_asns block_countries cache_keys cache_name cdn check_interval
          cleanup_interval client_ip_header close command comment
          configuration content_type cookie cookie_name cors_origins crypto
          custom_response dashboard debug_logging default default_cache_control demo
          directives directory disable disable_body disable_host
          disable_method disable_metrics disable_query disable_scheme
          disable_streaming disable_vary dispatch_timeout distributed
          dns_blacklist_file domains dynamic dynamic_domains early_hints echo
          email enable enable_caddy_error enable_caddy_metrics
          enable_hard_fails enabled err_log etcd events exclude field
          foreground hash headers heartbeat hide hosted_zone_id hostname
          include inject interval ip_blacklist_file ip_source ipv4_prefix
          ipv6_prefix jitter key key_alg key_name links load_owasp_crs local
          log log_buffer log_json log_key log_level log_path log_severity
          match match_all_paths matching_timeout max_cacheable_body_bytes
          max_pushes max_request_body_size max_response_body_size max_retries
          max_size metrics_endpoint metrics_interval mode network nuts oauth
          olric openapi_file otter override_domain packet_conn_wrappers
          pass_thru password_recovery_enabled path paths placeholder
          postgres_tls prefix profile prometheus prometheus_endpoint
          protocol_version_compatibility provider proxy publish_origins
          publisher_jwks_url publisher_jwt purge_age re read_interval realm
          redact_sensitive_data redis regex region replacement requests
          resolver resolvers retry_interval retry_on_failure root route
          route53_max_wait rule_file search_pattern secret_access_key server
          service_id session_token set shutdown size
          skip_route53_sync_on_delete socks5 souin stale startup storage
          storers strategy stream subroute subscriber_jwks_url subscriber_jwt
          subscriber_list_cache_size subscriptions sweep_interval tee template
          throttle ticker_interval time_format timeout topic_selector_cache
          tor tor_ip_blacklist_file transform transport transport_url ttl
          tx_id_req_header ui unescape_strings update_interval update_only
          upstream url validate versions wait_for_route53_sync
          whitelist_countries whitelist_file whitelist_ip window
          write_interval write_timeout zone zone_id zone_token
        )
      end

      # Connection matchers registered by plugins (caddy-l4, crowdsec).
      def self.plugin_matchers
        @plugin_matchers ||= Set.new %w(
          clock crowdsec dns http local_ip openvpn postgres proxy_protocol
          quic rdp regexp remote_ip_list socks4 socks5 ssh tls winbox
          wireguard xmpp
        )
      end

      # Enumerated argument values documented by plugins.
      def self.plugin_values
        @plugin_values ||= Set.new %w(
          akamai bypass bypass_request bypass_response cloudflare debug duckdns
          error fastly hard info interface ipv4 ipv6 re rfc2136 route53
          simple_http soft souin stream strict transform upnp warn
        )
      end

      # {$ENV_VAR} or {$ENV_VAR:default}, substituted before parsing.
      ENV_VAR = %r/\{\$[^\s{}"`]+\}/

      # {placeholder} or {http.request.uri.path}, replaced at runtime.
      PLACEHOLDER = %r/\{[A-Za-z_%?][^\s{}"`]*\}/

      # <<MARKER ... MARKER heredoc; the closing marker must match the opener.
      HEREDOC = %r/<<([A-Za-z0-9_-]+)\r?\n(?:.*\r?\n)*?[ \t]*\1(?=\s|$)/

      # An opening brace that ends its line (optionally followed by a comment).
      OPEN_BLOCK = %r/\{(?=[ \t]*(?:#.*)?\r?$)/

      # A token boundary in argument position.
      BOUNDARY = %r/(?=[\s,{}]|$)/

      # The first word on a line.
      WORD = %r/[^\s{}"`#@,][^\s{}"`,]*/

      # An argument token: stops before placeholders, quotes and commas.
      ARG = %r/[^\s{"`#,][^\s{"`,]*/

      # Site addresses contain a dot, colon, slash or wildcard, or are localhost.
      ADDRESS = %r/[.:\/*]|\Alocalhost\z/

      # log's "format filter {" / "format append {": opens the field list
      # handled by :log_format_block. Matched only from :format_args (the
      # dedicated argument state pushed for the 'format' subdirective), not
      # from the generic :args every other subdirective and plugin construct
      # shares, so this never fires outside a log directive's format module.
      # Source: https://caddyserver.com/docs/caddyfile/directives/log
      LOG_FORMAT_BLOCK = %r/(filter|append)([ \t]*)(\{)(?=[ \t]*(?:#.*)?\r?$)/

      state :block_common do
        rule %r/\s+/, Text::Whitespace
        rule %r/#.*/, Comment::Single
      end

      # Line starts in site blocks, snippets and directive blocks.
      state :root do
        mixin :block_common
        rule %r/\}/, Punctuation
        rule OPEN_BLOCK, Punctuation, :global_block

        # (snippet) and &(named-route) definitions
        rule %r/&?\([^\s()]+\)/, Name::Function, :args

        # @name named matcher definitions
        rule %r/@[^\s{}"`#,]+/, Name::Label, :margs

        # {$ENV} used as a site address
        rule ENV_VAR, Name::Variable, :address

        # {block} inside a snippet
        rule PLACEHOLDER, Name::Variable::Magic, :args

        rule %r/"/ do
          token Str::Double
          push :args
          push :dq
        end

        rule %r/`/ do
          token Str::Backtick
          push :args
          push :bt
        end

        # import and invoke reference a snippet, named route or file
        rule %r/(import|invoke)([ \t]+)([^\s{}"`#,]+)/ do
          groups Keyword, Text::Whitespace, Name::Function
          push :args
        end

        rule WORD do |m|
          word = m[0]
          if word == 'log'
            # The log directive's own block gets a dedicated state
            # (:log_block) instead of reusing :root, so that its "format"
            # subdirective's filter-action precedence (see :format_args)
            # only ever applies inside an actual log block, not to a
            # same-named "format" subdirective some other directive or
            # plugin might have.
            token Keyword
            push :log_args
          elsif self.class.directives.include?(word) || self.class.plugin_directives.include?(word)
            token Keyword
            push :args
          elsif word == 'match' || word == 'lb_retry_match'
            # match blocks (rate_limit, replace) and reverse_proxy's
            # lb_retry_match (same matcher-token syntax as a named matcher,
            # minus the @name) both contain matchers.
            # Source: https://caddyserver.com/docs/caddyfile/directives/reverse_proxy
            token Name::Attribute
            push :margs
          elsif self.class.subdirectives.include?(word) || self.class.plugin_subdirectives.include?(word)
            token Name::Attribute
            push :args
          elsif self.class.global_options.include?(word) || self.class.plugin_global_options.include?(word)
            token Keyword::Declaration
            push :args
          elsif word =~ ADDRESS
            token Name::Namespace
            push :address
          else
            token Name
            push :args
          end
        end

        rule %r/[{},]/, Punctuation
      end

      # Line starts inside the global options block.
      state :global_block do
        mixin :block_common
        rule %r/\}/, Punctuation, :pop!
        rule OPEN_BLOCK, Punctuation, :global_block

        # @name matcher sets (layer4 servers)
        rule %r/@[^\s{}"`#,]+/, Name::Label, :margs

        rule ENV_VAR, Name::Variable, :gargs
        rule PLACEHOLDER, Name::Variable::Magic, :gargs

        rule %r/"/ do
          token Str::Double
          push :gargs
          push :dq
        end

        rule %r/`/ do
          token Str::Backtick
          push :gargs
          push :bt
        end

        rule WORD do |m|
          word = m[0]
          if self.class.global_options.include?(word) || self.class.plugin_global_options.include?(word)
            token Keyword::Declaration
          elsif self.class.subdirectives.include?(word) || self.class.plugin_subdirectives.include?(word)
            token Name::Attribute
          elsif word =~ ADDRESS
            # listener addresses of layer4 servers
            token Name::Namespace
          else
            token Name
          end
          push :gargs
        end

        rule %r/[{},]/, Punctuation
      end

      # Line starts inside a named matcher block.
      state :matcher_block do
        mixin :block_common
        rule %r/\}/, Punctuation, :pop!
        rule OPEN_BLOCK, Punctuation, :matcher_block
        rule ENV_VAR, Name::Variable, :margs
        rule PLACEHOLDER, Name::Variable::Magic, :margs

        rule %r/"/ do
          token Str::Double
          push :margs
          push :dq
        end

        rule %r/`/ do
          token Str::Backtick
          push :margs
          push :bt
        end

        rule WORD do |m|
          word = m[0]
          if word == 'not'
            token Keyword::Pseudo
          elsif self.class.matchers.include?(word) || self.class.plugin_matchers.include?(word)
            token Name::Builtin
          elsif self.class.subdirectives.include?(word) || self.class.plugin_subdirectives.include?(word)
            token Name::Attribute
          else
            token Name
          end
          push :margs
        end

        rule %r/[{},]/, Punctuation
      end

      # The remainder of a site address line.
      state :address do
        rule %r/[ \t\r]+/, Text::Whitespace
        rule %r/\n/, Text::Whitespace, :pop!
        rule %r/#.*/, Comment::Single
        rule OPEN_BLOCK, Punctuation, :pop!
        rule %r/,/, Punctuation
        rule ENV_VAR, Name::Variable
        rule %r/"/, Str::Double, :dq
        rule %r/`/, Str::Backtick, :bt
        rule %r/[^\s{}"`#,]+/, Name::Namespace
        rule %r/[{}]/, Punctuation
      end

      # Rules shared by every argument state.
      state :arg_common do
        rule %r/[ \t\r]+/, Text::Whitespace
        rule %r/\\\r?\n/, Str::Escape # escaped newline continues the line
        rule %r/\n/, Text::Whitespace, :pop!
        rule %r/#.*/, Comment::Single
        rule %r/,/, Punctuation

        rule %r/"/, Str::Double, :dq
        rule %r/`/, Str::Backtick, :bt
        rule HEREDOC, Str::Heredoc

        rule %r/\\\{/, Str::Escape # escaped placeholder brace
        rule ENV_VAR, Name::Variable
        rule PLACEHOLDER, Name::Variable::Magic
        rule %r/@[^\s{}"`#,]+/, Name::Label

        # * wildcard matcher, header field prefixes (!, +, -, ?, >) and =404
        rule %r/\*(?=[\s,]|$)/, Operator
        rule %r/[!+\-?>](?=[A-Za-z])/, Operator
        rule %r/(=)(\d+)#{BOUNDARY}/ do
          groups Operator, Num::Integer
        end

        rule %r/\d+\.\d+#{BOUNDARY}/, Num::Float
        rule %r/\d+#{BOUNDARY}/, Num::Integer
        # durations (10s, 7d), sizes (5MB) and status code classes (2xx)
        rule %r/\d+(?:\.\d+)?[a-zA-Z]+#{BOUNDARY}/, Num::Other

        # host:port
        rule %r/((?:[a-z]+:\/\/)?[^\s:{}"`#,]*)(:)(\d+)#{BOUNDARY}/ do
          groups Name, Punctuation, Num::Integer
        end
      end

      state :arg_fallback do
        rule %r/[{}]/, Punctuation
      end

      # Arguments of a line in a site, snippet or directive block.
      state :args do
        rule OPEN_BLOCK, Punctuation, :pop!
        mixin :arg_common
        rule ARG do |m|
          token classify_argument(m[0])
        end
        mixin :arg_fallback
      end

      # Arguments of a line directly inside log's own block: the initial
      # "log" line (from :root's word == 'log'), and "output"/"sampling",
      # log's other two subdirectives that can open a block. Routing all
      # three through this same state — instead of the generic :args, which
      # would pop out to whatever is *below* :log_block — means every block
      # they open pushes another :log_block frame, so each nested block's
      # own "}" pops back to the right level instead of leaking out of log's
      # block entirely (matching how :margs/:matcher_block nest "not { }").
      state :log_args do
        rule OPEN_BLOCK do
          token Punctuation
          pop!
          push :log_block
        end

        mixin :args
      end

      # Line starts inside a log directive/option's own block, at any
      # nesting depth (log's own top level, or inside a nested "output { }"
      # / "sampling { }"). Identical to :root except "format", "output" and
      # "sampling" are intercepted before :root's generic subdirective
      # dispatch would treat them like any other subdirective:
      # - "format" needs log-filter-action precedence (see :format_args)
      #   that must not leak to a same-named subdirective some other
      #   directive or plugin has outside an actual log block;
      # - "output"/"sampling" must route their own block back through
      #   :log_args (see above) rather than the generic :args, so this
      #   state's own "}" only fires for a "}" that's actually log's own
      #   (or one of these two subdirectives' own), never one belonging to
      #   a deeper, unrelated nested block.
      state :log_block do
        rule %r/\}/, Punctuation, :pop!

        rule %r/(?:output|sampling)#{BOUNDARY}/ do
          token Name::Attribute
          push :log_args
        end

        rule %r/format#{BOUNDARY}/ do
          token Name::Attribute
          push :format_args
        end

        mixin :root
      end

      # Arguments of log's "format" line specifically (pushed only from
      # :log_block's "format" rule above). Recognises "filter {" / "append {"
      # so their field list gets log-filter-action precedence; any other
      # argument (an encoder name with no block, e.g. plain "format json")
      # falls through to ordinary :args behavior.
      state :format_args do
        rule LOG_FORMAT_BLOCK do
          groups Name::Constant, Text::Whitespace, Punctuation
          pop!
          push :log_format_block
        end

        mixin :args
      end

      # Line starts inside "format filter { }" / "format append { }" (see
      # LOG_FORMAT_BLOCK). "fields { }" opens the same field list one level
      # deeper; "wrap" takes an ordinary encoder-module argument; anything
      # else is a bare <field> name using the fields-block-optional shortcut,
      # whose filter action follows in argument position.
      # Source: https://caddyserver.com/docs/caddyfile/directives/log
      state :log_format_block do
        mixin :block_common
        rule %r/\}/, Punctuation, :pop!

        rule %r/(fields)([ \t]*)(\{)(?=[ \t]*(?:#.*)?\r?$)/ do
          groups Name::Attribute, Text::Whitespace, Punctuation
          push :log_fields_block
        end

        rule WORD do |m|
          word = m[0]
          if word == 'wrap'
            token Name::Attribute
            push :args
          else
            token Name
            push :log_field_args
          end
        end
      end

      # Line starts inside log format filter/append's "fields { }" block:
      # every line is a bare <field> name, with its filter action following
      # in argument position.
      state :log_fields_block do
        mixin :block_common
        rule %r/\}/, Punctuation, :pop!

        rule WORD do |m|
          token Name
          push :log_field_args
        end
      end

      # Arguments of a <field> line inside log's format filter/append field
      # list — the only argument state that routes an opening block to
      # :log_filter_block instead of popping out to the enclosing state.
      # Every documented filter action that takes a block (ip_mask, cookie,
      # query) shares that same nested-block grammar, regardless of what
      # precedes the brace (ip_mask's block follows two extra arguments,
      # e.g. "ip_mask 16 32 { }", so matching specific words before the
      # brace — as an earlier version of this state did — missed it and let
      # the state fall back to the generic OPEN_BLOCK pop, which returned
      # all the way to :log_format_block and let its closing "}" pop back to
      # :root one level too early, mis-scoping everything that followed).
      state :log_field_args do
        rule OPEN_BLOCK do
          token Punctuation
          pop!
          push :log_filter_block
        end

        mixin :args
      end

      # Line starts inside a log filter action's own nested block: ip_mask's
      # "{ ipv4 <cidr> ipv6 <cidr> }", or cookie/query's
      # "{ delete|replace|hash <key> ... }" (see :log_field_args). Filter and
      # sub-option words are checked before falling back to a plain Name, so
      # e.g. "replace" reads as the filter action (Name::Attribute) rather
      # than the unrelated top-level plugin directive of the same name.
      state :log_filter_block do
        mixin :block_common
        rule %r/\}/, Punctuation, :pop!

        rule WORD do |m|
          word = m[0]
          if self.class.subdirectives.include?(word) || self.class.plugin_subdirectives.include?(word)
            token Name::Attribute
          else
            token Name
          end
          push :args
        end
      end

      # Arguments of a line in the global options block.
      state :gargs do
        rule OPEN_BLOCK do
          token Punctuation
          pop!
          push :global_block
        end
        mixin :arg_common
        rule ARG do |m|
          token classify_argument(m[0])
        end
        mixin :arg_fallback
      end

      # Arguments of a named matcher line or a line in a matcher block.
      state :margs do
        rule OPEN_BLOCK do
          token Punctuation
          pop!
          push :matcher_block
        end
        mixin :arg_common
        rule ARG do |m|
          word = m[0]
          if word == 'not'
            token Keyword::Pseudo
          elsif self.class.matchers.include?(word) || self.class.plugin_matchers.include?(word)
            token Name::Builtin
          else
            token classify_argument(word)
          end
        end
        mixin :arg_fallback
      end

      # Double-quoted token: only \" is an escape; other backslashes are literal.
      state :dq do
        rule %r/\\\\/, Str::Double
        rule %r/\\"/, Str::Escape
        rule %r/\\/, Str::Double
        rule %r/[^"\\]+/, Str::Double
        rule %r/"/, Str::Double, :pop!
      end

      # Backtick-quoted token: no escapes at all.
      state :bt do
        rule %r/[^`]+/, Str::Backtick
        rule %r/`/, Str::Backtick, :pop!
      end

      private

      def classify_argument(word)
        klass = self.class
        if klass.constants.include?(word)
          Keyword::Constant
        elsif klass.http_methods.include?(word) || klass.values.include?(word) || klass.plugin_values.include?(word)
          Name::Constant
        else
          Name
        end
      end
    end
  end
end
