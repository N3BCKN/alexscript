# frozen_string_literal: true

require 'aruba/rspec'

# Tests for static method and static variable access on classes defined
# inside modules. Before the fix:
#   Test::Cos.moja_funkcja()   -> Nieznana metoda moja_funkcja dla typu type_class
#   Test::Cos::moja_funkcja()  -> Nie znaleziono funkcji w module Test::Cos
#   Test::Cos.STALA            -> Nieznana metoda statyczna STALA
#   Test::Cos::STALA           -> Nie znaleziono 'STALA' w module Test::Cos
#
# After the fix: all four patterns resolve correctly.

RSpec.describe 'Static members on module classes', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # ── Static methods with dot syntax ────────────────────────────────────

  describe 'Modul::Klasa.metoda_statyczna()' do
    it 'calls a user-defined static method via dot' do
      code = 'modul Test {
        klasa Cos {
          statyczna funkcja moja_funkcja() { zwroc "ze statyka" }
        }
      }
      pokazl Test::Cos.moja_funkcja()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('ze statyka')
    end

    it 'passes arguments to static method' do
      code = 'modul M {
        klasa K {
          statyczna funkcja dodaj(a, b) { zwroc a + b }
        }
      }
      pokazl M::K.dodaj(7, 35)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'built-in reflection keeps working on module class' do
      code = 'modul M {
        klasa K {
          funkcja konstruktor() {}
        }
      }
      pokazl M::K.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('klasa')
    end

    it 'reflection nazwa() returns the class name' do
      code = 'modul M {
        klasa Widget {}
      }
      pokazl M::Widget.nazwa()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Widget')
    end
  end

  # ── Static methods with double-colon syntax ───────────────────────────

  describe 'Modul::Klasa::metoda_statyczna()' do
    it 'calls a user-defined static method via ::' do
      code = 'modul Test {
        klasa Cos {
          statyczna funkcja moja_funkcja() { zwroc "ze statyka" }
        }
      }
      pokazl Test::Cos::moja_funkcja()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('ze statyka')
    end

    it 'dot and double-colon produce identical results' do
      code = 'modul M {
        klasa K {
          statyczna funkcja wartosc() { zwroc 100 }
        }
      }
      pokazl M::K.wartosc()
      pokazl M::K::wartosc()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      lines = last_command_started.output.strip.split("\n").map(&:strip)
      expect(lines[0]).to eq('100')
      expect(lines[1]).to eq('100')
    end
  end

  # ── Static vars with both syntaxes ────────────────────────────────────

  describe 'Modul::Klasa.STATYCZNA and Modul::Klasa::STATYCZNA' do
    it 'reads static var with dot syntax' do
      code = 'modul M {
        klasa K {
          statyczna niech WERSJA = 7
        }
      }
      pokazl M::K.WERSJA'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('7')
    end

    it 'reads static var with double-colon syntax' do
      code = 'modul M {
        klasa K {
          statyczna niech WERSJA = 7
        }
      }
      pokazl M::K::WERSJA'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('7')
    end
  end

  # ── Instance methods still work (no regression) ───────────────────────

  describe 'no regression: instance methods' do
    it 'instance method on module class still callable' do
      code = 'modul M {
        klasa K {
          funkcja konstruktor() {}
          funkcja powitanie() { zwroc "witaj" }
        }
      }
      pokazl M::K.nowy().powitanie()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('witaj')
    end

    it 'mixed: static + instance methods in same class' do
      code = 'modul M {
        klasa Kalkulator {
          statyczna funkcja wersja() { zwroc "1.0" }

          funkcja konstruktor(x) { niech @x = x }
          funkcja daj() { zwroc @x }
        }
      }
      pokazl M::Kalkulator.wersja()
      pokazl M::Kalkulator.nowy(42).daj()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      lines = last_command_started.output.strip.split("\n").map(&:strip)
      expect(lines[0].gsub(/[\\"]/, '')).to eq('1.0')
      expect(lines[1]).to eq('42')
    end
  end

  # ── Static methods on top-level class (non-module) ────────────────────

  describe 'no regression: top-level class static' do
    it 'Klasa.metoda_statyczna() still works' do
      code = 'klasa K {
        statyczna funkcja f() { zwroc "ok" }
      }
      pokazl K.f()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('ok')
    end

    it 'Klasa::metoda_statyczna() also works (symmetry side effect)' do
      code = 'klasa K {
        statyczna funkcja f() { zwroc "ok" }
      }
      pokazl K::f()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('ok')
    end

    it 'Klasa::STATIC_VAR also works (symmetry side effect)' do
      code = 'klasa K {
        statyczna niech WERSJA = 3
      }
      pokazl K::WERSJA'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3')
    end
  end

  # ── Inheritance: parent class in same module ──────────────────────────

  describe 'static method inherited through parent in same module' do
    it 'finds static method declared on parent class in the same module' do
      code = 'modul M {
        klasa Baza {
          statyczna funkcja hello() { zwroc "z bazy" }
        }
        klasa Dziecko < Baza {}
      }
      pokazl M::Dziecko.hello()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('z bazy')
    end
  end
end