
class UIDialog
  @parent : null
  @count : 0
  @byId  : {}

  button : {}

  constructor : (opts={}) ->
    { @parent, @id, @init, show, head, foot, body } = opts

    @parent = UIDialog.parent          unless @parent?
    @id = "dialog-#{UIDialog.count++}" unless @id?

    @parent.append """
      <div class="dialog" id="#{@id}">
        <div class="dlg-head"></div>
        <div class="dlg-body"></div>
        <div class="dlg-foot"></div>
      </div>"""
    @query = @$ = $("##{@id}")

    for section, v of {head:head,body:body,foot:foot}
      @[section] = $("##{@id} .dlg-#{section}")
      if v?
        @[section].append v.html if v.html?
        if v.buttons? then for k,b of v.buttons
          b.id = k; b.parent = @[section]
          btn = new UIButton b
          @button[k] = btn

    @init() if @init? and typeof @init is "function"
    @show() if show is yes

  hide : -> @show no
  show : (show=yes) ->
    state = if show then 'block' else 'none'
    @parent.css 'display', state
    @query.css  'display', state

class UIForm extends UIDialog
  @types :
    text     : (name, specs, data) ->
      """<input type="text"     name="#{name}" value="#{if data? then data else ''}"/>"""
    password : (name, specs, data) ->
      """<input type="password" name="#{name}" value="#{if data? then data else ''}"/>"""
    checkbox : (name, specs, data) ->
      """<input type="checkbox" name="#{name}" value="#{if data? then data else ''}"/>"""

  constructor : (opts={}) ->
    _opts = {}
    for k in [ 'parent', 'id', 'init', 'show', 'head', 'foot', 'body' ] when opts[k]?
      _opts[k] = opts[k]; delete opts[k]
    super _opts

    if opts['data']? then data = opts.data
    else data = {}

    for k, v of opts
      if UIForm.types[v]?
        @body.append UIForm.types[v](k,v,data[k])
        @[k] = @body.find "> *[name=#{k}]"

if window?
  $(document).ready ->
    $('body').append """<div class="dialog-container"></div>"""
    UIDialog.parent = $ 'body > .dialog-container'
    true
  window.UIDialog = UIDialog
  window.UIForm = UIForm

else
  cheerio = require('cheerio')
  $ = cheerio.load('<div id=dialog-container></div>')
  UIDialog.parent = $('#dialog-container')

  f = new UIForm
    name     : 'text'
    pass     : 'password'
    remember : 'bool'

  console.log f.parent.html()


