require 'aruba/rspec'

RSpec.describe 'Object Operations', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/lodz.rb', File.dirname(__FILE__)) }

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
      expect(last_command_started).to have_output(/Undefined key/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'raises error when accessing with non-string key' do
      code = '
        niech obj = {"name": "John"}
        pokazl obj[123]
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Object key must be a string/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    # it 'raises error when accessing properties of non-object' do
    #   code = '
    #     niech x = 5
    #     pokazl x["prop"]
    #   '
    #   run_command "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started.output.strip.gsub(/[\\"]/,
    #                                                 '')).to have_output(/\[line: \d+\], Expression x\[prop\] is neither array nor object/)
    #   expect(last_command_started.exit_status).not_to eq(0)
    # end
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

    it 'works with for-in loop' do
      code = '
        niech obj = {"a": 1
      '
      # NOTE: This test is incomplete in the original file
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Found '1' at the end of parsing/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end

  describe 'build in methods' do
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

    # it 'clears an object' do
    #   code = 'niech obj = {"a": 1, "b": 2, "c":3, "d": 4}
    #   obj.wyczysc()
    #   pokazl obj'
    #   require('byebug')
    #   byebug
    #   run_command_and_stop "ruby #{main_file_path} ' # {code}'"
    #   expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('{}')
    # end

    # it 'turns object into an array' do
    #   code = 'niech obj = {"a": 1, "b": 2, "c":3, "d": 4}
    #   pokazl obj.na_tablice()'
    #   run_command_and_stop "ruby #{main_file_path} ' # {code}'"
    #   expect(last_command_started.output.strip.gsub(/[\\"]/,
    #                                                 '')).to eq('[["a", {:type=>:type_int, :value=>1}], ["b", {:type=>:type_int, :value=>2}], ["c", {:type=>:type_int, :value=>3}], ["d", {:type=>:type_int, :value=>4}]]')
    # end

    # it 'checks if object is empty' do
    #   code = 'niech obj1 = {"a": 1, "b": 2, "c":3, "d": 4}
    #   niech obj2 = {}
    #   pokazl obj1.pusty()
    #   pokazl obj2.pusty()'
    #   run_command_and_stop "ruby #{main_file_path} ' # {code}'"
    #   expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("falsz\nprawda")
    # end
  end
end
