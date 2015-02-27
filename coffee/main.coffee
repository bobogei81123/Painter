
MainCanvas = $('#main-canvas')
Mainctx = MainCanvas[0].getContext '2d'
mouseStatus = 0
console.log(MainCanvas)

handleDocumentReady = () ->
  can = MainCanvas[0]
  can.width = MainCanvas.width()
  can.height = MainCanvas.height()
  can.onselectstart = () -> false
  $("#color1").spectrum()
  return

$( handleDocumentReady )

handleMouseDown = (e) ->
  color = $("#color1").spectrum("get").toHexString()
  console.log color
  Mainctx.beginPath()
  Mainctx.strokeStyle = color
  Mainctx.lineWidth = $('#range2').val()
  Mainctx.moveTo(e.offsetX, e.offsetY)
  mouseStatus = 1
  return

handleMouseMove = (e) ->
  if mouseStatus == 1
    Mainctx.lineTo e.offsetX, e.offsetY
    Mainctx.stroke()
  return

handleMouseUp = (e) ->
  mouseStatus = 0
  return

MainCanvas.mousedown( handleMouseDown )
MainCanvas.mousemove( handleMouseMove )
MainCanvas.mouseup( handleMouseUp )
MainCanvas.mouseleave( handleMouseUp )


