require 'aruba/rspec'

RSpec.describe 'Object Operations', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Object declaration and initialization' do
    it 'creates empty object correctly' do
      code = '
        niech obj = {}
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{}')
    end

    it 'creates object with simple properties' do
      code = '
        niech obj = {"name": "John", "age": 30}
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{name: John, age: 30}')
    end

    it 'creates object with mixed value types' do
      code = '
        niech obj = {
          "name": "John",
          "age": 30,
          "height": 1.85,
          "isStudent": prawda,
          "address": nic
        }
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/,
                                                    '')).to eq('{name: John, age: 30, height: 1.85, isStudent: prawda, address: nic}')
    end

    it 'creates nested objects' do
      code = '
        niech obj = {
          "name": "John",
          "address": {
            "city": "New York",
            "zip": "10001"
          }
        }
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/,
                                                    '')).to eq('{name: John, address: {city: New York, zip: 10001}}')
    end
  end

  describe 'Property access and modification' do
    it 'accesses properties using bracket notation' do
      code = '
        niech obj = {"name": "John", "age": 30}
        pokazl obj["name"]
        pokazl obj["age"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("John\n30")
    end

    it 'modifies existing properties' do
      code = '
        niech obj = {"name": "John", "age": 30}
        obj["age"] = 31
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{name: John, age: 31}')
    end

    it 'adds new properties' do
      code = '
        niech obj = {"name": "John"}
        obj["age"] = 30
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{name: John, age: 30}')
    end

    it 'accesses nested properties' do
      code = '
        niech obj = {
          "user": {
            "name": {
              "first": "John",
              "last": "Doe"
            }
          }
        }
        pokazl obj["user"]["name"]["first"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('John')
    end
  end

  describe 'Error handling' do
    it 'raises error when accessing undefined property' do
      code = '
        niech obj = {"name": "John"}
        pokazl obj["age"]
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/nic/)
      expect(last_command_started.exit_status).to eq(0)
    end

    # Previously this raised "Klucz obiektu musi byc ciagiem znakow".
    # Integer keys are now valid, so a missing integer key simply returns nic.
    it 'returns nic for a missing integer key' do
      code = '
        niech obj = {"name": "John"}
        pokazl obj[123]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end
  end

  describe 'Objects with arrays' do
    it 'creates object with array values' do
      code = '
        niech obj = {
          "numbers": [1, 2, 3],
          "names": ["John", "Jane"]
        }
        pokazl obj["numbers"]
        pokazl obj["names"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("[1, 2, 3]\n[John, Jane]")
    end

    it 'modifies array properties' do
      code = '
        niech obj = {"numbers": [1, 2, 3]}
        obj["numbers"][1] = 20
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{numbers: [1, 20, 3]}')
    end
  end

  describe 'Objects in control structures' do
    it 'works in conditional statements' do
      code = '
        niech user = {"age": 20}
        jesli user["age"] >= 18 {
          pokazl "Adult"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Adult')
    end

    it 'reports a syntax error for an unterminated object literal' do
      code = '
        niech obj = {"a": 1
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Znaleziono '1' na koncu parsowania/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end

  describe 'Integer keys' do
    it 'creates object with integer keys' do
      code = '
        niech obj = {1: "a", 2: "b"}
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{1: a, 2: b}')
    end

    it 'accesses an integer key' do
      code = '
        niech obj = {1: "jeden", 2: "dwa"}
        pokazl obj[2]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('dwa')
    end

    it 'assigns to a new integer key' do
      code = '
        niech obj = {}
        obj[10] = "ten"
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{10: ten}')
    end

    it 'reassigns an existing integer key' do
      code = '
        niech obj = {1: "old"}
        obj[1] = "new"
        pokazl obj[1]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('new')
    end

    it 'checks membership and removal for integer keys' do
      code = '
        niech obj = {5: "p", 6: "q"}
        pokazl obj.ma_klucz(5)
        pokazl obj.ma_klucz(7)
        obj.usun(5)
        pokazl obj.dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz\n1")
    end

    it 'supports nested integer keys' do
      code = '
        niech obj = {1: {2: "deep"}}
        pokazl obj[1][2]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('deep')
    end

    it 'reports calkowita as the type of an integer key' do
      code = '
        niech obj = {7: "x"}
        pokazl obj.klucze()[0].typ()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('calkowita')
    end
  end

  describe 'Boolean keys' do
    it 'creates object with boolean keys' do
      code = '
        niech obj = {prawda: "T", falsz: "F"}
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{prawda: T, falsz: F}')
    end

    it 'accesses a boolean key' do
      code = '
        niech obj = {prawda: "tak", falsz: "nie"}
        pokazl obj[prawda]
        pokazl obj[falsz]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("tak\nnie")
    end

    it 'checks membership and removal for boolean keys' do
      code = '
        niech obj = {prawda: 1, falsz: 2}
        pokazl obj.ma_klucz(prawda)
        obj.usun(prawda)
        pokazl obj.dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\n1")
    end

    it 'reports logiczna as the type of a boolean key' do
      code = '
        niech obj = {prawda: "x"}
        pokazl obj.klucze()[0].typ()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('logiczna')
    end
  end

  describe 'Null (nic) keys' do
    it 'creates object with a null key' do
      code = '
        niech obj = {nic: "z"}
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{nic: z}')
    end

    it 'accesses a null key and checks membership' do
      code = '
        niech obj = {nic: "pusto"}
        pokazl obj[nic]
        pokazl obj.ma_klucz(nic)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("pusto\nprawda")
    end

    it 'assigns to a null key' do
      code = '
        niech obj = {}
        obj[nic] = 1
        pokazl obj.ma_klucz(nic)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'reports nic as the type of a null key' do
      code = '
        niech obj = {nic: "x"}
        pokazl obj.klucze()[0].typ()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end
  end

  describe 'Key type distinctness' do
    it 'treats integer 1 and string "1" as distinct keys' do
      code = '
        niech obj = {}
        obj[1] = "int"
        obj["1"] = "str"
        pokazl obj.dlg()
        pokazl obj[1]
        pokazl obj["1"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\nint\nstr")
    end

    it 'treats boolean prawda and string "prawda" as distinct keys' do
      code = '
        niech obj = {}
        obj[prawda] = "b"
        obj["prawda"] = "s"
        pokazl obj.dlg()
        pokazl obj[prawda]
        pokazl obj["prawda"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\nb\ns")
    end

    it 'treats null nic and string "nic" as distinct keys' do
      code = '
        niech obj = {}
        obj[nic] = "n"
        obj["nic"] = "s"
        pokazl obj.dlg()
        pokazl obj[nic]
        pokazl obj["nic"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2\nn\ns")
    end

    it 'displays and counts an object with mixed key types' do
      code = '
        niech obj = {}
        obj["s"] = 1
        obj[9] = 2
        obj[prawda] = 3
        obj[nic] = 4
        pokazl obj
        pokazl obj.dlg()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("{s: 1, 9: 2, prawda: 3, nic: 4}\n4")
    end
  end

  describe 'Dynamic (expression) keys' do
    it 'evaluates a variable used as a key' do
      code = '
        niech K = "dyn"
        niech obj = {K: 42}
        pokazl obj["dyn"]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('42')
    end

    it 'evaluates a constant used as a key' do
      code = '
        niech ID = 100
        niech obj = {ID: "sto"}
        pokazl obj[100]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('sto')
    end

    it 'evaluates an arithmetic expression used as a key' do
      code = '
        niech obj = {1 + 1: "dwa"}
        pokazl obj[2]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('dwa')
    end
  end

  describe 'Invalid key types' do
    it 'raises an error for a float literal key' do
      code = '
        niech obj = {3.14: "x"}
        pokazl obj
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Klucz obiektu nie moze byc liczba zmiennoprzecinkowa/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'raises an error when assigning with a float key' do
      code = '
        niech obj = {}
        obj[3.14] = 1
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Klucz obiektu nie moze byc liczba zmiennoprzecinkowa/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'raises an error for a reference-type (array) key' do
      code = '
        niech obj = {}
        obj[[1]] = 1
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Klucz obiektu musi byc napisem/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end

  describe 'build in methods' do
    it 'performs methods on array not assigned to variables' do
      code = 'pokazl {}.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('obiekt')
    end

    it 'returns a proper type from object' do
      code = 'niech obj = {"a": 1}
      pokazl obj.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('obiekt')
    end

    it 'returns a lenght of an object' do
      code = 'niech obj = {"a": 1, "b": 2, "c":3, "d": 4}
      pokazl obj.dlg()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4')
    end

    it 'returns keys of an object' do
      code = 'niech obj = {"a": 1, "b": 2, "c":3, "d": 4}
      pokazl obj.klucze()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[a, b, c, d]')
    end

    it 'returns values of an object' do
      code = 'niech obj = {"a": 1, "b": 2, "c":3, "d": 4}
      pokazl obj.wartosci()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 2, 3, 4]')
    end

    it 'checks if object has a key' do
      code = 'niech obj = {"a": 1, "b": 2, "c":3, "d": 4}
      pokazl obj.ma_klucz("a")
      pokazl obj.ma_klucz("e")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz")
    end

    it 'checks if object has a value' do
      code = 'niech obj = {"a": 1, "b": 2, "c":3, "d": 4}
      pokazl obj.ma_wartosc(999)
      pokazl obj.ma_wartosc(1)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("falsz\nprawda")
    end

    it 'clears an object' do
      code = 'niech obj = {"a": 1, "b": 2, "c":3, "d": 4}
      obj.wyczysc()
      pokazl obj'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{}')
    end

    it 'turns object into an array' do
      code = 'niech obj = {"a": 1, "b": 2}
      pokazl obj.na_tablice()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[[a, 1], [b, 2]]')
    end

    it 'checks if object is empty' do
      code = 'niech obj1 = {"a": 1, "b": 2, "c":3, "d": 4}
      niech obj2 = {}
      pokazl obj1.pusty()
      pokazl obj2.pusty()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("falsz\nprawda")
    end

    it 'returns keys and values for an object with mixed key types' do
      code = 'niech obj = {1: "a", "b": prawda, nic: 5}
      pokazl obj.klucze()
      pokazl obj.wartosci()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("[1, b, nic]\n[a, prawda, 5]")
    end
  end

  describe 'iteration over collection-returning methods' do
    # Regression tests for a bug where obj.klucze() returned a raw Ruby array
    # instead of an AS-typed array, causing "BladTypu: brak konwersji of Symbol
    # into Integer" on indexing.

    it 'allows indexing into klucze() result' do
      code = 'niech obj = {"a": 1, "b": 2, "c": 3}
      pokazl obj.klucze()[0]
      pokazl obj.klucze()[1]
      pokazl obj.klucze()[2]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("a\nb\nc")
    end

    it 'returns proper string type from klucze() elements' do
      code = 'niech obj = {"a": 1}
      niech k = obj.klucze()
      pokazl k[0].typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('napis')
    end

    it 'allows calling string methods on klucze() elements' do
      code = 'niech obj = {"HELLO": 1}
      pokazl obj.klucze()[0].malymi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('hello')
    end

    it 'allows iterating over klucze() in a while loop' do
      code = 'niech obj = {"x": 10, "y": 20}
      niech k = obj.klucze()
      niech idx = 0
      dopoki idx < k.dlg() {
        pokazl k[idx]
        idx = idx + 1
      }'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("x\ny")
    end

    it 'allows iterating over klucze() with dla...w loop' do
      code = 'niech obj = {"x": 10, "y": 20}
      dla k w obj.klucze() {
        pokazl k
      }'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("x\ny")
    end

    it 'allows indexing into wartosci() result' do
      code = 'niech obj = {"a": 1, "b": "tekst", "c": prawda}
      pokazl obj.wartosci()[0]
      pokazl obj.wartosci()[1]
      pokazl obj.wartosci()[2]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("1\ntekst\nprawda")
    end

    it 'allows indexing into na_tablice() result' do
      code = 'niech obj = {"a": 1, "b": 2}
      pokazl obj.na_tablice()[0]
      pokazl obj.na_tablice()[1]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("[a, 1]\n[b, 2]")
    end

    it 'iterates over integer keys with dla...w loop' do
      code = 'niech obj = {1: "a", 2: "b", 3: "c"}
      dla k w obj.klucze() {
        pokazl k
      }'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("1\n2\n3")
    end
  end
end