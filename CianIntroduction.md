# Introduction #

Close is a systems programming language for the Parrot Virtual Machine.

If you are willing to work pretty hard at figuring things out, that sentence tells you everything you need to know about Close, and whether you want to learn it. If you're still not sure, well, that's what the rest of this e-book is all about.

To start with, Close is a "systems programming" language -- the kind of programming sometimes described as "close to the metal." The aim of Close is to write libraries, weird startup routines, and performance-intensive software, _without_ having to write in PIR (see below). A secondary goal of Close is to look like C or C++ whenever possible, to make it easy for programmers to start using Close.

Close would not exist without, and has no meaning outside of, the Parrot Virtual Machine. You can find out more about Parrot below, as it relates to Close. Or you can find out a _lot_ more about Parrot at the official Parrot website: www.parrot.org. No compilers for Close exist outside of the Parrot VM, and none are intended -- most other platforms already have a low-level, high-performance systems programming language, called 'C'.

Close is a systems programming language for the Parrot Virtual Machine.

If you're still interested, read on.

## Why Close? ##

"Why Close?" is actually two questions in one. The easiest one to answer is "Why did you pick the name 'Close'?" The name came out in a phone conversation -- I was describing the language to a friend of mine, and I said, "It's not 'C', but it's ... close." The fact that it's aimed at programming "close to the machine" just seals the deal.

The second question is "Why should I use Close?" This is a subjective question -- your opinion may differ from mine. But my stock answer is, "because the alternative is programming in PIR (assembly)."

Close is intended to provide the same service to Parrot users that C provides to other programmers -- provide a language that abstracts much of the machine details, but enables access to as many of the machine's capabilities as is feasible. Close is not intended to compete with Perl, but rather with PIR (the Parrot assembly language).

## Close 'gotcha's ##

There are three different kinds of potential "gotchas" in Close programming.

  * Differences between the behavior of Close and of C.

> Close is based on C, but some things are inevitably different. For example, you cannot take the address of a variable. (If you really know C, and you think about it for a moment, you'll understand just exactly how much has to be different because of this. That's why it's "Close" and not "C for Parrot".)

> When the behavior of Close differs from C or C++ in a _surprising_ way, those gotcha's will be identified in the text.

  * Differences between Close and PIR.

> These break down into a couple of categories. I generally don't worry about "not implemented." That's not a gotcha, it's either a scheduling issue or a deliberate design decision on my part.

> But there are times when the behavior of Close will **not** be the same as the behavior of PIR. Those gotcha's will be indicated in the text.

  * Differences between Parrot and the C hardware model.

> As discussed below, C assumes a certain hardware model. That model is significantly different from the Parrot VM. (For example, no taking the address of a variable!) When this causes surprising behavior in Close, those gotcha's will be indicated in the text.

## Parrot VM ##

The Parrot Virtual Machine is a VM aimed at supporting dynamic languages like Perl 6 and Python. You can find out about Parrot at www.parrot.org.

## Parrot Hardware Model ##

Parrot is aimed at dynamic languages, so the Parrot opcodes are targeted that way. This can be surprising if your background is 'vanilla' C or C++. Most C programmers will never have seen a _closure,_ whereas Parrot has a dedicated opcode for creating new closures.

### Registers ###

To start simply, Parrot is a register-based architecture, just like most modern CPU's. And Parrot has registers of different types, just like a CPU. Parrot has an infinite number of registers, though. And the types are a little unusual.

Parrot's register types are: `integer, numeric, string, and pmc.` Integer registers are what you may already be used to in a CPU - they store numbers, and can increment, decrement, add, subtract, etc. Numeric registers store floating-point numbers, and just like on every other CPU, nobody pays much attention to them.

String registers store strings. But that's all. On a conventional CPU, the 'string registers' are special pointer registers that are still fundamentally integers. On Parrot, the string registers point to strings. And strings are a special data type, not C strings, so you can't just point into the middle of one. In fact, you can't do any kind of arithmetic on a string pointer, except checking for equality and null. (IMO, Parrot's strings are poorly thought out. They're not super-low-level enough for speed, and they're not high-level enough for HLL-fu.)

PMC registers are like string registers - they store PMC's, and that's all they do. You can assign them - called binding, for reasons which will become clear later, do simple tests on them, or use opcodes that invoke vtable functions or named methods. And that's it.

### PMCs ###

_What's a PMC?_ you ask. Well, a PMC is whatever you make of it. Back in the day, when Parrot was young and the development team was optimistic, PMC stood for "Parrot Magic Cookie." Basically, a PMC is a pointer to an object - any kind of object. It's a "magic cookie" because you pass around the PMC, which identifies the object, but there's no guarantee that the PMC is a pointer. It could be an array index, a cryptographic signature, a string key into a database. But it doesn't matter, because you never actually look at the innards of the thing. You just put it into a register and then tell it, via operations performed on the register, to do things. "Increment yourself by one," or "append this other value to the list you are keeping."

In short, PMCs are objects. Or object-handles. Whatever. They're how nearly all of the "high level" work gets done on the Parrot platform. You don't write code that says "Increment the index and store this into the array that we're using as a stack." Instead, you create a ResizeablePMCArray object (PMC), and invoke the .push() opcode on it. Presto, a stack!

There are PMCs for a lot of things, including some things that there probably shouldn't be PMCs for. There are file handle PMCs, resizable array PMCs, really-big-number PMCs, network socket PMCs. If you need something done, there's probably a PMC for it. If there's not, well, there's an API for writing new PMCs and a lot of help available on [irc://irc.parrot.org/parrot](irc://irc.parrot.org/parrot).

### Namespaces ###

Namespaces are a way of partitioning your code and data so that your symbols -- function and variable names -- do not conflict with the symbols used by other authors. Nearly all recently-developed programming languages provide some kind of namespace analogue. Java calls them packages, C++ has namespaces, Perl has packages, etc.

Namespaces in Parrot form a graph. Technically, it should be a tree, but there's a Namespace PMC and an API of methods for accessing and creating namespaces, so who knows what might happen? But in practice, and for our purposes, namespaces are a tree.

Parrot mandates that the top level of namespaces are for the use of the HLLs - the programming languages that generate code. Thus a package called A written in Perl will be in the $root/perl/A namespace, while a package A written in Ruby would be in the $root/ruby/A namespace. Of course, Perl for Parrot is called Rakudo, and Ruby for Parrot is called Cardinal, but you get the idea.

What is important, from a Close perspective, are two things. First, _everything_ is in a namespace. If you don't specify a namespace, one is provided for you. And that applies to all code, no matter who generated it. Code written in PIR goes into the $root/parrot namespace by default. Code written in Close goes into the $root/close namespace by default.

Second, is that Close gives you control over what namespace, and what HLL, your code is a part of. Part of the syntax of the language allows for specifying whatever HLL or namespace you want. Of course, the _syntax_ is still close, but the resulting functions or data will be emitted in whatever namespace you specify.
```
namespace hll: c :: {
    String strcpy(String dest, String src) {
        dest = src;   // What? They're pmcs - of course this works!
    }
}
```
In the example above, the 'strcpy' function would be compiled into the HLL root namespace of the 'c' HLL.
```
.HLL 'c'
.namespace []
.sub 'strcpy'
    .param pmc dest
    .param pmc src

    assign dest, src

    .return (dest)
.end
```
This PIR code looks nothing like what would be generated (generated code is always full of generated names and temporary numbers) but conveys roughly what Close will produce.

### Package Scope ###

Parrot associates every "top level" object with a namespace. These top levels are namespaces, and they are simpler than you probably think. The easiest way to think of a namespace is as a Perl hash. When a function is loaded, or created, or somehow comes into being, it gets added to some namespace. If you happened to already have a namespace by that name, and there was stuff in it, the new function joins the stuff -- now you have **more** stuff. (If you have stuff with the same name, then there's a bunch of possible behaviors. Ignore this for now.)

This is the 'global variable' context for Parrot. This is the context that _subs_ (Parrot's name for functions) exist in. In fact, a sub is just another global variable -- there is only one namespace for 'symbols'. This namespace is the 'package' scope, and once your code is loaded into the Parrot VM it can reference symbols by name in this scope, regardless of execution order. This is akin to 'extern' scope in C and C++.

_**Gotcha:**_ (Hardware) There is no facility for providing an initial value for package scope values other than subs. As a result, _there are no global symbols other than subs._ While it is possible to store a "value" to a symbols at package scope, there is no way to define that symbol in the compiled bytecode. Instead, the symbol must be set up, and any initialization performed, at load time (for bytecode files) or compile time (for eval) using a special sub. Close does this automatically for initializers attached to `extern` objects.

### Lexical variables ###

Within a function, everything is manipulated using registers. This is the same as most CPU models. But Parrot provides some special support for 'lexical' variables. This support takes the form of special PMCs called LexPad and LexInfo that remember an association between particular register numbers and textual variable names.
```
    # ...
    $P0 = find_lex 'foo'
    # ...
```
This code does some surprising things. First, keep in mind that all lexical variables are PMCs. There are no lexical ints, or lexical strings. If you want to store an integer, it goes into an 'Integer' PMC. Same for any other register type. Parrot provides PMC versions of the "basic types," and these are the forms that HLL implementors are expected to use for their variables.

Since PMCs are object _references,_ it's fine if two registers refer to the same object. When you use the `find_lex` opcode to refer to a pre-existing lexical variable, Parrot looks up the name, determines where that PMC is stored, and hands you a reference to it. When you use `store_lex` the reverse happens.

This behavior immediately calls for a discussion of _closures._ Wikipedia has a pretty good article on the subject, and Simon Cozens wrote an even better [practical article](http://www.perl.com/pub/a/2002/05/29/closure.html) on perl.com. Here's an excerpt, illustrating the tricky nature of the beast:
```
sub make_counter {
    my $start = shift;
    return sub { $start++ }
}

my $from_ten = make_counter(10);
my $from_three = make_counter(3);

print $from_ten->();       # 10
print $from_ten->();       # 11
print $from_three->();     # 3
print $from_ten->();       # 12
print $from_three->();     # 4
```
The key point is that Parrot supports this, using lexical variables, at the opcode level. _How_ Parrot supports this is black magic, but it means that your program's "call stack" might look like a tree, because some closure forces an earlier version of the stack to stay around in memory so that some lexical variables will stay available.

### Subroutines ###

Oh frabjous day! Subroutines are pretty much exactly what you expect. A subroutine is the only thing that can be loaded from disk. All Parrot code, data, etc., travels in subroutines. But you know this, from reading the sections above.

Subroutines can have attributes attached to them using _adverbs._ The convention used in Perl6, and therefore used in PIR, and therefore used by Close, is that adverbs look like `:init` or maybe `:subid('foo')` if they need an argument. Each adverb is magickal, and causes your program to misbehave in unusual ways. They're documented later.

## PIR - Parrot Assembly ##

Like all the parts of Parrot, PIR is documented at www.parrot.org. In fact, there's even an O'Reilly book on the subject. But the fact remains that Parrot Assembly is still Assembly, and there were some pretty good reasons given for moving away from assembly and towards high-level languages back in the 1960's. Those reasons are still valid. Which is yet another reason why Close exists.


---


<table>
</table>
| [Previous: Contents](CianToc.md) | &nbsp; | [Next: Language Basics](CianLanguageBasics.md) |
|:---------------------------------|:-------|:-----------------------------------------------|