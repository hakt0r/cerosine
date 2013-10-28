# $ = require 'jquery' unless window?

console.keys = (o) -> console.log Object.keys o

_merge    = (t,d) -> t[k] = d[k] for k,v of d ; t
_defaults = (t,d) -> t[k] = d[k] for k,v of d when not t[k]?; t

_snatch   = (s,k) ->
  return if Array.isArray k
      (( t = s[f]; delete s[f]; t ) for f in k)
    else ( t = s[k]; delete s[k]; t )

_steal = (s,k) ->
  return if Array.isArray k
      t = {}; (t[f] = s[f]; delete s[f]) for f in k when s[f]?; t
    else ( t = s[k]; delete s[k]; t )

_global = if window? then window else global

_global.i19 = (key) ->
  l = i19.lang
  return i19[l][key] if i19[l][key]?
  key
i19.lang = 'en'; i19.en = {}

_api = class
  @Api : -> console.log 'unimplemented, replace this function'
  @parent     : null
  @extensions : {}
  @classes    : []
  @plugin     : (name, exports) =>
    @extensions[name] = exports
    @classes.push name
    @[name] = _new_plugin name, exports
  _new_plugin = (name,ext={}) ->
    o = class extends Cerosine
      className : name
    _merge o::, ext.fncs
    o

class Cerosine
  @_ = _api
  @count      : 0
  constructor : (opts={}) ->
    @read opts if @read?
    [ show ] = _snatch opts, [ 'show' ]
    @build   = _steal opts, [ 'tag', 'wrap', 'insert', 'hide' ]
    
    @defaults opts if @defaults?
    @build   = _defaults @build, wrap : ['', ''], tag  : 'div', insert : 'append', inline : no
    if show? then @show.opts = show else @show.opts = { initially: true, title : false }
    @[k] = v for k, v of opts

    @specs  = opts
    @id     = @className + '-' + _global[@className].count++ unless @id? 
    @class  = @className unless @class?
    @title  = @id if (@id? and not @title?) and @show.title
    @title  = i19 @title if i19? and @title?
    @parent = $ @parent if @parent? and (typeof @parent is "string")
    @parent = $ """<div>""" unless @parent?
    @insert()

    if show is no then @hide()
    _global[@className][@id] = @
    @init @ if @init? and typeof @init is "function"

  read_children : (opts) =>
    for name, ext of _api.extensions when ext.read?
      ext.read.call @, opts

  create_children : (parent, tpl) =>
    for name, ext of _api.extensions
      for key, val of ext when tpl[key]?
        val.call @, parent, tpl[key]

  update : => _api.Api @get, @render

  insert : (parent) =>
    @parent = parent if parent?
    { insert, tag, wrap } = @build
    ( insert = 'append'; @parent.html '' ) if insert is 'replace'
    @parent[insert] """#{wrap[0]}<#{tag} class="#{@class}" id="#{@id}"></#{tag}>#{wrap[1]}"""
    @query  = @$ = @parent.find "##{@id}"
    @query.cerosine = @
    if @layout? then @layout()
    else for section in ['head','body','foot'] when @specs[section]?
      tpl = @specs[section]
      @query.append """<div class="#{section}">"""
      @[section]     = sect = @query.find '.' + section
      @[section].tpl = tpl
      sect.cerosine = @
      @create_children sect, tpl if tpl?
    @head.prepend "<h2>#{@title}</h2>" if @title? and @head?

  render : (data) => @parent.html()
  show   : => @query.show()
  hide   : => @query.hide()
  close  : => 
    @query.hide().replaceWith ''
    delete _global[@className][@id]

###
  CFragment
###

_api.plugin 'CFragment', html : (parent, tpl, data) ->
  if (t = typeof tpl) is 'function' then res = _res = tpl(@query, data)
  else if t is 'string' then _res = tpl
  parent.append _res if typeof _res is 'string'

###
  CButton
###

_api.plugin 'CButton',
  fncs :
    read : (opts) ->
      if opts.click # whats up with _snatch
        @onclick = opts.click; delete opts.click
      yes
    defaults : (opts) ->
      opts.title = opts.id unless opts.title?
      _defaults @build, {tag : 'button', insert : 'append'}
    layout : ->
      @query.prepend @title if @title?
      @query.prepend """<img src="#{@icon}" class="icon" />""" if @icon?
      if @onclick?
        @click = (val) ->
          if val? then @query.on "click",  (=> val.apply @, arguments)
          else @query.triggerHandler 'click'
        @click @onclick
      if $.tooltip? and @tooltip?
        @query.attr('title',@tooltip); @query.tooltip()
  buttons : (parent, tpl) =>
    _add = (btn) ->
      parent.cerosine.button = {} unless parent.cerosine.buttons?
      parent.cerosine.button[btn.id] = btn
    if (t = typeof tpl) is 'object' then for id, button of tpl
      button = { id : id, click : button } if typeof button is 'function'
      button = _merge button, parent : parent, inline : true
      _add new CButton button
    else if t is 'string' and (f = parent.cerosine[tpl])? and typeof f is 'function'
      _add new CButton parent : parent, id : tpl, click : f, inline : true
      
###
  CMenu
###

_api.plugin 'CMenu', {}

###
  CPage
###

_api.plugin 'CPage', 
  pages : (->)
  fncs :
    read : (opts) ->
      @template = """<!doctype html><html><head><meta charset="utf-8"><title>cerosine</title></head><body></body></html>"""
      @type = 'public' unless opts.type?
    show : -> $('#pageContent').html @render()

###
  CList
###
_api.plugin 'CList',
  list : (parent, tpl) -> parent.cerosine.list = new CList tpl
  fncs :
    read : (opts) -> @get = _snatch opts, 'get'
    update : ->
      _api.Api.call null, @get, (data) =>
        @line data, @query

###
  CDialog
###

_api.plugin 'CDialog',
  fncs : 
    read : (opts={}) ->
      _defaults opts, parent : CDialog.parent, modal : yes
    toggle : -> @show @query.css('display') is 'none'
    hide : ->
      _hide = =>
        @parent.css 'display', 'none' if @modal
        @query.css  'display', 'none'
      if @query.fadeOut? then @query.fadeOut _hide else _hide()
    show : ->
      @insert()
      @parent.css 'display', 'block' if @modal
      @query.css  'display', 'block'
      if @query.fadeIn? then @query.fadeIn

###
  CForm and consorts
###

__tag = (tag, attr={}) ->
  buf = []
  buf.push '<' + tag
  for k, v of attr
    buf.push ' ' + k + '="' + v + '"'
  if inner? then buf.push inner + '></' + tag + '>'
  else buf.push '/>'
  return buf.join ''

__field_variant = (type) -> return (specs) ->
  verify = []
  for k,v in _api.verify when specs[k]
    verify.push v specs[k]
    delete specs[k]
  form = __tag 'input', (specs.type = type; specs)
  form.verify = verify
  form

_api.verify =
  length    : (length) -> -> return @length >= length
  minlength : (length) -> -> return @length >= length
  email : -> ->
    return i19 'email_incorrect_format' unless @match /.*@.*\..*/
    true
  password : -> ->
    e.push i19 'password_to_short'  unless @length >= 8
    e.push i19 'password_to_long'   unless @length <= 64
    e.push i19 'password_to_simple' unless @match /[a-zA-Z0-9.,!@#$%^&*()]+/
    return e if e.length > 0
    true

_api.types =
  number   : __field_variant 'number'
  hidden   : __field_variant 'hidden'
  text     : __field_variant 'text'
  password : __field_variant 'password'
  checkbox : (specs) ->
    if specs.value? and specs.value is true
      specs.checked = "checked"; delete specs['value']
    __tag 'input', (specs.type = 'checkbox'; specs)
  textarea : (specs) ->
    if (v = specs.value)? then delete specs['value'] else v = ''
    __tag 'textarea', specs

# This plugin is per-se supposed to patch any given
# Cerosine fragment
_api.plugin 'CForm',
  fields : (parent, tpl) ->
    data = if tpl.data? then (t = tpl.data; delete tpl.data; t) else {}
    _inst = parent.cerosine
    _inst.field = {} unless _inst.field?
    _inst.fields = -> Object.keys @field
    _inst.values = -> ( args = {}; args[i] = @field[i].val() for i in @fields(); args )
    for name, type of tpl
      if typeof type is 'object'
        specs = type 
        type  = specs.type
      else specs = {}
      if (tp = _api.types[type])?
        specs.name  = name
        specs.value = data[name] if data[name]?
        if specs.label?
          label = specs.label
          delete specs.label
        else label = name
        if specs.desc?
          desc = specs.desc
          delete specs.desc
        label = i19 label if i19?
        parent.append("""<label>#{label}</label>""") unless specs.type is 'hidden'
        parent.append(tp(specs))
        parent.append("""<span>#{desc}</span>""") if desc?
        _inst.field[name] = _inst[name] = parent.find "> *[name=#{name}]"
    null

###
  CNotification
###

class CNotification
  className : 'CNotification'
  start   : null
  timeout : null
  @count  : 0

  @init   : ->
    $('body').append """<div id="notification-container" style="pointer-events:none;position:fixed;top:0px;right:0px;bottom:0px;width:33%"></div>"""
    @container = $("#notification-container")

  constructor : (opts={}) ->
    { @start, @timeout, @text, @desc, @id } = opts
    @start = Date.now().getTime()/1000 unless @?
    @timeout = 2 unless @timeout?
    @text = i19 @text if i19?
    @desc = i19 @desc if i19?
    @id = CNotification.count++ unless @id
    @domid = "notification-#{@id}"
    CNotification.container.append """
      <div class="notification" id="#{@domid}" style="pointer-events:initial">
        <h2>#{@text}</h2>
      </div>"""
    @query = CNotification.container.find '#'+@domid
    @query.append """<span class="desc">#{@desc}</span>""" if @desc?
    @query.on 'mouseover',  @wait
    @query.on 'mouseleave', @reset
    @reset()
  wait : => @reset yes
  reset : (only=false)=>
    clearTimeout @timer if @timer?
    @timer = setTimeout @destroy, 1000 * @timeout unless only is true
  destroy : => @query.fadeOut => @query.replaceWith('')

# if window?
#   $.ready ->
#     CNotification.init()
#     notify "powered by cerosine"
# else CNotification.init()

###
  CTask
###

class CTask
  className : 'CTask'
  @container  : null

  constructor : (opts={}) ->

    { @parent, @id, @title, progress } = opts

    @parent = CTask.container unless @parent?
    @parent = $(@parent) if typeof @parent is "string"
    @parent.append """
      <div class="task">
        <div class="progress"></div>
        <h4>#{@title}</h4>
        <button class="close click">close</button>
      </div>"""

    @query = @$ = @parent.find ".task"

    @close = @query.find "button.close"
    @close.on 'click', =>
      @query.css "display", "none"

    for call in ['pause','cancel','resume']
      if opts[call]?
        @query.append """<button class="framed #{call}" />"""
        @[call] = @query.find '.'+call
        @[call].on 'click', -> call()

    @pbar = @query.find ".progress"
    @tbar = @query.find "h4"

    @progress progress,state if progress? 

  show : => @query.show()
  hide : => @query.hide()

  progress : (v,k) ->
    @tbar.html @title + if k? then ' [' + k + ']' else ''
    @pbar.css "width",'' + Math.min(100,v) + '%'

  done : -> @pbar.css 'background','green'

#if window? then $.ready ->
#  $('body').append """<div class="task-container noselect noclick"></div>"""
#  CTask.container = $ 'body > .task-container'
#  true

notify = (text,desc) -> new CNotification text : text, desc : desc

_merge _global, _merge _api,
  i19    : i19
  notify : notify

if window? then window[k] = v for k,v of _api
else module.exports = _api
