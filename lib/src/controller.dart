part of kwirk_escape;

class Controller {
  View view;
  Model model;

  /// number of the current Level, based of the name of json file
  /// e.g. Level_3.json -> currentLevel = 3
  /// 0 if no level is currently selected
  ///
  int currentLevel;

  /// Array containing all level as JSON-Strings
  static final level = List<String>(numberLevels);

  Controller() {
    // load all level-data and store it into the model
    for (num i = 1; i <= numberLevels; i++) {
      HttpRequest.getString('level/Level_$i.json')
          .then((final v) => level[i - 1] = v);
    }
    // initialize local storage if its empty
    window.localStorage.putIfAbsent(kwirk_storage, () => '1');

    // create a new view
    view = View();

    // initialize listeners
    _levelSelectionListener();
    _movePlayerListener();
    _initMenuListeners();
    _closeTutorialListener();
  }

  /// listener for the player movement per keyboard as well as touchscreen
  ///
  /// control.dart vom github-project ya2048 als vorlage genommen
  void _movePlayerListener() {
    final controls = [
      KeyCode.UP,
      KeyCode.W,
      KeyCode.RIGHT,
      KeyCode.D,
      KeyCode.DOWN,
      KeyCode.S,
      KeyCode.LEFT,
      KeyCode.A
    ];
    window.onKeyDown.where((ev) => controls.contains(ev.keyCode)).listen((ev) {
      if (model != null) {
        // determin screen orientation, since in portrait view the
        // gamefield gets rotated and thus the controls need to be adjusted
        var portrait = window.innerWidth < window.innerHeight;
        var hasMoved = false;
        switch (ev.keyCode) {
          case KeyCode.UP:
          case KeyCode.W:
            hasMoved = (portrait ? model.move(left) : model.move(up));
            break;
          case KeyCode.RIGHT:
          case KeyCode.D:
            hasMoved = (portrait ? model.move(up) : model.move(right));
            break;
          case KeyCode.DOWN:
          case KeyCode.S:
            hasMoved = (portrait ? model.move(right) : model.move(down));
            break;
          case KeyCode.LEFT:
          case KeyCode.A:
            hasMoved = (portrait ? model.move(down) : model.move(left));
            break;
        }
        if (hasMoved) {
          view.update(model, currentLevel);
        } else if (!model.inGoal) {
          view.screenShatter();
        }
      }
    });

    Point start, end;
    window.onTouchStart.listen((ev) => start = ev.changedTouches.first.page);
    window.onTouchEnd.listen((ev) {
      if (model != null) {
        // determin screen orientation, since in portrait view the
        // gamefield gets rotated and thus the controls need to be adjusted
        var portrait = window.innerWidth < window.innerHeight;
        var hasMoved = false;
        // determin swipe direction
        end = ev.changedTouches.last.page;
        int dx = start.x - end.x;
        int dy = start.y - end.y;
        var horizontal = dx.abs() > dy.abs();
        var vertical = dy.abs() > dx.abs();
        // threshhold is 3, so that minimal movements when double clicking
        // don't trigger a move
        if (vertical && dy > 3) {
          hasMoved = (portrait ? model.move(left) : model.move(up));
        } else if (horizontal && dx < -3) {
          hasMoved = (portrait ? model.move(up) : model.move(right));
        } else if (vertical && dy < -3) {
          hasMoved = (portrait ? model.move(right) : model.move(down));
        } else if (horizontal && dx > 3) {
          hasMoved = (portrait ? model.move(down) : model.move(left));
        } else {
          // do nothing if no valid move option
          return;
        }
        if (hasMoved) {
          view.update(model, currentLevel);
        } else if (!model.inGoal) {
          view.screenShatter();
        }
      }
    });
  }

  /// initializes the four buttons of kwirk's ingame menu
  /// /// access the menu through esc or double click
  /// - return to level selection:  return the the main menu
  /// - restart the level:          restart the level
  /// - next level:                 if possible, load the next level
  /// - close menu:                 closes the menu
  void _initMenuListeners() {
    // init the menu accessibility
    window.onDoubleClick.listen((ev) {
      view.showMenu();
    });
    window.onKeyDown.where((ev) => ev.keyCode == KeyCode.ESC).listen((ev) {
      view.showMenu();
    });

    //-----------------------------------------
    // init listener: return to level selection
    // when returning to the menu, clear the model / gamefield
    view.levelSelection.onClick.listen(
        (MouseEvent e) => {view.homeScreen(), model = null, currentLevel = 0});

    //-----------------------------------------
    // init listener: restart the level
    view.restart.onClick
        .listen((MouseEvent e) => _loadLevel(level[currentLevel - 1]));

    //-----------------------------------------
    // init listener: next level Button
    // only possible if you have once beaten the current level
    // if there is no next level< nothing happens
    view.nextLevel.onClick.listen((MouseEvent e) {
      if (currentLevel < numberLevels) {
        _loadLevel(level[currentLevel]);
        currentLevel++;
      } else {
        view.cleared.innerHtml = 'There is no next level :-(';
      }
    });

    //-----------------------------------------
    // init listener: close Menu Button
    view.close.onClick.listen((MouseEvent e) => view.hideMenu());
  }

  /// initialize the main menu's level selection buttons
  void _levelSelectionListener() {
    for (num i = 1; i <= numberLevels; i++) {
      querySelector('#lvl$i').onClick.listen((MouseEvent e) {
        // a level is only accessible if his preceding level was cleared
        if (int.parse(window.localStorage[kwirk_storage]) >= (i)) {
          _loadLevel(level[i - 1]);
          view.showLevel();
          currentLevel = i;
        }
      });
    }
  }

  ///initialize the button to close the window for the tutorial
  void _closeTutorialListener() {
    view.closeTutorial.onClick.listen((MouseEvent e) {
      view.hideTutorial();
    });
  }

  /// load a level into the game via json String
  void _loadLevel(String json) {
    Map<String, dynamic> level = jsonDecode(json);
    model = Model.fromJson(level);
    view.generateGameField(model);
    view.hideMenu();
    if (level.containsKey('Explanation')) {
      var field = <List<String>>[];
      var animate = <List<String>>[];
      final text = level['Explanation']['Text'];
      num i = 0;
      // add css class name
      level['Explanation']['Field'].forEach((row) =>
          {field.add([]), row.forEach((ele) => field[i].add(ele)), i++});
      i = 0;
      // add css animation class name
      level['Explanation']['Animate'].forEach((row) =>
          {animate.add([]), row.forEach((ele) => animate[i].add((ele == 'none' ? '' : ele))), i++});

      view.createTutorial(field, animate, text, field.length, field[0].length);
      view.showTutorial();
    }
  }
}
