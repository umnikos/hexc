"stdlib.hx" loadfile!

: amethyst
	-3 5 [ 
		0 2 [ 
			-8 0 [ 
				3vec
				-71 56 -1915 3vec + # base offset
				..
				dup block/type tostring "Amethyst Cluster" ==
				..
				[ block/break ] if 
			] ranged
		] ranged
	] ranged ;
	

