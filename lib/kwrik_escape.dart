library kwirk_escape;

import 'dart:html';
import 'dart:convert';

part 'src/model.dart';
part 'src/view.dart';
part 'src/controller.dart';

// indices for accessing dir information
// access [_row] first, then [_col]
const _row = 0; // y
const _col = 1; // x

/// Possible directions for the [Model] to move
/// ONLY USE THESE TO INDICATE DIRECTION!
///    r   c -> [dir]
///   -1,  0 -> [up]
const up = [-1, 0];

/// Possible directions for the [Model] to move
/// ONLY USE THESE TO INDICATE DIRECTION!
///    r   c -> [dir]
///    1,  0 -> [down]
const down = [1, 0];

/// Possible directions for the [Model] to move
/// ONLY USE THESE TO INDICATE DIRECTION!
///    r   c -> [dir]
///    0, -1 -> [left]
const left = [0, -1];

/// Possible directions for the [Model] to move
/// ONLY USE THESE TO INDICATE DIRECTION!
///    r   c -> [dir]
///    0,  1 -> [right]
const right = [0, 1];

/// number of levels
const numberLevels = 11;

const kwirk_storage = 'kwirk_escape';

/// colour scheme for locked level buttons
const lockedLevel = 'grey';

/// URL to background image in front page
const backGroundURL = 'img/kwirk.png';