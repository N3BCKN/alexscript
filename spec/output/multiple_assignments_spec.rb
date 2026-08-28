require 'aruba/rspec'

# Tests for multiple variable declaration and assignment:
#
#   niech x, y = 4, 5
#   niech a, b = [1, 2]
#   x, y = y, x
#
# Loose regexes are used for error assertions on purpose — they pin down which
# error fires, not its exact wording, so rephrasing a message does not break
# the suite. Tighten them once the wording is final.

RSpec.describe 'Multiple declaration - basics', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'declares two variables at once' do
    code = '
      niech x, y = 4, 5
      pokazl x
      pokazl y
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[4 5])
  end

  it 'declares three variables at once' do
    code = '
      niech a, b, c = 1, 2, 3
      pokazl a + b + c
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('6')
  end

  it 'has no upper limit on the number of targets' do
    code = '
      niech a, b, c, d, e, f, g, h = 1, 2, 3, 4, 5, 6, 7, 8
      pokazl a + b + c + d + e + f + g + h
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('36')
  end

  it 'accepts targets written without spaces after the comma' do
    code = '
      niech x,y,z = 1,2,3
      pokazl z
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('3')
  end

  it 'accepts a declaration split across lines' do
    code = '
      niech pierwszy,
            drugi = 10,
                    20
      pokazl pierwszy + drugi
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('30')
  end

  it 'evaluates the right-hand side left to right' do
    code = '
      funkcja licz(n) {
        pokazl "eval"
        zwroc n
      }
      niech a, b = licz(1), licz(2)
      pokazl a + b
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[eval eval 3])
  end
end

RSpec.describe 'Multiple declaration - types', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'preserves the type of each value independently' do
    code = '
      niech k, f, s = 1, 2.5, "tekst"
      pokazl k.typ()
      pokazl f.typ()
      pokazl s.typ()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[calkowita zmiennoprzecinkowa napis])
  end

  it 'binds prawda, falsz and nic without losing their type' do
    code = '
      niech t, f, n = prawda, falsz, nic
      pokazl t.typ()
      pokazl f.typ()
      pokazl n.typ()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[logiczna logiczna nic])
  end

  it 'keeps bound booleans usable in conditions' do
    code = '
      niech t, f = prawda, falsz
      jesli t {
        pokazl "tak"
      }
      jesli !f {
        pokazl "nie"
      }
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[tak nie])
  end

  it 'binds arrays and objects as whole values' do
    code = '
      niech tab, obj = [1, 2, 3], {"a": 1}
      pokazl tab.dlg()
      pokazl obj["a"]
      pokazl tab.typ()
      pokazl obj.typ()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[3 1 tablica obiekt])
  end

  it 'accepts arbitrary expressions on the right-hand side' do
    code = '
      niech a, b, c = 2 + 3 * 4, 10 / 4, 7 % 3
      pokazl a
      pokazl b
      pokazl c
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.split("\n").map(&:strip)
    expect(output).to eq(%w[14 2.5 1])
  end
end

RSpec.describe 'Multiple declaration - array destructuring', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'destructures an array literal across the targets' do
    code = '
      niech a, b = [10, 20]
      pokazl a
      pokazl b
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[10 20])
  end

  it 'destructures an array held in a variable' do
    code = '
      niech para = [7, 8]
      niech a, b = para
      pokazl a + b
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('15')
  end

  it 'destructures the return value of a function' do
    code = '
      funkcja min_max(arr) {
        zwroc [arr.min(), arr.max()]
      }
      niech mn, mx = min_max([3, 9, 1])
      pokazl mn
      pokazl mx
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[1 9])
  end

  it 'preserves element types while destructuring' do
    code = '
      niech t, n, s = [prawda, nic, "abc"]
      pokazl t.typ()
      pokazl n.typ()
      pokazl s.typ()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[logiczna nic napis])
  end

  it 'does NOT destructure when there is a single target' do
    code = '
      niech tab = [1, 2]
      pokazl tab.typ()
      pokazl tab.dlg()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[tablica 2])
  end

  it 'does not destructure a nested array further than one level' do
    code = '
      niech a, b = [[1, 2], [3, 4]]
      pokazl a.typ()
      pokazl a[1]
      pokazl b[0]
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[tablica 2 3])
  end
end

RSpec.describe 'Multiple assignment - reassignment and swap', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'reassigns already declared variables' do
    code = '
      niech x = 1
      niech y = 2
      x, y = 10, 20
      pokazl x
      pokazl y
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[10 20])
  end

  it 'swaps two variables' do
    code = '
      niech a = 1
      niech b = 2
      a, b = b, a
      pokazl a
      pokazl b
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[2 1])
  end

  it 'rotates three variables in one statement' do
    code = '
      niech a = 1
      niech b = 2
      niech c = 3
      a, b, c = c, a, b
      pokazl a
      pokazl b
      pokazl c
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[3 1 2])
  end

  it 'changes the type of a variable on reassignment' do
    code = '
      niech a = 1
      niech b = 2
      a, b = "tekst", prawda
      pokazl a.typ()
      pokazl b.typ()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[napis logiczna])
  end

  it 'works as a swap inside a loop (bubble sort)' do
    code = '
      niech tab = [5, 2, 9, 1]
      dla niech k = 0; tab.dlg(); 1 {
        dla niech j = 0; tab.dlg() - 1; 1 {
          jesli tab[j] > tab[j + 1] {
            niech pom = tab[j]
            tab[j] = tab[j + 1]
            tab[j + 1] = pom
          }
        }
      }
      pokazl tab[0]
      pokazl tab[3]
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[1 9])
  end
end

RSpec.describe 'Multiple declaration - scope, constants, globals', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'treats UPPERCASE targets as constants' do
    code = '
      niech A, B = 1, 2
      pokazl A
      pokazl B
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[1 2])
  end

  it 'prevents reassigning a constant declared this way' do
    code = '
      niech A, B = 1, 2
      A = 9
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/jest stala i nie moze byc zmieniana/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'prevents reassigning a constant through multiple assignment' do
    code = '
      niech A, B = 1, 2
      A, B = 8, 9
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/jest stala i nie moze byc zmieniana/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'mixes a constant and a regular variable in one declaration' do
    code = '
      niech STALA, zmienna = 100, 1
      zmienna = 2
      pokazl STALA
      pokazl zmienna
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[100 2])
  end

  it 'declares multiple globals' do
    code = '
      globalna niech g1, g2 = 7, 8
      jesli prawda {
        pokazl g1 + g2
      }
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('15')
  end

  it 'keeps multiple declarations local to their block' do
    code = '
      jesli prawda {
        niech ukryta1, ukryta2 = 1, 2
        pokazl ukryta1
      }
      pokazl ukryta2
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/Niezadeklarowany identyfikator ukryta2/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'works inside a function body' do
    code = '
      funkcja test() {
        niech a, b = 3, 4
        zwroc a * b
      }
      pokazl test()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('12')
  end

  it 'works inside a loop body' do
    code = '
      niech suma = 0
      dla niech k = 0; 3; 1 {
        niech a, b = k, k + 1
        suma += a + b
      }
      pokazl suma
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('9')
  end
end

RSpec.describe 'Multiple declaration - classes', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'destructures the array returned by an instance method' do
    code = '
      klasa Punkt {
        funkcja konstruktor(x, y) {
          niech @x = x
          niech @y = y
        }
        funkcja wspolrzedne() {
          zwroc [@x, @y]
        }
      }
      niech p = Punkt.nowy(3, 4)
      niech a, b = p.wspolrzedne()
      pokazl a
      pokazl b
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[3 4])
  end

  it 'destructures the array returned by a static method' do
    code = '
      klasa Zakres {
        statyczna funkcja granice() {
          zwroc [0, 100]
        }
      }
      niech lo, hi = Zakres.granice()
      pokazl lo
      pokazl hi
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[0 100])
  end

  it 'binds two instances to two variables' do
    code = '
      klasa Kot {
        funkcja konstruktor(imie) {
          niech @imie = imie
        }
        funkcja imie() {
          zwroc @imie
        }
      }
      niech a, b = Kot.nowy("Mruczek"), Kot.nowy("Filemon")
      pokazl a.imie()
      pokazl b.imie()
      pokazl a.typ()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[Mruczek Filemon instancja])
  end

  it 'swaps two instances' do
    code = '
      klasa Kot {
        funkcja konstruktor(imie) {
          niech @imie = imie
        }
        funkcja imie() {
          zwroc @imie
        }
      }
      niech a = Kot.nowy("Mruczek")
      niech b = Kot.nowy("Filemon")
      a, b = b, a
      pokazl a.imie()
      pokazl b.imie()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[Filemon Mruczek])
  end

  it 'declares multiple variables inside a method body' do
    code = '
      klasa Kalkulator {
        funkcja suma_i_roznica(a, b) {
          niech s, r = a + b, a - b
          zwroc [s, r]
        }
      }
      niech k = Kalkulator.nowy()
      niech s, r = k.suma_i_roznica(10, 4)
      pokazl s
      pokazl r
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[14 6])
  end

  it 'reads instance variables into multiple locals inside a method' do
    code = '
      klasa Wektor {
        funkcja konstruktor(x, y) {
          niech @x = x
          niech @y = y
        }
        funkcja dlugosc_kw() {
          niech a, b = @x, @y
          zwroc a * a + b * b
        }
      }
      pokazl Wektor.nowy(3, 4).dlugosc_kw()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('25')
  end

  it 'rejects multiple declaration of instance variables' do
    code = '
      klasa Zle {
        funkcja konstruktor() {
          niech @a, @b = 1, 2
        }
      }
      niech z = Zle.nowy()
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/zmiennych instancji|instancji \(@\)/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects multiple declaration of static class variables' do
    code = '
      klasa Zle {
        statyczna niech A, B = 1, 2
      }
      pokazl 1
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.exit_status).not_to eq(0)
  end
end

RSpec.describe 'Multiple declaration - modules', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'destructures the array returned by a module function' do
    code = '
      modul Geo {
        funkcja srodek() {
          zwroc [52, 21]
        }
      }
      niech lat, lon = Geo::srodek()
      pokazl lat
      pokazl lon
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[52 21])
  end

  it 'binds two module constants to two variables' do
    code = '
      modul Stale {
        niech A = 10
        niech B = 20
      }
      niech x, y = Stale::A, Stale::B
      pokazl x + y
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('30')
  end

  it 'declares multiple variables inside a module function' do
    code = '
      modul Narzedzia {
        funkcja przetworz(a, b) {
          niech x, y = b, a
          zwroc x - y
        }
      }
      pokazl Narzedzia::przetworz(3, 10)
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('7')
  end

  it 'works inside a method coming from an included module' do
    code = '
      modul Opisywalny {
        funkcja opis() {
          niech a, b = "obiekt", "klasy"
          zwroc a + " " + b + " " + sam.klasa()
        }
      }
      klasa Produkt {
        dolacz Opisywalny
        funkcja konstruktor() {
          niech @x = 1
        }
      }
      pokazl Produkt.nowy().opis()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('obiekt klasy Produkt')
  end

  it 'rejects multiple declaration directly in a module body' do
    code = '
      modul Zle {
        niech A, B = 1, 2
      }
      pokazl 1
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.exit_status).not_to eq(0)
  end
end

RSpec.describe 'Multiple declaration - error handling', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'rejects more targets than values' do
    code = 'niech a, b = 1'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects more values than targets' do
    code = 'niech a, b = 1, 2, 3'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/Przypisanie wielokrotne/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects an array of the wrong length when destructuring' do
    code = 'niech a, b, c = [1, 2]'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/Przypisanie wielokrotne/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects a non-array single value for several targets' do
    code = 'niech a, b = 5'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects a value list assigned to a single target' do
    code = 'niech x = 4, 5'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects a repeated target' do
    code = 'niech x, x = 1, 2'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/dwukrotnie|wystepuje/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects a keyword used as a target' do
    code = 'niech x, jesli = 1, 2'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/slowem kluczowym/)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects a literal used as a target' do
    code = 'niech x, 10 = 1, 2'
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects reassignment of undeclared variables' do
    code = '
      nowa1, nowa2 = 1, 2
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/musi byc zadeklarowana z .niech./)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'rejects reassignment when only one of the targets is declared' do
    code = '
      niech a = 1
      a, b = 2, 3
    '
    run_command "ruby #{main_file_path} '#{code}'"
    expect(last_command_started).to have_output(/musi byc zadeklarowana z .niech./)
    expect(last_command_started.exit_status).not_to eq(0)
  end

  it 'leaves every target untouched when the assignment fails' do
    code = '
      niech a = 1
      proba {
        a, brak = 2, 3
      } zlap (e) {
        pokazl a
      }
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('1')
  end
end

RSpec.describe 'Multiple declaration - regressions', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  it 'keeps single declaration working' do
    code = 'niech x = 5 pokazl x'
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('5')
  end

  it 'keeps single assignment working' do
    code = '
      niech x = 5
      x = 6
      pokazl x
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('6')
  end

  it 'keeps compound assignment working' do
    code = '
      niech x = 5
      x += 3
      pokazl x
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('8')
  end

  it 'keeps instance variable declaration working' do
    code = '
      klasa K {
        funkcja konstruktor() {
          niech @v = 42
        }
        funkcja v() {
          zwroc @v
        }
      }
      pokazl K.nowy().v()
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('42')
  end

  it 'keeps static variable declaration working' do
    code = '
      klasa Stale {
        statyczna niech PI = 3
      }
      pokazl Stale.PI
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('3')
  end

  it 'keeps module constants working' do
    code = '
      modul M {
        niech A = 5
      }
      pokazl M::A
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('5')
  end

  it 'keeps the comma in for-in loops working' do
    code = '
      dla klucz, wartosc w {"a": 1} {
        pokazl klucz
        pokazl wartosc
      }
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    output = last_command_started.output.strip.gsub(/[\\"]/, '').split("\n").map(&:strip)
    expect(output).to eq(%w[a 1])
  end

  it 'keeps commas in function arguments working' do
    code = '
      funkcja suma(a, b, c) {
        zwroc a + b + c
      }
      pokazl suma(1, 2, 3)
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip).to eq('6')
  end

  it 'keeps commas in array and object literals working' do
    code = '
      niech t = [1, 2, 3]
      niech o = {"a": 1, "b": 2}
      pokazl t.dlg()
      pokazl o["b"]
    '
    run_command_and_stop "ruby #{main_file_path} '#{code}'"
    expect(last_command_started.output.strip.split("\n").map(&:strip)).to eq(%w[3 2])
  end
end