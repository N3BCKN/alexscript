# versioning

## 0.1.0

first fully working version with basic structures:

- fully working interpreter system with tokenizer, parser and interpreter
- variables declaration,
- variables scopes, global and local variables
- comments (both one and multi liners)
- if-else statements,
- functions,
- for and while loops

## 0.2.0

* constant, unmutable variables
* null type of variables (nic)
* break and continue (zakoncz/nastepny) procedures in loops
* if one liner statements (jesli... to....)

## 0.3.0

* implement arrays with basic funcitonalities 
* include mechanism for build-in methods

### 0.3.1 
* implement loop statement (petla)

### 0.3.2
* impelement proper REPL mechanism

### 0.3.3
* add chain methods and methods performed on elements of array

### 0.3.4
* ability to modify elements from nested arrays

## 0.4.4
* add objects 
* add builtin methods for objects 
* add for loop to iterate over objects
* add for loop to iterate over arrays

### 0.4.5
* add exit statement (wyjscie())

### 0.4.6
* add compound operators += -= *= /=

### 0.4.7
* add function as arguments to other functions 
* implement recursion limit (600)
* implement nil (nic) as false in if/else conditions

### 0.4.8
* add "<<" operator to add elements to arrays

### 0.4.9
* add built in methods for arrays
* add built in methods for objects
* add built in methods for floats
* add built in methods for ints 
* add built in methods for strings

### 0.4.10
* allow for concatenation of strings with arrays and objects

### 0.4.11
* import files 

### 0.5.11
* implement exceptions

### 0.5.12
* add default function params 

### 0.5.13
* add rest param (*args) to function declarations

### 0.6.13
* add OOP 
* classes and instances
* classes inheritance 
* private methods 
* static methods and static variables

### 0.6.14
* standard libraries (Mat, Czas, Socket)

### 0.6.15
* add build in class and instance methods

### 0.7.15
* implement debugger 

### 0.7.16
* new standard libraries (HTTP, JSON, CSV, Plik, Digest, SecureRandom)

### 0.8.16
* anonymous functions and higher order methods 

### 0.8.17
* add built-in methods for modules
* fix static methods within modules
* allow modules to be reopen multiple times 

### 0.9.17
* implement async  
* bitwise operations
* regular expressions 

### 0.9.18
* add istnieje() (exist/defined) keyword 
* fix error with printing class indentifiers
* fix error with methods passing as arguments evaluation  
* set priority of custom methods over built in ones 

### 0.9.19
* quickfix: wrap object collection-returning methods in typed AS arrays
* allow dot operator for module function calls
* support qualified module paths in zlap exception types
* quickfix: rzuc accepts instances from ModuleClassInstantiation
* quickfix: properly display raw class instances without rendering content of env
* pokazl shows readable repr for functions and classes
* implicit constructors for 'bare' classes and in-module classes 
* strict null, return exceptions 

### 0.9.24
* migrate to ruby 4.0.3

### 0.9.25
* Return flow control has been rewritten from exceptions to throw/catch. The function return statement no longer allocates an exception object or builds a full stack trace on each call—instead, it uses Ruby's lightweight throw/catch mechanism. The result: recursion is ~3× faster (fib from 6.2s to 2.1s), and function and method calls are 25-35%.
* Lazy environment allocation and fast-path arithmetic. Runtimes only create the structures they actually use (instead of four hash tables on each call), and integer operations bypass expensive type checking. Overall, ~45% less memory allocation on a typical recursive workload.
* Function metadata is precompiled and unnecessary lookups are eliminated. Parameter information (count, default parameters, *rest) is counted once per parse, not per call; Double function resolution on the async path has also been removed. Loops, inheritance, and static methods have gained an additional 15-25%.

### 0.9.26
* new key types for objects (integer, variable, null)
* fix bug that blocked from checking type of constant variables


### 0.10.26

- fix operator precedence: `%` had its own level above `*` and `/`, so `2 * 6 % 4` parsed as `2 * (6 % 4)` and returned 4 instead of 0. All three operators now share one left-associative level, matching Ruby, Python and C. Breaking for any expression that mixed `%` with `*` or `/` without parentheses.
- division now always returns a float. Previously `/` returned an integer whenever the result happened to be whole (`10 / 5` → `2`) and a float otherwise (`10 / 4` → `2.5`), so the result type depended on the operand values rather than their types. Added `//` for floored integer division. Compound assignment was rewritten to delegate to the same operator dispatch as the expanded form — until now `+=`, `-=`, `*=` and `/=` applied Ruby's operators to raw values and kept the old type tag, so `x /= 2` floored while `x = x / 2` did not, and `x += 0.5` stored a float still tagged as an integer.
- fix `.dodaj()` and `.wstaw()` raising `BladTypu` for `prawda`, `falsz` and `nic`. Built-in methods received unwrapped values and had to re-derive the AlexScript type from the Ruby one, which cannot work for the three primitive singletons — they share a single class. Both methods are now registered as typed and receive the type tag alongside the value, so nothing is guessed. The `<<` operator was never affected, since it kept the type from the interpreter.
- Polish letters are now legal in identifiers, and keywords accept diacritic spellings. `niech imię = "Anna"`, `funkcja gęstość()` and `@nazwisko_użytkownika` all lex; `jeśli`, `zwróć`, `fałsz`, `dopóki`, `moduł`, `dołącz` and twelve more resolve to exactly the same tokens as their ASCII forms, so both spellings can be mixed freely in one file. ASCII stays canonical in the documentation — the aliases are a convenience, not a migration. Purely additive: diacritics were a lexing error before, so no existing program can be affected.
- the lexer scans bytes instead of characters. `String#[]` falls back to a linear scan as soon as a source file contains a single non-ASCII byte, which made tokenization quadratic for any file with Polish text in a string or a comment. 40k lines with one Polish character in a comment: 29.2s → 0.018s. Pure-ASCII files got 3-6× faster as a side effect, since the per-character String allocation is gone. Comment scanning switched from `index` to `byteindex`, which also fixes line numbers reported after non-ASCII text.