;; Intializaation of model and extentions
;; Definition of global variables and turtle properties

extensions [
  csv
]

globals [
  goods
  filename
  trades_executed
  trade_log
  agg_happiness
  agg_happiness_log
  prev_agg_happiness
  avg_happiness
  avg_happiness_log
  delta_happiness
  delta_happiness_log
  trade_rate
  trade_rate_log
  H
  H_log
  EH
  EH_log
]

turtles-own [
  goods_set
  current_offer
  current_ask
  dollars
  happiness
  avg_utility
]

to setup ;; sets the initial conditions for the ABM
  clear-all ;; clears previous data
  reset-ticks

  file-close-all ;; closes any still opened files
  set filename "F:/Users/Devan/Documents/ECO581/Model Data/goods data.csv" ;; sets variable with path to goods data file

  set goods csv:from-file filename ;; creates list of lists containing goods data from csv
  set goods remove-item 0 goods ;; removes the header row from the list

  set trades_executed 0
  set trade_rate 0

  set agg_happiness_log []
  set avg_happiness_log []
  set delta_happiness_log []
  set trade_log []
  set trade_rate_log []
  set H_log []
  set EH_log []

  turtle-maker initial_agents ;; calls the turtle-maker process to creat 100 agents for the market

  set agg_happiness sum [happiness] of turtles
  set agg_happiness_log fput agg_happiness agg_happiness_log

  set avg_happiness agg_happiness / count turtles
  set avg_happiness_log fput avg_happiness avg_happiness_log

  set delta_happiness 0


end


;; Main model operation function

to market
  ask turtles [
    set-ask
    set-offer
  ]

  ask turtles [ trade ]
  ask turtles [ wander ]

  offer-histogram
  ask-histogram

  tick-advance 1

  set prev_agg_happiness item 0 agg_happiness_log

  set agg_happiness sum [happiness] of turtles
  set agg_happiness_log fput agg_happiness agg_happiness_log

  set avg_happiness agg_happiness / count turtles
  set avg_happiness_log fput avg_happiness avg_happiness_log

  set delta_happiness agg_happiness - prev_agg_happiness
  set delta_happiness_log fput delta_happiness delta_happiness_log

  set trade_rate trades_executed / ticks
  set trade_rate_log fput trade_rate trade_rate_log

  set H shannon-diversity
  set H_log fput H H_log

  set EH shannon-equitability
  set EH_log fput EH EH_log

  do-plots

  if ticks > max_iterations [
    stop
  ]
end


;; Turtle generation and property calculations

to turtle-maker [amount] ;; generates turtle and initial turtle variables
  ;; used on setup and throughout run to create new turtles to participate in the market
  create-turtles amount [ ;; calls the create-turtles function

    let i 0
    let utility 0
    let quantity 0
    let sum_utility 0

    set goods_set [] ;;initialize each turtle's goods_set of goods
    set current_offer [] ;;initializes the turtle's current offered goods
    set current_ask [] ;; intitializes the turtle's current asked for goods

    set happiness 0 ;; intitializes the happiness variable

    foreach goods [ ;; generates the trutle's utility values for each good from the set of all goods
      x ->
      set x lput random 11 x
      set x lput random 11 x ;; sets the utility range from 0 to 10 randomly
      set goods_set fput x goods_set ;; adds each item and utility pair to the turtle's utility set
    ]

    foreach goods_set [ x ->
      set sum_utility sum_utility + item 2 x

    ]

    set avg_utility round (sum_utility / (length goods_set))

    set dollars random 10 + 1

    set xcor ((random 33) - 16) ;; assigns random x coordinate
    set ycor ((random 33) - 16) ;; assigns ranomd y coordinate

    set-happiness
  ]

end

to set-happiness

  set happiness 0

  foreach goods_set [ x ->

    set happiness happiness + (item 1 x * item 2 x)

  ]

  if system_type = "Monetary" [
    set happiness happiness + (avg_utility * dollars)
  ]

end

to set-offer ;; calculates the goods a turtle is willing to offer as a trade based on the playstyle and goods_set set of the turtle
  ;;intialize variables
  let offer_set []
  let inspected_good []

  let length_goods length goods_set
  let i 0

  set offer_set utility-sort 0 goods_set

  while [i < length_goods][

    set inspected_good item i offer_set

    if item 1 inspected_good >= 1 [
      set current_offer inspected_good
      set i length_goods
    ]

    set i i + 1
  ]
end

to set-ask ;; determines what goods a turtle will ask for based on their playstyle
  ;; intializes list variables
  let ask_set []
  let inspected_good []

  let length_goods length goods_set
  let i 0

  set ask_set utility-sort 1 goods_set

  while [i < length_goods][

    set inspected_good item i ask_set

    if item 1 inspected_good < 10 [
      set current_ask inspected_good
      set i length_goods
    ]

    set i i + 1
  ]

end


;; Turtle market actions

to wander
  set heading random 4 * 90
  fd 1
end

to trade
  if trade-match [
    (ifelse
      system_type = "Barter" [
        execute-trade-barter
        if current_ask = [] and current_offer = [] [
          set trades_executed trades_executed + 1
        ]
      ]
      system_type = "Monetary" [
       execute-trade-monetary
      ]
    )
  ]

end


;; Functions enabling turtles to exchange goods

to execute-trade-monetary

  if trade-match [
    let partner one-of other turtles-here with [(item 0 current_ask = item 0 [current_offer] of myself) or (item 0 current_offer = item 0 [current_ask] of myself)]

    if (item 0 [current_ask] of partner = item 0 current_offer) [
      sell-good partner

    ]
    if (item 0 [current_offer] of partner = item 0 current_ask) [
      buy-good partner
    ]
  ]
end

to execute-trade-barter
  let good1 ""
  let good2 ""
  let main_offer_ask ""

  let possible_trade []
  let exchange_set []
  let trade_pair []

  let good1_quant 0
  let good2_quant 0
  let good1_main_quant 0
  let good1_partner_quant 0
  let good2_main_quant 0
  let good2_partner_quant 0
  let good1_main_util 0
  let good1_partner_util 0
  let good2_main_util 0
  let good2_partner_util 0


  if trade-match [
    set main_offer_ask "barter"

    let partner one-of other turtles-here with [(item 0 current_ask = item 0 [current_offer] of myself) and (item 0 current_offer = item 0 [current_ask] of myself)]

    ask partner [
      set good1 item 0 current_ask
      set good2 item 0 current_offer

      set good1_partner_quant item 1 current_ask
      set good2_partner_quant item 1 current_offer
      set good1_partner_util item 2 current_ask
      set good2_partner_util item 2 current_offer
    ]

      set good1_main_quant item 1 current_offer
      set good2_main_quant item 1 current_ask
      set good1_main_util item 2 current_offer
      set good2_main_util item 2 current_ask

    set good1_quant min list good1_main_quant good1_partner_quant
    set good2_quant min list good2_main_quant good2_partner_quant

   if good1_quant > 0 and good2_quant > 0 [
    set exchange_set generate-quantity-pairs good1_quant good2_quant

    set possible_trade generate-positive-net-utility-pairs exchange_set good1_main_util good1_partner_util good2_main_util good2_partner_util
  ]

  if length possible_trade > 0 [
    set trade_pair determine-trade-pair possible_trade

    exchange-goods partner trade_pair main_offer_ask

    log-trade good1 item 0 trade_pair good2 item 1 trade_pair
    set-happiness

    ask partner [
      log-trade good2 item 1 trade_pair good1 item 0 trade_pair
      set-happiness

    ]
   ]
  ]

end

to buy-good [ partner ]
  let good1 ""
  let good2 ""
  let main_offer_ask ""

  let trade_pair []
  let buy_set []
  let possible_trade []

  let good1_quant 0
  let good2_quant 0
  let good1_main_util 0
  let good1_partner_util 0
  let good2_main_util 0
  let good2_partner_util 0


  set main_offer_ask "ask"
  set good1 "dollar(s)"
  set good2 item 0 current_ask

  set good2_quant item 1 [current_offer] of partner
  set good2_partner_util item 2 [current_offer] of partner
  set good1_partner_util [avg_utility] of partner

  set good1_quant dollars
  set good2_main_util item 2 current_ask
  set good1_main_util avg_utility

  if good1_quant > 0 and good2_quant > 0 [
    set buy_set generate-quantity-pairs good1_quant good2_quant

    set possible_trade generate-positive-net-utility-pairs buy_set good1_main_util good1_partner_util good2_main_util good2_partner_util
  ]

  if length possible_trade > 0 [
    set trade_pair determine-trade-pair possible_trade

    exchange-goods partner trade_pair main_offer_ask

    set-happiness
    log-trade good1 item 0 trade_pair good2 item 1 trade_pair

    ask partner [
      set-happiness
      log-trade good2 item 1 trade_pair good1 item 0 trade_pair
    ]

  ]


end

to sell-good [ partner ]
  let good1 ""
  let good2 ""
  let main_offer_ask ""

  let trade_pair []
  let buy_set []
  let possible_trade []

  let good1_quant 0
  let good2_quant 0
  let good1_main_util 0
  let good1_partner_util 0
  let good2_main_util 0
  let good2_partner_util 0


  set main_offer_ask "offer"
  set good1 item 0 current_offer
  set good2 "dollar(s)"

  set good1_quant item 1 current_offer
  set good1_main_util item 2 current_offer
  set good2_main_util avg_utility

  set good2_quant [dollars] of partner
  set good1_partner_util item 1 [current_ask] of partner
  set good2_partner_util [avg_utility] of partner

  if good1_quant > 0 and good2_quant > 0 [
    set buy_set generate-quantity-pairs good1_quant good2_quant

    set possible_trade generate-positive-net-utility-pairs buy_set good1_main_util good1_partner_util good2_main_util good2_partner_util
  ]

  if length possible_trade > 0 [
    set trade_pair determine-trade-pair possible_trade

    exchange-goods partner trade_pair main_offer_ask

    set-happiness
    log-trade good1 item 0 trade_pair good2 item 1 trade_pair

    ask partner [
      set-happiness
      log-trade good2 item 1 trade_pair good1 item 0 trade_pair
    ]

  ]


end

to exchange-goods [ partner trade_pair main_offer_ask]
  let good1_quant 0
  let good2_quant 0

  let temp_list []

  set good1_quant item 0 trade_pair
  set good2_quant item 1 trade_pair

  (ifelse
    system_type = "Monetary" [
    (ifelse
      main_offer_ask = "ask" [
        set temp_list current_ask
        set temp_list replace-item 1 temp_list (item 1 current_ask + good2_quant)

        set dollars dollars - good1_quant
        set goods_set replace-item (position current_ask goods_set) goods_set temp_list

        set current_ask []

        ask partner [
          set temp_list current_offer
          set temp_list replace-item 1 temp_list (item 1 current_offer - good2_quant)

          set dollars dollars + good1_quant
          set goods_set replace-item (position current_offer goods_set) goods_set temp_list

          set current_offer []
        ]
      ]
      main_offer_ask = "offer" [
        set temp_list current_offer
        set temp_list replace-item 1 temp_list (item 1 current_offer - good1_quant)

        set dollars dollars + good2_quant
        set goods_set replace-item (position current_offer goods_set) goods_set temp_list

        set current_offer []

        ask partner [
          set temp_list current_ask
          set temp_list replace-item 1 temp_list (item 1 current_ask + good1_quant)

          set goods_set replace-item (position current_ask goods_set) goods_set temp_list

          set dollars dollars - good2_quant

          set current_ask []
        ]
      ]
     )
    ]
    system_type = "Barter" [
      set temp_list current_ask
      set temp_list replace-item 1 temp_list (item 1 current_ask + good2_quant)

      set goods_set replace-item (position current_ask goods_set) goods_set temp_list

      set temp_list current_offer
      set temp_list replace-item 1 temp_list (item 1 current_offer - good1_quant)

      set goods_set replace-item (position current_offer goods_set) goods_set temp_list

      set current_ask []
      set current_offer []

      ask partner [
        set temp_list current_ask
        set temp_list replace-item 1 temp_list (item 1 current_ask + good1_quant)

        set goods_set replace-item (position current_ask goods_set) goods_set temp_list

        set temp_list current_offer
        set temp_list replace-item 1 temp_list (item 1 current_offer - good2_quant)

        set goods_set replace-item (position current_offer goods_set) goods_set temp_list

        set current_ask []
        set current_offer []
      ]
    ]

  )

  set trades_executed trades_executed + 1
end


;; Report returning functions used in higher level turtle behavior

to-report trade-match ;; goods trade mechanics - checks for offer/ask match and adjusts each turtles' goods_set if a match is found
  let ask_set (current_ask = [])
  let offer_set (current_offer = [])

  if system_type = "Barter"[
    (ifelse
      any? other turtles-here with [current_ask = [] or current_offer = []][

      ]
      ask_set or offer_set [

      ]
      any? other turtles-here with [(item 0 current_ask = item 0 [current_offer] of myself) and (item 0 current_offer = item 0 [current_ask] of myself)] [
        report true
      ]
    )
  ]

  if system_type = "Monetary" [
    (ifelse
      any? other turtles-here with [current_ask = [] or current_offer = []][

      ]
      ask_set or offer_set [

      ]
      any? other turtles-here with [(item 0 current_ask = item 0 [current_offer] of myself) or (item 0 current_offer = item 0 [current_ask] of myself)] [
        report true
      ]
    )
  ]

  report false

end

to-report generate-quantity-pairs [ good1_quant good2_quant ]
  let i 1
  let j 1

  let trade_set []
  let temp_list []

  while [ i <= good1_quant ] [

      set j 1

      while [ j <= good2_quant ] [
        set temp_list []

        set temp_list lput i temp_list
        set temp_list lput j temp_list

        set trade_set lput temp_list trade_set

        set j j + 1

      ]

      set i i + 1

    ]

  report trade_set

end

to-report generate-positive-net-utility-pairs [ trade_set good1_main_util good1_partner_util good2_main_util good2_partner_util ]

  let possible_trade []
  let temp_list []

  let good1_in 0
  let good1_out 0
  let good2_in 0
  let good2_out 0

  let net_main_util 0
  let net_partner_util 0

  foreach trade_set [ x ->
    set temp_list []

    set good1_out item 0 x * (-1)
    set good1_in item 0 x
    set good2_out item 1 x * (-1)
    set good2_in item 1 x

    set net_main_util (good1_out * good1_main_util) + (good2_in * good2_main_util)
    set net_partner_util (good2_out * good2_partner_util) + (good1_in * good2_partner_util)

    if net_main_util > 0 and net_partner_util > 0 [
      set temp_list lput good1_in temp_list
      set temp_list lput good2_in temp_list

      set possible_trade lput temp_list possible_trade

    ]

  ]

  report possible_trade

end

to-report determine-trade-pair [ possible_trade ]
  let trade_pair []

  Let trade_decision 0

  set trade_decision random (length possible_trade)

  set trade_pair item trade_decision possible_trade

  report trade_pair


end

to-report utility-sort [ method target ] ;;returns a sorted list based on utility
  (ifelse
    method = 0 [
      report sort-by [ [a b] -> (item 2 a) < (item 2 b) ] target
    ]
    method = 1 [
      report sort-by [ [a b] -> (item 2 a) > (item 2 b) ] target
    ]
  )
end


;; Global variable calculations and reporting

to offer-histogram
  set-current-plot "Offers"
  clear-plot

  let temp_list []
  let chart_counts []

  let temp 0
  let i 1

  let step 0.05

  let pen_color hsb 0 0 0

  let plot_point ""

  if goods != 0 [

    foreach goods [
      x ->
      set temp_list lput item 0 x temp_list

    ]

    foreach temp_list [
      x ->
      set temp count turtles with [current_offer != [] and item 0 current_offer = x]
      set chart_counts lput temp chart_counts
    ]

    set temp length chart_counts
    set-plot-x-range 0 (temp + 2)
    set-plot-y-range 0 (round ((count turtles / temp) * 1.5))


    foreach chart_counts [
      y ->

      set plot_point item (i - 1) temp_list
      set pen_color hsb (i * (360 / temp)) 50 75

      create-temporary-plot-pen plot_point
      set-plot-pen-mode 1
      set-plot-pen-color pen_color

      foreach (range 0 y step) [j -> plotxy i j]

      set-plot-pen-color black

      plotxy i y

      set-plot-pen-color pen_color

      set i i + 1
    ]
  ]

end

to ask-histogram
  set-current-plot "Asks"
  clear-plot

  let temp_list []
  let chart_counts []

  let temp 0
  let i 1

  let step 0.05

  let pen_color hsb 0 0 0

  let plot_point ""

  if goods != 0 [

    foreach goods [
      x ->
      set temp_list lput item 0 x temp_list

    ]

    foreach temp_list [
      x ->
      set temp count turtles with [current_ask != [] and item 0 current_ask = x]
      set chart_counts lput temp chart_counts
    ]

    set temp length chart_counts
    set-plot-x-range 0 (temp + 2)
    set-plot-y-range 0 (round ((count turtles / temp) * 1.5))


    foreach chart_counts [
      y ->

      set plot_point item (i - 1) temp_list
      set pen_color hsb (i * (360 / temp)) 50 75

      create-temporary-plot-pen plot_point
      set-plot-pen-mode 1
      set-plot-pen-color pen_color

      foreach (range 0 y step) [j -> plotxy i j]

      set-plot-pen-color black

      plotxy i y

      set-plot-pen-color pen_color

      set i i + 1
    ]
  ]
end

to do-plots

  set-current-plot "Aggregate Happiness"
  plot agg_happiness
  set-plot-x-range 0 ticks
  set-plot-y-range (round (min agg_happiness_log) - 1) (round (max agg_happiness_log) + 1)

  set-current-plot "Average Happiness"
  plot avg_happiness
  set-plot-x-range 0 ticks
  set-plot-y-range (round (min avg_happiness_log) - 1) (round (max avg_happiness_log) + 1)

  set-current-plot "Happiness Delta"
  plot delta_happiness
  set-plot-x-range (ticks - 25) ticks
  set-plot-y-range (round (min delta_happiness_log) - 1) (round (max delta_happiness_log) + 1)

  set-current-plot "Richness"
  plot H
  set-plot-x-range 0 ticks
  set-plot-y-range (round (min H_log) - 1) (round (max H_log) + 1)

  set-current-plot "Evenness"
  plot EH
  set-plot-x-range 0 ticks
  set-plot-y-range (round (min EH_log) - 1) (round (max EH_log) + 1)

  set-current-plot "Average Money"
  plot mean [dollars] of turtles
  set-plot-x-range 0 ticks
  set-plot-y-range (round (min [dollars] of turtles) - 1) (round (max [dollars] of turtles) + 1)
end

to log-trade [ gave_good gave_good_quant receive_good receive_good_quant ]
  let temp_list []

  set temp_list lput who temp_list
  set temp_list lput "gave_up" temp_list
  set temp_list lput gave_good_quant temp_list
  set temp_list lput gave_good temp_list
  set temp_list lput "and_received" temp_list
  set temp_list lput receive_good_quant temp_list
  set temp_list lput receive_good temp_list
  set temp_list lput "on_tick_#" temp_list
  set temp_list lput ticks temp_list

  set trade_log fput temp_list trade_log

  print temp_list

end

to-report shannon-diversity
  let shannon_log []

  let sdi 0
  let h_freq 0
  let h_proportion 0
  let ln_proportion 0
  let product_proportion_ln 0

  foreach [happiness] of turtles [ x ->
    set h_freq count turtles with [happiness = x]
    set h_proportion (h_freq / (count turtles))
    set ln_proportion ln(h_proportion)
    set product_proportion_ln (ln_proportion * h_proportion)

    set shannon_log lput product_proportion_ln shannon_log
  ]

  set sdi (-1) * sum shannon_log

  report sdi

end

to-report shannon-equitability
  let sei 0
  let count_categories 0

  foreach [happiness] of turtles [ x ->
    set count_categories count_categories + 1
  ]

  set sei H / ln(count_categories)

  report sei
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
11
57
88
90
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
703
283
817
328
Number of Agents
count turtles
17
1
11

MONITOR
703
331
817
376
Trades
trades_executed
17
1
11

BUTTON
11
20
89
54
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

INPUTBOX
706
159
861
219
Initial_Agents
100.0
1
0
Number

BUTTON
94
20
189
53
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
94
57
189
90
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

PLOT
8
454
492
663
Offers
Items
Offers
0.0
10.0
0.0
10.0
false
true
"\n" ""
PENS

PLOT
7
668
492
880
Asks
Items
Asks
0.0
10.0
0.0
10.0
false
true
"" ""
PENS

PLOT
495
455
695
605
Aggregate Happiness
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plotxy ticks agg_happiness"

PLOT
495
609
695
759
Average Happiness
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -7500403 true "" ""

PLOT
495
761
695
911
Happiness Delta
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -7500403 true "" ""

MONITOR
703
379
817
424
Tick Count
ticks
17
1
11

MONITOR
819
282
972
327
Trade Rate
precision trade_rate 3
17
1
11

MONITOR
820
376
972
421
Trade Rate STD Dev
precision standard-deviation trade_rate_log 3
17
1
11

MONITOR
820
330
972
375
Average Trade Rate
precision mean trade_rate_log 3
17
1
11

CHOOSER
706
49
844
94
System_Type
System_Type
"Monetary" "Barter"
1

PLOT
697
456
897
606
Richness
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
697
609
897
759
Evenness
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

INPUTBOX
706
97
861
157
Max_Iterations
1000.0
1
0
Number

PLOT
697
762
897
912
Average Money
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

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
