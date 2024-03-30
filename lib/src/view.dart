part of kwirk_escape;

class View {
  // html elements
  final selectLevel = querySelector('#selectLevel');
  final gamefield = querySelector('#gameField');
  final restart = querySelector('#restart');
  final levelSelection = querySelector('#levelSelection');
  final title = querySelector('#title');
  final nextLevel = querySelector('#nextLevel');
  final menuWindow = querySelector('#menu');
  final close = querySelector('#close');
  final cleared = querySelector('#cleared');
  final notification = querySelector('#notification');
  final container = querySelector('.container');
  final credits = querySelector('#credits');
  final tutField = querySelector('#tutorialField');
  final tutorial = querySelector('#tutorialWindow');
  final closeTutorial = querySelector('#closeTutorial');
  final tutorialNotification = querySelector('#tutorialNotification');
  // table for update
  List<List<HtmlElement>> table;

  View() {
    generateLevelList();
  }

  /// update the gamefield accordingly
  void update(Model model, int currentLevel) {
    final rowMax = model.getRowSize(), colMax = model.getColSize();
    Element tmp;
    for (num row = 0; row < rowMax; row++) {
      for (num col = 0; col < colMax; col++) {
        final td = table[row][col];
        // Wall, OoB, and Goal stays the same - always
        if (td.className != 'Wall' &&
            td.className != 'OoB' &&
            td.className != 'Goal') {
          if (td.className.contains('Teleport')) {
            // omly remove excess player
            td.classes.remove('Player');
          } else {
            td.classes.clear();
            // if Empty -> select FloorType
            tmp = model.getElement([row, col]);
            // for specific visualizaiton, check runtimetyp and update accordingly
            switch (tmp.runtimeTypeToString()) {
              case 'Empty': // if empty -> display floor
                td.classes.add(ftToString(model.getFloor([row, col])));
                break;
              case 'Block': // if block -> configure border
              case 'Gateway':
                if (tmp is Block) {
                  td.classes.add('Block');
                } else {
                  final gw = tmp as Gateway; // secure
                  if (gw.isJoint([row, col])) {
                    td.classes.add('Gateway_joint');
                  } else {
                    td.classes.add('Gateway');
                  }
                }
                // look in each dir and check if its a part of this element
                // if not, add a border
                if (model.getElement([row + up[_row], col + up[_col]]) != tmp) {
                  td.classes.add('top');
                }
                if (model.getElement([row + left[_row], col + left[_col]]) !=
                    tmp) {
                  td.classes.add('left');
                }
                if (model.getElement([row + down[_row], col + down[_col]]) !=
                    tmp) {
                  td.classes.add('bottom');
                }
                if (model.getElement([row + right[_row], col + right[_col]]) !=
                    tmp) {
                  td.classes.add('right');
                }
                break;
              // no defaults
            }
          }
        }
      }
    }
    // at last, add the player
    table[model.playerPos[_row]][model.playerPos[_col]].classes.add('Player');

    if (model.inGoal) {
      // update local storage
      if (int.parse(window.localStorage[kwirk_storage]) <= currentLevel) {
        window.localStorage
            .update(kwirk_storage, (lvl) => lvl = '${currentLevel + 1}');
        // if a new level is now unlocked, change button
        if (currentLevel + 1 <= numberLevels) {
          querySelector('#lvl${currentLevel + 1}')
              .style
              .removeProperty('background-color');
        }
      }
      // display menu
      menuWindow.style.display = 'block';
      nextLevel.style.display = 'inline-table';
      cleared.innerHtml = 'Wow you won, you are so smart!';
    }
  }

  /// generate the game field based on the model and initialize our table
  /// for the update function
  void generateGameField(Model model) {
    final rowMax = model.getRowSize(), colMax = model.getColSize();
    var field = '', addClasses = '';
    Element tmp;
    cleared.innerHtml = '';
    final tele = <Teleport>[];
    // next level only available if the current level is cleared
    nextLevel.style.display = 'none';
    for (num row = 0; row < rowMax; row++) {
      field += '<tr>';
      for (num col = 0; col < colMax; col++) {
        addClasses = ''; // rest border classes
        final pos = 'field_${row}_${col}';
        tmp = model.getElement([row, col]);
        switch (tmp.runtimeTypeToString()) {
          case 'Empty': // if empty -> display floor
            field += "<td id = '$pos' class = '${ftToString(model.getFloor([
              row,
              col
            ]))}'></td>";
            break;
          case 'Block':
          case 'Gateway':
            // configure border
            if (model.getElement([row + up[_row], col + up[_col]]) != tmp) {
              addClasses += ' top';
            }
            if (model.getElement([row + left[_row], col + left[_col]]) != tmp) {
              addClasses += ' left';
            }
            if (model.getElement([row + down[_row], col + down[_col]]) != tmp) {
              addClasses += ' bottom';
            }
            if (model.getElement([row + right[_row], col + right[_col]]) !=
                tmp) {
              addClasses += ' right';
            }
            if (tmp is Block) {
              field +=
                  "<td id = '$pos' class = '${'Block' + addClasses}'></td>";
            } else {
              final gw = tmp as Gateway; // secure
              field += "<td id = '$pos' class = '${(gw.isJoint([
                    row,
                    col
                  ]) ? 'Gateway_joint' : 'Gateway') + addClasses}'></td>";
            }
            break;
          case 'Goal':
            field += "<td id = '$pos' class = Goal></td>";
            break;
          case 'Teleport':
            field += "<td id = '$pos'></td>";
            // if (!tele.contains(model.getElement([row, col]))) {
            // tele.add(model.getElement([row, col]));
            //}
            if (!tele.contains(tmp)) {
              tele.add(tmp);
            }
            break;
        }
      }
      field += '</tr>';
    }
    gamefield.innerHtml = field;
    // init table for our update function
    table = List<List<HtmlElement>>(rowMax);

    for (num row = 0; row < rowMax; row++) {
      table[row] = List<HtmlElement>(colMax);
      for (num col = 0; col < colMax; col++) {
        table[row][col] = (gamefield.querySelector('#field_${row}_${col}'));
      }
    }
    // display teleports
    num i = 1;
    tele.forEach((port) {
      table[port._port_1[_row]][port._port_1[_col]].classes.add('Teleport_$i');
      table[port._port_2[_row]][port._port_2[_col]].classes.add('Teleport_$i');
      i += 1;
    });
    // add player to the game field
    table[model.playerPos[_row]][model.playerPos[_col]].classes.add('Player');
  }

  /// display the homescreen
  void homeScreen() {
    title.style.display = 'block';
    gamefield.innerHtml = '';
    notification.style.display = 'block';
    selectLevel.style.display = 'block';
    container.style.backgroundImage = 'url("$backGroundURL")';
    restart.style.display = 'none';
    levelSelection.style.display = 'none';
    nextLevel.style.display = 'none';
    credits.style.display = 'block';
    cleared.innerHtml = '';
    hideMenu();
    hideTutorial();
    // querySelector('html').style.overflow = 'auto';
  }

  /// display the inGame menu
  void showMenu() {
    menuWindow.style.display = 'block';
  }

  /// hide the inGame menu
  void hideMenu() {
    menuWindow.style.display = 'none';
  }

  /// show the window for the tutorial
  void showTutorial() {
    tutorial.style.display = 'block';
  }

  /// close the window for the tutorial
  void hideTutorial() {
    tutorial.style.display = 'none';
  }

  /// initialize the level list and grey scale all levels not playable
  /// based on the local storage and numberLevels
  void generateLevelList() {
    var field = '';
    for (num i = 1; i <= numberLevels; i++) {
      field += "<tr><td id= 'lvl$i' class ='lvlSelect'>Level $i</td></tr>";
    }
    selectLevel.innerHtml = field;
    // level not available
    for (num i = int.parse(window.localStorage[kwirk_storage]) + 1;
        i <= numberLevels;
        i++) {
      querySelector('#lvl$i').style.backgroundColor = lockedLevel;
    }
  }

  /// display the level
  void showLevel() {
    container.style.backgroundImage = 'none';
    title.style.display = 'none';
    selectLevel.style.display = 'none';
    notification.style.display = 'none';
    credits.style.display = 'none';
    restart.style.display = 'inline-block';
    levelSelection.style.display = 'inline-block';
    querySelector('.container').style.backgroundColor = 'white';
    // querySelector('html').style.overflow = 'hidden';
  }

  /// screen shake animation if the player moved in a not moveable dir
  void screenShatter() {
    var portrait = window.innerWidth < window.innerHeight;
    if (portrait) {
      gamefield.animate([
        {'transform': 'translate(0, 0) rotate(90deg)'},
        {'transform': 'translate(1px,1px) rotate(90deg)'},
        {'transform': 'translate(-1px,-1px) rotate(90deg)'},
        {'transform': 'translate(1px,1px) rotate(90deg)'},
        {'transform': 'translate(-1px,-1px) rotate(90deg)'},
        {'transform': 'translate(0, 0) rotate(90deg)'}
      ], 250);
    } else {
      gamefield.animate([
        {'transform': 'translate(0, 0)'},
        {'transform': 'translate(1px,1px)'},
        {'transform': 'translate(-1px,-1px)'},
        {'transform': 'translate(1px,1px)'},
        {'transform': 'translate(-1px,-1px)'},
        {'transform': 'translate(0, 0)'}
      ], 250);
    }
    //maybe find a better method to restart the animation i dont know
    //gamefield.replaceWith(gamefield);
  }

  void createTutorial(List<List<String>> elements, List<List<String>> animate,
      String text, int rowMax, int colMax) {
    tutorialNotification.innerHtml = text;
    var field = '';
    var addClasses = '';
    for (num row = 0; row < rowMax; row++) {
      field += '<tr>';
      for (num col = 0; col < colMax; col++) {
        addClasses = animate[row][col];
        switch (elements[row][col]) {
          case 'Empty': // do nothing
            field += '<td></td>';
            break;
          case 'Hole': // add hole css class
            field += '<td class = "Hole $addClasses" ></td>';
            break;
          case 'Block': // add block css class
            field += '<td class = "Block $addClasses"></td>';
            break;
          case 'Gateway': // add gateway css class
            field += '<td class = "Gateway $addClasses"></td>';
            break;
          case 'Gateway_joint':
            field += '<td class = "Gateway_joint $addClasses"></td>';
            break;
          case 'Teleport': // add teleport css class
            field += '<td class = "Teleport_1 $addClasses"></td>';
            break;
          case 'Player': // add player css class
            field += '<td class = "Player $addClasses"></td>';
            break;
          // no defaults
        }
      }
      field += '</tr>';
    }
    tutField.innerHtml = field;
  }
}
