( Fox game - an unfinished game that could make my fortune if I can send it back in time to 1984 )
( ... finish it )

( some variables for tracking how much of the dictionary we have consumed )
( so we can tell how near we are from treading on the computation stack )

( sprite numbers are explicit in the code rather than in symbolic constants )
( constants are quite expensive in Forth, so horrible though it is, )
( sprite numbers in tyhe code are all just given as literals )
(                                                                 )
(                                                                 )
( 1-4           walking fox, 4 frame                              )
( 5             jumping fox                                       )
( 6             Tile sheet, rows are tiles, columns are screens   )
(               Row 0     - empty                                 )
(                   1     - solid blocks all movement             )
(                   2     - semi-solid - can be walked on/through )
(                   3     - conveyor belt                         )
(                   4-5   - hazards                               )
(                   6-13  - tiles in different states of collapse )
(                   7-10  - baddy 1                               )
(                   11    - key                                   )
(                   12    - door                                  )
(                   13    - level data                            )
(                   14-17 - baddy2                                ) 
(                                                                 )
( The following are created externally:                           )
(                                                                 )
( 128-131       fox right facing, shifted                         )
( 144-159       fox right facing, jumping                         )
( 160-163       for left facing, shifted                          )
( 176-191       fox left facing, jumping                          )
(                                                                 )
( 251           decompressed tile map                             )
( 252           temp tile used as window into sheet               )
( 253           composition buffer for fix sprite                 )
( 254           background sprite built from tile map             )


0 VARIABLE LASTHERE 
0 VARIABLE FIRSTHERE 

HERE DUP LASTHERE ! FIRSTHERE !

	
." sprite creation " HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 

( some assembly - mainly for multiplies and divides ) 

HEX

: UNROLL-RSHIFTS 0 DO  CB C, 2C C, 
					  CB C, 1D C,  LOOP ;
					  
: UNROLL-LSHIFTS 0 DO  CB C, 15 C, 
					   CB C, 14 C,  LOOP ;

: 8MODX CREATE ;CODE E1 C, 
					26 C, 0 C,
					3E C, 7 C,
					A5 C,
					6F C,
					E5 C,
					C3 C, 45 C, 61 C, 
				SMUDGE
							
					
: /2X  CREATE ;CODE E1 C, 
					AF C,
					1 UNROLL-RSHIFTS
					E5 C,
					C3 C, 45 C, 61 C, 
			  SMUDGE
			  
: *2X  CREATE ;CODE E1 C, 
					AF C,
					1 UNROLL-LSHIFTS
					E5 C,
					C3 C, 45 C, 61 C, 
			  SMUDGE
			  
: *64X  CREATE ;CODE E1 C, 
					AF C,
					6 UNROLL-LSHIFTS
					E5 C,
					C3 C, 45 C, 61 C, 
			  SMUDGE
			  
			  
: /8X  CREATE ;CODE E1 C, 
					AF C,
					3 UNROLL-RSHIFTS
					E5 C,
					C3 C, 45 C, 61 C, 
			  SMUDGE
			  
: /8-1X  CREATE ;CODE E1 C, 
					AF C,
					3 UNROLL-RSHIFTS
					2B C,
					E5 C,
					C3 C, 45 C, 61 C, 
			  SMUDGE
			  
: X0! CREATE ;CODE 	E1 C, 
					36 C, 0 C,
					23 C,
					36 C, 0 C,
					C3 C, 45 C, 61 C, 
				SMUDGE
					
					
			  
/2X  /2 SMUDGE

/8X  /8 SMUDGE 
 
*2X *2 SMUDGE 

*64X *64 SMUDGE 
 
/8-1X /8-1 SMUDGE

X0! 0!  SMUDGE 

8MODX 8MOD SMUDGE

DECIMAL 

." custom assembly " HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 

( some forth words to define structures and arrays )

: <STRUCT 
	<BUILDS 0 , HERE 2 -
DOES>
	@ ;
	
: | SWAP DUP @ <BUILDS ,  DUP ROT SWAP +! DOES>  @ + ;

: W| 2 | ;
: C| 1 | ;

: STRUCT> DROP ;

: [] SWAP <BUILDS DUP , * 1 + ALLOT  DOES> DUP @ ROT * + 2 +  ; 
		

( the actual structure definitions - this is our game object )

1 CONSTANT ?SPRITE-ISALIVE

<STRUCT OBJ-STRUCT
	W| OBJ-SPN
	W| OBJ-X
	W| OBJ-Y
	W| OBJ-OLDX
	W| OBJ-DX
	W| OBJ-DY
	W| OBJ-CXMIN
	W| OBJ-CYMIN
	W| OBJ-CXMAX
	W| OBJ-CYMAX
	W| OBJ-TICK
	C| OBJ-FLAGS
STRUCT>

( an object descriptor describing an object on a a level )

0 CONSTANT E-PATROLTYPE
1 CONSTANT E-KEYTYPE 

<STRUCT DESC-STRUCT
	C| DESC-SPN
	C| DESC-X
	C| DESC-Y
	C| DESC-DX
	C| DESC-DY
	C| DESC-C1
	C| DESC-C2
	C| DESC-TYPE
STRUCT>

." type extensions "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 

( various global variables )

0 VARIABLE CURRENT-DESC

0 CONSTANT E-WALKING
1 CONSTANT E-JUMPING
2 CONSTANT E-FALLING
0 VARIABLE JUMP
0 VARIABLE JUMP-INDEX
0 VARIABLE START-JUMP
0 VARIABLE PLAYER-HITX
0 VARIABLE PLAYER-HITY
0 VARIABLE KEY-COUNT
0 VARIABLE DEAD
0 VARIABLE LEVEL
0 VARIABLE LIVES 
0 VARIABLE TILEMAP-PTR

." variables "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 

( 1 512 [] TILES  )

( ." tile array "  HERE LASTHERE @  - U. CR HERE LASTHERE ! )

( an array of game objets )

7 CONSTANT MAX-SPRITES
OBJ-STRUCT MAX-SPRITES [] GAME-SPRITES

( sentinel that holds the address of the last sprite )

0 VARIABLE LAST-SPRITE
MAX-SPRITES GAME-SPRITES LAST-SPRITE !

." sprite array "  HERE LASTHERE @  - U. CR HERE LASTHERE ! 

( code to support run length decoding of background tile maps )

0 VARIABLE DECODE-PTR 

( we store 2-bytes per tile in our decoded buffer - the first byte is the tile id, the second is a flag  )
( indicating the type of tile to speed up collisions                                                     )

: DECODE-PTR, 
	DECODE-PTR @ C!
	2 DECODE-PTR +!
;

( usage -- src srclen dst )
(                         )
( a token beginning with the high-bit 128 set indicates the start of a run, otherwise it is a literal )

: RL-DECODE 	DECODE-PTR ! OVER + 1 + SWAP 
				DO I  C@ 128  AND 0= IF 
									I C@  DECODE-PTR, R> 1 + >R  						
							  ELSE 		
									I C@  127 AND  R> 1 + >R  0 DO   					
																	J C@ DECODE-PTR, 
																  LOOP  R> 1 + >R  
							 ENDIF 
			0 +LOOP ;																	

( words used to look-up from fields in the game data )

: GET-NUM-LEVELS 		13 SPN ! TEST DROP DPTR @  C@ ;
: GET-LEVEL  			2 * 1 + 13 SPN ! TEST DROP DPTR @  +  @ DPTR @  + ;
: GET-NAME-FIELD  		DUP @ + 2 + ;
: GET-NAME  	  		GET-NAME-FIELD DUP 1 + SWAP C@ ;
: GET-KEYS-FIELD  		GET-NAME-FIELD DUP C@ + 1 + ;
: GET-NUMSPRITE-DESCS 	GET-KEYS-FIELD 1 + C@ ;
: GET-SPRITE-DESC 		GET-KEYS-FIELD 2 + SWAP  8 * + ;

: DECODE 251 SPN ! CLSM LEVEL @ GET-LEVEL DUP @ SWAP 2 + SWAP TILEMAP-PTR @  RL-DECODE ;

: SET-TILEMAP-PTR 251 SPN ! TEST DROP DPTR @ TILEMAP-PTR ! ;
: GET-CELL *64 SWAP *2 + TILEMAP-PTR @ + C@ ; 
: SET-CELL *64 SWAP *2 + TILEMAP-PTR @ + C! ; 
: GET-FLAG *64 SWAP *2 1 + + TILEMAP-PTR @ + C@ ; 
: SET-FLAG *64 SWAP *2 1 + + TILEMAP-PTR @ + C! ; 
: CLR-CELL *64 SWAP *2 + TILEMAP-PTR @ + 0 SWAP ! ;

." level decomp "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 

( code used at compile time to generate the quadratic jump curve )

0 VARIABLE Y
0 VARIABLE DY

2 24 [] JUMP-CURVE SMUDGE

: PLOT-CURVE 0 Y ! 3 16 * DY ! 12 0 DO  DY @ Y  +! Y @ 16 / DUP  I JUMP-CURVE ! 23 I - JUMP-CURVE !  -4  DY +! LOOP ; 
 PLOT-CURVE  

." jump curve "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 

( choose a frame for the player's fox sprite based on the players position and state )

: PLAYER-SELECT-SPRITE >R  R OBJ-X @ 8MOD /2  
						   R OBJ-SPN @ JUMP @ 0= IF 
														+ 
													ELSE  
														R OBJ-Y  @ 8MOD /2 *2 *2  + +  
												    ENDIF 									  
 R> DROP ;

( a tile from the tile sheet - 6- and copy it into the scratch tile )

: GET-TILE  SROW ! LEVEL @ 3 MOD  SCOL ! 252 SP1 ! 6 SP2 ! PWATTM PWBLM ;


: SET-TILE  SROW !  SCOL !  254 SP2 ! 252 SP1 ! GWATTM GWBLM  ;

( draw the player ) 

: PLAYER-DRAW
>R 
	 R OBJ-Y @  /8-1 SROW !  
	 R OBJ-X @  /8-1 SCOL ! 
	6 LEN ! 5 HGT ! 253 SP1 ! 254 SP2 !  
	PWBLM PWATTM  
	
	1 SCOL ! 1 SROW ! 
	R PLAYER-SELECT-SPRITE  SP1 !
	253 SP2 ! 
	GWORM  
	R OBJ-Y @ /8-1  ROW ! 
	R OBJ-X @ /8-1  COL !  
	253 SPN ! PUTBLS  
R> DROP ;
	
." player draw "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 
	
( handle player input - the player can be in one of three states: )
( walking, jumping or falling ) 
	
( trigger a jump )

: PLAYER-DO-JUMP
>R	
	E-JUMPING JUMP ! 				( set the jump state )
	JUMP-INDEX 0!					( reset the index into the jump curve )
	R OBJ-Y @ START-JUMP !			( set the start y coord for the jump )
	
	6 2 KB IF 						( use the currently held key to decide which way we are jumping )
		176 R OBJ-SPN !				( and set the sprite id appropriately )
		-2 R OBJ-DX !  
	ELSE 
	6 1 KB IF
		 144 R OBJ-SPN !
		2 R OBJ-DX ! 
	ELSE							
		R OBJ-SPN @ 16 OR  R OBJ-SPN !	( if no key is being pressed, get the sprite id from the current sprite )	
		R OBJ-DX 0!
	ENDIF 
	ENDIF 
	
R> DROP ;
	
( normal walking )
	
: PLAYER-DO-WALK
	>R
	6 2 KB IF 
		160 R OBJ-SPN !
		-2 R OBJ-X +!  
	ELSE 
	6 1 KB IF 
		128 R OBJ-SPN !
		2 R OBJ-X +! 
	ELSE
		R OBJ-SPN @ 239 AND  R OBJ-SPN !
	ENDIF
	ENDIF 
	R> DROP
;

." player input " HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 

( collision checks )

( update the state of a collapsing tile )

: INC-CELL 2DUP GET-CELL 1 + DUP 14 = IF 
										DROP CLR-CELL 
									  ELSE 
										ROT ROT SET-CELL 
									  ENDIF ;

( try and collapse this tile )

: TRY-CRUMBLE 
	2DUP 
 
	GET-CELL 5 > IF
		2DUP 
		2DUP 
		INC-CELL
		GET-CELL 
		GET-TILE 
		SET-TILE 
	ELSE
		DROP DROP
	ENDIF 
;

( flags that hold the tile underneath the fox ) 

0 VARIABLE GROUND-FLAG 
0 VARIABLE CEILING-FLAG 
0 VARIABLE WALL-FLAG 

( this OR-assigns the value to the variable i.e. like |= in C )
	
: OR! DUP @ ROT OR SWAP ! ;

 ( : DBG-DRAWCELL ROW ! COL ! 1 LEN ! 1 HGT ! INVV ; )

( determine if the player is standing on solid ground by testing the three cells below the player )

: PLAYER-CHECK-GROUND >R  R OBJ-Y @ 16  + /8  DUP DUP
						  R OBJ-X @ 4   + /8  SWAP     GET-FLAG  GROUND-FLAG OR!
						  R OBJ-X @ 12  + /8  SWAP     GET-FLAG  GROUND-FLAG OR!
						  R OBJ-X @ 20  + /8  SWAP     GET-FLAG  GROUND-FLAG OR!				 
R> DROP ;
						 
( determine if the player is standing on a collapseable platform )
						 
: PLAYER-CRUMBLE-GROUND >R  R OBJ-Y @ 16 + /8  DUP DUP 
						    R OBJ-X @ 4  + /8  SWAP  TRY-CRUMBLE
						    R OBJ-X @ 12 + /8  SWAP  TRY-CRUMBLE 
						    R OBJ-X @ 20 + /8  SWAP  TRY-CRUMBLE 
R> DROP ; 	 

( determine if the player is colliding with a solid ceiling )
						 
: PLAYER-CHECK-CEILING >R  R OBJ-Y @ 1 -  /8 DUP DUP  
						   R OBJ-X @ 4 +  /8   SWAP    GET-FLAG  CEILING-FLAG OR!
						   R OBJ-X @ 12 + /8   SWAP    GET-FLAG  CEILING-FLAG OR!
					       R OBJ-X @ 20 + /8   SWAP    GET-FLAG  CEILING-FLAG OR! 
R> DROP ;

( determine if the player is colliding with a wall )

: PLAYER-CHECK-WALL >R 
						R OBJ-SPN @ 32 AND  IF 
												R OBJ-X @ ( 0 + ) /8  
											ELSE 
												R OBJ-X @ 24 + /8 
											ENDIF
					 DUP
					 R OBJ-Y @ ( 0 + )  /8 GET-FLAG  WALL-FLAG OR!
					 R OBJ-Y @ 8 +  /8     GET-FLAG  WALL-FLAG OR!
 R> DROP ; 
		
." player checks  " HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 

( checks to do while the player is in flight )

: PLAYER-JUMPING-HITS 
>R 
	JUMP-INDEX @ 12 > IF			( if we are descending .... )
		R PLAYER-CHECK-GROUND  		( ... check the ground )
		GROUND-FLAG @ 8 AND IF		( ... is deadly tile? ) 
				1 DEAD !			( ... then dead )
			ELSE
			GROUND-FLAG @ IF 						( if ground .. )
				R OBJ-SPN  @ 239 AND R OBJ-SPN !	( ... sprite id and change state to walking )
				E-WALKING JUMP !
			ENDIF 
			ENDIF 
	ELSE							( if are ascending ... )
		  R PLAYER-CHECK-CEILING 	( ... check the ceiling )
		 CEILING-FLAG @ 8 AND IF	( ... is deadly tile> )
			1 DEAD !				( ... then dead )
		 ELSE 
		 CEILING-FLAG @ 1 AND IF 	( .. else solid, cancel horizontal velocity, and adjust jump )
			 R OBJ-DX 0! 
			 12 JUMP-INDEX @ - 11  + JUMP-INDEX ! 
			 ENDIF
		 ENDIF 
	ENDIF 
		
	R PLAYER-CHECK-WALL  			( if we have hit a solid wall ..)
	WALL-FLAG @ 1 AND IF 
		 R OBJ-OLDX @ R OBJ-X !		( reset xposition )
	ELSE  WALL-FLAG @ 8 AND IF		( else if deadly .... )
		1 DEAD !					( ... then dead )
		ENDIF
	ENDIF
R> DROP ;

( checks to do when we are falling )

: PLAYER-FALLING-HITS 
>R
	R PLAYER-CHECK-GROUND  
	GROUND-FLAG @ IF						( if ground of any kind, set state to walking and sprite id to appropriate )
		R OBJ-SPN @ 239 AND R OBJ-SPN !
		E-WALKING JUMP !
	ENDIF 
R> DROP ;

( checks to do when we are walking )

: PLAYER-WALKING-HITS 
>R
	R PLAYER-CHECK-GROUND 

	GROUND-FLAG @ 0=  IF					( if there's no ground .... )
		R OBJ-SPN  @ 16 OR R OBJ-SPN !
		E-FALLING JUMP !					( ... we are falling )
		ELSE GROUND-FLAG @ 8 AND IF			( if the ground is deadly ... )
		 1 DEAD ! 							( ... we are dead )
	ELSE GROUND-FLAG @ 4 AND IF 			( if we are on a conveyer ... )
		-1 R OBJ-X +!						( ... adjust xpos )
	ELSE    
			GROUND-FLAG @ 3 AND IF			( crumbling platform... )
				NOOP
			ELSE
				GROUND-FLAG @ 16 AND IF
					R PLAYER-CRUMBLE-GROUND
				ENDIF
			ENDIF 
	ENDIF 
	ENDIF 
	ENDIF 
		
	R PLAYER-CHECK-WALL  					( wall checks as above )
	WALL-FLAG @ 1 AND IF 
		R OBJ-OLDX @ R OBJ-X !
	 ELSE  WALL-FLAG @ 8 AND IF
		1 DEAD !
		ENDIF
	ENDIF	
	
R> DROP ;
	
( do the player background collision )
	
: PLAYER-HITS 
	 GROUND-FLAG 0!
	 CEILING-FLAG 0! 
	 WALL-FLAG 0!
	JUMP @ CASE 
		E-JUMPING OF PLAYER-JUMPING-HITS ENDOF
		E-WALKING OF PLAYER-WALKING-HITS ENDOF 
		E-FALLING OF PLAYER-FALLING-HITS ENDOF
	ENDCASE ;
		
." player hits  "  HERE LASTHERE @  - U.  HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U.  CR 

( move the player when they are jumping )

: PLAYER-JUMPING
>R
	START-JUMP @ JUMP-INDEX @ JUMP-CURVE @ - R OBJ-Y !
	1 JUMP-INDEX +!
	R OBJ-DX @ R OBJ-X +!
	JUMP-INDEX @ 24 = IF
		E-WALKING JUMP !
		START-JUMP @  R OBJ-Y !
	ENDIF 
R> DROP ;
	
( move the player when they are falling )
	
: PLAYER-FALLING  3 SWAP OBJ-Y +!  ;

( tick the player )
		  
: PLAYER-TICK
	>R
	R OBJ-X @ R OBJ-OLDX !
	JUMP @ CASE 
	E-WALKING OF
			3 1  KB IF
				R PLAYER-DO-JUMP
			ELSE
				R PLAYER-DO-WALK
			ENDIF 
		ENDOF
	E-JUMPING OF  R PLAYER-JUMPING ENDOF 
	E-FALLING OF  R PLAYER-FALLING ENDOF 
	ENDCASE 

	R PLAYER-HITS  
	
	R OBJ-X @ 12 + PLAYER-HITX !
	R OBJ-Y @ 8 + PLAYER-HITY !
	
	R PLAYER-DRAW
	
	R> DROP ;

." player move "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - .  HERE U. 

( update game objects )

: TICK-SPRITE DUP  OBJ-TICK @ CFA EXECUTE ;

: INIT-GAME-SPRITES  
	MAX-SPRITES 0 DO 0 
					I GAME-SPRITES OBJ-FLAGS ! 
				LOOP  ;
				
( find a free slot for a new game object )
				
: FIND-FREE 
	MAX-SPRITES 0 DO 
		I GAME-SPRITES 
			DUP OBJ-FLAGS @ ?SPRITE-ISALIVE AND 0= IF 
														LEAVE 
													  ELSE 
														DROP 
													  ENDIF 
	LOOP ; 

( tick all the live game objects )

: TICK-SPRITES  
	0 GAME-SPRITES >R 
	BEGIN 
		R OBJ-FLAGS @ ?SPRITE-ISALIVE AND IF 
												R TICK-SPRITE 
											 ENDIF 
		R> OBJ-STRUCT + >R
	R LAST-SPRITE @ = UNTIL 
	R> DROP  ; 	

( convert a tile id to a flag )

: T2FLG
	CASE 
	0 OF 0 ENDOF 
	1 OF 1 ENDOF
	2 OF 2 ENDOF 
	3 OF 4 ENDOF 
	4 OF 8 ENDOF
	5 OF 8 ENDOF
	6 OF 16 ENDOF 
	ENDCASE ;

0 VARIABLE TILE-PTR

( setup the background from the tilemap and the tile images )

: DRAW-BACKGROUND ATTON 254 SPN ! 0 COL ! 0 ROW ! PUTBLS ;

: SET-TILES 
	254 SPN ! CLSM 7 INK 0 PAPER 1 BRIGHT SETAM 
	16 0 DO  
		32 0 DO  I J 
			  GET-CELL DUP IF 
					DUP GET-TILE  
					I J SET-TILE  T2FLG  
					I J SET-FLAG 
				ELSE 
					DROP 
				ENDIF 	
		LOOP 
	LOOP ; 

." sprite tick "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 
	
( draw an enemy sprite )
	
: ENEMY-DRAW   >R  R OBJ-Y @ /8  ROW ! R OBJ-X @ DUP /8  COL !  8MOD /2 R OBJ-SPN @ + SPN ! ATTOFF PUTBLS   R>   DROP ;

." sprite draw "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 
		  
( do a box collision check ) 
		  
: CHECK  >R
			R OBJ-X @ R OBJ-CXMIN @ + PLAYER-HITX @ > IF 0 
			ELSE
			R OBJ-X @ R OBJ-CXMAX @ + PLAYER-HITX @ < IF 0 
			ELSE
			R OBJ-Y @ R OBJ-CYMIN @ + PLAYER-HITY @ > IF 0 
			ELSE
			R OBJ-Y @ R OBJ-CYMAX @ + PLAYER-HITY @ > 
			ENDIF 		
			ENDIF
			ENDIF 
			( R DBG-DRAW-HITS  )			
R> DROP ;
	
." sprite check "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 

( various tick functions )

: NULL-TICK DROP ;
	
: ENEMY-TICK  >R  
			  R OBJ-DX @ R OBJ-X +!  
			  -1 R OBJ-DY +!
				R OBJ-DY @ 0= IF 
					 R OBJ-OLDX @ R OBJ-DY ! 
					 R OBJ-DX @ MINUS R OBJ-DX ! 
				ENDIF
			
			 R CHECK  IF
				 1 DEAD ! 
			 ENDIF 
			
			R ENEMY-DRAW 
			( R DBG-DRAW-HITS )
				
 R> DROP ;
	
." enemy tick "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 
	
: DOOR-TICK >R
		 R CHECK IF
				 2 DEAD ! 
		 ENDIF 
		 
		 ( R DBG-DRAW-HITS )
R> DROP ;

." door tick "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 
	
( various object constructors )
	
: MAKE-DOOR
FIND-FREE >R
	12  R OBJ-SPN !
	R OBJ-Y !
	R OBJ-X !
	8 8 - R OBJ-CXMIN  ! 
	8 8 - R OBJ-CYMIN  ! 
	8 8 + R OBJ-CXMAX  ! 
	8 8 + R OBJ-CYMAX  ! 
	' DOOR-TICK R OBJ-TICK !
	1 R OBJ-FLAGS C! 
	R OBJ-X @ /8 SCOL !  R OBJ-Y @ /8 SROW !  254 SP2 ! R OBJ-SPN @  SP1 ! GWATTM GWBLM  	
	R OBJ-X @ /8 COL  ! R OBJ-Y  @ /8 ROW  !  R OBJ-SPN @ SPN ! PUTBLS
R> DROP ;


." door make "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 

: KEY-TICK  >R   
	R OBJ-X @ /8 COL ! R OBJ-Y @ /8 ROW ! 1 HGT ! 1 LEN ! R OBJ-OLDX @ 7 AND INK SETAV
	1 R OBJ-OLDX +!
	R CHECK  IF 
			0 10 DO 10 I 100 *  BLEEP LOOP 
			0 R OBJ-FLAGS C! 
			-1 KEY-COUNT +!
			0 GET-TILE R OBJ-X @ /8  R OBJ-Y @ /8 SET-TILE
			R OBJ-X @ /8 COL ! R OBJ-Y @ /8 ROW !  7 INK SETAV
			KEY-COUNT @ 0= IF 
				R OBJ-DX @ R OBJ-DY @ MAKE-DOOR 
			ENDIF 
	ENDIF
	 ( R DBG-DRAW-HITS )
R> DROP ;

." key tick "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 

: SET-COMMON >R 
	CURRENT-DESC @ DESC-SPN C@ R OBJ-SPN !
	CURRENT-DESC @ DESC-Y 	C@ R OBJ-Y !
	CURRENT-DESC @ DESC-X 	C@ R OBJ-X !
	1 R OBJ-FLAGS C!
R> DROP ;

." common  "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 

: MAKE-KEY 
	FIND-FREE >R
	R SET-COMMON
	CURRENT-DESC @ DESC-C1 	C@ R OBJ-DX !
	CURRENT-DESC @ DESC-C2 	C@ R OBJ-DY !
	0 R OBJ-OLDX !
	4 8 - R OBJ-CXMIN ! 
	4 8 - R OBJ-CYMIN ! 
	4 8 + R OBJ-CXMAX ! 
	4 8 + R OBJ-CYMAX !
	' KEY-TICK R OBJ-TICK !
	R OBJ-X @ /8  SCOL !  R OBJ-Y @ /8 SROW !  254 SP2 ! R OBJ-SPN @  SP1 ! GWATTM GWBLM  	
	SCOL @ COL ! SROW @ ROW ! SP1  @ SPN ! PUTBLS 
	R> DROP 
	;
	
." make key  "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 
	
: MAKE-PLAYER 
	FIND-FREE >R
	128 R OBJ-SPN !
	10 	R OBJ-X !
	106 R OBJ-Y !
	' PLAYER-TICK R OBJ-TICK !
	1 R OBJ-FLAGS C! 
	R> DROP ;
	
." make player  "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 
	
: MAKE-ENEMY 
	FIND-FREE >R
	R SET-COMMON
	CURRENT-DESC @ DESC-DX 	C@ R OBJ-DX !
	CURRENT-DESC @ DESC-DY 	C@ DUP R OBJ-DY ! R OBJ-OLDX !
	8 8 - R OBJ-CXMIN  !
	4 8 - R OBJ-CYMIN  !
	8 8 + R OBJ-CXMAX !
	4 8 + R OBJ-CYMAX  !
	' ENEMY-TICK R OBJ-TICK !
	R> DROP ;

." make enemy  "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 

: MAKE-SPRITE 
	DUP CURRENT-DESC !
	DESC-TYPE C@  CASE 
	E-KEYTYPE OF    	MAKE-KEY ENDOF 
	E-PATROLTYPE OF     MAKE-ENEMY ENDOF
	ENDCASE
;
	
: MAKE-SPRITES LEVEL @ GET-LEVEL GET-NUMSPRITE-DESCS 0  DO 
	I LEVEL @ GET-LEVEL GET-SPRITE-DESC MAKE-SPRITE 
	LOOP 
	;

." make sprites  "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 



( 0 VARIABLE FRAMES  )
( 0 VARIABLE LAST-FRAMES  )
( : COUNTER FRAMES 1 FRAMES +! ; )
( : SHOW-COUNTER FRAMES @ LAST-FRAMES @ - 17 0 AT . FRAMES @ LAST-FRAMES ! ; )
( : START-COUNTER  ' COUNTER INT-ON ; )
( : INNER-LOOP TICK-SPRITES   ; )

( print the level name )

: PRINT-NAME   LEVEL @ GET-LEVEL GET-NAME 17 0 AT TYPE  ;

( print the scrolling crawl on the title screen )

: PRINT-CRAWL 7 INK 17 0 AT LEVEL @ GET-LEVEL GET-NAME DROP + 32 TYPE ;

( setup and main loop )

: SHOW-LIVES   
	19 ROW ! 129 SPN ! 
	LIVES @ DUP 1 > IF 
						1 - 0 DO 
							I 5 * COL ! PUTBLS 
						LOOP 
					ELSE 
						DROP 
					ENDIF  ;

: SETUP-LEVEL 
	0 BORDER 7 INK 0 PAPER CLS 
	INIT-GAME-SPRITES 
	DECODE 
	SET-TILES 
	LEVEL @ GET-LEVEL GET-KEYS-FIELD C@  KEY-COUNT ! 
	DRAW-BACKGROUND  
	MAKE-SPRITES ;

: NEW-LIFE 
	( 0 FRAMES ! ) 
	E-WALKING JUMP ! 
	SETUP-LEVEL  
	PRINT-NAME  
	SHOW-LIVES  
	MAKE-PLAYER  
	0 DEAD !  ;

: FADE  0 7 DO I INK 32 LEN ! 17 HGT ! 0 COL ! 0 ROW ! SETAV 100 10 I * BLEEP -1 +LOOP   ;
: FLASHV  10 0  DO  32 LEN ! 17 HGT ! 0 COL ! 0 ROW ! INVV 10 10 I * BLEEP LOOP  ;

: OUTER-LOOP NEW-LIFE DI ( START-COUNTER ) BEGIN  TICK-SPRITES   ( SHOW-COUNTER ) DEAD @ UNTIL ;

." loop code  "  HERE LASTHERE @  - U. CR HERE LASTHERE ! HERE FIRSTHERE @ - . 

: SCROLL-CRAWL 32 LEN ! 1 HGT ! 0 COL ! 17 ROW ! SCL1V ;

: TITLE  10 LEVEL ! 
				SETUP-LEVEL  
				96 0 DO 
					I PRINT-CRAWL 
					8 0 DO 
						TICK-SPRITES 
						SCROLL-CRAWL 
						3 1  KB IF LEAVE ENDIF 
						LOOP 
					3 1  KB IF LEAVE  ENDIF 
				LOOP ;

: ATTRACT  10 0 DO 
					TITLE 
					3 1 KB IF LEAVE ENDIF 
					I LEVEL ! 
					SETUP-LEVEL 
					PRINT-NAME 
					1000 0  DO 
							TICK-SPRITES  
							3 1 KB IF LEAVE ENDIF 
						LOOP  FLASHV  
					3 1  KB IF LEAVE ENDIF 
				LOOP   ;

: MAIN  ( SETUP-SPRITES  )
		SET-TILEMAP-PTR
		ATTRACT 
		0 LEVEL !
		3 LIVES !
	BEGIN
		OUTER-LOOP 
		DEAD @ CASE 
			1 OF FADE  -1 LIVES +! ENDOF 
			2 OF FLASHV 1 LEVEL +!  LEVEL @ 10 MOD LEVEL !  ENDOF 
		ENDCASE 
		LIVES @ 0= IF 
			 32 LEN ! 17 HGT ! 0 COL ! 0 ROW ! 2 PAPER 0  INK CLSV 
			 10 12 AT ." GAME OVER" 
			 EI 100 0 DO HALT LOOP DI 
			0 LEVEL !
			3 LIVES !
			ATTRACT
		ENDIF 
	AGAIN ;


." main "  HERE LASTHERE @  - U. CR HERE LASTHERE ! 
."  "   LASTHERE @ FIRSTHERE @ - U.

0 COL ! 0 ROW ! 



