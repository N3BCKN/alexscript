# frozen_string_literal: true

require 'aruba/rspec'

# Tests for module reopening: multiple `modul Foo { ... }` blocks contribute
# to a single shared module, following Ruby-like semantics.
#
# Conflict policy:
#   constants -> runtime error on redefinition (strict)
#   functions -> silent overwrite
#   classes   -> reopened in place; methods merge/overwrite
#   nested    -> recursive reopen

RSpec.describe 'Module reopening', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # ── Basic reopen: additive ────────────────────────────────────────────

  describe 'additive reopen' do
    it 'second block adds a new constant visible alongside the first' do
      code = 'modul M { niech A = 1 }
      modul M { niech B = 2 }
      pokazl M::A
      pokazl M::B'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      lines = last_command_started.output.strip.split("\n").map(&:strip)
      expect(lines).to include('1', '2')
    end

    it 'second block adds a new function callable normally' do
      code = 'modul M {
        funkcja pierwsza() { zwroc "a" }
      }
      modul M {
        funkcja druga() { zwroc "b" }
      }
      pokazl M::pierwsza()
      pokazl M::druga()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      out = last_command_started.output
      expect(out).to match(/a/)
      expect(out).to match(/b/)
    end

    it 'second block adds a new class usable via ::' do
      code = 'modul M {
        klasa Foo {
          funkcja konstruktor() {}
          funkcja nazwa() { zwroc "foo" }
        }
      }
      modul M {
        klasa Bar {
          funkcja konstruktor() {}
          funkcja nazwa() { zwroc "bar" }
        }
      }
      pokazl M::Foo.nowy().nazwa()
      pokazl M::Bar.nowy().nazwa()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      out = last_command_started.output.gsub(/[\\"]/, '')
      expect(out).to match(/foo/)
      expect(out).to match(/bar/)
    end

    it 'three consecutive reopens all contribute' do
      code = 'modul M { niech A = 1 }
      modul M { niech B = 2 }
      modul M { niech C = 3 }
      pokazl M::A + M::B + M::C'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('6')
    end

    it 'reflection reflects the merged state' do
      code = 'modul M { niech A = 1 }
      modul M { niech B = 2 }
      pokazl M.stale()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      out = last_command_started.output.strip
      expect(out).to include('A')
      expect(out).to include('B')
    end
  end

  # ── Class reopen: methods merge and override ──────────────────────────

  describe 'class reopen inside a module' do
    it 'second block adds a new method to the existing class' do
      code = 'modul M {
        klasa C {
          funkcja konstruktor() {}
          funkcja alfa() { zwroc "A" }
        }
      }
      modul M {
        klasa C {
          funkcja beta() { zwroc "B" }
        }
      }
      niech c = M::C.nowy()
      pokazl c.alfa()
      pokazl c.beta()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      out = last_command_started.output.gsub(/[\\"]/, '')
      expect(out).to match(/A/)
      expect(out).to match(/B/)
    end

    it 'second block overrides an existing method' do
      code = 'modul M {
        klasa C {
          funkcja konstruktor() {}
          funkcja wartosc() { zwroc 1 }
        }
      }
      modul M {
        klasa C {
          funkcja wartosc() { zwroc 42 }
        }
      }
      pokazl M::C.nowy().wartosc()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'instance created before reopen still uses the original (static binding on method lookup)' do
      # Method lookup is dynamic through class_def in module_def, and reopen
      # mutates the SAME class_def in place. So even an instance created before
      # the reopen sees the new method via lookup.
      code = 'modul M {
        klasa C {
          funkcja konstruktor() {}
          funkcja metoda() { zwroc "stara" }
        }
      }
      niech c = M::C.nowy()
      modul M {
        klasa C {
          funkcja metoda() { zwroc "nowa" }
        }
      }
      pokazl c.metoda()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('nowa')
    end
  end

  # ── Nested module reopen ──────────────────────────────────────────────

  describe 'nested module reopen' do
    it 'outer reopen that extends a nested module' do
      code = 'modul Out {
        modul In { niech A = 1 }
      }
      modul Out {
        modul In { niech B = 2 }
      }
      pokazl Out::In::A
      pokazl Out::In::B'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      lines = last_command_started.output.strip.split("\n").map(&:strip)
      expect(lines).to include('1', '2')
    end

    it 'outer reopen that adds a brand-new nested module' do
      code = 'modul Out {
        modul First { niech X = 1 }
      }
      modul Out {
        modul Second { niech Y = 2 }
      }
      pokazl Out::First::X
      pokazl Out::Second::Y'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      lines = last_command_started.output.strip.split("\n").map(&:strip)
      expect(lines).to include('1', '2')
    end
  end

  # ── Function reopen policy: silent overwrite ──────────────────────────

  describe 'function reopen (silent overwrite)' do
    it 'last definition of the same function name wins' do
      code = 'modul M {
        funkcja f() { zwroc 1 }
      }
      modul M {
        funkcja f() { zwroc 2 }
      }
      pokazl M::f()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('2')
    end
  end

  # ── Conflict policy: constants are strict ─────────────────────────────
  # NOTE: these tests expect AS to exit non-zero, so run_command + stop.

  describe 'constant redefinition is an error' do
    it 'same constant in reopened module raises runtime error' do
      code = 'modul M { niech PI = 3.14 }
      modul M { niech PI = 3.0 }'
      run_command "ruby #{main_file_path} '#{code}'"
      stop_all_commands
      expect(last_command_started.output).to match(/PI/)
      expect(last_command_started.output).to match(/zdefiniowana/i)
    end

    it 'same constant in the same block still raises runtime error' do
      # this also used to work before Task 3 — verifying we did not regress
      code = 'modul M {
        niech PI = 3.14
        niech PI = 3.0
      }'
      run_command "ruby #{main_file_path} '#{code}'"
      stop_all_commands
      expect(last_command_started.output).to match(/PI/)
    end
  end

  # ── Cross-declaration usage within reopen ─────────────────────────────

  describe 'cross-reference between reopen blocks' do
    it 'function added in second block uses constant from first block' do
      code = 'modul M { niech PI = 3 }
      modul M {
        funkcja obwod(r) { zwroc 2 * PI * r }
      }
      pokazl M::obwod(5)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('30')
    end

    it 'class in second block dolacza sibling module from first block' do
      code = 'modul App {
        modul Helpers {
          funkcja powitanie() { zwroc "witaj" }
        }
      }
      modul App {
        klasa Controller {
          dolacz Helpers
          funkcja konstruktor() {}
          funkcja akcja() { zwroc powitanie() }
        }
      }
      pokazl App::Controller.nowy().akcja()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('witaj')
    end
  end

  # ── No regression on single-definition modules ────────────────────────

  describe 'no regression' do
    it 'plain single-block module still works exactly as before' do
      code = 'modul M {
        niech PI = 3.14
        funkcja kw(x) { zwroc x * x }
        klasa P {
          funkcja konstruktor(x) { niech @x = x }
          funkcja daj() { zwroc @x }
        }
      }
      pokazl M::PI
      pokazl M::kw(4)
      pokazl M::P.nowy(7).daj()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      lines = last_command_started.output.strip.split("\n").map(&:strip)
      expect(lines).to include('3.14', '16', '7')
    end
  end
end