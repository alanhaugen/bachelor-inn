extends Resource
class_name CampaignState
## Holds the state of the current game session.

enum GameStatus {
	MAIN_MENU,
	PLAYING,
	VICTORY,
	DEFEAT
}

enum LevelState {
	PLAYING,        ## Waiting for input
	CHOOSING_ATTACK, ## Selecting a target for an attack/skill
	ANIMATING,      ## Playing out unit actions
	TRANSITION,     ## Switching turns
	AI_TURN,         ## AI is thinking/acting
	CHOOSING_ENEMY   ## Selecting an enemy to attack AFTER moving
}

signal game_status_changed(new_status: GameStatus)
signal level_state_changed(new_state: LevelState)
signal turn_changed(is_player_turn: bool)

@export var game_status: GameStatus = GameStatus.MAIN_MENU:
	set(v):
		if game_status != v:
			game_status = v
			game_status_changed.emit(v)

@export var level_state: LevelState = LevelState.PLAYING:
	set(v):
		if level_state != v:
			level_state = v
			level_state_changed.emit(v)

@export var is_player_turn: bool = true:
	set(v):
		if is_player_turn != v:
			is_player_turn = v
			turn_changed.emit(v)

## The list of characters in the player's party
var characters: Array[Character] = []

## The index of the current level in Main.levels
@export var current_level_index: int = 0

## The name of the current level
@export var level_name: String = ""

## Battle log messages
@export var battle_log_history: Array[String] = []

func log_message(msg: String) -> void:
	battle_log_history.append(msg)
	if battle_log_history.size() > 50:
		battle_log_history.remove_at(0)
