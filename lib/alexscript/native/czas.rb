# frozen_string_literal: true

# lib/alexscript/native/czas.rb
#
# Native binding for Ruby's Time class, exposed as AlexScript's Czas class.
# All methods are Ruby lambdas — no AST interpretation overhead.
#
# Covers the full Ruby Time API:
#   - Construction: teraz, nowy, z_timestampu, utc, lokalny, parsuj
#   - Getters: rok, miesiac, dzien, godzina, minuta, sekunda, ...
#   - Predicates: czy_poniedzialek, czy_utc, czy_czas_letni, ...
#   - Arithmetic: dodaj, odejmij, dodaj_minuty, dodaj_godziny, dodaj_dni, ...
#   - Comparison: porownaj, rowny, przed, po, roznica, miedzy
#   - Conversion: format, do_tekstu, do_utc, do_lokalnego, iso8601, ...
#   - Rounding: zaokraglij, sufit, podloga
#   - Polish: nazwa_dnia_tygodnia, nazwa_miesiaca, do_tekstu_pl

require 'time' # Required for Time.parse, Time.strptime, Time#iso8601, Time#rfc2822, Time#httpdate

module AlexScript
  module Native
    module CzasLibrary
      # ── Polish Name Constants (frozen, zero-alloc on lookup) ────

      NAZWY_DNI = [
        'niedziela'.freeze,
        'poniedziałek'.freeze,
        'wtorek'.freeze,
        'środa'.freeze,
        'czwartek'.freeze,
        'piątek'.freeze,
        'sobota'.freeze
      ].freeze

      NAZWY_DNI_SKROT = [
        'ndz'.freeze, 'pon'.freeze, 'wt'.freeze, 'śr'.freeze,
        'czw'.freeze, 'pt'.freeze, 'sob'.freeze
      ].freeze

      NAZWY_MIESIECY = [
        'styczeń'.freeze, 'luty'.freeze, 'marzec'.freeze,
        'kwiecień'.freeze, 'maj'.freeze, 'czerwiec'.freeze,
        'lipiec'.freeze, 'sierpień'.freeze, 'wrzesień'.freeze,
        'październik'.freeze, 'listopad'.freeze, 'grudzień'.freeze
      ].freeze

      NAZWY_MIESIECY_DOPELNIACZ = [
        'stycznia'.freeze, 'lutego'.freeze, 'marca'.freeze,
        'kwietnia'.freeze, 'maja'.freeze, 'czerwca'.freeze,
        'lipca'.freeze, 'sierpnia'.freeze, 'września'.freeze,
        'października'.freeze, 'listopada'.freeze, 'grudnia'.freeze
      ].freeze

      NAZWY_MIESIECY_SKROT = [
        'sty'.freeze, 'lut'.freeze, 'mar'.freeze, 'kwi'.freeze,
        'maj'.freeze, 'cze'.freeze, 'lip'.freeze, 'sie'.freeze,
        'wrz'.freeze, 'paź'.freeze, 'lis'.freeze, 'gru'.freeze
      ].freeze

      # ── Registration ───────────────────────────────────────────

      def self.register
        Utils::NativeClassRegistry.define_class('Czas',
          ruby_class: Time,
          constructor: method(:construct),
          methods: build_instance_methods,
          static_methods: build_static_methods,
          static_vars: {}
        )
      end

      # ── Constructor ────────────────────────────────────────────
      # Czas.nowy()                              → current time
      # Czas.nowy(2024)                          → 2024-01-01 00:00:00
      # Czas.nowy(2024, 6, 15)                   → 2024-06-15 00:00:00
      # Czas.nowy(2024, 6, 15, 14, 30, 45)       → 2024-06-15 14:30:45
      # Czas.nowy("2024-06-15 14:30:45")          → parsed from string

      def self.construct(rok = nil, miesiac = nil, dzien = nil,
                         godzina = nil, minuta = nil, sekunda = nil)
        if rok.nil?
          Time.now
        elsif rok.is_a?(String)
          Time.parse(rok)
        else
          Time.new(
            rok,
            miesiac || 1,
            dzien || 1,
            godzina || 0,
            minuta || 0,
            sekunda || 0
          )
        end
      end

      # ── Instance Methods ───────────────────────────────────────

      def self.build_instance_methods
        {
          # ─── Getters (date/time components) ─────────────────
          'rok'              => ->(t) { t.year },
          'miesiac'          => ->(t) { t.month },
          'dzien'            => ->(t) { t.day },
          'godzina'          => ->(t) { t.hour },
          'minuta'           => ->(t) { t.min },
          'sekunda'          => ->(t) { t.sec },
          'mikrosekunda'     => ->(t) { t.usec },
          'nanosekunda'      => ->(t) { t.nsec },
          'ulamek_sekundy'   => ->(t) { t.subsec.to_f },
          'dzien_tygodnia'   => ->(t) { t.wday },
          'dzien_roku'       => ->(t) { t.yday },
          'strefa'           => ->(t) { t.zone },
          'przesuniecie_utc' => ->(t) { t.utc_offset },

          # ─── Timestamps ────────────────────────────────────
          'timestamp'        => ->(t) { t.to_i },
          'timestamp_f'      => ->(t) { t.to_f },

          # ─── Day-of-week predicates ────────────────────────
          'czy_niedziela'    => ->(t) { t.sunday? },
          'czy_poniedzialek' => ->(t) { t.monday? },
          'czy_wtorek'       => ->(t) { t.tuesday? },
          'czy_sroda'        => ->(t) { t.wednesday? },
          'czy_czwartek'     => ->(t) { t.thursday? },
          'czy_piatek'       => ->(t) { t.friday? },
          'czy_sobota'       => ->(t) { t.saturday? },

          # ─── State predicates ──────────────────────────────
          'czy_utc'          => ->(t) { t.utc? },
          'czy_czas_letni'   => ->(t) { t.dst? },

          # ─── Arithmetic (returns new Czas via auto-wrapping) ─
          'dodaj'            => ->(t, sekundy) { t + sekundy },
          'odejmij'          => ->(t, arg) { t - arg },
          # ^ If arg is Time (from Czas instance), returns Float (seconds diff).
          #   If arg is Numeric, returns new Time (auto-wrapped to Czas).

          'dodaj_sekundy'    => ->(t, n) { t + n },
          'dodaj_minuty'     => ->(t, n) { t + (n * 60) },
          'dodaj_godziny'    => ->(t, n) { t + (n * 3600) },
          'dodaj_dni'        => ->(t, n) { t + (n * 86400) },
          'dodaj_tygodnie'   => ->(t, n) { t + (n * 604800) },

          'odejmij_sekundy'  => ->(t, n) { t - n },
          'odejmij_minuty'   => ->(t, n) { t - (n * 60) },
          'odejmij_godziny'  => ->(t, n) { t - (n * 3600) },
          'odejmij_dni'      => ->(t, n) { t - (n * 86400) },
          'odejmij_tygodnie' => ->(t, n) { t - (n * 604800) },

          # ─── Comparison ────────────────────────────────────
          'porownaj'  => ->(t, inny) { t <=> inny },
          'rowny'     => ->(t, inny) { t.eql?(inny) },
          'przed'     => ->(t, inny) { (t <=> inny) < 0 },
          'po'        => ->(t, inny) { (t <=> inny) > 0 },
          'roznica'   => ->(t, inny) { (t - inny).to_f },
          'miedzy'    => ->(t, od, do_czasu) {
            (t <=> od) >= 0 && (t <=> do_czasu) <= 0
          },

          # ─── Formatting / Conversion ───────────────────────
          'format'        => ->(t, fmt = '%Y-%m-%d %H:%M:%S') { t.strftime(fmt) },
          'do_tekstu'     => ->(t) { t.strftime('%Y-%m-%d %H:%M:%S %z') },
          'do_utc'        => ->(t) { t.getutc },
          'do_lokalnego'  => ->(t, *args) {
            args.empty? ? t.getlocal : t.getlocal(args[0])
          },
          'do_strefy'     => ->(t, przesuniecie) { t.getlocal(przesuniecie) },
          'ascii'         => ->(t) { t.asctime },

          # ─── Standard formats ──────────────────────────────
          'iso8601'       => ->(t, n = 0) { t.iso8601(n) },
          'rfc2822'       => ->(t) { t.rfc2822 },
          'httpdate'      => ->(t) { t.httpdate },

          # ─── Rounding ──────────────────────────────────────
          'zaokraglij'    => ->(t, n = 0) { t.round(n) },
          'sufit'         => ->(t, n = 0) { t.ceil(n) },
          'podloga'       => ->(t, n = 0) { t.floor(n) },

          # ─── Decomposition ─────────────────────────────────
          'do_tablicy'    => ->(t) {
            # Returns [sek, min, godz, dzien, mies, rok, dzien_tyg, dzien_roku, czas_letni, strefa]
            t.to_a
          },

          # ─── Polish locale names ───────────────────────────
          'nazwa_dnia_tygodnia' => ->(t) {
            NAZWY_DNI[t.wday]
          },

          'nazwa_dnia_skrot' => ->(t) {
            NAZWY_DNI_SKROT[t.wday]
          },

          'nazwa_miesiaca' => ->(t) {
            NAZWY_MIESIECY[t.month - 1]
          },

          'nazwa_miesiaca_dopelniacz' => ->(t) {
            NAZWY_MIESIECY_DOPELNIACZ[t.month - 1]
          },

          'nazwa_miesiaca_skrot' => ->(t) {
            NAZWY_MIESIECY_SKROT[t.month - 1]
          },

          'do_tekstu_pl' => ->(t) {
            dzien_tyg = NAZWY_DNI[t.wday]
            d         = t.day
            mies      = NAZWY_MIESIECY_DOPELNIACZ[t.month - 1]
            r         = t.year
            godz      = format('%02d', t.hour)
            min       = format('%02d', t.min)
            sek       = format('%02d', t.sec)
            "#{dzien_tyg}, #{d} #{mies} #{r}, #{godz}:#{min}:#{sek}"
          }
        }
      end

      # ── Static Methods ─────────────────────────────────────────

      def self.build_static_methods
        {
          # Current time
          'teraz' => ->() { Time.now },

          # From Unix timestamp
          # Czas.z_timestampu(1700000000)
          # Czas.z_timestampu(1700000000, 500000)  → with microseconds
          'z_timestampu' => ->(sekundy, *args) {
            if args.empty?
              Time.at(sekundy)
            elsif args.length == 1
              Time.at(sekundy, args[0])
            else
              Time.at(sekundy, args[0], args[1].to_sym)
            end
          },

          # UTC time
          # Czas.utc(2024, 6, 15, 14, 30, 45)
          'utc' => ->(rok, *args) { Time.utc(rok, *args) },

          # Local time
          # Czas.lokalny(2024, 6, 15, 14, 30, 45)
          'lokalny' => ->(rok, *args) { Time.local(rok, *args) },

          # Parse from string (heuristic)
          # Czas.parsuj("2024-06-15 14:30:45")
          'parsuj' => ->(tekst) { Time.parse(tekst.to_s) },

          # Parse with explicit format
          # Czas.parsuj_format("15/06/2024", "%d/%m/%Y")
          'parsuj_format' => ->(tekst, fmt) { Time.strptime(tekst.to_s, fmt.to_s) },

          # Parse standard formats
          'z_iso8601' => ->(tekst) { Time.iso8601(tekst.to_s) },
          'z_rfc2822' => ->(tekst) { Time.rfc2822(tekst.to_s) },
          'z_httpdate' => ->(tekst) { Time.httpdate(tekst.to_s) },

          # Sleep (blocks execution)
          # Czas.uspij(2)     → sleeps 2 seconds
          # Czas.uspij(0.5)   → sleeps 500ms
          'uspij' => ->(sekundy) {
            sleep(sekundy)
            true
          },

          # Stempel — returns current Unix timestamp as integer
          'stempel' => ->() { Time.now.to_i },

          # Stempel precyzyjny — returns current timestamp as float
          'stempel_f' => ->() { Time.now.to_f },

          # Mierz — measure execution time (returns seconds as float)
          # Usage in AS: niech czas_ms = Czas.mierz(...)  → not possible without blocks
          # Instead: niech start = Czas.stempel_f() ... niech czas = Czas.stempel_f() - start
        }
      end
    end
  end
end
