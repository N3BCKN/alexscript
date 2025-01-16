RSpec.describe 'Advanced Variable Operations' do
  describe 'Multiple variable declarations' do
    it 'handles multiple declarations in sequence' do
      code = '
        niech x = 5
        niech y = 10
        niech z = 15
        pokazl x + y + z
      '
      expect(execute_code(code)).to eq("30\n")
    end

    it 'allows using previous variables in new declarations' do
      code = '
        niech x = 5
        niech y = x + 3
        niech z = y * 2
        pokazl z
      '
      expect(execute_code(code)).to eq("16\n")
    end

    it 'maintains correct type inference in chained declarations' do
      code = '
        niech x = 5
        niech y = x / 2
        pokazl y
      '
      expect(execute_code(code)).to eq("2.5\n")
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
      expect(execute_code(code)).to eq("20\n")
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
      expect(execute_code(code)).to eq("15\n12\n24\n6\n")
    end

    it 'maintains type through reassignments' do
      code = '
        niech x = 5
        x = x + 0.5
        pokazl x
      '
      expect(execute_code(code)).to eq("5.5\n")
    end
  end

  describe 'Cross-type operations' do
    it 'handles string and number concatenation' do
      code = '
        niech text = "Value: "
        niech num = 42
        pokazl text + num
      '
      expect(execute_code(code)).to eq("Value: 42\n")
    end

    it 'handles mixed numeric types in operations' do
      code = '
        niech x = 5
        niech y = 2.5
        niech z = x * y
        pokazl z
      '
      expect(execute_code(code)).to eq("12.5\n")
    end

    it 'performs correct type conversion in complex operations' do
      code = '
        niech a = 10
        niech b = 3
        niech c = a / b
        pokazl c
      '
      expect(execute_code(code)).to eq("3.3333333333333335\n")
    end
  end

  describe 'Error handling and edge cases' do
    it 'raises error on redeclaration of existing variable' do
      code = '
        niech x = 5
        niech x = 10
      '
      expect { execute_code(code) }.to raise_error(RuntimeError, /already declared/)
    end

    it 'raises error on undefined variable usage' do
      code = '
        pokazl undeclared_var
      '
      expect { execute_code(code) }.to raise_error(RuntimeError, /Undeclared identifier/)
    end

    it 'raises error on invalid type operations' do
      code = '
        niech text = "hello"
        niech num = 5
        pokazl text - num
      '
      expect { execute_code(code) }.to raise_error(RuntimeError, /Unsupported operator/)
    end

    it 'raises error on constant reassignment' do
      code = '
        niech CONST = 5
        CONST = 10
      '
      expect { execute_code(code) }.to raise_error(RuntimeError, /cannot be mutated/)
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
      expect(execute_code(code)).to eq("3\n6\n")
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
      expect(execute_code(code)).to eq("10\n5\n")
    end

    it 'raises error on accessing out-of-scope variables' do
      code = '
        jesli prawda {
          niech x = 5
        }
        pokazl x
      '
      expect { execute_code(code) }.to raise_error(RuntimeError, /Undeclared identifier/)
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
      expect(execute_code(code)).to eq("7.5\n12.5\n0.5\n")
    end

    it 'maintains integer type when possible' do
      code = '
        niech x = 10
        niech y = 2
        pokazl x / y
      '
      expect(execute_code(code)).to eq("5\n")
    end

    it 'raises error on invalid type conversions' do
      code = '
        niech x = "5"
        niech y = 3
        pokazl x * y
      '
      expect { execute_code(code) }.to raise_error(RuntimeError, /Unsupported operator/)
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
      expect(execute_code(code)).to eq("14.333333333333334\n")
    end

    it 'handles complex string operations' do
      code = '
        niech name = "John"
        niech age = 25
        niech message = "Name: " + name + ", Age: " + age
        pokazl message
      '
      expect(execute_code(code)).to eq("Name: John, Age: 25\n")
    end

    it 'handles mixed boolean expressions' do
      code = '
        niech x = 5
        niech y = 10
        pokazl (x < y) i (x + 5 == y) i !(x == y)
      '
      expect(execute_code(code)).to eq("prawda\n")
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
      expect(execute_code(code)).to eq("5\n0\n5\n")
    end

    it 'handles very large numbers' do
      code = '
        niech x = 1000000
        niech y = 2000000
        pokazl x * y
      '
      expect(execute_code(code)).to eq("2000000000000\n")
    end

    it 'handles very small decimal numbers' do
      code = '
        niech x = 0.0000001
        niech y = 0.0000002
        pokazl x + y
      '
      expect(execute_code(code)).to eq("3.0e-7\n")
    end
  end

  describe 'Global Variables' do
    it 'defines and accesses global variable' do
      code = '
        globalna niech x = 42
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'accesses global from within function' do
      code = '
        globalna niech counter = 0
        funkcja increment() {
          counter = counter + 1
          pokazl counter
        }
        increment()
        increment()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n2")
    end

    it 'accesses global from nested blocks' do
      code = '
        globalna niech value = 10
        jesli prawda {
          pokazl value
          jesli prawda {
            value = value + 5
            pokazl value
          }
        }
        pokazl value
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("10\n15\n15")
    end

    it 'accesses global from loop' do
      code = '
        globalna niech sum = 0
        dla niech i = 0; 3; 1 {
          sum = sum + i
        }
        pokazl sum
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end

    it 'maintains global state across function calls' do
      code = '
        globalna niech state = []
        funkcja add_item(item) {
          state.dodaj(item)
        }
        add_item(1)
        add_item(2)
        add_item(3)
        pokazl state
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[1, 2, 3]')
    end

    it 'allows shadowing global in local scope' do
      code = '
        globalna niech x = 10
        funkcja test() {
          niech x = 20
          pokazl x
        }
        test()
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("20\n10")
    end
  end

  describe 'Constants' do
    it 'defines and accesses constant' do
      code = '
        niech PI = 3.14159
        pokazl PI
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3.14159')
    end

    it 'raises error when modifying constant' do
      code = '
        niech MAX_SIZE = 100
        MAX_SIZE = 200
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/cannot be mutated/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'raises error when modifying constant in function' do
      code = '
        niech CONFIG = {"port": 8080}
        funkcja update_config() {
          CONFIG = {"port": 9090}
        }
        update_config()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/cannot be mutated/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'allows accessing constant in nested scopes' do
      code = '
        niech MAX_ATTEMPTS = 3
        funkcja validate() {
          dla niech i = 0; MAX_ATTEMPTS; 1 {
            pokazl i
          }
        }
        validate()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n1\n2")
    end
  end

  describe 'Mixed Global and Constant scenarios' do
    it 'combines globals and constants' do
      code = '
        niech MAX_ITEMS = 3
        globalna niech items = []

        funkcja add_if_possible(item) {
          jesli items.dlg < MAX_ITEMS {
            items.dodaj(item)
            zwroc prawda
          }
          zwroc falsz
        }

        pokazl add_if_possible("a")
        pokazl add_if_possible("b")
        pokazl add_if_possible("c")
        pokazl add_if_possible("d")
        pokazl items
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda\nfalsz\n[\"a\", \"b\", \"c\"]")
    end

    it 'handles multiple globals and constants' do
      code = '
        niech MIN_VALUE = 0
        niech MAX_VALUE = 100
        globalna niech current = 50
        globalna niech history = []

        funkcja update_value(delta) {
          niech new_value = current + delta
          jesli new_value >= MIN_VALUE i new_value <= MAX_VALUE {
            current = new_value
            history.dodaj(new_value)
            zwroc prawda
          }
          zwroc falsz
        }

        pokazl update_value(-30)
        pokazl update_value(60)
        pokazl update_value(30)
        pokazl history
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nfalsz\n[20, 80]")
    end
  end

  describe 'Error cases' do
    it 'raises error when redefining global' do
      code = '
        globalna niech x = 10
        globalna niech x = 20
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/already declared/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'raises error when redefining constant' do
      code = '
        niech MAX = 100
        niech MAX = 200
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/already declared/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'raises error when modifying constant in complex ways' do
      code = '
        niech ARRAY = [1, 2, 3]
        ARRAY = [4, 5, 6]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/cannot be mutated/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'validates global variable declaration syntax' do
      code = '
        globalna x = 10
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Invalid syntax/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end

  describe 'Complex scoping scenarios' do
    it 'handles globals in nested functions' do
      code = '
        globalna niech count = 0

        funkcja outer() {
          funkcja inner() {
            count = count + 1
          }
          inner()
          pokazl count
        }

        outer()
        outer()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n2")
    end

    it 'maintains constant immutability in complex scenarios' do
      code = '
        niech CONFIG = {
          "host": "localhost",
          "ports": [8080, 8081]
        }

        funkcja update_ports() {
          CONFIG["ports"] = [9090, 9091]
        }

        update_ports()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/cannot be mutated/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'handles multiple global updates in different scopes' do
      code = '
        globalna niech counter = 0
        globalna niech values = []

        funkcja process() {
          counter = counter + 1
          values.dodaj(counter)
        }

        dla niech i = 0; 3; 1 {
          process()
        }

        pokazl counter
        pokazl values
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("3\n[1, 2, 3]")
    end
  end
end
