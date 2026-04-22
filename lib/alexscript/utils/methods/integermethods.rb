# frozen_string_literal: true

module AlexScript
  module Utils
    module Methods
      class IntegerMethods < BaseTypeHandler
        private

        def register_methods
          register_method('typ', ->(num) { 'calkowita' })
          register_method('napis', ->(num) { num.to_s })
          register_method('abs', ->(num) { num.abs })
          register_method('parzysta', lambda { |num|
            [:type_bool, num.even? ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })
          register_method('nieparzysta', lambda { |num|
            [:type_bool, num.odd? ? Utils::BOOL_TRUE : Utils::BOOL_FALSE]
          })

          # Bitowe: konwersje do stringa 
          # Binarna reprezentacja liczby (bez prefiksu "0b"), dla ujemnych z minusem
          register_method('binarnie', ->(num) { num.to_s(2) })
          # Szesnastkowa reprezentacja (bez prefiksu "0x"), lowercase
          register_method('szesnastkowo', ->(num) { num.to_s(16) })
          # Osemkowa reprezentacja (bez prefiksu "0o")
          register_method('osemkowo', ->(num) { num.to_s(8) })

          # Długość bitowa: liczba bitów potrzebnych do reprezentacji abs(num)
          # Przykład: (10).dlugosc_bitowa() == 4  (bo 10 = 0b1010)
          register_method('dlugosc_bitowa', ->(num) { num.bit_length })

          # Liczba ustawionych bitów (popcount).
          # Dla liczb ujemnych używamy reprezentacji uzupełnień do 2 o długości bit_length+1,
          # tak jak Ruby. Dla dodatnich — zwykły count.
          register_method('policz_bity', lambda { |num|
            if num >= 0
              num.to_s(2).count('1')
            else
              # two's complement representation: ~num XOR mask o odpowiedniej szerokości
              # Prostsza definicja spójna z Ruby (Integer#bit_length dla -1 = 0):
              # zwracamy liczbę ustawionych bitów w nieskończonej reprezentacji 2s-complement,
              # ograniczoną do bit_length. Dla -1 → 0, bo w 2s-comp wszystkie bity sa "1" i nie ma
              # sensownej skończonej odpowiedzi. Definiujemy to jak w Pythonie bin(x & 0xFFFF...).
              # Prosty wariant: liczba bitów ustawionych w abs(num).
              num.abs.to_s(2).count('1')
            end
          })

          # Dostęp do n-tego bitu (0-indeksowany od LSB): zwraca 0 lub 1
          register_method('bit', lambda { |num, n|
            if n < 0
              Utils.runtime_error("Indeks bitu nie moze byc ujemny", 0)
            end
            num[n]
          })

          # Ustawia n-ty bit (zwraca nową liczbę)
          register_method('ustaw_bit', lambda { |num, n|
            if n < 0
              Utils.runtime_error("Indeks bitu nie moze byc ujemny", 0)
            end
            num | (1 << n)
          })

          # Zeruje n-ty bit
          register_method('wyczysc_bit', lambda { |num, n|
            if n < 0
              Utils.runtime_error("Indeks bitu nie moze byc ujemny", 0)
            end
            num & ~(1 << n)
          })

          # Przełącza n-ty bit (XOR z 1<<n)
          register_method('przelacz_bit', lambda { |num, n|
            if n < 0
              Utils.runtime_error("Indeks bitu nie moze byc ujemny", 0)
            end
            num ^ (1 << n)
          })
        end
      end
    end
  end
end