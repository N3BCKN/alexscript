require 'aruba/rspec'

RSpec.describe 'Array Operations', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Array declaration and initialization' do
    it 'creates empty array correctly' do
      code = '
        niech arr = []
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[]')
    end

    it 'creates array with integers' do
      code = '
        niech arr = [1, 2, 3, 4, 5]
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 2, 3, 4, 5]')
    end

    it 'creates array with mixed types' do
      code = '
        niech arr = [1, "text", 3.14, prawda, nic]
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, text, 3.14, prawda, nic]')
    end

    it 'creates nested arrays' do
      code = '
        niech arr = [1, [2, 3], [4, [5, 6]]]
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, [2, 3], [4, [5, 6]]]')
    end
  end

  describe 'Array access and modification' do
    it 'accesses elements by index' do
      code = '
        niech arr = [10, 20, 30, 40]
        pokazl arr[0]
        pokazl arr[2]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("10\n30")
    end

    it 'allows negative indexing' do
      code = '
        niech arr = [1, 2, 3, 4]
        pokazl arr[-1]
        pokazl arr[-2]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("4\n3")
    end

    it 'modifies elements by index' do
      code = '
        niech arr = [1, 2, 3]
        arr[1] = 20
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 20, 3]')
    end

    it 'raises error on out of bounds access' do
      code = '
        niech arr = [1, 2, 3]
        pokazl arr[5]
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Indeks poza zakresem/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end

  describe 'Built-in array methods' do
    it 'performs methods on array not assigned to variables' do
      code = 'pokazl [1,2,3].typ()
      pokazl [1,2,3].suma()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("tablica\n6")
    end

    it 'returns array length' do
      code = '
        niech arr = [1, 2, 3, 4, 5]
        pokazl arr.dlg
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end

    it 'adds element to end of array' do
      code = '
        niech arr = [1, 2, 3]
        arr.dodaj(4)
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 2, 3, 4]')
    end

    it 'adds element using << operator' do
      code = '
        niech arr = [1, 2]
        arr << 3
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 2, 3]')
    end

    it 'removes element at index' do
      code = '
        niech arr = [1, 2, 3, 4]
        arr.usun(1)
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 3, 4]')
    end

    it 'returns an error when index you want to remove is nonexistent' do
      code = '
        niech arr = [1, 2, 3, 4]
        arr.usun(999)
        pokazl arr
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Indeks poza zakresem/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'inserts element at index' do
      code = '
        niech arr = [1, 2, 4]
        arr.wstaw(2, 3)
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 2, 3, 4]')
    end

    it 'returns an error when index you want to insert value after is nonexistent' do
      code = '
        niech arr = [1, 2, 3, 4]
        arr.wstaw(999, 3)
        pokazl arr
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Indeks poza zakresem/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    it 'returns first element of the array' do
      code = '
        niech arr = [1, 2, 3]
        pokazl arr.pierwszy()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('1')
    end

    it 'returns nil/nic when you try to get first element of an empty array' do
      code = '
        niech arr = []
        pokazl arr.pierwszy()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end

    it 'returns last element of the array' do
      code = '
        niech arr = [1, 2, 3]
        pokazl arr.ostatni()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end

    it 'returns nil/nic when you try to get last element of an empty array' do
      code = '
        niech arr = []
        pokazl arr.pierwszy()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end

    it 'returns proper index of the array with given value' do
      code = '
      niech arr = [1, 2, 3, 4]
      pokazl arr.indeks(4)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end

    it 'returns first index of the array with given value, when there are duplicates' do
      code = '
      niech arr = [1, 2, 3, 4, 4, 4, 4]
      pokazl arr.indeks(4)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end

    it 'returns nic/nic when you try to get index of the nonexistent value from the array' do
      code = '
      niech arr = [1, 2, 3, 4, 4, 4, 4]
      pokazl arr.indeks(999)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end

    # it 'swaps elements' do
    #   code = '
    #     niech arr = [1, 2, 3, 4]
    #     arr.zamien(0, 3)
    #     pokazl arr
    #   '
    #   run_command_and_stop "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[4, 2, 3, 1]')
    # end

    it 'clears array' do
      code = '
        niech arr = [1, 2, 3]
        arr.wyczysc()
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[]')
    end

    it 'reverses array' do
      code = '
        niech arr = [1, 2, 3, 4]
        pokazl arr.odwroc()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[4, 3, 2, 1]')
    end

    it 'checks if array is empty' do
      code = '
        niech arr = [1, 2, 3, 4]
        niech arr1 = []
        pokazl arr.pusta()
        pokazl arr1.pusta()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("falsz\nprawda")
    end

    it 'creates array copy' do
      code = '
        niech arr1 = [1, 2, 3]
        niech arr2 = arr1.kopiuj()
        arr1[0] = 10
        pokazl arr1
        pokazl arr2
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("[10, 2, 3]\n[1, 2, 3]")
    end

    it 'checks if element exists' do
      code = '
        niech arr = [1, 2, 3]
        pokazl arr.zawiera(2)
        pokazl arr.zawiera(5)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz")
    end

    # it 'counts element occurrences' do
    #   code = '
    #     niech arr = [1, 2, 2, 3, 2, 4]
    #     pokazl arr.licz(2)
    #   '
    #   run_command_and_stop "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started.output.strip).to eq('3')
    # end
  end

  describe 'Numeric array operations' do
    it 'calculates sum of elements' do
      code = '
        niech arr = [1, 2, 3, 4, 5]
        pokazl arr.suma()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('15')
    end

    it 'sum of elements equals 0 with empty array' do
      code = '
        niech arr = []
        pokazl arr.suma()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('0')
    end

    it 'calculates average of elements' do
      code = '
        niech arr = [2, 4, 6, 8]
        pokazl arr.srednia()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5.0')
    end

    it 'average of elements equals 0 with empty array' do
      code = '
        niech arr = []
        pokazl arr.srednia()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('0')
    end

    it 'finds minimum value' do
      code = '
        niech arr = [3, 1, 4, 1, 5]
        pokazl arr.min()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('1')
    end

    it 'minimum value is nil with empty array' do
      code = '
        niech arr = []
        pokazl arr.min()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end

    it 'finds maximum value' do
      code = '
        niech arr = [3, 1, 4, 1, 5]
        pokazl arr.max()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end

    it 'maximum value is nil with empty array' do
      code = '
        niech arr = []
        pokazl arr.max()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end

    it 'raises error on numeric operations with non-numeric arrays' do
      code = '
        niech arr = [1, "text", 3]
        pokazl arr.suma()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Tablica moze zawierac wylacznie liczby/)
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end

  describe 'Error handling and edge cases' do
    it 'raises error on non-integer index' do
      code = '
        niech arr = [1, 2, 3]
        pokazl arr[2.5]
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Indeks tablicy musi byc liczbą całkowitą/)
      expect(last_command_started.exit_status).not_to eq(0)
    end

    # it 'raises error when swapping invalid indices' do
    #   code = '
    #     niech arr = [1, 2, 3]
    #     arr.zamien(0, 10)
    #   '
    #   run_command_and_stop "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started).to have_output(/Invalid array indices/)
    #   expect(last_command_started.exit_status).not_to eq(0)
    # end

    # it 'handles empty array operations correctly' do
    #   code = '
    #     niech arr = []
    #     pokazl arr.suma()
    #     pokazl arr.srednia()
    #   '
    #   run_command_and_stop "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started.output.strip).to eq("0\n0")
    # end

    it 'preserves nested array structure after modifications' do
      code = '
        niech arr = [1, [2, 3], [4, [5, 6]]]
        arr[1][0] = 20
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, [20, 3], [4, [5, 6]]]')
    end
  end

  describe 'Array in control structures' do
    it 'works correctly in loops' do
      code = '
        niech arr = [1, 2, 3]
        dla niech indeks = 0; arr.dlg; 1 {
          arr[indeks] = arr[indeks] * 2
        }
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[2, 4, 6]')
    end

    # it 'works in conditional statements' do
    #   code = '
    #     niech arr = [1, 2, 3]
    #     jesli arr.dlg > 2 {
    #       arr.dodaj(4)
    #     }
    #     pokazl arr
    #   '
    #   run_command_and_stop "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 2, 3, 4]')
    # end
  end
end
