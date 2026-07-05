# frozen_string_literal: true

module AlexScript
  module Utils
    # PrimitiveValue represents special language values: prawda, falsz, nic
    # These are singleton-like values that display without quotes and have
    # type safety (can't be confused with strings)
    class PrimitiveValue
      attr_reader :lexeme, :type

      def initialize(lexeme, type)
        @lexeme = lexeme
        @type = type
        freeze
      end

      def to_s
        @lexeme
      end

      def inspect
        @lexeme
      end

      # Equality comparison
      def ==(other)
        case other
        when PrimitiveValue
          @lexeme == other.lexeme
        when String
          @lexeme == other
        else
          false
        end
      end

      def eql?(other)
        self == other
      end

      def hash
        @lexeme.hash
      end

      # Check if this is a truthy value
      def truthy?
        @type == :bool && @lexeme == 'prawda'
      end

      # Check if this is a falsy value
      def falsy?
        @type == :bool && @lexeme == 'falsz'
      end

      # Check if this is null
      def null?
        @type == :null
      end

      # Check if this is a boolean
      def bool?
        @type == :bool
      end
    end

    # singleton instances for the three special values
    BOOL_TRUE = PrimitiveValue.new('prawda', :bool)
    BOOL_FALSE = PrimitiveValue.new('falsz', :bool)
    NULL_VALUE = PrimitiveValue.new('nic', :null)

    OBJECT_NULL_KEY = Object.new.freeze  # `nic` used as a key
    OBJECT_MISS_KEY = Object.new.freeze  # never a key in any object; for invalid lookups

    # keys in objects allowed: "napis", "calkowita", "logiczna" or "nic"
    def self.object_key(value, line = nil)
      case value
      when String  then value
      when Integer then value
      when PrimitiveValue
        if value.bool?
          value.truthy? ? true : false
        elsif value.null?
          OBJECT_NULL_KEY
        else
          runtime_error('Niedozwolony typ klucza obiektu', line)
        end
      when Float
        runtime_error('Klucz obiektu nie moze byc liczba zmiennoprzecinkowa', line)
      else
        runtime_error('Klucz obiektu musi byc napisem, liczba calkowita, wartoscia logiczna lub nic', line)
      end
    end

    # variant for ma_klucz / usun — invalid key can't be present
    def self.object_key_for_lookup(value)
      case value
      when String, Integer then value
      when PrimitiveValue
        if value.bool? then (value.truthy? ? true : false)
        elsif value.null? then OBJECT_NULL_KEY
        else OBJECT_MISS_KEY
        end
      else OBJECT_MISS_KEY
      end
    end

    # Ruby key -> AlexScript [type, value]
    def self.object_key_typed(ruby_key)
      case ruby_key
      when String          then [:type_string, ruby_key]
      when Integer         then [:type_int, ruby_key]
      when true            then [:type_bool, BOOL_TRUE]
      when false           then [:type_bool, BOOL_FALSE]
      when OBJECT_NULL_KEY then [:type_null, NULL_VALUE]
      else [:type_string, ruby_key.to_s] # defensive
      end
    end
  end
end