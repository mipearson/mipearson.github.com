computeColour = (colourFrom, colourTo, percent) ->
  colours = for idx in [0..2]
    Math.floor((colourTo[idx] - colourFrom[idx]) * percent + colourFrom[idx])
  'rgb(' + colours.join(', ') + ')'

setSkyGradient = (colourFrom, colourTo, percent) ->
  # console.log colourFrom, colourTo, percent
  top = computeColour(colourFrom.top, colourTo.top, percent)
  bottom = computeColour(colourFrom.bottom, colourTo.bottom, percent) 
  gradientString = '(top, ' + top + ' 0%, ' + bottom + ' 100%)'
  $('body').css(background: top)
  $('body').css(background: "-webkit-linear-gradient#{gradientString}")
  $('body').css(background: "-moz-linear-gradient#{gradientString}")
  
setHills = (darkPercent) -> 
   $('#bg1').css(background: 'url(../images/hillslight.png) repeat-x bottom left');
   $('#bg2').css(background: 'url(../images/hillsdark.png) repeat-x bottom left').css(opacity: darkPercent);

setBGFromHour = (hour) ->
  if hour < 7
    setSkyGradient(midnight, sunrise, hour / 7)
  else if hour < 12
    setSkyGradient(sunrise, midday, (hour - 7) / 5)
  else if(hour < 19)
    setSkyGradient(midday, sunrise, (hour - 12) / 7)
  else
    setSkyGradient(sunrise, midnight, (hour - 19) / 5)

  if hour < 12
    setHills(1 - (hour / 12))
  else
    setHills((hour - 12) / 12)
  
midnight = 
  top: [0,0,0]
  bottom: [0,11,119]
sunrise = 
  top: [90,150,168]
  bottom: [255, 222, 147]
midday = 
  top: [135,224,253]
  bottom: [244,252,251]
    
now = new Date()
setBGFromHour(now.getHours() + now.getMinutes() / 60)