import dom

type
  CanvasRenderingContext* = ref object
    font* {.importc.}: cstring
    fillStyle* {.importc.}: cstring

  ContextAttributes* = ref object
    alpha* {.importc.}: bool

  Canvas* = Element

{.push importcpp.}

proc getContext*(canvasElement: Element, contextType: cstring,
    contextAttributes = ContextAttributes(alpha: true)): CanvasRenderingContext

proc fillRect*(context: CanvasRenderingContext,
    x, y, width, height: int)

proc drawImage*(context: CanvasRenderingContext, image: Element, sx, sy,
    sWidth, sHeight, dx, dy, dWidth, dHeight: int)

{.pop.}

proc setDimensions(c: Canvas, w, h: string) =
  c.setAttribute("width",w)
  c.setAttribute("height",h)

var vt340panel : Canvas
var vt340ctx : CanvasRenderingContext
var vt340chargen : Element
var x_pos, y_pos : int = 0
var vt340memory {.exportc.} : array[80*16,int]
var vt340cursor_state = false

proc drawChar(x,y: int, code: int, a: bool) =
  var keycode = code - 0o40
  if (keycode<0 or keycode>0o177-0o40): keycode = 0
  var ypos = ((keycode div 8)) + 3
  var xpos = 12 + (keycode mod 8) * 9
  # if a: vt340ctx.fillRect(x*11, y*36,x*11+11, y*36+36)
  vt340ctx.drawImage(vt340chargen, xpos*11, ypos*36, 11, 36, x*11, y*36, 11, 36)

proc keypress(ev: Event) =
  var charCode = ev.which
  #{.emit: "`charCode` = `ev`.key.charCodeAt(0);".}
  # {.emit: "console.log(`charCode`,`ev`.keyCode, `ev`.char, `ev`.key);".}
  # echo(ev.keyCode, ev.which)
  drawChar(x_pos,y_pos, vt340memory[x_pos+y_pos*80], false)
  case charCode:
    of 13:
      y_pos = y_pos + 1
      if y_pos>15: y_pos = 0
      x_pos = 0
    of 8:
        if x_pos > 0: x_pos = x_pos - 1
    else:
      drawChar(x_pos,y_pos, charCode, false)
      vt340memory[x_pos + y_pos * 80] = charCode and 0xff
      x_pos = x_pos + 1
      if x_pos>79:
        x_pos = 0;
        y_pos += 1;
      if y_pos>15: y_pos = 0

proc drawCursor() {.exportc.} =
  # {.emit:"console.log(`vt340cursor_state`);".}
  var old = vt340memory[x_pos+y_pos*80]
  if not vt340cursor_state:
    drawChar(x_pos, y_pos, 0o137, true)
  else:
    drawChar(x_pos,y_pos, old, true)
  vt340cursor_state = not vt340cursor_state
  discard window.setTimeout(drawCursor, 500)

proc init() =
  vt340panel = dom.document.getElementById("vt340-panel")
  vt340chargen = dom.document.getElementById("vt340-chargen")
  vt340ctx = vt340panel.getContext("2d")
  window.addEventListener("keypress",keypress,true)
  vt340panel.setDimensions("880","576")
  discard window.setTimeout(drawCursor, 500)

proc main() {.exportc.} =
  init()
  vt340ctx.fillStyle = "#000000"
  vt340ctx.fillRect(0,0,880,576)
  vt340ctx.fillStyle = "#550000"
