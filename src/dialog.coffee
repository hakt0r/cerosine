
class UIDialog
  @container : null
  @count : 0
  @byId  : {}
  button : {}
  constructor : (opts={}) ->
    { @container, @id, @init, show, head, foot, body } = opts
    @container = UIDialog.container    unless @container?
    @id = "dialog-#{UIDialog.count++}" unless @id?
    @container.append """
      <div class="dialog" id="#{@id}">
        <div class="dlg-head"></div>
        <div class="dlg-body"></div>
        <div class="dlg-foot"></div>
      </div>"""
    @query = $("##{@id}")
    for section, v of {head:head,body:body,foot:foot} when v?
      @[section] = $("##{@id} .dlg-#{section}")
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
    @container.css 'display', state
    @query.css     'display', state

$(document).ready ->
  $('body').append """<div class="dialog-container"></div>"""
  UIDialog.container = $ 'body > .dialog-container'
  true

window.UIDialog = UIDialog