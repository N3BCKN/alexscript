# AlexScript

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Homebrew](https://img.shields.io/badge/homebrew-N3BCKN%2Falexscript-orange)](https://github.com/N3BCKN/homebrew-alexscript)
[![Docker](https://img.shields.io/badge/docker-alexscript%2Falexscript-blue)](https://hub.docker.com/r/alexscript/alexscript)
[![Try it online](https://img.shields.io/badge/try%20it-online-green)](https://alexscript.pl/try)

**AlexScript** is a general-purpose, dynamically typed, interpreted programming language with **Polish-language syntax**. It ships with a complete object-oriented system, modules with mixins, exception handling, cooperative async/await, an interactive REPL, a built-in debugger, and a focused standard library covering files, networking, JSON, CSV, cryptography, and more.

```ruby
klasa Osoba {
    funkcja konstruktor(imie, wiek) {
        niech @imie = imie
        niech @wiek = wiek
    }

    funkcja przedstaw_sie() {
        pokazl "Cześć, jestem #{@imie} i mam #{@wiek} lat."
    }
}

niech anna = Osoba.nowy("Anna", 30)
anna.przedstaw_sie()    # Cześć, jestem Anna i mam 30 lat.
```

If you've used Ruby, Python, or JavaScript, the semantics will feel immediately familiar, only vocabulary changes. `klasa` is `class`, `funkcja` is `function`, `niech` is `let`, `jesli` is `if`. Full list list of keyword is small enough to learn in an afternoon, and the language design favors the same patterns you already know.

---

## Table of contents

- [Why a Polish-syntax language?](#why-a-polish-syntax-language)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Language tour](#language-tour)
- [Standard library](#standard-library)
- [Real-world projects](#real-world-projects)
- [Documentation](#documentation)
- [Try it in the browser](#try-it-in-the-browser)
- [Project status & roadmap](#project-status--roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Why a Polish-syntax language?

Most programming languages are built around English keywords. For native English speakers this is invisible — for everyone else, it's a small but persistent cognitive tax, especially when learning to program. AlexScript is an experiment in lowering that tax for Polish speakers without compromising on language design: the syntax is Polish, but the underlying model (classes, modules, closures, exceptions, async) is mainstream and battle-tested.

AlexScript is also a real, full-featured implementation — not a syntactic novelty. It has been used to build a working HTTP framework, an HTTP client library, and even a BASIC interpreter written in AlexScript itself. See [Real-world projects](#real-world-projects) below.

---

## Installation

### Homebrew (macOS / Linux)

```bash
brew tap N3BCKN/alexscript
brew install alexscript
```

Verify the installation:

```bash
alexscript --version
```

### Docker

```bash
docker run -it --rm alexscript/alexscript:latest
```

The image is published on [Docker Hub](https://hub.docker.com/r/alexscript/alexscript) and drops you straight into the interactive REPL.

### From source

AlexScript requires **Ruby 4.0.3 or later**. Clone the repository, install dependencies, and run the interpreter directly:

```bash
git clone https://github.com/N3BCKN/alexscript.git
cd alexscript
bundle install
ruby lib/alexscript.rb
```

### Editor support

A [Visual Studio Code extension](https://marketplace.visualstudio.com/items?itemName=N3BCKN.alexscript) provides syntax highlighting, snippets, and a custom dark theme tuned for AlexScript code. Search for **AlexScript** in the VS Code marketplace, or install from the command line:

```bash
code --install-extension N3BCKN.alexscript
```

---

## Quick start

Save the following as `hello.as`:

```ruby
funkcja powitaj(imie) {
    pokazl "Witaj, #{imie}!"
}

powitaj("Świat")
```

Run it:

```bash
alexscript hello.as
```

Or evaluate a one-liner directly from the shell:

```bash
alexscript 'pokazl "Hello from AlexScript"'
```

Launch the REPL with no arguments:

```bash
alexscript
```

The REPL evaluates expressions immediately, prints results, and binds the previous result to `_` for chained experimentation:

```text
> niech x = 10
> niech y = 20
> x + y
=> 30
> _ * 2
=> 60
```

---

## Language tour

A quick walkthrough of the most important constructs. For the full guide, see the [tutorial](https://alexscript.pl/docs).

### Variables and types

```ruby
niech imie = "Anna"          # napis (string)
niech wiek = 30              # calkowita (integer)
niech wzrost = 1.72          # zmiennoprzecinkowa (float)
niech aktywna = prawda       # logiczna (boolean — prawda/falsz)
niech adres = nic            # nic (null)
niech tagi = ["pl", "ruby"]  # tablica (array)
niech profil = {             # obiekt (object/hash)
    "miasto": "Warszawa",
    "kraj": "PL"
}
```

Variables are declared with `niech`. Constants are written in `UPPER_CASE` and cannot be reassigned. The language is dynamically typed but strongly typed at runtime — `"abc" - 5` raises `BladTypu`, not silent coercion.

### Control flow

```ruby
jesli wiek >= 18 {
    pokazl "dorosly"
} albojesli wiek >= 13 {
    pokazl "nastolatek"
} albo {
    pokazl "dziecko"
}

# Inline form for short branches:
jesli x > 100 to pokazl "duzo"

# C-style numeric for loop:
dla niech k = 0; 10; 1 {
    pokazl k
}

# For-each over collections:
dla owoc w ["jablko", "gruszka", "sliwka"] {
    pokazl owoc
}

# Two-variable form for objects:
dla klucz, wartosc w profil {
    pokazl "#{klucz} => #{wartosc}"
}
```

### Functions and closures

Functions are first-class values. Anonymous functions use `fn`, and closures capture their lexical environment.

```ruby
funkcja kwadrat(x) {
    zwroc x * x
}

# Default and rest parameters:
funkcja powitaj(imie, formalna = falsz) {
    jesli formalna to zwroc "Dzień dobry, #{imie}"
    zwroc "Cześć, #{imie}"
}

funkcja suma(*liczby) {
    niech wynik = 0
    dla n w liczby { wynik = wynik + n }
    zwroc wynik
}

# Closure over enclosing scope:
funkcja licznik() {
    niech n = 0
    zwroc fn() {
        n = n + 1
        zwroc n
    }
}

niech c = licznik()
pokazl c()    # 1
pokazl c()    # 2
pokazl c()    # 3
```

### Higher-order array methods

Arrays come with the standard functional toolkit. Methods chain naturally:

```ruby
niech liczby = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

niech wynik = liczby
    .filtruj(fn(x) { x % 2 == 0 })
    .mapuj(fn(x) { x * x })
    .redukuj(fn(acc, x) { acc + x }, 0)

pokazl wynik    # 220   (4 + 16 + 36 + 64 + 100)
```

The full set: `mapuj`, `filtruj`, `redukuj`, `kazdy`, `znajdz`, `dowolny`, `wszystkie`, `sortuj`. Numeric arrays additionally respond to `suma`, `srednia`, `min`, `max`.

### Object-oriented programming

Classes support single inheritance, abstract classes, static methods, private methods, and reflection. The `super` call works through inheritance chains of any depth.

```ruby
klasa Zwierze {
    funkcja konstruktor(nazwa) {
        niech @nazwa = nazwa
    }

    funkcja odglos() {
        zwroc "..."
    }

    funkcja przedstaw() {
        zwroc "Jestem #{@nazwa} i robie #{sam.odglos()}"
    }
}

klasa Pies < Zwierze {
    funkcja odglos() {
        zwroc "Hau hau!"
    }
}

niech p = Pies.nowy("Burek")
pokazl p.przedstaw()    # Jestem Burek i robie Hau hau!
```

Method chains using `zwroc sam` give you the Builder pattern out of the box:

```ruby
niech wynik = Builder.nowy()
    .ustaw_x(10)
    .ustaw_y(20)
    .zbuduj()
```

### Modules and mixins

Modules group related code under a namespace and can be mixed into classes with `dolacz`. They also support reopening, so a single module can be split across multiple files.

```ruby
modul Identyfikator {
    funkcja id_string() {
        zwroc "ID:#{@id}"
    }
}

klasa Uzytkownik {
    dolacz Identyfikator

    funkcja konstruktor(id, imie) {
        niech @id = id
        niech @imie = imie
    }
}

pokazl Uzytkownik.nowy(42, "Anna").id_string()    # ID:42
```

### Exceptions

Built-in exception classes form a hierarchy under `WyjatekPodstawowy`. Catching is type-aware via `zlap (e : TypBledu)`, and `wkoncu` provides guaranteed cleanup.

```ruby
proba {
    niech wynik = ryzykowna_operacja()
} zlap (e : BladSieci) {
    pokazl "Network failure: #{e["wiadomosc"]}"
} zlap (e) {
    pokazl "Other error: #{e["wiadomosc"]}"
} wkoncu {
    posprzataj()
}
```

### Async / await

AlexScript ships with cooperative concurrency built on Ruby fibers and a Fiber Scheduler. The `czekaj` keyword suspends an async function until a promise settles; `uruchom_rownolegle` runs tasks concurrently. Native I/O (sleep, sockets, file reads) integrates with the scheduler — what looks like blocking code cooperatively yields instead.

```ruby
asynchroniczna funkcja pobierz(id) {
    czekaj uspij(100)
    zwroc "data #{id}"
}

asynchroniczna funkcja main() {
    niech a = uruchom_rownolegle(fn() { czekaj pobierz(1) })
    niech b = uruchom_rownolegle(fn() { czekaj pobierz(2) })
    niech c = uruchom_rownolegle(fn() { czekaj pobierz(3) })

    # All three run in parallel — total ~100ms, not 300ms.
    pokazl czekaj a
    pokazl czekaj b
    pokazl czekaj c
}

uruchom(main)
```

The full Promise API is available — `Obietnica.wszystkie`, `Obietnica.dowolna`, `Obietnica.limit_czasu` — and the executor pattern (`Obietnica.nowy(fn(spelnij, odrzuc) { ... })`) lets you wrap callback-based APIs.

### Built-in debugger

Drop `debug()` anywhere in your code to enter an interactive byebug-style debugger:

```ruby
niech x = 10
debug()           # pause here
niech y = oblicz(x)
```

You get conditional breakpoints (`ustaw 15 jesli k > 100`), watchpoints (`sledz x`), logpoints (`loguj 15 x`), full scope inspection, and live variable modification. No CLI flag, no setup — the debugger is always there.

---

## Standard library

Each library is loaded with `import("name")` (no path prefix, no `.as` extension):

| Library | Purpose |
|---|---|
| **Mat** | Math constants and functions: trigonometry, logs, roots, factorials, GCD/LCM, random numbers |
| **Czas** | Dates, times, timestamps, formatting, time arithmetic, Polish locale names |
| **Plik** | File I/O, directory listing, path manipulation, file metadata |
| **Json** | JSON parsing, generation, file round-tripping, validation |
| **Csv** | CSV parsing and generation, with optional header support |
| **Socket** | TCP/UDP networking — `SocketTcp`, `SerwerTcp`, `SocketUdp`, plus DNS helpers |
| **Http** | High-level HTTP client with TLS, redirects, JSON helpers, URL utilities |
| **Digest** | Cryptographic hashes (MD5, SHA1/256/384/512), HMAC, constant-time compare |
| **SecureRandom** | Cryptographically secure tokens, UUIDs, hex strings, random bytes |

Example — fetch a JSON endpoint and write filtered results to a file:

```ruby
import("http")
import("json")
import("plik")

niech odp = Http.get_json("https://api.example.com/users")
niech dorosli = odp.filtruj(fn(u) { u["wiek"] >= 18 })
Json.generuj_plik("./dorosli.json", dorosli, prawda)

pokazl "Zapisano #{dorosli.dlg()} rekordów."
```

---

## Real-world projects

The clearest signal that AlexScript is more than a toy: people have built non-trivial software with it.

### [Zubr](https://github.com/N3BCKN/zubr) — web framework

A minimalist HTTP framework written in pure AlexScript. Includes a router, middleware stack, request/response abstractions, and a connection handler — all in idiomatic AlexScript code. Demonstrates that the language scales to real systems work.

```ruby
import("zubr")

niech app = Zubr::App.nowy()

app.get("/", fn(zad, odp) {
    odp.tekst("Witaj w Żubrze!")
})

app.uruchom(8080)
```

### [Posel](https://github.com/N3BCKN/posel) — HTTP client

A higher-level HTTP client library on top of the standard `Http` module. Adds a fluent builder API, automatic retries, and structured error handling.

### [asbasic](https://github.com/N3BCKN/asbasic) — BASIC interpreter

A working BASIC interpreter implemented in AlexScript. Includes a lexer, parser, AST evaluator, and runtime — proof that AlexScript is expressive enough to host another language.

For more sample programs (sorting algorithms, design patterns, data-structure exercises), see the [examples directory](https://github.com/N3BCKN/alexscript/tree/master/examples).

---

## Documentation

Full documentation is available at [**alexscript.pl/docs**](https://alexscript.pl/docs):

- **Tutorial** — guided walkthrough from "Hello World" to async, with each section building on the previous one
- **Standard library reference** — every method, every argument, every return type, all verified against the source
- **Project guides** — deep dives into Zubr, Posel, and the BASIC interpreter

---

## Try it in the browser

You can run AlexScript without installing anything: [**alexscript.pl/try**](https://alexscript.pl/try) is a fully-functional in-browser interpreter. Paste any of the examples from this README and they will run as-is.

---

## Project status & roadmap

AlexScript is **production-ready for hobby and educational use**. The language specification is stable, the standard library is comprehensive, and the test suite is extensive. It's not yet recommended for high-throughput production workloads — the interpreter is single-threaded and prioritizes correctness over peak performance.

### On the horizon

- **Pattern matching** — destructuring assignment and match expressions
- **Null-coalescing and optional chaining** — `?.` and `??` operators
- **Property getters/setters** — auto-generated accessors for instance variables
- **Pipeline operator** — natural function-composition syntax
- **Optional actor-model concurrency** — beyond the current cooperative scheduler

The current focus is performance work — string concatenation has been identified as the primary bottleneck, and a native-method dispatch fast path is in design.

---

## Contributing

Contributions are welcome — bug reports, feature proposals, documentation improvements, and pull requests. Before opening a large PR, please open an issue first to discuss the design.

The codebase is organized as a classic interpreter pipeline: `lexer.rb` → `parser.rb` → `ast.rb` → `interpreter.rb`, with method registries (`*methods.rb`) per type and native libraries under separate files. The test suite uses RSpec with Aruba and covers the lexer, parser, interpreter, every standard library, and end-to-end behavior.

```bash
# Run the full test suite:
rspec

# Run a single spec file:
rspec spec/interpreter/oop_spec.rb
```

---

## License

AlexScript is released under the [MIT License](LICENSE). You're free to use it, modify it, redistribute it, and build commercial products on top of it.