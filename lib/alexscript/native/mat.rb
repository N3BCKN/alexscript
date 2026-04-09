# frozen_string_literal: true

# lib/alexscript/native/mat.rb
#
# Native binding for Ruby's Math module, exposed as AlexScript's Mat class.
# Purely static — Mat cannot be instantiated. All methods are class-level.
#
# Covers the full Ruby Math API:
#   - Trigonometric: sin, cos, tan, asin, acos, atan, atan2
#   - Hyperbolic: sinh, cosh, tanh, asinh, acosh, atanh
#   - Exponential/Logarithmic: exp, log, log2, log10, expm1, log1p
#   - Power/Root: sqrt, cbrt, hypot
#   - Error functions: erf, erfc
#   - Gamma: gamma, lgamma
#   - Low-level float: frexp, ldexp
#   - Rounding: floor, ceil, round, obetnij (truncate)
#   - Utility: abs, min, max, clamp, znak (sign), potega, silnia
#   - Random: losowa, losowa_zakres, losowa_calkowita
#
# Constants: PI, E, NIESKONCZONOSC, MINUS_NIESKONCZONOSC, NAN
#
# Performance: all methods are direct Ruby lambda calls — zero AST overhead.

module AlexScript
  module Native
    module MatLibrary

      def self.register
        Utils::NativeClassRegistry.define_class('Mat',
          constructor: ->(*) {
            raise "Mat jest klasą statyczną i nie może być instancjonowana"
          },
          methods: {},  # No instance methods — purely static
          static_methods: build_static_methods,
          static_vars: build_static_vars
        )
      end

      # ── Constants ──────────────────────────────────────────────

      def self.build_static_vars
        {
          'PI'                    => Math::PI,
          'E'                     => Math::E,
          'NIESKONCZONOSC'        => Float::INFINITY,
          'MINUS_NIESKONCZONOSC'  => -Float::INFINITY,
          'NAN'                   => Float::NAN
        }
      end

      # ── Static Methods ─────────────────────────────────────────

      def self.build_static_methods
        {
          # ─── Trigonometric ─────────────────────────────────
          'sin'   => ->(x) { Math.sin(x) },
          'cos'   => ->(x) { Math.cos(x) },
          'tan'   => ->(x) { Math.tan(x) },

          # ─── Inverse trigonometric ─────────────────────────
          'asin'  => ->(x) { Math.asin(x) },
          'acos'  => ->(x) { Math.acos(x) },
          'atan'  => ->(x) { Math.atan(x) },
          'atan2' => ->(y, x) { Math.atan2(y, x) },

          # ─── Hyperbolic ────────────────────────────────────
          'sinh'  => ->(x) { Math.sinh(x) },
          'cosh'  => ->(x) { Math.cosh(x) },
          'tanh'  => ->(x) { Math.tanh(x) },

          # ─── Inverse hyperbolic ────────────────────────────
          'asinh' => ->(x) { Math.asinh(x) },
          'acosh' => ->(x) { Math.acosh(x) },
          'atanh' => ->(x) { Math.atanh(x) },

          # ─── Exponential / Logarithmic ─────────────────────
          'exp'   => ->(x) { Math.exp(x) },
          'expm1' => ->(x) { Math.expm1(x) },   # e^x - 1 (precise for small x)

          'log'   => ->(x, *args) {
            args.empty? ? Math.log(x) : Math.log(x, args[0])
          },
          'log2'  => ->(x) { Math.log2(x) },
          'log10' => ->(x) { Math.log10(x) },
          'log1p' => ->(x) { Math.log1p(x) },   # log(1+x) (precise for small x)

          # ─── Power / Root ──────────────────────────────────
          'sqrt'       => ->(x) { Math.sqrt(x) },
          'cbrt'       => ->(x) { Math.cbrt(x) },
          'hipotenuza' => ->(x, y) { Math.hypot(x, y) },
          'potega'     => ->(x, y) { x ** y },

          # ─── Error functions ───────────────────────────────
          'erf'  => ->(x) { Math.erf(x) },
          'erfc' => ->(x) { Math.erfc(x) },

          # ─── Gamma ─────────────────────────────────────────
          'gamma'  => ->(x) { Math.gamma(x) },
          'lgamma' => ->(x) { Math.lgamma(x)[0] },  # returns only the log value

          # ─── Low-level float decomposition ─────────────────
          'frexp' => ->(x) {
            # Returns [fraction, exponent] where x = fraction * 2^exponent
            f, e = Math.frexp(x)
            [f, e]
          },
          'ldexp' => ->(f, e) { Math.ldexp(f, e) },

          # ─── Rounding ──────────────────────────────────────
          'podloga'  => ->(x) { x.floor },
          'sufit'    => ->(x) { x.ceil },
          'zaokraglij' => ->(x, *args) {
            args.empty? ? x.round : x.round(args[0])
          },
          'obetnij'  => ->(x) { x.truncate },

          # ─── Absolute / Sign ───────────────────────────────
          'abs'  => ->(x) { x.abs },
          'znak' => ->(x) {
            if x > 0 then 1
            elsif x < 0 then -1
            else 0
            end
          },

          # ─── Min / Max / Clamp ─────────────────────────────
          'min' => ->(x, y) { x < y ? x : y },
          'max' => ->(x, y) { x > y ? x : y },
          'ogranicz' => ->(x, dolna, gorna) {
            # clamp: returns x bounded to [dolna, gorna]
            x < dolna ? dolna : (x > gorna ? gorna : x)
          },

          # ─── Combinatorics ─────────────────────────────────
          'silnia' => ->(n) {
            raise "Silnia wymaga liczby nieujemnej" if n < 0
            result = 1
            i = 2
            while i <= n
              result *= i
              i += 1
            end
            result
          },

          # ─── Degree / Radian conversion ────────────────────
          'na_radiany' => ->(stopnie) { stopnie * Math::PI / 180.0 },
          'na_stopnie' => ->(radiany) { radiany * 180.0 / Math::PI },

          # ─── Random ────────────────────────────────────────
          'losowa' => ->() { rand },
          'losowa_zakres' => ->(od, do_val) { rand(od..do_val) },
          'losowa_calkowita' => ->(od, do_val) { rand(od..do_val) },

          # ─── Predicates ────────────────────────────────────
          'czy_nan'            => ->(x) { x.is_a?(Float) && x.nan? },
          'czy_nieskonczonosc' => ->(x) { x.is_a?(Float) && x.infinite? ? true : false },
          'czy_parzysta'       => ->(x) { x.to_i.even? },
          'czy_nieparzysta'    => ->(x) { x.to_i.odd? },

          # ─── Integer math ──────────────────────────────────
          'nwd' => ->(a, b) { a.gcd(b) },       # GCD
          'nww' => ->(a, b) { a.lcm(b) },       # LCM
          'reszta' => ->(a, b) { a % b },        # modulo (alias)
          'dzielenie_calkowite' => ->(a, b) {     # integer division
            raise "Dzielenie przez zero" if b == 0
            a / b
          }
        }
      end
    end
  end
end
