: <STRUCT 
	<BUILDS 0 , HERE 2 -
DOES>
	@ ;
	
: | SWAP DUP @ <BUILDS ,  DUP ROT SWAP +! DOES>  @ + ;

: W| 2 | ;
: C| 1 | ;
: $| 3 | ;

: GET-DESC DUP C@ SWAP 1+ @ SWAP ;

: STRUCT> DROP ;

: [] SWAP <BUILDS DUP , * 1 + ALLOT  DOES> DUP @ ROT * + 2 +  ; 

: $ <BUILDS 34 WORD HERE C@ 1 + ALLOT DOES> ;

: ($") R COUNT DUP 1+ R> + >R  ;
: $" 34 ( STATE @ IF ) COMPILE ($") WORD HERE C@ 1+ ALLOT ( ELSE WORD HERE COUNT ENDIF ) ; IMMEDIATE

: TO-UPPER 95 AND ;

0 VARIABLE LOCATION-COUNT 
0 VARIABLE OBJECT-COUNT 

1 CONSTANT VISITED
2 CONSTANT DARK

<STRUCT LOCATION-STRUCT
	W| LOCATIONSTRUCT-ID 
	$| LOCATIONSTRUCT-DESC
	W| LOCATIONSTRUCT-FLAGS
STRUCT>

LOCATION-STRUCT 128 [] LOCATIONS

: LOCATION-DESC:  34 WORD HERE DUP C@ 1 + ALLOT  
				LOCATION-COUNT @ 1 - LOCATIONS >R 
				DUP C@ R LOCATIONSTRUCT-DESC C! 
				1+ R LOCATIONSTRUCT-DESC 1 + ! R> DROP ;

: ->LOCATION-FLAGS LOCATION-COUNT @ 1 - LOCATIONS LOCATIONSTRUCT-FLAGS ! ;

: +FLAG DUP @ ROT OR SWAP ! ;   			
: -FLAG DUP @ ROT MINUS 1 - AND SWAP ! ; 		
 

: LOCATION-ID: LOCATION-COUNT @ DUP 1 LOCATION-COUNT +! CONSTANT  LOCATIONS LOCATIONSTRUCT-ID  LATEST PFA SWAP ! ;  


LOCATION-ID: DESTROYED
LOCATION-ID: CARRIED
LOCATION-ID: WORN

<STRUCT OBJECT-STRUCT
	W| OBJECT-LOCATION
	$| OBJECT-DESC 
STRUCT>

OBJECT-STRUCT 128 [] OBJECTS 

: OBJECT-DESC: 34 WORD HERE DUP C@ 1 + ALLOT  
				OBJECT-COUNT @ 1 - OBJECTS >R 
				DUP C@ R OBJECT-DESC C! 
				1+ R OBJECT-DESC 1 + ! R> DROP ;

: OBJECT-ID: OBJECT-COUNT @ 1 OBJECT-COUNT +! CONSTANT ;  

: OBJECT-LOCATION: -FIND IF  
						DROP CFA EXECUTE 
					ELSE 
						DESTROYED 
					ENDIF 
					
					OBJECT-COUNT @ 1 - OBJECTS OBJECT-LOCATION ! ;
				


0 VARIABLE BUF-PTR
0 VARIABLE WORD-PTR
0 VARIABLE WORD-LEN
$ BUF "                                                    "
$ WORD-BUF "                                               "

: WORD-PTR-0! 0 WORD-LEN !  WORD-BUF COUNT DROP WORD-PTR ! ;
: WORD-PTR+! WORD-PTR @ C! 1 WORD-PTR +! ;
: WORD-NAME NFA COUNT 127 AND ;
: WORD-BUF-COUNT WORD-PTR @ WORD-LEN @ -  WORD-LEN @ ;
: .WORD-BUF  WORD-BUF-COUNT  TYPE ;
: ++ DUP WORD-LEN +! OVER + SWAP DO I C@ WORD-PTR+! LOOP ;

: MOVE-WORD-BUF
		  HERE 
		  WORD-LEN @ C,   
		  WORD-LEN @ 0 DO WORD-BUF COUNT DROP I + C@  C,  LOOP DP !  ;

: CMOVE-HERE
	HERE							
	ROT								
	ROT 							
	DUP C,						   
	OVER +							
	SWAP 							
	DO I C@ 127 AND C, LOOP 0 C, 0 C, DP ! ; 
	
: DISPATCH-ACTION	
		  WORD-BUF-COUNT
		  CMOVE-HERE		
		  HERE LATEST  (FIND) IF 
			DROP CFA EXECUTE 
			1
		  ELSE
			0
		  ENDIF ;

: PARSE-SPACES BEGIN BUF-PTR @ C@ 32 = WHILE 1 BUF-PTR +! REPEAT ;
: PARSE-CHARS BEGIN BUF-PTR @ C@ DUP 32 = SWAP 0 = OR 0= WHILE BUF-PTR @ C@ TO-UPPER WORD-PTR+! 1 WORD-LEN +!  1 BUF-PTR +! REPEAT ;
: PARSE-VERB-NOUN  WORD-PTR-0! PARSE-SPACES $" -" ++ PARSE-CHARS $" -" ++  PARSE-SPACES PARSE-CHARS  ;
: READ-INPUT  BUF COUNT EXPECT CR   BUF COUNT DROP BUF-PTR ! ;

: PARSE	  READ-INPUT
		  PARSE-VERB-NOUN
		  DISPATCH-ACTION 0= IF 
			." I don't understand" CR 
		  ENDIF ;

0 VARIABLE PLAYER-LOCATION 

: ++PLAYER-LOCATION PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-ID @ WORD-NAME ++ ;
: LOCATION-ACTION  WORD-PTR-0! ++ ++PLAYER-LOCATION DISPATCH-ACTION ;


0 VARIABLE QUIT-FLAG 

: CANT-GO ." You can't go that way." CR ;
		

: CARRIED?  OBJECT-LOCATION @ CARRIED = ;
: WORN? OBJECT-LOCATION @  WORN = ;
: PRESENT? >R 
		   R CARRIED?
		   R WORN? OR
		   R OBJECT-LOCATION @ PLAYER-LOCATION @  = OR 
R> DROP ;

: -BYE- ." see you later!" CR 1 QUIT-FLAG ! ;

: INVENTORY 
	0 >R
	OBJECT-COUNT @  0 DO 
						I OBJECTS OBJECT-LOCATION @ CARRIED = IF
								I OBJECTS OBJECT-DESC GET-DESC TYPE CR
								ELSE
									I OBJECTS OBJECT-LOCATION @ WORN = IF
											I OBJECTS OBJECT-DESC GET-DESC TYPE ."  (worn)" CR
											R> R> R> 1 + >R >R >R 
											ENDIF
								ENDIF
					LOOP R> ;	
																											
: -I- 	
		." You are carrying: " CR 
		INVENTORY 0= IF  ." nothing" CR ENDIF ;
							
: -INVENTORY- -I- ;
			

: EXAMINE-* 
	OBJECTS >R 
	R PRESENT? IF
		R OBJECT-DESC GET-DESC TYPE CR  
	ELSE
		." I don't see that here"
	ENDIF 
R> DROP ;

: TAKE-* OBJECTS >R
	R CARRIED? R WORN? OR IF
		." You already have it" CR
		ELSE R PRESENT? IF 
			CARRIED R OBJECT-LOCATION !
			." Taken" CR
	ELSE
		." You can't" CR
	ENDIF 
	ENDIF 
R> DROP ;

: DROP-* OBJECTS >R 
	R CARRIED? R WORN? OR IF
		PLAYER-LOCATION @ R OBJECT-LOCATION !
		." Dropped"  CR
	ELSE
		." You're not carrying it" CR 
	ENDIF 
R> DROP ;


: ANYTHING? 0 >R OBJECT-COUNT @ 0 DO 
					I OBJECTS OBJECT-LOCATION @ PLAYER-LOCATION @ = IF 
					R> R> R> 1 >R >R >R 
					ENDIF
				LOOP R> ; 

: ALSO-SEE  ANYTHING? IF ." You can also see:" CR 
			OBJECT-COUNT @ 0 DO 
				I OBJECTS OBJECT-LOCATION @ PLAYER-LOCATION @ = IF 
						I OBJECTS OBJECT-DESC GET-DESC TYPE CR 
					ENDIF 
				LOOP 
			ENDIF ;

: BRIEF	    PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-FLAGS @ DARK AND IF
					." It is dark here"
			 ELSE
					PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-DESC  GET-DESC TYPE CR 
			ENDIF ;
		
 : -LOOK- $" -LOOK-" LOCATION-ACTION 0= IF  BRIEF  ENDIF  ALSO-SEE ;	

: FULL 	PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-FLAGS @ DARK AND IF
					." It is dark here"
			ELSE
					-LOOK-
					 VISITED PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-FLAGS +FLAG 
			ENDIF ;
	

: CHANGE-LOCATION 
			PLAYER-LOCATION @ LOCATIONS LOCATIONSTRUCT-FLAGS @ VISITED AND IF 
								BRIEF
							ELSE
								FULL  
							ENDIF ;
			
: -N-  $" -N-" LOCATION-ACTION 0= IF CANT-GO ELSE CHANGE-LOCATION  ENDIF ;
: -S-  $" -S-" LOCATION-ACTION 0= IF CANT-GO ELSE CHANGE-LOCATION  ENDIF ;
: -E-  $" -E-" LOCATION-ACTION 0= IF CANT-GO ELSE CHANGE-LOCATION  ENDIF ;
: -W-  $" -W-" LOCATION-ACTION 0= IF CANT-GO ELSE CHANGE-LOCATION  ENDIF ;


0 VARIABLE DARK-MOVES 

LOCATION-ID: THE-FOYER 
	LOCATION-DESC: "The foyer"
	0 ->LOCATION-FLAGS

	: -N-THE-FOYER ." You've only just arrived, and besides, the weather outside" CR
				   ." seems to be gettng worse." CR ;

	: -LOOK-THE-FOYER ." You are standing in a spacious hall, splendidly decorated in red" CR
					  ." and gold, with glittering chandeliers overhead. The entrance from" CR
					  ." the street is to the north, and there are doorways south and west." CR ;

LOCATION-ID: THE-CLOAKROOM 
	LOCATION-DESC: "The cloakroom"
	 0 ->LOCATION-FLAGS

	: -LOOK-THE-CLOAKROOM ." The walls of this small room were clearly once lined with hooks, " CR
					      ." though now only one remains. The exit is a door to the east" CR ;	
						  
	: -E-THE-CLOAKROOM THE-FOYER PLAYER-LOCATION ! ;
	: -W-THE-FOYER THE-CLOAKROOM PLAYER-LOCATION ! ;

LOCATION-ID: THE-BAR
	LOCATION-DESC: "The bar"
	DARK ->LOCATION-FLAGS

	: -LOOK-THE-BAR ." The bar, much rougher than you'd have guessed after the opulence" CR
				    ." of the foyer to the north, is completely empty. There seems to" CR
				    ." be some sort of message scrawled in the sawdust on the floor" CR ;

	: -READ-MESSAGE 
				PLAYER-LOCATION @ THE-BAR = 
				THE-BAR LOCATIONS LOCATIONSTRUCT-FLAGS @ DARK AND 0= IF 
					DARK-MOVES @ 2 < IF
						." The message, neatly marked in the sawdust, reads... " CR
						." You have won." CR
						1 QUIT-FLAG  !
					ELSE
						." The message has been carelessly trampled, making " CR
						." it difficult to read. You can just distinguish the words..." CR
						." You have lost."
						1 QUIT-FLAG !
					ENDIF 
				ELSE
					." you can't " CR 
			    ENDIF ;
					
	: -EXAMINE-MESSAGE -READ-MESSAGE ;
	: -LOOK-MESSAGE -READ-MESSAGE ;
	
	: BLUNDER ." Blundering around in the dark isn't a good idea"  CR 
			  1 DARK-MOVES +! ;

	: -N-THE-BAR THE-FOYER PLAYER-LOCATION ! ;
	: -S-THE-BAR THE-BAR LOCATIONS LOCATIONSTRUCT-FLAGS @ DARK AND 0= IF CANT-GO ELSE BLUNDER ENDIF ;
	: -E-THE-BAR THE-BAR LOCATIONS LOCATIONSTRUCT-FLAGS @ DARK AND 0= IF CANT-GO ELSE BLUNDER ENDIF ;
	: -W-THE-BAR THE-BAR LOCATIONS LOCATIONSTRUCT-FLAGS @ DARK AND 0= IF CANT-GO ELSE BLUNDER ENDIF ;
	
	: -S-THE-FOYER THE-BAR PLAYER-LOCATION ! ;

OBJECT-ID: MY-CLOAK 
	OBJECT-DESC: "My velvet cloak"
	OBJECT-LOCATION: WORN

	: -EXAMINE-CLOAK ." A handsome cloak, of velvet trimmed " CR
					  ." with satin, and slightly spattered with raindrops. Its " CR
					  ." blackness is so deep that it almost seems to suck light from the room " CR ;
				  
	: -DROP-CLOAK PLAYER-LOCATION @ THE-CLOAKROOM 0= IF
					  ." This isn't the best place to leave a smart cloak lying around. " CR
				  ELSE
					  ." You drop the cloak on the floor" CR
					 DESTROYED MY-CLOAK OBJECTS OBJECT-LOCATION  ! 
					 DARK THE-BAR LOCATIONS LOCATIONSTRUCT-FLAGS -FLAG
				  ENDIF ;

				
OBJECT-ID: DISCARDED-TICKET
	OBJECT-DESC: "A discarded theatre ticket"
	OBJECT-LOCATION: THE-FOYER
	
	 : -EXAMINE-TICKET ." An out-of-date ticket to a bawdy romp titled" CR 
					  ." 'Dominic and Shelley Pull It Off'. " CR ;
					  
	 : -TAKE-TICKET DISCARDED-TICKET TAKE-* ;
	 : -GET-TICKET -TAKE-TICKET ;
	 : -DROP-TICKET DISCARDED-TICKET DROP-* ; 
				
: MAIN 
	0 DARK-MOVES !
	THE-FOYER PLAYER-LOCATION  !
	CLS CHANGE-LOCATION BEGIN ." >" PARSE  QUIT-FLAG @ UNTIL ;
	 