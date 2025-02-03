: me get_caster ;
	: my me ;

: entity/eyes entity_pos/eye ;
	: eyes entity/eyes ;
: entity/feet entity_pos/foot ;
	: feet entity/feet ;
: entity/gaze get_entity_look ;
	: entity/look entity/gaze ;
	: gaze entity/gaze ;
: entity/height get_entity_height ;
: entity/velocity get_entity_velocity ;

: raycast/block raycast ;
: raycast/face raycast/axis ;
: raycast/entity raycast/entity ;

: tostring "EAST" "wawqwawaw" symbol! ;

: swap swap ;
	EXPAND: 2 swap 
		local x = pop()
		local y = pop()
		push(x)
		push(y) ;
: drop pseudo-novice ;
	EXPAND: 1 pseudo-novice pop() ;
: 2drop "SOUTH_EAST" "ada" symbol! ;
: 3drop "SOUTH_EAST" "adada" symbol! ;
# TODO: ndrop!
: dropd "SOUTH_EAST" "ae" symbol! ;
# TODO: expansion for symbol! macros?
# - probably by being able to define new named symbols in the symbol table instead of this
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
# dups n items, unlike gemini that dups 1 item n times
: ndup dup_many ;
# dups an item enough times for there to be n of it at the top (so n-1 dups)
: dupn duplicate_n ;
: dupd over swap ;
: tuck tuck ;
: swapd swap_two_three ;
# FIXME: give this a better name
: 13swap swap_one_three ;

# t for true
# f for false
# TODO: turn these into literals
: null const/null ;
	: nil null ;
# TODO: const vectors

: 3vec construct_vec ;

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
: < less ;
: <= less_eq ;
: > greater ;
: >= greater_eq ;
: len abs ;
	: length len ;
: list/push append ;
: list/pop unappend ;
: list/empty empty_list ; # TODO: this should just be { } and not a word
: list/singleton singleton ;
: nlist last_n_list ;
: list/find index_of ;
: list/index index ;
	: list/select list/index ;
: list/replace replace ;
: list/slice slice ;
: list/concat + ;
: list/length length ;

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

: explode explode ;
	: explosion explode ;
: block/type type/block_item ;
: block/break break_block ;
: block/place place_block ;
: block/smelt smelt ;
: block/freeze freeze ;
: block/ignite ignite ;
: block/fall falling_block ;
: conjure/water create_water ;
: conjure/lava create_lava ;
: conjure/block conjure_block ;
: conjure/light conjure_light ;
: conjure/lightning lightning ;
: conjure/mesh conjure_mesh ; # from hexical
: craft/phial craft/battery ;
: craft/cypher craft/cypher ;
: craft/trinket craft/trinket ;
: craft/artifact craft/artifact ;
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

: call eval ;
	: exec call ;
	EXPAND: 1 eval
		local code = pop()
		if code.type ~= "code" then
			error("can only eval a quotation")
		end
		append(code.value) ;
: choose "SOUTH_EAST" "awdd" symbol! ; # FIXME: importing the stdlib twice fucks with shadowing
# TODO: expansion for this once you make boolean literals
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
: 2dip "SOUTH_EAST" "deaqqdq" symbol! ;
: 3dip "SOUTH_EAST" "deaqqdqe" symbol! ;
# TODO: ndip!
: calld [ call ] dip ;

: min 2dup > [ swap ] if drop ;
: max 2dup < [ swap ] if drop ;

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

: read/raven read/local ;
	: raven/read read/raven ;
: write/raven local ;
	: raven/write write/raven ;
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
: tp/entity dupd gate/open gate/close ;
: tp me tp/entity ;

: stack/size stack_len ;
# clear the whole stack
: stack/clear sekhmet ;
	: clear stack/clear ;
# only leaves the top iota of the stack
# TODO: stack/top_n
: stack/top "SOUTH_WEST" "qaqddq" symbol! ; # hexical metaeval
: heket "NORTH_EAST" "wdwadad" symbol! ; # hextweaks utilities

: . print ;
# print the whole stack
: .. stack/size last_n_list . splat ;


# looping options:
# - thoth
# - sisyphus
# - heket (hextweaks utility)

: thoth for_each ;

# num quotation -> executes quotation that many times, *preserving* the stack after each iteration
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

# start end quotation -> executes quotation on values of range, *restoring* the stack after each iteration
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


# takes coords, makes a safe explosion there that only damages entities (still breaks item frames though)
: implode 5 dupn
	block/break
	conjure/lava # TODO: use this only in the nether, not always (costs 10 dust when the explosion is 30)
	10 explode
	conjure/block
	block/break ;

