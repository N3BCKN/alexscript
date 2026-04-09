require 'aruba/rspec'

RSpec.describe 'Czas native library', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # ── 1. Construction ─────────────────────────────────────────

  describe 'construction' do
    it 'creates current time with Czas.teraz()' do
      code = '
        import("czas")
        niech t = Czas.teraz()
        pokazl t.rok() > 2000
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'creates current time with Czas.nowy()' do
      code = '
        import("czas")
        niech t = Czas.nowy()
        pokazl t.rok() > 2000
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq('prawda')
    end

    it 'creates time from full components' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 6, 15, 14, 30, 45)
        pokazl t.rok()
        pokazl t.miesiac()
        pokazl t.dzien()
        pokazl t.godzina()
        pokazl t.minuta()
        pokazl t.sekunda()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2024\n6\n15\n14\n30\n45")
    end

    it 'creates time with partial components (defaults to Jan 1 00:00:00)' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024)
        pokazl t.miesiac()
        pokazl t.dzien()
        pokazl t.godzina()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n1\n0")
    end

    it 'creates time from string' do
      code = '
        import("czas")
        niech t = Czas.nowy("2024-03-15 10:20:30")
        pokazl t.rok()
        pokazl t.miesiac()
        pokazl t.dzien()
        pokazl t.godzina()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2024\n3\n15\n10")
    end

    it 'creates from Unix timestamp with z_timestampu()' do
      code = '
        import("czas")
        niech t = Czas.z_timestampu(0)
        pokazl t.rok()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1970")
    end

    it 'creates UTC time' do
      code = '
        import("czas")
        niech t = Czas.utc(2024, 1, 1, 12, 0, 0)
        pokazl t.czy_utc()
        pokazl t.rok()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\n2024")
    end

    it 'creates local time' do
      code = '
        import("czas")
        niech t = Czas.lokalny(2024, 7, 4, 18, 0, 0)
        pokazl t.rok()
        pokazl t.miesiac()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2024\n7")
    end

    it 'parses time from string with parsuj()' do
      code = '
        import("czas")
        niech t = Czas.parsuj("2024-08-20 09:15:30")
        pokazl t.rok()
        pokazl t.miesiac()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2024\n8")
    end

    it 'parses with explicit format via parsuj_format()' do
      code = '
        import("czas")
        niech t = Czas.parsuj_format("20/06/2024", "%d/%m/%Y")
        pokazl t.dzien()
        pokazl t.miesiac()
        pokazl t.rok()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("20\n6\n2024")
    end

    it 'parses ISO8601 format' do
      code = '
        import("czas")
        niech t = Czas.z_iso8601("2024-06-15T14:30:00Z")
        pokazl t.rok()
        pokazl t.miesiac()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2024\n6")
    end
  end

  # ── 2. Getters ──────────────────────────────────────────────

  describe 'getters' do
    it 'returns all date/time components' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 14, 15, 9, 26)
        pokazl t.rok()
        pokazl t.miesiac()
        pokazl t.dzien()
        pokazl t.godzina()
        pokazl t.minuta()
        pokazl t.sekunda()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2024\n3\n14\n15\n9\n26")
    end

    it 'returns day of year (leap year)' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 14)
        pokazl t.dzien_roku()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("74")
    end

    it 'returns day of week (Thursday = 4)' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 14)
        pokazl t.dzien_tygodnia()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("4")
    end

    it 'returns timestamp as integer' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1)
        pokazl t.timestamp() > 0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'returns UTC timezone info' do
      code = '
        import("czas")
        niech t = Czas.utc(2024, 1, 1)
        pokazl t.strefa()
        pokazl t.przesuniecie_utc()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("UTC\n0")
    end

    it 'returns microseconds and nanoseconds for whole-second time' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1)
        pokazl t.mikrosekunda()
        pokazl t.nanosekunda()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n0")
    end
  end

  # ── 3. Day-of-week predicates ───────────────────────────────

  describe 'day-of-week predicates' do
    it 'correctly identifies Thursday' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 14)
        pokazl t.czy_czwartek()
        pokazl t.czy_poniedzialek()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nfalsz")
    end

    it 'correctly identifies Sunday' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 17)
        pokazl t.czy_niedziela()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'correctly identifies all days of the week' do
      code = '
        import("czas")
        pokazl Czas.nowy(2024, 3, 11).czy_poniedzialek()
        pokazl Czas.nowy(2024, 3, 12).czy_wtorek()
        pokazl Czas.nowy(2024, 3, 13).czy_sroda()
        pokazl Czas.nowy(2024, 3, 14).czy_czwartek()
        pokazl Czas.nowy(2024, 3, 15).czy_piatek()
        pokazl Czas.nowy(2024, 3, 16).czy_sobota()
        pokazl Czas.nowy(2024, 3, 17).czy_niedziela()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda\nprawda\nprawda\nprawda\nprawda")
    end
  end

  # ── 4. State predicates ─────────────────────────────────────

  describe 'state predicates' do
    it 'detects UTC time' do
      code = '
        import("czas")
        niech t = Czas.utc(2024, 1, 1)
        pokazl t.czy_utc()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'czy_czas_letni returns a boolean' do
      code = '
        import("czas")
        niech t = Czas.lokalny(2024, 1, 1)
        niech wynik = t.czy_czas_letni()
        pokazl wynik == prawda lub wynik == falsz
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end
  end

  # ── 5. Arithmetic ───────────────────────────────────────────

  describe 'arithmetic' do
    it 'adds seconds' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.dodaj(60)
        pokazl t2.minuta()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1")
    end

    it 'adds minutes' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.dodaj_minuty(30)
        pokazl t2.minuta()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("30")
    end

    it 'adds hours' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.dodaj_godziny(3)
        pokazl t2.godzina()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("15")
    end

    it 'adds days' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.dodaj_dni(1)
        pokazl t2.dzien()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2")
    end

    it 'adds weeks' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.dodaj_tygodnie(1)
        pokazl t2.dzien()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("8")
    end

    it 'subtracts seconds' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.odejmij(60)
        pokazl t2.godzina()
        pokazl t2.minuta()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("11\n59")
    end

    it 'subtracts days crossing month boundary' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.odejmij_dni(1)
        pokazl t2.miesiac()
        pokazl t2.dzien()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("12\n31")
    end

    it 'chains arithmetic operations' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.dodaj_dni(1).dodaj_godziny(2).dodaj_minuty(30)
        pokazl t2.dzien()
        pokazl t2.godzina()
        pokazl t2.minuta()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2\n14\n30")
    end

    it 'handles negative addition (going back in time)' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = t.dodaj(-3600)
        pokazl t2.godzina()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("11")
    end

    it 'calculates difference between two times' do
      code = '
        import("czas")
        niech t1 = Czas.nowy(2024, 1, 1, 12, 0, 0)
        niech t2 = Czas.nowy(2024, 1, 1, 13, 0, 0)
        pokazl t2.roznica(t1)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("3600.0")
    end
  end

  # ── 6. Comparison ───────────────────────────────────────────

  describe 'comparison' do
    it 'compares with przed() and po()' do
      code = '
        import("czas")
        niech t1 = Czas.nowy(2024, 1, 1)
        niech t2 = Czas.nowy(2024, 12, 31)
        pokazl t1.przed(t2)
        pokazl t2.po(t1)
        pokazl t2.przed(t1)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nfalsz")
    end

    it 'compares with porownaj() returning -1, 0, 1' do
      code = '
        import("czas")
        niech t1 = Czas.nowy(2024, 1, 1)
        niech t2 = Czas.nowy(2024, 12, 31)
        niech t3 = Czas.nowy(2024, 1, 1)
        pokazl t1.porownaj(t2)
        pokazl t2.porownaj(t1)
        pokazl t1.porownaj(t3)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("-1\n1\n0")
    end

    it 'checks miedzy()' do
      code = '
        import("czas")
        niech od = Czas.nowy(2024, 1, 1)
        niech do_czasu = Czas.nowy(2024, 12, 31)
        niech srodek = Czas.nowy(2024, 6, 15)
        pokazl srodek.miedzy(od, do_czasu)
        pokazl od.miedzy(srodek, do_czasu)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nfalsz")
    end
  end

  # ── 7. Formatting ───────────────────────────────────────────

  describe 'formatting' do
    it 'formats with strftime via format()' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 15, 14, 30, 45)
        pokazl t.format("%Y-%m-%d")
        pokazl t.format("%H:%M:%S")
        pokazl t.format("%d.%m.%Y %H:%M")
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("2024-03-15\n14:30:45\n15.03.2024 14:30")
    end

    it 'converts to ISO8601' do
      code = '
        import("czas")
        niech t = Czas.utc(2024, 3, 15, 14, 30, 45)
        pokazl t.iso8601()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to include("2024-03-15T14:30:45Z")
    end

    it 'converts to UTC and back to local' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 15, 14, 30, 45)
        niech utc = t.do_utc()
        pokazl utc.czy_utc()
        niech lok = utc.do_lokalnego()
        pokazl lok.rok()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\n2024")
    end

    it 'converts to specific timezone' do
      code = '
        import("czas")
        niech t = Czas.utc(2024, 1, 1, 12, 0, 0)
        niech tokyo = t.do_strefy("+09:00")
        pokazl tokyo.godzina()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("21")
    end
  end

  # ── 8. Rounding ─────────────────────────────────────────────

  describe 'rounding' do
    it 'rounds, ceils and floors subseconds' do
      code = '
        import("czas")
        niech t = Czas.z_timestampu(1700000000.7)
        niech z = t.zaokraglij(0)
        niech s = t.sufit(0)
        niech p = t.podloga(0)
        pokazl z.mikrosekunda()
        pokazl s.mikrosekunda()
        pokazl p.mikrosekunda()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("0\n0\n0")
    end
  end

  # ── 9. Polish locale names ──────────────────────────────────

  describe 'Polish locale names' do
    it 'returns day name and abbreviation' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 14)
        pokazl t.nazwa_dnia_tygodnia()
        pokazl t.nazwa_dnia_skrot()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("czwartek\nczw")
    end

    it 'returns month name in all forms' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 14)
        pokazl t.nazwa_miesiaca()
        pokazl t.nazwa_miesiaca_dopelniacz()
        pokazl t.nazwa_miesiaca_skrot()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("marzec\nmarca\nmar")
    end

    it 'returns all 12 months in nominative' do
      code = '
        import("czas")
        dla niech m = 1; 13; 1 {
          niech t = Czas.nowy(2024, m, 1)
          pokazl t.nazwa_miesiaca()
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expected = %w[styczeń luty marzec kwiecień maj czerwiec lipiec sierpień wrzesień październik listopad grudzień].join("\n")
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq(expected)
    end

    it 'returns all 12 months in genitive' do
      code = '
        import("czas")
        dla niech m = 1; 13; 1 {
          niech t = Czas.nowy(2024, m, 1)
          pokazl t.nazwa_miesiaca_dopelniacz()
        }
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expected = %w[stycznia lutego marca kwietnia maja czerwca lipca sierpnia września października listopada grudnia].join("\n")
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq(expected)
    end

    it 'formats full Polish date string' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 3, 14, 15, 9, 26)
        pokazl t.do_tekstu_pl()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip.gsub(/[\\"]/, '')).to eq("czwartek, 14 marca 2024, 15:09:26")
    end
  end

  # ── 10. Static helpers ──────────────────────────────────────

  describe 'static helper methods' do
    it 'returns current timestamp with stempel()' do
      code = '
        import("czas")
        niech ts = Czas.stempel()
        pokazl ts > 1700000000
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'returns precise timestamp with stempel_f()' do
      code = '
        import("czas")
        niech ts = Czas.stempel_f()
        pokazl ts > 1700000000
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'sleeps for specified time with uspij()' do
      code = '
        import("czas")
        niech start = Czas.stempel_f()
        Czas.uspij(0.05)
        niech koniec = Czas.stempel_f()
        pokazl koniec - start >= 0.04
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end
  end

  # ── 11. Decomposition ──────────────────────────────────────

  describe 'do_tablicy()' do
    it 'returns 10-element array with correct components' do
      code = '
        import("czas")
        niech t = Czas.utc(2024, 3, 14, 15, 9, 26)
        niech tab = t.do_tablicy()
        pokazl tab.dlg()
        pokazl tab[0]
        pokazl tab[1]
        pokazl tab[2]
        pokazl tab[3]
        pokazl tab[4]
        pokazl tab[5]
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("10\n26\n9\n15\n14\n3\n2024")
    end
  end

  # ── 12. Edge cases ──────────────────────────────────────────

  describe 'edge cases' do
    it 'handles year boundary (Dec 31 + 1 second)' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 12, 31, 23, 59, 59)
        niech t2 = t.dodaj(1)
        pokazl t2.rok()
        pokazl t2.miesiac()
        pokazl t2.dzien()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2025\n1\n1")
    end

    it 'handles leap year (Feb 29 + 1 day)' do
      code = '
        import("czas")
        niech t = Czas.nowy(2024, 2, 29, 12, 0, 0)
        pokazl t.dzien()
        pokazl t.miesiac()
        niech t2 = t.dodaj_dni(1)
        pokazl t2.dzien()
        pokazl t2.miesiac()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("29\n2\n1\n3")
    end

    it 'handles negative timestamps (before 1970)' do
      code = '
        import("czas")
        niech t = Czas.z_timestampu(-86400)
        pokazl t.rok()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1969")
    end

    it 'handles very large timestamps (year 2100)' do
      code = '
        import("czas")
        niech t = Czas.z_timestampu(4102444800)
        pokazl t.rok()
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2100")
    end
  end
end