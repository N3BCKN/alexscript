require 'aruba/rspec'

RSpec.describe 'Compound Operators', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Addition assignment (+=)' do
    it 'adds integers correctly' do
      code = '
        niech x = 5
        x += 3
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8')
    end

    it 'adds floats correctly' do
      code = '
        niech x = 5.5
        x += 3.3
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8.8')
    end

    it 'handles mixed number types' do
      code = '
        niech x = 5
        x += 3.5
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8.5')
    end

    it 'concatenates strings' do
      code = '
        niech str = "Hello"
        str += " World"
        pokazl str
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Hello World')
    end

    # it 'raises error when adding incompatible types' do
    #   code = '
    #     niech x = 5
    #     x += "3"
    #   '
    #   run_command_and_stop "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started).to have_output(/Unsupported operator/)
    #   expect(last_command_started.exit_status).not_to eq(0)
    # end
  end

  describe 'Subtraction assignment (-=)' do
    it 'subtracts integers correctly' do
      code = '
        niech x = 10
        x -= 3
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('7')
    end

    it 'subtracts floats correctly' do
      code = '
        niech x = 5.5
        x -= 2.2
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3.3')
    end

    it 'handles mixed number types' do
      code = '
        niech x = 10
        x -= 2.5
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('7.5')
    end

    # it 'raises error when subtracting strings' do
    #   code = '
    #     niech str = "Hello"
    #     str -= " World"
    #   '
    #   run_command "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started).to have_output(/Unsupported operator/)
    #   expect(last_command_started.exit_status).not_to eq(0)
    # end

    # it 'raises error when subtracting incompatible types' do
    #   code = '
    #     niech x = 5
    #     x -= "3"
    #   '
    #   run_command "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started).to have_output(/Unsupported operator/)
    #   expect(last_command_started.exit_status).not_to eq(0)
    # end
  end

  describe 'Multiplication assignment (*=)' do
    it 'multiplies integers correctly' do
      code = '
        niech x = 5
        x *= 3
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('15')
    end

    it 'multiplies floats correctly' do
      code = '
        niech x = 2.5
        x *= 2.0
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5.0')
    end

    it 'handles mixed number types' do
      code = '
        niech x = 5
        x *= 2.5
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('12.5')
    end

    it 'raises error when multiplying strings' do
      code = '
        niech str = "Hello"
        str *= 3
        pokazl str
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('HelloHelloHello')
    end

    it 'handles multiplication by zero' do
      code = '
        niech x = 5
        x *= 0
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('0')
    end
  end

  describe 'Division assignment (/=)' do
    it 'divides integers correctly' do
      code = '
        niech x = 10
        x /= 2
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end

    it 'divides floats correctly' do
      code = '
        niech x = 5.5
        x /= 2.0
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2.75')
    end

    it 'handles mixed number types' do
      code = '
        niech x = 10
        x /= 2.5
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4.0')
    end

    it 'raises error when dividing by zero' do
      code = '
        niech x = 10
        x /= 0
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Dzielenie przez zero/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    # it 'raises error when dividing strings' do
    #   code = '
    #     niech str = "Hello"
    #     str /= 2
    #   '
    #   run_command "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started).to have_output(/Unsupported operator/)
    #   expect(last_command_started.exit_status).not_to eq(0)
    # end
  end

  describe 'Multiple compound operations' do
    it 'handles multiple operators in sequence' do
      code = '
        niech x = 10
        x += 5
        x *= 2
        x -= 7
        x /= 2
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('11')
    end

    it 'maintains correct type through operations' do
      code = '
        niech x = 10
        x /= 2
        x += 1.5
        x *= 2
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('13.0')
    end
  end

  describe 'Compound operators with variables' do
    it 'handles operations with other variables' do
      code = '
        niech x = 10
        niech y = 5
        x += y
        pokazl x
        x *= y
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("15\n75")
    end

    it 'raises error on undefined variables' do
      code = '
        niech x = 5
        x += undefined_var
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niezadeklarowany identyfikator/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end

  describe 'Compound operators with expressions' do
    it 'handles compound assignment with expressions' do
      code = '
        niech x = 10
        x += 2 * 3
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('16')
    end

    it 'handles complex expressions in compound assignment' do
      code = '
        niech x = 5
        niech y = 3
        x += (y * 2) + 1
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('12')
    end
  end

  describe 'Edge cases and error conditions' do
    it 'raises error on constant modification' do
      code = '
        niech CONSTANT = 5
        CONSTANT += 3
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Zmienna CONSTANT jest stala/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'handles very large numbers' do
      code = '
        niech x = 1000000
        x *= 1000000
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('1000000000000')
    end

    it 'handles very small numbers' do
      code = '
        niech x = 0.0000001
        x += 0.0000002
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3.0e-07')
    end

    it 'raises error on uninitialized variable compound assignment' do
      code = '
        niech x
        x += 5
      '
      run_command "ruby #{main_file_path} '#{code}'"
      # expect(last_command_started).to have_output(/Uninitialized/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end
end
