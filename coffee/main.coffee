

class Main
  constructor: () ->
    @mouseStatus = 0
    @currentTool = -1
    @canvas = $('#main-canvas')
    @ctx = @canvas[0].getContext('2d')
    @tools = []

  mouseDown: () ->
    @mouseStatus = 1

  mouseUp: () ->
    @mouseStatus = 0

  init: () ->
    toolDiv = $('#toolbox-wrapper')
    @tools.forEach (tool, idx) ->
      img = $('<img>').attr('src', 'img/' + tool.iconImg).addClass('tool-img')
      wrapDiv = $('<div>')
        .addClass('tool-icon')
        .append(img)
        .click ()->
          main.changeCurrentTool idx

        
      toolDiv.append(wrapDiv)

  changeCurrentTool: (idx) ->
    return if idx == @currentTool
    toolDiv = $('#toolbox-wrapper')
    toolDiv.children[idx].addClass 'active'
      
    

  

class Tools
  constructor: (o) ->
    _.extend @, o
    return

class ColorInput
  constructor: (o) ->
    _.extend @, o
    return

  val: () ->
    return '#000000'

pencilTool = new Tools
  controlVals: [
    new ColorInput(),
    #new RangeInput(),
  ]
  onMouseDown: (e) ->
    console.log @
    main.mouseDown()
    color = @controlVals[0].val()
    ctx = main.ctx
    ctx.beginPath()
    ctx.strokeStyle = color
    ctx.lineWidth = 5
    ctx.moveTo e.offsetX, e.offsetY
  iconImg: 'pencil-icon.svg'

main = new Main()
main.tools = [
  pencilTool,
  pencilTool,
  pencilTool,
  pencilTool,
]
main.init()




#handleMouseDown = (e) ->
  #color = $("#color1").spectrum("get").toHexString()
  #console.log color
  #Mainctx.beginPath()
  #Mainctx.strokeStyle = color
  #Mainctx.lineWidth = $('#range2').val()
  #Mainctx.moveTo(e.offsetX, e.offsetY)
  #window.mouseStatus = 1
  #return

#handleMouseMove = (e) ->
  #console.log e.offsetX, e.offsetY
  #console.log mouseStatus
  #if mouseStatus == 1
    #Mainctx.lineTo e.offsetX, e.offsetY
    #console.log e.offsetX, e.offsetY
    #Mainctx.stroke()
  #return

#handleMouseUp = (e) ->
  #window.mouseStatus = 0
  #return


#handleDocumentReady = () ->
  #window.MainCanvas = $('#main-canvas')
  #window.Mainctx = MainCanvas[0].getContext "2d"
  #window.mouseStatus = 0
  #can = MainCanvas[0]
  #can.width = MainCanvas.width()
  #can.height = MainCanvas.height()
  #can.onselectstart = () -> false
  #$("#color1").spectrum()
  #MainCanvas.mousedown( handleMouseDown )
  #MainCanvas.mousemove( handleMouseMove )
  #MainCanvas.mouseup( handleMouseUp )
  #MainCanvas.mouseleave( handleMouseUp )
  #return

#$( handleDocumentReady )
