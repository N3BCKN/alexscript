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