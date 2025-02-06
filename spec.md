
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
It is also a compiled language. All of the above does not execute during compile time but is instead translated into hex patterns.
Words that merely get compiled like this are ordinary words.

*Macros* are words that execute during compile time. They work exactly like regular words, but when encountered are immediately evaluated using whatever was previously read
```
5 3 print!
-! "3" is printed during comptime
--> 5
```
Macros do not and cannot define new syntax.

To prevent a macro from executing immediately, quote it with `[[ ]]` instead. The quotation can be expanded with either `call!` or just `call`
```
5 [[ 3 print! ]] call
-! "3" is printed during comptime
--> 5
```

New words can be defined with the `def!` macro, or with the equivalent `: ... ;` syntactic sugar.
```
[ 3 ] "a" def!
: b 5 ;
a b +
--> 8
```

New macros can be defined with the `defmacro!` macro, or with the equivalent `:: ... ;;` syntactic sugar.
```
:: print-twice! dup print! print! ;;
```
All words are inlined and thus cannot have recursive definitions.

A macro, when not given enough literal values to act, may force execution of regular words as well.
```
2 3 * 5 + print!
-! "11" is printed during comptime
-->
```
Macros are allowed to have recursive (even mutually recursive) definitions.

This execution is done not through any actual execution (casting hexes), but through simulation instead.
Such simulated effects are defined on a per-word basis with the `SIMULATE:` syntax.
The following simulation is a (partial) simulation of the `+` word:
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

Simulations can thus only be defined for pure words (words with no external effects).
