# frozen_string_literal: true

# lib/alexscript/native/json_lib.rb
#
# Native binding for Ruby's JSON module, exposed as AlexScript's Json class.
# Purely static — Json cannot be instantiated.
#
# Covers:
#   Parsing:  parsuj, parsuj_plik
#   Generating: generuj, generuj_ladnie, generuj_plik
#   Validation: czy_poprawny
#
# AS objects/arrays map directly to JSON objects/arrays.
# AS prawda/falsz/nic map to JSON true/false/null.

require 'json'

module AlexScript
  module Native
    module JsonLibrary

      def self.register
        Utils::NativeClassRegistry.define_class('Json',
          constructor: ->(*) {
            raise "Json jest klasą statyczną i nie może być instancjonowana"
          },
          methods: {},
          static_methods: build_static_methods,
          static_vars: {}
        )
      end

      def self.build_static_methods
        {
          # ─── Parsing ───────────────────────────────────────

          # Json.parsuj('{"klucz": "wartość"}')  → AS object
          # Json.parsuj('[1, 2, 3]')              → AS array
          'parsuj' => ->(tekst) {
            convert_from_ruby(JSON.parse(tekst.to_s))
          },

          # returns nic (nil) instead of errro
          'parsuj_bezpiecznie' => ->(tekst) {
            begin
              convert_from_ruby(JSON.parse(tekst.to_s))
            rescue JSON::ParserError
              nil
            end
          },

          # Json.parsuj_plik("dane.json")  → AS object/array
          'parsuj_plik' => ->(sciezka) {
            content = File.read(sciezka.to_s)
            convert_from_ruby(JSON.parse(content))
          },

          # ─── Generating ────────────────────────────────────

          # Json.generuj(obiekt)  → compact JSON string
          'generuj' => ->(dane) {
            ruby_val = convert_to_ruby(dane)
            JSON.generate(ruby_val)
          },

          # Json.generuj_ladnie(obiekt)  → pretty-printed JSON
          # Json.generuj_ladnie(obiekt, 4)  → with custom indent
          'generuj_ladnie' => ->(dane, *args) {
            ruby_val = convert_to_ruby(dane)
            indent = args.empty? ? '  ' : ' ' * args[0].to_i
            JSON.pretty_generate(ruby_val, indent: indent)
          },

          # ─── File I/O ──────────────────────────────────────

          # Json.generuj_plik("output.json", obiekt)
          # Json.generuj_plik("output.json", obiekt, prawda)  → pretty
          'generuj_plik' => ->(sciezka, dane, *args) {
            ruby_val = convert_to_ruby(dane)
            ladnie = !args.empty? && args[0] == true
            json_str = ladnie ? JSON.pretty_generate(ruby_val) : JSON.generate(ruby_val)
            File.write(sciezka.to_s, json_str)
            json_str.length
          },

          # ─── Validation ────────────────────────────────────

          # Json.czy_poprawny('{"a": 1}')  → prawda
          # Json.czy_poprawny('not json')  → falsz
          'czy_poprawny' => ->(tekst) {
            begin
              JSON.parse(tekst.to_s)
              true
            rescue JSON::ParserError
              false
            end
          },

          # ─── Merge ─────────────────────────────────────────

          # Json.polacz(obiekt1, obiekt2)  → merged object
          'polacz' => ->(obj1, obj2) {
            r1 = convert_to_ruby(obj1)
            r2 = convert_to_ruby(obj2)
            raise "Oba argumenty muszą być obiektami" unless r1.is_a?(Hash) && r2.is_a?(Hash)
            convert_from_ruby(r1.merge(r2))
          },

          # ─── Query helpers ─────────────────────────────────

          # Json.klucze(obiekt)  → array of keys
          'klucze' => ->(obj) {
            ruby_val = convert_to_ruby(obj)
            raise "Argument musi być obiektem" unless ruby_val.is_a?(Hash)
            ruby_val.keys
          },

          # Json.wartosci(obiekt)  → array of values
          'wartosci' => ->(obj) {
            ruby_val = convert_to_ruby(obj)
            raise "Argument musi być obiektem" unless ruby_val.is_a?(Hash)
            convert_from_ruby(ruby_val.values)
          }
        }
      end

      private

      # Convert AS value (already converted by NativeTypeConverter) to pure Ruby
      # for JSON.generate. Handles nested structures.
      def self.convert_to_ruby(val)
        case val
        when Hash
          # Could be an AS object {string_key => {type:, value:}} or plain Ruby hash
          if val.values.first.is_a?(Hash) && val.values.first.key?(:type)
            # AS object format
            result = {}
            val.each do |k, v|
              result[k.to_s] = convert_to_ruby_inner(v)
            end
            result
          else
            val
          end
        when Array
          # Could be AS array [{type:, value:}, ...] or plain Ruby array
          if val.first.is_a?(Hash) && val.first.key?(:type)
            val.map { |elem| convert_to_ruby_inner(elem) }
          else
            val
          end
        when Utils::PrimitiveValue
          if val.null? then nil
          elsif val.truthy? then true
          else false
          end
        else
          val
        end
      end

      def self.convert_to_ruby_inner(typed_val)
        return typed_val unless typed_val.is_a?(Hash) && typed_val.key?(:type)

        v = typed_val[:value]
        case typed_val[:type]
        when :type_int, :type_float, :type_string
          v
        when :type_bool
          v.is_a?(Utils::PrimitiveValue) ? v.truthy? : v
        when :type_null
          nil
        when :type_array
          v.map { |elem| convert_to_ruby_inner(elem) }
        when :type_object
          result = {}
          v.each { |k, inner| result[Utils.object_key_typed(k)[1].to_s] = convert_to_ruby_inner(inner) }
          result
        when :type_instance
          v[:__native__] ? v[:__native__].to_s : v.to_s
        else
          v
        end
      end

      # Convert Ruby parsed JSON back to AS-compatible value.
      # Returns raw Ruby value — NativeTypeConverter.from_ruby handles the rest.
      def self.convert_from_ruby(val)
        val  # NativeClassRegistry.convert_return handles this
      end
    end
  end
end