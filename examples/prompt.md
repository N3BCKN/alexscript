1. Basic Syntax and Variable Declaration
Variable Declaration
Variables are declared using the niech keyword. They follow a strict typing system but type is inferred from the assigned value.

niech x = 5              # integer
niech y = 3.14           # float
niech text = "hello"     # string
niech flag = prawda      # boolean (prawda/falsz)
niech empty = nic        # null value


Constants can be declared using UPPERCASE identifiers:

niech CONSTANT = 100     # This variable cannot be mutated

Global variables can be declared using globalna keyword:

globalna niech x = 10    # declares global variable



2. Control Flow
Conditional Statements
The language uses jesli, albo, and albojesli for conditional execution:

jesli x > 5 {
    pokazl "x is greater than 5"
} albojesli x < 0 {
    pokazl "x is negative"
} albo {
    pokazl "x is between 0 and 5"
}

One-liner conditional using to:

jesli x > 10 to pokazl "Greater than 10"

Loops
While Loop
Uses dopoki keyword:

dopoki x < 10 {
    pokazl x
    x = x + 1
}

For Loop
Uses dla keyword with range:

dla niech i = 0; 10; 1 {  # (start; end; step)
    pokazl i
}

Infinite Loop
The petla keyword creates an infinite loop that continues until explicitly broken:

petla {
    pokazl "This will run forever"
    
    jesli condition to zakoncz  # Exits the loop
    
    jesli other_condition to nastepny  # Skips to next iteration
}

Loop control:

zakoncz    # breaks the loop
nastepny   # continues to next iteration


3. Functions
Function Declaration and Usage
Functions are declared using funkcja keyword:

funkcja add(a, b) {
    zwroc a + b
}

# Function call
niech result = add(5, 3)

Functions can return any type and can be nested

funkcja outer() {
    funkcja inner() {
        zwroc "inner function"
    }
    zwroc inner()
}

4. Data Structures
Arrays
Arrays can hold mixed types and are zero-indexed:

niech arr = [1, "two", 3.14, prawda]
niech empty = []

# Accessing elements
pokazl arr[0]        # prints 1

# Modifying elements
arr[1] = "new"      # changes second element

Array Built-in Methods
arr.dlg             # returns array length
arr.dodaj(element)  # adds element to end
arr << element      # alternative way to add element
arr.usun(index)     # removes element at index
arr.wstaw(index, element)  # inserts element at index
arr.zamien(idx1, idx2)     # swaps elements
arr.wyczysc()       # removes all elements
arr.odwroc()        # reverses array
arr.kopiuj()        # creates array copy
arr.zawiera(element)  # checks if element exists
arr.indeks(element)   # returns first index of element
arr.licz(element)     # counts occurrences

For numeric arrays only:
arr.suma()          # sum of elements
arr.srednia()       # average of elements
arr.min()           # minimum value
arr.max()           # maximum value

Objects/Hashes
Objects use key-value pairs with string keys:
niech obj = {
    "name": "John",
    "age": 30
}

# Accessing values
pokazl obj["name"]

# Setting/modifying values
obj["city"] = "New York"

5. Output and Display
Print statements:

pokaz x          # prints without newline
pokazl x         # prints with newline


6. Operators and Expressions
Arithmetic Operators

+     # addition
-     # subtraction
*     # multiplication
/     # division
%     # modulo
^     # exponentiation

Comparison Operators
==    # equal
!=    # not equal
>     # greater than
<     # less than
>=    # greater than or equal
<=    # less than or equal

Logical Operators
i     # logical AND
lub   # logical OR
!     # logical NOT

7. Type System
Built-in types:

:type_int - Integer numbers
:type_float - Floating point numbers
:type_string - String values
:type_bool - Boolean values (prawda/falsz)
:type_null - Null value (nic)
:type_array - Arrays
:type_object - Objects/Hashes

8. Comments
# Single line comment

/* Multi-line
   comment */


   



1. Basic Syntax and Variable Declaration
Variable Declaration
Variables are declared using the niech keyword. They follow a strict typing system but type is inferred from the assigned value.

niech x = 5              # integer
niech y = 3.14           # float
niech text = "hello"     # string
niech flag = prawda      # boolean (prawda/falsz)
niech empty = nic        # null value


Constants can be declared using UPPERCASE identifiers:

niech CONSTANT = 100     # This variable cannot be mutated

Global variables can be declared using globalna keyword:

globalna niech x = 10    # declares global variable



2. Control Flow
Conditional Statements
The language uses jesli, albo, and albojesli for conditional execution:

jesli x > 5 {
    pokazl "x is greater than 5"
} albojesli x < 0 {
    pokazl "x is negative"
} albo {
    pokazl "x is between 0 and 5"
}

One-liner conditional using to:

jesli x > 10 to pokazl "Greater than 10"

Loops
While Loop
Uses dopoki keyword:

dopoki x < 10 {
    pokazl x
    x = x + 1
}

For Loop
Uses dla keyword with range:

dla niech i = 0; 10; 1 {  # (start; end; step)
    pokazl i
}

Infinite Loop
The petla keyword creates an infinite loop that continues until explicitly broken:

petla {
    pokazl "This will run forever"
    
    jesli condition to zakoncz  # Exits the loop
    
    jesli other_condition to nastepny  # Skips to next iteration
}

Loop control:

zakoncz    # breaks the loop
nastepny   # continues to next iteration


3. Functions
Function Declaration and Usage
Functions are declared using funkcja keyword:

funkcja add(a, b) {
    zwroc a + b
}

# Function call
niech result = add(5, 3)

Functions can return any type and can be nested

funkcja outer() {
    funkcja inner() {
        zwroc "inner function"
    }
    zwroc inner()
}

4. Data Structures
Arrays
Arrays can hold mixed types and are zero-indexed:

niech arr = [1, "two", 3.14, prawda]
niech empty = []

# Accessing elements
pokazl arr[0]        # prints 1

# Modifying elements
arr[1] = "new"      # changes second element

Array Built-in Methods
arr.dlg             # returns array length
arr.dodaj(element)  # adds element to end
arr << element      # alternative way to add element
arr.usun(index)     # removes element at index
arr.wstaw(index, element)  # inserts element at index
arr.zamien(idx1, idx2)     # swaps elements
arr.wyczysc()       # removes all elements
arr.odwroc()        # reverses array
arr.kopiuj()        # creates array copy
arr.zawiera(element)  # checks if element exists
arr.indeks(element)   # returns first index of element
arr.licz(element)     # counts occurrences

For numeric arrays only:
arr.suma()          # sum of elements
arr.srednia()       # average of elements
arr.min()           # minimum value
arr.max()           # maximum value

Objects/Hashes
Objects use key-value pairs with string keys:
niech obj = {
    "name": "John",
    "age": 30
}

# Accessing values
pokazl obj["name"]

# Setting/modifying values
obj["city"] = "New York"

5. Output and Display
Print statements:

pokaz x          # prints without newline
pokazl x         # prints with newline


6. Operators and Expressions
Arithmetic Operators

+     # addition
-     # subtraction
*     # multiplication
/     # division
%     # modulo
^     # exponentiation

Comparison Operators
==    # equal
!=    # not equal
>     # greater than
<     # less than
>=    # greater than or equal
<=    # less than or equal

Logical Operators
i     # logical AND
lub   # logical OR
!     # logical NOT

7. Type System
Built-in types:

:type_int - Integer numbers
:type_float - Floating point numbers
:type_string - String values
:type_bool - Boolean values (prawda/falsz)
:type_null - Null value (nic)
:type_array - Arrays
:type_object - Objects/Hashes

8. Comments
# Single line comment

/* Multi-line
   comment */


   AlexScript Object-Oriented Programming System Documentation
1. Introduction
AlexScript implements a comprehensive object-oriented programming paradigm with Polish-language syntax. The OOP system provides all essential features found in modern object-oriented languages, including classes, inheritance, encapsulation, and polymorphism.
2. Classes
2.1 Basic Class Definition
Classes in AlexScript are defined using the klasa keyword followed by the class name and a block of code enclosed in curly braces.
klasa Osoba {
    funkcja konstruktor(imie, wiek) {
        niech @imie = imie
        niech @wiek = wiek
    }
    
    funkcja przedstaw_sie() {
        zwroc "Nazywam się " + @imie + " i mam " + @wiek + " lat"
    }
}
2.2 Constructors
A constructor is defined using the konstruktor method within a class. It initializes the object's state when an instance is created.
klasa Punkt {
    funkcja konstruktor(x, y) {
        niech @x = x
        niech @y = y
    }
}
Constructors can specify default parameters:
klasa Konfiguracja {
    funkcja konstruktor(nazwa = "domyslna", wartosc = 100) {
        niech @nazwa = nazwa
        niech @wartosc = wartosc
    }
}
2.3 Class Instantiation
Objects are instantiated using the .nowy() method on the class name:
niech osoba = Osoba.nowy("Jan", 30)
niech punkt = Punkt.nowy(5, 10)
niech konfig = Konfiguracja.nowy()  // Uses default parameters
3. Instance Variables
3.1 Declaration and Access
Instance variables are prefixed with @ and are scoped to the instance. They can be accessed within instance methods.
klasa Samochod {
    funkcja konstruktor(marka, model) {
        niech @marka = marka
        niech @model = model
        niech @przebieg = 0
    }
    
    funkcja jedz(kilometry) {
        niech @przebieg = @przebieg + kilometry
    }
    
    funkcja info() {
        zwroc @marka + " " + @model + ", przebieg: " + @przebieg + " km"
    }
}
3.2 Default Values
Instance variables are automatically initialized as nic (null) if not explicitly assigned.
4. Methods
4.1 Instance Methods
Instance methods are defined using the funkcja keyword within a class declaration:
klasa Kalkulator {
    funkcja konstruktor() {
        niech @wynik = 0
    }
    
    funkcja dodaj(liczba) {
        niech @wynik = @wynik + liczba
    }
    
    funkcja odejmij(liczba) {
        niech @wynik = @wynik - liczba
    }
    
    funkcja pobierz_wynik() {
        zwroc @wynik
    }
}
4.2 Method Invocation
Methods are invoked using dot notation:
niech kalk = Kalkulator.nowy()
kalk.dodaj(5)
kalk.dodaj(10)
pokazl kalk.pobierz_wynik()  // Displays: 15
5. Inheritance
5.1 Basic Inheritance
AlexScript supports single inheritance using the < operator.
klasa Zwierze {
    funkcja konstruktor(nazwa) {
        niech @nazwa = nazwa
    }
    
    funkcja odglos() {
        zwroc "..."
    }
    
    funkcja przedstaw() {
        zwroc "Jestem " + @nazwa + " i robię " + odglos()
    }
}

klasa Pies < Zwierze {
    funkcja odglos() {
        zwroc "Hau hau!"
    }
}
5.2 Inheritance Rules

Subclasses inherit all methods and instance variables from their parent class.
Only single inheritance is supported (a class can have only one parent).
The inheritance chain can be of any length (multi-level inheritance).
All instance variables and methods are inherited, including private methods.

6. Method Overriding and Polymorphism
6.1 Method Overriding
Subclasses can override methods inherited from parent classes to provide specialized behavior.
klasa Figura {
    funkcja konstruktor() {}
    
    funkcja pole() {
        zwroc 0
    }
    
    funkcja opis() {
        zwroc "Pole: " + pole()
    }
}

klasa Prostokat < Figura {
    funkcja konstruktor(a, b) {
        niech @a = a
        niech @b = b
    }
    
    funkcja pole() {
        zwroc @a * @b
    }
}
6.2 Polymorphism
AlexScript supports polymorphism, allowing subclass instances to be used where parent class instances are expected:
funkcja wyswietl_pole(figura) {
    pokazl "Pole figury: " + figura.pole()
}

niech prostokat = Prostokat.nowy(4, 5)
wyswietl_pole(prostokat)  // Uses Prostokat's implementation of pole()
7. The super Keyword
The super keyword allows access to parent class methods from within a subclass.
7.1 Calling Parent Constructor
klasa Pojazd {
    funkcja konstruktor(nazwa, predkosc) {
        niech @nazwa = nazwa
        niech @predkosc = predkosc
    }
}

klasa Samochod < Pojazd {
    funkcja konstruktor(nazwa, predkosc, marka) {
        super(nazwa, predkosc)  // Calls parent constructor
        niech @marka = marka
    }
}
7.2 Calling Parent Methods
klasa Prostokat < Figura {
    funkcja opis() {
        zwroc "Prostokąt o " + super()  // Calls parent's opis() method
    }
}
7.3 Calling Specific Parent Methods
Using the dot notation, you can call specific methods from the parent class:
klasa Potomna < Bazowa {
    funkcja metoda() {
        zwroc super.inna_metoda() + " zmodyfikowana"
    }
}
8. Static Methods and Variables
Static methods and variables belong to the class rather than to instances. They are defined using the statyczny keyword.
8.1 Static Variables
klasa Matematyka {
    statyczny niech PI = 3.14159
    statyczny niech E = 2.71828
}

pokazl Matematyka.PI  // Displays: 3.14159
8.2 Static Methods
klasa Matematyka {
    statyczny funkcja kwadrat(x) {
        zwroc x * x
    }
    
    statyczny funkcja pierwiastek(x) {
        zwroc x ^ 0.5
    }
}

pokazl Matematyka.kwadrat(4)      // Displays: 16
pokazl Matematyka.pierwiastek(9)  // Displays: 3
8.3 Static Inheritance
Static methods and variables are inherited by subclasses:
klasa Geometria < Matematyka {
    statyczny funkcja pole_kola(r) {
        zwroc Matematyka.PI * Matematyka.kwadrat(r)
    }
}

pokazl Geometria.pole_kola(5)  // Displays: 78.53975
9. Abstract Classes
Abstract classes cannot be instantiated directly and are meant to be subclassed. They are defined using the abstrakcyjna keyword before klasa.
abstrakcyjna klasa Figura {
    funkcja konstruktor() {}
    
    funkcja pole() {
        rzuc "Metoda abstrakcyjna 'pole' musi być zaimplementowana w klasach pochodnych"
    }
    
    funkcja opis() {
        zwroc "Figura geometryczna"
    }
}

klasa Prostokat < Figura {
    funkcja konstruktor(a, b) {
        niech @a = a
        niech @b = b
    }
    
    funkcja pole() {
        zwroc @a * @b
    }
}

// niech figura = Figura.nowy()  // Error: Cannot instantiate abstract class
niech prostokat = Prostokat.nowy(4, 5)  // OK
10. Access Control
AlexScript supports public and private methods for encapsulation.
10.1 Private Methods
Private methods are accessible only within the class they are defined in and in subclasses. They are defined by placing the prywatne keyword before method declarations.
klasa Kalkulator {
    funkcja konstruktor() {
        niech @wynik = 0
    }
    
    funkcja dodaj(a, b) {
        zwroc oblicz_sume(a, b)
    }
    
    prywatne
    
    funkcja oblicz_sume(a, b) {
        zwroc a + b
    }
}

niech kalk = Kalkulator.nowy()
pokazl kalk.dodaj(5, 3)       // OK, displays: 8
// pokazl kalk.oblicz_sume(5, 3)  // Error: Cannot call private method
10.2 Inheritance of Private Methods
Private methods are inherited by subclasses and remain private:
klasa Bazowa {
    funkcja metoda_publiczna() {
        zwroc metoda_prywatna() * 2
    }
    
    prywatne
    
    funkcja metoda_prywatna() {
        zwroc 42
    }
}

klasa Pochodna < Bazowa {
    funkcja inna_metoda() {
        zwroc metoda_prywatna() + 10  // Can access parent's private method
    }
}

niech obj = Pochodna.nowy()
pokazl obj.metoda_publiczna()  // Displays: 84
pokazl obj.inna_metoda()       // Displays: 52
// pokazl obj.metoda_prywatna()   // Error: Cannot call private method
11. Advanced OOP Features
11.1 Class Composition
klasa Silnik {
    funkcja konstruktor(moc) {
        niech @moc = moc
    }
    
    funkcja pobierz_moc() {
        zwroc @moc
    }
}

klasa Samochod {
    funkcja konstruktor(model, silnik) {
        niech @model = model
        niech @silnik = silnik
    }
    
    funkcja opis() {
        zwroc @model + " z silnikiem o mocy " + @silnik.pobierz_moc() + " KM"
    }
}

niech silnik = Silnik.nowy(150)
niech auto = Samochod.nowy("Toyota", silnik)
pokazl auto.opis()  // Displays: Toyota z silnikiem o mocy 150 KM
11.2 Factory Methods
klasa Osoba {
    funkcja konstruktor(imie, wiek, zawod) {
        niech @imie = imie
        niech @wiek = wiek
        niech @zawod = zawod
    }
    
    statyczny funkcja stworz_studenta(imie, wiek) {
        zwroc Osoba.nowy(imie, wiek, "student")
    }
    
    statyczny funkcja stworz_nauczyciela(imie, wiek) {
        zwroc Osoba.nowy(imie, wiek, "nauczyciel")
    }
}

niech student = Osoba.stworz_studenta("Jan", 20)
niech nauczyciel = Osoba.stworz_nauczyciela("Anna", 45)
11.3 Multi-level Inheritance
klasa A {
    funkcja metoda() {
        zwroc "A"
    }
}

klasa B < A {
    funkcja metoda() {
        zwroc super() + "B"
    }
}

klasa C < B {
    funkcja metoda() {
        zwroc super() + "C"
    }
}

niech obj = C.nowy()
pokazl obj.metoda()  // Displays: ABC
12. Implementation Details
12.1 Class Representation
Internally, classes are represented as structures containing:

Parent class reference
Methods table (including private methods)
Static methods table
Static variables table
Abstract flag indicating whether the class is abstract

12.2 Instance Representation
Instances are represented as structures containing:

Class name reference
Instance variables table
Reference to class definition

12.3 Method Resolution
When a method is called on an instance:

The interpreter first checks if the method exists in the instance's class
If not found, it searches through the inheritance chain
If the method is found but is private, access rules are enforced
If the method is not found in any parent class, an error is raised

12.4 Super Method Resolution
When super() is used in a method:

The current method name is determined through context tracking
The parent class is identified
The method with the same name is searched in the parent class
The method is executed with the current instance as context




WYJĄTKI
Exception Handling in AlexScript
Table of Contents
Introduction
Exception Types
Try-Catch-Finally Blocks
Throwing Exceptions
Custom Exceptions
Exception Properties
Working with Exceptions in Functions
Best Practices
Introduction
AlexScript provides a robust exception handling system that allows you to gracefully respond to errors during execution. The exception system is inspired by JavaScript's syntax while incorporating features from Ruby's exception model. This chapter documents the exception handling mechanisms in AlexScript.
Exception Types
AlexScript comes with several built-in exception types:
Exception Type
Description
WyjatekPodstawowy
Base exception from which all other exceptions inherit
BladWykonania
General runtime error
BladSkladni
Syntax error
BladTypu
Type error (incompatible types)
BladZakresu
Range or index error
BladMetody
Method not found or invalid method call
BladNazwy
Undefined variable or identifier
BladArgumentu
Invalid argument provided to function
BladDzieleniaPrzezZero
Division by zero error

When an error occurs during execution, AlexScript automatically raises one of these exceptions with an appropriate error message.
Try-Catch-Finally Blocks
AlexScript provides proba, zlap, and wkoncu keywords (equivalent to try, catch, and finally) to handle exceptions.
Basic Syntax
proba {
    # Code that might throw an exception
} zlap (e) {
    # Code to handle the exception
} wkoncu {
    # Code that executes regardless of whether an exception was thrown
}

Example: Basic Exception Handling
proba {
    niech x = 10
    niech y = 0
    pokazl x / y  # This will cause a division by zero error
} zlap (e) {
    pokazl "An error occurred: " + e[‘wiadomosc’]
} wkoncu {
    pokazl "This code always runs"
}

Output:
An error occurred: Dzielenie przez zero
This code always runs

Catching Specific Exception Types
You can catch specific types of exceptions by specifying the exception type after the catch variable:
proba {
    # Code that might throw an exception
} zlap (e : BladDzieleniaPrzezZero) {
    # This block only executes for division by zero errors
} zlap (e : BladTypu) {
    # This block only executes for type errors
} zlap (e) {
    # This block executes for all other exceptions
}

Example: Multiple Catch Blocks
funkcja podziel(a, b) {
    jesli b == 0 {
        rzuc { typ: "BladDzieleniaPrzezZero", wiadomosc: "Cannot divide by zero" }
    }
    zwroc a / b
}

proba {
    pokazl podziel(10, 0)
} zlap (e : BladDzieleniaPrzezZero) {
    pokazl "Division error: " + e[‘wiadomosc’]
} zlap (e) {
    pokazl "Other error: " +  e[‘wiadomosc’]
}

Output:
Division error: Cannot divide by zero

Throwing Exceptions
You can explicitly throw exceptions using the rzuc keyword. AlexScript provides two ways to throw exceptions:
1. Simple Exception with Message
rzuc "Error message"

This creates a basic WyjatekPodstawowy with the specified message.
2. Exception with Type and Message
rzuc { typ: "ExceptionType", wiadomosc: "Error message" }

This creates an exception of the specified type with the given message.
Examples
# Simple exception
rzuc "Something went wrong"

# Typed exception
rzuc { typ: "BladTypu", wiadomosc: "Expected number, got string" }

# Custom exception (defined elsewhere)
rzuc { typ: "MojWlasnyWyjatek", wiadomosc: "Custom error occurred" }

Custom Exceptions
You can define your own exception types using the wyjatek keyword:
Basic Syntax
wyjatek ExceptionName

This creates a new exception type that inherits from WyjatekPodstawowy.
Inheritance
You can specify a parent exception type for your custom exception:
wyjatek ExceptionName : ParentExceptionName

Example: Creating and Using Custom Exceptions
# Define a hierarchy of custom exceptions
wyjatek BladAplikacji
wyjatek BladDanych : BladAplikacji
wyjatek BladBazyDanych : BladDanych

funkcja polacz_z_baza() {
    rzuc { typ: "BladBazyDanych", wiadomosc: "Failed to connect to database" }
}

proba {
    polacz_z_baza()
} zlap (e : BladBazyDanych) {
    pokazl "Database error: " +  e[‘wiadomosc’]
} zlap (e : BladAplikacji) {
    pokazl "Application error: " +  e[‘wiadomosc’]
}

Output:
Database error: Failed to connect to database

Exception Properties
When you catch an exception, the exception object contains several properties:
Property
Description
wiadomosc
The error message
typ
The exception type
linia
The line number where the exception occurred

Example: Accessing Exception Properties
proba {
    niech arr = [1, 2, 3]
    pokazl arr[10]  # Index out of bounds
} zlap (e) {
    pokazl "Error type: " + e[‘typ’]
    pokazl "Message: " +  e[‘wiadomosc’]
    pokazl "Line: " + e[‘linia’]
}

Output:
Error type: BladZakresu
Message: Indeks poza zakresem
Line: 3

Working with Exceptions in Functions
Exceptions propagate up the call stack until they are caught. This allows for centralizing error handling.
Example: Exception Propagation
funkcja funkcja_a() {
    funkcja_b()
}

funkcja funkcja_b() {
    funkcja_c()
}

funkcja funkcja_c() {
    rzuc "Error in function C"
}

proba {
    funkcja_a()
} zlap (e) {
    pokazl "Caught error: " +  e[‘wiadomosc’]
}

Output:
Caught error: Error in function C

Example: Rethrowing Exceptions
You can catch an exception, perform some operations, and then rethrow it:
proba {
    # Some code that might throw an exception
    rzuc "Original error"
} zlap (e) {
    pokazl "Logging error: " +  e[‘wiadomosc’]
    
    # Rethrow the exception
    rzuc "Modified error based on: " + e.wiadomosc
}

Best Practices
1. Use Specific Exception Types
Instead of catching all exceptions, catch specific types to handle different errors appropriately:
proba {
    # Code that might throw different exceptions
} zlap (e : BladDzieleniaPrzezZero) {
    # Handle division by zero
} zlap (e : BladTypu) {
    # Handle type errors
} zlap (e) {
    # Handle other exceptions
}

2. Always Include Finally for Cleanup
Use the wkoncu block for cleanup operations that must be performed regardless of whether an exception occurred:
niech plik = otworz_plik("dane.txt")
proba {
    # Operations on the file
} wkoncu {
    zamknij_plik(plik)  # Always close the file
}

3. Keep Exception Handling Separate from Business Logic
Separate your business logic from exception handling to improve code clarity:
# Good practice
funkcja podziel(a, b) {
    jesli b == 0 {
        rzuc { typ: "BladDzieleniaPrzezZero", wiadomosc: "Cannot divide by zero" }
    }
    zwroc a / b
}

# Usage with proper exception handling
proba {
    wynik = podziel(10, input_value)
    # Process result
} zlap (e) {
    # Handle error
}

4. Create a Custom Exception Hierarchy
For complex applications, create a custom exception hierarchy to categorize errors:
wyjatek BladAplikacji
wyjatek BladWalidacji : BladAplikacji
wyjatek BladWalidacjiDanych : BladWalidacji
wyjatek BladWalidacjiFormularza : BladWalidacji

This allows you to catch exceptions at different levels of specificity as needed.
5. Include Relevant Information in Exceptions
When throwing exceptions, include information that will help diagnose the problem:
funkcja przetworz_dane(dane) {
    jesli dane.length == 0 {
        rzuc { 
            typ: "BladDanych", 
            wiadomosc: "Empty data set. Expected at least 1 record."
        }
    }
    # Process data
}




Functions in AlexScript
Table of Contents
Introduction
Declaring and Calling Functions
Parameters and Arguments
Regular Parameters
Default Parameters
Rest Parameters
Return Values
Explicit Returns
Implicit Returns
Early Returns
Return Types
Variable Scope in Functions
Local Scope
Outer Scope Access
Nested Functions
Argument Shadowing
Functions as Values
Assigning Functions to Variables
Passing Functions as Arguments
Error Handling
Argument Validation
Recursion Limits
Common Errors
Advanced Usage
Combining with Other Language Features
Introduction
Functions are a fundamental building block in AlexScript. They allow you to encapsulate reusable code, organize your program, and create abstractions. Functions in AlexScript are declared using the funkcja keyword, followed by a name, parameters, and a body enclosed in curly braces.
Declaring and Calling Functions
Basic Function Declaration
funkcja nazwa_funkcji() {
    # Ciało funkcji
}

Function Call
nazwa_funkcji()

Example
funkcja powitaj() {
    pokazl "Witaj, świecie!"
}

powitaj()  # Wyświetli: "Witaj, świecie!"

Empty Functions
You can declare functions without any body:
funkcja pusta() {}

pusta()  # Zwraca: nic

Parameters and Arguments
Regular Parameters
Functions can accept parameters that allow passing data to the function.
funkcja suma(a, b) {
    zwroc a + b
}

pokazl suma(5, 3)  # Wyświetli: 8

Default Parameters
Parameters can have default values that are used when a corresponding argument is not provided.
funkcja powitaj(imie, pozdrowienie = "Cześć") {
    pokazl pozdrowienie + ", " + imie + "!"
}

powitaj("Anna")              # Wyświetli: "Cześć, Anna!"
powitaj("Tomek", "Witaj")    # Wyświetli: "Witaj, Tomek!"

Default parameters must appear after all regular parameters. The following will cause an error:
funkcja niepoprawna(a = 1, b) {  # Błąd: parametr bez wartości domyślnej po parametrze z wartością domyślną
    # ...
}

Rest Parameters
Functions can accept a variable number of arguments using the rest parameter syntax. The rest parameter must be the last parameter in the function declaration.
funkcja suma(pierwszy, *reszta) {
    niech wynik = pierwszy
    dla liczba w reszta {
        wynik += liczba
    }
    zwroc wynik
}

pokazl suma(1, 2, 3, 4, 5)  # Wyświetli: 15

Rest parameters are collected into an array, even if no additional arguments are provided:
funkcja zlicz(nazwa, *elementy) {
    pokazl nazwa + ": " + elementy.dlg  # .dlg gets the length of an array
}

zlicz("Lista")         # Wyświetli: "Lista: 0"
zlicz("Liczby", 1, 2)  # Wyświetli: "Liczby: 2"

Return Values
Explicit Returns
Functions can return values using the zwroc keyword:
funkcja kwadrat(x) {
    zwroc x * x
}

pokazl kwadrat(4)  # Wyświetli: 16

Implicit Returns
If a function does not explicitly return a value, it implicitly returns nic:
funkcja bez_zwrotu() {
    niech x = 5
}

pokazl bez_zwrotu()  # Wyświetli: nic

Early Returns
Functions can return from any point, which is useful for conditional logic:
funkcja absolutna(x) {
    jesli x < 0 {
        zwroc -x
    }
    zwroc x
}

pokazl absolutna(-5)  # Wyświetli: 5
pokazl absolutna(5)   # Wyświetli: 5

Return Types
Functions can return values of any type:
funkcja zwroc_int() { zwroc 42 }
funkcja zwroc_float() { zwroc 3.14 }
funkcja zwroc_string() { zwroc "tekst" }
funkcja zwroc_bool() { zwroc prawda }
funkcja zwroc_array() { zwroc [1, 2, 3] }
funkcja zwroc_object() { zwroc {"klucz": "wartość"} }
funkcja zwroc_nic() { zwroc nic }

pokazl zwroc_int()     # Wyświetli: 42
pokazl zwroc_float()   # Wyświetli: 3.14
pokazl zwroc_string()  # Wyświetli: tekst
pokazl zwroc_bool()    # Wyświetli: prawda
pokazl zwroc_array()   # Wyświetli: [1, 2, 3]
pokazl zwroc_object()  # Wyświetli: {klucz: wartość}
pokazl zwroc_nic()     # Wyświetli: nic

Variable Scope in Functions
Local Scope
Variables declared inside a function are local to that function and not accessible outside:
funkcja test() {
    niech x = 10
    pokazl x
}

test()      # Wyświetli: 10
pokazl x    # Błąd: Niezdefiniowana zmienna x

Outer Scope Access
Functions can access variables from the outer scopes:
niech x = 10

funkcja test() {
    pokazl x  # Dostęp do zmiennej z zewnętrznego zakresu
}

test()  # Wyświetli: 10

Nested Functions
Functions can be defined inside other functions, creating nested scopes:
funkcja zewnetrzna() {
    niech x = 1
    
    funkcja wewnetrzna() {
        niech y = 2
        pokazl x + y  # Dostęp do zmiennej z zewnętrznej funkcji
    }
    
    wewnetrzna()  # Wyświetli: 3
}

zewnetrzna()
wewnetrzna()  # Błąd: Niezdefiniowana funkcja

Argument Shadowing
Function parameters can shadow variables from outer scopes:
niech x = 10

funkcja test(x) {  # Parametr x przesłania zewnętrzną zmienną x
    pokazl x
}

test(5)     # Wyświetli: 5
pokazl x    # Wyświetli: 10 (zewnętrzna zmienna nie jest zmodyfikowana)

Functions as Values
Assigning Functions to Variables
Functions are first-class citizens in AlexScript and can be assigned to variables:
funkcja powitaj() {
    pokazl "Witaj!"
}

niech moja_funkcja = powitaj
moja_funkcja()  # Wyświetli: "Witaj!"

Passing Functions as Arguments
Functions can be passed as arguments to other functions:
funkcja zastosuj(funkcja, wartosc) {
    zwroc funkcja(wartosc)
}

funkcja podwoj(x) {
    zwroc x * 2
}

funkcja dodaj_trzy(x) {
    zwroc x + 3
}

pokazl zastosuj(podwoj, 5)      # Wyświetli: 10
pokazl zastosuj(dodaj_trzy, 5)  # Wyświetli: 8

Error Handling
Argument Validation
AlexScript validates the number of arguments passed to a function:
funkcja suma(a, b) {
    zwroc a + b
}

suma(1)      # Błąd: Funkcja suma oczekiwala minimum 2 argumentów, otrzymała 1
suma(1, 2, 3)  # Błąd: Funkcja suma oczekiwala maksymalnie 2 argumentów, otrzymała 3

With default parameters, minimum arguments are only those without defaults:
funkcja test(a, b = 5) {
    pokazl a + b
}

test(3)      # Poprawne, b przyjmie wartość domyślną 5
test(3, 7)   # Poprawne, b przyjmie wartość 7
test()       # Błąd: Funkcja test oczekiwala minimum 1 argumentów, otrzymała 0

With rest parameters, there's no maximum limit on arguments:
funkcja suma(a, *liczby) {
    # ...
}

suma(1)                  # Poprawne, liczby to pusta tablica
suma(1, 2, 3, 4, 5, 6)   # Poprawne, liczby to [2, 3, 4, 5, 6]

Recursion Limits
AlexScript has a limit on recursion depth to prevent stack overflow:
funkcja nieskonczona_rekursja() {
    nieskonczona_rekursja()  # Spowoduje błąd po pewnej liczbie wywołań
}

nieskonczona_rekursja()  # Błąd: Maximum recursion depth exceeded, stack is too deep

Example of safe recursion with a base case:
funkcja silnia(n) {
    jesli n <= 1 {
        zwroc 1  # Przypadek bazowy, zapobiega nieskończonej rekursji
    }
    zwroc n * silnia(n - 1)
}

pokazl silnia(5)  # Wyświetli: 120

Common Errors
Calling undefined functions:
nieistniejaca_funkcja()  # Błąd: Funkcja nieistniejaca_funkcja nie zostala zadeklarowana w obecnym zakresie

Calling non-function values:
niech x = 5
x()  # Błąd: Niepoprawna wartosc funkcji dla x

Missing return value:
funkcja test() {
    zwroc  # Błąd składniowy: oczekiwano wyrażenia po zwroc
}

Advanced Usage
Combining with Other Language Features
Functions can be combined with other language features like loops, conditionals, and data structures:
funkcja przetwarzaj_tablice(tablica) {
    niech suma = 0
    dla element w tablica {
        jesli element == nic {
            nastepny  # Przejdź do następnej iteracji
        }
        suma += element
    }
    zwroc suma
}

funkcja stworz_dane() {
    zwroc [1, 2, nic, 4, 5]
}

pokazl przetwarzaj_tablice(stworz_dane())  # Wyświetli: 12

Functions with multiple returns and complex branching:
funkcja zlozoność(x) {
    jesli x < 0 {
        zwroc "ujemna"
    } albojesli x == 0 {
        jesli prawda {
            zwroc "zero"
        }
        zwroc "nigdy nie dojdzie"
    } albo {
        dla niech i = 0; i < x; i += 1 {
            jesli i == 2 {
                zwroc "znaleziono 2"
            }
        }
        zwroc "dodatnia"
    }
}

pokazl zlozoność(-1)  # Wyświetli: ujemna
pokazl zlozoność(0)   # Wyświetli: zero
pokazl zlozoność(5)   # Wyświetli: znaleziono 2


Functions in AlexScript provide a powerful mechanism for code organization and reuse. With features like default parameters, rest parameters, and first-class functions, you can write expressive and flexible code to solve a wide range of problems.



