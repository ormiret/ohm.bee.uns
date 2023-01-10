import std/[strutils, strformat, asyncdispatch, sets, hashes, json,
            sugar, os, random, asyncnet]
import karax/[karaxdsl, vdom, vstyles, kbase], jester, ws, ws/jester_extra

proc fileList(): seq[string] =
  result = collect:
    for file in walkFiles("public/img/*"):
      file.split({'/'})[^1]
var files = fileList()
echo fmt"Have {files.len} files to display"
randomize()

converter toString(x: VNode): string = $x

let full = new(VStyle)
full.setAttr(StyleAttr.width, "100%".kstring)
full.setAttr(StyleAttr.height, "100%".kstring)
full.setAttr(StyleAttr.margin, "0".kstring)
full.setAttr(StyleAttr.backgroundColor, "black".kstring)

template index*(rest: untyped): untyped =
  buildHtml(html(lang = "en")):
    head:
      meta(charset = "UTF-8", name="viewport", content="width=device-width, initial-scale=1")
      # link(rel = "stylesheet", href = "https://unpkg.com/@picocss/pico@latest/css/pico.min.css")
      script(src = "https://unpkg.com/htmx.org@1.6.0")
      title: text "Ω 🐝 🥁"
    body(style=full):
      main(class="container", style=full): rest

proc randGif(fnames: seq[string]): VNode =
  let fname = fnames.sample
  if fname.endsWith(".mp4"):
    result = buildhtml(tdiv(id="content", style=full)):
      video(src="/img/"&fname, style=full, autoplay="true", loop="true", muted="true")
  else:
    result = buildhtml(tdiv(id="content",style=full)):
      img(src="/img/"&fname, style=full)

proc waitForClose(ws: WebSocket): Future[void] {.async.} =
  # Need to be processing recived packets to get close when client disconnects
  try:
    discard await ws.receiveStrPacket()
  except:
    echo "Close"
      
routes:
  get "/":
    let html = index:
      tdiv(hx-ws="connect:/ws", style=full):
        tdiv(id="content", style=full):
          text "Loading..."
    resp html
  get "/reload":
    files = fileList()
    let html = index:
      text fmt"Done. Now have {files.len} files"
    resp html
  get "/ws":
    var ws = await newWebSocket(request)
    try:
      asyncCheck waitForClose(ws)
      while ws.readyState == Open:
        let nb = files.randGif
        echo "sending: "&nb
        await ws.send(nb)
        await sleepAsync(60000)
      echo "Socket closed."
    except:
      echo "Someone disconnected?"
    resp ""
    
  
