import std/[strutils, strformat, asyncdispatch, sets, hashes, json,
            sugar, os, random, asyncnet]
import karax/[karaxdsl, vdom, vstyles, kbase]
import prologue
import prologue/websocket
import prologue/middlewares/staticfile


proc fileList(): seq[string] =
  result = collect:
    for file in walkFiles("public/img/*"):
      file.split({'/'})[^1]

randomize()

converter toString(x: VNode): string = $x

proc full(): VStyle =
  result = new(VStyle)
  result.setAttr(StyleAttr.width, "100%".kstring)
  result.setAttr(StyleAttr.height, "100%".kstring)
  result.setAttr(StyleAttr.margin, "0".kstring)
  result.setAttr(StyleAttr.backgroundColor, "black".kstring)

template index*(rest: untyped): untyped =
  buildHtml(html(lang = "en")):
    head:
      meta(charset = "UTF-8", name="viewport", content="width=device-width, initial-scale=1")
      # link(rel = "stylesheet", href = "https://unpkg.com/@picocss/pico@latest/css/pico.min.css")
      script(src = "https://unpkg.com/htmx.org@1.6.0")
      title: text "Ω 🐝 🥁"
    body(style=full()):
      main(class="container", style=full()): rest

proc randGif(fnames: seq[string]): VNode =
  let fname = fnames.sample
  if fname.endsWith(".mp4"):
    result = buildhtml(tdiv(id="content", style=full())):
      video(src="/public/img/"&fname, style=full(), autoplay="true", loop="true", muted="true")
  else:
    result = buildhtml(tdiv(id="content",style=full())):
      img(src="/public/img/"&fname, style=full())

proc waitForClose(ws: WebSocket): Future[void] {.async.} =
  # Need to be processing recived packets to get close when client disconnects
  try:
    discard await ws.receiveStrPacket()
  except:
    echo "Close"


proc root*(ctx: Context) {.async, gcsafe.} =
  let html = index:
    tdiv(hx-ws="connect:/ws", style=full()):
      tdiv(id="content", style=full()):
        text "Loading..."
  resp html

proc ws*(ctx: Context) {.async, gcsafe.} =
  var ws = await newWebSocket(ctx)
  try:
    asyncCheck waitForClose(ws)
    while ws.readyState == Open:
      let nb = randGif(fileList())
      echo "sending: "&nb
      await ws.send(nb)
      await sleepAsync(60000)
    echo "Socket closed."
  except:
    echo "Someone disconnected?"
  resp ""
  

when isMainModule:
  var app = newApp()
  app.use(staticFileMiddleware("public"))
  app.get("/", root)
  # app.get("/reload", reload)
  app.get("/ws", ws)
  app.run()
    
  
