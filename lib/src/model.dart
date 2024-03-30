part of kwirk_escape;

/// The Model of [Kwirk_Escape]
///
/// contains the following Attributes:
/// - [level]:      Array of all level as JSON-Strings
/// - [empty]:      [Empty] [Element] for [elements]
/// - [floor]:      List of [FloorType] - shaping the Ground of Kwirk_Escape
/// - [elements]:   List of [Element]s - offering interaction in Kwirk_Escape
/// - [playerPos]:  The Players positon
/// - [inGoal]:     a check, whether the Player already finished the Stage
///
/// offers the following Methods:
/// - [getRowMax]:              returns number of rows
/// - [gotColMax]:              returns number of cols
/// - [getElement(pos)]:        returns the [Element] at pos
/// - [getFloor(pos)]:          returns the [FloorType] at pos
/// - [Model.fromJson(json)]:   creates the [Model] form a .json File (constructor)
class Model {
  // ---- Attributes ----

  /// [Empty] [Element] for multi use
  /// it is intended to only have one instance of this [Element]
  Empty empty;
  List<List<FloorType>> floor;
  List<List<Element>> elements;
  List<int> playerPos = List<int>(2); // fixed length 2
  /// default Value = false, will be set to true once [Goal.interact] is called
  bool inGoal = false;

  // ---- Constructor ----

  /// creates a Model out of a .json File
  /// rules can be found here: Team-04-E/doc/json_rules.md
  Model.fromJson(Map<String, dynamic> json) {
    empty = Empty(this);
    floor = [];
    elements = [];
    num i = 0;
    // create FloorType List
    json['FloorType'].forEach((row) => {
          floor.add([]),
          row.forEach((col) => floor[i].add(ftFromString(col))),
          i++
        });
    i = 0;
    // get all Elements
    var elementMap = Element.elementsFromJson(json, this);
    // create Element List based on elementMap
    json['Elements'].forEach((row) => {
          elements.add([]),
          row.forEach((col) => elements[i].add(elementMap[col])),
          i++
        });
    playerPos = [(json['Player'][_row]), (json['Player'][_col])];
  }

  // ---- Methods ----

  int getRowSize() {
    return floor.length;
  }

  int getColSize() {
    // n x m field -> it doenst matter what n i ask they are all the same
    return floor[0].length;
  }

  /// get [Element] at pos
  Element getElement(List<int> pos) {
    return elements[pos[_row]][pos[_col]];
  }

  /// get [Floor] at pos
  FloorType getFloor(List<int> pos) {
    return floor[pos[_row]][pos[_col]];
  }

  /// move the Player in dir
  ///
  /// returns true if the postion changed
  bool move(List<int> dir) {
    // dont move if inGoal
    if (inGoal) {
      return false;
    }
    // can only move on FloorType.Ground
    if (getFloor(
            [(playerPos[_row] + dir[_row]), (playerPos[_col] + dir[_col])]) !=
        FloorType.Ground) {
      return false;
    }
    final newPos = getElement(
            [(playerPos[_row] + dir[_row]), (playerPos[_col] + dir[_col])])
        .interact(dir);
    // look whether the [pos] has changed
    if (playerPos == newPos) {
      return false;
    }
    // set new pos
    playerPos = newPos;
    return true;
  }
}

/// The super class of every [Element] the [Model] can
/// interact with.
abstract class Element {
  Model model;

  /// [interact] with this in the given dir
  ///
  /// returns the new [playerPos]
  List<int> interact(List<int> dir);

  /// a toString Method for better access to runtype
  String runtimeTypeToString();

  /// Creates a Map of {id, [Element]} (based on json) for further use
  static Map<int, Element> elementsFromJson(
      Map<String, dynamic> json, Model model) {
    var map = <int, Element>{};
    json['Element'].forEach((ele) => {
          map.putIfAbsent(
              ele['id'], () => _elementFromJsonString(ele['type'], ele, model))
        });
    return map;
  }

  /// Creates an [Element] based on the supplied json and the type
  static Element _elementFromJsonString(
      String type, Map<String, dynamic> json, Model model) {
    switch (type) {
      case 'Empty':
        return model.empty;
        break;
      case 'Goal':
        return Goal(model);
        break;
      case 'Block':
        return Block._fromJson(json, model);
        break;
      case 'Gateway':
        return Gateway._fromJson(json, model);
        break;
      case 'Teleport':
        return Teleport._fromJson(json, model);
        break;
      default:
        Error();
        return null;
    }
  }
}

/// The [Block] is a multipositional [Element] which can be interacted
/// with by the Player. It also has a special interaction with the
/// [FloorType.Hole]. If every part of a [Block] has said [FloorType]
/// underneath it, the [Block] will "fall" into the hole and thus
/// truning the [FloorType.Hole] into [FloorType.Ground]. While doing
/// so the [Block] will disappear from the game
class Block extends Element {
  /// [position] is a List of the [Element]s positions and thus
  /// shapes the [Element]
  List<List<int>> position;

  /// Creates a new [Block] out of json, model
  Block._fromJson(Map<String, dynamic> json, Model model) {
    // e.g. {"id": 2, "type": "Block", "position": [[2, 10], [2, 11], [3, 10], [3, 11], [4, 10], [4, 11]]}],
    super.model = model;
    position = [];
    num i = 0;
    json['position'].forEach((row) =>
        {position.add([]), row.forEach((col) => position[i].add(col)), i++});
  }

  @override
  String runtimeTypeToString() {
    return 'Block';
  }

  @override
  List<int> interact(List<int> dir) {
    if (_moveable(dir)) {
      _moveElement(dir);
      return [
        super.model.playerPos[_row] + dir[_row],
        super.model.playerPos[_col] + dir[_col]
      ];
    } else {
      // if not moveable -> do nothing
      return super.model.playerPos;
    }
  }

// ----- helper methods -----

  /// Determins wheteher this is moveable in dir
  ///
  /// this is moveable if each pos is moveable
  /// a pos is considered moveable if:
  ///   - the sequential [FloorType] is [FloorType.Ground] or [FloorType.Hole]
  ///   - the sequential [Element] is [Empty] or part of this
  ///
  /// returns true if each pos is moveable in dir
  bool _moveable(List<int> dir) {
    var current = List<int>(2);
    var element = true, floor = true;
    // - element and floor start with the neutral element of the && operation
    // - for each pos it is checked whether this is moveable - stored in element/floor
    // - floor/element && 'bool' - ensures that we dont forget a false evaluation
    position.forEach((pos) => {
          current = [pos[_row] + dir[_row], pos[_col] + dir[_col]],
          floor = floor &&
              ((super.model.getFloor(current) == FloorType.Ground) ||
                  (super.model.getFloor(current) == FloorType.Hole)),
          element = element &&
              ((super.model.getElement(current) == this) ||
                  (super.model.getElement(current) is Empty))
        });
    return floor && element;
  }

  /// Move this in dir
  ///
  /// After moving this, the method checks whether this is "hovering" completely
  /// over a [FloorType.Hole], if yes, this "falls" into the [FloorType.Hole],
  /// turning it to [FloorType.Ground]
  void _moveElement(List<int> dir) {
    position.forEach((pos) => pos = _movePart(pos, dir));
    // update field info
    position
        .forEach((pos) => super.model.elements[pos[_row]][pos[_col]] = this);
    if (!(_hasGround())) {
      position.forEach((pos) => _toGround(pos));
    }
  }

  /// move part in dir
  ///
  /// returns the new part
  List<int> _movePart(List<int> part, List<int> dir) {
    // turn old field to empty
    super.model.elements[part[_row]][part[_col]] = super.model.empty;
    // move coordinates
    part[_row] += dir[_row];
    part[_col] += dir[_col];
    return part;
  }

  /// check whether any [FloorType] under this is [FloorType.Ground]
  ///
  /// returns true if yes
  bool _hasGround() {
    // - hasGround starts with the neutral element of the || operation
    // - for each pos it is checked wheether this had Ground - stored in hasGround
    // - hasGround || 'bool' - ensures that we dont forget a true evaluation
    var hasGround = false;
    position.forEach((pos) => hasGround =
        (hasGround || (super.model.getFloor(pos) == FloorType.Ground)));
    return hasGround;
  }

  /// turn the [FloorType] underneath this to [Ground]
  /// and remove this [Element] from the [Model]
  void _toGround(List<int> pos) {
    position.forEach((pos) => {
          super.model.floor[pos[_row]][pos[_col]] = FloorType.Ground,
          super.model.elements[pos[_row]][pos[_col]] = super.model.empty
        });
  }
}

/// The [Gateway] is a special [Element] that has one solid part (joint)
/// and up to four parts surrounding it (min = 1). The Player can
/// rotate the parts around the joint if there is nothing blocking the
/// rotation.
/// The [Gateway]'s surrounding [FloorType]'s must be [FloorType.Ground] or
/// [FloorType.Wall] (though Wall reduces movement possibilities)
class Gateway extends Element {
  // ---- keys for simpler access to the maps ----

  /// north
  static final N = 'nord';

  /// northEast
  static final NE = 'nordEast';

  /// east
  static final E = 'east';

  /// southEast
  static final SE = 'southEast';

  /// south
  static final S = 'south';

  /// southWest
  static final SW = 'southWest';

  /// west
  static final W = 'west';

  /// northWest
  static final NW = 'nordWest';

  // ---- Attributes ----

  /// Map to remember what parts this has
  /// key = N, E, S, W
  /// value = true if there is part
  final _parts = {N: false, E: false, S: false, W: false};

  /// possible pos of each part of this and where it might rotate to
  Map<String, List<int>> _partPos;

  /// pos where the player needs to be on in order to interact with this
  /// and pos where the parts have to "go through" in order to rotate
  Map<String, List<int>> _cornerPos;

  /// joint of the [Gateway] where it's parts are rotating around
  final _joint = List<int>(2);

  // ---- Constructor ----

  Gateway._fromJson(Map<String, dynamic> json, Model model) {
    // e.g {"id": 2, "type": "Gateway", "joint": [3,5], "parts" : ["nord", "south", "west"]}],

    super.model = model;
    // fill joint
    _joint[_row] = json['joint'][_row] as int;
    _joint[_col] = json['joint'][_col] as int;
    // put in correct values
    json['parts'].forEach((ele) => _parts.update(ele, (v) => true));

    // create _partPos
    _partPos = Map<String, List<int>>.unmodifiable({
      N: List<int>.unmodifiable([_joint[_row] - 1, _joint[_col]]),
      E: List<int>.unmodifiable([_joint[_row], _joint[_col] + 1]),
      S: List<int>.unmodifiable([_joint[_row] + 1, _joint[_col]]),
      W: List<int>.unmodifiable([_joint[_row], _joint[_col] - 1])
    });

    // create _cornerPos
    _cornerPos = Map<String, List<int>>.unmodifiable({
      NE: List<int>.unmodifiable([_joint[_row] - 1, _joint[_col] + 1]),
      SE: List<int>.unmodifiable([_joint[_row] + 1, _joint[_col] + 1]),
      SW: List<int>.unmodifiable([_joint[_row] + 1, _joint[_col] - 1]),
      NW: List<int>.unmodifiable([_joint[_row] - 1, _joint[_col] - 1])
    });
  }

  @override
  String runtimeTypeToString() {
    return 'Gateway';
  }

  @override
  List<int> interact(List<int> dir) {
    // check it the player is standing in a corner, only then his move is valid
    if (!_validPos()) {
      // nothing happens
      return super.model.playerPos;
    }
    final clockwise = _clockwise(dir);
    if (_rotateable(clockwise)) {
      _rotate(clockwise);
      // move player in dir
      return _movePlayer(dir);
    } else {
      // nothing happens
      return super.model.playerPos;
    }
  }

  /// Method to lookUp this joint position
  bool isJoint(List<int> pos) {
    return pos[_row] == _joint[_row] && pos[_col] == _joint[_col];
  }

// ---- helper methods ----

  /// check if the player is standing in a valid pos, in order to
  /// interact with this
  ///
  /// return true is the player is in a corner pos
  bool _validPos() {
    // initialize return value with neutral element for || operation
    var valid = false;
    _cornerPos.values.forEach((pos) => valid = valid ||
        (super.model.playerPos[_row] == pos[_row] &&
            super.model.playerPos[_col] == pos[_col]));
    return valid;
  }

  /// determin whether its a clockwise or counterclockwise rotatin
  /// based on dir and playerPos
  ///
  /// returns true if clockwise
  bool _clockwise(List<int> dir) {
    // based on the dir the player wants to go and his pos we can determin
    // the rotations dir
    // e.g. if he wants to go south/down there are only 2 possible places he can stand on
    // those being northEast or northWest, now we only need to know if hes standing in either
    // of those and then we know the dir - in our implementation we are checking the northEast
    // field, if hes standing there its a clockwise rotation
    return ((dir == right) &&
            (super.model.playerPos[_row] == _cornerPos[NW][_row]) &&
            (super.model.playerPos[_col] == _cornerPos[NW][_col])) ||
        ((dir == down) &&
            (super.model.playerPos[_row] == _cornerPos[NE][_row]) &&
            (super.model.playerPos[_col] == _cornerPos[NE][_col])) ||
        ((dir == left) &&
            (super.model.playerPos[_row] == _cornerPos[SE][_row]) &&
            (super.model.playerPos[_col] == _cornerPos[SE][_col])) ||
        ((dir == up) &&
            (super.model.playerPos[_row] == _cornerPos[SW][_row]) &&
            (super.model.playerPos[_col] == _cornerPos[SW][_col]));
  }

  /// determin whether this is rotateable in either clockwise (true)
  /// or counter clockwise (false) direction
  ///
  /// returns true if rotateable
  bool _rotateable(bool clockwise) {
    // initialize bool with neutral value of && operation
    var rotateable = true;
    // check for each pos not only the new pos but the field inbetween
    if (clockwise) {
      rotateable = rotateable &&
          _rotateablePart(_parts[N], _cornerPos[NE], _partPos[E]) &&
          _rotateablePart(_parts[E], _cornerPos[SE], _partPos[S]) &&
          _rotateablePart(_parts[S], _cornerPos[SW], _partPos[W]) &&
          _rotateablePart(_parts[W], _cornerPos[NW], _partPos[N]);
    } else {
      rotateable = rotateable &&
          _rotateablePart(_parts[N], _cornerPos[NW], _partPos[W]) &&
          _rotateablePart(_parts[W], _cornerPos[SW], _partPos[S]) &&
          _rotateablePart(_parts[S], _cornerPos[SE], _partPos[E]) &&
          _rotateablePart(_parts[E], _cornerPos[NE], _partPos[N]);
    }
    return rotateable;
  }

  /// determin whether a part of this is moveable
  /// in order to determin that, we need to know the pos it is going to next
  /// and the corner it has to pass in order the reach next
  ///
  /// returns true if the part is moveable
  bool _rotateablePart(bool part, List<int> corner, List<int> next) {
    // part is true if there is a part
    // if there is no part -> ture
    // if there is one -> check if it can be moved
    // A = wether there is part // B = whether the part can be moved
    // !A || B == !A || (A && B)
    return !part ||
        (super.model.getFloor(corner) != FloorType.Wall &&
                model.getElement(corner) is Empty) &&
            (super.model.getFloor(next) != FloorType.Wall &&
                (super.model.getElement(next) is Empty ||
                    super.model.getElement(next) == this));
  }

  /// rotate this in either clockwise or counterclockwise direction based on
  /// [clockwise]
  /// also updates the model accordingly
  void _rotate(bool clockwise) {
    final temp = _rotatePart(N);
    if (clockwise) {
      _parts[N] = _rotatePart(W);
      _parts[W] = _rotatePart(S);
      _parts[S] = _rotatePart(E);
      _parts[E] = temp;
    } else {
      _parts[N] = _rotatePart(E);
      _parts[E] = _rotatePart(S);
      _parts[S] = _rotatePart(W);
      _parts[W] = temp;
    }
    _partPos.forEach((part, pos) => {
          if (_parts[part]) {super.model.elements[pos[_row]][pos[_col]] = this}
        });
  }

  /// rotates this part
  bool _rotatePart(String part) {
    // if this part exists
    if (_parts[part]) {
      // remove reference in model
      super.model.elements[_partPos[part][_row]][_partPos[part][_col]] =
          super.model.empty;
    }
    return _parts[part];
  }

  /// move player in dir
  /// if, through the rotation, the pos the player wants to go it blocked
  /// by this, the player is moved to two spaces in dir instead
  ///
  /// returns the new playerPos
  List<int> _movePlayer(List<int> dir) {
    // better readability
    var pos = super.model.playerPos;
    // if the pos the player wants to move is this, move the player two spaces
    // e.g. this happens if the player is standing northeast and there is a part
    // in north and east
    if (super
            .model
            .getElement([pos[_row] + dir[_row], pos[_col] + dir[_col]]) ==
        this) {
      // move player 2 spaces
      return [pos[_row] + (2 * dir[_row]), pos[_col] + (2 * dir[_col])];
    } else {
      // move player in dir
      return [pos[_row] + dir[_row], pos[_col] + dir[_col]];
    }
  }
}

/// The [Teleport] has two positions, if the player steps in either of those,
/// he may be teleported to the other. However, this only works if the player
/// has access to one free space on the other pos. this means a pos that has
/// [FloorType.Ground] and [Element] [Empty]
/// This mustn't be placed near a [Gateway]
class Teleport extends Element {
  /// one teleport pos
  final _port_1 = List<int>(2);

  /// other teleport pos
  final _port_2 = List<int>(2);

  /// Creates a new [Teleport] out of json, model
  Teleport._fromJson(Map<String, dynamic> json, Model model) {
    // e.g. {"id": 1, "type": "Teleport", "port_1": [1, 3], "port_2": [2, 6]}
    super.model = model;
    _port_1[_row] = json['port_1'][_row] as int;
    _port_1[_col] = json['port_1'][_col] as int;
    _port_2[_row] = json['port_2'][_row] as int;
    _port_2[_col] = json['port_2'][_col] as int;
  }

  @override
  List<int> interact(List<int> dir) {
    // interacting with is this is possible, as long as
    // the player has another field to go to

    // check port the player wants to use

    // if player wants to acces port_1, port to port_2
    if ((super.model.playerPos[_row] + dir[_row]) == _port_1[_row] &&
        (super.model.playerPos[_col] + dir[_col]) == _port_1[_col]) {
      return _port_2;
    } else {
      // else port_1
      return _port_1;
    }
  }

  @override
  String runtimeTypeToString() {
    return 'Teleport';
  }

}

/// The [Empty] class is used as an indicator, that a field ist empty
/// and thus the [Model] or other [Element]s can interact with it.
class Empty extends Element {
  /// Creates a new Empty instance out of model
  ///
  /// no _fromJson needed, since this Element holds no additional Attributes
  Empty(Model model) {
    super.model = model;
  }

  @override
  String runtimeTypeToString() {
    return 'Empty';
  }

  @override
  List<int> interact(List<int> dir) {
    // always return the own positionon the field
    return [
      super.model.playerPos[_row] + dir[_row],
      super.model.playerPos[_col] + dir[_col]
    ];
  }
}

/// This is the [Goal] of the Game. The level is considered cleared, once
/// the playerPos reaches this
class Goal extends Element {
  /// Creates new Goal instance out of model
  ///
  /// no _fromJson needed since this Element holds no additional Attributes
  Goal(Model model) {
    super.model = model;
  }

  @override
  String runtimeTypeToString() {
    return 'Goal';
  }

  @override
  List<int> interact(List<int> dir) {
    // the level is cleared now
    super.model.inGoal = true;
    // interact with this is always possible
    return [
      super.model.playerPos[_row] + dir[_row],
      super.model.playerPos[_col] + dir[_col]
    ];
  }
}

/// These are the four possible types of the floor
/// The logic behind these types is implemented in
/// other classes
/// in general:
/// - [FloorType.Ground] the playerPos and [Block] can go here
/// - [FloorType.Hole] the playerPos and [Block] can go here, if
///   the [Block] has only [FloorType.Hole] underneath him, he "falls"
///   int to [FloorType.Hole] and turns it into [FloorType.Ground]
/// - [FloorType.Wall] level border, nothing can go here
/// - [FloorType.OoB] a field outside the level that should not be visible
///   for cleaner visualization
enum FloorType {
  /// the Player (playerPos) and [Block] can go here
  Ground,

  /// the Player (playerPos) and [Block] can go here. If the
  /// [Block] has only [FloorType.Hole] underneath him, he "falls"
  /// into the [FloorType.Hole] and turns it into [FloorType.Ground]
  Hole,

  /// level border, nothing can go here
  Wall,

  /// a field outside the level that should not be visible
  /// for cleaner visualization
  OoB
}

/// a toString Method for better access to runtype
String ftToString(FloorType t) {
  switch (t) {
    case FloorType.Ground:
      return 'Ground';
      break;
    case FloorType.Hole:
      return 'Hole';
      break;
    case FloorType.Wall:
      return 'Wall';
      break;
    case FloorType.OoB:
      return 'OoB';
      break;
    default:
      Error();
      return '';
  }
}

/// helper to get FloorType from json
FloorType ftFromString(String s) {
  switch (s) {
    case 'Ground':
      return FloorType.Ground;
      break;
    case 'Hole':
      return FloorType.Hole;
      break;
    case 'Wall':
      return FloorType.Wall;
      break;
    case 'OoB':
      return FloorType.OoB;
      break;
    default:
      Error();
      return null;
  }
}
