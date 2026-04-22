require 'aruba/rspec'

RSpec.describe 'Keyword-as-identifier validation', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'variable declarations with keyword names' do
    it 'rejects niech niech = 5' do
      code = 'niech niech = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'niech' jest slowem kluczowym")
    end

    it 'rejects niech funkcja = 5' do
      code = 'niech funkcja = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'funkcja' jest slowem kluczowym")
    end

    it 'rejects niech klasa = 5' do
      code = 'niech klasa = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'klasa' jest slowem kluczowym")
    end

    it 'rejects niech dla = 5' do
      code = 'niech dla = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'dla' jest slowem kluczowym")
    end

    it 'rejects niech w = 5' do
      code = 'niech w = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'w' jest slowem kluczowym")
    end

    it 'rejects niech i = 5' do
      code = 'niech i = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'i' jest slowem kluczowym")
    end

    it 'rejects niech lub = 5' do
      code = 'niech lub = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'lub' jest slowem kluczowym")
    end

    it 'rejects niech jesli = 5' do
      code = 'niech jesli = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'jesli' jest slowem kluczowym")
    end

    it 'rejects niech modul = 5' do
      code = 'niech modul = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'modul' jest slowem kluczowym")
    end

    it 'rejects niech fn = 5' do
      code = 'niech fn = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'fn' jest slowem kluczowym")
    end

    it 'rejects niech jesli = 5 (keyword with dedicated statement branch)' do
      code = 'niech jesli = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'jesli' jest slowem kluczowym")
    end

    it 'rejects niech prawda = 5 with proactive guard' do
      code = 'niech prawda = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'prawda' jest slowem kluczowym")
    end
  end

  describe 'literal keywords as LHS' do
    it 'rejects niech prawda = 5' do
      code = 'niech prawda = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'prawda' jest slowem kluczowym")
    end

    it 'rejects niech falsz = 5' do
      code = 'niech falsz = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'falsz' jest slowem kluczowym")
    end

    it 'rejects niech nic = 5' do
      code = 'niech nic = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'nic' jest slowem kluczowym")
    end

    # Non-keyword non-identifier: still caught, by the LHS type check.
    it 'rejects niech 42 = 5' do
      code = 'niech 42 = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include('Nazwa zmiennej musi byc prawidlowym identyfikatorem')
    end
  end

  describe 'function and class declarations' do
    it 'rejects function named niech' do
      code = 'funkcja niech() {}'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'niech' jest slowem kluczowym")
    end

    it 'rejects class named funkcja' do
      code = 'klasa funkcja {}'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'funkcja' jest slowem kluczowym")
    end

    it 'rejects function parameter named niech' do
      code = 'funkcja foo(niech) {}'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'niech' jest slowem kluczowym")
    end
  end

  describe 'global variable declarations' do
    it 'rejects globalna niech klasa = 5' do
      code = 'globalna niech klasa = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'klasa' jest slowem kluczowym")
    end

    it 'rejects globalna niech prawda = 5' do
      code = 'globalna niech prawda = 5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'prawda' jest slowem kluczowym")
    end
  end

  describe 'for loop variables' do
    it 'rejects keyword as for loop variable' do
      code = 'dla funkcja w [1, 2, 3] { pokazl funkcja }'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include("'funkcja' jest slowem kluczowym")
    end
  end

  describe 'regression: valid code still works' do
    it 'accepts normal identifiers' do
      code = 'niech x = 5
      pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end

    it 'accepts identifiers that start with keyword letters' do
      # "iterator" begins with "i" (keyword), but is a distinct identifier
      code = 'niech iterator = 10
      pokazl iterator'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end

    it 'accepts identifiers that contain keyword substrings' do
      code = 'niech jesli_to_dziala = 42
      pokazl jesli_to_dziala'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'still allows certain keywords as method names' do
      # parse_method_name explicitly allows klasa, nic, prawda, falsz, dla, w
      code = 'klasa A {
        funkcja konstruktor() {}
      }
      niech a = A.nowy()
      pokazl a.klasa()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('A')
    end
  end
end