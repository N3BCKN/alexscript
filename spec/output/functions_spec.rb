require 'aruba/rspec'

RSpec.describe 'Functions', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/lodz.rb', File.dirname(__FILE__)) }

  describe 'Function declaration and basic calls' do
    it 'declares and calls simple function' do
      code = '
        funkcja test() {
          pokazl "test"
        }
        test()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('test')
    end

    it 'returns value explicitly' do
      code = '
        funkcja get_value() {
          zwroc 42
        }
        pokazl get_value()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'handles implicit return (nic)' do
      code = '
        funkcja empty() {
          niech x = 5
        }
        pokazl empty()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('nic')
    end
  end

  describe 'Function arguments' do
    it 'accepts single argument' do
      code = '
        funkcja square(x) {
          zwroc x * x
        }
        pokazl square(5)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('25')
    end

    it 'accepts multiple arguments' do
      code = '
        funkcja sum(a, b, c) {
          zwroc a + b + c
        }
        pokazl sum(1, 2, 3)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('6')
    end

    it 'validates argument count' do
      code = '
        funkcja test(a, b) {
          zwroc a + b
        }
        test(1)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/expected 2 arguments/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'handles complex argument types' do
      code = '
        funkcja process(arr, obj) {
          zwroc arr[0] + obj["value"]
        }
        niech arr = [1, 2, 3]
        niech obj = {"value": 10}
        pokazl process(arr, obj)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('11')
    end
  end

  describe 'Variable scope and closures' do
    it 'maintains proper variable scope' do
      code = '
        niech x = 1
        funkcja test() {
          niech x = 2
          pokazl x
        }
        test()
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2\n1")
    end

    it 'accesses outer scope variables' do
      code = '
        niech x = 1
        funkcja test() {
          pokazl x
        }
        test()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('1')
    end

    it 'handles nested function scopes' do
      code = '
        funkcja outer() {
          niech x = 1
          funkcja inner() {
            niech x = 2
            zwroc x
          }
          zwroc x + inner()
        }
        pokazl outer()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end

    it 'maintains scope with argument shadowing' do
      code = '
        niech x = 1
        funkcja test(x) {
          pokazl x
        }
        test(2)
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2\n1")
    end
  end

  describe 'Return values and types' do
    it 'returns different types' do
      code = '
        funkcja get_int() { zwroc 42 }
        funkcja get_float() { zwroc 3.14 }
        funkcja get_string() { zwroc "text" }
        funkcja get_bool() { zwroc prawda }
        funkcja get_null() { zwroc nic }
        pokazl get_int()
        pokazl get_float()
        pokazl get_string()
        pokazl get_bool()
        pokazl get_null()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("42\n3.14\ntext\nprawda\nnic")
    end

    it 'returns arrays and objects' do
      code = '
        funkcja get_array() {
          zwroc [1, 2, 3]
        }
        funkcja get_object() {
          zwroc {"key": "value"}
        }
        pokazl get_array()
        pokazl get_object()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 2, 3]\n{"key": "value"}')
    end

    it 'handles early returns' do
      code = '
        funkcja early_return(x) {
          jesli x < 0 { zwroc "negative" }
          jesli x == 0 { zwroc "zero" }
          zwroc "positive"
        }
        pokazl early_return(-1)
        pokazl early_return(0)
        pokazl early_return(1)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("negative\nzero\npositive")
    end
  end

  describe 'Function recursion' do
    it 'handles simple recursion' do
      code = '
        funkcja factorial(n) {
          jesli n <= 1 { zwroc 1 }
          zwroc n * factorial(n - 1)
        }
        pokazl factorial(5)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('120')
    end

    it 'handles deep recursion with multiple arguments' do
      code = '
        funkcja fibonacci(n, a, b) {
          jesli n == 0 { zwroc a }
          zwroc fibonacci(n - 1, b, a + b)
        }
        pokazl fibonacci(6, 0, 1)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8')
    end
  end

  describe 'Error handling' do
    it 'handles undefined function calls' do
      code = '
        undefined_function()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Function.*not declared/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'handles calling non-function values' do
      code = '
        niech x = 5
        x()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Not a function/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'validates return value usage' do
      code = '
        funkcja test() {
          zwroc
        }
        pokazl test() + 1
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Invalid operation/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'handles stack overflow' do
      code = '
        funkcja recursive() {
          recursive()
        }
        recursive()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Stack overflow/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end

  describe 'Function as values' do
    it 'assigns function to variable' do
      code = '
        funkcja test() {
          zwroc 42
        }
        niech func = test
        pokazl func()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'passes function as argument' do
      code = '
        funkcja apply(func, x) {
          zwroc func(x)
        }
        funkcja double(x) {
          zwroc x * 2
        }
        pokazl apply(double, 5)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end
  end

  describe 'Complex function scenarios' do
    it 'handles function with multiple returns and branches' do
      code = '
        funkcja complex(x) {
          jesli x < 0 {
            zwroc "negative"
          } albojesli x == 0 {
            niech y = 5
            jesli y > 3 {
              zwroc "special zero"
            }
            zwroc "zero"
          } albo {
            dla niech indeks = 0; x; 1 {
              jesli indeks == 2 {
                zwroc "early exit"
              }
            }
            zwroc "positive"
          }
        }
        pokazl complex(-1)
        pokazl complex(0)
        pokazl complex(5)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("negative\nspecial zero\nearly exit")
    end

    it 'combines functions with other language features' do
      code = '
        funkcja process_array(arr) {
          niech sum = 0
          dla niech indeks = 0; arr.dlg; 1 {
            jesli arr[indeks] == nic {
              nastepny
            }
            sum = sum + arr[indeks]
          }
          zwroc sum
        }

        funkcja create_data() {
          niech arr = [1, nic, 3, nic, 5]
          zwroc process_array(arr)
        }

        pokazl create_data()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('9')
    end
  end
end
