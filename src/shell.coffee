pty = require("pty.js")

{ Server } = require './server'
{ i19 }    = require './cerosine'

new Server
  project : "cerosine"
  js : termjs : 'https://raw.github.com/chjj/term.js/master/src/term.js'
  api :
    connect : ->
      @pty = term = pty.spawn("bash", [],
        name: "xterm-color"
        cols: 80
        rows: 30
        cwd: process.env.HOME
        env: process.env )
      term.on "data", (data) => @reply termdata : data
    term : (data) -> @pty.write data
  page :
    title : 'test_page'
    body : html : 'test_body<style>.terminal {font-family: Mono}</style>'
    coffee : init : ->
      window.Api = new WebApi __apiconf
      Api.register pong : (msg) -> console.log 'pong', msg
      Api.connect ->
        window.term = new Terminal cols: 80, rows: 24, screenKeys: true
        term.open document.body
        term.write "\u001b[31m Connected to \x1b[33mcerosine\x1b[0m shell powered by term.js!\u001b[m\r\n"
        term.on 'data', (data) => @send term : data
        @register
          termdata   : (data) -> term.write data
          disconnect : -> term.destroy()
