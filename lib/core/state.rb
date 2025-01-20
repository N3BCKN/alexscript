# frozen_string_literal: true

require 'byebug'
class Environment
  attr_reader :variables, :functions, :parent

  @@call_depth = 0
  @@max_call_depth = 600

  def initialize(parent = nil)
    @variables = {}
    @parent = parent
    @functions = {}
    @built_in_methods = BuiltInMethods::MethodRegistry.new
  end

  def get_var(name)
    current = self
    while current
      value = current.variables[name]
      return value if value

      current = current.parent
    end
  end

  def set_local_var(name, value, type, is_constant = false)
    @variables[name] = { value: value, type: type, constant: is_constant }
  end

  def set_var(name, value, type, is_constant = false)
    current = self
    while current
      if current.variables[name]
        current.variables[name][:value] = value
        return value
      end
      current = current.parent
    end
    # if var was not found in parent scopes, create it in current one
    @variables[name] = { value: value, type: type, constant: is_constant }
  end

  def get_func(name)
    current = self
    while current
      value = current.functions[name]
      return value if value

      current = current.parent
    end
  end

  def get_global_env
    current = self
    current = current.parent while current.parent
    current
  end

  def increment_call_depth(line)
    @@call_depth += 1
    return unless @@call_depth > @@max_call_depth

    Utils.runtime_error("Maximum recursion depth (#{@@max_call_depth}) exceeded, stack is too deep", line)
  end

  def decrement_call_depth
    @@call_depth -= 1
  end

  # for passing function as argments to other functions
  def get_func_as_value(name)
    func = get_func(name)
    return nil unless func

    [:type_function, { declaration: func[0], env: func[1] }]
  end

  def set_func(name, value)
    # value is an 2dms array storing both function declaration and current env where it was declared
    @functions[name] = value
  end

  # return a new environmnet that is a child of the current one
  # this is used for the nested scopes (functions, loop, blocks etc)
  def new_env
    Environment.new(self)
  end

  def call_method(obj_type, method_name, receiver, args = [], line)
    method = @built_in_methods.get_method(obj_type, method_name)
    Utils.runtime_error("Unknown method #{method_name} for type #{obj_type}", line) unless method

    begin
      method.call(receiver, *args)
    rescue StandardError => e
      Utils.runtime_error("Error executing method #{method_name}: #{e.message}", line)
    end
  end
end
