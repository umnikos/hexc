"stdlib.hx" loadfile!

# makes a light at your feet if you're standing in pitch darkness
# useful while mining
: lamp [ 
	my feet dup get_light 7 < [ conjure/light ] if 
] 20 "lamp" cassette/loop ;

