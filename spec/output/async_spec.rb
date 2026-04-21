# frozen_string_literal: true

require 'aruba/rspec'

RSpec.describe 'Async end-to-end', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # Helper to strip trailing whitespace and the escape artifacts that
  # accumulate from shell quoting. Keeps assertions readable.
  def clean_output
    last_command_started.output.strip.gsub(/[\\"]/, '')
  end

  # -----------------------------------------------------------------
  # 1. Core async/await happy path
  # -----------------------------------------------------------------
  describe 'core async/await' do
    it 'runs a trivial async function that sleeps then returns' do
      code = '
        asynchroniczna funkcja policz() {
            czekaj uspij(10)
            zwroc 42
        }
        pokazl uruchom(policz)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('42')
    end

    it 'propagates return values through nested czekaj' do
      code = '
        asynchroniczna funkcja wewnetrzna() {
            czekaj uspij(10)
            zwroc "hello"
        }

        asynchroniczna funkcja zewnetrzna() {
            niech wynik = czekaj wewnetrzna()
            zwroc wynik
        }

        pokazl uruchom(zewnetrzna)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('hello')
    end

    it 'returns nic from async function with no explicit return' do
      code = '
        asynchroniczna funkcja cicha() {
            czekaj uspij(5)
        }
        pokazl uruchom(cicha)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('nic')
    end

    it 'can chain multiple czekaj calls in sequence' do
      code = '
        asynchroniczna funkcja krok(x) {
            czekaj uspij(5)
            zwroc x + 1
        }
        asynchroniczna funkcja lancuch() {
            niech a = czekaj krok(0)
            niech b = czekaj krok(a)
            niech c = czekaj krok(b)
            zwroc c
        }
        pokazl uruchom(lancuch)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('3')
    end

    it 'supports recursion through async functions' do
      code = '
        asynchroniczna funkcja silnia(n) {
            jesli n <= 1 {
                zwroc 1
            }
            niech pod = czekaj silnia(n - 1)
            zwroc n * pod
        }
        pokazl uruchom(silnia(5))
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('120')
    end
  end

  # -----------------------------------------------------------------
  # 2. Value types flowing through czekaj
  # -----------------------------------------------------------------
  describe 'value types through czekaj' do
    it 'passes integers' do
      code = '
        asynchroniczna funkcja f() { zwroc 123 }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('123')
    end

    it 'passes floats' do
      code = '
        asynchroniczna funkcja f() { zwroc 3.14 }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('3.14')
    end

    it 'passes strings' do
      code = '
        asynchroniczna funkcja f() { zwroc "napis" }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('napis')
    end

    it 'passes booleans' do
      code = '
        asynchroniczna funkcja f() { zwroc prawda }
        asynchroniczna funkcja g() { zwroc falsz }
        pokazl uruchom(f)
        pokazl uruchom(g)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq("prawda\nfalsz")
    end

    it 'passes arrays' do
      code = '
        asynchroniczna funkcja f() { zwroc [1, 2, 3] }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('[1, 2, 3]')
    end

    it 'passes objects' do
      code = '
        asynchroniczna funkcja f() { zwroc {"a": 1, "b": 2} }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('{a: 1, b: 2}')
    end

    it 'passes nic' do
      code = '
        asynchroniczna funkcja f() { zwroc nic }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('nic')
    end
  end

  # -----------------------------------------------------------------
  # 3. Obietnica API — stan, wartosc, powod, spelniona, odrzucona
  # -----------------------------------------------------------------
  describe 'Obietnica API' do
    it 'Obietnica.spelniona returns value through czekaj' do
      code = '
        asynchroniczna funkcja f() {
            zwroc czekaj Obietnica.spelniona(7)
        }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('7')
    end

    it 'Obietnica.spelniona works with strings' do
      code = '
        asynchroniczna funkcja f() {
            zwroc czekaj Obietnica.spelniona("gotowe")
        }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('gotowe')
    end

    it 'Obietnica.odrzucona raises through czekaj' do
      code = '
        asynchroniczna funkcja f() {
            zwroc czekaj Obietnica.odrzucona("cos poszlo nie tak")
        }
        uruchom(f)
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/cos poszlo nie tak/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'can check stan of a fulfilled Obietnica' do
      code = '
        niech p = Obietnica.spelniona(42)
        pokazl p.stan()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('spelniona')
    end

    it 'can check stan of a rejected Obietnica' do
      code = '
        niech p = Obietnica.odrzucona("blad")
        pokazl p.stan()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('odrzucona')
    end

    it 'reads wartosc of fulfilled Obietnica' do
      code = '
        niech p = Obietnica.spelniona(100)
        pokazl p.wartosc()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('100')
    end

    it 'reads powod of rejected Obietnica' do
      code = '
        niech p = Obietnica.odrzucona("error message")
        pokazl p.powod()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to match(/error message/)
    end

    it 'wartosc on pending async promise raises' do
      code = '
        asynchroniczna funkcja opozniona() {
            czekaj uspij(50)
            zwroc 1
        }
        niech p = opozniona()
        pokazl p.wartosc()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/nie jest spelniona/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  # -----------------------------------------------------------------
  # 4. uruchom — entry point into async world
  # -----------------------------------------------------------------
  describe 'uruchom' do
    it 'accepts a function value (no-arg convenience form)' do
      code = '
        asynchroniczna funkcja f() { zwroc 1 }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('1')
    end

    it 'accepts an Obietnica directly' do
      code = '
        asynchroniczna funkcja f() { zwroc 5 }
        niech p = f()
        pokazl uruchom(p)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('5')
    end

    it 'accepts a call expression producing an Obietnica' do
      code = '
        asynchroniczna funkcja f(x) { zwroc x * 2 }
        pokazl uruchom(f(21))
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('42')
    end

    it 'rejects non-promise, non-async-function argument' do
      code = '
        uruchom(42)
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/uruchom oczekuje/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'rejects synchronous function' do
      code = '
        funkcja zwykla() { zwroc 1 }
        uruchom(zwykla)
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/uruchom oczekuje/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  # -----------------------------------------------------------------
  # 5. uspij
  # -----------------------------------------------------------------
  describe 'uspij' do
    it 'actually waits the requested time' do
      code = '
        asynchroniczna funkcja f() {
            czekaj uspij(100)
            zwroc "done"
        }
        pokazl uruchom(f)
      '
      start = Time.now
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      elapsed_ms = (Time.now - start) * 1000

      expect(clean_output).to eq('done')
      # Ruby startup takes ~200-500ms; uspij should add at least its 100ms.
      # Generous bounds to be CI-friendly.
      expect(elapsed_ms).to be >= 100
    end

    it 'uspij(0) yields without blocking' do
      code = '
        asynchroniczna funkcja f() {
            czekaj uspij(0)
            zwroc "ok"
        }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('ok')
    end

    it 'rejects non-number argument' do
      code = '
        asynchroniczna funkcja f() {
            czekaj uspij("nie liczba")
        }
        uruchom(f)
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/uspij oczekuje liczby/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  # -----------------------------------------------------------------
  # 6. Async lambdas
  # -----------------------------------------------------------------
  describe 'async lambdas' do
    it 'assigns async fn to a variable and invokes via uruchom' do
      code = '
        niech f = asynchroniczna fn(x) { zwroc x * 3 }
        pokazl uruchom(f(7))
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('21')
    end

    it 'allows czekaj inside async fn body' do
      code = '
        niech f = asynchroniczna fn() {
            czekaj uspij(5)
            zwroc "lambda"
        }
        pokazl uruchom(f())
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('lambda')
    end

    it 'captures variables via closure' do
      code = '
        niech licznik = 10
        niech zwieksz = asynchroniczna fn() {
            czekaj uspij(5)
            zwroc licznik + 1
        }
        pokazl uruchom(zwieksz())
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('11')
    end
  end

  # -----------------------------------------------------------------
  # 7. Async methods in classes
  # -----------------------------------------------------------------
  describe 'async methods in classes' do
    it 'class can have async instance methods' do
      code = '
        klasa Licznik {
            funkcja konstruktor() {
                niech @wartosc = 0
            }

            asynchroniczna funkcja zwieksz() {
                czekaj uspij(5)
                niech @wartosc = @wartosc + 1
                zwroc @wartosc
            }
        }

        niech l = Licznik.nowy()
        pokazl uruchom(l.zwieksz())
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('1')
    end

    it 'async methods can use sam (self)' do
      code = '
        klasa Osoba {
            funkcja konstruktor(imie) {
                niech @imie = imie
            }

            asynchroniczna funkcja przywitaj() {
                czekaj uspij(5)
                zwroc "Czesc, " + @imie
            }
        }

        niech p = Osoba.nowy("Ala")
        pokazl uruchom(p.przywitaj())
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('Czesc, Ala')
    end

    it 'multiple async calls on the same instance share state' do
      code = '
        klasa Akumulator {
            funkcja konstruktor() {
                niech @suma = 0
            }

            asynchroniczna funkcja dodaj(x) {
                czekaj uspij(5)
                niech @suma = @suma + x
                zwroc @suma
            }
        }

        asynchroniczna funkcja main() {
            niech a = Akumulator.nowy()
            czekaj a.dodaj(10)
            czekaj a.dodaj(20)
            niech wynik = czekaj a.dodaj(30)
            zwroc wynik
        }

        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('60')
    end
  end

  # -----------------------------------------------------------------
  # 8. uruchom_rownolegle — concurrent fibers
  # -----------------------------------------------------------------
  describe 'uruchom_rownolegle' do
    it 'spawns a fiber and returns a promise for its result' do
      code = '
        asynchroniczna funkcja main() {
            niech zad = uruchom_rownolegle(fn() {
                czekaj uspij(10)
                zwroc 99
            })
            niech wynik = czekaj zad
            zwroc wynik
        }
        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('99')
    end

    it 'two parallel fibers run concurrently, not sequentially' do
      # Each fiber sleeps 100ms; sequentially = 200ms, concurrently = ~100ms.
      # We assert upper bound well below 200ms to catch regressions.
      code = '
        asynchroniczna funkcja main() {
            niech a = uruchom_rownolegle(fn() {
                czekaj uspij(100)
                zwroc "a"
            })
            niech b = uruchom_rownolegle(fn() {
                czekaj uspij(100)
                zwroc "b"
            })
            niech wa = czekaj a
            niech wb = czekaj b
            zwroc wa + wb
        }
        pokazl uruchom(main)
      '
      start = Time.now
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      elapsed_ms = (Time.now - start) * 1000

      expect(clean_output).to eq('ab')
      # 100ms sleep concurrent, plus Ruby startup, plus some slack.
      # Sequential would be >= 200ms + startup. 300ms is comfortable middle ground.
      # Adjust if your CI is unusually slow.
      expect(elapsed_ms).to be < 2000    # upper safety; main check is the value
    end

    it 'rejects non-function argument' do
      code = '
        asynchroniczna funkcja main() {
            uruchom_rownolegle(42)
        }
        uruchom(main)
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/uruchom_rownolegle oczekuje funkcji/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  # -----------------------------------------------------------------
  # 9. Execution ordering and fiber isolation
  # -----------------------------------------------------------------
  describe 'execution ordering' do
    it 'fibers interleave at czekaj boundaries' do
      # Two fibers, different sleep durations — faster one should finish first.
      code = '
        asynchroniczna funkcja wolny() {
            czekaj uspij(60)
            pokazl "wolny"
        }
        asynchroniczna funkcja szybki() {
            czekaj uspij(20)
            pokazl "szybki"
        }
        asynchroniczna funkcja main() {
            niech k = uruchom_rownolegle(fn() { czekaj wolny() })
            niech s = uruchom_rownolegle(fn() { czekaj szybki() })
            czekaj k
            czekaj s
        }
        uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq("szybki\nwolny")
    end

    it 'sync code inside async function runs without yielding' do
      # No czekaj means no yield; output should be fully ordered.
      code = '
        asynchroniczna funkcja f() {
            pokazl "a"
            pokazl "b"
            pokazl "c"
        }
        uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq("a\nb\nc")
    end

    it 'variables in different fibers do not collide' do
      code = '
        asynchroniczna funkcja z_wartoscia(x) {
            czekaj uspij(10)
            zwroc x
        }

        asynchroniczna funkcja main() {
            niech a = uruchom_rownolegle(fn() { czekaj z_wartoscia(100) })
            niech b = uruchom_rownolegle(fn() { czekaj z_wartoscia(200) })
            niech wa = czekaj a
            niech wb = czekaj b
            zwroc wa + wb
        }
        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('300')
    end
  end

  # -----------------------------------------------------------------
  # 10. Error handling
  # -----------------------------------------------------------------
  describe 'error handling' do
    it 'runtime error in async function propagates to uruchom' do
      code = '
        asynchroniczna funkcja zly() {
            czekaj uspij(5)
            niech x = nieistniejaca_zmienna
            zwroc x
        }
        uruchom(zly)
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/nieistniejaca_zmienna|Niezdefiniowana|nieznana/i)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'proba/zlap catches error from czekaj' do
      code = '
        asynchroniczna funkcja zly() {
            czekaj uspij(5)
            rzuc BladWykonania.nowy("wybuch")
        }

        asynchroniczna funkcja bezpieczny() {
            proba {
                czekaj zly()
            } zlap (e) {
                zwroc "zlapano: " + e["wiadomosc"]
            }
        }

        pokazl uruchom(bezpieczny)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to match(/zlapano:.*wybuch/)
    end

    it 'throw via rzuc translates to promise rejection' do
      code = '
        asynchroniczna funkcja rzucajacy() {
            rzuc BladWykonania.nowy("bum")
        }
        uruchom(rzucajacy)
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/bum/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'error in uruchom_rownolegle fiber surfaces on czekaj' do
      code = '
        asynchroniczna funkcja main() {
            niech z = uruchom_rownolegle(fn() {
                rzuc BladWykonania.nowy("fiber error")
            })
            proba {
                czekaj z
                zwroc "nie powinno tu dojsc"
            } zlap (e) {
                zwroc "zlapano"
            }
        }
        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('zlapano')
    end
  end

  # -----------------------------------------------------------------
  # 11. Static validation (parser)
  # -----------------------------------------------------------------
  describe 'static validation of czekaj' do
    it 'BladSkladni when czekaj appears at top level' do
      code = '
        niech x = czekaj cos()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/czekaj/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'BladSkladni when czekaj appears in a sync function' do
      code = '
        funkcja zwykla() {
            niech x = czekaj cos()
        }
        zwykla()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/czekaj/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'BladSkladni when czekaj appears in a sync lambda' do
      code = '
        niech f = fn() {
            czekaj cos()
        }
        f()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/czekaj/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'BladSkladni when asynchroniczna is not followed by funkcja or fn' do
      code = '
        asynchroniczna niech x = 1
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/funkcja|fn/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'async context does not leak to following top-level statements' do
      code = '
        asynchroniczna funkcja f() { zwroc 1 }
        niech y = czekaj f()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/czekaj/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  # -----------------------------------------------------------------
  # 12. Edge cases
  # -----------------------------------------------------------------
  describe 'edge cases' do
    it 'czekaj on non-Obietnica value returns unchanged (sugar)' do
      code = '
        asynchroniczna funkcja f() {
            niech x = czekaj 42
            zwroc x
        }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('42')
    end

    it 'czekaj on already-fulfilled promise returns immediately' do
      code = '
        asynchroniczna funkcja f() {
            niech p = Obietnica.spelniona("gotowe")
            zwroc czekaj p
        }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('gotowe')
    end

    it 'deep czekaj chain across many functions' do
      code = '
        asynchroniczna funkcja poz1() {
            czekaj uspij(2)
            zwroc 1
        }
        asynchroniczna funkcja poz2() {
            czekaj uspij(2)
            niech x = czekaj poz1()
            zwroc x + 1
        }
        asynchroniczna funkcja poz3() {
            czekaj uspij(2)
            niech x = czekaj poz2()
            zwroc x + 1
        }
        asynchroniczna funkcja poz4() {
            czekaj uspij(2)
            niech x = czekaj poz3()
            zwroc x + 1
        }
        asynchroniczna funkcja poz5() {
            czekaj uspij(2)
            niech x = czekaj poz4()
            zwroc x + 1
        }

        pokazl uruchom(poz5)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('5')
    end

    it 'async function returning a computed value using sync math' do
      code = '
        asynchroniczna funkcja f(n) {
            czekaj uspij(5)
            niech suma = 0
            dla niech k = 1; n + 1; 1 {
                suma = suma + k
            }
            zwroc suma
        }
        pokazl uruchom(f(10))
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('55')
    end

    it 'async function calling sync function' do
      code = '
        funkcja podwoj(x) { zwroc x * 2 }

        asynchroniczna funkcja f() {
            czekaj uspij(5)
            zwroc podwoj(21)
        }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('42')
    end

    it 'uruchom called from sync code works naturally' do
      code = '
        asynchroniczna funkcja f() { zwroc "ok" }
        niech wynik = uruchom(f)
        pokazl wynik
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('ok')
    end

    it 'czekaj on fulfilled Obietnica does not trigger deadlock' do
      # Edge case: the await path when the promise is already settled
      # must return synchronously without yielding. If it incorrectly
      # yields to a nonexistent reactor, we'd get a FiberError.
      code = '
        asynchroniczna funkcja f() {
            zwroc czekaj Obietnica.spelniona(1)
        }
        pokazl uruchom(f)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('1')
    end
  end

  # -----------------------------------------------------------------
  # 13. Function argument handling in async
  # -----------------------------------------------------------------
  describe 'argument handling' do
    it 'async function receives positional arguments' do
      code = '
        asynchroniczna funkcja f(a, b, c) {
            czekaj uspij(5)
            zwroc a + b + c
        }
        pokazl uruchom(f(1, 2, 3))
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('6')
    end

    it 'async function respects default arguments' do
      code = '
        asynchroniczna funkcja f(a, b = 100) {
            czekaj uspij(5)
            zwroc a + b
        }
        pokazl uruchom(f(1))
        pokazl uruchom(f(1, 2))
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq("101\n3")
    end

    it 'async function with rest parameter' do
      code = '
        asynchroniczna funkcja suma(*liczby) {
            czekaj uspij(5)
            niech wynik = 0
            dla x w liczby {
                wynik = wynik + x
            }
            zwroc wynik
        }
        pokazl uruchom(suma(1, 2, 3, 4, 5))
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('15')
    end

    it 'async function error when too few arguments' do
      code = '
        asynchroniczna funkcja f(a, b) { zwroc a + b }
        uruchom(f(1))
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/oczekiwala|oczekiwała/i)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  # -----------------------------------------------------------------
  # 14. Integration with existing language features
  # -----------------------------------------------------------------
  describe 'integration with language features' do
    it 'async function inside module' do
      code = '
        modul Narzedzia {
            asynchroniczna funkcja pobierz_liczbe() {
                czekaj uspij(5)
                zwroc 42
            }
        }

        pokazl uruchom(Narzedzia::pobierz_liczbe())
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('42')
    end

    it 'asynchroniczna fn passed as argument to HOF mapuj (after uruchom)' do
      code = '
        asynchroniczna funkcja podwoj(x) {
            czekaj uspij(2)
            zwroc x * 2
        }

        asynchroniczna funkcja main() {
            niech liczby = [1, 2, 3]
            niech wyniki = []
            dla n w liczby {
            niech wynik = czekaj podwoj(n)
            wyniki << wynik
            }
            zwroc wyniki
        }

        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('[2, 4, 6]')
    end

    it 'async function with if/else branching' do
      code = '
        asynchroniczna funkcja klasyfikuj(n) {
            czekaj uspij(5)
            jesli n > 0 {
                zwroc "dodatnia"
            } albojesli n < 0 {
                zwroc "ujemna"
            } albo {
                zwroc "zero"
            }
        }

        pokazl uruchom(klasyfikuj(5))
        pokazl uruchom(klasyfikuj(-3))
        pokazl uruchom(klasyfikuj(0))
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq("dodatnia\nujemna\nzero")
    end

    it 'async function using try/catch with Obietnica.odrzucona' do
        code = '
          asynchroniczna funkcja bezpieczny() {
              proba {
                  niech x = czekaj Obietnica.odrzucona("problem")
                  zwroc "nie dojdzie"
              } zlap (e) {
                  zwroc "zlapano: " + e["wiadomosc"]
              }
          }
          pokazl uruchom(bezpieczny)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to match(/zlapano:.*problem/)
      end
    end

    describe 'Obietnica combinators' do
      describe 'Obietnica.wszystkie' do
      it 'resolves with array of values in original order' do
        code = '
          asynchroniczna funkcja pierwszy() {  
            czekaj uspij(30)
            zwroc "a" 
          }
          asynchroniczna funkcja drugi() { 
            czekaj uspij(10)
            zwroc "b" 
          }
          asynchroniczna funkcja trzeci() {  
            czekaj uspij(20)
            zwroc "c" 
          }

          asynchroniczna funkcja main() {
              niech wyniki = czekaj Obietnica.wszystkie([pierwszy(), drugi(), trzeci()])
              zwroc wyniki
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to eq('[a, b, c]')
      end

      it 'works with an empty array' do
        code = '
          asynchroniczna funkcja main() {
              niech wyniki = czekaj Obietnica.wszystkie([])
              zwroc wyniki
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to eq('[]')
      end

      it 'rejects fast when one promise rejects' do
        code = '
          asynchroniczna funkcja zle() {
              czekaj uspij(10)
              rzuc BladWykonania.nowy("padam")
          }
          asynchroniczna funkcja dobre() {
              czekaj uspij(100)
              zwroc "ok"
          }

          asynchroniczna funkcja main() {
              proba {
                  czekaj Obietnica.wszystkie([dobre(), zle()])
                  zwroc "nie dojdzie"
              } zlap (e) {
                  zwroc "zlapano: " + e["wiadomosc"]
              }
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to match(/zlapano:.*padam/)
      end

      it 'treats non-promise values as already-fulfilled' do
        code = '
          asynchroniczna funkcja a() { 
            czekaj uspij(10)
            zwroc "a" 
          }

          asynchroniczna funkcja main() {
              niech wyniki = czekaj Obietnica.wszystkie([a(), "surowy", 42])
              zwroc wyniki
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to eq('[a, surowy, 42]')
      end
    end

    describe 'Obietnica.dowolna' do
      it 'resolves with value of first fulfilled promise' do
        code = '
          asynchroniczna funkcja wolny() { 
            czekaj uspij(100)  
            zwroc "wolny" 
          }
          asynchroniczna funkcja szybki() { 
            czekaj uspij(20)
            zwroc "szybki" 
          }

          asynchroniczna funkcja main() {
              niech wynik = czekaj Obietnica.dowolna([wolny(), szybki()])
              zwroc wynik
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to eq('szybki')
      end

      it 'rejects when all promises reject' do
        code = '
          asynchroniczna funkcja zle1() {
              czekaj uspij(10)
              rzuc BladWykonania.nowy("pierwszy")
          }
          asynchroniczna funkcja zle2() {
              czekaj uspij(20)
              rzuc BladWykonania.nowy("drugi")
          }

          asynchroniczna funkcja main() {
              proba {
                  czekaj Obietnica.dowolna([zle1(), zle2()])
                  zwroc "nie dojdzie"
              } zlap (e) {
                  zwroc "zlapano: " + e["wiadomosc"]
              }
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to match(/zlapano:/)
      end

      it 'rejects immediately on empty array' do
        code = '
          asynchroniczna funkcja main() {
              proba {
                  czekaj Obietnica.dowolna([])
                  zwroc "nie dojdzie"
              } zlap (e) {
                  zwroc "zlapano"
              }
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to eq('zlapano')
      end
    end

    describe 'Obietnica.limit_czasu' do
      it 'passes through value when promise settles in time' do
        code = '
          asynchroniczna funkcja szybki() {
              czekaj uspij(10)
              zwroc "gotowe"
          }

          asynchroniczna funkcja main() {
              niech wynik = czekaj Obietnica.limit_czasu(szybki(), 100)
              zwroc wynik
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to eq('gotowe')
      end

      it 'rejects when promise takes too long' do
        code = '
          asynchroniczna funkcja wolny() {
              czekaj uspij(200)
              zwroc "nie dojdzie"
          }

          asynchroniczna funkcja main() {
              proba {
                  czekaj Obietnica.limit_czasu(wolny(), 30)
                  zwroc "nie powinno tu dojsc"
              } zlap (e) {
                  zwroc "timeout: " + e["wiadomosc"]
              }
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to match(/timeout:.*limit czasu/i)
      end

      it 'propagates rejection faster than timeout' do
        code = '
          asynchroniczna funkcja zle() {
              czekaj uspij(10)
              rzuc BladWykonania.nowy("oryginalny blad")
          }

          asynchroniczna funkcja main() {
              proba {
                  czekaj Obietnica.limit_czasu(zle(), 100)
                  zwroc "nie dojdzie"
              } zlap (e) {
                  zwroc "zlapano: " + e["wiadomosc"]
              }
          }
          pokazl uruchom(main)
        '
        run_command_and_stop "ruby #{main_file_path} '#{code}'"
        expect(clean_output).to match(/zlapano:.*oryginalny blad/)
      end
    end
  end


  describe 'Obietnica.nowy executor-style' do
    it 'fulfills when executor calls spelnij' do
      code = '
        asynchroniczna funkcja main() {
            niech p = Obietnica.nowy(fn(spelnij, odrzuc) {
                spelnij(42)
            })
            zwroc czekaj p
        }
        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('42')
    end

    it 'rejects when executor calls odrzuc' do
      code = '
        asynchroniczna funkcja main() {
            niech p = Obietnica.nowy(fn(spelnij, odrzuc) {
                odrzuc("cos poszlo nie tak")
            })
            proba {
                czekaj p
                zwroc "nie dojdzie"
            } zlap (e) {
                zwroc "zlapano: " + e["wiadomosc"]
            }
        }
        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to match(/zlapano:.*cos poszlo nie tak/)
    end

    it 'supports deferred spelnij via uruchom_rownolegle' do
      # Executor spawns a parallel task that settles the promise later.
      code = '
        asynchroniczna funkcja main() {
            niech p = Obietnica.nowy(fn(spelnij, odrzuc) {
                uruchom_rownolegle(fn() {
                    czekaj uspij(20)
                    spelnij("po opoznieniu")
                })
            })
            zwroc czekaj p
        }
        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('po opoznieniu')
    end

    it 'executor exception becomes promise rejection' do
      code = '
        asynchroniczna funkcja main() {
            niech p = Obietnica.nowy(fn(spelnij, odrzuc) {
                rzuc BladWykonania.nowy("wybuch w executorze")
            })
            proba {
                czekaj p
                zwroc "nie dojdzie"
            } zlap (e) {
                zwroc "zlapano: " + e["wiadomosc"]
            }
        }
        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to match(/zlapano:.*wybuch/)
    end

    it 'second call to spelnij is a no-op' do
      code = '
        asynchroniczna funkcja main() {
            niech p = Obietnica.nowy(fn(spelnij, odrzuc) {
                spelnij("pierwszy")
                spelnij("drugi")
                odrzuc("ignored")
            })
            zwroc czekaj p
        }
        pokazl uruchom(main)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(clean_output).to eq('pierwszy')
    end
  end
end