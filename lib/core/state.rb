# frozen_string_literal: true

require 'byebug'
class Environment
  attr_reader :variables, :parent

  def initialize(parent = nil)
    @variables = {}
    @parent = parent
  end

  def get_var(name)
    current = self
    while current
      value = current.variables[name]
      return value if value

      current = current.parent
    end
    nil
  end

  def set_var(name, value)
    current = self
    while current
      if @variables[name]
        @variables[name] = value
        return value
      end
      current = current.parent
    end
    # set variable in current scope/env if it wasn't found in any of the parrent scopes
    @variables[name] = value
  end

  # return a new environmnet that is a child of the current one
  # this is used for the nested scopes (functions, loop, blocks etc)
  def new_env
    Environment.new(self)
  end
end
