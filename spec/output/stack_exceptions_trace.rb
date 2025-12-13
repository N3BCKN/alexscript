require 'aruba/rspec'

RSpec.describe 'Exception Stack Trace', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Stack trace in exceptions' do
    it 'shows function call stack' do
      code = '
        funkcja c() {
          rzuc BladWykonania.nowy("Error in c")
        }
        funkcja b() {
          c()
        }
        funkcja a() {
          b()
        }
        
        proba {
          a()
        } zlap (e) {
          pokazl e["stos"].dlg
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end

    it 'shows method call stack' do
      code = '
        klasa BazaDanych {
          funkcja konstruktor() {}
          funkcja zapytanie() {
            rzuc BladWykonania.nowy("DB error")
          }
        }
        
        proba {
          niech db = BazaDanych.nowy()
          db.zapytanie()
        } zlap (e) {
          pokazl e["stos"][0]
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to match(/BazaDanych#zapytanie/)
    end

    it 'shows constructor in stack' do
      code = '
        klasa Test {
          funkcja konstruktor() {
            rzuc BladTypu.nowy("Constructor error")
          }
        }
        
        proba {
          niech t = Test.nowy()
        } zlap (e) {
          pokazl e["stos"][0]
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to match(/Test\.nowy/)
    end

    it 'shows nested function and method calls' do
      code = '
        klasa Serwis {
          funkcja konstruktor() {}
          funkcja proces() {
            helper()
          }
        }
        
        funkcja helper() {
          rzuc BladWykonania.nowy("Helper error")
        }
        
        proba {
          niech s = Serwis.nowy()
          s.proces()
        } zlap (e) {
          pokazl e["stos"].dlg
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2')
    end

    it 'shows static method in stack' do
      code = '
        klasa Matematyka {
          statyczny funkcja dziel(a, b) {
            jesli b == 0 to rzuc BladDzieleniaPrzezZero.nowy("Nie dziel przez zero")
            zwroc a / b
          }
        }
        
        proba {
          Matematyka.dziel(10, 0)
        } zlap (e) {
          pokazl e["stos"][0]
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to match(/Matematyka#dziel/)
    end

    it 'preserves stack through multiple catch blocks' do
      code = '
        funkcja outer() {
          inner()
        }
        
        funkcja inner() {
          rzuc BladTypu.nowy("Type error")
        }
        
        proba {
          outer()
        } zlap (e : BladWykonania) {
          pokazl "nie złapany"
        } zlap (e : BladTypu) {
          pokazl e["stos"].dlg
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2')
    end
  end
end