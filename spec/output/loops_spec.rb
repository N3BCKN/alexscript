require 'aruba/rspec'

RSpec.describe 'Loops', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/lodz.rb', File.dirname(__FILE__)) }

  describe 'For loop (dla)' do
    it 'iterates with positive step' do
      code = '
        niech sum = 0
        dla niech i = 0; 3; 1 {
          sum = sum + i
        }
        pokazl sum
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end

    it 'iterates with negative step' do
      code = '
        niech sum = 0
        dla niech i = 5; 2; -1 {
          sum = sum + i
        }
        pokazl sum
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('14')
    end

    it 'handles custom step values' do
      code = '
        niech result = []
        dla niech i = 0; 10; 2 {
          result.dodaj(i)
        }
        pokazl result
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[0, 2, 4, 6, 8]')
    end

    it 'maintains proper variable scope' do
      code = '
        niech x = 0
        dla niech i = 0; 2; 1 {
          niech x = i
          pokazl x
        }
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n0")
    end

    it 'allows nested for loops' do
      code = '
        dla niech i = 0; 2; 1 {
          dla niech j = 0; 2; 1 {
            pokazl i * j
          }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n0\n0\n1")
    end
  end

  describe 'While loop (dopoki)' do
    it 'executes while condition is true' do
      code = '
        niech x = 0
        dopoki x < 3 {
          pokazl x
          x = x + 1
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2")
    end

    it 'handles complex conditions' do
      code = '
        niech x = 0
        niech y = 10
        dopoki x < 3 i y > 7 {
          pokazl x
          x = x + 1
          y = y - 1
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2")
    end

    it 'maintains variable scope' do
      code = '
        niech x = 0
        dopoki x < 2 {
          niech y = x * 2
          pokazl y
          x = x + 1
        }
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n2\n2")
    end

    it 'allows nested while loops' do
      code = '
        niech x = 0
        dopoki x < 2 {
          niech y = 0
          dopoki y < 2 {
            pokazl x * y
            y = y + 1
          }
          x = x + 1
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n0\n0\n1")
    end
  end

  describe 'Infinite loop (petla)' do
    it 'executes until break' do
      code = '
        niech x = 0
        petla {
          pokazl x
          x = x + 1
          jesli x >= 3 { zakoncz }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2")
    end

    it 'handles nested infinite loops' do
      code = '
        niech x = 0
        petla {
          niech y = 0
          petla {
            pokazl x * y
            y = y + 1
            jesli y >= 2 { zakoncz }
          }
          x = x + 1
          jesli x >= 2 { zakoncz }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n0\n0\n1")
    end
  end

  describe 'Loop control statements' do
    it 'handles break in for loop' do
      code = '
        dla niech i = 0; 5; 1 {
          jesli i > 2 { zakoncz }
          pokazl i
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2")
    end

    it 'handles continue in for loop' do
      code = '
        dla niech i = 0; 5; 1 {
          jesli i == 2 { nastepny }
          pokazl i
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n3\n4")
    end

    it 'handles break in while loop' do
      code = '
        niech x = 0
        dopoki prawda {
          pokazl x
          x = x + 1
          jesli x > 2 { zakoncz }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2")
    end

    it 'handles continue in while loop' do
      code = '
        niech x = 0
        dopoki x < 5 {
          x = x + 1
          jesli x == 3 { nastepny }
          pokazl x
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n2\n4\n5")
    end
  end

  describe 'Loop with array operations' do
    it 'modifies array in for loop' do
      code = '
        niech arr = [1, 2, 3, 4]
        dla niech i = 0; arr.dlg; 1 {
          arr[i] = arr[i] * 2
        }
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[2, 4, 6, 8]')
    end

    it 'builds array in while loop' do
      code = '
        niech arr = []
        niech x = 0
        dopoki x < 3 {
          arr.dodaj(x * x)
          x = x + 1
        }
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[0, 1, 4]')
    end
  end

  describe 'Error handling in loops' do
    it 'handles undefined variables in loop condition' do
      code = '
        dopoki undefined < 5 {
          pokazl "error"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Undeclared identifier/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'handles invalid loop conditions' do
      code = '
        dopoki "string" {
          pokazl "error"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Condition must be boolean/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'handles array bounds errors in loops' do
      code = '
        niech arr = [1, 2, 3]
        dla niech i = 0; 5; 1 {
          pokazl arr[i]
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Array index out of bounds/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end

  describe 'Variable scope and shadowing' do
    it 'allows shadowing in nested loops' do
      code = '
        niech x = 0
        dla niech i = 0; 2; 1 {
          niech x = i
          pokazl x
        }
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n0")
    end

    it 'maintains proper scope for loop variables' do
      code = '
        dla niech i = 0; 2; 1 {
          niech temp = i
        }
        pokazl temp
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Undeclared identifier/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'handles complex nested scopes' do
      code = '
        niech x = 0
        dla niech i = 0; 2; 1 {
          niech x = i
          dla niech j = 0; 2; 1 {
            niech x = j
            pokazl x
          }
          pokazl x
        }
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n1\n0\n1\n1\n0")
    end
  end

  describe 'Mixed loop types' do
    it 'combines different loop types' do
      code = '
        niech x = 0
        dla niech i = 0; 2; 1 {
          dopoki x < i + 2 {
            pokazl x
            x = x + 1
          }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2\n3")
    end

    it 'handles breaks across nested different loop types' do
      code = '
        dla niech i = 0; 3; 1 {
          petla {
            pokazl i
            zakoncz
          }
          jesli i == 1 { zakoncz }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1")
    end
  end
end
