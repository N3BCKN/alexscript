# frozen_string_literal: true

require 'aruba/rspec'

RSpec.describe 'Modules', type: :aruba do
  # let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', __dir__) }
   let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'Basic module definition' do
    it 'defines empty module' do
      code = <<~CODE
        modul TestModul {}
        pokazl "OK"
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/"OK"/)
    end

    it 'defines module with constant' do
      code = <<~CODE
        modul Matematyka {
          niech PI = 3.14159
        }
        pokazl Matematyka::PI
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/3.14159/)
    end

    it 'defines module with multiple constants' do
      code = <<~CODE
        modul Stale {
          niech X = 10
          niech Y = 20
          niech Z = 30
        }
        pokazl Stale::X
        pokazl Stale::Y
        pokazl Stale::Z
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/10/)
      expect(last_command_started).to have_output(/20/)
      expect(last_command_started).to have_output(/30/)
    end

    it 'rejects non-constant variables in module' do
      code = <<~CODE
        modul Test {
          niech lowercase = 5
        }
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to_not be_successfully_executed
      expect(last_command_started).to have_output(/Tylko stałe .* mogą być definiowane w module/)
    end
  end

  describe 'Module functions' do
    it 'defines and calls module function' do
      code = <<~CODE
        modul Matematyka {
          funkcja dodaj(a, b) {
            zwroc a + b
          }
        }
        pokazl Matematyka::dodaj(5, 3)
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/8/)
    end

    it 'calls multiple module functions' do
      code = <<~CODE
        modul Operacje {
          funkcja mnoz(a, b) {
            zwroc a * b
          }
          
          funkcja dziel(a, b) {
            zwroc a / b
          }
        }
        pokazl Operacje::mnoz(4, 5)
        pokazl Operacje::dziel(10, 2)
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/20/)
      expect(last_command_started).to have_output(/5/)
    end

    it 'validates function argument count' do
      code = <<~CODE
        modul Test {
          funkcja suma(a, b, c) {
            zwroc a + b + c
          }
        }
        pokazl Test::suma(1, 2)
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/oczekiwała minimum 3 argumentów/)
    end
  end

  describe 'Module classes' do
    it 'defines class in module and creates instance' do
      code = <<~CODE
        modul Ksztalty {
          klasa Prostokat {
            funkcja konstruktor(a, b) {
              niech @a = a
              niech @b = b
            }
            
            funkcja pole() {
              zwroc @a * @b
            }
          }
        }
        
        niech p = Ksztalty::Prostokat.nowy(4, 5)
        pokazl p.pole()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/20/)
    end

    it 'handles multiple classes in module' do
      code = <<~CODE
        modul Geometria {
          klasa Kwadrat {
            funkcja konstruktor(a) {
              niech @a = a
            }
            funkcja pole() {
              zwroc @a * @a
            }
          }
          
          klasa Kolo {
            funkcja konstruktor(r) {
              niech @r = r
            }
            funkcja pole() {
              zwroc 3.14 * @r * @r
            }
          }
        }
        
        niech kw = Geometria::Kwadrat.nowy(5)
        niech ko = Geometria::Kolo.nowy(3)
        pokazl kw.pole()
        pokazl ko.pole()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/25/)
      expect(last_command_started).to have_output(/28.25999/)
    end

    it 'supports class inheritance in module' do
      code = <<~CODE
        modul Zwierzeta {
          klasa Zwierze {
            funkcja konstruktor(nazwa) {
              niech @nazwa = nazwa
            }
            
            funkcja glos() {
              zwroc "..."
            }
          }
          
          klasa Pies < Zwierze {
            funkcja glos() {
              zwroc "Hau!"
            }
          }
        }
        
        niech pies = Zwierzeta::Pies.nowy("Burek")
        pokazl pies.glos()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/"Hau!"/)
    end
  end

  describe 'Nested modules' do
    it 'defines nested module' do
      code = <<~CODE
        modul A {
          niech X = 1
          
          modul B {
            niech Y = 2
          }
        }
        
        pokazl A::X
        pokazl A::B::Y
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/1/)
      expect(last_command_started).to have_output(/2/)
    end

    it 'defines deeply nested modules' do
      code = <<~CODE
        modul A {
          modul B {
            modul C {
              niech VALUE = 42
              
              funkcja get_value() {
                zwroc VALUE
              }
            }
          }
        }
        
        pokazl A::B::C::VALUE
        pokazl A::B::C::get_value()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/42/)
    end

    it 'creates class from nested module' do
      code = <<~CODE
        modul Zewnetrzny {
          modul Wewnetrzny {
            klasa Test {
              funkcja konstruktor() {
                niech @val = 100
              }
              
              funkcja get() {
                zwroc @val
              }
            }
          }
        }
        
        niech t = Zewnetrzny::Wewnetrzny::Test.nowy()
        pokazl t.get()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/100/)
    end

    it 'handles multiple nested modules at same level' do
      code = <<~CODE
        modul Root {
          modul A {
            niech VAL = 1
          }
          
          modul B {
            niech VAL = 2
          }
          
          modul C {
            niech VAL = 3
          }
        }
        
        pokazl Root::A::VAL
        pokazl Root::B::VAL
        pokazl Root::C::VAL
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/1/)
      expect(last_command_started).to have_output(/2/)
      expect(last_command_started).to have_output(/3/)
    end
  end

  describe 'Module mixins (dolacz)' do
    it 'includes module methods into class' do
      code = <<~CODE
        modul Porownywalne {
          funkcja rowne(inne) {
            zwroc @wartosc == inne
          }
        }
        
        klasa Liczba {
          dolacz Porownywalne
          
          funkcja konstruktor(k) {
            niech @wartosc = k
          }
        }
        
        niech x = Liczba.nowy(5)
        pokazl x.rowne(5)
        pokazl x.rowne(10)
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/prawda/)
      expect(last_command_started).to have_output(/falsz/)
    end

    it 'includes multiple modules' do
      code = <<~CODE
        modul A {
          funkcja metoda_a() {
            zwroc "A"
          }
        }
        
        modul B {
          funkcja metoda_b() {
            zwroc "B"
          }
        }
        
        klasa Test {
          dolacz A
          dolacz B
          
          funkcja konstruktor() {}
        }
        
        niech t = Test.nowy()
        pokazl t.metoda_a()
        pokazl t.metoda_b()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/"A"/)
      expect(last_command_started).to have_output(/"B"/)
    end

    it 'gives priority to class methods over module methods' do
      code = <<~CODE
        modul M {
          funkcja test() {
            zwroc "modul"
          }
        }
        
        klasa K {
          dolacz M
          
          funkcja konstruktor() {}
          
          funkcja test() {
            zwroc "klasa"
          }
        }
        
        niech k = K.nowy()
        pokazl k.test()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/"klasa"/)
    end

    it 'includes module constants into class' do
      code = <<~CODE
        modul Config {
          niech MAX_SIZE = 100
          niech MIN_SIZE = 10
        }
        
        klasa Buffer {
          dolacz Config
          
          funkcja konstruktor() {
            niech @size = MAX_SIZE
          }
          
          funkcja get_size() {
            zwroc @size
          }
          
          funkcja get_min() {
            zwroc MIN_SIZE
          }
        }
        
        niech b = Buffer.nowy()
        pokazl b.get_size()
        pokazl b.get_min()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/100/)
      expect(last_command_started).to have_output(/10/)
    end

    it 'module methods can access instance variables' do
      code = <<~CODE
        modul Incrementable {
          funkcja increment() {
            niech @count = @count + 1
          }
          
          funkcja get_count() {
            zwroc @count
          }
        }
        
        klasa Counter {
          dolacz Incrementable
          
          funkcja konstruktor() {
            niech @count = 0
          }
        }
        
        niech c = Counter.nowy()
        c.increment()
        c.increment()
        c.increment()
        pokazl c.get_count()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/3/)
    end
  end

  describe 'Combined features' do
    it 'combines modules, classes, functions and constants' do
      code = <<~CODE
        modul Matematyka {
          niech PI = 3.14159
          
          funkcja kwadrat(x) {
            zwroc x * x
          }
          
          klasa Kalkulator {
            funkcja konstruktor() {
              niech @wynik = 0
            }
            
            funkcja pole_kola(r) {
              zwroc PI * kwadrat(r)
            }
          }
        }
        
        niech k = Matematyka::Kalkulator.nowy()
        pokazl k.pole_kola(5)
        pokazl Matematyka::PI
        pokazl Matematyka::kwadrat(4)
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/78.53975/)
      expect(last_command_started).to have_output(/3.14159/)
      expect(last_command_started).to have_output(/16/)
    end

    it 'nested modules with mixins' do
      code = <<~CODE
        modul External {
          modul Helpers {
            funkcja helper_method() {
              zwroc "helped"
            }
          }
          
          klasa Worker {
            dolacz Helpers
            
            funkcja konstruktor() {}
            
            funkcja work() {
              zwroc helper_method()
            }
          }
        }
        
        niech k = External::Worker.nowy()
        pokazl k.work()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to be_successfully_executed
      expect(last_command_started).to have_output(/"helped"/)
    end
  end

  describe 'Error handling' do
    it 'raises error for undefined module' do
      code = <<~CODE
        pokazl NieistniejacyModul::STALA
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to_not be_successfully_executed
      expect(last_command_started).to have_output(/Nie znaleziono.*NieistniejacyModul/)
    end

    it 'raises error for undefined module function' do
      code = <<~CODE
        modul Test {
          niech X = 1
        }
        pokazl Test::nieistniejaca_funkcja()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Nie znaleziono/)
    end

    it 'raises error for undefined module class' do
      code = <<~CODE
        modul Test {
          niech X = 1
        }
        niech t = Test::NieistniejacaKlasa.nowy()
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Nie znaleziono/)
    end

    it 'raises error when including undefined module' do
      code = <<~CODE
        klasa Test {
          dolacz NieistniejacyModul
          
          funkcja konstruktor() {}
        }
      CODE

      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Nie znaleziono modułu/)
    end
  end
end