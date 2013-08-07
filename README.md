## cerosine - coffee-script inspired UI kit for html5 and jQuery

### Installation
    $ sudo npm install cerosine (TODO: publish when ready ;)
    $ sudo npm install git://github.com/hakt0r/cerosine.git

### Documentation
#### Example
    s = new UIButton
    parent : '#toolbar'
    click  : ->
      s.$.css.addClass "active"
      d = new UIDialog
        parent : "#dialogs"
        head : html : "<h1>header</h1>"
        body : html : """
            <div>#{Math.random()*100}</div>
            <div>#{Math.random()*100}</div>
            <div>#{Math.random()*100}</div>
          """
        init : ->
          d.$.attr 'is-dialog', 'yes'

#### UIDialog options
##### Functions
  * show : show the dialog
  * hide : hide the dialog
##### Options
  * parent @ string (dom-query)
  * id @ string
  * init @ function
  * show @ bool
  * head, body, foot :
    * tml @ string
    * uttons @ { UIButton }

#### UIButton
##### Functions
  * show : show the button
  * hide : hide the button
##### Options
  * parent @ string (dom-query)
  * id @ string
  * hide @ bool
  * class @ string
  * title @ string
  * tooltip @ string
  * init @ function
  * click @ function

#### UITask options
##### Functions
  * show : show the notification
  * hide : hide the notification
  * progress : update the progress bar
    * value @ int (0-100)
    * status @ string, optional
  * hide : hide the notification
##### Options
  * parent @ string (dom-query)
  * id @ string
  * title @ string
  * status @ string
  * progress @ int (0-100)

### Copyrights
  * c) 2013 Sebastian Glaser <anx@ulzq.de>

### Licensed under GNU GPLv3

cerosine is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

cerosine is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this software; see the file COPYING.  If not, write to
the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA 02111-1307 USA

http://www.gnu.org/licenses/gpl.html