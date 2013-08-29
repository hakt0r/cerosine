class UIButton
  @count : 0
  @byId  : {}
  constructor : (opts={})->
    { tag, wrap, insert, @parent, @tooltip, @click, @init, @class, @id, @title, hide } = opts
    @parent = document.querySelector(@parent) if typeof @parent is "string"
    @id = "button-#{UIButton.count++}" unless @id?
    @title = @id unless @title?
    @class = @id unless @class?
    wrap = ['',''] unless wrap?
    tag  = 'button' unless tag?
    insert = 'append' unless insert?
    $(@parent)[insert]("""#{wrap[0]}<#{tag} class="#{@class}" id="#{@id}-btn">#{@title}</#{tag}>#{wrap[1]}""")
    @query = @$ =  $("##{@id}-btn")
    @query.hide() if hide? and hide is true
    @query.on("click", => @click.apply @, arguments) if @click?
    UIButton.byId[@id] = @
    @init() if @init?
    if $.tooltip? and @tooltip?
      @query.attr('title',@tooltip)
      @query.tooltip()
  show : => @query.show()
  hide : => @query.hide()

window.UIButton = UIButton