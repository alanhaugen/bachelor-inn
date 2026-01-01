# bachelor-inn

## HANDOFF note

Tutorial text is intentionally minimal.
Add mechanics by extending the Dialogic timeline and emitting new signals from game logic.

### How levels are authored (GridMap rules)

You can make levels by editing the scenes in scenes/levels

They support Grid Floor level planes (building tiles in height)

The first level is firstLevel

You will find the order levels are loaded in scenes/ui/main_menu.tscn (see Levels in inspector)

Please edit the GridMap "Map" to change the appearance and weights of the level

Edit Units to place unit spawn points and interactables

You can change weights in scripts/combat/terrain.gd

### How units are placed

As stated above, Units GridMap in the level scenes decide where units are placed

In Dialogic, you can make characters which players get to choose.

In Dialogic, you can use a call to Event to place units

The original cast of units are made in scripts/save_game.gd

### What Dialogic can trigger (start battle, end battle, cutscene)

Check out Main and Event calls inside Dialogic

Main lets you

* load next level
* load a specific level

Event lets you

* move a unit
* can be triggered from the trigger interactable tile

### What not to touch

You should be able to build the rest of the game without touching gdscript

The game is essentally a series of events, see scripts/combat/commands

### What next

Remember to work on save/load, interim battle scene, battle sequences, story, ui, etc.
