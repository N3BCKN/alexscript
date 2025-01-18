require 'aruba/rspec'

RSpec.describe 'Control Flow', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/lodz.rb', File.dirname(__FILE__)) }

  describe 'While loop (dopoki)' do
    it 'executes basic while loop correctly' do
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

    it 'handles nested while loops' do
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

    it 'handles break statement in while loop' do
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

    it 'handles continue statement in while loop' do
      code = '
        niech x = 0
        dopoki x < 4 {
          x = x + 1
          jesli x == 2 { nastepny }
          pokazl x
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n3\n4")
    end
  end

  describe 'Infinite loop (petla)' do
    it 'executes infinite loop with break' do
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

    it 'handles nested infinite loops with breaks' do
      code = '
        niech x = 0
        petla {
          niech y = 0
          petla {
            pokazl x + y
            y = y + 1
            jesli y >= 2 { zakoncz }
          }
          x = x + 1
          jesli x >= 2 { zakoncz }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n1\n2")
    end
  end

  describe 'For loop (dla)' do
    it 'executes basic for loop correctly' do
      code = '
        dla niech indeks = 0; 3; 1 {
          pokazl indeks
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2")
    end

    it 'handles custom step in for loop' do
      code = '
        dla niech indeks = 0; 6; 2 {
          pokazl indeks
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n2\n4")
    end

    it 'handles negative step in for loop' do
      code = '
        dla niech indeks = 5; 0; -1 {
          pokazl indeks
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("5\n4\n3\n2\n1")
    end

    it 'handles break in for loop' do
      code = '
        dla niech indeks = 0; 5; 1 {
          jesli indeks > 2 { zakoncz }
          pokazl indeks
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2")
    end

    it 'handles continue in for loop' do
      code = '
        dla niech indeks = 0; 4; 1 {
          jesli indeks == 2 { nastepny }
          pokazl indeks
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n3")
    end
  end

  describe 'If statements' do
    it 'handles basic if statement' do
      code = '
        niech x = 5
        jesli x > 3 {
          pokazl "greater"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('greater')
    end

    it 'handles if-else statement' do
      code = '
        niech x = 2
        jesli x > 3 {
          pokazl "greater"
        } albo {
          pokazl "smaller"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('smaller')
    end

    it 'handles multiple else-if statements' do
      code = '
        niech x = 5
        jesli x < 3 {
          pokazl "small"
        } albojesli x < 7 {
          pokazl "medium"
        } albojesli x < 10 {
          pokazl "large"
        } albo {
          pokazl "very large"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('medium')
    end

    it 'handles one-liner if statements' do
      code = '
        niech x = 5
        jesli x > 3 to pokazl "greater"
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('greater')
    end
  end

  describe 'Null value (nic) handling' do
    it 'handles null in conditions' do
      code = '
        niech x = nic
        jesli x == nic {
          pokazl "is null"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('is null')
    end

    it 'handles null in comparisons' do
      code = '
        pokazl nic == nic
        pokazl nic != 5
        pokazl 5 != nic
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end

    it 'handles null in loops' do
      code = '
        niech x = 0
        niech y = nic
        dopoki x < 3 {
          jesli y == nic {
            pokazl "null"
          }
          x = x + 1
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("null\nnull\nnull")
    end

    it 'handles operations with null' do
      code = '
        niech x = nic
        niech y = 5
        pokazl x + y
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end
  end

  describe 'Complex control flow scenarios' do
    it 'combines different control structures' do
      code = '
        dla niech indeks = 0; 3; 1 {
          jesli indeks == 1 {
            nastepny
          }
          niech j = 0
          dopoki j < 2 {
            pokazl indeks * j
            j = j + 1
          }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n0\n0\n0")
    end

    it 'handles nested conditions with null checks' do
      code = '
        niech x = 5
        niech y = nic
        jesli x > 3 {
          jesli y == nic {
            pokazl "nested null"
          } albo {
            pokazl "nested value"
          }
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nested null')
    end

    it 'handles complex loop termination' do
      code = '
        niech x = 0
        petla {
          x = x + 1
          jesli x == 2 { nastepny }
          jesli x == 4 { zakoncz }
          pokazl x
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n3")
    end
  end

  describe 'Error handling in control structures' do
    it 'handles undefined variables in conditions' do
      code = '
        jesli undefined > 5 {
          pokazl "error"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Undeclared identifier/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'handles type errors in conditions' do
      code = '
        niech x = "string"
        jesli x > 5 {
          pokazl "error"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Unsupported operator/)
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
  end

  describe 'Scope handling' do
    it 'maintains proper variable scope in control structures' do
      code = '
        niech x = 1
        jesli prawda {
          niech y = 2
          pokazl x + y
        }
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("3\n1")
    end

    it 'handles variable shadowing in nested blocks' do
      code = '
        niech x = 1
        jesli prawda {
          niech x = 2
          pokazl x
        }
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2\n1")
    end
  end

  describe 'If oneliners' do
    it 'executes code when condition is true' do
      code = 'jesli prawda to pokazl "prawda"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'does not execute code when condition is false' do
      code = '
      niech x = 1
      jesli 5 > 6 to x = 2
      pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('1')
    end

    it 'returns an error when then statement (to) is missing' do
      code = 'jesli prawda pokazl 5'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Expected 'tok_lcurly', found 'pokazl/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end
end
