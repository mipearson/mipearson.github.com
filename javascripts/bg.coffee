SkyBox = (gradientSelector, hillsSelector, hillsShadowSelector) ->
  @gradientSelector = gradientSelector
  @hillsSelector = hillsSelector
  @hillsShadowSelector = hillsShadowSelector
  
SkyBox::computeColour = (colourFrom, colourTo, percent) ->
  colours = for idx in [0..2]
    Math.floor((colourTo[idx] - colourFrom[idx]) * percent + colourFrom[idx])
  'rgb(' + colours.join(', ') + ')'

SkyBox::setSkyGradient = (colourFrom, colourTo, percent) ->
  # console.log colourFrom, colourTo, percent
  top = @computeColour(colourFrom.top, colourTo.top, percent)
  bottom = @computeColour(colourFrom.bottom, colourTo.bottom, percent) 
  gradientString = '(top, ' + top + ' 0%, ' + bottom + ' 100%)'
  $(@gradientSelector).css(background: top)
  $(@gradientSelector).css(background: "-webkit-gradient(linear, left top, left bottom, color-stop(0%,#{top}), color-stop(100%,#{bottom})")
  $(@gradientSelector).css(background: "-webkit-linear-gradient#{gradientString}")
  $(@gradientSelector).css(background: "-moz-linear-gradient#{gradientString}")
  
SkyBox::setHills = (darkPercent) -> 
   $(@hillsSelector).css(background: 'url(../images/hillslight.png) repeat-x bottom left');
   $(@hillsShadowSelector).css(background: 'url(../images/hillsdark.png) repeat-x bottom left').css(opacity: darkPercent);

SkyBox::render = (hour) ->
  if hour < 7
    @setSkyGradient(@midnight, @sunrise, hour / 7)
  else if hour < 12
    @setSkyGradient(@sunrise, @midday, (hour - 7) / 5)
  else if(hour < 19)
    @setSkyGradient(@midday, @sunrise, (hour - 12) / 7)
  else
    @setSkyGradient(@sunrise, @midnight, (hour - 19) / 5)

  if hour < 12
    @setHills(1 - (hour / 12))
  else
    @setHills((hour - 12) / 12)
  
SkyBox::midnight = 
  top: [0,0,0]
  bottom: [0,11,119]
SkyBox::sunrise = 
  top: [90,150,168]
  bottom: [255, 222, 147]
SkyBox::midday = 
  top: [135,224,253]
  bottom: [244,252,251]
  

skyBox = new SkyBox('body', '#bg1', '#bg2')
now = new Date()
skyBox.render(now.getHours() + now.getMinutes() / 60)
