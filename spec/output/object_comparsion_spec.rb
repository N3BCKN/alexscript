require 'aruba/rspec'

RSpec.describe 'Object and Array Comparison', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Object comparison with ==' do
    it 'compares empty objects as equal' do
      code = '
        niech obj1 = {}
        niech obj2 = {}
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares objects with same content as equal' do
      code = '
        niech obj1 = {"a": 1, "b": 2}
        niech obj2 = {"a": 1, "b": 2}
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares objects with different content as not equal' do
      code = '
        niech obj1 = {"a": 1, "b": 2}
        niech obj2 = {"a": 1, "b": 3}
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
    end

    it 'compares objects with same keys in different order as equal' do
      code = '
        niech obj1 = {"x": 1, "y": 2, "z": 3}
        niech obj2 = {"z": 3, "x": 1, "y": 2}
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares objects with different number of keys as not equal' do
      code = '
        niech obj1 = {"a": 1}
        niech obj2 = {"a": 1, "b": 2}
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
    end

    it 'returns empty object for non-existent method' do
      code = '
        klasa Test {}
        niech info = Test.info_metody("nieistniejaca")
        pokazl info == {}
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'Array comparison with ==' do
    it 'compares empty arrays as equal' do
      code = '
        niech arr1 = []
        niech arr2 = []
        pokazl arr1 == arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares arrays with same content as equal' do
      code = '
        niech arr1 = [1, 2, 3]
        niech arr2 = [1, 2, 3]
        pokazl arr1 == arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares arrays with different content as not equal' do
      code = '
        niech arr1 = [1, 2, 3]
        niech arr2 = [1, 2, 4]
        pokazl arr1 == arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
    end

    it 'compares arrays with different lengths as not equal' do
      code = '
        niech arr1 = [1, 2, 3]
        niech arr2 = [1, 2, 3, 4]
        pokazl arr1 == arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
    end

    it 'compares arrays with mixed types' do
      code = '
        niech arr1 = [1, "text", prawda]
        niech arr2 = [1, "text", prawda]
        pokazl arr1 == arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'Nested structure comparison' do
    it 'compares nested objects' do
      code = '
        niech obj1 = {"a": {"b": 1, "c": 2}}
        niech obj2 = {"a": {"b": 1, "c": 2}}
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares nested arrays' do
      code = '
        niech arr1 = [[1, 2], [3, 4]]
        niech arr2 = [[1, 2], [3, 4]]
        pokazl arr1 == arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares arrays in objects' do
      code = '
        niech obj1 = {"data": [1, 2, 3]}
        niech obj2 = {"data": [1, 2, 3]}
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares objects in arrays' do
      code = '
        niech arr1 = [{"x": 1}, {"y": 2}]
        niech arr2 = [{"x": 1}, {"y": 2}]
        pokazl arr1 == arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares deeply nested structures' do
      code = '
        niech deep1 = {"a": {"b": {"c": [1, 2, 3]}}}
        niech deep2 = {"a": {"b": {"c": [1, 2, 3]}}}
        pokazl deep1 == deep2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'Object comparison with !=' do
    it 'returns prawda for different objects' do
      code = '
        niech obj1 = {"a": 1}
        niech obj2 = {"a": 2}
        pokazl obj1 != obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'returns falsz for equal objects' do
      code = '
        niech obj1 = {"a": 1}
        niech obj2 = {"a": 1}
        pokazl obj1 != obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
    end
  end

  describe 'Cross-type comparison' do
    it 'compares object and array as not equal' do
      code = '
        niech obj = {"a": 1}
        niech arr = [1]
        pokazl obj == arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
    end

    it 'compares empty object and empty array as not equal' do
      code = '
        pokazl {} == []
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
    end

    it 'compares object and number as not equal' do
      code = '
        niech obj = {"value": 42}
        pokazl obj == 42
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
    end
  end

  describe 'Numeric type compatibility in collections' do
    it 'compares int and float in objects as equal' do
      code = '
        niech obj1 = {"value": 5}
        niech obj2 = {"value": 5.0}
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares arrays with mixed int and float as equal' do
      code = '
        niech arr1 = [1, 2, 3]
        niech arr2 = [1.0, 2.0, 3.0]
        pokazl arr1 == arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'Class instance comparison' do
    it 'compares different instances as not equal' do
      code = '
        klasa Test {}
        niech obj1 = Test.nowy()
        niech obj2 = Test.nowy()
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('falsz')
    end

    it 'compares same instance reference as equal' do
      code = '
        klasa Test {}
        niech obj1 = Test.nowy()
        niech obj2 = obj1
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'Edge cases with null values' do
    it 'compares objects with null values' do
      code = '
        niech obj1 = {"value": nic}
        niech obj2 = {"value": nic}
        pokazl obj1 == obj2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares arrays with null values' do
      code = '
        niech arr1 = [1, nic, 3]
        niech arr2 = [1, nic, 3]
        pokazl arr1 == arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'Practical use cases' do
    it 'validates configuration objects' do
      code = '
        funkcja waliduj(config) {
          niech expected = {"host": "localhost", "port": 8080}
          zwroc config == expected
        }
        niech config = {"host": "localhost", "port": 8080}
        pokazl waliduj(config)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'detects duplicates in array of objects' do
      code = '
        funkcja ma_duplikaty(arr) {
          dla niech i = 0; arr.dlg - 1; 1 {
            dla niech j = i + 1; arr.dlg; 1 {
              jesli arr[i] == arr[j] {
                zwroc prawda
              }
            }
          }
          zwroc falsz
        }
        niech items = [{"id": 1}, {"id": 2}, {"id": 1}]
        pokazl ma_duplikaty(items)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end

    it 'compares state changes' do
      code = '
        funkcja czy_zmieniono(old, new) {
          zwroc old != new
        }
        niech old_state = {"logged_in": prawda}
        niech new_state = {"logged_in": falsz}
        pokazl czy_zmieniono(old_state, new_state)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end
end