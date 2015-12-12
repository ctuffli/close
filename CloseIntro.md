

# Preface #

The [Parrot Virtual Machine](http://www.parrot.org) (Parrot VM or PVM) is intended to support dynamic languages, and the tools being built on and around it support that goal. But as Dan Sugalski poined out in his [Parrot Post-Mortem](http://www.sidhe.org/~dan/blog/archives/000435.html), not having a high-level language (HLL) sitting right on top of PIR means that everyone needs to program in PIR.

Unfortunately, PIR is assembly language. For a processor that nobody really understands. It's not that the PVM is a new processor -- porting assembly from one CPU to another is generally a simple task. But the Parrot model is _not_ "just another CPU," and so programming in PIR is _not_ just learning another set of slightly-different opcodes and registers. Do you know what the difference between a vtable and a method call is? Do you know what to do with a namespace? Do you know why the _CPU_ cares about namespaces?

**Close** is a general-purpose programming language modeled on C. Where possible, it has the same syntax, or the same "style," that C does. Like C, Close is not a "very high level" language, nor is it a "big" language. Instead, it aims to serve the same role that C serves in systems programming: provide an abstract syntax that gives access to low-level functionality.

This part of the Close wiki is intended to help you, the reader, understand how to program in Close. It contains a tutorial section intended to get you up and working as quickly as possible, with separate chapters for major themes in the language.

This is not an introduction to programming. It is an introduction to programming Close on the Parrot VM. You are assumed to know about things like variables, loops, subroutines, statements, objects, and the like.

Close is an evolving language. As of this writing (July, 2009) major parts of the language are missing or unimplemented. Thus, you may encounter sections that list "planned" behavior, or that make statements that simply aren't true. Please submit tickets for the latter. Of course, you are welcome to help implement the former.

# Introduction #

We begin with a quick introduction to Close. The aim is to show the essential elements of the language in a "real-world" fashion. So here is some code:
```
namespace PCT::Node;

int serial_number = 10;

class PCT::Node
    extends ::parrot::Capture
    :phylum(P6object)
{
    pmc attr(str attrname, pmc value, int has_value, pmc default = new Undef)
        :method
    {
        if (has_value) {
            return self[attrname] = value;
        }
        else {
            value = self[attrname];

            if (isnull value) {
                return default;
            }

            return value;
        }
    }

    # ...
}
```

## Real world code example ##

The first milestone in Close development was to be able to re-implement the file ~/compilers/pct/src/PCT/Node.pir shipped with Parrot. The above lines are from the top of the Node.c= that implements the same functionality.

You will note that unlike C, there are classes in Close. And namespaces. And the interaction between classes and namespaces is defined by Parrot, so it may not be intuitive to you if you are familiar with e.g., Java, C#, or C++. We'll come back to that later.

### Function definition ###

The function being defined is called 'attr' and it takes four arguments: `attrname`, `value`, `has_value`, and `default`. The `attrname` is a `str` -- a string -- and thus is suitable for storing in a PVM 'S' register. The `value` is a `pmc` -- an object reference. The boolean `has_value` is an `int` -- a tradition that extends even to Parrot opcodes -- and so could be stored in an 'I' register. And the `default` parameter is another PMC, providing a value to be used if none is stored.

In addition, the `attr` function is also declared to be a _method_ by the `:method` _adverb._ Adverbial modifiers follow the expression or declaration they modify, and are indicated with a leading colon(':') character.

A function that is a method will have an additional, implicit, parameter referred to as `self.` The `self` parameter is a reference to the current object, much like `this` in C++ or Java.

Finally, the `attr` method returns a PMC. As in C, the return type is at the beginning of the declaration, along with any storage class (such as 'extern') or type qualifiers (such as 'const' or 'inline').


### Function body ###

Within the function body, things are much as they would be in a C program, with two exceptions:

  * The `self` variable is accessed as though it were a Hash, using the postfix '[ ]' operator and a string index. This may be confusing for C programmers, because `self` was not declared anywhere, and the class declaration at the top has no indicator of any Hash or Array heritage. All true. But a Capture has Hash-like behavior, so deal with it.

  * The `isnull` keyword is a built-in unary operator. It results in a similar 'isnull' opcode being generated in the resulting compiled bytecode. You can find a long list of the various PVM opcodes, along with their representation in Close, in the file $CLOSE/src/parser/builtins.pg.

In general, the PVM opcodes are broken into four distinct categories. Eventually, there should only be three categories.
  1. Opcodes that are represented as syntax elements. These include if, goto, call/return, etc.
  1. Opcodes that you don't need to call. (You can still do if from inline assembly, but this is a short list, and you don't need 'em.)
  1. Opcodes that are provides as builtin operators, like `isnull` above.
  1. Opcodes that I haven't got around to, yet. (Hey! We're at release 0.1 here.)

## The structure of Close code ##

A Close file -- called a _compilation unit_ -- is composed of directives, declarations and statements. A _directive_ is a note to the compiler about something happening in the code -- a `hll` or `namespace` block, for example. A _declaration_ is one or more lines of code that declares a variable, function, or class. And a _statement_ is executable code that causes some action to occur.

### Directives ###

The most obvious directives used in Close are the `hll` and `namespace` directives. These tell the compiler to change the default HLL or namespace, respectively, used when creating global symbols. (A global symbol is a function, class, or a global variable.)

Close programs default to compiling in the `close` HLL, in the root namespace. That is,
a function declaration like this
```
   void main() {
      say("Hello, world!");
   }
```

will be compiled into PIR that looks like this.
```
.HLL "close"

.namespace []

.sub "main"
    $P29 = "say"("Hello, world!")
    .return ($P29)
.end
```

(Some details have been removed for clarity.) Notice that the Close compiler automatically generates a `.HLL` directive indicating that the function is part of the `close` HLL. And notice that the default namespace is the empty (root) namespace of the close HLL.

Each Close compilation unit starts in the default HLL: `close` and in the default namespace: `[].`

#### The `hll` directive ####

The `hll` directive resets the default HLL used in generated code. It can be used in two forms. The "statement form" resets the HLL from the current position until the end of the compilation unit, or until another hll directive appears. A statement form directive looks like
```
hll Cobol;

int x;        # x is in Cobol HLL
int f() {     # f is also in Cobol HLL
   return x; 
}
```

Or, you may wish to use the "block form" of the directive. A block form directive includes a set of curly braces ('{ }') to indicate where the specified HLL applies.
```
hll Pascal { 
   int a;     # a is in Pascal HLL
}

int g() {     # g is NOT in Pascal HLL
   return a;
}
```

#### The `namespace` directive ####

The `namespace` directive works in an analogous fashion to the `hll` directive. You can use either a statement form or a block form, and it resets the namespace in which new symbols are allocated.
```
namespace Foo;

int a;

namespace Other::Namespace {
   int b;
}
```

## Variables and arithmetic expressions ##

## PMC types ##

## Functions ##

## Arguments ##

## External symbols and scope ##