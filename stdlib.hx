: me get_caster ;
	: my me ;

: entity/eyes entity_pos/eye ;
	: eyes entity/eyes ;
: entity/feet entity_pos/foot ;
	: feet entity/feet ;
: entity/gaze get_entity_look ;
	: entity/look entity/gaze ;
	: gaze entity/gaze ;
: entity/up theodolite ;
: entity/height get_entity_height ;
: entity/velocity get_entity_velocity ;
: entity/name/get string/name/get ;
	: name/get entity/name/get ;
: entity/name/set string/name/set ;
	: name/set entity/name/set ;

: raycast/block raycast ;
: raycast/face raycast/axis ;
: raycast/entity raycast/entity ;

: tostring string/iota ;

: swap swap ;
	EXPAND: 2 swap 
		local x = pop()
		local y = pop()
		push(x)
		push(y) ;
: drop pseudo-novice ;
	EXPAND: 1 "a" pop() ;
# TODO: expansions defined through other words?
: 2drop "SOUTH_EAST" "ada" symbol! ;
	EXPAND: 1 "ada"
		pop() 
		push({
			type = "symbol",
			name = "pseudo-novice",
			pattern = "a",
		}) ;
: 3drop "SOUTH_EAST" "adada" symbol! ;
	EXPAND: 1 "adada"
		pop() 
		push({
			type = "symbol",
			pattern = "ada",
		}) ;
# TODO: ndrop!
: dropd "SOUTH_EAST" "ae" symbol! ;
	EXPAND: 1 "ae"
		local x = pop() 
		push({
			type = "symbol",
			name = "pseudo-novice",
			pattern = "a",
		})
		push(x) ;
: rot rotate ;
	EXPAND: 3 rotate
		local z = pop()
		local y = pop()
		local x = pop()
		push(y)
		push(z)
		push(x) ;
: -rot rotate_reverse ;
	EXPAND: 3 rotate_reverse
		local z = pop()
		local y = pop()
		local x = pop()
		push(z)
		push(x)
		push(y) ;
: dup duplicate ;
	EXPAND: 1 duplicate
		local x = pop()
		push(x)
		push(x) ;
: 2dup 2dup ;
	EXPAND: 2 2dup
		local x = pop()
		local y = pop()
		push(y)
		push(x)
		push(y)
		push(x) ;
# dups n items, unlike gemini that dups 1 item n times
: ndup dup_many ;
# dups an item enough times for there to be n of it at the top (so n-1 dups)
: dupn duplicate_n ;
: dupd over swap ;
: tuck tuck ;
	EXPAND: 2 tuck
		local y = pop()
		local x = pop()
		push(y)
		push(x)
		push(y) ;
: over over ;
	EXPAND: 2 over
		local y = pop()
		local x = pop()
		push(x)
		push(y)
		push(x) ;
: swapd swap_two_three ;
	EXPAND: 1 swap_two_three
		local x = pop()
		push({
			type = "symbol",
			name = "swap",
			pattern = "aawdd",
		})
		push(x) ;
# other name suggestions: "flip", "mirror"
: spin swap_one_three ;
	EXPAND: 3 swap_one_three
		local z = pop()
		local y = pop()
		local x = pop()
		push(z)
		push(y)
		push(x) ;

# t for true
# f for false
# TODO: turn this into a literal
: null const/null ;
	: nil null ;
: == equals ;
: ~= not_equals ;
	: != ~= ;
: + add ;
	EXPAND: 2 add
		local y = pop()
		local x = pop()
		print(x.type)
		print(y.type)
		if x.type ~= y.type then fail() return end
		if x.type == "number" then
			x.value = x.value + y.value
			push(x)
			return
		end
		if x.type == "code" then
			for _,v in ipairs(y.value) do
				x.value[#x.value+1] = v
			end
			-- TODO: trigger expansions on the new boundary
			-- this will require recursive expansions
			push(x)
			return
		end
		fail()
		return ;
: - sub ;
	EXPAND: 2 sub
		local y = pop()
		if y.type ~= "number" then fail() return end
		local x = pop()
		if x.type ~= "number" then fail() return end
		x.value = x.value - y.value
		push(x) ;
: * mul ;
	EXPAND: 2 mul
		local y = pop()
		if y.type ~= "number" then fail() return end
		local x = pop()
		if x.type ~= "number" then fail() return end
		x.value = x.value * y.value
		push(x) ;
: / div ;
	EXPAND: 2 div
		local y = pop()
		if y.type ~= "number" then fail() return end
		local x = pop()
		if x.type ~= "number" then fail() return end
		x.value = x.value / y.value
		push(x) ;
: % modulo ;
: < less ;
: <= less_eq ;
: > greater ;
: >= greater_eq ;
: len abs ;
	: length len ;
: list/push append ;
: list/pop unappend ;
: list/empty { } ;
	: {} { } ;
	: [] [ ] ;
: list/singleton singleton ;
: nlist last_n_list ;
: list/find index_of ;
: list/index index ;
	: list/select list/index ;
: list/replace replace ;
: list/slice slice ;
: list/concat + ;
: list/length length ;

# TODO: const vectors
: 3vec construct_vec ;
: up const/vec/y ;
: down 0 -1 0 3vec ; # FIXME
: vec/dot mul ;
: vec/cross div ;

# num|vec|list -> mat
: mat/make matrix/make ;
	: mat/new mat/make ;
# mat -> num|vec|list
: mat/unmake matrix/unmake ;
	: mat/split mat/unmake ;
	: mat/old mat/unmake ;
: mat/transpose "EAST" "qqqaede" symbol! ;
	: mat/flip mat/transpose ;
: mat/inv matrix/inverse ;
: mat/+ + ;
	: mat/add mat/+ ;
: mat/* vec/dot ;
	: mat/mul mat/* ;


: that/block my eyes my gaze raycast/block ;
	: this/block that/block ;
: that/face my eyes my gaze raycast/face ;
	: this/face that/face ;
: that/spot that/block that/face + ;
	: that/place that/spot ;
	: this/spot that/spot ;
	: this/place that/place ;
: that/entity my eyes my gaze raycast/entity ;
	: this/entity that/entity ;

: impulse add_motion ;

: scale/get interop/pehkui/get ;
: scale/set interop/pehkui/set ;

: property/read observe_property ;
: property/write set_property ;

# valid keys are vectors and entities
# key, iota ->
: idea/write writeidea ;
# key -> iota
: idea/read readidea ;

: call eval ;
	: exec call ;
	EXPAND: 1 eval
		local code = pop()
		if code.type ~= "code" then
			error("can only eval a quotation")
		end
		append(code.value) ;
: choose "SOUTH_EAST" "awdd" symbol! ; # FIXME: importing the stdlib twice fucks with shadowing
	EXPAND: 3 "awdd"
		local fcase = pop()
		local tcase = pop()
		local b = pop()
		if b.type ~= "bool" then return fail() end
		if b.value then
			push(tcase)
		else
			push(fcase)
		end ;
: ifelse choose call ;
: if [ ] ifelse ;
: dip nephthys ;
	EXPAND: 2 nephthys 
		local code = pop()
		if code.type ~= "code" then
			error("can only dip a quotation")
		end
		local preserved = pop()
		append(code.value)
		push(preserved) ;
	: 1dip dip ;
: 2dip "SOUTH_EAST" "deaqqdq" symbol! ;
: 3dip "SOUTH_EAST" "deaqqdqe" symbol! ;
# TODO: ndip!
: calld [ call ] dip ;
: keep over calld ; # like dip but the quotation also sees the value
# apply p and q to x
# calls p with x on the stack, pushes x back to the stack then calls q
# x p q ->
: bi [ keep ] dip call ;
# apply p to x and q to y
# x y p q ->
: bi* [ dip ] dip call ;
# apply p to x and then p to y
# x y p ->
: bi@ dup bi* ;

: min 2dup > [ swap ] if drop ;
: max 2dup < [ swap ] if drop ;

: explode explode ;
	: explosion explode ;
: block/type type/block_item ;
: block/break/raw break_block ;
: block/break dup block/type tostring "Air" != [ block/break/raw ] [ drop ] ifelse ;
	: break/block block/break ;
	: dig block/break ;
: block/place place_block ;
: block/smelt smelt ;
: block/freeze freeze ;
: block/ignite ignite ;
: block/fall falling_block ;
: block/read string/block/get ;
	: read/block block/read ;
: block/write string/block/set ;
	: write/block block/write ;
: conjure/water create_water ;
: conjure/lava create_lava ;
: conjure/block conjure_block ;
: conjure/light conjure_light ;
: conjure/lightning lightning ;
: conjure/mesh conjure_mesh ; # from hexical
: conjure/fireball ghast_fireball ;
: craft/phial craft/battery ;
: craft/cypher craft/cypher ;
: craft/trinket craft/trinket ;
: craft/artifact craft/artifact ;
: craft/hexburst conjure_hexburst ; # edible iota, pushes to wand stack
	: conjure/hexburst craft/hexburst ;
: craft/hextito conjure_hextito ; # edible spell, CASTS AS WAND.
	: conjure/hextito craft/hextito ;
: flight/anchored flight/range ;
	: flight/anchor flight/anchored ;
: flight/timed flight/time ;
: flight/winged flight ;
	: flight/wings flight/winged ;
	: flight/altiora flight/winged ;
	: flight/elytra flight/winged ;
	: wings flight/winged ;
	: winged flight/winged ;
	: altiora flight/winged ;
: weather/clear dispel_rain ; # 5 dust
: weather/rain summon_rain ; # 5 dust
# wristpocket
: pocket wristpocket ; # like /take but with your offhand
: pocket/take sleight ; # takes an item entity
: pocket/place sleight ; # places at a vector
: pocket/eat mage_mouth ;
: pocket/item wristpocket_item ;
: pocket/count wristpocket_count ;
: pocket/use mage_hand ;

# does a bunch of different things
# entity/vector ->
: trick prestidigitation ;

: compose list/concat ;
# takes a thing on the stack and makes a quotation that pushes it to the stack
# TODO: "bubble" data type for when bubble is given a literal
# should compile to "literal then bubble" when in doubt
# and otherwise treated exactly like numeric symbols
# but expansion of list/singleton will know to get rid of the bubble
# IDEA: code literally is just a list of symbols
# there is no difference between lists and quotations
# so I should rethink literals
# (\4 instead of 4)
# PROBLEM: (typos) and optimizations will mess with lists
# RESOLUTION: lists and code should be separate types
# and specifically here it should be list/singleton
# doing the coersion when it sees a symbol or bubble
# (with the coerse function being provided by hexc.lua)
# PROBLEM: when a list and a closure are concatenated what do we do? is it a list or a closure?
: quote bubble list/singleton ;
: curry [ quote ] dip compose ;
# equivalent to `curry curry`
: 2curry rot quote rot quote rot compose compose ;
: 3curry 2curry curry ;

: raven/read read/local ;
	: read/raven raven/read ;
: raven/write local ;
	: write/raven raven/write ;
: soroban/inc soroban_increment ;
: soroban/dec soroban_decrement ;

: zone/extinguish extinguish ;
	: area/extinguish zone/extinguish ;
: zone zone_entity ;
: zone/animal zone_entity/animal ;
: zone/not_animal zone_entity/not_animal ;
: zone/monster zone_entity/monster ;
: zone/not_monster zone_entity/not_monster ;
: zone/item zone_entity/item ;
: zone/not_item zone_entity/not_item ;
: zone/player zone_entity/player ;
: zone/not_player zone_entity/not_player ;
: zone/living zone_entity/living ;
: zone/not_living zone_entity/not_living ;
: zone/type zone_entity/type ;
: zone/not_type zone_entity/not_type ;
: zone/wisp zone_entity/wisp ;
: zone/not_wisp zone_entity/not_wisp ;


: mind/flay brainsweep ; # 100 dust
	: flay/mind mind/flay ;
: mind/instill reviveflayed ; # 160 dust for a villager

: gate/new gate/make ; # 320 dust
: gate/open gate/mark ;
: gate/close gate/close ;
# gate, entity -> tp entity to gate
: tp dupd gate/open gate/close ;
: tp/me me tp ;

# entity number ->
: blink/lesser "SOUTH_WEST" "awqqqwaq" symbol! ;
# vec ->
: blink/greater greater_blink ;
# blinks you a given distance, uses greater blink because it's cheaper
# number ->
: blink 0 0 rot 3vec blink/greater ;

# vec entity -> vec
: coordinate-transform 
	[ entity/gaze ] [ entity/up ] bi 
	2dup vec/cross 
	spin 3 nlist mat/new mat/inv swap * mat/old ;

# takes an offset vector (in xyz base) and blinks you according to that
# vec ->
: blink/rel me coordinate-transform blink/greater ;
# takes an absolute position (in xyz base) and blinks you to that spot
# vec ->
: blink/abs my feet - blink/rel ;

# pos, dir ->
: missile/rel [ me coordinate-transform ] dip magic_missile ;
# pos, dir ->
: missile/abs [ my eyes - ] dip missile/rel ;

: stack/size stack_len ;
	: stack/len stack/size ;
# clear the whole stack
: stack/clear sekhmet ;
	: clear stack/clear ;
# only leaves the top iota of the stack
# TODO: stack/top_n
: stack/top "SOUTH_WEST" "qaqddq" symbol! ; # hexical metaeval
# turns the entire stack into a single list
# `[ stack/wrap ] dip` works as expected
: stack/wrap stack/size nlist ;
	: stack/pack stack/wrap ;
: stack/unwrap splat ;
	: stack/unpack stack/unwrap ;

: . "NORTH_EAST" "de" symbol! ;
: print . drop ;
# print the whole stack
: .. stack/size last_n_list . splat ;

# TODO: Athena (advanced metaeval)
# TODO: blackboxes
	# practically just sets of hashes, though

# looping options:
# - thoth
	# seshat?
	# pollux/castor's?
# - sisyphus
# - heket (hextweaks utility)
# - iris??? (cursed, semantically a jump but implemented as a continuation for "the rest of the program" that does not return)
# - cassettes

: thoth for_each ; # cursed
: continue atalanta ; # skips end of this iteration to go to the next one
: sisyphus sisyphus ; # while true loop exited with `break`
: heket "NORTH_EAST" "wdwadad" symbol! ; # hextweaks utilities, loops while the top of the stack is truthy
: iris eval/cc ; # the most cursed of them all
: terminate janus ; # breaks through everything
# FIXME: CHARON'S BREAKS HERMES
# either find a new charon's, a new hermes, or just use iris
: halt [ ] sisyphus ;

# applies a hex to every value of a list, *resetting* the stack after each iteration
# for every iteration only returns what is on the top of the stack instead of the whole stack
# list quotation -> list
: map [ stack/top ] compose swap thoth ;

# applies a qutation to every values of a list, keeps the ones for which the quotation returns true
# list quotation -> list
: filter [ keep swap [ stack/top ] [ stack/clear ] ifelse ] curry swap thoth ;

# executes quotation that many times, *maintaining* the stack after each iteration
# num quotation ->
: times swap floor 0 max [
	dupd [ call ] 2dip 1 sub
] heket 2drop ; 

# stack, quot -> stack
# calls the quotation while nullifying its stack effect
# only 6 symbols if given a literal quotation
: 0preserving [ drop ] swap compose [ clear ] compose null list/singleton thoth drop ; 
# stack, quot -> stack, any
# the same but pushes the last output of the quotation
: 1preserving [ drop ] swap compose [ stack/top ] compose null list/singleton thoth splat ; 

# start end quotation -> executes quotation on values of range, *resetting* the stack after each iteration
# TODO: implement this with thoth and pollux's/castor's to get rid of the 0preserving
: ranged -rot over sub floor 1 add 0 max [
	# stack is {quotation, iterator, steps left}
	[ swap dup [ 0preserving ] dip swap 1 add ] dip 1 sub
] heket 3drop ; 

# takes a quotation, curries it with a fixed version of itself
# the resulting quotation only contains the original one once
: fix [ dupd [ dup call ] 2curry swap call ] [ dup call ] curry curry ;
# a more understandable version, this one contains the original quotation twice so it's not to be used
: fix/simple [ dup curry ] swap compose dup curry ;

# takes and returns a number
: fib 1 0 rot [ over add swap ] times dropd ;
# recursion demo
: fib/recursive [ over 1 > [ 2dup [ 1 - ] dip call -rot [ 2 - ] dip call + ] [ drop ] ifelse ] fix call ;


: conjure/liquid dup conjure/water dup block/type tostring "Air" == [ conjure/lava ] [ drop ] ifelse ;
# takes coords, makes a safe explosion there that only damages entities (still breaks item frames though)
: implode 5 dupn
	block/break
	conjure/liquid
	10 explode
	conjure/block
	block/break ;

# code, delay, identifier ->
: cassette/enqueue enqueue ;
	: tape/enqueue cassette/enqueue ;
# identifier ->
: cassette/dequeue dequeue ;
	: tape/dequeue cassette/dequeue ;
	: kill cassette/dequeue ;
# ->
: cassette/disqueue killall ;
	: tape/disqueue cassette/disqueue ;

# calls your code immediately through a cassette
# code ->
: cassette/call 0 random cassette/enqueue ;
	: tape/call cassette/call ;

# will make the spell enqueue itself automatically after running
# first iteration runs immediately
# code, delay, identifier ->
: cassette/loop [ 
	# stack is {self, action, delay, identifier}
	rot 3dip cassette/enqueue
] 3curry fix cassette/call ;
	: tape/loop cassette/loop ;

# identical to cassette/loop but does not stop looping on a mishap
: cassette/loop/robust [ 
	# stack is {self, action, delay, identifier}
	rot [ cassette/enqueue ] dip call
] 3curry fix cassette/call ;
	: tape/loop/robust cassette/loop/robust ;

# uses a cassette to sleep a number of seconds
# moves the entire stack and the rest of the spell
# to the cassette when it does so
# FIXME: this currently does not work inside loops
# although there's not much I can do about it since it's an iris bug
# secs ->
: sleep 20 *
	# desired state: 
	# [ [ list/singleton {delay} random cassette/enqueue terminate ] iris {stack} stack/unwrap ] call
	[ [ list/singleton ] dip random cassette/enqueue terminate ] curry [ iris ] curry
	[ stack/wrap [ stack/unwrap ] curry ] dip
	swap compose call
;
# TODO: the above code would very much benefit from fried quotations

