require 'aruba/rspec'

RSpec.describe 'Mat native library', type: :aruba do
  let(:main_file_path) { File.expand_path('../../../lib/alexscript.rb', File.dirname(__FILE__)) }

  # ── 1. Constants ────────────────────────────────────────────

  describe 'constants' do
    it 'exposes PI' do
      code = '
        import("mat")
        pokazl Mat.PI > 3.14
        pokazl Mat.PI < 3.15
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'exposes E' do
      code = '
        import("mat")
        pokazl Mat.E > 2.71
        pokazl Mat.E < 2.72
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'exposes NIESKONCZONOSC and MINUS_NIESKONCZONOSC' do
      code = '
        import("mat")
        pokazl Mat.NIESKONCZONOSC > 999999999
        pokazl Mat.MINUS_NIESKONCZONOSC < -999999999
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'exposes NAN' do
      code = '
        import("mat")
        pokazl Mat.czy_nan(Mat.NAN)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end
  end

  # ── 2. Trigonometry ─────────────────────────────────────────

  describe 'trigonometry' do
    it 'computes sin' do
      code = '
        import("mat")
        niech wynik = Mat.sin(0)
        pokazl wynik == 0.0
        pokazl Mat.sin(Mat.PI / 2) > 0.999
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'computes cos' do
      code = '
        import("mat")
        pokazl Mat.cos(0) == 1.0
        pokazl Mat.cos(Mat.PI) < -0.999
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'computes tan' do
      code = '
        import("mat")
        pokazl Mat.tan(0) == 0.0
        niech t = Mat.tan(Mat.PI / 4)
        pokazl t > 0.999
        pokazl t < 1.001
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end

    it 'computes inverse trig functions' do
      code = '
        import("mat")
        niech a = Mat.asin(1)
        niech b = Mat.acos(1)
        niech c = Mat.atan(1)
        pokazl a > 1.57
        pokazl a < 1.58
        pokazl b == 0.0
        pokazl c > 0.785
        pokazl c < 0.786
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda\nprawda\nprawda")
    end

    it 'computes atan2' do
      code = '
        import("mat")
        niech a = Mat.atan2(1, 1)
        pokazl a > 0.785
        pokazl a < 0.786
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end
  end

  # ── 3. Hyperbolic ───────────────────────────────────────────

  describe 'hyperbolic functions' do
    it 'computes sinh, cosh, tanh at zero' do
      code = '
        import("mat")
        pokazl Mat.sinh(0) == 0.0
        pokazl Mat.cosh(0) == 1.0
        pokazl Mat.tanh(0) == 0.0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end

    it 'computes inverse hyperbolic' do
      code = '
        import("mat")
        pokazl Mat.asinh(0) == 0.0
        pokazl Mat.acosh(1) == 0.0
        pokazl Mat.atanh(0) == 0.0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end
  end

  # ── 4. Exponential / Logarithmic ────────────────────────────

  describe 'exponential and logarithmic' do
    it 'computes exp' do
      code = '
        import("mat")
        pokazl Mat.exp(0) == 1.0
        niech e = Mat.exp(1)
        pokazl e > 2.718
        pokazl e < 2.719
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end

    it 'computes log with default and custom base' do
      code = '
        import("mat")
        pokazl Mat.log(1) == 0.0
        niech l = Mat.log(8, 2)
        pokazl l > 2.999
        pokazl l < 3.001
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda")
    end

    it 'computes log2, log10' do
      code = '
        import("mat")
        pokazl Mat.log2(8) == 3.0
        pokazl Mat.log10(1000) == 3.0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    # it 'computes expm1 and log1p (precision for small values)' do
    #   code = '
    #     import("mat")
    #     pokazl Mat.expm1(0) == 0.0
    #     pokazl Mat.log1p(0) == 0.0
    #   '
    #   run_command_and_stop "ruby #{main_file_path} '#{code}'"
    #   expect(last_command_started.output.strip).to eq("prawda\nprawda")
    # end
  end

  # ── 5. Power / Root ─────────────────────────────────────────

  describe 'power and root' do
    it 'computes sqrt' do
      code = '
        import("mat")
        pokazl Mat.sqrt(4) == 2.0
        pokazl Mat.sqrt(9) == 3.0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'computes cbrt' do
      code = '
        import("mat")
        pokazl Mat.cbrt(27) == 3.0
        pokazl Mat.cbrt(8) == 2.0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'computes hipotenuza' do
      code = '
        import("mat")
        pokazl Mat.hipotenuza(3, 4) == 5.0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end

    it 'computes potega' do
      code = '
        import("mat")
        pokazl Mat.potega(2, 10)
        pokazl Mat.potega(3, 3)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1024\n27")
    end
  end

  # ── 6. Error and Gamma ──────────────────────────────────────

  describe 'error and gamma functions' do
    it 'computes erf and erfc' do
      code = '
        import("mat")
        pokazl Mat.erf(0) == 0.0
        pokazl Mat.erfc(0) == 1.0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'computes gamma (4! = 24)' do
      code = '
        import("mat")
        pokazl Mat.gamma(5) == 24.0
        pokazl Mat.gamma(1) == 1.0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'computes lgamma' do
      code = '
        import("mat")
        pokazl Mat.lgamma(1) == 0.0
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda")
    end
  end

  # ── 7. Rounding ─────────────────────────────────────────────

  describe 'rounding' do
    it 'floors values' do
      code = '
        import("mat")
        pokazl Mat.podloga(3.7)
        pokazl Mat.podloga(-3.2)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("3\n-4")
    end

    it 'ceils values' do
      code = '
        import("mat")
        pokazl Mat.sufit(3.2)
        pokazl Mat.sufit(-3.7)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("4\n-3")
    end

    it 'rounds values' do
      code = '
        import("mat")
        pokazl Mat.zaokraglij(3.5)
        pokazl Mat.zaokraglij(3.14159, 2)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("4\n3.14")
    end

    it 'truncates values' do
      code = '
        import("mat")
        pokazl Mat.obetnij(3.9)
        pokazl Mat.obetnij(-3.9)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("3\n-3")
    end
  end

  # ── 8. Abs / Sign ──────────────────────────────────────────

  describe 'abs and znak' do
    it 'computes abs' do
      code = '
        import("mat")
        pokazl Mat.abs(5)
        pokazl Mat.abs(-5)
        pokazl Mat.abs(0)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("5\n5\n0")
    end

    it 'computes znak (sign)' do
      code = '
        import("mat")
        pokazl Mat.znak(42)
        pokazl Mat.znak(-7)
        pokazl Mat.znak(0)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n-1\n0")
    end
  end

  # ── 9. Min / Max / Clamp ────────────────────────────────────

  describe 'min, max, ogranicz' do
    it 'computes min and max' do
      code = '
        import("mat")
        pokazl Mat.min(3, 7)
        pokazl Mat.max(3, 7)
        pokazl Mat.min(-1, 1)
        pokazl Mat.max(-1, 1)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("3\n7\n-1\n1")
    end

    it 'clamps values with ogranicz' do
      code = '
        import("mat")
        pokazl Mat.ogranicz(5, 0, 10)
        pokazl Mat.ogranicz(-5, 0, 10)
        pokazl Mat.ogranicz(15, 0, 10)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("5\n0\n10")
    end
  end

  # ── 10. Silnia ──────────────────────────────────────────────

  describe 'silnia (factorial)' do
    it 'computes factorials' do
      code = '
        import("mat")
        pokazl Mat.silnia(0)
        pokazl Mat.silnia(1)
        pokazl Mat.silnia(5)
        pokazl Mat.silnia(10)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n1\n120\n3628800")
    end
  end

  # ── 11. Degree / Radian conversion ─────────────────────────

  describe 'degree/radian conversion' do
    it 'converts degrees to radians and back' do
      code = '
        import("mat")
        niech r = Mat.na_radiany(180)
        niech s = Mat.na_stopnie(Mat.PI)
        pokazl r > 3.14
        pokazl r < 3.15
        pokazl s > 179.99
        pokazl s < 180.01
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda\nprawda\nprawda")
    end

    it 'does round-trip conversion' do
      code = '
        import("mat")
        niech wynik = Mat.na_stopnie(Mat.na_radiany(45))
        pokazl wynik > 44.99
        pokazl wynik < 45.01
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end
  end

  # ── 12. Random ──────────────────────────────────────────────

  describe 'random' do
    it 'generates random float in [0, 1)' do
      code = '
        import("mat")
        niech r = Mat.losowa()
        pokazl r >= 0
        pokazl r < 1
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end

    it 'generates random in range' do
      code = '
        import("mat")
        niech r = Mat.losowa_zakres(10, 20)
        pokazl r >= 10
        pokazl r <= 20
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nprawda")
    end
  end

  # ── 13. Predicates ─────────────────────────────────────────

  describe 'predicates' do
    it 'detects NaN and infinity' do
      code = '
        import("mat")
        pokazl Mat.czy_nan(Mat.NAN)
        pokazl Mat.czy_nan(1.0)
        pokazl Mat.czy_nieskonczonosc(Mat.NIESKONCZONOSC)
        pokazl Mat.czy_nieskonczonosc(1.0)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nfalsz\nprawda\nfalsz")
    end

    it 'checks parity' do
      code = '
        import("mat")
        pokazl Mat.czy_parzysta(4)
        pokazl Mat.czy_parzysta(7)
        pokazl Mat.czy_nieparzysta(7)
        pokazl Mat.czy_nieparzysta(4)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("prawda\nfalsz\nprawda\nfalsz")
    end
  end

  # ── 14. NWD / NWW / Integer math ────────────────────────────

  describe 'integer math' do
    it 'computes GCD and LCM' do
      code = '
        import("mat")
        pokazl Mat.nwd(12, 8)
        pokazl Mat.nwd(17, 5)
        pokazl Mat.nww(4, 6)
        pokazl Mat.nww(3, 7)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("4\n1\n12\n21")
    end

    it 'computes modulo and integer division' do
      code = '
        import("mat")
        pokazl Mat.reszta(10, 3)
        pokazl Mat.dzielenie_calkowite(10, 3)
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("1\n3")
    end
  end

  # ── 15. frexp / ldexp ───────────────────────────────────────

  describe 'frexp and ldexp' do
    it 'decomposes and recomposes floats' do
      code = '
        import("mat")
        niech fr = Mat.frexp(1024.0)
        pokazl fr.dlg()
        niech odtworzone = Mat.ldexp(fr[0], fr[1])
        pokazl odtworzone
      '
      run_command_and_stop "ruby #{main_file_path} '#{code}'"
      expect(last_command_started.output.strip).to eq("2\n1024.0")
    end
  end

  # ── 16. Cannot instantiate ──────────────────────────────────

  describe 'instantiation prevention' do
    it 'raises error when trying to instantiate Mat' do
      code = '
        import("mat")
        niech m = Mat.nowy()
      '
      run_command "ruby #{main_file_path} '#{code}'"
      expect(last_command_started).to have_output(/Mat jest klasą statyczną/)
      expect(last_command_started).to have_exit_status(1)
    end
  end
end
