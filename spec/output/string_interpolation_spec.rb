# frozen_string_literal: true

require 'aruba/rspec'

RSpec.describe 'String Interpolation', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'basic interpolation' do
    it 'interpolates single variable' do
      code = 'niech imie = "Jan"
      pokazl "Cześć #{imie}!"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Cześć Jan!')
    end

    it 'interpolates multiple variables' do
      code = 'niech imie = "Anna"
      niech wiek = 30
      pokazl "Cześć #{imie}, masz #{wiek} lat"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Cześć Anna, masz 30 lat')
    end

    it 'interpolates at start of string' do
      code = 'niech x = "test"
      pokazl "#{x} na początku"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('test na początku')
    end

    it 'interpolates at end of string' do
      code = 'niech x = "koniec"
      pokazl "to jest #{x}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('to jest koniec')
    end

    it 'interpolates only, no literal text' do
      code = 'niech x = "samo"
      pokazl "#{x}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('samo')
    end
  end

  describe 'expression interpolation' do
    it 'interpolates arithmetic expression' do
      code = 'niech a = 5
      niech b = 3
      pokazl "Suma: #{a + b}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Suma: 8')
    end

    it 'interpolates function call' do
      code = 'funkcja podwoj(x) { zwroc x * 2 }
      pokazl "Wynik: #{podwoj(21)}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Wynik: 42')
    end

    it 'interpolates fn call' do
      code = 'niech kwadrat = fn(x) { x * x }
      pokazl "5² = #{kwadrat(5)}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('5² = 25')
    end

    it 'interpolates array access' do
      code = 'niech arr = [10, 20, 30]
      pokazl "Pierwszy: #{arr[0]}, trzeci: #{arr[2]}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Pierwszy: 10, trzeci: 30')
    end

    it 'interpolates method call on array' do
      code = 'niech arr = [1, 2, 3, 4]
      pokazl "Długość: #{arr.dlg()}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Długość: 4')
    end
  end

  describe 'type conversions in interpolation' do
    it 'converts int to string' do
      code = 'niech n = 42
      pokazl "Liczba: #{n}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Liczba: 42')
    end

    it 'converts float to string' do
      code = 'niech x = 3.14
      pokazl "Pi: #{x}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Pi: 3.14')
    end

    it 'converts bool to string' do
      code = 'niech t = prawda
      niech f = falsz
      pokazl "T: #{t}, F: #{f}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('T: prawda, F: falsz')
    end

    it 'converts nic to string' do
      code = 'niech x = nic
      pokazl "Wartość: #{x}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Wartość: nic')
    end

    it 'converts array to string' do
      code = 'niech arr = [1, 2, 3]
      pokazl "Tablica: #{arr}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Tablica: [1, 2, 3]')
    end
  end

  describe 'edge cases' do
    it 'empty string without interpolation' do
      code = 'pokazl ""'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('')
    end

    it 'string without interpolation (backward compatibility)' do
      code = 'pokazl "Zwykły tekst bez interpolacji"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Zwykły tekst bez interpolacji')
    end

    it 'hash without curly brace is literal' do
      code = 'pokazl "Cena: 100# zł"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Cena: 100# zł')
    end

    it 'interpolation in assignment' do
      code = 'niech imie = "Bob"
      niech powitanie = "Witaj, #{imie}!"
      pokazl powitanie'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Witaj, Bob!')
    end

    it 'three consecutive interpolations' do
      code = 'niech a = "X"
      niech b = "Y"
      niech c = "Z"
      pokazl "#{a}#{b}#{c}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('XYZ')
    end

    it 'interpolation with complex expression' do
      code = 'niech liczby = [1, 2, 3, 4, 5]
      pokazl "Suma kwadratów: #{liczby.mapuj(fn(x) { x * x }).redukuj(fn(a, b) { a + b }, 0)}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Suma kwadratów: 55')
    end
  end

  describe 'interpolation with OOP' do
    it 'interpolates instance variables via method' do
      code = 'klasa Osoba {
        funkcja konstruktor(n, k) {
          niech @imie = n
          niech @wiek = k
        }
        funkcja opis() {
          zwroc "#{@imie} (#{@wiek} lat)"
        }
      }
      niech o = Osoba.nowy("Ewa", 25)
      pokazl o.opis()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Ewa (25 lat)')
    end
  end

  describe 'escape sequences' do
    it 'escaped hash does not trigger interpolation' do
      code = 'niech x = "test"
      pokazl "Literal: \#{x}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Literal: #{x}')
    end

    it 'newline escape still works in interpolated string' do
      code = 'niech x = "A"
      pokazl "#{x}\nB"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("AnB")
    end
  end
end