# frozen_string_literal: true

# lib/alexscript/native/http_lib.rb
#
# Native binding for Ruby's Net::HTTP, exposed as AlexScript's Http class.
#
# Design:
#   - Purely static — convenience methods for all HTTP verbs
#   - Returns AS objects: {status, cialo, naglowki, wiadomosc, czy_sukces, ...}
#   - Auto HTTPS based on URL scheme
#   - Auto redirect following (configurable max)
#   - JSON helpers: get_json, post_json, put_json
#   - Form helpers: post_formularz
#   - URL utilities: koduj_url, dekoduj_url, parsuj_url, zbuduj_url
#   - File download: pobierz

require 'net/http'
require 'uri'
require 'json'
require 'openssl'

module AlexScript
  module Native
    module HttpLibrary

      def self.register
        Utils::NativeClassRegistry.define_class('Http',
          constructor: ->(*) {
            raise "Http jest klasą statyczną — użyj Http.get(), Http.post() itd."
          },
          methods: {},
          static_methods: build_static_methods,
          static_vars: {}
        )
      end

      def self.build_static_methods
        {
          # ─── Core HTTP verbs ───────────────────────────────

          'get' => ->(url, *args) {
            naglowki = args[0] || {}
            opcje = args[1] || {}
            execute_request(:get, url.to_s, nil, naglowki, opcje)
          },

          'post' => ->(url, *args) {
            cialo = args[0]
            naglowki = args[1] || {}
            opcje = args[2] || {}
            execute_request(:post, url.to_s, cialo, naglowki, opcje)
          },

          'put' => ->(url, *args) {
            cialo = args[0]
            naglowki = args[1] || {}
            opcje = args[2] || {}
            execute_request(:put, url.to_s, cialo, naglowki, opcje)
          },

          'patch' => ->(url, *args) {
            cialo = args[0]
            naglowki = args[1] || {}
            opcje = args[2] || {}
            execute_request(:patch, url.to_s, cialo, naglowki, opcje)
          },

          'delete' => ->(url, *args) {
            naglowki = args[0] || {}
            opcje = args[1] || {}
            execute_request(:delete, url.to_s, nil, naglowki, opcje)
          },

          'head' => ->(url, *args) {
            naglowki = args[0] || {}
            opcje = args[1] || {}
            execute_request(:head, url.to_s, nil, naglowki, opcje)
          },

          'options' => ->(url, *args) {
            naglowki = args[0] || {}
            execute_request(:options, url.to_s, nil, naglowki, {})
          },

          # ─── JSON convenience ──────────────────────────────

          'get_json' => ->(url, *args) {
            naglowki = extract_headers(args[0])
            naglowki['Accept'] = 'application/json'
            opcje = args[1] || {}
            odpowiedz = execute_request(:get, url.to_s, nil, naglowki, opcje)
            begin
              JSON.parse(extract_body(odpowiedz))
            rescue JSON::ParserError => e
              raise "Odpowiedź nie jest poprawnym JSON: #{e.message}"
            end
          },

          'post_json' => ->(url, dane, *args) {
            naglowki = extract_headers(args[0])
            naglowki['Content-Type'] = 'application/json'
            naglowki['Accept'] = 'application/json'
            cialo = dane.is_a?(String) ? dane : convert_to_json(dane)
            opcje = args[1] || {}
            odpowiedz = execute_request(:post, url.to_s, cialo, naglowki, opcje)
            begin
              JSON.parse(extract_body(odpowiedz))
            rescue JSON::ParserError => e
              raise "Odpowiedź nie jest poprawnym JSON: #{e.message}"
            end
          },

          'put_json' => ->(url, dane, *args) {
            naglowki = extract_headers(args[0])
            naglowki['Content-Type'] = 'application/json'
            naglowki['Accept'] = 'application/json'
            cialo = dane.is_a?(String) ? dane : convert_to_json(dane)
            opcje = args[1] || {}
            odpowiedz = execute_request(:put, url.to_s, cialo, naglowki, opcje)
            begin
              JSON.parse(extract_body(odpowiedz))
            rescue JSON::ParserError
              extract_body(odpowiedz)
            end
          },

          # ─── Form data ─────────────────────────────────────

          'post_formularz' => ->(url, dane, *args) {
            naglowki = extract_headers(args[0])
            opcje = args[1] || {}
            form_data = convert_to_form(dane)
            naglowki['Content-Type'] = 'application/x-www-form-urlencoded'
            execute_request(:post, url.to_s, form_data, naglowki, opcje)
          },

          # ─── Download ──────────────────────────────────────

          'pobierz' => ->(url, sciezka) {
            uri = URI.parse(url.to_s)
            http = build_http(uri, {})
            request = Net::HTTP::Get.new(uri)
            http.start do |h|
              h.request(request) do |response|
                File.open(sciezka.to_s, 'wb') do |f|
                  response.read_body { |chunk| f.write(chunk) }
                end
              end
            end
            true
          },

          # ─── URL utilities ─────────────────────────────────

          'koduj_url' => ->(tekst) {
            URI.encode_www_form_component(tekst.to_s)
          },

          'dekoduj_url' => ->(tekst) {
            URI.decode_www_form_component(tekst.to_s)
          },

          'parsuj_url' => ->(url) {
            uri = URI.parse(url.to_s)
            {
              'schemat' => uri.scheme || '',
              'host' => uri.host || '',
              'port' => uri.port || 0,
              'sciezka' => uri.path || '',
              'zapytanie' => uri.query || '',
              'fragment' => uri.fragment || '',
              'uzytkownik' => uri.user || '',
              'haslo' => uri.password || ''
            }
          },

          'zbuduj_url' => ->(schemat, host, *args) {
            port = args[0]
            sciezka = args[1] || '/'
            zapytanie = args[2]
            uri = URI::Generic.build(
              scheme: schemat.to_s,
              host: host.to_s,
              port: port ? port.to_i : nil,
              path: sciezka.to_s,
              query: zapytanie ? zapytanie.to_s : nil
            )
            uri.to_s
          },

          'zbuduj_zapytanie' => ->(params) {
            ruby_params = convert_to_form_hash(params)
            URI.encode_www_form(ruby_params)
          },

          'parsuj_zapytanie' => ->(tekst) {
            URI.decode_www_form(tekst.to_s).to_h
          }
        }
      end

      private

      def self.execute_request(method, url_str, body, headers, options)
        uri = URI.parse(url_str)
        http = build_http(uri, options)
        request = build_request(method, uri, body, headers)

        response = http.start { |h| h.request(request) }

        max_redirects = extract_opt(options, 'przekierowania', 5)
        redirect_count = 0

        while response.is_a?(Net::HTTPRedirection) && redirect_count < max_redirects
          location = response['location']
          new_uri = URI.parse(location)
          new_uri = URI.join(uri, location) unless new_uri.host
          http = build_http(new_uri, options)
          request = build_request(:get, new_uri, nil, headers)
          response = http.start { |h| h.request(request) }
          uri = new_uri
          redirect_count += 1
        end

        build_response(response)
      end

      def self.build_http(uri, options)
        http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          store = OpenSSL::X509::Store.new
          store.set_default_paths
          http.cert_store = store
        end
        timeout = extract_opt(options, 'timeout', 30)
        http.open_timeout = timeout
        http.read_timeout = timeout
        http.write_timeout = timeout if http.respond_to?(:write_timeout=)
        http
      end

      def self.build_request(method, uri, body, headers)
        path = uri.request_uri
        request = case method
                  when :get     then Net::HTTP::Get.new(path)
                  when :post    then Net::HTTP::Post.new(path)
                  when :put     then Net::HTTP::Put.new(path)
                  when :patch   then Net::HTTP::Patch.new(path)
                  when :delete  then Net::HTTP::Delete.new(path)
                  when :head    then Net::HTTP::Head.new(path)
                  when :options then Net::HTTP::Options.new(path)
                  else raise "Nieobsługiwana metoda HTTP: #{method}"
                  end
        apply_headers(request, headers)
        request.body = body.is_a?(String) ? body : body.to_s if body
        request
      end

      def self.apply_headers(request, headers)
        return unless headers.is_a?(Hash)
        headers.each do |k, v|
          val = v.is_a?(Hash) && v.key?(:value) ? v[:value] : v
          request[k.to_s] = val.to_s
        end
      end

      def self.build_response(response)
        resp_headers = {}
        response.each_header { |k, v| resp_headers[k] = v }
        status_code = response.code.to_i
        {
          'status' => status_code,
          'wiadomosc' => response.message || '',
          'cialo' => response.body || '',
          'naglowki' => resp_headers,
          'czy_sukces' => status_code >= 200 && status_code < 300,
          'czy_przekierowanie' => status_code >= 300 && status_code < 400,
          'czy_blad_klienta' => status_code >= 400 && status_code < 500,
          'czy_blad_serwera' => status_code >= 500 && status_code < 600
        }
      end

      def self.extract_headers(h)
        return {} unless h.is_a?(Hash)
        result = {}
        h.each { |k, v| result[k.to_s] = v.is_a?(Hash) && v.key?(:value) ? v[:value].to_s : v.to_s }
        result
      end

      def self.extract_body(obj)
        return '' unless obj.is_a?(Hash)
        v = obj['cialo']
        v.is_a?(Hash) && v.key?(:value) ? v[:value].to_s : v.to_s
      end

      def self.extract_opt(options, key, default)
        return default unless options.is_a?(Hash)
        v = options[key]
        return default unless v
        v.is_a?(Hash) && v.key?(:value) ? (v[:value] || default) : v
      end

      def self.convert_to_json(dane)
        return JSON.generate(dane) unless dane.is_a?(Hash)
        result = {}
        dane.each do |k, v|
          if v.is_a?(Hash) && v.key?(:type)
            result[k.to_s] = Utils::NativeTypeConverter.to_ruby(v[:type], v[:value])
          elsif v.is_a?(Hash) && v.key?(:value)
            result[k.to_s] = v[:value]
          else
            result[k.to_s] = v
          end
        end
        JSON.generate(result)
      end

      def self.convert_to_form(dane)
        URI.encode_www_form(convert_to_form_hash(dane))
      end

      def self.convert_to_form_hash(dane)
        result = {}
        return result unless dane.is_a?(Hash)
        dane.each { |k, v| result[k.to_s] = v.is_a?(Hash) && v.key?(:value) ? v[:value].to_s : v.to_s }
        result
      end
    end
  end
end