require 'aruba/rspec'

RSpec.describe 'istnieje() keyword', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'basic variable existence' do
    it 'returns prawda for a defined variable' do
      code = 'niech x = 5
      pokazl istnieje(x)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'returns falsz for an undefined name' do
      code = 'pokazl istnieje(jakas_nieznana_zmienna)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
    end

    it 'does not raise BladNazwy for an undefined name' do
      # to jest sedno feature'a — argument nie jest ewaluowany
      code = 'jesli istnieje(brak) {
        pokazl "nie powinno"
      } albo {
        pokazl "ok"
      }'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('ok')
    end

    it 'returns prawda for a variable with value nic' do
      code = 'niech x = nic
      pokazl istnieje(x)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'returns prawda for a variable holding falsz' do
      code = 'niech x = falsz
      pokazl istnieje(x)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end
  end

  describe 'recognizes other kinds of names' do
    it 'returns prawda for a defined function' do
      code = 'funkcja powitaj() { pokazl "hej" }
      pokazl istnieje(powitaj)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'returns prawda for a user-defined class' do
      code = 'klasa Test {
        funkcja konstruktor() { }
      }
      pokazl istnieje(Test)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'returns prawda for a user-defined module' do
      code = 'modul Helpers {
        funkcja foo() { zwroc 1 }
      }
      pokazl istnieje(Helpers)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'returns prawda for an imported native class' do
      code = 'import("json")
      pokazl istnieje(Json)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end
  end

  describe 'scope behavior' do
    it 'returns falsz for a variable that fell out of scope' do
      code = 'jesli prawda {
        niech wewnetrzna = 1
      }
      pokazl istnieje(wewnetrzna)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
    end

    it 'returns prawda for a variable declared in outer scope' do
      code = 'niech zewnetrzna = 1
      jesli prawda {
        pokazl istnieje(zewnetrzna)
      }'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end
  end

  describe 'usage in expressions' do
    it 'works as a condition in jesli' do
      code = 'niech x = 42
      jesli istnieje(x) {
        pokazl x
      }'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'composes with logical operators' do
      code = 'niech a = 1
      pokazl istnieje(a) i istnieje(b)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
    end

    it 'allows guard before access' do
      # idiomatyczny use case: sprawdź zanim użyjesz
      code = 'jesli istnieje(opcja) {
        pokazl opcja
      } albo {
        pokazl "domyslna"
      }'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('domyslna')
    end
  end

  describe 'syntax errors' do
    it 'rejects istnieje without parentheses' do
      code = 'pokazl istnieje x'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'rejects istnieje with an expression instead of identifier' do
      code = 'pokazl istnieje(1 + 2)'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'rejects istnieje with empty parentheses' do
      code = 'pokazl istnieje()'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end
end