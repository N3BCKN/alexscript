# frozen_string_literal: true

require 'aruba/rspec'

# Tests for modules as first-class values.
#
# Before the fix:
#   - `pokazl Test` → "BladNazwy: Niezadeklarowany identyfikator Test"
#   - `Test.typ()`  → "BladWykonania: Nieznana klasa Test"
#
# After the fix:
#   - Identifier lookup falls through to env.get_module, making modules
#     usable as plain values (:type_module).
#   - StaticMethodCall falls back to the module when no class is found,
#     enabling built-in reflection methods from ModuleMethods.

RSpec.describe 'Module as first-class value', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  #  Bare module name as a value ─

  describe 'printing a module directly' do
    it 'pokazl Module prints a compact summary' do
      code = 'modul Test {}
      pokazl Test'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('modul Test')
    end

    it 'module can be printed without members defined' do
      code = 'modul Pusty {}
      pokazl Pusty'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('modul Pusty')
    end
  end

  #  Reflection methods: .typ() and .nazwa() ─

  describe 'basic reflection' do
    it 'Module.typ() returns "modul"' do
      code = 'modul Test {}
      pokazl Test.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('modul')
    end

    it 'Module.nazwa() returns the module name' do
      code = 'modul Matematyka {}
      pokazl Matematyka.nazwa()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Matematyka')
    end

    it 'Module.id() returns a stable integer' do
      code = 'modul M {}
      pokazl M.id().typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('calkowita')
    end
  end

  #  Listing members: stale / funkcje / klasy / podmoduly 

  describe 'listing module members' do
    it 'lists constants' do
      code = 'modul M {
        niech A = 1
        niech B = 2
      }
      pokazl M.stale()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      out = last_command_started.output.strip
      expect(out).to include('A')
      expect(out).to include('B')
    end

    it 'lists functions' do
      code = 'modul M {
        funkcja pierwsza() { zwroc 1 }
        funkcja druga()   { zwroc 2 }
      }
      pokazl M.funkcje()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      out = last_command_started.output.strip
      expect(out).to include('pierwsza')
      expect(out).to include('druga')
    end

    it 'lists classes' do
      code = 'modul M {
        klasa Foo {}
        klasa Bar {}
      }
      pokazl M.klasy()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      out = last_command_started.output.strip
      expect(out).to include('Foo')
      expect(out).to include('Bar')
    end

    it 'lists nested submodules' do
      code = 'modul Out {
        modul In1 {}
        modul In2 {}
      }
      pokazl Out.podmoduly()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      out = last_command_started.output.strip
      expect(out).to include('In1')
      expect(out).to include('In2')
    end

    it 'returns empty array for a module with no constants' do
      code = 'modul M {}
      pokazl M.stale()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('[]')
    end
  end

  #  zawiera() membership check 

  describe 'Module.zawiera(name)' do
    it 'returns prawda for existing constant' do
      code = 'modul M { niech PI = 3.14 }
      pokazl M.zawiera("PI")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'returns prawda for existing function' do
      code = 'modul M { funkcja f() {} }
      pokazl M.zawiera("f")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'returns prawda for existing class' do
      code = 'modul M { klasa K {} }
      pokazl M.zawiera("K")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'returns prawda for existing nested module' do
      code = 'modul Out { modul In {} }
      pokazl Out.zawiera("In")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'returns falsz for missing name' do
      code = 'modul M { niech A = 1 }
      pokazl M.zawiera("B")'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('falsz')
    end
  end

  #  modul_nadrzedny() for nested vs top-level ─

  describe 'Module.modul_nadrzedny()' do
    it 'returns nic for a top-level module' do
      code = 'modul M {}
      pokazl M.modul_nadrzedny()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('nic')
    end
  end

  #  Interaction with other language features 

  describe 'module value in expressions' do
    it 'can be assigned to a variable and reused' do
      code = 'modul Test {}
      niech m = Test
      pokazl m.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('modul')
    end

    it 'supports reflection on a module referenced via variable' do
      code = 'modul Test { funkcja f() {} }
      niech m = Test
      pokazl m.nazwa()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Test')
    end
  end

  #  Error cases ─

  describe 'error handling' do
    it 'reports unknown module method cleanly' do
      code = 'modul M {}
      pokazl M.nieistniejaca_metoda()'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/BladWykonania: Nieznana metoda 'nieistniejaca_metoda' dla modułu M w linii 2/)
      expect(last_command_started).to have_exit_status(1)
    end

    it 'still reports unknown identifier for truly undefined names' do
      code = 'pokazl CosCzegoNieMa'
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/BladNazwy: Niezadeklarowany identyfikator CosCzegoNieMa/)
      expect(last_command_started).to have_exit_status(1)
    end
  end

  #  Chaining methods on module constants 
 
  describe 'method call on module constant' do
    it 'Test::PI.typ() returns the type of the constant' do
      code = 'modul Test { niech PI = 3.14 }
      pokazl Test::PI.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('zmiennoprzecinkowa')
    end
 
    it 'string constant supports chained method calls' do
      code = 'modul Conf { niech NAZWA = "apka" }
      pokazl Conf::NAZWA.duzymi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('APKA')
    end
 
    it 'integer constant supports .typ()' do
      code = 'modul M { niech N = 42 }
      pokazl M::N.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('calkowita')
    end
 
    it 'chains multiple methods in sequence' do
      code = 'modul M { niech S = "hello" }
      pokazl M::S.duzymi().dlg()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end
 
    it 'constant works inside arithmetic expression' do
      code = 'modul M { niech PI = 3.14 }
      pokazl M::PI + 1'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4.140000000000001').or eq('4.14')
    end
  end
 
  #  Chaining on module function return values ─
 
  describe 'method call on module function result' do
    it 'Test::fun().typ() returns the type of the return value' do
      code = 'modul M {
        funkcja cos() { zwroc "napis" }
      }
      pokazl M::cos().typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('napis')
    end
 
    it 'chains method call on returned integer' do
      code = 'modul M {
        funkcja piec() { zwroc 5 }
      }
      pokazl M::piec().typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('calkowita')
    end
 
    it 'chains multiple methods on returned string' do
      code = 'modul U {
        funkcja dajTekst() { zwroc "abc" }
      }
      pokazl U::dajTekst().duzymi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('ABC')
    end
  end
 
  #  Chaining on module class instantiation 
 
  describe 'method call after module class instantiation' do
    it 'Modul::Klasa.nowy().metoda() works' do
      code = 'modul M {
        klasa Foo {
          funkcja konstruktor() {}
          funkcja hi() { zwroc "witaj" }
        }
      }
      pokazl M::Foo.nowy().hi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('witaj')
    end
 
    it 'supports constructor arguments and chained method' do
      code = 'modul M {
        klasa Licznik {
          funkcja konstruktor(start) { niech @n = start }
          funkcja wartosc() { zwroc @n }
        }
      }
      pokazl M::Licznik.nowy(10).wartosc()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end
  end
 
  #  Index access on module members 
 
  describe 'index access after ::' do
    it 'allows [idx] on module function returning array' do
      code = 'modul M {
        funkcja lista() { zwroc [10, 20, 30] }
      }
      pokazl M::lista()[1]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('20')
    end
  end
 
  #  No regression: old behaviour still works 
 
  describe 'base cases still work unchanged' do
    it 'plain module constant access returns the value' do
      code = 'modul M { niech PI = 3.14 }
      pokazl M::PI'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3.14')
    end
 
    it 'plain module function call works' do
      code = 'modul M { funkcja podwoj(x) { zwroc x * 2 } }
      pokazl M::podwoj(21)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end
 
    it 'plain module class instantiation works' do
      code = 'modul M {
        klasa K {
          funkcja konstruktor() { niech @v = 7 }
          funkcja daj() { zwroc @v }
        }
      }
      niech obj = M::K.nowy()
      pokazl obj.daj()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('7')
    end
  end

   describe 'method call on module constant' do
    it 'Test::PI.typ() returns the type of the constant' do
      code = 'modul Test { niech PI = 3.14 }
      pokazl Test::PI.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('zmiennoprzecinkowa')
    end
 
    it 'string constant supports chained method calls' do
      code = 'modul Conf { niech NAZWA = "apka" }
      pokazl Conf::NAZWA.duzymi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('APKA')
    end
 
    it 'integer constant supports .typ()' do
      code = 'modul M { niech N = 42 }
      pokazl M::N.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('calkowita')
    end
 
    it 'chains multiple methods in sequence' do
      code = 'modul M { niech S = "hello" }
      pokazl M::S.duzymi().dlg()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('5')
    end
 
    it 'constant works inside arithmetic expression' do
      code = 'modul M { niech PI = 3.14 }
      pokazl M::PI + 1'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('4.140000000000001').or eq('4.14')
    end
  end
 
  # ── Chaining on module function return values ─────────────────────────
 
  describe 'method call on module function result' do
    it 'Test::fun().typ() returns the type of the return value' do
      code = 'modul M {
        funkcja cos() { zwroc "napis" }
      }
      pokazl M::cos().typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('napis')
    end
 
    it 'chains method call on returned integer' do
      code = 'modul M {
        funkcja piec() { zwroc 5 }
      }
      pokazl M::piec().typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('calkowita')
    end
 
    it 'chains multiple methods on returned string' do
      code = 'modul U {
        funkcja dajTekst() { zwroc "abc" }
      }
      pokazl U::dajTekst().duzymi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('ABC')
    end
  end
 
  # ── Chaining on module class instantiation ────────────────────────────
 
  describe 'method call after module class instantiation' do
    it 'Modul::Klasa.nowy().metoda() works' do
      code = 'modul M {
        klasa Foo {
          funkcja konstruktor() {}
          funkcja hi() { zwroc "witaj" }
        }
      }
      pokazl M::Foo.nowy().hi()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('witaj')
    end
 
    it 'supports constructor arguments and chained method' do
      code = 'modul M {
        klasa Licznik {
          funkcja konstruktor(start) { niech @n = start }
          funkcja wartosc() { zwroc @n }
        }
      }
      pokazl M::Licznik.nowy(10).wartosc()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('10')
    end
  end
 
  # ── Index access on module members ────────────────────────────────────
 
  describe 'index access after ::' do
    it 'allows [idx] on module function returning array' do
      code = 'modul M {
        funkcja lista() { zwroc [10, 20, 30] }
      }
      pokazl M::lista()[1]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('20')
    end
  end
 
  # ── No regression: old behaviour still works ──────────────────────────
 
  describe 'base cases still work unchanged' do
    it 'plain module constant access returns the value' do
      code = 'modul M { niech PI = 3.14 }
      pokazl M::PI'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('3.14')
    end
 
    it 'plain module function call works' do
      code = 'modul M { funkcja podwoj(x) { zwroc x * 2 } }
      pokazl M::podwoj(21)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end
 
    it 'plain module class instantiation works' do
      code = 'modul M {
        klasa K {
          funkcja konstruktor() { niech @v = 7 }
          funkcja daj() { zwroc @v }
        }
      }
      niech obj = M::K.nowy()
      pokazl obj.daj()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('7')
    end
  end
end