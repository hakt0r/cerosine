
class UIDialog
  @parent : null
  @count : 0
  @byId  : {}
  button : {}
  constructor : (opts={}) ->
    { @parent, @id, @init, show, head, foot, body } = opts
    @parent = UIDialog.parent    unless @parent?
    @id = "dialog-#{UIDialog.count++}" unless @id?
    @parent.append """
      <div class="dialog" id="#{@id}">
        <div class="dlg-head"></div>
        <div class="dlg-body"></div>
        <div class="dlg-foot"></div>
      </div>"""
    @query = @$ = $("##{@id}")
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
    @parent.css 'display', state
    @query.css     'display', state

$(document).ready ->
  $('body').append """<div class="dialog-container"></div>"""
  UIDialog.parent = $ 'body > .dialog-container'
  true

window.UIDialog = UIDialog