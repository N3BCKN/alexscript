require 'aruba/rspec'

RSpec.describe 'Cli', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Basic type declarations' do
    it 'correctly declares integer variable' do
      code = 'niech x = 5 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end

    it 'correctly declares float variable' do
      code = 'niech x = 5.5 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5.5')
    end

    it 'correctly declares string variable' do
      code = 'niech text = "Hello" pokazl text'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Hello')
    end

    it 'correctly declares boolean variable' do
      code = 'niech flag = prawda pokazl flag'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'correctly declares null variable' do
      code = 'niech empty = nic pokazl empty'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end
  end

  describe 'Variable scope' do
    it 'maintains local variable in block' do
      code = '
        niech x = 5
        jesli prawda {
          niech y = 10
          pokazl y
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end

    it 'cannot access local variable outside block' do
      code = '
        jesli prawda {
          niech x = 5
        }
        pokazl x
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niezadeklarowany identyfikator x/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'can access global variable in any scope' do
      code = '
        globalna niech x = 5
        jesli prawda {
          pokazl x
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end
  end

  describe 'Constants' do
    it 'allows declaring constant (UPPERCASE)' do
      code = 'niech CONSTANT = 100 pokazl CONSTANT'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('100')
    end

    it 'prevents changing constant value' do
      code = '
        niech CONSTANT = 100
        CONSTANT = 200
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Zmienna CONSTANT jest stala i nie moze byc zmieniana/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'returns proper type of constant variable' do
      code = 'niech CONSTANT = 100 pokazl CONSTANT.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('calkowita')
    end 
  end

  describe 'Variable modification' do
    it 'allows reassigning variable value' do
      code = '
        niech x = 5
        x = 10
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end

    it 'allows compound operators modification (+= etc)' do
      code = '
        niech x = 5
        x += 3
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8')
    end
  end
end

RSpec.describe 'Arithmetic Operations', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Integer operations' do
    it 'performs addition correctly' do
      code = 'niech x = 5 + 3 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8')
    end

    it 'performs subtraction correctly' do
      code = 'niech x = 5 - 3 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2')
    end

    it 'performs multiplication correctly' do
      code = 'niech x = 5 * 3 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('15')
    end

    it 'performs division correctly' do
      code = 'niech x = 6 / 2 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end

    it 'performs division with automatic float conversion' do
      code = 'niech x = 5 / 2 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2.5')
    end

    it 'performs exponentiation correctly' do
      code = 'niech x = 2 ** 3 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8')
    end

    it 'performs modulo correctly' do
      code = 'niech x = 7 % 3 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('1')
    end
  end

  describe 'Float operations' do
    it 'adds float and integer correctly' do
      code = 'niech x = 5.5 + 3 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8.5')
    end

    it 'subtracts float from float correctly' do
      code = 'niech x = 5.5 - 2.2 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3.3')
    end

    it 'multiplies float by integer correctly' do
      code = 'niech x = 2.5 * 3 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('7.5')
    end

    it 'divides float by float correctly' do
      code = 'niech x = 5.0 / 2.0 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2.5')
    end
  end

  describe 'Complex arithmetic operations' do
    it 'maintains correct operation order' do
      code = 'niech x = 2 + 3 * 4 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('14')
    end

    it 'respects parentheses in operations' do
      code = 'niech x = (2 + 3) * 4 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('20')
    end

    it 'handles complex calculations correctly' do
      code = 'niech x = (5 + 3) * 2 - 4 / 2 pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('14')
    end
  end

  describe 'Arithmetic error handling' do
    it 'raises error on division by zero' do
      code = 'niech x = 5 / 0'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Dzielenie przez zero/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'raises error on invalid operations' do
      code = 'niech x = "text" * 5'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niewspierany operator/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end
end
