# Language Basics #

## Structure of Close Programs ##

Close programs aren't always 'programs', in the sense that many uses of Close will be for writing individual _functions_. Regardless, a Close _compilation unit_ always outputs a sequence of subroutine definitions.

Each function you write contains _declarations_ of variables or functions, and _statements_ that are executed sequentially. There is no limit to the number of declarations or statements you can have within a function, but generally small functions are easier to write.

A _declaration_ can define one or more symbols. Each symbol declaration may include an _initializer_ that sets the starting value for that symbol.

A _statement_ can be used for control flow -- to decide which set of statements to execute next -- or it can be an _expression_ to evaluate in order to invoke a different function or compute a value. Statements can be gathered together in _blocks_, both to organize them and to make a collection of statements subject to the control of another statement.
```
#include <std/io>				// Declares print, say.
#include <std/types>				// Declares Integer

using namespace std;				// Makes std:: names visible

void main() {					// Program starts at 'main'

	for (Integer count = 10; count != 0; --count) {
		sing_verse(count);		// Not declared?
	}
}

void sing_verse(lexical Integer count) {	// 'lexical' is a storage class
	
	String how_many() {			// Lexically nested function
		if (count == 0) {		// 'count' from sing_verse
			return "No more";
		}
		else {
			return count;
		}
	}
	
	say(how_many(), " bottles of beer on the wall!  ",
		how_many(), " bottles of beer!");
	print("Take one down, pass it around, ");
	--count;
	say(how_many(), " bottles of beer on the wall!");
}
```
There are some things that should be familiar to you if you're a C or Java programmer. The #include directives bring symbol definitions into the current file. The `using namespace std` directive makes names contained in the std namespace visible without needing a `std::` prefix on them. The `for` loop and the `--count` pre-decrement operator work about as you would expect (note that you may declare a loop variable in the loop header). And the function calls are the same.

And there are some things that are different, too. First, in the declaration of `sing_verse` there is the storage class specifier `lexical` associated with the count parameter. Then there is the nested function, `how_many()`. And, perhaps least surprising, the lexical parameter `count` is visible inside the nested function.

Finally, there is the fact that `sing_verse` could be called without being declared. That comes from the fact that Close evaluates all declarations before binding any of them. This isn't particularly important in the current example, and in fact you could insert a function declaration for `sing_verse` at the top if you like. But the delayed binding is particularly helpful in other areas, especially writing classes. (Close takes more from Java than from C++ in this regard.)

## Source Files ##

- Structure of source files
- Fake preprocessor
- Functions
- External declarations
- Namespaces

## Character Sets ##

Close is built on Parrot, and Parrot supports a plethora of character sets. Accordingly, any character set supported by Parrot is valid for source files. As explained below, special characters may only be used under certain circumstances.

## Comments ##

Close takes its comment syntax directly from C. A single line can be commented out using two forward slashes ('//'), while a long block of text can be commented out by starting with a forward slash and asterisk ('/`*`') and ending with an asterisk and forward slash ('`*`/').
```
// This is a single line comment.
// This is a different line, but also a comment.

/* This is a "block" comment, that 
   may span multiple lines. Note that just like
   in C & C++, if you include another /* in the comment,
   it doesn't nest.  
    */
```
## Identifiers ##

The names given to namespaces and function and variable symbols are called _identifiers._ Close is intended to be able to support languages with arbitrary characters in their identifiers. For example, almost all Perl variables start with either '@', '$', or '%'. But in order to be true to the 'C' feel, this is prohibited in Close.

Instead, Close differentiates between _declarators_ -- the initial specification of a name when you are telling the compiler about it -- and _identifiers_ -- a name used to refer to a symbol. The rule is that all identifiers must follow the C convention for identifiers: start with underscore ('_') or an alphabetic letter, followed by zero or more underscores, alphabetic letters, or numeric digits. But declarators and namespace names may be quoted, to include special characters._

To close the gap between declarators and identifiers, Close allows the specification of an _alias._
```
int x = 1;					// Common, but short, C name.

Integer NumberOfRetries = 3;			// Longer, mixed-case, name

namespace hll:rakudo :: 'Module++' {		// Note quotes around namespace name.
	Integer '$Counter' alias Counter;	// Quoted  declarator plus alias.
}
```