
class UITask
  @container  : null

  constructor : (opts={}) ->

    { @parent, @id, @title, progress } = opts

    @parent = Task.container unless @parent?
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

$(document).ready ->
  $('body').append """<div class="task-container noselect noclick"></div>"""
  Task.container = $ 'body > .task-container'
  true

window.UITask = UITask