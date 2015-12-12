## What is Close? ##

Close is a C-like language for the [Parrot Virtual Machine.](http://www.parrot.org) It is intended to provide a comfortable syntax and development platform for "systems programming" on the PVM -- that is, for writing the sort of low-level subroutines that might otherwise be written in assembly.

Close is the brain-child of Austin Hastings. There is no ISO standard, there was no university project. Resources about Close are therefore limited.

### Close objectives ###

The aim of Close is to provide a programming language that is just as expressive as PIR (the current assembly language for the PVM) and enables nearly identical coding.

Note that this is an "aim." Close isn't there yet. But if you can write it in PIR, you should be able to write it in Close.

### Close example code ###

Here is some example code in Close:
```
void greeting() {
   say("Hello, world!");
}
```

If you have a C or Java background, you will likely be able to read Close from the very start. Learning how to write Close is mostly a question of learning the underlying Parrot architecture well enough to accomplish what you need.

## What is this project? ##

This Google Code project is the repository for the Close compiler source code, plus the run-time library routines, plus some other library code being developed in Close. It is also the issue-tracking tool for reporting bugs and requesting features in the language.

### Close resources ###

Ignoring the **Issues** and **Source** tabs at the top of the screen, the Close wiki contains

  * Close Development
    * Close language & compiler
    * Close Run-Time Library
    * Close Libraries

  * Close Language Documentation
    * The Close Programming Language
      * [Introduction](CloseIntro.md)

  * Close Projects
    * Close Run-Time Library
    * Close Libraries