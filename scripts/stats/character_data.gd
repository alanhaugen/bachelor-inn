extends Resource
class_name CharacterData
## CharacterData is pure storage information.
## No scene or node access should happen here.

#region enums
## This dictates level progression, skills and compatible weapons
enum Speciality
{
	Generic,
	## This class has more movement than the other classes
	## allowing them to get to objectives or outrun enemies.
	## This could for example be a horse rider in a medieval
	## setting or a ranger in a fantasy setting
	Runner,
	## Most classes usually fall in this category in games
	## like fire emblem. If we want to use the sanity mechanic
	## for our game, then these units might have extra resistance
	## from sanity damage from battles
	Militia,
	## The classic healer/utility buffer. Their abilities do not
	## necessarily have to affect battles, they could improve
	## movement or conjure terrain.
	Scholar
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

@export var health := 4
@export var strength := 4
@export var mind := 4
@export var speed := 4
@export var focus := 4 #
@export var endurance := 4 #
@export var defense := 4
@export var resistance := 4 #
@export var luck := 4
@export var mana := 4 #


func duplicate_data() -> CharacterData:
	return duplicate(true);


func save() -> Dictionary:
	return {
		"unit_name": unit_name,
		"speciality": speciality,
		"personality": personality,
		"health": health,
		"strength": strength,
		"mind": mind,
		"speed": speed,
		"focus": focus,
		"endurance": endurance,
		"defense": defense,
		"resistance": resistance,
		"luck": luck,
		"mana": mana
	}
