
MainCanvas = $('#main-canvas')
Mainctx = MainCanvas[0].getContext '2d'
mouseStatus = 0
console.log(MainCanvas)

handleDocumentReady = () ->
  can = MainCanvas[0]
  can.width = MainCanvas.width()
  can.height = MainCanvas.height()
  can.onselectstart = () -> false

$( handleDocumentReady )

handleMouseDown = (e) ->
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


