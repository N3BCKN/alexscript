require 'aruba/rspec'

RSpec.describe 'Bitwise Operators', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'bitwise AND (&)' do
    it 'computes basic AND' do
      code = 'pokazl 12 & 10'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8')
    end

    it 'works with variables' do
      code = 'niech a = 15
      niech b = 9
      pokazl a & b'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('9')
    end

    it 'yields zero for disjoint bits' do
      code = 'pokazl 4 & 2'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('0')
    end
  end

  describe 'bitwise OR (|)' do
    it 'computes basic OR' do
      code = 'pokazl 12 | 10'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('14')
    end

    it 'yields left operand when right is zero' do
      code = 'pokazl 42 | 0'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end
  end

  describe 'bitwise XOR (^)' do
    it 'computes basic XOR' do
      code = 'pokazl 12 ^ 10'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('6')
    end

    it 'yields zero when operands are equal' do
      code = 'pokazl 7 ^ 7'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('0')
    end

    it 'is its own inverse' do
      code = 'niech x = 42
      niech k = 13
      pokazl x ^ k ^ k'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end
  end

  describe 'bitwise NOT (~)' do
    it 'complements positive number' do
      code = 'pokazl ~5'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('-6')
    end

    it 'complements zero' do
      code = 'pokazl ~0'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('-1')
    end

    it 'double complement is identity' do
      code = 'pokazl ~~42'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'binds tighter than binary operators' do
      # ~1 & 3  =>  (-2) & 3  =>  2
      code = 'pokazl ~1 & 3'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2')
    end
  end

  describe 'left shift (<<)' do
    it 'shifts integer left' do
      code = 'pokazl 1 << 4'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('16')
    end

    it 'preserves array append semantics' do
      code = 'niech t = [1, 2]
      t << 3
      pokazl t'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[1, 2, 3]')
    end

    it 'supports arbitrary precision' do
      # 1 << 100 = 1267650600228229401496703205376
      code = 'pokazl 1 << 100'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('1267650600228229401496703205376')
    end

    it 'raises on negative shift' do
      code = 'pokazl 4 << -1'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include('Przesuniecie bitowe o wartosc ujemna')
    end
  end

  describe 'right shift (>>)' do
    it 'shifts integer right' do
      code = 'pokazl 16 >> 2'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4')
    end

    it 'rounds toward negative infinity for negatives' do
      # Ruby: -8 >> 1 == -4
      code = 'pokazl -8 >> 1'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('-4')
    end

    it 'raises on negative shift' do
      code = 'pokazl 4 >> -1'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include('Przesuniecie bitowe o wartosc ujemna')
    end
  end

  describe 'operator precedence' do
    it '& binds tighter than |' do
      # 1 | 2 & 2  =>  1 | (2 & 2)  =>  1 | 2  =>  3
      code = 'pokazl 1 | 2 & 2'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end

    it '^ binds between & and |' do
      # 1 | 2 ^ 3 & 3  =>  1 | (2 ^ (3 & 3))  =>  1 | (2 ^ 3)  =>  1 | 1  =>  1
      code = 'pokazl 1 | 2 ^ 3 & 3'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('1')
    end

    it 'shift binds tighter than bitwise AND' do
      # 1 << 3 & 15  =>  (1 << 3) & 15  =>  8 & 15  =>  8
      code = 'pokazl 1 << 3 & 15'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('8')
    end

    it 'addition binds tighter than shift' do
      # 1 + 2 << 3  =>  (1 + 2) << 3  =>  3 << 3  =>  24
      code = 'pokazl 1 + 2 << 3'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('24')
    end

    it 'bitwise operators bind tighter than comparison' do
      # 1 & 1 == 1  =>  (1 & 1) == 1  =>  prawda
      # note: this mirrors Ruby/Python/C famous precedence behavior
      code = 'pokazl 1 & 1 == 1'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end
  end

  describe 'type errors' do
    it 'raises on float with &' do
      code = 'pokazl 3.5 & 1'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include('Niewspierany operator')
    end

    it 'raises on string with |' do
      code = 'pokazl "a" | 1'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include('Niewspierany operator')
    end

    it 'raises on float with ~' do
      code = 'pokazl ~3.5'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.output).to include('Niewspierany operator')
    end
  end

  describe 'exponent operator migration (**)' do
    it 'computes integer power' do
      code = 'pokazl 2 ** 10'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('1024')
    end

    it 'is right-associative' do
      # 2 ** 3 ** 2  =>  2 ** (3 ** 2)  =>  2 ** 9  =>  512
      code = 'pokazl 2 ** 3 ** 2'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('512')
    end

    it 'supports fractional exponent via float' do
      code = 'pokazl 9 ** 0.5'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3.0')
    end

    it 'binds tighter than multiplication' do
      # 2 * 3 ** 2  =>  2 * 9  =>  18
      code = 'pokazl 2 * 3 ** 2'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('18')
    end
  end
end