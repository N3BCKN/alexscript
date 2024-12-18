# frozen_string_literal: true

require 'byebug'
class Environment
  attr_reader :variables, :functions, :parent

  def initialize(parent = nil)
    @variables = {}
    @parent = parent
    @functions = {}
  end

  def get_var(name)
    current = self
    while current
      value = current.variables[name]
      return value if value

      current = current.parent
    end
  end

  def set_local(name, value)
    @variables[name] = value
  end

  def set_var(name, value)
    current = self
    while current
      if current.variables[name]
        current.variables[name] = value
        return value
      end
      current = current.parent
    end
    # if var was not found in parent scopes, create it in current one
    @variables[name] = value
  end

  def get_func(name)
    current = self
    while current
      value = current.functions[name]
      return value if value

      current = current.parent
    end
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
end
