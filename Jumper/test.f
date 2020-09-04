
: FOX  0 BORDER 
	0 PAPER 
	2 INK 
	1 BRIGHT 
	CLS EI 4 0 DO 
			I 128 + SPN ! 
			I 4 * COL  ! 
			0 ROW ! 
			PUTBLS 
		LOOP 
		4 ROW ! 
		0 COL ! 
		BEGIN 
			4 0 DO 
				I 128 + SPN ! 
				PUTBLS 
				10 0 DO 
					HALT
				LOOP 
			LOOP 
		AGAIN ;