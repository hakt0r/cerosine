
colors = require 'colors'

Sync = require 'ync'
Cerosine = require './cerosine'
{ CList, CFragment, CPage, CMenu, CDialog, CButton, CForm } = Cerosine

String::test = (m) -> @.match(m) isnt null 

tests = 0; success = 0
test = (name, value) ->
  console.log name.yellow
  tests++
  if value is false then console.log 'error'.red, name.yellow, value
  else success++

new Sync
  CFragment : ->
    t = false
    f = new CFragment
      id : 'test_frag'
      title : 'test_title'
      head  : html : 'test_static'
      body  : html : -> 'test_function'
      foot  : buttons : test_button : -> t = true 
    r = f.render()
    test 'frg_tag',               r.test /^<div/
    test 'frg_class',             r.test /CFragment/
    test 'title',                 r.test /test_title/
    test 'section_static_html',   r.test /test_static/
    test 'section_function_html', r.test /test_function/
    test 'section_btn_id',        r.test /test_button/
    test 'btn_tag',               r.test /button class="CButton/
    test 'btn_class',             r.test /CButton/
    if e = f.button.test_button?
      f.button.test_button.click()
      test 'section_btn_click', t
    test 'section_btn_exists', e
    @proceed()

  CList : ->
    t = false
    Cerosine.Api = (get, callback) -> callback { a : get[0], b : get[1], c : get[2], d : get[3] }
    f = new CList
      title : "test_list"
      get : [ 'test', 1, 2, 3]
      head : buttons : test_add : -> t = true
      line : (data, parent) -> parent.append "<tr><td>#{k}</td><td>#{v}</td></tr>" for k, v of data
    f.update()
    r = f.render()
    test 'list_title',     r.test /test_list/
    test 'list_data_str',  r.test />test</
    test 'list_data_key1', r.test />a</
    test 'list_data_key2', r.test />b</
    test 'list_data_key3', r.test />c</
    test 'list_data_val1', r.test />1</
    test 'list_data_val2', r.test />2</
    test 'list_data_val3', r.test />3</
    if f.button.add?
      test 'list_button',  true
      f.buttons.add.click()
      test 'list_button_click', t
    @proceed()

  CButton : ->
    t = false
    f = new CButton
      id    : 'test_id'
      title : 'test_title'
      click : -> t = true
    r = f.render()
    test 'button_id',       r.test /test_id/
    test 'button_title',    r.test /test_title/
    f.click()
    test 'button_function', t
    @proceed()

  CForm : ->
    f = new CForm body : fields :
      test_pass : 'password'
      test_text : 'text'
      test_chec : 'checkbox'
    r = f.render()
    test 'section_form_password', r.test /test_pass/
    test 'section_form_text',     r.test /test_text/
    test 'section_form_checkbox', r.test /test_chec/
    @proceed()

  backend : ->
    @run "finalize" if window?
    { Server } = require './server'
    i19.test_page = "A Test Page"
    Server.boot
      project : "cerosine"
      api : test : -> true
      pages : 'index.html' :
        id : 'test_page'
        body : html : 'test_body'
      ready : => @proceed()

  finalize : ->
    if tests is success
      console.log 'All'.green, (''+tests).yellow, "passed without errors".green
    else
      console.log 'Warning'.red, '[', (''+(tests-success)).red, '/', (''+tests).yellow, ']', "tests had".yellow, "errors".red
