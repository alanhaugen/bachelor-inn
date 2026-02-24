extends Resource
class_name EnemyDefinitions

@export var UID: String  ## The unique id of the spawn point in the Occupancy map, hint: "01_Enemy", "04_EnemyBird", "05_EnemyGhost", "06_EnemyMonster":
@export var scene: PackedScene ## the Visual scene for the monster that should be instantiated
@export var base_data: CharacterData 
@export var base_state: CharacterState 
