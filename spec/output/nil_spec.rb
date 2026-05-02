require 'aruba/rspec'

RSpec.describe 'Null value (nic) operations', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Basic nil operations' do
    it 'initializes variable as nil' do
      code = '
        niech x = nic
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end

    it 'allows reassignment to and from nil' do
      code = '
        niech x = 5
        x = nic
        pokazl x
        x = 10
        pokazl x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("nic\n10")
    end

    it 'handles comparison with nil' do
      code = '
        niech x = nic
        niech y = nic
        niech z = 5
        pokazl x == y
        pokazl x == z
        pokazl x != z
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz\nprawda")
    end
  end

  describe 'Null in expressions' do
    it 'handles arithmetic with nil' do
      code = '
        niech x = nic
        niech y = 5
        pokazl x + y
        pokazl y + x
        pokazl x * y
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niewspierany operator \+ pomiedzy/)
      expect(last_command_started).to have_exit_status(1)
    end

    # it 'handles string concatenation with nil' do
    #   code = '
    #     niech text = "Value: "
    #     niech x = nic
    #     pokazl text + x
    #     pokazl x + text
    #   '
    #   run_command_and_stop "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Value: nic\nnic")
    # end

    it 'handles boolean operations with nil' do
      code = '
        niech x = nic
        pokazl x i prawda
        pokazl x lub prawda
        pokazl !x
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("nic\nprawda\nprawda")
    end
  end

  describe 'Null in control structures' do
    it 'handles nil in if conditions' do
      code = '
        niech x = nic
        jesli x {
          pokazl "should not print"
        } albo {
          pokazl "x is nil or false"
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('x is nil or false')
    end

    it 'handles nil in loops' do
      code = '
        niech arr = [1, nic, 3, nic, 5]
        dla niech indeks = 0; arr.dlg; 1 {
          jesli arr[indeks] == nic {
            nastepny
          }
          pokazl arr[indeks]
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("1\n3\n5")
    end
  end

  describe 'Null in functions' do
    it 'handles nil as function argument' do
      code = '
        funkcja test(x) {
          pokazl x == nic
        }
        test(nic)
        test(5)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("prawda\nfalsz")
    end

    it 'handles nil as function return value' do
      code = '
        funkcja get_value(x) {
          jesli x > 0 {
            zwroc x
          }
          zwroc nic
        }
        pokazl get_value(5)
        pokazl get_value(-1)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("5\nnic")
    end
  end

  describe 'Null in data structures' do
    it 'handles nil in arrays' do
      code = '
        niech arr = [1, nic, 3]
        pokazl arr
        pokazl arr[1]
        arr[1] = 2
        pokazl arr
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("[1, nic, 3]\nnic\n[1, 2, 3]")
    end

    it 'handles nil in objects' do
      code = '
        niech obj = {"a": 1, "b": nic, "c": 3}
        pokazl obj
        pokazl obj["b"]
        obj["b"] = 2
        pokazl obj
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/,
                                                    '')).to eq("{a: 1, b: nic, c: 3}\nnic\n{a: 1, b: 2, c: 3}")
    end
  end

  describe 'Error cases with nil' do
    it 'raises error when calling methods on nil' do
      code = '
        niech x = nic
        pokazl x.dlg
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Blad podczas wykonywania metody dlg/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'raises error when indexing nil' do
      code = '
        niech x = nic
        pokazl x[0]
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/nie jest ani tablica ani obiektem/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'raises error when using nil as array index' do
      code = '
        niech arr = [1, 2, 3]
        pokazl arr[nic]
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Indeks tablicy musi byc liczbą całkowitą/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  describe 'strict null handling in binary operators' do
    # Ruby/Python-style: nic + cokolwiek (poza == i !=) raises a clear error
    # instead of silently propagating null and masking bugs.

    it 'still allows == and != with nic' do
      code = '
        pokazl nic == nic
        pokazl nic == 5
        pokazl nic != "x"
        pokazl 5 != nic
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nfalsz\nprawda\nprawda")
    end

    it 'raises type error for string + nic' do
      code = '
        niech wynik = "Witaj, " + nic
        pokazl wynik
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niewspierany operator \+ pomiedzy/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'raises type error for arithmetic with nic' do
      code = '
        niech wynik = 5 + nic
        pokazl wynik
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Niewspierany operator \+ pomiedzy/)
      expect(last_command_started).to have_exit_status(1)
    end
  end
end
