# frozen_string_literal: true

# implements deep equality comparison for all AlexScript types.
# recursively compares arrays, objects, and instances, handling nested structures
# and reference equality for instance types.

module AlexScript
  module Core
    module Helpers
      module DeepEquality

        # deep comparison of values for == and != operators
        def deep_equal?(left_type, left_value, right_type, right_value)
          # different types are not equal (except numeric types which can be compared)
          return false if left_type != right_type && 
                  !([left_type, right_type] - [:type_int, :type_float]).empty?
          
          case [left_type, right_type]
          when [:type_array, :type_array]
            return false if left_value.size != right_value.size
            
            left_value.each_with_index do |left_elem, idx|
            right_elem = right_value[idx]
            return false unless deep_equal?(left_elem[:type], left_elem[:value], 
                            right_elem[:type], right_elem[:value])
            end
            true
          when [:type_object, :type_object]
            return false if left_value.keys.sort != right_value.keys.sort
            
            left_value.each do |key, left_val|
            return false unless right_value.key?(key)
            right_val = right_value[key]
            return false unless deep_equal?(left_val[:type], left_val[:value],
                            right_val[:type], right_val[:value])
            end
            true
          when [:type_instance, :type_instance]
            # instances are equal only if they're the same object (reference equality)
            left_value.equal?(right_value)
          else
            # for primitives (int, float, string, bool, null) use regular comparison
            left_value == right_value
          end
        end
      end
    end
  end 
end 