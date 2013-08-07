class UIButton
  @count : 0
  @byId  : {}
  constructor : (opts={})->
    { @parent, @tooltip, @click, @init, @class, @id, @title, hide } = opts
    @parent = document.querySelector(@parent) if typeof @parent is "string"
    @id = "button-#{UIButton.count++}" unless @id?
    @title = @id unless @title?
    @class = @id unless @class?
    $(@parent).append("""<button class="#{@class}" id="#{@id}-btn">#{@title}</button>""")
    @query = @$ =  $("##{@id}-btn")
    @query.hide() if hide? and hide is true
    @query.on("click", => @click.apply @, arguments) if @click?
    UIButton.byId[@id] = this
    @init() if @init?
    if $.tooltip? and @tooltip?
      @query.attr('title',@tooltip)
      @query.tooltip()
  show : => @query.show()
  hide : => @query.hide()

window.UIButton = UIButton