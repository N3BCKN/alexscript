require 'aruba/rspec'

RSpec.describe 'Array Operations', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/lodz.rb', File.dirname(__FILE__)) }

  describe 'build in methods' do
    it 'rerurns type properly' do
      code = 'niech x = 4
      pokazl x.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('calkowita')
    end

    it 'converts value to string' do
      code = 'niech x = 4
      pokazl x.napis()
      pokazl x.napis().typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("4\nnapis")
    end

    it 'returns an absolute value' do
      code = 'niech x = -4
      pokazl x.abs()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4')
    end

    it 'returns true if even' do
      code = 'niech x = 4
      pokazl x.parzysta()
      pokazl x.nieparzysta'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz")
    end

    it 'returns true if odd' do
      code = 'niech x = 5
      pokazl x.parzysta()
      pokazl x.nieparzysta'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("falsz\nprawda")
    end
  end
end
