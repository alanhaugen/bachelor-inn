extends Node

const NAMES: Array[String] = [
	"Xathog-Ruun",
	"Ylthuun",
	"Thozra'el",
	"Khar'Neth",
	"Ulmaggoth",
	"Sleeper",
	"The Thing",
	"He Who Watches",
	"The Drowned",
	"Crawling Silence",
	"Alien",
	"Zhae'kul-ith",
	"Qor'thaal",
	"Nyss-Vek",
	"Hrr'kath",
	"Vool-Xir",
	"Borrowed Faces",
	"The Unfinished",
	"Echo",
	"Sec'Mat",
	"Unfinished projects",
	"d'ave",
	"mar'k",
	"Cringe Memory",
]

static func pick_random() -> String:
	return NAMES[randi() % NAMES.size()]
