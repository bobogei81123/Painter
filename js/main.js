// Generated by CoffeeScript 1.9.0
var MainCanvas, Mainctx, handleDocumentReady, handleMouseDown, handleMouseMove, handleMouseUp, mouseStatus;

MainCanvas = $('#main-canvas');

Mainctx = MainCanvas[0].getContext('2d');

mouseStatus = 0;

console.log(MainCanvas);

handleDocumentReady = function() {
  var can;
  can = MainCanvas[0];
  can.width = MainCanvas.width();
  can.height = MainCanvas.height();
  can.onselectstart = function() {
    return false;
  };
  $("#color1").spectrum();
};

$(handleDocumentReady);

handleMouseDown = function(e) {
  var color;
  color = $("#color1").spectrum("get").toHexString();
  console.log(color);
  Mainctx.beginPath();
  Mainctx.strokeStyle = color;
  Mainctx.lineWidth = $('#range2').val();
  Mainctx.moveTo(e.offsetX, e.offsetY);
  mouseStatus = 1;
};

handleMouseMove = function(e) {
  if (mouseStatus === 1) {
    Mainctx.lineTo(e.offsetX, e.offsetY);
    Mainctx.stroke();
  }
};

handleMouseUp = function(e) {
  mouseStatus = 0;
};

MainCanvas.mousedown(handleMouseDown);

MainCanvas.mousemove(handleMouseMove);

MainCanvas.mouseup(handleMouseUp);

MainCanvas.mouseleave(handleMouseUp);
