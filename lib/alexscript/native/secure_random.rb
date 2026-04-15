# frozen_string_literal: true

# lib/alexscript/native/securerandom_lib.rb
#
# Native binding for Ruby's SecureRandom module.
# Exposed as AlexScript's SecureRandom class — purely static.
#
# Covers:
#   SecureRandom.hex(n)             → random hex string (n bytes → 2n chars)
#   SecureRandom.base64(n)          → random base64 string
#   SecureRandom.urlsafe_base64(n)  → URL-safe base64
#   SecureRandom.uuid()             → UUID v4
#   SecureRandom.alfanumeryczny(n)  → alphanumeric string
#   SecureRandom.losowa_liczba(n)   → random int [0, n) or float [0, 1)
#   SecureRandom.losowe_bajty(n)    → array of random byte values

require 'securerandom'

module AlexScript
  module Native
    module SecureRandomLibrary

      def self.register
        Utils::NativeClassRegistry.define_class('SecureRandom',
          constructor: ->(*) {
            raise "SecureRandom jest klasą statyczną — użyj SecureRandom.hex(), SecureRandom.uuid() itd."
          },
          methods: {},
          static_methods: build_static_methods,
          static_vars: {}
        )
      end

      def self.build_static_methods
        {
          # ─── Hex ───────────────────────────────────────────

          # SecureRandom.hex()    → 32-char hex (16 bytes)
          # SecureRandom.hex(10)  → 20-char hex (10 bytes)
          'hex' => ->(*args) {
            n = args.empty? ? 16 : args[0].to_i
            ::SecureRandom.hex(n)
          },

          # ─── Base64 ────────────────────────────────────────

          # SecureRandom.base64()    → base64 string (16 bytes)
          # SecureRandom.base64(20)  → base64 string (20 bytes)
          'base64' => ->(*args) {
            n = args.empty? ? 16 : args[0].to_i
            ::SecureRandom.base64(n)
          },

          # SecureRandom.urlsafe_base64()    → URL-safe base64
          # SecureRandom.urlsafe_base64(20)  → URL-safe base64 (20 bytes)
          'urlsafe_base64' => ->(*args) {
            n = args.empty? ? 16 : args[0].to_i
            ::SecureRandom.urlsafe_base64(n)
          },

          # ─── UUID ──────────────────────────────────────────

          # SecureRandom.uuid()  → "550e8400-e29b-41d4-a716-446655440000"
          'uuid' => ->() {
            ::SecureRandom.uuid
          },

          # ─── Alphanumeric ──────────────────────────────────

          # SecureRandom.alfanumeryczny()    → 16-char alphanumeric
          # SecureRandom.alfanumeryczny(32)  → 32-char alphanumeric
          'alfanumeryczny' => ->(*args) {
            n = args.empty? ? 16 : args[0].to_i
            ::SecureRandom.alphanumeric(n)
          },

          # ─── Random numbers ────────────────────────────────

          # SecureRandom.losowa_liczba()      → float [0.0, 1.0)
          # SecureRandom.losowa_liczba(100)   → int [0, 100)
          'losowa_liczba' => ->(*args) {
            if args.empty?
              ::SecureRandom.random_number
            else
              ::SecureRandom.random_number(args[0].to_i)
            end
          },

          # ─── Random bytes ──────────────────────────────────

          # SecureRandom.losowe_bajty(16)  → array of 16 random byte values [0-255]
          'losowe_bajty' => ->(*args) {
            n = args.empty? ? 16 : args[0].to_i
            ::SecureRandom.random_bytes(n).bytes.to_a
          },

          # ─── Random in range ───────────────────────────────

          # SecureRandom.losowa_z_zakresu(1, 100)  → random int [min, max]
          'losowa_z_zakresu' => ->(min, max) {
            range = max.to_i - min.to_i + 1
            min.to_i + ::SecureRandom.random_number(range)
          },

          # ─── Token generation ──────────────────────────────

          # SecureRandom.token()    → 32-char URL-safe token
          # SecureRandom.token(64)  → 64-char URL-safe token
          'token' => ->(*args) {
            n = args.empty? ? 32 : args[0].to_i
            ::SecureRandom.urlsafe_base64(n).slice(0, n)
          },

          # ─── Random choice ─────────────────────────────────

          # SecureRandom.wybierz("abcdef", 8)  → 8-char string from given chars
          'wybierz' => ->(znaki, dlugosc) {
            chars = znaki.to_s.chars
            Array.new(dlugosc.to_i) { chars[::SecureRandom.random_number(chars.size)] }.join
          }
        }
      end
    end
  end
end