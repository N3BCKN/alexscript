require 'aruba/rspec'

RSpec.describe 'Logical Operations', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/lodz.rb', File.dirname(__FILE__)) }

  describe 'Comparison operators' do
    it 'correctly compares numbers (==)' do
      code = 'pokazl 5 == 5'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'correctly compares different numbers (!=)' do
      code = 'pokazl 5 != 3'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'correctly compares greater/less than' do
      code = '
        pokazl 5 > 3
        pokazl 3 < 5
        pokazl 5 >= 5
        pokazl 3 <= 3
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda\nprawda")
    end

    it 'correctly compares strings' do
      code = 'pokazl "abc" == "abc"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end
  end

  describe 'Logical operators' do
    it 'performs AND operation' do
      code = 'pokazl prawda i prawda'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'performs OR operation' do
      code = 'pokazl falsz lub prawda'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'performs NOT operation' do
      code = 'pokazl !falsz'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'maintains correct order of logical operations' do
      code = 'pokazl prawda lub falsz i falsz'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end
  end

  describe 'Short-circuit evaluation' do
    it 'does not execute right side of OR if left is true' do
      code = '
        niech x = 5
        prawda lub (x = 10)
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end

    it 'does not execute right side of AND if left is false' do
      code = '
        niech x = 5
        falsz i (x = 10)
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end
  end
end

RSpec.describe 'Control Flow', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/lodz.rb', File.dirname(__FILE__)) }

  describe 'If statement' do
    it 'executes block when condition is true' do
      code = '
        jesli prawda {
          pokazl "wykonane"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('wykonane')
    end

    it 'does not execute block when condition is false' do
      code = '
        jesli falsz {
          pokazl "niewykonane"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('')
    end

    it 'handles else block' do
      code = '
        jesli falsz {
          pokazl "if"
        } albo {
          pokazl "else"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('else')
    end

    it 'handles else if blocks' do
      code = '
        niech x = 5
        jesli x < 3 {
          pokazl "mniej niz 3"
        } albojesli x < 7 {
          pokazl "mniej niz 7"
        } albo {
          pokazl "7 lub wiecej"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('mniej niz 7')
    end
  end

  describe 'Single-line if statement' do
    it 'executes instruction when condition is true' do
      code = 'jesli prawda to pokazl "wykonane"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('wykonane')
    end

    it 'does not execute instruction when condition is false' do
      code = 'jesli falsz to pokazl "niewykonane"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('')
    end
  end

  describe 'Nested conditional statements' do
    it 'correctly handles nested if-else' do
      code = '
        jesli prawda {
          jesli falsz {
            pokazl "niewykonane"
          } albo {
            pokazl "wykonane"
          }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('wykonane')
    end

    it 'maintains proper variable scope in nested blocks' do
      code = '
        niech x = 1
        jesli prawda {
          niech y = 2
          jesli prawda {
            niech z = 3
            pokazl x + y + z
          }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('6')
    end
  end

  describe 'While loop' do
    it 'executes loop while condition is true' do
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

    it 'skips loop when condition is initially false' do
      code = '
        niech x = 5
        dopoki x < 3 {
          pokazl x
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('')
    end

    it 'handles break statement' do
      code = '
        niech x = 0
        dopoki prawda {
          pokazl x
          x = x + 1
          jesli x > 2 {
            zakoncz
          }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2")
    end

    it 'handles continue statement' do
      code = '
        niech x = 0
        dopoki x < 4 {
          x = x + 1
          jesli x == 2 {
            nastepny
          }
          pokazl x
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n3\n4")
    end
  end
end
