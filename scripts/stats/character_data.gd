extends Resource
class_name CharacterData

var unit_name := "Empty"
var speciality := 0
var personality := 0

var health := 4
var strength := 4
var mind := 4
var speed := 4
var focus := 4
var endurance := 4
var defense := 4
var resistance := 4
var luck := 4
var mana := 4

var experience := 0
var level := 1
var skills: Array[Skill] = []

func duplicate_data() -> CharacterData:
	return duplicate(true)
