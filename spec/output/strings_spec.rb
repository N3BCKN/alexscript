require 'aruba/rspec'

RSpec.describe 'Cli', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'concatenation' do
    it 'can display a string with array' do
      code = 'pokazl "napis" + [1,2,3,4]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('napis[1, 2, 3, 4]')
    end
  end

  describe 'build in methods' do
    it 'performs methods on strings not assigned to variables' do
      code = 'pokazl "napis".typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('napis')
    end

    it 'shows properly size of a string' do
      code = 'niech str = "Hello, World"
      pokazl str.dlg()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('12')
    end

    it 'turn string to uppercase' do
      code = 'niech str = "hello, World"
      pokazl str.zduzej()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Hello, world')
    end

    it 'all chars in string lowercase' do
      code = 'niech str = "HELlO, WORLD"
      pokazl str.malymi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('hello, world')
    end

    it 'capitalize string' do
      code = 'niech str = "Hello, World"
      pokazl str.duzymi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('HELLO, WORLD')
    end

    it 'checks if strign is empty' do
      code = 'niech str1 = "Hello, World"
        niech str2 = ""
        pokazl str1.pusta()
        pokazl str2.pusta()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("falsz\nprawda")
    end

    it 'change strign to number (float)' do
      code = 'niech str = "5"
      pokazl str.liczba().typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('zmiennoprzecinkowa')
    end

    it 'returns nil/nic if string cannot be turned into a number (float)' do
      code = 'niech str = "Hello, World"
        pokazl str.liczba()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end

    it 'splits string into an array with separator' do
      code = 'niech str = "Hello, World"
        pokazl str.rozdziel(",")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[Hello,  World]')
    end

    it 'returns char from given string index' do
      code = 'niech str = "Hello, World"
      pokazl str.indeks(1)
      pokazl str.indeks(str.dlg-1)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("e\nd")
    end

    it 'returns error if index is out of bounds' do
      code = 'niech str = "Hello, World"
      pokazl str.indeks(9999)'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/ndeks poza zakresem/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'returns bool if string contains a given substring or not' do
      code = 'niech str = "Hello, World"
        pokazl str.zawiera("Hello")
        pokazl str.zawiera("test")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz")
    end

    it 'slices string' do
      code = 'niech str = "Hello, World"
        pokazl str.wydziel(0, 7)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Hello, ')
    end

    it 'deletes chars from a string' do
      code = 'niech str = "Hello, World"
        str.usun("World")
        pokazl str'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('He, ')
    end

    it 'reverses string' do
      code = 'niech str = "Hello, World"
      pokazl str.odwroc()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('dlroW ,olleH')
    end

    it 'returns empty string when empty string is reversed' do
      code = 'niech str = ""
      pokazl str.odwroc()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('')
    end

    it 'clears string from whitespaces' do
      code = 'niech str = "     Hello, World     "
      pokazl str.wyczysc()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Hello, World')
    end
  end
end
