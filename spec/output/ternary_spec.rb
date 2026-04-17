require 'aruba/rspec'

RSpec.describe 'Ternary Operator', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Basic ternary evaluation' do
    it 'returns true branch when condition is truthy' do
      code = 'pokazl prawda ? "tak" : "nie"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('tak')
    end

    it 'returns false branch when condition is falsy' do
      code = 'pokazl falsz ? "tak" : "nie"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nie')
    end

    it 'evaluates comparison condition correctly — true case' do
      code = 'pokazl 10 > 5 ? "wiekszy" : "mniejszy"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('wiekszy')
    end

    it 'evaluates comparison condition correctly — false case' do
      code = 'pokazl 3 > 5 ? "wiekszy" : "mniejszy"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('mniejszy')
    end

    it 'evaluates equality condition' do
      code = 'niech x = 5 pokazl x == 5 ? "rowne" : "nierowne"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('rowne')
    end
  end

  describe 'Ternary assigned to variable' do
    it 'assigns true branch value to variable' do
      code = 'niech wiek = 20 niech status = wiek >= 18 ? "dorosly" : "nieletni" pokazl status'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('dorosly')
    end

    it 'assigns false branch value to variable' do
      code = 'niech wiek = 15 niech status = wiek >= 18 ? "dorosly" : "nieletni" pokazl status'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nieletni')
    end

    it 'assigns integer from ternary' do
      code = 'niech x = 10 niech wynik = x > 0 ? 1 : -1 pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('1')
    end

    it 'assigns float from ternary' do
      code = 'niech x = 0 niech wynik = x > 0 ? 1.5 : 2.5 pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('2.5')
    end

    it 'assigns boolean from ternary' do
      code = 'niech x = 5 niech wynik = x > 0 ? prawda : falsz pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('prawda')
    end
  end

  describe 'Precedence with other operators' do
    it 'condition uses full arithmetic expression' do
      code = 'pokazl 2 + 3 > 4 ? "tak" : "nie"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('tak')
    end

    it 'condition uses logical AND' do
      code = 'niech a = 5 niech b = 10 pokazl a > 0 i b > 0 ? "oba dodatnie" : "nie"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('oba dodatnie')
    end

    it 'condition uses logical OR' do
      code = 'niech x = -1 pokazl x > 0 lub x == -1 ? "tak" : "nie"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('tak')
    end

    it 'branch is an arithmetic expression' do
      code = 'niech x = 3 pokazl x > 0 ? x * 10 : x * -1'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('30')
    end
  end

  describe 'Nested ternary (right-associativity)' do
    it 'evaluates first branch of nested ternary' do
      code = 'niech pkt = 95 niech ocena = pkt >= 90 ? "A" : pkt >= 70 ? "B" : "C" pokazl ocena'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('A')
    end

    it 'evaluates middle branch of nested ternary' do
      code = 'niech pkt = 75 niech ocena = pkt >= 90 ? "A" : pkt >= 70 ? "B" : "C" pokazl ocena'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('B')
    end

    it 'evaluates last branch of nested ternary' do
      code = 'niech pkt = 40 niech ocena = pkt >= 90 ? "A" : pkt >= 70 ? "B" : "C" pokazl ocena'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('C')
    end

    it 'handles three levels of nesting' do
      code = 'niech x = 0 niech s = x > 0 ? "plus" : x < 0 ? "minus" : "zero" pokazl s'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('zero')
    end
  end

  describe 'Ternary inside function' do
    it 'can be used in function return' do
      code = '
        funkcja abs(n) {
          zwroc n >= 0 ? n : n * -1
        }
        pokazl abs(-7)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('7')
    end

    it 'can be used as function argument' do
      code = '
        funkcja podwoj(x) {
          zwroc x * 2
        }
        niech n = 4
        pokazl podwoj(n > 0 ? n : 0)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('8')
    end
  end

  describe 'Lazy evaluation' do
    it 'does not evaluate the false branch when condition is true' do
      code = '
        niech wywolano = falsz
        funkcja efekt() {
          wywolano = prawda
          zwroc "uboczny"
        }
        niech wynik = prawda ? "ok" : efekt()
        pokazl wynik
        pokazl wywolano
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      lines = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n")
      expect(lines[0]).to eq('ok')
      expect(lines[1]).to eq('falsz')
    end

    it 'does not evaluate the true branch when condition is false' do
      code = '
        niech wywolano = falsz
        funkcja efekt() {
          wywolano = prawda
          zwroc "uboczny"
        }
        niech wynik = falsz ? efekt() : "ok"
        pokazl wynik
        pokazl wywolano
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      lines = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n")
      expect(lines[0]).to eq('ok')
      expect(lines[1]).to eq('falsz')
    end
  end

  describe 'Ternary with string interpolation' do
    it 'works inside interpolated string' do
      code = 'niech x = -3 pokazl "Liczba jest #{x >= 0 ? "nieujemna" : "ujemna"}"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Liczba jest ujemna')
    end
  end

  describe 'Ternary with arrays and objects' do
    it 'returns element from array based on condition' do
      code = 'niech arr = [10, 20, 30] niech wynik = arr.dlg > 0 ? arr[0] : nic pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('10')
    end

    it 'returns nic when array is empty' do
      code = 'niech arr = [] niech wynik = arr.dlg > 0 ? arr[0] : nic pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nic')
    end
  end

  describe 'Ternary inside anonymous function (fn)' do
    it 'works inside fn body' do
      code = 'niech abs = fn(n) { n >= 0 ? n : n * -1 } pokazl abs(4)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('4')
    end

    it 'works as fn body for negative input' do
      code = 'niech abs = fn(n) { n >= 0 ? n : n * -1 } pokazl abs(-9)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('9')
    end
  end
end