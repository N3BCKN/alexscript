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