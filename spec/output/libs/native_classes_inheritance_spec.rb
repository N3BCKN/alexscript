require 'aruba/rspec'

RSpec.describe 'Native class inheritance and introspection', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # ── 1. Introspection ───────────────────────────────────────

  describe 'introspection on native classes' do
    it 'Czas.metody() returns native methods' do
      code = '
        import("czas")
        niech m = Czas.metody_statyczne()
        pokazl m.zawiera("teraz")
        pokazl m.zawiera("utc")
        pokazl m.zawiera("parsuj")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end

    it 'instance.metody() returns native instance methods' do
      code = '
        import("czas")
        niech t = Czas.nowy()
        niech m = t.metody()
        pokazl m.zawiera("rok")
        pokazl m.zawiera("miesiac")
        pokazl m.zawiera("dodaj_dni")
        pokazl m.zawiera("nazwa_dnia_tygodnia")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda\nprawda")
    end

    it 'Mat.metody_statyczne() returns native static methods' do
      code = '
        import("mat")
        niech m = Mat.metody_statyczne()
        pokazl m.zawiera("sin")
        pokazl m.zawiera("sqrt")
        pokazl m.zawiera("losowa")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end
  end

  # ── 2. Basic inheritance ────────────────────────────────────

  describe 'inheriting from native class' do
    it 'subclass without constructor inherits native constructor and methods' do
      code = '
        import("czas")
        klasa MojCzas < Czas {}
        niech t = MojCzas.nowy(2024, 6, 15)
        pokazl t.rok()
        pokazl t.miesiac()
        pokazl t.dzien()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2024\n6\n15")
    end

    it 'inherited instance has access to all native methods' do
      code = '
        import("czas")
        klasa MojCzas < Czas {}
        niech t = MojCzas.nowy(2024, 3, 14)
        pokazl t.nazwa_dnia_tygodnia()
        pokazl t.czy_czwartek()
        pokazl t.format("%Y-%m-%d")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("czwartek\nprawda\n2024-03-14")
    end

    it 'inherited instance reports correct class name' do
      code = '
        import("czas")
        klasa MojCzas < Czas {}
        niech t = MojCzas.nowy()
        pokazl t.klasa()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("MojCzas")
    end
  end

  # ── 3. Subclass with constructor using super() ──────────────

  describe 'subclass with super()' do
    it 'passes arguments to native parent constructor' do
      code = '
        import("czas")
        klasa DataUrodzenia < Czas {
          funkcja konstruktor(rok, miesiac, dzien) {
            super(rok, miesiac, dzien)
            niech @opis = "Urodziny"
          }

          funkcja opis() {
            zwroc @opis + ": " + sam.format("%d.%m.%Y")
          }
        }

        niech d = DataUrodzenia.nowy(1990, 5, 15)
        pokazl d.rok()
        pokazl d.miesiac()
        pokazl d.opis()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("1990\n5\nUrodziny: 15.05.1990")
    end
  end

  # ── 4. Method overriding ────────────────────────────────────

  describe 'overriding native methods' do
    it 'AS method overrides native method' do
      code = '
        import("czas")
        klasa PolskiCzas < Czas {
          funkcja do_tekstu() {
            zwroc sam.nazwa_dnia_tygodnia() + ", " + sam.dzien() + " " + sam.nazwa_miesiaca_dopelniacz() + " " + sam.rok()
          }
        }

        niech t = PolskiCzas.nowy(2024, 3, 14)
        pokazl t.do_tekstu()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("czwartek, 14 marca 2024")
    end

    it 'subclass can add new methods alongside inherited ones' do
      code = '
        import("czas")
        klasa Stoper < Czas {
          funkcja konstruktor() {
            super()
            niech @start = sam.timestamp_f()
          }

          funkcja uplynal() {
            niech teraz = Czas.teraz()
            zwroc teraz.timestamp_f() - @start
          }
        }

        niech s = Stoper.nowy()
        Czas.uspij(0.05)
        niech t = s.uplynal()
        pokazl t >= 0.04
        pokazl s.rok() > 2000
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end
  end

  # ── 5. Introspection on subclass ────────────────────────────

  describe 'introspection on subclass' do
    it 'subclass.metody() includes inherited native methods' do
      code = '
        import("czas")
        klasa MojCzas < Czas {}
        niech t = MojCzas.nowy()
        niech m = t.metody()
        pokazl m.zawiera("rok")
        pokazl m.zawiera("dodaj_dni")
        pokazl m.zawiera("nazwa_miesiaca")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end

    it 'subclass with override shows overridden method' do
      code = '
        import("czas")
        klasa MojCzas < Czas {
          funkcja moja_metoda() {
            zwroc 42
          }
        }
        niech t = MojCzas.nowy()
        niech m = t.metody()
        pokazl m.zawiera("moja_metoda")
        pokazl m.zawiera("rok")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end
  end

  # ── 6. Arithmetic still works on subclass ───────────────────

  describe 'arithmetic on subclass' do
    it 'inherited arithmetic returns proper results' do
      code = '
        import("czas")
        klasa MojCzas < Czas {}
        niech t = MojCzas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.dodaj_dni(1)
        pokazl t2.dzien()
        pokazl t2.godzina()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2\n12")
    end
  end
end
