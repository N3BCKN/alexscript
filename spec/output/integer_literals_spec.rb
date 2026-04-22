require 'aruba/rspec'

RSpec.describe 'Integer Literals', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'binary literals' do
    it 'parses 0b prefix' do
      code = 'pokazl 0b1010'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end

    it 'parses uppercase 0B prefix' do
      code = 'pokazl 0B1111'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('15')
    end

    it 'works inside expressions' do
      code = 'pokazl 0b1100 & 0b1010'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8')
    end
  end

  describe 'hexadecimal literals' do
    it 'parses 0x prefix' do
      code = 'pokazl 0xFF'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('255')
    end

    it 'parses lowercase hex digits' do
      code = 'pokazl 0xdeadbeef'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3735928559')
    end

    it 'parses uppercase 0X prefix' do
      code = 'pokazl 0X10'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('16')
    end
  end

  describe 'octal literals' do
    it 'parses 0o prefix' do
      code = 'pokazl 0o777'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('511')
    end

    it 'parses uppercase 0O prefix' do
      code = 'pokazl 0O10'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8')
    end
  end

  describe 'interaction with decimals' do
    it 'still parses plain integer' do
      code = 'pokazl 42'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'still parses zero' do
      code = 'pokazl 0'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('0')
    end

    it 'still parses floats' do
      code = 'pokazl 0.5'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('0.5')
    end
  end

  describe 'literal errors' do
    it 'rejects empty binary literal' do
      code = 'pokazl 0b'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include('Nieprawidlowy literal binarny')
    end

    it 'rejects empty hex literal' do
      code = 'pokazl 0x'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include('Nieprawidlowy literal szesnastkowy')
    end
  end
end