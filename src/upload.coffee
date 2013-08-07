class FileUpload extends Task

  constructor : (file, meta) ->

    super
      title : "Upload: #{file.name}"
      progress : yes

    t_start = Date.now() / 1000
    id      = null; worker = null; @ws = Api.socket; last = 0; segment = 0
    chunk   = 1024 * 16
    r       = new FileReader file

    work = =>
      newlen = r.result.length
      if r.result?
        if newlen > last + chunk or file.size is newlen
          if Api.socket.bufferedAmount < 2*chunk
            data = r.result.substr(last,chunk)
            Api.send_binary(id,segment++,data)
            # console.log last, last+chunk, data.length, md5(data)
            last       += chunk
            percent     = (last / file.size * 100).toFixed 0
            time_passed = (Date.now() / 1000) - t_start
            kbps        = segment * 16 / time_passed
            eta         = ((file.size / 1024) / kbps) - time_passed
            eta         = eta.toFixed 2
            kbps        = kbps.toFixed 2
            @progress percent, kbps + "kbps eta: " + eta + "s"
            if last    >= file.size
              console.log "done", kbps
              clearInterval worker
              Api.send upload: done: id:id
              @done()
          else console.log "not_working: buffer"
        else   console.log "not_working: no data"

    r.onerror     = (e) -> debugger
    # r.onprogress  = work
    r.readAsBinaryString file

    Api.register upload : (reply) ->
      if reply.error is false
        console.log 'starting upload', reply.id
        id = reply.id
        worker = setInterval work, 333
      else console.log reply.error

    Api.send upload : request :
      size: file.size
      name: file.name
      type: file.type
      meta: meta

  # This is samplecode / and belongs to rtv
  # @init: =>
  #   ftp = {}
  #   _button = new UIButton
  #     parent : "body"
  #     class : "framed upload"
  #     id : "upload"
  #     click : ->
  #       _dialog = new UIDialog
  #         container : $("#dialogs")
  #         title : "upload"
  #         show : yes
  #         class : "framed window dialog"
  #         head:html: "<h3>Upload</h3>"
  #         body:html: """
  #           <form method="post" enctype="multipart/form-data">
  #             <input type="file" name="file" />
  #           </form>"""
  #         foot:buttons:
  #           doupload :
  #             title : "Upload"
  #             tooltip : "Upload this file."
  #             click : ->
  #               f = document.querySelector("input[name='file']").files[0]
  #               new FileUpload f
  #               _dialog.hide()
  #           noupload :
  #             title : "Cancel"
  #             tooltip : "Close this dialog."
  #             click : -> _dialog.hide()

window.FileUpload = FileUpload