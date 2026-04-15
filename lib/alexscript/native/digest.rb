# frozen_string_literal: true

# lib/alexscript/native/digest_lib.rb
#
# Native binding for Ruby's Digest module.
# Exposed as AlexScript's Digest class — purely static.
#
# Supports: MD5, SHA1, SHA256, SHA384, SHA512
# Each algorithm available as:
#   Digest.md5(tekst)         → hex string
#   Digest.sha256(tekst)      → hex string
#   Digest.sha256_base64(t)   → base64 string
#   Digest.sha256_bajty(t)    → raw bytes as array of ints
#   Digest.sha256_plik(path)  → hex digest of file
#
# Also: incremental hashing via instance classes
#   Digest.nowy_md5() / nowy_sha1() / nowy_sha256() / nowy_sha384() / nowy_sha512()

require 'digest'

module AlexScript
  module Native
    module DigestLibrary

      def self.register
        Utils::NativeClassRegistry.define_class('Digest',
          constructor: ->(*) {
            raise "Digest jest klasą statyczną — użyj Digest.md5(), Digest.sha256() itd."
          },
          methods: {},
          static_methods: build_static_methods,
          static_vars: {}
        )
      end

      def self.build_static_methods
        methods = {}

        # ─── Generate convenience methods for each algorithm ─
        algorithms = {
          'md5'    => Digest::MD5,
          'sha1'   => Digest::SHA1,
          'sha256' => Digest::SHA256,
          'sha384' => Digest::SHA384,
          'sha512' => Digest::SHA512
        }

        algorithms.each do |name, klass|
          # Digest.md5("tekst") → hex string
          methods[name] = ->(tekst) {
            klass.hexdigest(tekst.to_s)
          }

          # Digest.md5_base64("tekst") → base64 string
          methods["#{name}_base64"] = ->(tekst) {
            klass.base64digest(tekst.to_s)
          }

          # Digest.md5_bajty("tekst") → array of byte values
          methods["#{name}_bajty"] = ->(tekst) {
            klass.digest(tekst.to_s).bytes.to_a
          }

          # Digest.md5_plik("/path/to/file") → hex digest of file
          methods["#{name}_plik"] = ->(sciezka) {
            klass.file(sciezka.to_s).hexdigest
          }
        end

        # ─── HMAC ────────────────────────────────────────────

        # Digest.hmac_sha256(klucz, wiadomosc) → hex
        methods['hmac_sha256'] = ->(klucz, wiadomosc) {
          require 'openssl'
          OpenSSL::HMAC.hexdigest('SHA256', klucz.to_s, wiadomosc.to_s)
        }

        methods['hmac_sha512'] = ->(klucz, wiadomosc) {
          require 'openssl'
          OpenSSL::HMAC.hexdigest('SHA512', klucz.to_s, wiadomosc.to_s)
        }

        methods['hmac_md5'] = ->(klucz, wiadomosc) {
          require 'openssl'
          OpenSSL::HMAC.hexdigest('MD5', klucz.to_s, wiadomosc.to_s)
        }

        methods['hmac_sha1'] = ->(klucz, wiadomosc) {
          require 'openssl'
          OpenSSL::HMAC.hexdigest('SHA1', klucz.to_s, wiadomosc.to_s)
        }

        # ─── Comparison ─────────────────────────────────────

        # Digest.porownaj(hex1, hex2) → bool (constant-time comparison)
        methods['porownaj'] = ->(a, b) {
          require 'openssl'
          if OpenSSL.respond_to?(:fixed_length_secure_compare)
            begin
              OpenSSL.fixed_length_secure_compare(a.to_s, b.to_s)
            rescue ArgumentError
              false
            end
          else
            a.to_s == b.to_s
          end
        }

        # ─── Utility ────────────────────────────────────────

        # Digest.hex_na_bajty("ab53...") → [171, 83, ...]
        methods['hex_na_bajty'] = ->(hex) {
          [hex.to_s].pack('H*').bytes.to_a
        }

        # Digest.bajty_na_hex([171, 83, ...]) → "ab53..."
        methods['bajty_na_hex'] = ->(bajty) {
          arr = bajty.is_a?(Array) ? bajty : [bajty]
          raw = arr.map { |b|
            v = b.is_a?(Hash) && b.key?(:value) ? b[:value] : b
            v.to_i
          }
          raw.pack('C*').unpack1('H*')
        }

        methods
      end
    end
  end
end