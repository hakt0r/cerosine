require 'coffee-script'
htx        = require 'htx'
util       = require 'util'
fs         = require 'fs'
http       = require 'http'
https      = require 'https'
httpServer = require 'http-server'
colors     = require 'colors'
jquery     = require 'jquery'

# { Sync, Join }  = require 'ync'
_anapi_path     = '../../anapi/src/anapi.coffee' # 'anapi'
AnAPI           = require(_anapi_path).Server
{ Sync, Join }  = require '../../ync/src/ync'

Array::uniq = ->
  h = {}
  h[v] = true for v in @
  return Object.keys(h).sort()

_merge    = (t,d) -> t[k] = d[k] for k,v of d ; t
_defaults = (t,d) -> t[k] = d[k] for k,v of d when not t[k]?; t

class File
  path : null
  keys : []

  constructor : (opts={}) ->
    # Read site configuration, globals
    { @path, defaults, oninit } = opts
    @defaults.val = defaults
    @read oninit

  read : (callback) =>
    try
      data = JSON.parse fs.readFileSync @path
      @keys = Object.keys(data).concat(@keys).uniq()
      @[k] = v for k,v of data
    catch e
      console.log "ERROR:".red, "can't read from", @path.green
      console.log e
      @defaults()
      return @write null, callback
    return callback() if callback?

  defaults : =>
    console.log 'WARN: '.yellow, 'using defaults for', @path.green
    try
      vals  = @defaults.val
      @keys = @keys.concat(Object.keys vals).uniq()
      @[k] = v for k, v of vals when not @[k]?
    catch e
      console.log "ERROR:".red, "setting defaults for", @path.green
      console.log e

  write : (vals, callback) =>
    try
      @[k] = v for k,v of vals if vals?
      tmp = {}
      fs.writeFileSync @path, JSON.stringify @
    catch e
      console.log "ERROR:".red, "can't save to", @path.yellow
      console.log e
      callback false if callback?

class Folder
  constructor : (opts={}) ->
    { @path, @filter, thread } = opts
    thread.part() if thread
    @file = {}
    reader = new Join =>
      if @meta?
        for k, v of @meta when @image[k]?
          @image[k][o] = p for o, p of v
      thread.join()

    @index = new File
      path : @path + '/index.json'
    reader.part fs.readFile series_path + '/index.json', (err, data) ->
      unless err
        try series.meta = JSON.parse data
      else
        series.meta = meta = {}
      reader.join()
    
    reader.part fs.readdir series_path, (error, files) ->
      unless error?
        i = 0
        for file in files  when not file.match /\.json$/
          file_path = (series_path + '/' + file).replace path, ''
          series.image[file_path.split('/').pop()] =
            path : file_path
            id   : i++
      reader.join()

class Konsole
  widget : {}
  update : (id,line) =>
    @widget[id] = line
    console.log line for k, line of @widget

console.Debug = new Konsole

class CLSync extends Sync
  constructor : (opts) ->
    [ _run, _exec ] = [ @run, @exec ]
    _widget = (fnc) => => @widget(); fnc.apply @, arguments
    @run  = _widget _run
    @exec = _widget _exec
    super opts
  widget : => console.Debug.update @id, '[ ' + @title.yellow + ' ] ' + @current.yellow

class Server
  constructor : (opts) ->
    { @project, @template, @pages, @js, @coffee, page, ready, subsystem } = opts
    _callback = if ready? then ready else (->)
    _api = if opts.api? then opts.api else {}
    _me  = this
    boot = new CLSync
      title : @project
      fork  : yes
      config : =>
        dport = 8080 # Read site configuration, globals
        @config = new File
          path : process.env.PWD + '/etc/config.coffee',
          defaults :
            port   : dport
            wsport : dport + 1
          oninit : boot.proceed

      create_etc        : -> fs.mkdir './etc',        @proceed
      create_tmp        : -> fs.mkdir './tmp',        @proceed
      create_tmp_www    : -> fs.mkdir './tmp/www',    @proceed
      create_tmp_www_js : -> fs.mkdir './tmp/www/js', @proceed

      link_assets : ->
        if fs.existsSync './var'
          console.log 'linking var'
          fs.symlink '../../var', './tmp/www/var', @proceed
        else @proceed()

      update_assets : =>
        _get = (url, callback) ->
          if url.match '^https:' then https.get url, (res) ->
            res.setEncoding 'utf8'; buf = []
            res.on 'data', (data) -> buf.push data
            res.on 'end', (req) -> callback buf.join ''
          else http.get url, (res) ->
            res.setEncoding 'utf8'; buf = []
            res.on 'data', (data) -> buf.push data
            res.on 'end', (req) -> callback buf.join ''

        path   = require 'path'
        coffee = require 'coffee-script'

        @pages = {}    unless @pages?
        @jsappend = {} unless @jsappend?
        @js = {}       unless @js?

        @pages['index.html'] = page if page?

        @js = _merge({
            anapi : _anapi_path
            jquery : 'http://code.jquery.com/jquery-2.0.3.min.js'
            cerosine : '../../cerosine/src/cerosine.coffee'
          },@js)
        # @template = """<html><head></head></html>""" unless @template?
        @pages = { 'index.html' : (->) } unless @pages['index.html']?

        create = new Join -> boot.proceed()
        # compile global script assets
        _jsasset = (name, file) ->
          console.log '[', '   asset'.yellow , ']', name, file
          create.part()
          file     = path.resolve process.env.PWD + '/src', file if file.match /^\./ # resolve relative paths
          filename = path.basename file
          outpath  = './tmp/www/js/' + name + '.js'
          fs.exists file, (exists) ->
            if exists is true
              console.log '[', ' compile'.yellow , ']', name, filename
              fs.readFile file, (error, data) ->
                data = data.toString 'utf8'
                if file.match /coffee$/
                  data = coffee.compile data
                  filename = filename.replace /coffee$/, 'js'
                fs.writeFileSync outpath, data
                create.join()
            else fs.exists outpath, (exists) ->
              return create.join() if exists is true
              console.log '[', '   fetch'.yellow , ']', name, filename
              _get file, (data) ->
                fs.writeFileSync outpath, data
                create.join()
        _jsasset name, file for name, file of @js

        # compile pages
        for name, page of @pages
          console.log '[', '    page'.yellow , ']', name
          # scripts
          for k, code of page.coffee
            if typeof code is 'function'
              @jsappend[k] = code.toString()
            else @jsappend[k] = coffee.compile code
          # html
          $ = jquery.create()
          $(@template).find('head > *').appendTo 'head'
          $(@template).find('body > *').appendTo 'body'
          page.parent = $('body')
          page.id = name.replace(/\..*/,'') unless page.id?
          @pages[name] = p = new CFragment page
          tpl = '<!doctype html><html>' + $('html').html() + '</html>'
          tpl = tpl.replace '</body>', """<script type="text/javascript">
            window.__apiconf = "ws://localhost:#{@config.wsport}/"
            </script></body>"""
          tpl = tpl.replace '</head>', """<script type="text/javascript" src="js/#{k}.js"></script></head>""" for k, v of @js
          tpl = tpl.replace '</body>', """<script type="text/javascript">\n(\n#{v}\n).call()\n</script></body>""" for k, v of @jsappend
          create.part fs.writeFile './tmp/www/' + name, tpl, create.join

      start_webserver : => # Start backend server
        @web = httpServer.createServer(
          root      : './tmp/www'
          cache     : 1
          showDir   : yes
          autoIndex : yes
        ).listen @config.port, '0.0.0.0', =>
          console.log '[', @project.yellow, ']', 'webserver'.yellow , "listening".green, @config.port
          boot.proceed()

      start_websocket : =>
        @api = new AnAPI
          port : @config.wsport
          subsystem : subsystem
        @api.api.register _api
        boot.proceed()
        console.log '[', @project.yellow, ']', 'websocket'.yellow , "listening".green, @config.wsport

      start_cli : =>
        global.exit = -> process.exit(0)
        _callback() if _callback?
        console.log '[', @project.yellow, ']', 'ready'.green
        require("repl").start
          useGlobal : yes
          prompt : "#{@project} > "
          input  : process.stdin
          output : process.stdout

module.exports =
  File : File
  Folder : Folder
  Server : Server