require 'aruba/rspec'

RSpec.describe 'Advanced Variable Operations', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Multiple variable declarations' do
    it 'handles multiple declarations in sequence' do
      code = '
        niech x = 5
        niech y = 10
        niech z = 15
        pokazl x + y + z
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('30')
    end

    it 'allows using previous variables in new declarations' do
      code = '
        niech x = 5
        niech y = x + 3
        niech z = y * 2
        pokazl z
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('16')
    end

    it 'maintains correct type inference in chained declarations' do
      code = '
        niech x = 5
        niech y = x / 2
        pokazl y
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2.5')
    end
  end

  describe 'Variable reassignment and mutations' do
    it 'allows multiple reassignments of the same variable' do
      code = '
        niech x = 5
        x = 10
        x = 15
        x = x + 5
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('20')
    end

    it 'handles compound assignments with different operators' do
      code = '
        niech x = 10
        x += 5
        pokazl x
        x -= 3
        pokazl x
        x *= 2
        pokazl x
        x /= 4
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("15\n12\n24\n6")
    end

    it 'maintains type through reassignments' do
      code = '
        niech x = 5
        x = x + 0.5
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5.5')
    end
  end

  describe 'Cross-type operations' do
    it 'handles string and number concatenation' do
      code = '
        niech text = "Value: "
        niech num = 42
        pokazl text + num
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Value: 42')
    end

    it 'handles mixed numeric types in operations' do
      code = '
        niech x = 5
        niech y = 2.5
        niech z = x * y
        pokazl z
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('12.5')
    end

    it 'performs correct type conversion in complex operations' do
      code = '
        niech a = 10
        niech b = 3
        niech c = a / b
        pokazl c
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3.3333333333333335')
    end
  end

  describe 'Error handling and edge cases' do
    it 'raises error on undefined variable usage' do
      code = '
        pokazl undeclared_var
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niezadeklarowany identyfikator/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'raises error on invalid type operations' do
      code = '
        niech text = "hello"
        niech num = 5
        pokazl text - num
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niewspierany operator - pomiedzy hello a 5/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'raises error on constant reassignment' do
      code = '
        niech CONST = 5
        CONST = 10
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Zmienna CONST jest stala i nie moze byc zmieniana/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  describe 'Scope and visibility' do
    it 'correctly handles nested scope declarations' do
      code = '
        niech x = 1
        jesli prawda {
          niech y = 2
          pokazl x + y
          jesli prawda {
            niech z = 3
            pokazl x + y + z
          }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("3\n6")
    end

    it 'maintains proper variable shadowing' do
      code = '
        niech x = 5
        jesli prawda {
          niech x = 10
          pokazl x
        }
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("10\n5")
    end

    it 'raises error on accessing out-of-scope variables' do
      code = '
        jesli prawda {
          niech x = 5
        }
        pokazl x
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niezadeklarowany identyfikator/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  describe 'Type conversion and coercion' do
    it 'handles implicit numeric type conversion' do
      code = '
        niech x = 5
        niech y = 2.5
        pokazl x + y
        pokazl x * y
        pokazl y / x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("7.5\n12.5\n0.5")
    end

    it 'maintains integer type when possible' do
      code = '
        niech x = 10
        niech y = 2
        pokazl x / y
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end

    it 'raises error on invalid type conversions' do
      code = '
        niech x = "5"
        niech y = 3
        pokazl x * y
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niewspierany operator/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  describe 'Complex expressions' do
    it 'handles complex mathematical expressions' do
      code = '
        niech x = 5
        niech y = 3
        niech z = 2
        pokazl (x + y) * z - (x / y)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('14.333333333333334')
    end

    it 'handles complex string operations' do
      code = '
        niech name = "John"
        niech age = 25
        niech message = "Name: " + name + ", Age: " + age
        pokazl message
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Name: John, Age: 25')
    end

    it 'handles mixed boolean expressions' do
      code = '
        niech x = 5
        niech y = 10
        pokazl (x < y) i (x + 5 == y) i !(x == y)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'Edge cases and boundary conditions' do
    it 'handles zero value operations correctly' do
      code = '
        niech x = 0
        pokazl 5 + x
        pokazl 5 * x
        pokazl 5 - x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("5\n0\n5")
    end

    it 'handles very large numbers' do
      code = '
        niech x = 1000000
        niech y = 2000000
        pokazl x * y
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2000000000000')
    end

    it 'handles very small decimal numbers' do
      code = '
        niech x = 0.0000001
        niech y = 0.0000002
        pokazl x + y
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3.0e-07')
    end
  end
end
