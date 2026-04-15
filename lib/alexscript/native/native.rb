# frozen_string_literal: true

require_relative './czas'
require_relative './mat'
require_relative './plik'
require_relative './json'
require_relative './csv'
require_relative './socket'
require_relative './http'
require_relative './digest'
require_relative './secure_random'

module AlexScript
  module Native
    def self.setup!
      # Register native class definitions
      CzasLibrary.register
      MatLibrary.register
      PlikLibrary.register
      JsonLibrary.register
      CsvLibrary.register
      SocketLibrary.register
      HttpLibrary.register
      DigestLibrary.register
      SecureRandomLibrary.register

      # Register importable library names
      # Maps import("czas") → register Czas class into caller's environment
      Utils::NativeClassRegistry.register_library('czas') do |env|
        Utils::NativeClassRegistry.register_into_env('Czas', env)
      end

      Utils::NativeClassRegistry.register_library('mat') do |env|
        Utils::NativeClassRegistry.register_into_env('Mat', env)
      end

      Utils::NativeClassRegistry.register_library('plik') do |env|
        Utils::NativeClassRegistry.register_into_env('Plik', env)
      end

      Utils::NativeClassRegistry.register_library('json') do |env|
        Utils::NativeClassRegistry.register_into_env('Json', env)
      end
 
      Utils::NativeClassRegistry.register_library('csv') do |env|
        Utils::NativeClassRegistry.register_into_env('Csv', env)
      end

      Utils::NativeClassRegistry.register_library('socket') do |env|
        Utils::NativeClassRegistry.register_into_env('SocketTcp', env)
        Utils::NativeClassRegistry.register_into_env('SerwerTcp', env)
        Utils::NativeClassRegistry.register_into_env('SocketUdp', env)
        Utils::NativeClassRegistry.register_into_env('Socket', env)
      end

      Utils::NativeClassRegistry.register_library('http') do |env|
        Utils::NativeClassRegistry.register_into_env('Http', env)
      end

      Utils::NativeClassRegistry.register_library('digest') do |env|
        Utils::NativeClassRegistry.register_into_env('Digest', env)
      end
 
      Utils::NativeClassRegistry.register_library('securerandom') do |env|
        Utils::NativeClassRegistry.register_into_env('SecureRandom', env)
      end
    end
  end
end
