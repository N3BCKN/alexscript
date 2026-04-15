require 'aruba/rspec'

RSpec.describe 'SecureRandom native library', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'hex' do
    it 'generates 32-char hex by default' do
      code = '
        import("securerandom")
        pokazl SecureRandom.hex().dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("32")
    end

    it 'generates hex of specified length' do
      code = '
        import("securerandom")
        pokazl SecureRandom.hex(10).dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("20")
    end

    it 'generates unique values' do
      code = '
        import("securerandom")
        pokazl SecureRandom.hex() != SecureRandom.hex()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end
  end

  describe 'base64' do
    it 'generates non-empty base64' do
      code = '
        import("securerandom")
        pokazl SecureRandom.base64().dlg() > 0
        pokazl SecureRandom.base64(10).dlg() > 0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end
  end

  describe 'urlsafe_base64' do
    it 'generates URL-safe string without + or /' do
      code = '
        import("securerandom")
        niech u = SecureRandom.urlsafe_base64(32)
        pokazl u.dlg() > 0
        pokazl u.zawiera("+")
        pokazl u.zawiera("/")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nfalsz\nfalsz")
    end
  end

  describe 'uuid' do
    it 'generates 36-char UUID' do
      code = '
        import("securerandom")
        niech u = SecureRandom.uuid()
        pokazl u.dlg()
        pokazl u.zawiera("-")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("36\nprawda")
    end

    it 'generates unique UUIDs' do
      code = '
        import("securerandom")
        pokazl SecureRandom.uuid() != SecureRandom.uuid()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end
  end

  describe 'alfanumeryczny' do
    it 'generates 16-char string by default' do
      code = '
        import("securerandom")
        pokazl SecureRandom.alfanumeryczny().dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("16")
    end

    it 'generates specified length' do
      code = '
        import("securerandom")
        pokazl SecureRandom.alfanumeryczny(32).dlg()
        pokazl SecureRandom.alfanumeryczny(1).dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("32\n1")
    end
  end

  describe 'losowa_liczba' do
    it 'generates float [0, 1) without argument' do
      code = '
        import("securerandom")
        niech f = SecureRandom.losowa_liczba()
        pokazl f >= 0
        pokazl f < 1
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'generates int [0, n) with argument' do
      code = '
        import("securerandom")
        niech n = SecureRandom.losowa_liczba(100)
        pokazl n >= 0
        pokazl n < 100
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end
  end

  describe 'losowe_bajty' do
    it 'generates byte array of specified size' do
      code = '
        import("securerandom")
        niech b = SecureRandom.losowe_bajty(16)
        pokazl b.dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("16")
    end

    it 'values are in 0-255 range' do
      code = '
        import("securerandom")
        niech b = SecureRandom.losowe_bajty(1)
        pokazl b[0] >= 0
        pokazl b[0] <= 255
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end
  end

  describe 'losowa_z_zakresu' do
    it 'generates number within range' do
      code = '
        import("securerandom")
        niech z = SecureRandom.losowa_z_zakresu(10, 20)
        pokazl z >= 10
        pokazl z <= 20
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'handles single value range' do
      code = '
        import("securerandom")
        pokazl SecureRandom.losowa_z_zakresu(5, 5)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("5")
    end
  end

  describe 'token' do
    it 'generates 32-char token by default' do
      code = '
        import("securerandom")
        pokazl SecureRandom.token().dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("32")
    end

    it 'generates token of specified length' do
      code = '
        import("securerandom")
        pokazl SecureRandom.token(64).dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("64")
    end

    it 'generates unique tokens' do
      code = '
        import("securerandom")
        pokazl SecureRandom.token() != SecureRandom.token()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end
  end

  describe 'wybierz' do
    it 'generates string from given characters' do
      code = '
        import("securerandom")
        niech k = SecureRandom.wybierz("abc", 10)
        pokazl k.dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("10")
    end

    it 'uses only provided characters' do
      code = '
        import("securerandom")
        niech k = SecureRandom.wybierz("x", 5)
        pokazl k
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("xxxxx")
    end
  end

  describe 'cannot instantiate' do
    it 'raises error on SecureRandom.nowy()' do
      code = '
        import("securerandom")
        niech s = SecureRandom.nowy()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/SecureRandom jest klasą statyczną/)
      expect(last_command_started).to have_exit_status(1)
    end
  end
end
