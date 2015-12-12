_"Release early, release often."_ is the mantra of open source. That, plus some pressure from Andrew Whitworth, is why Close is already available here on GoogleCode. But that means that Close isn't finished -- what FOSS project ever is, really? -- and so this page exists to document what the plan is for developing Close.

# Upcoming Milestones #

## 0.2: Rewrite PCT library ##

The next step in growing Close is to rewrite the entire PCT library. This should pretty thoroughly show that Close can be used to write useful code. Completing this milestone should mark the general availability of Close.

### Requirements ###

  * A spec for the entire PCT suite.
  * More features in Close?

## 0.3: Extend PCT to support non-PMC registers ##

Presently, PCT expects all of the variables and values it deals with to be processed in PMC registers. That is, if you specify an assignment of a constant value "1" to a variable "x", PCT generates code like:
```
    $P0 = new 'Integer'
    $P0 = 1
    $P1 = $P0
    store_lex "x", $P1
```
But for Close, which expects to be able to dictate the types of the variables you create using the full register set of Parrot, this won't work. So we need to extend PCT somehow so that (for example) setting the "register type" on an expression, or variable, or whatever, will cause the correct register space to be used. Thus, the code above should have been something like:
```
    .local int x
    x = 1
```

### Requirements ###

  * I have no idea.

## 0.4: Type checking ##

Presently, all variable types secretly resolve to PMC, and no type checking is done. (Because I don't know how.) At some point, that needs to get fixed. Once variables can be typed, static type checking will be needed.

### Requirements ###

  * Austin has to go to compiler school.

# Completed Milestones #

Boy, am I happy to be creating this section. :)

## 0.1: Rewrite PCT::Node ##

### Completed: 05 July, 2009 ###

Patrick Michaud's Parrot Compiler Toolkit really is the greatest thing since sliced bread. And the PCT::Node class is the root class that most of the rest of the system uses. Since I need to get some changes made to PCT for later milestones, I've chosen the ability to replace this one single file (`$PARROT/compilers/pct/src/PCT/Node.pir`) as the definition of release 0.1 of Close.

### Requirements ###

  * A spec for PCT::Node. Ideally in the form of a test framework.
  * A test framework for testing Close against PIR code.
  * Some more features in Close, but which ones?

### Notes ###

The release was created at [r45](https://code.google.com/p/close/source/detail?r=45). I added the `pct/PCT/Node.c=` file under `library/` directory, and created unit test code under `t/library/pct/...`