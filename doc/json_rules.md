# Rules for Kwirk Escape 'level' JSON Data

## *when adding features to Kwirk Escape update this accordingly*

## when adding a level:
- one must also increment the `numberLevels` (in: Team-04-E/lib/kwirk_escape.dart) counter according to the number of level added
- the file's name has to be like this: `Level_X.json` -> 'X' being the next number of the number used by the latest level

## creating a level:
The File requires:
- a `FloorType`-Attribute --- a 2-dimensional-Array of FloorTypes. This Array represents the position of each `FloorType` These are the possible types: `Wall` `OoB` `Ground` `Hole` --- saved as Strings <br> e.g. `"FloorType": [["Wall", "Wall" .... "Wall"],[...],...]` 

-  an `Element`-Attribute --- an Array of other json-Elements. The other json-Elements represent an `Element` of Kwirk Escape each. Rules for these types can be found further below 

- an `Elements`-Attribute --- a 2-dimensional-Array of numbers. This Array represents the position of each `Element` in a Level using the `Element`'s ID (only in json) -> basically a mapper

- a `Player`-Attribute --- an Array of two numbers. The first representing the player's row-position, the secend his col-position <br> e.g. `"Player": [2, 7]`

in any order

## the `Element`-types:
- in General: each `Element` needs an `id` and `type`

- `Empty`: should always look like this `{"id": 0, "type": "Empty"}`

- `Goal`: should always look like this `{"id": 1, "type": "Goal"}`

*`Empty` and `Goal` are rather special `Element`-types. They don't need any more Attributes and thus should be used like shown above. There should always be only one `Empty`-Element, since it's behavior is not based on it's position and thus it can be reused*
- `Block`: `{"id": id, "type": "Block", "position": [[x1, y1], [x2, y2]]}` this is structure of a `Block` --- the position Attribute can be as long as you like. x and y are numbers representing the `Block`'s position, id is the next possible id number

- `Gateway`: `{"id": id, "type": "Gateway", "joint": [x, y], "parts": ["north", "south"]}` this is the `Gateway`'s structre. joint represents the center point of the `Gateway`, where the parts are rotating around. the `parts`-list, is a list of one to four Strings defining the `Gateway`'s part's  starting position. The allowed types are: `nord`, `east`, `south` and `west` --- in any order. id is the next possible id number

Since a Level has to always have a `Goal` and `Empty`Elements, there is no reason to alter their ID's, though possible

Each and every `Element` has to have
-  an unique `id` --- to generate the `Models`'s `Element`-List using the `Elements`-Attribute from above
- a `type`-field, consisting of its type

in order to be generateable by the `Model`'s constructors <br>
**Each additional attribute is defined by the specific `Element`** <br>
for further examples please look into the alreay existing level under `Team-04-E/web/level`

TimeStamp: 2020.05.27 
Author: Nicklas Hummelsheim