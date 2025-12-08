require 'aruba/rspec'

RSpec.describe 'Primitive Values (Bool and Null)', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Bool values display without quotes' do
    it 'displays prawda without quotes' do
      code = 'pokazl prawda'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
      expect(last_command_started.output.strip).not_to include('"')
    end

    it 'displays falsz without quotes' do
      code = 'pokazl falsz'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
      expect(last_command_started.output.strip).not_to include('"')
    end

    it 'displays nic without quotes' do
      code = 'pokazl nic'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('nic')
      expect(last_command_started.output.strip).not_to include('"')
    end

    it 'displays string with quotes' do
      code = 'pokazl "prawda"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('"prawda"')
    end
  end

  describe 'Bool values in variables' do
    it 'displays bool variable without quotes' do
      code = '
        niech x = prawda
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
      expect(last_command_started.output.strip).not_to include('"')
    end

    it 'displays null variable without quotes' do
      code = '
        niech x = nic
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('nic')
      expect(last_command_started.output.strip).not_to include('"')
    end
  end

  describe 'Bool comparisons' do
    it 'compares prawda == prawda correctly' do
      code = 'pokazl prawda == prawda'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'compares prawda == falsz correctly' do
      code = 'pokazl prawda == falsz'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
    end

    it 'compares nic == nic correctly' do
      code = 'pokazl nic == nic'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end
  end

  describe 'Bool in logic operations' do
    it 'works with logical AND' do
      code = 'pokazl prawda i prawda'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'works with logical OR' do
      code = 'pokazl falsz lub prawda'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'works with logical NOT' do
      code = 'pokazl !falsz'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end
  end

  describe 'Functions returning bool' do
    it 'returns prawda from function without quotes' do
      code = '
        funkcja test() {
          zwroc prawda
        }
        pokazl test()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
      expect(last_command_started.output.strip).not_to include('"')
    end

    it 'returns falsz from function without quotes' do
      code = '
        funkcja test() {
          zwroc falsz
        }
        pokazl test()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
      expect(last_command_started.output.strip).not_to include('"')
    end

    it 'returns nic from function without quotes' do
      code = '
        funkcja test() {
          zwroc nic
        }
        pokazl test()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('nic')
      expect(last_command_started.output.strip).not_to include('"')
    end
  end

  describe 'Built-in methods returning bool' do
    it 'array.pusta() returns falsz without quotes' do
      code = '
        niech arr = [1, 2, 3]
        pokazl arr.pusta()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
      expect(last_command_started.output.strip).not_to include('"')
    end

    it 'empty array.pusta() returns prawda without quotes' do
      code = '
        niech arr = []
        pokazl arr.pusta()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
      expect(last_command_started.output.strip).not_to include('"')
    end

    it 'string.zawiera() returns prawda without quotes' do
      code = '
        niech tekst = "hello"
        pokazl tekst.zawiera("ell")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
      expect(last_command_started.output.strip).not_to include('"')
    end
  end

  describe 'Bool and null .typ() method' do
    it 'prawda.typ() returns logiczna' do
      code = '
        niech x = prawda
        pokazl x.typ()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('logiczna')
    end

    it 'falsz.typ() returns logiczna' do
      code = '
        niech x = falsz
        pokazl x.typ()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('logiczna')
    end

    it 'nic.typ() returns null' do
      code = '
        niech x = nic
        pokazl x.typ()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('null')
    end
  end

  describe 'Bool and null .napis() method' do
    it 'prawda.napis() returns prawda' do
      code = '
        niech x = prawda
        pokazl x.napis()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'nic.napis() returns nic' do
      code = '
        niech x = nic
        pokazl x.napis()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end
  end

  describe 'Bool in arrays' do
    it 'displays array with bool values without quotes' do
      code = '
        niech arr = [prawda, falsz, nic]
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      output = last_command_started.output.strip
      expect(output).to include('prawda')
      expect(output).to include('falsz')
      expect(output).to include('nic')
    end
  end

  describe 'Bool in objects' do
    it 'displays object with bool values' do
      code = '
        niech obj = {"flag": prawda, "empty": nic}
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      output = last_command_started.output.strip
      expect(output).to include('prawda')
      expect(output).to include('nic')
    end
  end

  describe 'Conditional with bool' do
    it 'executes if block with prawda' do
      code = '
        jesli prawda {
          pokazl "dziala"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('dziala')
    end

    it 'skips if block with falsz' do
      code = '
        jesli falsz {
          pokazl "nie dziala"
        } albo {
          pokazl "dziala"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('dziala')
    end
  end
end