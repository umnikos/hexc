
> [!Warning]
> This document describes what is (currently) the *plan* for what the final language should look like, NOT what it actually looks like.

This is a concatenative language...
```
2 3 5 + 7 *
--> 2 56
```
of the functional kind.
```
[ 3 + ] 2 swap call
--> 5
```
It is also a compiled language. All of the above does not execute during compile time but is instead translated into hex patterns, also called symbols.
All symbols are words (functions), but beyond that words can be defined as a sequence of other words. The following code first defines an `inc` word before using it to increment the number 5:
```
: inc 1 + ; 5 inc
--> 6
```
Words that merely get compiled like this are ordinary words.

*Macros* are words that execute during compile time. They work exactly like regular words, but when encountered are immediately evaluated using whatever was previously read
```
5 3 print!
-! "3" is printed during comptime
--> 5
```
The macros in hexc have several limitations that might make them less powerful but also make them way easier to reason about:
  1. Macros do not and cannot define new syntax
  2. Macros only work on literal values passed to them beforehand
  3. A quotation is defined purely by its action, not its source code or the list of symbols it compiles to. Hence macros cannot do (or at least should not do) inspection of any quotations' internals.

A macro, when not given enough literal values to act, may force execution of regular words as well.
```
2 3 * 5 + print!
-! "11" is printed during comptime
-->
```

To prevent a macro from executing immediately, quote it with `[[ ]]` instead.
```
5 [[ 3 print! ]]
-! compilation error
```
Macros cannot be compiled down to hex patterns, and for that reason macro quotations also cannot be compiled down to hex patterns.
Thus when a top-level macro quotation is found it forces execution of words after itself like `call` and `if` to eventually expand the quotation.
```
5 2 < [[ "yes" print! ]] [[ "no" print! ]] ifelse
-! "no" is printed during comptime
-->
```
This mechanism is what allows hexc's very simple macros (which are basically just string replacement) to be way more powerful than an equivalent C preprocessor macro, allowing for conditional execution and looping.

New words can be defined with the `def!` macro, or with the equivalent `: ... ;` syntactic sugar. 
```
[ 3 ] "a" def!
: b 5 ;
a b +
--> 8
```
Normal words are inlined and thus cannot have recursive definitions.

New macros can be defined with the `defmacro!` macro, or with the equivalent `:: ... ;;` syntactic sugar.
```
:: print-twice! dup print! print! ;;
```
Macros are allowed to have recursive (even mutually recursive) definitions.

Compile-time execution of regular words is done not through any actual execution (casting hexes), but through simulation instead.
Such simulated effects are defined on a per-symbol basis, either in lua with the `SIMULATE:` syntax or in hexc itself with the `simulate!` macro.
The following simulation is a (partial) simulation of the `+` word in lua:
```
SIMULATE: add
  local y = pop()
  local x = pop()
  if x.type == "number" and y.type == "number" then
    x.value = x.value + y.value
    push(x)
    return
  end
  fail()
;
```
And the following is a simulation of `2dup` in hexc:
```
"2dup" [ over over ] simulate! drop
```

Simulations can only be defined for pure words (words with no external effects).

Simulations are also to be used when the particular symbol used cannot be found in the symbol registry.

Expansion of non-macro words when it's given enough literal values is also done as a form optimization, and this is called a reduction. A word that has a simulation defined can have reductions enabled for it using the `reduce!` macro, by passing the word name and how many literal arguments are needed. For example, here's a simulation of the `2drop` symbol that turns into `drop drop` when given one or more literal arguments:
```
"2drop"
  [ drop drop ] simulate!
  1 reduce!
drop
```

Symbols that do not have a pattern in the symbol registry can be defined using the `symbol!` macro, which pushes said symbol as a literal. (`call` will work to turn it into a non-literal)
```
"SOUTH_WEST" "qaqddq" symbol!
  "stack/top" alias!
  [ [ stack/clear ] dip ] simulate!
  1 reduce!
drop
```


The third and final kind of parentheses is the one for list literals, and apart from being sugar for `nlist` it also forces immediate execution of words inside.
```
{ 1 2 3 + 10 }
--> { 1 5 10 }
```
