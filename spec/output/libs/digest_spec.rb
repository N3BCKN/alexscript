require 'aruba/rspec'

RSpec.describe 'Digest native library', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }
  let(:test_file) { '/tmp/as_digest_rspec.txt' }

  after(:each) { FileUtils.rm_f(test_file) }

  describe 'MD5' do
    it 'computes correct MD5 hex digest' do
      code = '
        import("digest")
        pokazl Digest.md5("hello")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("5d41402abc4b2a76b9719d911017c592")
    end

    it 'returns 32-char hex string' do
      code = '
        import("digest")
        pokazl Digest.md5("test").dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("32")
    end

    it 'returns base64 digest' do
      code = '
        import("digest")
        pokazl Digest.md5_base64("hello").dlg() > 0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'returns byte array of 16 elements' do
      code = '
        import("digest")
        pokazl Digest.md5_bajty("hello").dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("16")
    end
  end

  describe 'SHA1' do
    it 'computes correct SHA1 hex digest' do
      code = '
        import("digest")
        pokazl Digest.sha1("hello")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d")
    end

    it 'returns 40-char hex string' do
      code = '
        import("digest")
        pokazl Digest.sha1("test").dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("40")
    end
  end

  describe 'SHA256' do
    it 'computes correct SHA256 hex digest' do
      code = '
        import("digest")
        pokazl Digest.sha256("hello")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    end

    it 'returns 64-char hex string' do
      code = '
        import("digest")
        pokazl Digest.sha256("test").dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("64")
    end

    it 'returns 32-byte array' do
      code = '
        import("digest")
        pokazl Digest.sha256_bajty("hello").dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("32")
    end

    it 'is deterministic' do
      code = '
        import("digest")
        pokazl Digest.sha256("abc") == Digest.sha256("abc")
        pokazl Digest.sha256("abc") != Digest.sha256("xyz")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end
  end

  describe 'SHA384' do
    it 'returns 96-char hex string' do
      code = '
        import("digest")
        pokazl Digest.sha384("hello").dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("96")
    end
  end

  describe 'SHA512' do
    it 'returns 128-char hex string' do
      code = '
        import("digest")
        pokazl Digest.sha512("hello").dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("128")
    end
  end

  describe 'HMAC' do
    it 'computes HMAC-SHA256' do
      code = '
        import("digest")
        niech h = Digest.hmac_sha256("key", "msg")
        pokazl h.dlg()
        pokazl Digest.hmac_sha256("key", "msg") == h
        pokazl Digest.hmac_sha256("other", "msg") != h
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("64\nprawda\nprawda")
    end

    it 'computes HMAC-SHA512' do
      code = '
        import("digest")
        pokazl Digest.hmac_sha512("key", "msg").dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("128")
    end

    it 'computes HMAC-MD5 and HMAC-SHA1' do
      code = '
        import("digest")
        pokazl Digest.hmac_md5("key", "msg").dlg()
        pokazl Digest.hmac_sha1("key", "msg").dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("32\n40")
    end
  end

  describe 'comparison' do
    it 'compares digests securely' do
      code = '
        import("digest")
        niech a = Digest.sha256("test")
        niech b = Digest.sha256("test")
        niech c = Digest.sha256("other")
        pokazl Digest.porownaj(a, b)
        pokazl Digest.porownaj(a, c)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nfalsz")
    end
  end

  describe 'hex/bytes conversion' do
    it 'converts hex to bytes and back' do
      code = '
        import("digest")
        niech b = Digest.hex_na_bajty("48656c6c6f")
        pokazl b.dlg()
        pokazl b[0]
        niech h = Digest.bajty_na_hex([72, 101, 108, 108, 111])
        pokazl h
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("5\n72\n48656c6c6f")
    end
  end

  describe 'file hashing' do
    it 'hashes file content same as string' do
      File.write(test_file, 'hello')
      code = "
        import(\"digest\")
        pokazl Digest.sha256_plik(\"#{test_file}\")
      "
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    end
  end
end
