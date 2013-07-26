class Task
  constructor : (opts={}) ->
    { @parent, @id, @title, progress } = opts
    @parent = $(@parent) if typeof @parent is "string"
    console.log @parent.append """
      <div class="task">
        <div class="progress"></div>
        <h4>#{@title}</h4>
      </div>"""
    @query = @parent.find ".task"

    for call in ['pause','cancel','resume']
      if opts[call]?
        @query.append """<button class="framed #{call}" />"""
        @[call] = @query.find '.'+call
        @[call].on 'click', -> call()

    @pbar = @query.find ".progress"
    @tbar = @query.find "h4"
  progress : (v,k) ->
    @tbar.html @title + ' @' + k
    @pbar.css "width",''+v+'%'
  done : -> @pbar.css 'background','green'

window.Task = Task