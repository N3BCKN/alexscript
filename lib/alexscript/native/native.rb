# frozen_string_literal: true

require_relative './czas'
require_relative './mat'
require_relative './plik'

module AlexScript
  module Native
    def self.setup!
      # Register native class definitions
      CzasLibrary.register
      MatLibrary.register
      PlikLibrary.register

      # Register importable library names
      # Maps importuj("czas") → register Czas class into caller's environment
      Utils::NativeClassRegistry.register_library('czas') do |env|
        Utils::NativeClassRegistry.register_into_env('Czas', env)
      end

      Utils::NativeClassRegistry.register_library('mat') do |env|
        Utils::NativeClassRegistry.register_into_env('Mat', env)
      end

      Utils::NativeClassRegistry.register_library('plik') do |env|
        Utils::NativeClassRegistry.register_into_env('Plik', env)
      end
    end
  end
end
