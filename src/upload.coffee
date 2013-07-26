class FileUpload extends Task
  constructor : (f) ->
    t_start = Date.now()/1000
    super
      parent : "#news"
      title : "Upload: #{f.name}"
      progress : yes
    id = null; worker = null; @ws = api.socket; last = 0; segment = 0
    chunk = 1024*16
    r = new FileReader f
    work = =>
      newlen = r.result.length
      if r.result?
        if newlen > last + chunk or f.size is newlen
          if api.socket.bufferedAmount < 2*chunk
            data = r.result.substr(last,chunk)
            api.send_binary(id,segment++,data)
            # console.log last, last+chunk, data.length, md5(data)
            last       += chunk
            percent     = (last / f.size * 100).toFixed 0
            time_passed = (Date.now()/1000) - t_start
            kbps        = segment * 16 / time_passed
            eta         = ((f.size/1024)/kbps) - time_passed
            eta         = eta.toFixed 2
            kbps        = kbps.toFixed 2
            @progress percent, kbps + "kbps eta: " + eta + "s"
            if last    >= f.size
              console.log "done", kbps
              clearInterval worker
              api.send msg:upload:done:id:id
              @done()
          else console.log "not_working: buffer"
        else console.log "not_working: no data"
    r.onerror  = (e) -> debugger
    r.onprogress  = work
    r.readAsBinaryString(f)
    console.log "loading"
    api.register msg:upload: (reply) ->
      id = reply.id
      worker = setInterval(work,333)
    api.send msg:upload:request:
      size: f.size
      name: f.name
      type: f.type

$(document).ready ->
  ftp = {}
  _button = new UIButton
    parent : "#menu"
    class : "framed upload"
    id : "upload"
    tooltip : "Upload a file to the music library"
    click : ->
      _dialog = new UIDialog
        container : $("#dialogs")
        title : "upload"
        show : yes
        class : "framed window dialog"
        head:html: "<h3>Upload</h3>"
        body:html: """
          <form method="post" enctype="multipart/form-data">
            <input type="file" name="file" />
          </form>"""
        foot:buttons:
          doupload :
            title : "Upload"
            tooltip : "Upload this file."
            click : ->
              f = document.querySelector("input[name='file']").files[0]
              new FileUpload f
              _dialog.hide()
          noupload :
            title : "Cancel"
            tooltip : "Close this dialog."
            click : -> _dialog.hide()

window.FileUpload = FileUpload