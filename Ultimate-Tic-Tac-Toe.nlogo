globals
[
  ; turn based
  colorList colorNameList shapeList numOfTurn

  ; grids
  grids winGrid placeableGrid

  sizeScalar sizeFactor
  gameEnded
  highLighted

  moves moveIndex
]

; set up the board
to setup
  ca
  crt 1
  ; draw 9 by 9 grid
  let i 0
  while [i < 8]
  [
    ask turtle 0
    [
      ifelse ((i - 2) mod 3 = 0)
      [
        ; the thicker white lines
        set color white
        set pen-size 3
      ]
      [
        ; the thinner blue lines
        set color blue
        set pen-size 2
      ]
      ; horizontal lines
      pu
      setxy 0 (i + 0.5)
      set heading 90
      pd
      fd 9
      ; vertical lines
      pu
      setxy (i + 0.5) 0
      set heading 0
      pd
      fd 9
    ]
    set i i + 1
  ]

  ; kill the turtle used to draw lines
  ask turtle 0 [
    die
  ]

  initializeGrid

  ; initialize
  set colorList [red yellow]
  set colorNameList ["RED" "YELLOW"]
  set shapeList ["x" "circle"]

  set numOfTurn 0
  set winGrid 0

  set sizeScalar 0.75
  set sizeFactor 4

  set gameEnded false
  set highLighted 0

  set moves []
  set moveindex -1

  ; all black to start
  ask patches
  [
    set pcolor black
  ]
end

to initializeGrid
  ; one list for each of 9 tempGrids
  let tempGrids [ [[0][0][0]] [[0][0][0]] [[0][0][0]] ]
  ; put patches in tempGrids
  ask patches
  [
    ; find row and col
    let row int(pycor / 3)
    let col int(pxcor / 3)
    ; find list of grid correspond to this row
    let rowGrid (item row tempGrids)
    ; find the grid correspond to the patch
    let curGrid (item col rowGrid)
    ; modify the grid
    set curGrid (lput self curGrid)
    ; modify the list of grid
    set rowGrid (replace-item col rowGrid curGrid)
    ; modify the entire thing
    set tempGrids (replace-item row tempGrids rowGrid)
  ]
  ; reset grids
  set grids []
  ; remove 0 and put together
  foreach tempGrids
  [
    rowGrid ->
    let finalRowGrid []
    foreach rowGrid
    [
      ; put together each row
      curGrid -> set curGrid remove-item 0 curGrid
      set finalRowGrid (lput curGrid finalRowGrid)
    ]
    ; put everything together
    set grids (lput finalRowGrid grids)
  ]

  ; print to check
;  foreach grids
;  [
;    rowGrid ->
;    foreach rowGrid
;    [
;      curGrid -> print(curGrid)
;    ]
;  ]
end

to play
  ; if game didn't end yet
  if not gameEnded
  [
    ; find x y
    let x (round mouse-xcor)
    let y (round mouse-ycor)

    ; clear last highlighted if needed
    if (highLighted != 0)
    [
      ask highlighted
      [
        if (not (placeable x y))
        [
          set pcolor black
        ]
      ]
    ]

    set highLighted 0

    ; highlight
    ask patches
    [
      if (placeable x y)
      [
        set pcolor cyan
        set highLighted self
      ]
    ]

    ; when clicked
    if mouse-down? and highLighted != 0
    [
      ; need to clear
      while [moveIndex != (length moves) - 1]
      [
        set moves remove-item ((length moves) - 1) moves
      ]
      set moves (lput (list x y) moves)
      set moveIndex moveIndex + 1
      spawn x y
    ]
  ]
end

to spawn [x y]
  ; find the patch the mouse is on
  ask patches
	  [
    ; it has to be an empty square
    if (placeable x y)
    [
      set highlighted 0
      ; see whose turn it is
      sprout 1
      [
        set shape (item (numOfTurn mod 2) shapeList)
        set color (item (numOfTurn mod 2) colorList)
        set size sizeScalar
      ]
      ; check and increment
      check x y
      set numOfTurn numOfTurn + 1
      wait 0.1
    ]
  ]

  ; figure out new placeableGrid
  let row (y - (int(y / 3) * 3 + 1)) + 1
  let col (x - (int(x / 3) * 3 + 1)) + 1

  ; check the patch in the middle of the grid to go
  ask patches with [pxcor = (col * 3 + 1) and pycor = (row * 3 + 1)]
  [
    ; see if the grid ended
    ifelse (any? turtles-here and first [size] of turtles-here = (sizeFactor * sizeScalar))
    [
      ; anywhere if the grid is filled
      set placeableGrid 0
    ]
    [
      ; otherwise in the responding corner
      set placeableGrid (item col (item row grids))
    ]
  ]

  ; color the patches accordingly
  ask patches
  [
    ifelse (placeableGrid = 0 or member? self placeableGrid)
    [set pcolor black]
    [set pcolor gray]
  ]
end

to check [x y]
  ; get my grid
  let myGrid getGrid x y
  foreach myGrid
  [
    p ->
    ask p
    [
      ; check all turtles in this grid
      if any? turtles-here
      [
        ask turtles-here
        [
          ; check all directions
          set heading 0
          repeat 4
          [
            if (checkhelper 1 myGrid) and (checkhelper 2 myGrid)
            [
              set winGrid myGrid
            ]
            set heading heading + 90
          ]
          set heading 45
          repeat 4
          [
            if (checkhelper sqrt(2) myGrid) and (checkhelper (2 * sqrt(2)) myGrid)
            [
              set winGrid myGrid
            ]
            set heading heading + 90
          ]
        ]
      ]
    ]
  ]

  if (winGrid != 0)
  [
    ; spawn a large shape here
    let cx (int(x / 3) * 3 + 1)
    let cy (int(y / 3) * 3 + 1)
    ask patch cx cy
    [
      sprout 1
      [
        set shape (item (numOfTurn mod 2) shapeList)
        set color (item (numOfTurn mod 2) colorList)
        set size sizeFactor * sizeScalar
      ]
    ]

    set winGrid 0

    ; check for final winner
    finalCheck cx cy
  ]
end

to finalCheck [cx cy]
  ; check all directions
  ask turtles with [xcor = cx and ycor = cy]
  [
    set heading 0
    repeat 4
    [
      if (finalCheckhelper 3) and (finalCheckhelper 6)
      [
        set gameEnded true
      ]
      set heading heading + 90
    ]
    set heading 45
    repeat 4
    [
      if (finalCheckhelper (3 * sqrt(2))) and (finalCheckhelper (6 * sqrt(2)))
      [
        set gameEnded true
      ]
      set heading heading + 90
    ]
  ]

  ; announce winner
  if (gameEnded)
  [
    ; using color to determine text
    ifelse first [color] of turtles with [xcor = cx and ycor = cy] = (item 0 colorList)
    [
      output-print (sentence (item 0 colorNameList) "WON!!!")
    ]
    [
      output-print (sentence (item 1 colorNameList) "WON!!!")
    ]
  ]
end

; undo and redo
to undo
  ; check for invalid case
  ifelse (moveIndex >= 0)
  [
    set gameEnded false

    set numOfTurn numOfTurn - 1

    ; get the move by going back in moves list
    let lastMove (item moveIndex moves)
    set moveIndex moveIndex - 1
    let x first lastMove
    let y last lastMove

    ; kill the turtle and set the correct grid
    ask turtles with [xcor = x and ycor = y] [die]
    set placeableGrid (getGrid x y)

    ; edge case of ending grid
    let cxy (getCXY x y)
    ask turtles with [xcor = first cxy and ycor = last cxy]
    [
      if (size = sizeFactor * sizeScalar)
      [die]
    ]

    ; color the patches accordingly
    set highlighted 0
    ask patches
    [
      ; edge case of 0
      ifelse (moveIndex = -1 or placeableGrid = 0 or member? self placeableGrid)
      [set pcolor black]
      [set pcolor gray]
    ]
  ]
  [
    output-print ("Invalid")
  ]
end

to redo
  ; check for invalid case
  ifelse moveIndex < (length moves - 1)
  [
    ; advance through the moves list
    set moveIndex moveIndex + 1
    let nextMove (item moveIndex moves)
    spawn (first nextMove) (last nextMove)
  ]
  [
    output-print ("Invalid")
  ]
end

; Helper Methods

; check if placeable
to-report placeable [x y]
  ; correct coordinate, empty square, and in correct grid by color
  report pxcor = x and pycor = y and any? turtles-here = false and pcolor != gray
end

; check if it is a connected len ahead
to-report checkhelper [len myGrid]
  ; first checks if there are 2 turtles in a row,
  if any? turtles-on (patch-ahead len)
  [
    ; check if 2 turtles are in the same smaller grid.
    if member? (patch-ahead len) myGrid
    [
      ; check if these 2 turtles are the same color
      if first [color] of (turtles-on patch-ahead len) = [color] of self
      [
        report true
      ]
    ]
  ]
  report false
end

; check if it is a connected len ahead
to-report finalCheckHelper [len]
  ; first checks if there are 2 turtles in a row,
  if any? turtles-on (patch-ahead len)
  [
    ; check if these 2 turtles are the same size
    if first [size] of (turtles-on patch-ahead len) = sizeScalar * sizeFactor
    [
      ; check if these 2 turtles are the same color
      if first [color] of (turtles-on patch-ahead len) = [color] of self
      [
        report true
      ]
    ]

  ]
  report false
end

; get the grid for this coordinate
to-report getGrid [x y]
  let row int(y / 3)
  let col int(x / 3)
  report (item col (item row grids))
end

; get the coordinates of the center of the grid the given coordinate belong to
to-report getCXY [x y]
  let cx (int(x / 3) * 3 + 1)
  let cy (int(y / 3) * 3 + 1)
  report (list cx cy)
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
668
469
-1
-1
50.0
1
10
1
1
1
0
1
1
1
0
8
0
8
0
0
1
ticks
30.0

BUTTON
39
31
106
64
NIL
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
39
91
102
124
NIL
play
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
15
144
155
198
13

BUTTON
20
234
84
267
NIL
undo
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
96
235
159
268
NIL
redo
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
41
288
119
321
Free Play
ask patches [set pcolor black]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
