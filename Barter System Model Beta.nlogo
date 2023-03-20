extensions [
  csv
]

globals [
  goods
  comp_goods
  filename
  trades_executed
  barter
  fininterm
]
turtles-own [
  goods_set
  current_offer
  current_ask
  dollars
]


to setup ;; sets the initial conditions for the ABM
  clear-all ;; clears previous data
  reset-ticks

  file-close-all ;; closes any still opened files
  set filename "F:/Users/Devan/Documents/ECO581/Model Data/goods data.csv" ;; sets variable with path to goods data file

  set goods csv:from-file filename ;; creates list of lists containing goods data from csv
  set goods remove-item 0 goods ;; removes the header row from the list

  set trades_executed 0

  (ifelse
    market_method = "Barter" [
      set fininterm 0
      set barter 1
    ]
    market_method = "Financial Intermediary" [
      set fininterm 1
      set barter 0
    ]
   )

  print goods ;; displays list - debugging only

  turtle-maker initial_agents ;; calls the turtle-maker process to creat 100 agents for the market


end


to market
  ask turtles [
    set-ask
    set-offer
    wander
    trade
  ]


  tick-advance 1
end


to wander
  let temp_offer []
  let temp_ask []

  set temp_offer current_offer
  set temp_ask current_ask

  (ifelse
    any? other turtles-here [

    ]
    (any? turtles-on neighbors) [
      move-to one-of turtles-on neighbors
    ]
    (not any? other turtles-here) and (not any? turtles-on neighbors) and (unlimited_information) [
      (ifelse
        any? turtles with [(current_ask = temp_offer) or (current_offer = temp_ask)][
          move-to one-of turtles with [(current_ask = temp_offer) or (current_offer = temp_ask)]
        ]
        not any? turtles with [(current_ask = temp_offer) or (current_offer = temp_ask)][
          set heading (random 4 * 90)
          fd 1
        ]
      )
    ]
    (not any? other turtles-here) and (not any? turtles-on neighbors) and (not unlimited_information) [
      set heading (random 4 * 90)
      fd 1
    ]
  )



end



to trade ;; goods trade mechanics - checks for offer/ask match and adjusts each turtles' goods_set if a match is found
  let main_offer [] ;; intializes the temp_offer list
  let main_ask [] ;; initializes the temp_ask list

  let offer_ask_match False
  let ask_offer_match False

  let offer_set False
  let ask_set False

  let main_offer_set False
  let main_ask_set False

  let trade_execute false ;; intializes trade execute to default value of false

  set main_offer current_offer ;; sets the temp_ask list to the main turtle's current offer
  set main_ask current_ask ;; sets the temp_offer list to the main turtle's current ask

  set main_offer_set (length main_offer > 0)
  set main_ask_set (length main_ask > 0)


  if any? other turtles-here [ ;; continues if there are other turtles on the same spaces as the main turtle
    print main_offer
    print main_ask
    ask one-of other turtles-here [ ;; begins to compare the main and trade partner turtles
      print current_offer
      print current_ask

      set offer_set (length current_offer > 0)
      set ask_set (length current_ask > 0)

        if main_offer_set and ask_set [
          set offer_ask_match (item 0 main_offer = item 0 current_ask)
        ]
        if main_ask_set and offer_set [
          set ask_offer_match (item 0 main_ask = item 0 current_offer)
        ]
        if not ask_lock [
          (ifelse
            main_offer_set and not ask_set[

            ]
            not main_ask_set and offer_set [

            ]
          )
        ]
        if not offer_lock [
          (ifelse
            not main_offer_set and ask_set []
            main_ask_set and not offer_set []
          )
        ]


        if offer_ask_match and ask_offer_match[ ;; trade will execute if both turtles match in offer and ask
          set goods_set remove-item (position current_offer goods_set) goods_set ;; removes the trade partner's offered goods from their goods_set
          set goods_set lput current_ask goods_set ;; adds the trade partner's ask to their goods_set

          print (word "Trade executed! " current_ask " was traded for " main_offer)

          set current_ask [] ;; clears the ask of the trade partner
          set current_offer [] ;; clears the offer of the trade partner


          set trade_execute true ;; sets the trade esecute value to 1 for yes

          set trades_executed trades_executed + 1
        ]

      move-to one-of patches with [ not any? turtles-here ]

       ]
     ]

    if trade_execute [ ;; executes goods_set changes if a trade match occurred
      set goods_set remove-item (position current_offer goods_set) goods_set ;; removes the main turtle's offer from their goods_set
      set goods_set lput current_ask goods_set ;; adds the ask to the main turtle's goods_set

      set current_offer [] ;; clears the ask of the main turtle
      set current_ask [] ;; clears the offer of the main turtle
    ]
end


to-report sort-with [ key lst ] ;;returns a sorted list
  report sort-by [ [a b] -> (runresult key a) < (runresult key b) ] lst
end


to turtle-maker [amount] ;; generates turtle and initial turtle variables
  ;; used on setup and throughout run to create new turtles to participate in the market
  create-turtles amount [ ;; calls the create-turtles function

    set goods_set [] ;;initialize each turtle's goods_set of goods
    set current_offer [] ;;initializes the turtle's current offered goods
    set current_ask [] ;; intializes the turtle's current asked for goods

    let initial_goods_set random (length goods) + 1 ;; selects a random size for each turtle's initial goods_set
    let i 0 ;;initialized the counter variable

    ;; The following loop creates an initial list of owned goods for each turtle that enters the market that is some random number of goods
    ;; The number of goods for each turtle initially is random but less than or equal to the number of all goods
    ;; Turtles may have duplicate goods as a result of this
    while [i < initial_goods_set][
      set goods_set lput item (random (length goods)) goods goods_set ;; adds new goods to the end of the turtle's goods_set list
      set i i + 1 ;;iterates the loop
    ]

    set dollars random 10
    set xcor ((random 33) - 16)
    set ycor ((random 33) - 16)


    show goods_set
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


to set-offer ;; calculates the goods a turtle is willing to offer as a trade based on the playstyle and goods_set set of the turtle
  ;;intialize variables
  let proceed 0

  if not offer_lock [
   set proceed random 2
  ]

  if length current_offer > 0 [
    set proceed 2
  ]

  if proceed < 1 [
    set current_offer one-of goods_set
  ]


end


to set-ask ;; determines what goods a turtle will ask for based on their playstyle
  ;; intializes list variables
  let proceed 0

  if not ask_lock [
    set proceed random 2
  ]

  if length current_ask > 0 [
    set proceed 2
  ]

  if proceed < 1 [
    set current_ask one-of goods
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

MONITOR
7
400
121
445
Trades
trades_executed
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

CHOOSER
707
43
884
88
market_method
market_method
"Barter" "Financial Intermediary"
0

SWITCH
707
90
884
123
Offer_Lock
Offer_Lock
0
1
-1000

SWITCH
707
126
884
159
Ask_Lock
Ask_Lock
0
1
-1000

SWITCH
707
162
884
195
Unlimited_Information
Unlimited_Information
1
1
-1000

INPUTBOX
706
210
861
270
Initial_Agents
100.0
1
0
Number

BUTTON
451
550
589
583
NIL
wander
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

BUTTON
92
128
187
161
Run Market
market
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
92
169
187
202
Run Market
market
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
279
574
368
619
Potato Offers
count turtles with [current_offer = [\"Potato\"]]
17
1
11

MONITOR
371
575
450
620
Potato Asks
count turtles with [current_ask = [\"Potato\"]]
17
1
11

MONITOR
376
707
472
752
Onion for Potato
count turtles with [current_offer = [\"Potato\"] and current_ask = [\"Onion\"]]
17
1
11

MONITOR
376
657
481
702
Potato for Onion
count turtles with [current_offer = [\"Onion\"] and current_ask = [\"Potato\"]]
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
