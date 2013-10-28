{ Server } = require './server'
{ i19 }    = require './cerosine'

http = require 'http'

_get = (url, callback) -> http.get url, (res) ->
  res.setEncoding 'utf8'
  buf = []
  res.on 'data', (data) -> buf.push data
  res.on 'end', (req) -> callback buf.join ''

new Server
  i19 : en :
    test_page : "A Test Page"
    test_body : "A Test Page"
  project : "cerosine"
  js : termjs : 'https://raw.github.com/chjj/term.js/master/src/term.js'
  api : ping : (a) -> @reply pong : 'anapi biatsch: ' + a 
  page :
    title : 'test_page'
    body : html : 'test_body'
    coffee : init : ->
      console.log 'init by insanity'
      window.Api = new WebApi __apiconf
      Api.register pong : (msg) -> console.log 'pong', msg
      Api.connect -> @send ping : 'anapy?'
  ready : ->
    _get 'http://localhost:8080/index.html', (data) ->
      #console.log data
      #process.exit(1)