require 'aruba/rspec'

RSpec.describe 'Json native library', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }
  let(:test_file) { '/tmp/as_json_rspec.json' }

  after(:each) { FileUtils.rm_f(test_file) }

  describe 'parsing' do
    it 'parses JSON object' do
      code = '
        import("json")
        niech obj = Json.parsuj("{\"imie\": \"Jan\", \"wiek\": 30}")
        pokazl obj["imie"]
        pokazl obj["wiek"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Jan\n30")
    end

    it 'parses JSON array' do
      code = '
        import("json")
        niech tab = Json.parsuj("[1, 2, 3]")
        pokazl tab.dlg()
        pokazl tab[0]
        pokazl tab[2]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("3\n1\n3")
    end

    it 'parses nested structures' do
      code = '
        import("json")
        niech d = Json.parsuj("{\"a\": {\"b\": 42}, \"c\": [1, 2]}")
        pokazl d["a"]["b"]
        pokazl d["c"][0]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("42\n1")
    end

    it 'parses all JSON types correctly' do
      code = '
        import("json")
        niech d = Json.parsuj("{\"i\": 42, \"f\": 3.14, \"t\": true, \"fa\": false, \"n\": null}")
        pokazl d["i"]
        pokazl d["t"]
        pokazl d["fa"]
        pokazl d["n"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("42\nprawda\nfalsz\nnic")
    end
  end

  describe 'generating' do
    it 'generates compact JSON from object' do
      code = '
        import("json")
        niech j = Json.generuj({"a": 1, "b": 2})
        pokazl j
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      output = last_command_started.output.strip.gsub(/[\\"]/, '')
      expect(output).to include('a')
      expect(output).to include('1')
    end

    it 'generates pretty JSON' do
      code = '
        import("json")
        niech j = Json.generuj_ladnie({"x": 10})
        pokazl j.zawiera("\n")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'round-trips parse and generate' do
      code = '
        import("json")
        niech oryg = {"klucz": "wartość", "n": 99}
        niech json = Json.generuj(oryg)
        niech odtw = Json.parsuj(json)
        pokazl odtw["klucz"]
        pokazl odtw["n"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("wartość\n99")
    end
  end

  describe 'validation' do
    it 'validates correct JSON' do
      code = '
        import("json")
        pokazl Json.czy_poprawny("{\"a\": 1}")
        pokazl Json.czy_poprawny("nie json")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nfalsz")
    end
  end

  describe 'merge' do
    it 'merges two objects' do
      code = '
        import("json")
        niech p = Json.polacz({"a": 1}, {"b": 2, "a": 99})
        pokazl p["a"]
        pokazl p["b"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("99\n2")
    end
  end

  describe 'keys' do
    it 'extracts keys from object' do
      code = '
        import("json")
        niech k = Json.klucze({"x": 1, "y": 2})
        pokazl k.dlg()
        pokazl k.zawiera("x")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2\nprawda")
    end
  end

  describe 'file operations' do
    it 'writes and reads JSON file' do
      code = "
        import(\"json\")
        Json.generuj_plik(\"#{test_file}\", {\"test\": 123})
        niech d = Json.parsuj_plik(\"#{test_file}\")
        pokazl d[\"test\"]
      "
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("123")
    end
  end

  describe 'cannot instantiate' do
    it 'raises error on Json.nowy()' do
      code = '
        import("json")
        niech j = Json.nowy()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Json jest klasą statyczną/)
      expect(last_command_started).to have_exit_status(1)
    end
  end
end
