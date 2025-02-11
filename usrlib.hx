"stdlib.hx" loadfile!

# makes a light at your feet if you're standing in pitch darkness
# useful while mining
: lamp [ 
	my feet dup get_light 7 < [ conjure/light ] if 
] 20 "lamp" cassette/loop ;

# casts `gasp` roughly when you're about to start drowning
: breathing [
	my breath # max is 300, not 20. minimum is negative
	0 <= [ me gasp ] if
] 10 "breathing" cassette/loop ;

# reads and casts whenever you press G (telepathy button)
: cad [
	get_telepathy 0 == [ click read call ] if
] 1 "cad" cassette/loop/robust ;
