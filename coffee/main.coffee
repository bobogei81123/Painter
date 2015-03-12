
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
    @detectDiv = $('#detect-div')
    @tools = []
    @buttons = []
    @BufDis = 50
    @undoList = []
    @layers = []
    @activeLayerIdx = 0
    @width = 800
    @height = 600

  mouseDown: () ->
    @mouseStatus = 1

  mouseUp: () ->
    @mouseStatus = 0

  init: () ->
    @layers = [new Layer()]
    @layers[0].render(0, 0)
    @layers[0].addActive()
    @depthArr = [@layers[0]]

    
    #@ctx.globalCompositeOperation = 'destination-atop'
    #@bctx.globalCompositeOperation = 'destination-atop'
    toolDiv = $('#toolbox-wrapper')
    @tools.forEach (tool, idx) ->
      tool.render toolDiv, idx


    #@ctx.fillStyle = 'rgba(255, 255, 255, 255)'
    #@ctx.fillRect 0, 0, @canvas.width(), @canvas.height()

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
      @putImageData idt, x, y
      return


    @detectDiv.mousedown @onMouseDown
    @detectDiv.mousemove @onMouseMove
    @detectDiv.mouseup @onMouseUp

    $('#layer-add-icon').click @addLayer
    $('#layer-remove-icon').click @removeLayer
    $('#layer-up-icon').click @upLayer
    $('#layer-down-icon').click @downLayer

  changeCurrentTool: (idx) ->

    if @currentTool >= 0 and @tools[@currentTool].onEnd?
      @tools[@currentTool].onEnd @activeLayer

    return if idx == @currentTool

    @curLayer().ctx.restore()
    @curLayer().bctx.restore()
    @curLayer().ctx.save()
    @curLayer().bctx.save()

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

  changeCurrentLayer: (idx) =>
    return if idx == @activeLayerIdx
    @endCurrentTool()

    @curLayer().removeActive()
    @layers[idx].addActive()
    @activeLayerIdx = idx

  endCurrentTool: () ->
    if @currentTool >= 0 and @tools[@currentTool].onEnd?
      @tools[@currentTool].onEnd @curLayer()


  addLayer: () =>
    z = @layers.length
    idx = @layers.length
    nl = new Layer()
    @layers.push nl
    @depthArr.push nl
    nl.render(idx, z)

  removeLayer: () =>
    return if @depthArr.length <= 1
    cid = @curLayerZ()
    @depthArr[cid].destruct()
    for i in [cid..@depthArr.length-1]
      @depthArr[i] = @depthArr[i+1]
      @depthArr[i].setZ i
    
    @depthArr.pop()

  downLayer: () =>
    cid = @curLayerZ()
    return if cid >= @depthArr.length - 1
    Layer.swap depthArr[cid], depthArr[cid+1]



  onMouseDown: (e) =>
    console.log 'zzz'
    x = e.offsetX - @BufDis
    y = e.offsetY - @BufDis
    return if x < 0 or x >= @width or y < 0 or y >= @height
    @mouseDown()
    if @currentTool != -1
      @tools[@currentTool].onMouseDown(x, y, @layers[@activeLayerIdx])
      return

  onMouseUp: (e) =>
    @mouseUp()
    if @currentTool != -1
      @tools[@currentTool].onMouseUp(e.offsetX - @BufDis, e.offsetY - @BufDis, @layers[@activeLayerIdx])
      return
    
      
  onMouseMove: (e) =>
    [x, y] = [e.offsetX - @BufDis, e.offsetY - @BufDis]

    if @currentTool != -1
      @tools[@currentTool].onMouseMove(x, y, @layers[@activeLayerIdx], @mouseStatus)

    if x < 0 or x >= @width or y < 0 or y >= @height
      @mouseUp()
    return

  curLayer: () ->
    return @layers[@activeLayerIdx]

  curLayerZ: () ->
    return @curLayer().z

  undo: () ->
    if @currentTool != -1 and @tools[@currentTool].onEnd?
      @tools[@currentTool].onEnd(@activeLayer)
    return if @undoList.length <= 0
    un = @undoList.pop()
    un.undo()

  save: (l, img) ->
    @undoList.push(new UndoOp layer: l, img: img)
    if @undoList.length > 20
      @undoList.shift()

class Layer
  @count: 0
  constructor: () ->
    @id = Layer.count
    Layer.count += 1
    @name = 'Layer ' + @id
    return

  render: (idx, z) ->
    @renderCanvas()
    @renderPannel idx
    console.log z
    @setZ z

  setZ: (z) ->
    @z = z
    @canDiv.css 'zIndex', z
    console.log z
  
  renderCanvas: () ->
    @canvas = document.createElement 'canvas'
    @canvas.width = 800
    @canvas.height = 600
    @canvas.className = 'main-canvas'

    @bcanvas = document.createElement 'canvas'
    @bcanvas.width = 800
    @bcanvas.height = 600
    @bcanvas.className = 'buffer-canvas'

    layerDiv = document.createElement 'div'
    layerDiv.className = 'layer-div'
    layerDiv.appendChild @canvas
    layerDiv.appendChild @bcanvas

    dv = document.getElementById 'canvas-wrapper'
    dv.insertBefore layerDiv, dv.firstChild
    @canDiv = $ layerDiv
    console.log @canDiv

    @ctx = @canvas.getContext '2d'
    @bctx = @bcanvas.getContext '2d'

    @ctx.fillStyle = 'rgba(255, 255, 255, 0)'
    @ctx.fillRect 0, 0, @canvas.width, @canvas.height

    @ctx.width = @bctx.width = 800
    @ctx.height = @bctx.height = 600

  destruct: () ->
    @canDiv.detach()
    @layDiv.detach()

  renderPannel: (idx)->
    wrapper = $ '#layer-main'
    imgDiv = $ '<canvas>'
             .addClass 'layer-img'
    wraDiv = $ '<div>'
             .addClass 'layer-img-wrapper'
             .append imgDiv
    textP = $ '<p>'
            .text @name
    textDiv = $ '<div>'
             .addClass 'layer-text'
             .append textP
    idiv = $ '<div>'
             .addClass 'layer-item'
             .append wraDiv, textDiv
    wrapper.prepend idiv
    @layDiv = idiv
    @prevCan = @layDiv.find( 'canvas' )
    console.log @prevCan.width()
    @prevCan[0].width = @prevCan.width()
    @prevCan[0].height = @prevCan.height()
    console.log @prevCan[0]
    @layDiv.click () ->
      main.changeCurrentLayer idx

  addActive: () ->
    @layDiv.addClass 'active'
    
  removeActive: () ->
    @layDiv.removeClass 'active'
  makePrev: () ->
    console.log window.a = @prevCan[0]
    @prevCan[0].getContext('2d').drawImage @canvas, 0, 0, @prevCan.width(), @prevCan.height()
      
# MountPoint
class MountPoint
  constructor: (o) ->
    _.extend @, o

  dis: (x, y) ->
    return Math.euclidDistance(x, y, @x, @y)

  setxy: (x, y, ctx) ->
    @x = x
    @y = y
    if ctx?
      @draw(ctx)
    return
  
  draw: (ctx) ->
    ctx.drawMountCircle @x, @y

  getxy: () ->
    return [@x, @y]

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
      if d < bdis
        bdis = d
        cm = m
    return cm
  
  drawMounts: (ctx) ->
    @mountPoints.forEach (m) ->
      m.draw ctx

  render: (con, idx) ->
    img = $('<img>').attr('src', 'img/' + @iconImg).addClass('tool-img')
    wrapDiv = $('<div>')
      .addClass('tool-icon')
      .append(img)
      .click ()->
        main.changeCurrentTool idx

    con.append(wrapDiv)

  save: (l) ->
    console.log l
    imgData = l.ctx.getImageData 0, 0, l.ctx.width, l.ctx.height
    main.save l, imgData

  onEnd: (l) ->
    console.log l
    l.makePrev()

#ShapeTools
class ShapeTools extends Tools
  onLoad: () ->
    @hasShape = false
    @mountPoints = [
      new MountPoint(),
      new MountPoint(),
    ]

  onMouseDown: (x, y, l) ->
    if not @hasShape
      @mount(0).setxy x, y
      @mount(1).setxy x, y
    else
      m = @getClosetMount x, y
      if m?
        @dragMount = m
      else
        @onDrawEnd l
        @hasShape = false
        @onMouseDown x, y, l

  onMouseMove: (x, y, l, st) ->
    return if st == 0
    if not @hasShape
      @mount(1).setxy x, y
    else if @dragMount?
      @dragMount.setxy x, y
    l.bctx.clearAll()
    @draw l.bctx

  onMouseUp: (x, y, l) ->
    if not @hasShape
      @mount(1).setxy x, y, l.bctx
      @hasShape = true
    l.bctx.clearAll()
    @draw l.bctx
    @drawMounts l.bctx

  onDrawEnd: (l) ->
    console.log l
    l.bctx.clearAll()
    @save l
    @draw l.ctx
    @hasShape = false

  onEnd: (l) ->
    return if not @hasShape
    @hasShape = false
    @onDrawEnd l
    
class UndoOp
  constructor: (o) ->
    _.extend @, o

  undo: () ->
    @layer.ctx.putImageData @img, 0, 0

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
class PencilTool extends Tools
  controlVals: [
    new ColorInput( text: 'Draw color:' ),
    new RangeInput( text: 'Draw width:' ),
  ]
  onMouseDown: (x, y, l) ->
    console.log '???'
    @save l
    color = @controlVals[0].val()
    l.ctx.beginPath()
    l.ctx.strokeStyle = color.toRgbString()
    l.ctx.lineJoin = l.ctx.lineCap = 'round'
    l.ctx.lineWidth = @controlVals[1].val()
    l.ctx.moveTo x, y

  onMouseMove: (x, y, l, status) ->
    l.bctx.clearAll()
    l.bctx.beginPath()
    l.bctx.arc x, y, @getVal(1) / 2.0, 0, 2.0 * Math.PI
    l.bctx.stroke()
    return if status == 0
    l.ctx.lineTo x, y
    l.ctx.stroke()

  onMouseUp: (x, y, l, status) ->
    @onEnd(l)
    return

  onEnd: (l) ->
    console.log 'zzz'
    console.log l
    super(l)
    

  iconImg: 'pencil-icon.svg'

paintTool = new Tools
  controlVals: [
    new ColorInput( text: 'Fill color:' ),
  ]
  onMouseDown: (x, y, l) ->
    @save l
    color = @controlVals[0].val().toRgb()
    colorVec = [color.r, color.g, color.b, color.a*255]
    width = l.ctx.width
    height = l.ctx.height
    rawData = l.ctx.getImageData(0, 0, width, height)


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


    l.ctx.putImageData rawData, 0, 0


  onMouseMove: (x, y, l, status) ->
    return

  onMouseUp: (x, y, l) ->
    return

  iconImg: 'paint-icon.png'

rectTool = new ShapeTools
  controlVals: [
    new ColorInput( text: 'Border color:' )
    new ColorInput
      text: 'Fill color:'
      defaultColor: '#00000000'
    new RangeInput( text: 'Border width:' )
  ]



  draw: (ctx) ->
    ctx.beginPath()
    ctx.strokeStyle = @getVal(0).toRgbString()
    ctx.fillStyle = @getVal(1).toRgbString()
    ctx.lineWidth = @getVal(2)
    [sx, sy, ex, ey] = [@mount(0).x, @mount(0).y, @mount(1).x, @mount(1).y]
    ctx.rect(sx, sy, ex-sx, ey-sy)
    ctx.fill()
    ctx.stroke()
    
  iconImg: 'rect-icon.png'

circleTool = new ShapeTools
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


  draw: (ctx) ->
    ctx.beginPath()
    ctx.strokeStyle = @controlVals[0].val().toRgbString()
    ctx.fillStyle = @getVal(1).toRgbString()
    ctx.lineWidth = parseInt(@getVal(2))
    [sx, sy, ex, ey] = @mount(0).getxy().concat @mount(1).getxy()
    res = @drawEllipse(sx, sy, ex, ey, ctx)
    ctx.ellipse(res[0], res[1], res[2], res[3] ,0, 0, 2*Math.PI)
    ctx.fill()
    ctx.stroke()

  iconImg: 'circle-icon.png'

lineTool = new ShapeTools
  controlVals: [
    new ColorInput( text: 'Border color:' )
    new RangeInput( text: 'Border width:' )
  ]

  draw: (ctx) ->
    ctx.beginPath()
    ctx.strokeStyle = @getVal(0).toRgbString()
    ctx.lineWidth = parseInt(@getVal(1))
    pos = @getPos()
    ctx.moveTo pos[0].x, pos[0].y
    ctx.lineTo pos[1].x, pos[1].y
    ctx.stroke()

  iconImg: 'line-icon.png'

rectSelectTool = new Tools
  controlVals: [
  ]

  onLoad: () ->
    @selected = false
    @drag = false

  onMouseDown: (x, y, l) ->
    if not @selected
      @startSelectx = x
      @startSelecty = y
    else
      @offx = x - @curx
      @offy = y - @cury

      if @offx >= 0 and @offy >= 0 and @offx < @selectWidth and @offy < @selectHeight
        @drag = true

  setCtx: (ctx) ->
    ctx.strokeStyle = "black"
    ctx.lineWidth = 2
    ctx.setLineDash([5])


  onMouseMove: (x, y, l, st) ->
    return if st == 0

    if not @selected
      @endx = x
      @endy = y
      l.bctx.clearAll()
      l.bctx.beginPath()
      @setCtx l.bctx

      l.bctx.rect @startSelectx, @startSelecty, x - @startSelectx, y - @startSelecty
      l.bctx.stroke()
    else if @drag
      l.bctx.clearAll()
      [realx, realy] = [x - @offx, y - @offy]
      l.bctx.putImageData @tempImg, realx, realy
      l.bctx.beginPath()
      l.bctx.rect realx, realy, @selectWidth, @selectHeight
      l.bctx.stroke()
      [@curx, @cury] = [realx, realy]
      
  onMouseUp: (x, y, l) ->
    
    if not @selected
      @endSelectx = x
      @endSelecty = y
      @selectWidth = x - @startSelectx
      @selectHeight = y - @startSelecty

      @tempImg = l.ctx.getImageData @startSelectx
      , @startSelecty
      , @selectWidth
      , @selectHeight

      @save l
      l.ctx.clearRect @startSelectx
      , @startSelecty
      , @selectWidth
      , @selectHeight

      l.bctx.putImageData @tempImg, @startSelectx, @startSelecty

      @selected = true
      [@curx, @cury] = [@startSelectx, @startSelecty]
    else if @drag
      @drag = false

  onDrawEnd: (l) ->
    tmp = document.createElement 'canvas'
    tmp.width = @selectWidth
    tmp.height = @selectHeight
    tmpctx = tmp.getContext '2d'
    tmpctx.putImageData @tempImg, 0, 0
    l.bctx.clearAll()
    l.ctx.drawImage tmp, @curx, @cury
    @selected = false

  iconImg: 'rect-select-icon.svg'

sprayTool = new Tools
  controlVals: [
    new ColorInput( text: "Spray Color: " )
    new RangeInput( text: "Range: " )
  ]
  onMouseDown: (x, y, l) ->
    @save l
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
        l.ctx.setPixel my.curx + dx, my.cury + dy, color.toRgb()
      return
    ,
      100
      

  onMouseMove: (x, y, l, status) ->
    @r = parseInt @getVal 1
    l.bctx.clearAll()
    l.bctx.beginPath()
    l.bctx.arc x, y, @r, 0, 2*Math.PI, false
    l.bctx.stroke()
    if status == 1
      @curx = x
      @cury = y

  onMouseUp: (x, y, l, status) ->
    clearInterval @timerId
    return

  iconImg: 'spray-icon.png'

undoTool = new Tools
  controlVals: [
  ]

  run: () ->
    main.undo()

  iconImg: 'undo-icon.png'

  render: (con, idx) ->
    img = $('<img>').attr('src', 'img/' + @iconImg).addClass('tool-img')
    my = @
    wrapDiv = $('<div>')
      .addClass('tool-icon')
      .append(img)
      .click ()->
        my.run()

    con.append(wrapDiv)

downloadTool = new Tools
  render: (con, idx) ->
    img = $('<img>').attr('src', 'img/' + @iconImg).addClass('tool-img')
    my = @
    wrapDiv = $('<div>')
      .addClass('tool-icon')
      .append(img)

    wrapA = $('<a>')
      .append wrapDiv
      .click ()->
        my.run(@)

    con.append(wrapA)

  run: (link) ->
    link.href = main.canvas[0].toDataURL()
    link.download = 'myPaint.png'

  iconImg: "download-icon.svg"

main = new Main()
main.tools = [
  new PencilTool,
  paintTool,
  rectTool,
  circleTool,
  lineTool,
  rectSelectTool,
  sprayTool,
  undoTool,
  downloadTool,
]
main.init()
