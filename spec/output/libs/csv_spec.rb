require 'aruba/rspec'

RSpec.describe 'Csv native library', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }
  let(:test_file) { '/tmp/as_csv_rspec.csv' }
  let(:test_file2) { '/tmp/as_csv_rspec2.csv' }

  after(:each) do
    FileUtils.rm_f(test_file)
    FileUtils.rm_f(test_file2)
  end

  describe 'parsing text' do
    it 'parses CSV into array of arrays' do
      code = '
        import("csv")
        niech k = Csv.parsuj("a,b,c\n1,2,3")
        pokazl k.dlg()
        pokazl k[0][0]
        pokazl k[1][2]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\na\n3")
    end

    it 'parses single line' do
      code = '
        import("csv")
        niech l = Csv.parsuj_linie("x,y,z")
        pokazl l.dlg()
        pokazl l[0]
        pokazl l[2]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("3\nx\nz")
    end

    it 'parses with custom separator' do
      code = '
        import("csv")
        niech k = Csv.parsuj("a;b;c\n1;2;3", ";")
        pokazl k[0][1]
        pokazl k[1][0]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("b\n1")
    end
  end

  describe 'parsing with headers' do
    it 'returns array of objects' do
      code = '
        import("csv")
        niech d = Csv.parsuj_z_naglowkami("imie,wiek\nJan,30\nAna,25")
        pokazl d.dlg()
        pokazl d[0]["imie"]
        pokazl d[1]["wiek"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\nJan\n25")
    end

    it 'extracts headers' do
      code = '
        import("csv")
        niech n = Csv.naglowki("kol1,kol2,kol3\na,b,c")
        pokazl n.dlg()
        pokazl n[0]
        pokazl n[2]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("3\nkol1\nkol3")
    end
  end

  describe 'generating' do
    it 'generates CSV from arrays' do
      code = '
        import("csv")
        niech g = Csv.generuj([["a", "b"], ["1", "2"]])
        pokazl g.zawiera("a,b")
        pokazl g.zawiera("1,2")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'generates single line' do
      code = '
        import("csv")
        niech l = Csv.generuj_linie(["x", "y", "z"])
        pokazl l.zawiera("x,y,z")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'generates with headers' do
      code = '
        import("csv")
        niech g = Csv.generuj_z_naglowkami(["h1", "h2"], [["v1", "v2"]])
        pokazl g.zawiera("h1,h2")
        pokazl g.zawiera("v1,v2")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'generates with custom separator' do
      code = '
        import("csv")
        niech g = Csv.generuj([["a", "b"]], ";")
        pokazl g.zawiera("a;b")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end
  end

  describe 'file operations' do
    it 'writes and reads CSV file' do
      code = "
        import(\"csv\")
        Csv.generuj_plik(\"#{test_file}\", [[\"a\", \"b\"], [\"1\", \"2\"]])
        niech k = Csv.parsuj_plik(\"#{test_file}\")
        pokazl k.dlg()
        pokazl k[0][0]
        pokazl k[1][1]
      "
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\na\n2")
    end

    it 'writes and reads CSV with headers' do
      code = "
        import(\"csv\")
        Csv.generuj_plik_z_naglowkami(\"#{test_file}\", [\"imie\", \"wiek\"], [[\"Jan\", \"30\"]])
        niech d = Csv.parsuj_plik_z_naglowkami(\"#{test_file}\")
        pokazl d.dlg()
        pokazl d[0][\"imie\"]
      "
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("1\nJan")
    end

    it 'extracts headers from file' do
      code = "
        import(\"csv\")
        Csv.generuj_plik_z_naglowkami(\"#{test_file}\", [\"x\", \"y\"], [[\"1\", \"2\"]])
        niech n = Csv.naglowki_pliku(\"#{test_file}\")
        pokazl n.dlg()
        pokazl n[0]
      "
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\nx")
    end
  end

  describe 'utility' do
    it 'counts rows and columns' do
      code = '
        import("csv")
        pokazl Csv.liczba_wierszy("a,b\n1,2\n3,4")
        pokazl Csv.liczba_kolumn("a,b,c\n1,2,3")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("3\n3")
    end

    it 'extracts a column by name' do
      code = '
        import("csv")
        niech k = Csv.kolumna("imie,wiek\nJan,30\nAna,25", "wiek")
        pokazl k.dlg()
        pokazl k[0]
        pokazl k[1]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\n30\n25")
    end
  end

  describe 'edge cases' do
    it 'handles empty input' do
      code = '
        import("csv")
        niech k = Csv.parsuj("")
        pokazl k.dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0")
    end
  end

  describe 'cannot instantiate' do
    it 'raises error on Csv.nowy()' do
      code = '
        import("csv")
        niech c = Csv.nowy()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Csv jest klasą statyczną/)
      expect(last_command_started).to have_exit_status(1)
    end
  end
end
