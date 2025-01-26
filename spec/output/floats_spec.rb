require 'aruba/rspec'

RSpec.describe 'Array Operations', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/lodz.rb', File.dirname(__FILE__)) }

  describe 'build in methods' do
    it 'performs methods on floats not assigned to variables' do
      code = 'pokazl 4.322.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('zmiennoprzecinkowa')
    end

    it 'rerurns type properly' do
      code = 'niech x = 4.32
      pokazl x.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('zmiennoprzecinkowa')
    end

    it 'converts value to string' do
      code = 'niech x = 4.32
      pokazl x.napis()
      pokazl x.napis().typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("4.32\nnapis")
    end

    it 'returns an absolute value' do
      code = 'niech x = -4.32
      pokazl x.abs()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4.32')
    end

    it 'returns rounded value' do
      code = 'niech x = 4.32
      pokazl x.zaokragl()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4')
    end

    it 'returns rounded value with precision' do
      code = 'niech x = 4.323223
      pokazl x.zaokragl(2)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4.32')
    end

    it 'returns floor value with precision' do
      code = 'niech x = 4.323223
      pokazl x.zaokragl_dol(2)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4.32')
    end

    it 'returns ceiling value with precision' do
      code = 'niech x = 4.327
      pokazl x.zaokragl_gora(2)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4.33')
    end
  end
end
