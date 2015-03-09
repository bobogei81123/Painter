
# Math 
Math.random2DNormal = (c = 1) ->
  r = Math.sqrt(-2.0 * Math.log( Math.random() ) )
  theta = Math.random() * 2.0 * Math.PI
  return [c * r * Math.cos(theta), c * r * Math.sin(theta)]

Math.euclidDistance = (x1, y1, x2, y2) ->
  Math.sqrt( (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2) )

#Main
class Main
  constructor: () ->
    @mouseStatus = 0
    @currentTool = -1
    @canvas = $('#main-canvas')
    @bcanvas = $('#buf-canvas')
    @detectDiv = $('#detect-div')
    @ctx = @canvas[0].getContext('2d')
    @bctx = @bcanvas[0].getContext('2d')
    @tools = []
    @width = @canvas.width()
    @height = @canvas.height()
    @BufDis = 50
    @undoList = []

  mouseDown: () ->
    @mouseStatus = 1

  mouseUp: () ->
    @mouseStatus = 0

  init: () ->
    can = @canvas[0]
    can.width = @ctx.width = @canvas.width()
    can.height = @ctx.height = @canvas.height()
    #can.onselectstart = () -> false

    can = @bcanvas[0]
    can.width = @bctx.width = @bcanvas.width()
    can.height = @bctx.height = @bcanvas.height()
    #can.onselectstart = () -> false

    toolDiv = $('#toolbox-wrapper')
    @tools.forEach (tool, idx) ->
      img = $('<img>').attr('src', 'img/' + tool.iconImg).addClass('tool-img')
      wrapDiv = $('<div>')
        .addClass('tool-icon')
        .append(img)
        .click ()->
          main.changeCurrentTool idx

      toolDiv.append(wrapDiv)

    @ctx.fillStyle = 'rgba(255, 255, 255, 255)'
    @ctx.fillRect 0, 0, @canvas.width(), @canvas.height()

    CanvasRenderingContext2D.prototype.clearAll = () ->
      @clearRect 0, 0, @width, @height

    CanvasRenderingContext2D.prototype.circle = (x, y, r) ->
      @arc x, y, r, 0, 2.0*Math.PI

    CanvasRenderingContext2D.prototype.drawMountCircle = (x, y) ->
      @beginPath()
      @strokeStyle = '#00FFFF'
      @lineWidth = 4
      @arc x, y, 4, 0, 2.0*Math.PI
      @stroke()
      

    CanvasRenderingContext2D.prototype.setPixel = (x, y, color) ->
      idt = @.createImageData 1, 1
      if color instanceof String
        idt.data[0] = color[0]
        idt.data[1] = color[1]
        idt.data[2] = color[2]
        idt.data[3] = color[3]
      else
        idt.data[0] = color.r
        idt.data[1] = color.g
        idt.data[2] = color.b
        idt.data[3] = color.a * 255
      console.log idt.data, color
      @putImageData idt, x, y
      return


    @detectDiv.mousedown @onMouseDown
    @detectDiv.mousemove @onMouseMove
    @detectDiv.mouseup @onMouseUp

  changeCurrentTool: (idx) ->

    if @currentTool >= 0 and @tools[@currentTool].onEnd?
      @tools[@currentTool].onEnd @ctx, @bctx

    return if idx == @currentTool

    @ctx.restore()
    @bctx.restore()
    @ctx.save()
    @bctx.save()

    toolDiv = $('#toolbox-wrapper')
    toolDiv.children().removeClass 'active'
    toolDiv.children().eq(idx).addClass 'active'
    topDiv = $('#top-wrapper')
    topDiv.empty()
    @tools[idx].controlVals.forEach (ctr) ->
      ctr.render(topDiv)
    @currentTool = idx
    if @tools[idx].onLoad?
      @tools[idx].onLoad()

  onMouseDown: (e) =>
    console.log "mouse down"
    @mouseDown()
    if @currentTool != -1
      @tools[@currentTool].onMouseDown(e.offsetX - @BufDis, e.offsetY - @BufDis, @ctx, @bctx)
      return

  onMouseUp: (e) =>
    @mouseUp()
    if @currentTool != -1
      @tools[@currentTool].onMouseUp(e.offsetX - @BufDis, e.offsetY - @BufDis, @ctx, @bctx)
      return
    
      
  onMouseMove: (e) =>
    [x, y] = [e.offsetX - @BufDis, e.offsetY - @BufDis]

    if @currentTool != -1
      @tools[@currentTool].onMouseMove(x, y, @ctx, @bctx, @mouseStatus)

    if x < 0 or x >= @width or y < 0 or y >= @height
      @mouseUp()
    return

  undo: () ->
    return if @undoList.length <= 0
    img = @undoList.pop()
    @ctx.putImageData img, 0, 0

  restore: () ->
    imgData = @ctx.getImageData 0, 0, @width, @height
    console.log imgData
    @undoList.push imgData
    if @undoList.length > 10
      @undoList.shift()

# MountPoint
class MountPoint
  constructor: (o) ->
    _.extend @, o

  dis: (x, y) ->
    console.log x, y, @x, @y
    return Math.euclidDistance(x, y, @x, @y)

  setxy: (x, y, ctx) ->
    @x = x
    @y = y
    if ctx?
      @draw(ctx)
    return
  
  draw: (ctx) ->
    ctx.drawMountCircle @x, @y

# Tools
class Tools
  constructor: (o) ->
    _.extend @, o
    @mountPoints = []
    return

  getVal: (i) ->
    return @controlVals[i].val()

  getMount: (i) ->
    return @mountPoints[i]

  mount: (i) ->
    return @mountPoints[i]

  getPos: () ->
    rt = []
    @mountPoints.forEach (m) ->
      rt.push x: m.x, y: m.y
    return rt

  pos: (i) ->
    return x: mountPoints[i].x, y: mountPoints[i].y
  
  getClosetMount: (x, y) ->
    bdis = 10
    for m in @mountPoints
      d = m.dis x, y
      console.log d
      if d < bdis
        bdis = d
        cm = m
    return cm
  
  drawMounts: (ctx) ->
    @mountPoints.forEach (m) ->
      m.draw ctx

  save: () ->
    main.restore()

# ColorInput
class ColorInput
  constructor: (o) ->
    @defaultColor = '#000000'
    _.extend @, o
    return

  render: (par) ->
    textSpan = $('<span> ' + @text + ' </span>').addClass('option-text-span')
    colorInput = $('<input type="text" id="color1"/>')
    wrapDiv = $('<div>').addClass('option-wrapper')
    wrapDiv.append(textSpan).append(colorInput)
    par.append(wrapDiv)
    colorInput.spectrum
      clickoutFiresChange: true
      showPalette: true
      #hideAfterPaletteSelect:true
      palette: [
        ["#000","#444","#666","#999","#ccc","#eee","#f3f3f3","#fff"],
        ["#f00","#f90","#ff0","#0f0","#0ff","#00f","#90f","#f0f"],
        ["#f4cccc","#fce5cd","#fff2cc","#d9ead3","#d0e0e3","#cfe2f3","#d9d2e9","#ead1dc"],
        ["#ea9999","#f9cb9c","#ffe599","#b6d7a8","#a2c4c9","#9fc5e8","#b4a7d6","#d5a6bd"],
        ["#e06666","#f6b26b","#ffd966","#93c47d","#76a5af","#6fa8dc","#8e7cc3","#c27ba0"],
        ["#c00","#e69138","#f1c232","#6aa84f","#45818e","#3d85c6","#674ea7","#a64d79"],
        ["#900","#b45f06","#bf9000","#38761d","#134f5c","#0b5394","#351c75","#741b47"],
        ["#600","#783f04","#7f6000","#274e13","#0c343d","#073763","#20124d","#4c1130"],
        ["#00000000"]
      ]
      showAlpha: true
      color: @defaultColor
    @spec = colorInput
    return
    

  val: () ->
    @spec.spectrum('get')

#RangeInput
class RangeInput
  constructor: (o) ->
    _.extend @, o
    return

  render: (par) ->
    textSpan = $('<span> ' + @text + ' </span>').addClass('option-text-span')
    rangeInput = $('<input type="range" id="range2" min="0" max="100" value="3"/>')
    numInput = $('<input type="number" min="0" max="100" value="3"/>')
    wrapDiv = $('<div>').addClass('option-wrapper')
    wrapDiv.append(textSpan).append(rangeInput).append numInput
    par.append(wrapDiv)
    @inp = rangeInput
    @value = 3
    my = @
    rangeInput.on 'input', () ->
      my.value = parseInt rangeInput.val()
      numInput.val my.value

    numInput.on 'input', () ->
      my.value = parseInt numInput.val()
      rangeInput.val my.value
    return
    

  val: () ->
    @value

# Pencil Tool
pencilTool = new Tools
  controlVals: [
    new ColorInput( text: 'Draw color:' ),
    new RangeInput( text: 'Draw width:' ),
  ]
  onMouseDown: (x, y, ctx) ->
    @save()
    color = @controlVals[0].val()
    ctx.beginPath()
    ctx.strokeStyle = color.toRgbString()
    ctx.lineJoin = ctx.lineCap = 'round'
    ctx.lineWidth = @controlVals[1].val()
    ctx.moveTo x, y

  onMouseMove: (x, y, ctx, bctx, status) ->
    bctx.clearAll()
    bctx.beginPath()
    bctx.arc x, y, @getVal(1) / 2.0, 0, 2.0 * Math.PI
    bctx.stroke()
    return if status == 0
    ctx.lineTo x, y
    ctx.stroke()

  onMouseUp: (x, y, ctx, status) ->
    return

  iconImg: 'pencil-icon.svg'

paintTool = new Tools
  controlVals: [
    new ColorInput( text: 'Fill color:' ),
  ]
  onMouseDown: (x, y, ctx) ->
    @save()
    color = @controlVals[0].val().toRgb()
    colorVec = [color.r, color.g, color.b, color.a*255]
    rawData = ctx.getImageData(0, 0, ctx.width, ctx.height)

    width = ctx.width
    height = ctx.height

    getData = (x, y) ->
      o = (y*width + x)*4
      return [ rawData.data[o], rawData.data[o+1], rawData.data[o+2], rawData.data[o+3] ]

    putData = (x, y) ->
      o = (y*width + x)*4
      rawData.data[o] = color.r
      rawData.data[o+1] = color.g
      rawData.data[o+2] = color.b
      rawData.data[o+3] = color.a*255
      
    isEqual4 = (l1, l2) ->
      return (l1[0] == l2[0]) && (l1[1] == l2[1]) && (l1[2] == l2[2]) && (l1[3] == l2[3])

    if isEqual4 colorVec, getData(x, y)
      return

    inRange = (_x, _y) ->
      return _x >= 0 and _x < width and _y >= 0 and _y < height

    
    cur = getData x, y
    quex = [ x ]
    quey = [ y ]
    [qs, qe] = [0, 1]
    dx = [1, 0, -1, 0]
    dy = [0, 1, 0, -1]
    putData(x, y)

    while qs != qe

      nx = quex[qs]
      ny = quey[qs]
      ++ qs
      
      for i in [0..3]
        qx = nx + dx[i]
        qy = ny + dy[i]

        continue if qx < 0 or qx >= width or qy < 0 or qy >= height

        o = (qy * width + qx) * 4
        #nex = [rawData.data[o], rawData.data[o+1], rawData.data[o+2], rawData.data[o+3]]
        if rawData.data[o] == cur[0] && rawData.data[o+1] == cur[1] && rawData.data[o+2] == cur[2] && rawData.data[o+3] == cur[3]
          #o = (qy * width + qx) * 4
          rawData.data[o] = colorVec[0]
          rawData.data[o+1] = colorVec[1]
          rawData.data[o+2] = colorVec[2]
          rawData.data[o+3] = colorVec[3]

          quex.push(qx)
          quey.push(qy)
          ++ qe


    ctx.putImageData rawData, 0, 0


  onMouseMove: (x, y, ctx, bctx, status) ->
    return

  onMouseUp: (x, y, ctx) ->
    return

  iconImg: 'paint-icon.png'

rectTool = new Tools
  controlVals: [
    new ColorInput( text: 'Border color:' )
    new ColorInput
      text: 'Fill color:'
      defaultColor: '#00000000'
    new RangeInput( text: 'Border width:' )
  ]
  onMouseDown: (x, y, ctx) ->
    @startx = x
    @starty = y
  onMouseMove: (x, y, ctx, bctx, st) ->
    return if st == 0
    @endx = x
    @endy = y
    bctx.clearRect 0, 0, bctx.width, bctx.height
    bctx.beginPath()
    bctx.strokeStyle = @getVal(0).toRgbString()
    bctx.fillStyle = @getVal(1).toRgbString()
    bctx.lineWidth = @getVal(2)
    bctx.rect(@startx, @starty, @endx - @startx, @endy - @starty)
    bctx.fill()
    bctx.stroke()
    
  onMouseUp: (x, y, ctx, bctx) ->
    @save()
    ctx.beginPath()
    ctx.strokeStyle = @controlVals[0].val().toRgbString()
    ctx.fillStyle = @getVal(1).toRgbString()
    ctx.lineWidth = @getVal(2)
    ctx.rect(@startx, @starty, @endx - @startx, @endy - @starty)
    ctx.fill()
    ctx.stroke()
    bctx.clearRect 0, 0, bctx.width, bctx.height

  iconImg: 'rect-icon.png'

circleTool = new Tools
  controlVals: [
    new ColorInput( text: 'Border color:' )
    new ColorInput
      text: 'Fill color:'
      defaultColor: '#00000000'
    new RangeInput( text: 'Border width:' )
  ]
  drawEllipse: (x1, y1, x2, y2, ctx) ->
    [x1, x2] = [x2, x1] if x1 > x2
    [y1, y2] = [y2, y1] if y1 > y2
    centx = (x1 + x2) / 2
    centy = (y1 + y2) / 2
    lenx = (x2 - x1) / 2
    leny = (y2 - y1) / 2
    return [centx, centy, lenx, leny]

  onMouseDown: (x, y, ctx) ->
    @startx = x
    @starty = y

  onMouseMove: (x, y, ctx, bctx, st) ->
    return if st == 0
    @endx = x
    @endy = y
    bctx.clearAll()
    bctx.clearRect 0, 0, bctx.width, bctx.height
    bctx.beginPath()
    bctx.strokeStyle = @controlVals[0].val().toRgbString()
    bctx.fillStyle = @getVal(1).toRgbString()
    bctx.lineWidth = parseInt(@getVal(2))
    res = @drawEllipse(@startx, @starty, @endx, @endy, bctx)
    bctx.ellipse(res[0], res[1], res[2], res[3] ,0, 0, 2*Math.PI)
    bctx.fill()
    bctx.stroke()

  onMouseUp: (x, y, ctx, bctx) ->
    bctx.clearAll()
    @save()
    ctx.beginPath()
    ctx.strokeStyle = @controlVals[0].val().toRgbString()
    ctx.fillStyle = @getVal(1).toRgbString()
    ctx.lineWidth = parseInt(@getVal(2))

    res = @drawEllipse(@startx, @starty, @endx, @endy, ctx)
    ctx.ellipse(res[0], res[1], res[2], res[3] ,0, 0, 2*Math.PI)
    
    ctx.fill()
    ctx.stroke()
    ctx.beginPath()

    ctx.stroke()

  iconImg: 'circle-icon.png'

lineTool = new Tools
  controlVals: [
    new ColorInput( text: 'Border color:' )
    new RangeInput( text: 'Border width:' )
  ]

  onLoad: () ->
    @hasLine = false
    @mountPoints = [new MountPoint()
                    ,new MountPoint()]

  onMouseDown: (x, y, ctx, bctx) ->
    if not @hasLine
      @getMount(0).setxy x, y
      @getMount(1).setxy x, y
    else
      m = @getClosetMount(x, y)
      if m?
        @dragMount = m
      else
        @onEnd(ctx, bctx)
        @hasLine = false
        @onMouseDown x, y, ctx, bctx

  draw: (ctx) ->
    ctx.beginPath()
    ctx.strokeStyle = @getVal(0).toRgbString()
    ctx.lineWidth = parseInt(@getVal(1))
    pos = @getPos()
    console.log pos
    ctx.moveTo pos[0].x, pos[0].y
    ctx.lineTo pos[1].x, pos[1].y
    ctx.stroke()


  onMouseMove: (x, y, ctx, bctx, st) ->
    return if st == 0
    if not @hasLine
      @mount(1).setxy x, y
      bctx.clearAll()
      @draw bctx
    else
      bctx.clearAll()
      @dragMount.setxy x, y, bctx
      @draw bctx


  onMouseUp: (x, y, ctx, bctx) ->
    if not @hasLine
      @hasLine = true
      @mount(1).setxy x, y
      bctx.clearAll()
      @draw bctx
      
      console.log @mountPoints
      @mountPoints.forEach (m) ->
        m.draw(bctx)

    else
      bctx.clearAll()
      @dragMount.setxy x, y
      @drawMounts bctx
      @draw bctx

  onEnd: (ctx, bctx) ->
    console.log 'zzz'
    bctx.clearAll()
    @save()
    @draw ctx

  iconImg: 'line-icon.png'

rectSelectTool = new Tools
  controlVals: [
  ]

  onLoad: () ->
    @selected = false
    @drag = false

  onMouseDown: (x, y, ctx) ->
    if not @selected
      @startSelectx = x
      @startSelecty = y
    else
      @offx = x - @curx
      @offy = y - @cury
      console.log @offx, @offy, @curx, @cury

      if @offx >= 0 and @offy >= 0 and @offx < @selectWidth and @offy < @selectHeight
        @drag = true
        console.log "Drag = True"

  setCtx: (ctx) ->
    ctx.strokeStyle = "black"
    ctx.lineWidth = 2
    ctx.setLineDash([5])


  onMouseMove: (x, y, ctx, bctx, st) ->
    return if st == 0

    if not @selected
      @endx = x
      @endy = y
      bctx.clearAll()
      bctx.beginPath()
      @setCtx bctx

      bctx.rect @startSelectx, @startSelecty, x - @startSelectx, y - @startSelecty
      bctx.stroke()
    else if @drag
      bctx.clearAll()
      [realx, realy] = [x - @offx, y - @offy]
      bctx.putImageData @tempImg, realx, realy
      bctx.beginPath()
      bctx.rect realx, realy, @selectWidth, @selectHeight
      bctx.stroke()
      [@curx, @cury] = [realx, realy]
      
  onMouseUp: (x, y, ctx, bctx) ->
    
    if not @selected
      @endSelectx = x
      @endSelecty = y
      @selectWidth = x - @startSelectx
      @selectHeight = y - @startSelecty

      @tempImg = ctx.getImageData @startSelectx
      , @startSelecty
      , @selectWidth
      , @selectHeight

      @save()
      ctx.clearRect @startSelectx
      , @startSelecty
      , @selectWidth
      , @selectHeight

      bctx.putImageData @tempImg, @startSelectx, @startSelecty

      @selected = true
      [@curx, @cury] = [@startSelectx, @startSelecty]
      console.log @curx, @cury
    else if @drag
      @drag = false

  onEnd: (ctx, bctx) ->
    return if not @selected
    bctx.clearAll()
    ctx.putImageData @tempImg, @curx, @cury
    @selected = false

  iconImg: 'rect-select-icon.svg'

sprayTool = new Tools
  controlVals: [
    new ColorInput( text: "Spray Color: " )
    new RangeInput( text: "Range: " )
  ]
  onMouseDown: (x, y, ctx) ->
    @save()
    color = @controlVals[0].val()
    @curx = x
    @cury = y
    @r = parseInt @getVal 1
    my = @

    @timerId =  setInterval () ->
      for i in [0..30]
        arr = Math.random2DNormal my.r / 2.5
        dx = Math.round arr[0]
        dy = Math.round arr[1]
        ctx.setPixel my.curx + dx, my.cury + dy, color.toRgb()
      return
    ,
      100
      

  onMouseMove: (x, y, ctx, bctx, status) ->
    @r = parseInt @getVal 1
    bctx.clearAll()
    bctx.beginPath()
    bctx.arc x, y, @r, 0, 2*Math.PI, false
    bctx.stroke()
    if status == 1
      @curx = x
      @cury = y

  onMouseUp: (x, y, ctx, status) ->
    clearInterval @timerId
    return

  iconImg: 'spray-icon.png'

undoTool = new Tools
  controlVals: [
  ]

  onLoad: () ->
    @onEnd()
  
  onEnd: () ->
    main.undo()

  onMouseDown: (x, y, ctx) ->
    return
      

  onMouseMove: (x, y, ctx, bctx, status) ->
    return

  onMouseUp: (x, y, ctx, status) ->
    return

  iconImg: 'undo-icon.png'



main = new Main()
main.tools = [
  pencilTool,
  paintTool,
  rectTool,
  circleTool,
  lineTool,
  rectSelectTool,
  sprayTool,
  undoTool,
]
main.init()
