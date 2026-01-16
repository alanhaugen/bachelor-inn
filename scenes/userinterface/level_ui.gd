extends Control


@onready var stat_pop_up : StatPopUp = %GUI_POPUP;
@onready var side_bar : SideBar = %GUI_POPUP2;
@onready var player_healthbar : HealthBar = %HealthBar;
@onready var enemy_healthbar : HealthBar = %HealthBar2;
@onready var move_pop_up : Control = %MovePopup;
@onready var skill_ribbon : Control = %Ribbon;
@onready var skill_selection : SkillChoose = %SkillChoose;
@onready var turn_transition : Control = %TurnTransition;
@onready var level_transition : Control = %LevelTransition;


func hide_all() -> void :
	stat_pop_up.hide();
	side_bar.hide();
	player_healthbar.hide();
	enemy_healthbar.hide();
	move_pop_up.hide();
	skill_ribbon.hide();
	skill_selection.hide();
	turn_transition.get_canvas_layer_node().hide();
	level_transition.hide();
