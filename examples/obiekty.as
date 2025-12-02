# niech planety = [
#     ["Merkury", 57.9, 88]
# ]

# planety[0][0] = 5
# pokaz planety

# pokazl planety[0][0] = "Dupa"

# pokaz planety[0]

# niech imie = "Jan"
# niech x = {
#     "name": imie,
#     "surname": "Kowalski",
#     "age": 12,
#     "something": {
#         "something": "something",
#         "something": "dupa"
#     }
# }
# niech a = "name"
# x["something"]["something"] = "test"
# pokaz x["something"]["something"] 
# pokazl x

#        niech arr = [1, 2, 3, 4]
#        pokazl arr.dlg 
#        niech x = 0
#        pokazl arr[x]
#         dla niech indeks = 0; arr.dlg; 1 {
#           pokazl indeks
#           pokazl arr 
#           arr[indeks] = arr[indeks] * 2
#         }
#         pokazl arr



# niech obiekt = {
#     "klucz": "test0", 
#     "klucz": "test1"
# }


jesli !nic to pokazl "nic"


alexscript/
├── lib/
│   ├── core/              # Główne komponenty interpretera
│   │   ├── lexer.rb       # Tokenizacja kodu
│   │   ├── parser.rb      # Parsowanie tokenów do AST
│   │   ├── interpreter.rb # Wykonywanie kodu
│   │   └── environment.rb # Zarządzanie zmiennymi i scope
│   │
│   ├── ast/              # Definicje węzłów AST
│   │   ├── base.rb       # Klasy bazowe Node, Expr, Stmt
│   │   ├── literals.rb   # Int, Float, String, Bool, Null
│   │   ├── variables.rb  # Identifier, Assignment, VariableDeclaration
│   │   ├── operations.rb # BinOp, UnOp, LogicalOp
│   │   ├── control.rb    # If, While, For
│   │   ├── functions.rb  # FuncDecl, FuncCall
│   │   ├── arrays.rb     # ArrayLiteral, ArrayAccess
│   │   └── objects.rb    # ObjectLiteral, ObjectAccess
│   │
│   ├── std/              # Biblioteki standardowe
│   │   ├── io/           # Input/Output
│   │   │   ├── input.rb 
│   │   │   └── print.rb
│   │   ├── net/          # Sieciowe
│   │   │   └── socket.rb
│   │   └── time.rb
│   │
│   └── utils/            # Narzędzia pomocnicze
│       ├── errors.rb     # Obsługa błędów
│       ├── token.rb      # Klasa Token
│       └── debug.rb      # Narzędzia debugowania
│
├── examples/             # Przykładowe programy
│   ├── basic/
│   ├── network/
│   └── algorithms/
│
├── test/                # Testy
│   ├── core/
│   ├── ast/
│   └── std/
│
├── bin/                 # Skrypty wykonywalne
│   └── alexscript            # Główny skrypt uruchomieniowy
│
├── Gemfile             # Zależności
├── README.md
└── alexscript.rb            # Punkt wejścia do interpretera
