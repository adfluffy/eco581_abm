
extensions [csv]

globals [pokemon comp_pokemon filename trades_executed death_counter turn_counter casual_deaths collector_deaths competitive_deaths exit_rate entrance_rate entries]
turtles-own [collection current_offer current_ask ability investment playstyle exploit]


to setup ;; sets the initial conditions for the ABM
  clear-all ;; clears previous data
  reset-ticks

  file-close-all ;; closes any still opened files
  set filename "F:/Users/Devan/Documents/ECO581/Model Data/Pokemon Data (version 1).csv" ;; sets variable with path to pokemon data file

  set pokemon csv:from-file filename ;; creates list of lists containing pokemon data from csv
  set pokemon remove-item 0 pokemon ;; removes the header row from the list

  set trades_executed 0
  set death_counter 0
  set turn_counter 0

  set entries 100

  set entrance_rate 0
  set exit_rate 0

  set casual_deaths 0
  set collector_deaths 0
  set competitive_deaths 0

  print pokemon ;; displays list - debugging only

  turtle-maker entries ;; calls the turtle-maker process to creat 100 agents for the market

  csv:to-file "intial_turtles.csv" [ (list who playstyle ability collection) ] of turtles ;; records the information of the intial turtle seed for analysis

end


to gobarter
  let temp_heading 0 ;; intializes variable
  let new_turtles 0

  set turn_counter turn_counter + 1

  ask turtles [
    if length (current_offer) = 0 [;; sets the current offer if the turtle has no offer already setr
      set-offer ;; calls the set-offer function to set the turtle's offer. Might return [] depending on criteria of turtle playstyle
    ]

    if length (current_ask) = 0 [;; sets the current ask if the turtle has no ask already set
      set-ask ;; calls the set-ask function to set the turtle's ask. Might return [] depending on criteria of turtle playstyle
    ]

    (ifelse
      (length (current_offer) = 0) and (length (current_ask) = 0) [ ;; determines if the turtle has no offer AND no ask. Makes these turtles wander
        set heading 90 * random 4 ;; sets heading to 0, 90, 180, or 270 degrees
        fd (random 10 + 1) ;; has the turtle move 1-10 patches in random direction
      ]
      (length (current_offer) > 0) and (length (current_ask) > 0) [ ;; determines that a turtle has both an offer and an ask
        set temp_heading random 2 ;; randomly assigns the turtle heaing parameter

        (ifelse
          temp_heading = 0 [ ;; turtle will go to the patch for their offered pokemon
            setxy (item 4 current_offer) (item 5 current_offer) ;; sets the x and y coordinates to the offered pokemon's (x,y) based on their number
          ]
          temp_heading = 1 [ ;; turtle will go to the patch for their asked pokemon
            setxy (item 4 current_ask) (item 5 current_ask) ;; sets the x and y coordinates to the asked pokemon's (x,y) based on their number
          ])
      ])

    trade

    exit-market

    generate-pokemon

    set investment investment + ability
  ]

  set new_turtles random 100

  turtle-maker new_turtles

  set entries entries + new_turtles

  set entrance_rate round (count turtles / turn_counter)
  set exit_rate round (death_counter / turn_counter)

  tick-advance 1

end


to trade ;; pokemon trade mechanics - checks for offer/ask match and adjusts each turtles' collection if a match is found
  let temp_offer [] ;; intializes the temp_offer list
  let temp_ask [] ;; initializes the temp_ask list

  let trade_execute false ;; intializes trade execute to default value of false

  set temp_offer current_offer ;; sets the temp_ask list to the main turtle's current offer
  set temp_ask current_ask ;; sets the temp_offer list to the main turtle's current ask

  if any? other turtles-here [ ;; continues if there are other turtles on the same spaces as the main turtle
    ask other turtles-here [ ;; begins to compare the main and trade partner turtles
      if (length temp_offer > 0) and (length temp_ask > 0) and (length current_offer > 0) and (length current_ask > 0)[

        if (item 0 current_ask = item 0 temp_offer) and (item 0 current_offer = item 0 temp_ask)[ ;; trade will execute if both turtles match in offer and ask
          set collection remove-item (position current_offer collection) collection ;; removes the trade partner's offered pokemon from their collection
          set collection lput current_ask collection ;; adds the trade partner's ask to their collection

          set current_ask [] ;; clears the ask of the trade partner
          set current_offer [] ;; clears the offer of the trade partner


          set trade_execute true ;; sets the trade esecute value to 1 for yes

          set trades_executed trades_executed + 1

        ]
       ]
     ]

    if trade_execute [ ;; executes collection changes if a trade match occurred
      set collection remove-item (position current_offer collection) collection ;; removes the main turtle's offer from their collection
      set collection lput current_ask collection ;; adds the ask to the main turtle's collection

      set current_offer [] ;; clears the ask of the main turtle
      set current_ask [] ;; clears the offer of the main turtle
    ]
  ]
end


to-report sort-with [ key lst ] ;;returns a sorted list
  report sort-by [ [a b] -> (runresult key a) < (runresult key b) ] lst
end


to turtle-maker [amount] ;; generates turtle and initial turtle variables
  ;; used on setup and throughout run to create new turtles to participate in the market
  create-turtles amount [ ;; calls the create-turtles function

    set collection [] ;;initialize each turtle's collection of pokemon
    set current_offer [] ;;initializes the turtle's current offered pokemon
    set current_ask [] ;; intializes the turtle's current asked for pokemon

    let initial_collection random (length pokemon) ;; selects a random size for each turtle's initial collection
    let i 0 ;;initialized the counter variable

    ;; The following loop creates an initial list of owned pokemon for each turtle that enters the market that is some random number of pokemon
    ;; The number of pokemon for each turtle initially is random but less than or equal to the number of all pokemon
    ;; Turtles may have duplicate pokemon as a result of this
    while [i < initial_collection][
      set collection lput item (random (length pokemon)) pokemon collection ;; adds new pokemon to the end of the turtle's collection list
      set i i + 1 ;;iterates the loop
    ]
    set investment 0 ;;sets current time investment for the turtle to 0
    set playstyle one-of [0 0 0 0 1 1 2] ;; Playstyles - 0: Casual, 1: Collector, 2: Comptetitive
    set ability ability-set (playstyle) ;;sets the turtle's ability to play based on their playstyle
    set exploit 0 ;;initializes the turtle's willingness to exploit the creation of pokemon
  ]


end


to-report find-dup [ my_list ] ;; finds duplicates in a given list
  ;returns the first duplicated item, or false if no duplicates
  if length my_list = 1 [ report false ] ;we've run out of list before a dup is found
  ;compare the first element of the list to the rest

  let check first my_list   	
  let against butfirst my_list
  ;does the first element match any remaining element?
  foreach against [
	x -> if check = x  [report check ]  ;found a duplicate, report it.
]
  ;no matches. test the remainder of the list for a duplicate
  report find-dup against
end


to-report dup-exists [ my_list ] ;; determines if duplicates exist in a given list
  ;returns the first duplicated item, or false if no duplicates
  if length my_list = 0 [ report false ] ;we've run out of list before a dup is found
  ;compare the first element of the list to the rest

  let check first my_list   	
  let against butfirst my_list
  ;does the first element match any remaining element?
  foreach against [
	x -> if check = x  [report true ]  ;found a duplicate, report it.
]
  ;no matches. test the remainder of the list for a duplicate
  report dup-exists against
end


to set-offer ;; calculates the pokemon a turtle is willing to offer as a trade based on the playstyle and collection set of the turtle
  ;;intialize variables
  let temp false

  if length collection > 0 [
   (ifelse
     playstyle = 0 [ ;; instructions for Casual turtles to offer pokemon
       set temp dup-exists collection ;; finds if the turtle has a duplicate pokemon in their collection - temp as a boolean

       (ifelse
         temp [ ;; temp value of true - a duplicate exisits
           set current_offer find-dup collection ;; use find-dup function to return the duplicate pokemon from the collection and set the offer list to that pokemon
         ]
         not temp[ ;; temp value of false - no duplicate found
           set current_offer one-of collection ;; Casual players will offer a random pokemon in trade if they don't have a duplicate to offer
       ])
     ]
     playstyle = 1 [ ;; instructions for Collector turtles to offer pokemon
       set temp dup-exists collection

       (ifelse
         temp [
           set current_offer find-dup collection
         ]
         not temp[
           set current_offer [] ;; Collector players will opt to not offer a trade if they have no duplicate pokemon to trade
       ])
     ]
     playstyle = 2 [ ;; instructions for Competitive turtle to offer pokemon
       set temp dup-exists collection

       (ifelse
         temp [
           set current_offer find-dup (collection)
         ]
         not temp[
           set current_offer competitive-check (collection) ;; Competitive player will offer a trade so long as the offered pokemon is not a competitive one (in the comp_pokemon list)
       ])
     ]
   )
]


end


to generate-pokemon ;; returns a valid pokemon for turtle based on current collection and time investment
  ;;intializes lists
  let generated_pokemon [] ;; list for info of generated pokemon
  let temp_gen [] ;; temporary list
  ;; intializes integer variables
  let i 0 ;; counter variable
  let choice 0 ;; integer variable

  foreach pokemon [;; iterates through all pokemon to determine what are eligible pokemon to generate
    x -> if item 2 x <= investment [;; compares the turtle's current time investment to the required investment for all pokemon and proceeds if the turtle has enough investment
      set temp_gen lput x temp_gen ;; adds all time-investment eligible pokemon to the temporary list variable
      ]
    ]
  if (length temp_gen > 0) and (length collection > 0) [
    foreach temp_gen [ ;; goes through the time-investment eligible pokemon to determine if the are excludable
      x ->
      set i position (x) temp_gen ;; sets the counter variable i to the position of x in the temp_gen list. This is to allow for accureate removal while the temp_gen list's length is variable
      if (x = one-of collection) and (item 6 x = 1)[ ;; if a pokemon is already earned by the turtle and excludable, the code proceeds
        set temp_gen remove-item i temp_gen ;; removes the excludable pokemon already received by the turtle from the possiblities list for generation
      ]
    ]

  ]
  set i length temp_gen ;; resets the i counter to the length of eligible pokemon to generate

  (ifelse
    i > 0 [
      set choice random (i) ;; sets the choice variable to some random value from 0 to i
      set generated_pokemon item (choice) temp_gen
    ] ;; sets the generated_pokemon to the random member of eligible pokemon in temp_gen
    i = 0 [
      set generated_pokemon []
    ]
  )

  set collection lput generated_pokemon collection ;; returns that pokemon
end


To-report ability-set  [ turtle_playstyle ] ;; calculates a turtle's ability to play based on the turtle's playstyle
	;;intialized variables
	Let temp_ability 0
	Let base_time 0
	Let additional_time 0
	Let additional_max_time 0

  (Ifelse
  	turtle_playstyle = 0 [ ;; play time constraints for a casual turtle
    		Set Base_time  0 ;; we assume that there is no baseline daily playtime for the casual turtle
    		Set Additional_max_time 1.00 ;; we also assume that the casual turtle at most commits an average of 1 hour per day
  ]
  	turtle_playstyle = 1 [ ;; play time constraints for the collector turtle
    		Set Base_time 1 ;; we assume that this play style will at least commit an hour to play per day
    		Set Additional_max_time 6.00 ;; we also assume that at most this play style will commit up to an addtional 6 hours on average per day
  ]
  	turtle_playstyle = 3 [ ;; play time constraints for the competitive turtle
    		Set Base_time 2 ;; we assume that this play style will commit to a minimum of 2 hours of play per day
    		Set Additional_max_time 6.00 ;; we also assume that this type of turtle will commit up to an additional 6 hours of play on average per day
  ])

  Set additional_time  (precision (random-float additional_max_time) 2) ;; determines the addtional time (beyond the base time for each play style) that a turtle will commit to

  Set temp_ability  (base_time + additional_time + 0.01) ;; combines the additional time (turtle specific) witht he base time (play style specific), and makes sure that the value is greater than 0

  Set ability temp_ability ;;sets the turtle's ability to play from the temporary variable

  Report ability ;;reports result
  	
end


to-report competitive-check [ collection_list ] ;; determines if a pokemon is non-competitive to offer as a trade
  let offer [] ;; sets the default offer to nothing

  if length collection_list > 0 [
    foreach collection_list [ ;; checks each item in the collection for a turtle
      x -> if item 3 x = 0 [ ;;if the 3rd item (4th column from the original CSV) is 0, the pokemon is non-competitive and can be offered
        set offer x ;; sets the offer to the non-competitive pokemon
      ]
    ]
  ]
  report offer ;; returns the acceptable offer

end


to set-ask ;; determines what pokemon a turtle will ask for based on their playstyle
  ;; intializes list variables
  let ask_mon []  ;; variable to report pokemon turtle will ask for
  let possible_ask [] ;; internal list of possible asks given turtle playstyle

  let i 0 ;; integer variable

  if length current_offer > 0 [

    (ifelse ;; ifelse to determine how to proceed based on turtle's playstyle
      playstyle = 0 [ ;; Causal asks. Turtles with this playstyle will ask for pokemon +-1 time investment compared to their offer
        foreach pokemon [ ;; iterates through possible pokemon
          x -> if (item 2 x <= item 2 current_offer + 1) and (item 2 x >= item 2 current_offer - 1)[ ;; if a pokemon has at most +1 and at least -1 time investment proceed with code
            set possible_ask lput x possible_ask ;; adds eligible pokemon to list possible asks
          ]
        ]
      ]
      playstyle = 1 [ ;; Collector asks. Turtles with this playstyle will ask for pokemon +-1 time investment compared to their offer, and the ask must not be in their collection
        foreach pokemon [
          x -> if (item 2 x <= item 2 current_offer + 1) and (item 2 x >= item 2 current_offer - 1) and (x != one-of collection)[ ;; if a pokemon has at most +1 time investment and at least -1 time investment while not in the collection of the turtle the code proceeds
            set possible_ask lput x possible_ask ;; adds eligible pokemon to list of possible asks
          ]
        ]
      ]
      playstyle = 2 [ ;; Competitive asks. Turtles with this playstyle will ask for pokemon +-1 time investment compared to thier offer and only if the pokemon is competitively ranked
        foreach pokemon [
          x -> if (item 2 x <= item 2 current_offer + 1) and (item 2 x >= item 2 current_offer - 1) and (item 3 x != 0) [;; same as casual, but also checks to see if a pokemon has a competitive ranking. if all are true then code proceeds
            set possible_ask lput x possible_ask ;; adds eligible pokemon to list of possible asks
          ]
        ]
      ]
    )
  ]

  if length possible_ask > 0 [
     set i random(length possible_ask) ;; assigns a value to i for use in determining the asked for pokemon
     set ask_mon item (i) possible_ask
  ] ;; reports no ask if there are no eligible asks given the turtle's playstyle criteria

 set current_ask ask_mon


end


to exit-market
  let exit_condition 0
  let exit_control 0

  (ifelse
    playstyle = 0 [ ;; casual playstyle exit conditions
      set exit_condition (abs investment - 8)
      set exit_condition (random 20) - exit_condition

    ]
    playstyle = 1 [ ;; collector playstyle exit conditions
      if member? pokemon collection [
        set exit_condition 999
      ]
    ]
    playstyle = 2 [ ;; competitive playstyle exit conditions
      foreach pokemon [ x ->
        set exit_control exit_control + item 3 x

        if item 3 x > 0 [
          if member? x collection [
            set exit_condition exit_condition + item 3 x
          ]
        ]
      ]

      if exit_control > exit_condition [
        set exit_condition 0
      ]

    ])

  if exit_condition > 18 [
    set death_counter death_counter + 1

    (ifelse
      playstyle = 0 [set casual_deaths casual_deaths + 1]
      playstyle = 1 [set collector_deaths collector_deaths + 1]
      playstyle = 2 [set competitive_deaths competitive_deaths + 1]
    )

    die
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
45
55
109
88
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
45
94
150
128
Go Barter (1)
gobarter
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
7
452
121
497
Number of Agents
count turtles
17
1
11

BUTTON
44
133
204
167
Go Barter (Continuous)
gobarter
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
14
284
128
329
Trades
trades_executed
17
1
11

MONITOR
233
451
337
496
Market Exits
death_counter
17
1
11

MONITOR
121
452
225
497
Casual Turtles
count turtles with [playstyle = 0]
17
1
11

MONITOR
121
497
224
542
Collector Turtles
count turtles with [playstyle = 1]
17
1
11

MONITOR
120
542
224
587
Competitive Turtles
count turtles with [playstyle = 2]
17
1
11

MONITOR
14
237
128
282
Periods
turn_counter
17
1
11

MONITOR
337
451
447
496
Casual Exits
casual_deaths
17
1
11

MONITOR
337
497
447
542
Collector Exits
collector_deaths
17
1
11

MONITOR
337
540
447
585
Competitive Exits
competitive_deaths
17
1
11

BUTTON
45
7
123
41
Clear All
clear-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
233
497
337
542
 Exit per Turn
exit_rate
17
1
11

MONITOR
473
497
587
542
Entry per Turn
entrance_rate
17
1
11

MONITOR
473
452
586
497
Market Entries
entries
17
1
11

@#$#@#$#@
## Research Question

This model seeks to determine the viablity of barter system markets under different conditions. Does a system of bartered exchange allow for agents to be better or worse off than the more prevelent system of financial intermediary exchange?

In this alpha build of my model, the primary model parameters are:

*Global set of tradable goods
*Agent's set of tradable goods
*Agent ability to generate new goods
*Agent playstyle to determine willingness to offer certian goods, ask for certain goods, and exit the market
*Rate of entry for new market participants

The primary metric that the model measures is the number of completed trades. This measure can either be converted to a flow metric (trades per period) for comparision against subsequent runs or model alterations or can be used over a fixed set of periods to allow for comparison. 

## Justification

Modern barter system markets are reletively scarce, and as such observations of real-world market viabilty are difficult to obtain. By utilizing an Agent Based Model approach to this question we are able to study the effects on agents under different exchange methods.

## Primary Currency

The most important metric of this model is the number of completed trades required for the market participants to complete thier market exit conditions.

## Key Model Parameters

The key parameters for the model are as follows:

*Global set of tradable goods

This set of goods availible for all agents to select from upon intialization. This information is pulled from a CSV file and can be altered prior to each model run.

*Agent's set of tradable goods

Generated per agent based on the global available goods for the market. Each agent has a randomly generated set of initial goods and preferences. This set of goods will be referred to and adjusted as trades are executed. 

*Agent ability to generate new goods

This ability of the agent to generate new goods is determined randomly upon model initialization and is based on agent playstyle. 

*Agent playstyle to determine willingness to offer certian goods, ask for certain goods, and exit the market

Determines the agent's preferences for what they are willing to trade, what they want in return for that trade, and under what conditions they will exit the market. 

*Rate of entry for new market participants

Random number of new market participants enters each turn


## Initialization

Model intializes with 100 agents, each with randomly assigned intial collections of goods, their playstyle, and their ability to generate new goods. All agents start on the origin patch at (0,0) as their position will change based on their offer/ask.

## Stopping Condition

Since the model can either utilize either a rate of trade occurance or the absolute number of trades over a given period of time no stopping condition is included in the model. 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
