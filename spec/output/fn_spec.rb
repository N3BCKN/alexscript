# frozen_string_literal: true

require 'aruba/rspec'

RSpec.describe 'Anonymous Functions (fn)', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  #  Basic fn definition and calling─

  describe 'basic fn' do
    it 'assigns fn to variable and calls it' do
      code = 'niech powitaj = fn() { pokazl "Witaj" }
      powitaj()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Witaj')
    end

    it 'fn with parameters' do
      code = 'niech dodaj = fn(a, b) { zwroc a + b }
      pokazl dodaj(3, 7)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end

    it 'empty fn returns nic' do
      code = 'niech pusty = fn() {}
      pokazl pusty()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('nic')
    end
  end

  #  Implicit return (single-expression body)─

  describe 'implicit return' do
    it 'returns value of single expression without zwroc' do
      code = 'niech f = fn(x) { x * 2 }
      pokazl f(5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end

    it 'implicit return with string' do
      code = 'niech f = fn() { "hello" }
      pokazl f()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('hello')
    end

    it 'implicit return with arithmetic expression' do
      code = 'niech f = fn(a, b) { a + b * 2 }
      pokazl f(1, 3)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('7')
    end

    it 'implicit return with boolean expression' do
      code = 'niech f = fn(x) { x > 10 }
      pokazl f(15)
      pokazl f(5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nfalsz")
    end

    it 'implicit return with array literal' do
      code = 'niech f = fn(x) { [x, x * 2, x * 3] }
      pokazl f(4)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[4, 8, 12]')
    end

    it 'implicit return with function call (FuncCallStmt)' do
      code = 'niech g = fn(x) { x + 1 }
      niech f = fn(x) { g(x) }
      pokazl f(4)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end

    it 'implicit return with nested function calls' do
      code = 'niech a = fn(x) { x * 2 }
      niech b = fn(x) { x + 1 }
      niech c = fn(x) { a(b(x)) }
      pokazl c(4)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end
  end

  #  Explicit return (zwroc)

  describe 'explicit return' do
    it 'returns value with zwroc in single-line' do
      code = 'niech f = fn(x) { zwroc x + 1 }
      pokazl f(9)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end

    it 'early return in multiline fn' do
      code = 'niech f = fn(x) {
        jesli x < 0 {
          zwroc "ujemna"
        }
        zwroc "dodatnia"
      }
      pokazl f(-5)
      pokazl f(5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("ujemna\ndodatnia")
    end
  end

  #  Multiline fn

  describe 'multiline fn' do
    it 'multiline fn with local variables' do
      code = 'niech oblicz = fn(x, y) {
        niech suma = x + y
        niech iloczyn = x * y
        zwroc suma + iloczyn
      }
      pokazl oblicz(3, 4)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('19')
    end

    it 'multiline fn with loop' do
      code = 'niech suma_do = fn(n) {
        niech wynik = 0
        dla niech idx = 1; n + 1; 1 {
          wynik = wynik + idx
        }
        zwroc wynik
      }
      pokazl suma_do(5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('15')
    end

    it 'multiline fn without zwroc returns nic' do
      code = 'niech f = fn(x) {
        niech y = x + 1
        niech z = y * 2
      }
      pokazl f(5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('nic')
    end
  end

  #  IIFE (Immediately Invoked Function Expression)─

  describe 'IIFE' do
    it 'immediately invokes fn without arguments' do
      code = 'pokazl fn() { "natychmiast" }()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('natychmiast')
    end

    it 'immediately invokes fn with arguments' do
      code = 'pokazl fn(x, y) { x + y }(10, 20)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('30')
    end

    it 'IIFE in arithmetic expression' do
      code = 'niech wynik = fn(x) { x * 2 }(5) + 10
      pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('20')
    end

    it 'chained IIFE: fn returning fn, both invoked' do
      code = 'pokazl fn() { zwroc fn(x) { x * 3 } }()(7)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('21')
    end
  end

  #  Closures

  describe 'closures' do
    it 'captures variable from outer scope' do
      code = 'niech mnoznik = 10
      niech f = fn(x) { x * mnoznik }
      pokazl f(5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('50')
    end

    it 'closure over mutable state (counter)' do
      code = 'funkcja licznik(start) {
        niech n = start
        zwroc fn() {
          n = n + 1
          zwroc n
        }
      }
      niech licz = licznik(0)
      pokazl licz()
      pokazl licz()
      pokazl licz()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n2\n3")
    end

    it 'separate closures have independent state' do
      code = 'funkcja tworzLicznik() {
        niech n = 0
        zwroc fn() {
          n = n + 1
          zwroc n
        }
      }
      niech a = tworzLicznik()
      niech b = tworzLicznik()
      pokazl a()
      pokazl a()
      pokazl b()
      pokazl a()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n2\n1\n3")
    end

    it 'closure captures nested scope variables' do
      code = 'funkcja zewnetrzna() {
        niech x = 100
        funkcja wewnetrzna() {
          niech y = 200
          zwroc fn() { x + y }
        }
        zwroc wewnetrzna()
      }
      niech f = zewnetrzna()
      pokazl f()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('300')
    end
  end

  #  fn as argument (to regular functions)─

  describe 'fn as argument' do
    it 'passes fn to regular function' do
      code = 'funkcja zastosuj(f, wartosc) {
        zwroc f(wartosc)
      }
      pokazl zastosuj(fn(x) { x * 3 }, 7)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('21')
    end

    it 'passes multiple fn arguments' do
      code = 'funkcja polacz(f, g, x) {
        zwroc f(g(x))
      }
      pokazl polacz(fn(x) { x + 1 }, fn(x) { x * 2 }, 5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('11')
    end

    it 'fn variable passed by name as argument' do
      code = 'niech podwoj = fn(x) { x * 2 }
      funkcja zastosuj(f, val) { zwroc f(val) }
      pokazl zastosuj(podwoj, 8)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('16')
    end
  end

  #  fn returning fn─

  describe 'fn returning fn' do
    it 'fn returns another fn' do
      code = 'niech mnoznik = fn(n) {
        zwroc fn(x) { x * n }
      }
      niech razy3 = mnoznik(3)
      niech razy5 = mnoznik(5)
      pokazl razy3(10)
      pokazl razy5(10)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("30\n50")
    end

    it 'fn returning fn with implicit return' do
      code = 'niech dodajN = fn(n) { fn(x) { x + n } }
      niech f = dodajN(100)
      pokazl f(42)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('142')
    end
  end

  #  Parameters: defaults and rest

  describe 'parameter features' do
    it 'fn with default parameters' do
      code = 'niech powitaj = fn(imie, pozdrowienie = "Czesc") {
        zwroc pozdrowienie + " " + imie
      }
      pokazl powitaj("Jan")
      pokazl powitaj("Jan", "Witaj")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Czesc Jan\nWitaj Jan")
    end

    it 'fn with rest parameters' do
      code = 'niech suma = fn(pierwszy, *reszta) {
        niech wynik = pierwszy
        dla el w reszta {
          wynik = wynik + el
        }
        zwroc wynik
      }
      pokazl suma(1, 2, 3, 4, 5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('15')
    end
  end

  #  fn in OOP context

  describe 'fn in classes' do
    it 'fn inside method accesses instance variables' do
      code = 'klasa Licznik {
        funkcja konstruktor(start) {
          niech @n = start
        }
        funkcja pobierz_inkrementer() {
          zwroc fn() {
            niech @n = @n + 1
            zwroc @n
          }
        }
      }
      niech l = Licznik.nowy(0)
      niech ink = l.pobierz_inkrementer()
      pokazl ink()
      pokazl ink()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n2")
    end
  end

  #  Recursion

  describe 'recursion' do
    it 'fn recurses through its variable name' do
      code = 'niech silnia = fn(n) {
        jesli n <= 1 {
          zwroc 1
        }
        zwroc n * silnia(n - 1)
      }
      pokazl silnia(5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('120')
    end
  end

  #  Scope

  describe 'scope' do
    it 'fn parameters shadow outer variables' do
      code = 'niech x = 100
      niech f = fn(x) { x + 1 }
      pokazl f(5)
      pokazl x'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("6\n100")
    end
  end

  #  Error handling

  # Error handling

  describe 'error handling' do
    it 'fn with too few arguments raises error' do
      code = 'niech f = fn(a, b) { a + b }
      f(1)'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/BladArgumentu: Funkcja f oczekiwala minimum 2 argumentów, otrzymała 1/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'fn with too many arguments raises error' do
      code = 'niech f = fn(a) { a }
      f(1, 2, 3)'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/BladArgumentu: Funkcja f oczekiwala maksymalnie 1 argumentów, otrzymała 3/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'calling non-function value via IIFE syntax raises error' do
      code = 'niech x = 5
      pokazl x()'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/BladNazwy: Niepoprawna wartosc funkcji dla x w linii 2/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  #  zwroc inside proba─

  describe 'fn with exception handling' do
    it 'zwroc inside proba propagates correctly' do
      code = 'niech f = fn(a, b) {
        proba {
          zwroc a + b
        } zlap (e) {
          zwroc -1
        }
      }
      pokazl f(2, 3)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end

    it 'fn catches actual errors inside proba' do
      code = 'niech bezpieczny_podziel = fn(a, b) {
        proba {
          jesli b == 0 {
            rzuc "dzielenie przez zero"
          }
          zwroc a / b
        } zlap (e) {
          zwroc -1
        }
      }
      pokazl bezpieczny_podziel(10, 2)
      pokazl bezpieczny_podziel(10, 0)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("5\n-1")
    end
  end

  #  Complex integration

  describe 'integration' do
    it 'compose pattern with multiple fn' do
      code = 'funkcja komponuj(f, g) {
        zwroc fn(x) { f(g(x)) }
      }
      niech dodaj1 = fn(x) { x + 1 }
      niech razy2 = fn(x) { x * 2 }
      niech dodaj1_potem_razy2 = komponuj(razy2, dodaj1)
      pokazl dodaj1_potem_razy2(4)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end
  end
end

# ════════════════════════════════════════════════════════════════════════
# Custom Higher-Order Functions
# ════════════════════════════════════════════════════════════════════════

RSpec.describe 'Custom Higher-Order Functions', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'passing fn to user functions' do
    it 'applies fn twice' do
      code = 'funkcja zastosuj_dwa_razy(wartosc, f) {
        zwroc f(f(wartosc))
      }
      pokazl zastosuj_dwa_razy(3, fn(x) { x * 2 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('12')
    end

    it 'applies fn n times' do
      code = 'funkcja zastosuj_n_razy(wartosc, f, n) {
        niech wynik = wartosc
        dla niech step = 0; n; 1 {
          wynik = f(wynik)
        }
        zwroc wynik
      }
      pokazl zastosuj_n_razy(2, fn(x) { x * 2 }, 4)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('32')
    end

    it 'passes named function (funkcja) as argument' do
      code = 'funkcja podwoj(x) {
        zwroc x * 2
      }
      funkcja zastosuj(f, val) {
        zwroc f(val)
      }
      pokazl zastosuj(podwoj, 7)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('14')
    end

    it 'returns fn from user function' do
      code = 'funkcja tworzMnoznik(n) {
        zwroc fn(x) { x * n }
      }
      niech razy3 = tworzMnoznik(3)
      niech razy7 = tworzMnoznik(7)
      pokazl razy3(10)
      pokazl razy7(10)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("30\n70")
    end

    it 'function composition: pipe' do
      code = 'funkcja pipe(fns, wartosc) {
        niech wynik = wartosc
        dla f w fns {
          wynik = f(wynik)
        }
        zwroc wynik
      }
      niech kroki = [fn(x) { x + 1 }, fn(x) { x * 3 }, fn(x) { x - 2 }]
      pokazl pipe(kroki, 4)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('13')
    end

    it 'conditional function application' do
      code = 'funkcja zastosuj_jesli(wartosc, f, warunek) {
        jesli warunek(wartosc) {
          zwroc f(wartosc)
        }
        zwroc wartosc
      }
      pokazl zastosuj_jesli(5, fn(x) { x * 10 }, fn(x) { x > 3 })
      pokazl zastosuj_jesli(2, fn(x) { x * 10 }, fn(x) { x > 3 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("50\n2")
    end

    it 'custom map implementation with user function' do
      code = 'funkcja moja_mapa(tablica, f) {
        niech wynik = []
        dla el w tablica {
          wynik << f(el)
        }
        zwroc wynik
      }
      pokazl moja_mapa([1, 2, 3], fn(x) { x ** 2 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[1, 4, 9]')
    end

    it 'custom reduce implementation with user function' do
      code = 'funkcja moja_redukcja(tablica, f, init) {
        niech acc = init
        dla el w tablica {
          acc = f(acc, el)
        }
        zwroc acc
      }
      pokazl moja_redukcja([1, 2, 3, 4], fn(a, b) { a + b }, 0)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end

    it 'decorator pattern: wraps fn with logging' do
      code = 'funkcja z_logowaniem(f) {
        zwroc fn(x) {
          pokazl "Wejscie: " + x
          niech wynik = f(x)
          pokazl "Wyjscie: " + wynik
          zwroc wynik
        }
      }
      niech podwoj = z_logowaniem(fn(x) { x * 2 })
      podwoj(5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("Wejscie: 5\nWyjscie: 10")
    end
  end
end

# ════════════════════════════════════════════════════════════════════════
# Higher-Order Array Methods
# ════════════════════════════════════════════════════════════════════════

RSpec.describe 'Higher-Order Array Methods', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'mapuj' do
    it 'maps fn over array of integers' do
      code = 'niech arr = [1, 2, 3, 4]
      niech wynik = arr.mapuj(fn(x) { x * 2 })
      pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[2, 4, 6, 8]')
    end

    it 'maps fn over strings' do
      code = 'niech arr = ["a", "b", "c"]
      niech wynik = arr.mapuj(fn(s) { s + "!" })
      pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[a!, b!, c!]')
    end

    it 'maps with index using two-param fn' do
      code = 'niech arr = [10, 20, 30]
      niech wynik = arr.mapuj(fn(el, idx) { el + idx })
      pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[10, 21, 32]')
    end

    it 'maps using pre-defined fn variable' do
      code = 'niech podwoj = fn(x) { x * 2 }
      niech arr = [5, 10, 15]
      pokazl arr.mapuj(podwoj)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[10, 20, 30]')
    end

    it 'maps empty array returns empty array' do
      code = 'niech arr = []
      pokazl arr.mapuj(fn(x) { x * 2 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[]')
    end

    it 'does not modify original array' do
      code = 'niech arr = [1, 2, 3]
      niech nowa = arr.mapuj(fn(x) { x * 10 })
      pokazl arr
      pokazl nowa'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("[1, 2, 3]\n[10, 20, 30]")
    end
  end

  describe 'filtruj' do
    it 'filters elements matching predicate' do
      code = 'niech arr = [1, 2, 3, 4, 5, 6]
      niech parzyste = arr.filtruj(fn(x) { x % 2 == 0 })
      pokazl parzyste'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[2, 4, 6]')
    end

    it 'filters strings by length' do
      code = 'niech slowa = ["kot", "a", "pies", "ze", "hipopotam"]
      niech dlugie = slowa.filtruj(fn(s) { s.dlg() > 2 })
      pokazl dlugie'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[kot, pies, hipopotam]')
    end

    it 'filter returns empty when nothing matches' do
      code = 'niech arr = [1, 2, 3]
      pokazl arr.filtruj(fn(x) { x > 100 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[]')
    end

    it 'does not modify original array' do
      code = 'niech arr = [1, 2, 3, 4, 5]
      niech male = arr.filtruj(fn(x) { x < 3 })
      pokazl arr
      pokazl male'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("[1, 2, 3, 4, 5]\n[1, 2]")
    end
  end

  describe 'redukuj' do
    it 'reduces array to sum' do
      code = 'niech arr = [1, 2, 3, 4, 5]
      niech suma = arr.redukuj(fn(acc, x) { acc + x }, 0)
      pokazl suma'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('15')
    end

    it 'reduces array to product' do
      code = 'niech arr = [1, 2, 3, 4]
      niech iloczyn = arr.redukuj(fn(acc, x) { acc * x }, 1)
      pokazl iloczyn'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('24')
    end

    it 'reduces to concatenated string' do
      code = 'niech arr = ["a", "b", "c"]
      niech wynik = arr.redukuj(fn(acc, s) { acc + s }, "")
      pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('abc')
    end

    it 'reduces empty array returns initial value' do
      code = 'niech arr = []
      pokazl arr.redukuj(fn(acc, x) { acc + x }, 99)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('99')
    end
  end

  describe 'kazdy' do
    it 'executes fn for each element (side effects)' do
      code = 'niech arr = [1, 2, 3]
      arr.kazdy(fn(x) { pokazl x * 10 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("10\n20\n30")
    end

    it 'kazdy with index' do
      code = '[10, 20, 30].kazdy(fn(el, idx) { pokazl idx + ": " + el })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("0: 10\n1: 20\n2: 30")
    end

    it 'kazdy on empty array does nothing' do
      code = 'niech arr = []
      arr.kazdy(fn(x) { pokazl x })
      pokazl "koniec"'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('koniec')
    end
  end

  describe 'znajdz' do
    it 'finds first matching element' do
      code = 'niech arr = [1, 2, 3, 4, 5]
      pokazl arr.znajdz(fn(x) { x > 3 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4')
    end

    it 'returns nic when nothing found' do
      code = 'niech arr = [1, 2, 3]
      pokazl arr.znajdz(fn(x) { x > 100 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('nic')
    end
  end

  describe 'dowolny and wszystkie' do
    it 'dowolny returns prawda when at least one matches' do
      code = 'pokazl [1, 2, 3, 4].dowolny(fn(x) { x > 3 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'dowolny returns falsz when none match' do
      code = 'pokazl [1, 2, 3].dowolny(fn(x) { x > 10 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
    end

    it 'wszystkie returns prawda when all match' do
      code = 'pokazl [2, 4, 6].wszystkie(fn(x) { x % 2 == 0 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'wszystkie returns falsz when one does not match' do
      code = 'pokazl [2, 4, 5, 6].wszystkie(fn(x) { x % 2 == 0 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
    end

    it 'dowolny on empty array returns falsz' do
      code = 'pokazl [].dowolny(fn(x) { x > 0 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
    end

    it 'wszystkie on empty array returns prawda' do
      code = 'pokazl [].wszystkie(fn(x) { x > 0 })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end
  end

  describe 'sortuj' do
    it 'sorts numbers naturally without comparator' do
      code = 'pokazl [3, 1, 4, 1, 5, 2].sortuj()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[1, 1, 2, 3, 4, 5]')
    end

    it 'sorts strings naturally without comparator' do
      code = 'pokazl ["banan", "arbuz", "cytryna"].sortuj()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('[arbuz, banan, cytryna]')
    end

    it 'sorts ascending with comparator fn' do
      code = 'pokazl [5, 2, 8, 1, 9].sortuj(fn(a, b) { a - b })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[1, 2, 5, 8, 9]')
    end

    it 'sorts descending with comparator fn' do
      code = 'pokazl [5, 2, 8, 1, 9].sortuj(fn(a, b) { b - a })'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[9, 8, 5, 2, 1]')
    end

    it 'sorts empty array' do
      code = 'pokazl [].sortuj()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[]')
    end

    it 'does not modify original array' do
      code = 'niech arr = [3, 1, 2]
      niech posortowana = arr.sortuj()
      pokazl arr
      pokazl posortowana'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("[3, 1, 2]\n[1, 2, 3]")
    end
  end

  describe 'method chaining' do
    it 'chains mapuj and filtruj' do
      code = 'niech arr = [1, 2, 3, 4, 5, 6]
      niech wynik = arr.mapuj(fn(x) { x * 2 }).filtruj(fn(x) { x > 6 })
      pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[8, 10, 12]')
    end

    it 'chains filtruj, mapuj, and redukuj' do
      code = 'niech arr = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      niech wynik = arr.filtruj(fn(x) { x % 2 == 0 }).mapuj(fn(x) { x * x }).redukuj(fn(acc, x) { acc + x }, 0)
      pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('220')
    end

    it 'chains sortuj with filtruj' do
      code = 'niech wynik = [5, 3, 8, 1, 9, 2].filtruj(fn(x) { x > 3 }).sortuj()
      pokazl wynik'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[5, 8, 9]')
    end
  end
end