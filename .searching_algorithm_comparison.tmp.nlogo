turtles-own [
  light-intensity
  destination_turtle
  destination_light
]

globals []

extensions [py]

to setup
  clear-all
  setup-patches
  setup-turtles
  py:setup "python3"
  setup-levy-flight-py
  reset-ticks
end

to setup-patches
  repeat number_wall_patches [
    ask patch random-xcor random-ycor [
      set pcolor 33
    ]
  ]
  repeat number_target_patches [
    ask patch random-xcor random-ycor [
      set pcolor red
    ]
  ]
end

to setup-turtles
  create-turtles number_turtles
  ask turtles [
    setxy random-xcor random-ycor
    set light-intensity 0
    set destination_turtle -1
    set destination_light -1
    print "----"
    show color
    show who
  ]
end

to setup-levy-flight-py
  ;print (word "setting up levy-flight alg. - lmax="world-width)
  py:set "lmax" world-width
  py:set "lstep" world-width / 100

  (py:run
"from scipy.integrate import quad"
"import numpy"
""
"def getLevyFlightXY(ls = {'l0': 0, 'lmax':25, 'step': 0.25}, qs = {'q0': -25, 'qmax': 25}, a=2, B=1, coef = 1/(2*numpy.pi)):"
"    "
"    ls = numpy.arange( ls.get('l0', 0), ls.get('lmax', 25), ls.get('step', 0.25))"
"    qs = {"
"        'q0': qs.get('q0', -25),"
"        'qmax': qs.get('qmax', -1*qs.get('q0', -25))"
"    }"
""
;;"    print(f\"l=[{ls[0]}, {ls[-1]}]; q=({qs['q0']}, {qs['qmax']}); a={a}; B={B}; coef={format(coef, '.4f')}\")"
""
"    def func(q, a, B, l, coef):"
"        return (coef)*numpy.e**( -B * abs(q)**a ) * numpy.cos(q*l) "
""
"    def Func(ls, a, B, coef):"
"        res = numpy.zeros_like(ls)"
"        for i,val in enumerate(ls):"
"            y, err = quad(func, qs['q0'], qs['qmax'], args=(a, B, val, coef))"
"            res[i] = y"
"        return res"
""
"    cumsum = numpy.cumsum(Func(ls, a=a, B=B, coef=coef))"
"    last_Y = cumsum/cumsum[-1]"
"    #format(math.pi, '.2f')"
;;"    print(f\"x-min({ls[0]}, {format(last_Y[0], '.3f')}) y-max({ls[-1]}, {format(last_Y[-1], '.3f')})\")"
"    return ls, last_Y"
"    "
"x,y = getLevyFlightXY(ls = {'l0': 0, 'lmax': lmax, 'step': lstep})"
  )
end




to go
  if count turtles = 0 [ stop ]
  if count patches with [pcolor = red] = 0 [ stop ]
  check_light_around_simple
  move-turtles
  update-intensity
  check-patch
  check-death
  tick
end

to check_light_around_simple
  ask turtles [

    ifelse show-path
      [ pd ]
      [ pu ]
    let this_turtle who
    let tmp_destination_turtle who
    let tmp_destination_light -1
    ask max-one-of turtles in-radius light-sensor-range [ light-intensity ] [
      ifelse (this_turtle != who) and (light-intensity > 0)
      [
        set tmp_destination_turtle who
        set tmp_destination_light light-intensity
      ]
      [
        set tmp_destination_turtle -1
        set tmp_destination_light -1
      ]
     ]
    set destination_turtle tmp_destination_turtle
    set destination_light tmp_destination_light
    ifelse labels
    [
      ifelse destination_turtle != -1
      [
        set label (word who":"light-intensity"/"destination_turtle":"destination_light)
      ]
      [
        set label (word who":"light-intensity"/ No target")
      ]
    ]
    [ set label "" ]
  ]
end

to move-turtles
  ask turtles [
    ifelse ( destination_turtle != -1 and firefly-optimization )
    [
      go-to-destination_turtule who
    ]
    [
      secure-random-move who
    ]
  ]
end

to go-to-destination_turtule [turtle_number]
  ask turtle turtle_number [
    set heading towards turtle destination_turtle
    ifelse levy-flight
       [ make-levy-flight-step who ]
       [ fd 1 ]
  ]
end

to secure-random-move [turtle_number]
  ask turtle turtle_number [
    right random 360
    ask patch-ahead 1 [
      ifelse pcolor != 33
      [
        ask turtle turtle_number [
          ifelse levy-flight
            [ make-levy-flight-step who]
            [ fd 1 ]
        ]
      ]
      [ secure-random-move turtle_number ]
    ]
  ]
end

to make-levy-flight-step [turtle_number]
  ask turtle turtle_number [
    let step-length get-x-py (random 100)
    fd step-length
  ]
end

to-report get-x-py [value]
  py:set "i" value
  let step py:runresult "x[ numpy.abs(numpy.subtract.outer(y, i/100 )).argmin(0) ]"
  ; show "from py"
  ; show step
  report step
end



to update-intensity
  ask turtles [
    ifelse pcolor = red
    [
      set light-intensity light-intensity + additional-intensity
    ]
    [
      if light-intensity > 0 [
        set light-intensity light-intensity - 1
      ]
    ]
  ]
end

to check-patch
  ask turtles [
    if pcolor = red [
      set pcolor green
    ]
  ]
end

to check-death
  ask turtles [
    if pcolor = 33 [
      set pcolor 13
      die ;; can be commented
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
9
10
446
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
461
10
534
43
setup
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
538
10
601
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
608
10
713
55
Targets found
count patches with [pcolor = green]
17
1
11

MONITOR
716
10
837
55
Targets not found
count patches with [pcolor = red]
17
1
11

INPUTBOX
649
73
735
133
number_turtles
20.0
1
0
Number

INPUTBOX
558
72
645
132
number_target_patches
50.0
1
0
Number

INPUTBOX
461
72
554
132
number_wall_patches
0.0
1
0
Number

SLIDER
461
237
650
270
light-sensor-range
light-sensor-range
1
40
20.0
1
1
NIL
HORIZONTAL

SLIDER
461
275
655
308
additional-intensity
additional-intensity
0
33
10.0
1
1
NIL
HORIZONTAL

SWITCH
460
148
584
181
levy-flight
levy-flight
1
1
-1000

SWITCH
591
148
777
181
firefly-optimization
firefly-optimization
0
1
-1000

SWITCH
460
186
592
219
show-path
show-path
0
1
-1000

SWITCH
599
186
702
219
labels
labels
1
1
-1000

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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="m_lf-fo-targets" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="number_turtles">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_target_patches">
      <value value="1"/>
      <value value="4"/>
      <value value="8"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="light-sensor-range">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_wall_patches">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ca_lf-fo-targets" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="number_turtles">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_target_patches">
      <value value="1"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="light-sensor-range">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_wall_patches">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ca_lf-fo-targets" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="number_turtles">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_target_patches">
      <value value="1"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="light-sensor-range">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="additional-intensity">
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_wall_patches">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="ca_lf-fo-targets" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="number_turtles">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_target_patches">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="light-sensor-range">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="additional-intensity">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number_wall_patches">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
