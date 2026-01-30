extends Resource
class_name CharacterData
## CharacterData is pure storage information.
## No scene or node access should happen here.

#region enums
## This dictates level progression, skills and compatible weapons
enum Speciality
{
	Generic,
	
	Runner,
	## This class has more movement than the other classes
	## allowing them to get to objectives or outrun enemies.
	## This could for example be a horse rider in a medieval
	## setting or a ranger in a fantasy setting
	Militia,
	## Most classes usually fall in this category in games
	## like fire emblem. If we want to use the sanity mechanic
	## for our game, then these units might have extra resistance
	## from sanity damage from battles
	Scholar
	## The classic healer/utility buffer. Their abilities do not
	## necessarily have to affect battles, they could improve
	## movement or conjure terrain.
}

enum Personality
{
	Normal,
	Zealot,
	Devoted,
	Young,
	Old,
	Jester,
	Therapist,
	Vindictive,
	Snob,
	Crashout,
	Grump,
	Determined,
	Silly,
	SmartAlec,
	HeroComplex,
	Vitriolic,
	Noble,
	Selfish,
	Tired,
	ExCultist,
	FactoryWorker,
	FactoryOwner
}
#endregion

#region Unit Stats
@export var unit_name := "Empty"
@export var speciality : Speciality = Speciality.Generic
@export var personality : Personality = Personality.Normal

@export var strength : int = 4
@export var mind : int = 4
@export var speed : int = 4
@export var focus : int = 4
@export var endurance : int = 4
@export var weapon_id : String = "unarmed"


func duplicate_data() -> CharacterData:
	return duplicate(true);


func save() -> Dictionary:
	return {
		"unit_name": unit_name,
		"speciality": speciality,
		"personality": personality,
		"strength": strength,
		"mind": mind,
		"speed": speed,
		"focus": focus,
		"endurance": endurance,
		"weapon_id" : weapon_id
	}
