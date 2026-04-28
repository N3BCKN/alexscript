require 'aruba/rspec'

RSpec.describe 'User-defined methods override built-in introspection', type: :aruba do
  let(:main_file_path) { File.expand_path('../../lib/alexscript.rb', File.dirname(__FILE__)) }

  describe 'overriding common collision names' do
    it 'user-defined id() wins over built-in object_id' do
      code = 'klasa Uzytkownik {
        funkcja konstruktor(id) {
          niech @id = id
        }
        funkcja id() {
          zwroc @id
        }
      }
      niech u = Uzytkownik.nowy("user-123")
      pokazl u.id()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('user-123')
    end

    it 'user-defined typ() wins over built-in typ' do
      code = 'klasa Produkt {
        funkcja konstruktor(typ) {
          niech @typ = typ
        }
        funkcja typ() {
          zwroc @typ
        }
      }
      niech p = Produkt.nowy("elektronika")
      pokazl p.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('elektronika')
    end

    it 'user-defined napis() wins over built-in napis' do
      code = 'klasa Punkt {
        funkcja konstruktor(x, y) {
          niech @x = x
          niech @y = y
        }
        funkcja napis() {
          zwroc "(#{@x.napis()}, #{@y.napis()})"
        }
      }
      niech p = Punkt.nowy(3, 4)
      pokazl p.napis()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('(3, 4)')
    end

    it 'user-defined klasa() wins over built-in klasa' do
      code = 'klasa Uczen {
        funkcja konstruktor(klasa_szkolna) {
          niech @klasa_szkolna = klasa_szkolna
        }
        funkcja klasa() {
          zwroc @klasa_szkolna
        }
      }
      niech u = Uczen.nowy("5A")
      pokazl u.klasa()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('5A')
    end

    it 'user-defined kopia() wins over built-in kopia' do
      code = 'klasa Dokument {
        funkcja konstruktor(tresc) {
          niech @tresc = tresc
        }
        funkcja kopia() {
          zwroc "kopia: " + @tresc
        }
      }
      niech d = Dokument.nowy("zawartosc")
      pokazl d.kopia()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('kopia: zawartosc')
    end
  end

  describe 'built-in fallback when no user-defined method' do
    it 'built-in id() works on a class without user id()' do
      code = 'klasa Bezosobowy {
        funkcja konstruktor() {}
      }
      niech b = Bezosobowy.nowy()
      pokazl b.id().typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      # built-in id zwraca object_id — Integer, czyli "calkowita"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('calkowita')
    end

    it 'built-in klasa() works when user class defines no klasa method' do
      code = 'klasa Pies {
        funkcja konstruktor() {}
      }
      niech p = Pies.nowy()
      pokazl p.klasa()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('Pies')
    end

    it 'built-in metody() lists user methods even when no override' do
      code = 'klasa Kot {
        funkcja konstruktor() {}
        funkcja miauczenie() { zwroc "miau" }
      }
      niech k = Kot.nowy()
      pokazl k.metody()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      out = last_command_started.output.strip
      # built-in zwraca posortowaną listę zawierającą miauczenie
      expect(out).to include('miauczenie')
    end
  end

  describe 'override correctness — user method receives correct arguments' do
    it 'user-defined method with arguments dispatches normally' do
      code = 'klasa Liczby {
        funkcja konstruktor() {
          niech @stan = 0
        }
        funkcja id(dodaj) {
          zwroc @stan + dodaj
        }
      }
      niech l = Liczby.nowy()
      pokazl l.id(42)'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('42')
    end

    it 'user-defined method has access to instance variables' do
      code = 'klasa Konto {
        funkcja konstruktor(saldo) {
          niech @saldo = saldo
        }
        funkcja typ() {
          jesli @saldo > 1000 to zwroc "premium"
          zwroc "standard"
        }
      }
      niech k1 = Konto.nowy(500)
      niech k2 = Konto.nowy(5000)
      pokazl k1.typ()
      pokazl k2.typ()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("standard\npremium")
    end
  end

  describe 'inheritance preserves override semantics' do
    it 'override in parent is inherited by child' do
      code = 'klasa Bazowa {
        funkcja konstruktor() {
          niech @nazwa = "bazowa-id"
        }
        funkcja id() {
          zwroc @nazwa
        }
      }

      klasa Pochodna < Bazowa {
        funkcja konstruktor() {
          super()
        }
      }

      niech p = Pochodna.nowy()
      pokazl p.id()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('bazowa-id')
    end

    it 'child can override parent override' do
      code = 'klasa Bazowa {
        funkcja konstruktor() {}
        funkcja id() {
          zwroc "bazowa"
        }
      }

      klasa Pochodna < Bazowa {
        funkcja konstruktor() { super() }
        funkcja id() {
          zwroc "pochodna"
        }
      }

      niech p = Pochodna.nowy()
      pokazl p.id()'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('pochodna')
    end
  end

  describe 'real-world idiom: id used as object key' do
    # Powtórzenie scenariusza z bug raportu — id() jako klucz w obiekcie/JSON
    it 'overridden id() returns string usable as object key' do
      code = 'klasa Sesja {
        funkcja konstruktor(id) {
          niech @id = id
        }
        funkcja id() {
          zwroc @id
        }
      }

      niech s = Sesja.nowy("abc123")
      niech magazyn = {}
      magazyn[s.id()] = "zalogowany"
      pokazl magazyn["abc123"]'
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq('zalogowany')
    end
  end

  describe 'unknown method still raises' do
    it 'raises BladMetody for a name that is neither user nor built-in' do
      code = 'klasa Pusta {
        funkcja konstruktor() {}
      }
      niech p = Pusta.nowy()
      pokazl p.totalnie_nieznana_metoda()'
      run_command "ruby #{main_file_path} '#{code}'"
      last_command_started.stop
      expect(last_command_started.exit_status).not_to eq(0)
    end
  end
end