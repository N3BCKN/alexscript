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

    # Singleton instances for the three special values
    BOOL_TRUE = PrimitiveValue.new('prawda', :bool)
    BOOL_FALSE = PrimitiveValue.new('falsz', :bool)
    NULL_VALUE = PrimitiveValue.new('nic', :null)
  end
end