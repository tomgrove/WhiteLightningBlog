( yet another version of "Cloak of Darkness", Interactive Fiction's "Hello World" )
( this file needs to be compiled against the if.sna base )

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
	CLS CHANGE-LOCATION BEGIN ." >" PARSE  QUIT-FLAG @ UNTIL 
	BEGIN AGAIN ;
	
	( ZAP )