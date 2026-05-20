# frozen_string_literal: true

# lib/alexscript/native/wyrazenie.rb
#
# native binding for ruby ::Regexp + ::MatchData — exposed as
# alexscript Wyrazenie + Dopasowanie
#
# design notes:
#   * two native classes are registered: Wyrazenie (ruby_class: Regexp)
#     and Dopasowanie (ruby_class: MatchData). thanks to @ruby_class_map
#     Regexp/MatchData values returned from lambdas auto-wrap into
#     AS instances without manual code in every method
#   * flag string "imx" (i = ignore case, m = multiline — dot
#     matches \n, x = extended — whitespace/comments). parsed
#     via static FLAG_BITS table (zero allocations, O(1) lookup)
#   * availability: always (bootstrap in Environment), no import needed
#   * error messages include the word "argument" where it makes sense
#     — thanks to that Utils::Errors#determine_exception_class classifies
#     them as BladArgumentu after passing through rescue in oop.rb
#
# public api:
#   Wyrazenie.nowy(wzor, flagi = "")                (constructor)
#   Wyrazenie.escapuj(tekst)                        (static)
#
#   wzorzec.dopasuj(tekst)              → Dopasowanie | nic
#   wzorzec.dopasuj_wszystkie(tekst)    → [Dopasowanie]
#   wzorzec.pasuje(tekst)               → bool
#   wzorzec.zamien(tekst, zastapienie)  → string (first match)
#   wzorzec.zamien_wszystkie(t, z)      → string
#   wzorzec.podziel(tekst, limit = nic) → [string]
#   wzorzec.skanuj(tekst)               → [string] or [[string]]
#   wzorzec.wzor()                      → string
#   wzorzec.flagi()                     → string ("imx")
#   wzorzec.do_tekstu()                 → string ("/wzor/flagi")
#
#   dopasowanie.tekst()        → string (full match)
#   dopasowanie.przed()        → string (pre-match)
#   dopasowanie.po()           → string (post-match)
#   dopasowanie.grupa(n)       → string | nic
#   dopasowanie.grupy()        → [string | nic] (without group 0)
#   dopasowanie.nazwana(nazwa) → string | nic
#   dopasowanie.nazwane()      → { nazwa: string | nic }
#   dopasowanie.indeks()       → int
#   dopasowanie.indeks_konca() → int
#   dopasowanie.rozmiar()      → int (number of groups + 1)

module AlexScript
  module Native
    module WyrazenieLibrary
      module_function

      # single frozen flag bits table — zero allocations during parsing,
      # O(1) lookup per char
      FLAG_BITS = {
        'i' => Regexp::IGNORECASE,
        'm' => Regexp::MULTILINE,
        'x' => Regexp::EXTENDED
      }.freeze

      # "imx" → Regexp::IGNORECASE | MULTILINE | EXTENDED
      # unknown char → BladArgumentu
      def parse_flags(flags_str)
        return 0 if flags_str.nil?
        s = flags_str.to_s
        return 0 if s.empty?

        bits = 0
        s.each_char do |ch|
          bit = FLAG_BITS[ch]
          unless bit
            raise Utils::AlexScriptError.new(
              'BladArgumentu',
              "Nieprawidlowy argument 'flagi': nieznana flaga '#{ch}'. Dozwolone: i, m, x"
            )
          end
          bits |= bit
        end
        bits
      end

      # reverse operation: int → "imx". reads only known bits
      def flags_to_string(options)
        s = String.new
        s << 'i' if (options & Regexp::IGNORECASE) != 0
        s << 'm' if (options & Regexp::MULTILINE)  != 0
        s << 'x' if (options & Regexp::EXTENDED)   != 0
        s
      end

      # Invoke an AS function value with a MatchData, return its result as
      # a Ruby String suitable for sub/gsub replacement. Any return type
      # is coerced via the interpreter's formatter — matching how "" + x
      # behaves in AS for non-string values.
      def invoke_callback(fn_value, match_data)
        interpreter = Fiber[:alex_interpreter]
        unless interpreter
          raise Utils::AlexScriptError.new(
            'BladWykonania',
            'Callback w zamien wymaga aktywnego interpretera'
          )
        end

        _, match_instance = Utils::NativeClassRegistry.wrap_native_object('Dopasowanie', match_data)
        arg_tuple = [:type_instance, match_instance]
        result_type, result_value = call_as_function(interpreter, fn_value, [arg_tuple])
        interpreter.stringify_for_interpolation(result_type, result_value)
      end

      # Minimal AS-function invocation: bind params, run body, capture
      # ReturnError. Avoids synthesizing a LambdaCall AST node (zero
      # throwaway AST allocations per match).
      def call_as_function(interpreter, fn_value, arg_tuples)
        func_declr = fn_value[:declaration]
        func_env   = fn_value[:env]

        params = func_declr.params
        rest_param = params.find(&:rest?)
        min_args = params.count { |p| !p.has_default? && !p.rest? }

        if arg_tuples.size < min_args
          raise Utils::AlexScriptError.new(
            'BladArgumentu',
            "Callback oczekiwal minimum #{min_args} argumentow, otrzymal #{arg_tuples.size}"
          )
        end

        unless rest_param
          if arg_tuples.size > params.size
            raise Utils::AlexScriptError.new(
              'BladArgumentu',
              "Callback oczekiwal maksymalnie #{params.size} argumentow, otrzymal #{arg_tuples.size}"
            )
          end
        end

        call_env = func_env.new_env
        rest_idx = params.index(&:rest?)
        normal_params = rest_param ? params.reject(&:rest?) : params

        normal_params.each_with_index do |param, idx|
          if idx < arg_tuples.size && (rest_idx.nil? || idx < rest_idx)
            call_env.set_local_var(param.name, arg_tuples[idx][1], arg_tuples[idx][0])
          elsif param.has_default?
            default_tuple = interpreter.interpret!(param.default_value, func_env)
            call_env.set_local_var(param.name, default_tuple[1], default_tuple[0])
          else
            raise Utils::AlexScriptError.new('BladArgumentu', "Brakujacy argument #{param.name}")
          end
        end

        if rest_param
          rest_position = rest_idx || params.size
          rest_args = arg_tuples[rest_position..-1] || []
          rest_elements = rest_args.map { |a| { type: a[0], value: a[1] } }
          call_env.set_local_var(rest_param.name, rest_elements, :type_array)
        end

        catch(:alex_return) do
          if func_declr.implicit_return?
            interpreter.interpret!(func_declr.body_statement.stmts[0].expression, call_env)
          else
            interpreter.interpret!(func_declr.body_statement, call_env)
            [:type_null, Utils::NULL_VALUE]
          end
        end
      end

      def register!
        register_wyrazenie!
        register_dopasowanie!
      end
      

      #  Wyrazenie 

      def register_wyrazenie!
        Utils::NativeClassRegistry.define_class(
          'Wyrazenie',
          ruby_class: Regexp,

          # Wyrazenie.nowy("wzor")
          # Wyrazenie.nowy("wzor", "i")
          # Wyrazenie.nowy("wzor", "imx")
          constructor: ->(wzor = nil, flagi = nil) {
            if wzor.nil?
              raise Utils::AlexScriptError.new(
                'BladArgumentu',
                'Wyrazenie.nowy oczekuje 1 lub 2 argumentow (wzor[, flagi])'
              )
            end

            begin
              Regexp.new(wzor.to_s, WyrazenieLibrary.parse_flags(flagi))
            rescue RegexpError => e
              raise Utils::AlexScriptError.new(
                'BladArgumentu',
                "Nieprawidlowy argument 'wzor' (wyrazenie regularne): #{e.message}"
              )
            end
          },

          methods: {
            # single match. nil (=> nic) when no match — auto conversion
            # MatchData → Dopasowanie via @ruby_class_map
            'dopasuj' => ->(re, tekst) { re.match(tekst.to_s) },

            # all matches as [Dopasowanie]. using scan with
            # block + Regexp.last_match — the only way to get full
            # MatchData (scan normally returns strings or group arrays)
            # each element must be wrapped manually — NativeTypeConverter
            # for array elements does not use ruby_class_map
            'dopasuj_wszystkie' => ->(re, tekst) {
              matches = []
              tekst.to_s.scan(re) { matches << Regexp.last_match }
              elements = matches.map do |m|
                _, inst = Utils::NativeClassRegistry.wrap_native_object('Dopasowanie', m)
                { type: :type_instance, value: inst }
              end
              [:type_array, elements]
            },

            # predicate. using =~ instead of match? — match? is faster,
            # but =~ works everywhere; difference negligible here
            'pasuje' => ->(re, tekst) { !!(re =~ tekst.to_s) },

            # replace first occurrence with replacement string
            # callback (fn) reserved for stage 2
            'zamien' => ->(re, tekst, zastapienie) {
              if zastapienie.is_a?(Hash) && zastapienie[:declaration]
                tekst.to_s.sub(re) { WyrazenieLibrary.invoke_callback(zastapienie, Regexp.last_match) }
              else
                tekst.to_s.sub(re, zastapienie.to_s)
              end
            },

            'zamien_wszystkie' => ->(re, tekst, zastapienie) {
              if zastapienie.is_a?(Hash) && zastapienie[:declaration]
                tekst.to_s.gsub(re) { WyrazenieLibrary.invoke_callback(zastapienie, Regexp.last_match) }
              else
                tekst.to_s.gsub(re, zastapienie.to_s)
              end
            },

            # split. no limit → default ruby behavior (drops trailing empties)
            # explicit limit → passed to split
            'podziel' => ->(re, tekst, limit = nil) {
              if limit.nil?
                tekst.to_s.split(re)
              else
                tekst.to_s.split(re, limit.to_i)
              end
            },

            # scan — [string] when no groups, [[string]] when groups exist
            'skanuj' => ->(re, tekst) { tekst.to_s.scan(re) },

            # introspection
            'wzor'      => ->(re) { re.source },
            'flagi'     => ->(re) { WyrazenieLibrary.flags_to_string(re.options) },
            'do_tekstu' => ->(re) {
              "/#{re.source}/#{WyrazenieLibrary.flags_to_string(re.options)}"
            }
          },

          static_methods: {
            # returns string with regex metacharacters escaped
            # Wyrazenie.escapuj("1+2*3") → "1\\+2\\*3"
            'escapuj' => ->(tekst) { Regexp.escape(tekst.to_s) }
          },

          static_vars: {}
        )
      end

      #  Dopasowanie 

      def register_dopasowanie!
        Utils::NativeClassRegistry.define_class(
          'Dopasowanie',
          ruby_class: MatchData,

          # Dopasowanie comes from .dopasuj()/.dopasuj_wszystkie()
          # manual creation makes no sense — MatchData only exists
          # from running Regexp on a string
          constructor: ->(*) {
            raise Utils::AlexScriptError.new(
              'BladWykonania',
              'Dopasowanie nie jest tworzone recznie — uzyj Wyrazenie.dopasuj()'
            )
          },

          methods: {
            # full matched text (== group 0)
            'tekst' => ->(m) { m[0] },

            # text before and after match
            'przed' => ->(m) { m.pre_match },
            'po'    => ->(m) { m.post_match },

            # index access: 0 = full match, 1..n = groups
            # Ruby MatchData#[] returns nil for out-of-range and
            # unmatched optional groups — maps to nic
            'grupa' => ->(m, idx) { m[idx.to_i] },

            # all groups (without group 0). nil → nic
            'grupy' => ->(m) { m.captures },

            # named group. missing name → nic (not an exception)
            'nazwana' => ->(m, nazwa) {
              name = nazwa.to_s
              return nil unless m.names.include?(name)
              m[name]
            },

            # hash of named groups. unmatched → nil → nic
            'nazwane' => ->(m) { m.named_captures },

            # positions in original string
            'indeks'       => ->(m) { m.begin(0) },
            'indeks_konca' => ->(m) { m.end(0) },

            # number of elements (1 + number of groups — like Ruby MatchData#size)
            'rozmiar' => ->(m) { m.size }
          },

          static_methods: {},
          static_vars: {}
        )
      end
    end
  end
end