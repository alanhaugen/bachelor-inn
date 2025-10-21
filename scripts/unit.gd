class_name unit extends Node

enum Speciality
{
	Scout,
	Support,
	Fighter
}

# Here are the properties of a unit
# finne ut av design, i design dokuemtnene
# prosjeketbeskrivelsen, er viktig og ganske tom.
# GDD mangler informasjon som vi må bestemme
# Project statement. Må ha!
# Hva er spillet vårt?
# Lite område hvor du sloss mot fiender
# Hva er resten av spillet?
# Områdene er delt opp i levels
# Så for meg
# Pokemon overworld
# Er det mer et JRPG?
# Akkuratt nå, litt vague hva som er gameplay.
# Golden sun?
# Et kart, går fra et sted til et annet
# Overworld map, går fra hit til hit
# Define biomes
# Slutt på kamp dialog
# Vi er en God like being
# Spiser de negative følelsene, be vil bytte side!
# Enheter ved for lav sanity, insanity, blir fiender
# Naturlig går ned, går ikke ned alt hver bane
# Enemies, har de sanity attacks?
# Noen enemies gjør mer sanity skade enn andre
# Enheter kan ha special skill, slik som heal sanity (therapy) men det skader enhetens egen sanity
# Å få spilleren til å bry seg blir vanskelig, har med historien og player choices
# Spilleren blir aldri direkte referert til
# Spilleren bør velge selv, og føle at de har gjort egne valg
# En karakter burde ha valg, slik at spilleren kan gjøre valg
# En visuell effekt, eller gameplay effect når noen begynner å bli insane?
# En treshold med god sanity, de får perks i gameplay men vil også velge vei i historien
# Det blir vanskeligere å være snill
# Gameplay er ikke spennende om historien og gameplayet er ikke smurt sammen, og hvis de ikke påvirker hverandre
# 100 % transformation, krever en animasjon
# Story. Hvis karakterer kan permament dø, da kan de ikke interaktere med historien lenger
# Ingen karakterer er irreplacable.
# Men noen historier vil ikke... fungere uten alle karakterene
# Replacable characters etc. må disktureres om det er mulig å oppnå neste møte
# Spillet handler om en gruppe av folk, ikke alle kommer tilbake per mission
# Spilleren blir belønnet via å beskytte de enhetene de liker ved at de overlever missions
# Forced iron man mode (ikke saves)
# Likeable characters blir skrevet, story choices vil handle om gruppen av karaterer
# Da er scope tatt tilbake litt
# Hvis vi begynner å crunche i dag (så blir alt bra)
# Blir skikkelig kult om vi får det til
# Etter dette semesteret, så har vi mer crunch
# La oss ha en evaluering etter semesteret
# Dette er noe vi ønsker å lage 
# Når du velger kart, 
# Lag dialogsystem
# Lag scene transitions
# Lag neste level system
# Hvordan lage et spill hvor du mister enheter der spilleren fortsetter å spille?
# Hvordan kan vi unngå at spillere gjrø save-load hele tiden?
# How can we make a game around loss and the consequences of loss? How to keep players playing in the face of loss?
# Spillet må designes rundt konsekvenser.
# Bør gå inn i psykologi og mentaliteten til en spiller. Hvordan få spilleren til å føle med karakterene?
# Lobotomy kaisen blir nevnt, hvorfor ser man på det?
# Karakterene er det spilleren gjør ut av karakterene.
# Dialogue jams, som setter deres personlighet
# Viser et spill der karakterer personligheter, personlighetsattributer, og det vil bestemmer hva de sier
# Tre classes. Drep alle fiender, men blir litt enkelt, magikerne var tøffe, de har magi som kan kastes på objekter
# Skill som magiker som gjør at man blir ekstra god på ...
# Karakterene kan dø, de har ikke mer enn 10 liv
# Alternative win conditions:
# Map size? 32x40
# En player løfter guden
# Guden/objektet snakker til dem
# Objektet kommuniserer intuitivt
# Er det en hub? Alltid har med alle
# men om alle mistes, eller en mister for mange?
# Drafte nye. Droppe units? Geir Jonasdatter må dermed droppes.
# En gruppe folk. Må testes!
# Animere kostymer. Dele karakterene i små biter
# Når du lager en karakter, gjøre det lett å bygge på karatkerene
# Base karakterer i de første prototypene, to per archetype
# Karakterene kommer til å ta lengst tid, bakgrunnene kan gå fort å tegne
# En turned karakter vil være spesielt sterke
# Hva slags typer monstre skal vi ha?
# Temaet for spillet er: Følelser, å gi opp, apati, grådighet.
# 7 Deadly sins
# Spirits som spiser følelsene
# Mennesker som har blirr endret, eller et konsept som påvirker folk
# Alt handler om følelser, er naturen påvirket?
# Korrupsjon seeps out
# Starter med mennesker men også andre ting
# Monstrene bør henge med storyline
# Tenticle, grådighet
# Engler i spillet?
# Distorted, og det ukjente er skummelt
# Det er skummelt når noe forandrer seg og blir korruptert eller mutert
# Project description
# Må få færre dokumenter
# Jason snakket i går om spill beskrivelse
# What is our game?
# Game mechanics? Story?
# Hva er målet til karakterene? Redde verden
# Turn-based tactical RPG
# Three pillars: Story about Loss, Character Customizability, Choice and Consequences (affecting human-values)
# Arbeidsmetodikk
# Work methodology
# We are making a game
# Using Godot, BlockBench, etc.
# Setting and theme
# Cosmic horror: Følelser, forskjellige skapninger, sanity, cosmic bliss, det ukjente og kjente
# hunmanity, survival, connection, cromraderie, belonging, fear
# Fantasy, dark fantasy, good vs. evil
# Victorian age? Srkiv i Art bible
# Tech og klær kan være mer fleksibel i en fantasiverden
# Sverd gir ikke mening, spyd er mer vanlig
# Spyd, buer, jå
# Pistol
# Muscut, bajonett
# Poor-mans weapons
# Katana-man
# Våpenoversikt
# Bernt Ribulus bruker enten en rake eller katana
# Unlocker mulighet til å velge våpen de har level til å bruke
# Kister med våpen
# Weapon type: Tools etc.
# Fight transition should be skippable
# Fight sequence burde dukke opp bare på noen steder (?)
# Visuell stil er en selling point
# Project management tools og schedule documents
# Neste uke kommer de til å snakke om neste oblig
# Pause frem til 15:00
# 

# TODO for neste økt doing:
# Combat # Map size 32x40
# Story map
# Les litt i boken om prosjektbeskrivelse
# Lag en våpenoversikt (spear, etc.)
# Lag en tile oversikt (path, ground, tree, treasure chest, building, mountain, mist)
# Skriv ned art style i art bible
# Sanity system
# Fog/Mist tiles
# Path tiles
# Levels
# Save/Load system (load json)
# Dialog system
# Level/Map system
# Level-up system
# Skill system
# UI inspect
# Main menu
# Splash screen

@export var isPlayable :bool = true; ## Friend or foe
@export var unitName :String = "Bernard Grunderburger"; ## Unit name
@export var speciality :Speciality = Speciality.Fighter; ## Unit speciality

@export var health :int       = 4; ## Unit health
@export var range :int        = 4; ## Movement range
@export var mind :int         = 4; ## Mind reduces sanity loss from combat or other events
@export var defense :int      = 4; ## Lowers damage of weapon attacks
@export var resistence :int   = 4; ## Lowers damage of magic attacks
@export var luck  :int        = 4; ## Affects many other skills
@export var intimidation :int = 4; ## How the unit affects sanity in battle.
@export var skill :int        = 4; ## Chance to hit critical.
@export var strength :int     = 4; ## Damage with weapons
@export var magic :int        = 4; ## Damage with magic
@export var speed :int        = 4; ## Speed is chance to Avoid = (Speed x 3 + Luck) / 2
@export var weapon :Weapon    = null; ## Weapon held by unit

## SKILLS

## SKILL TREE

func _ready() -> void:
	print(unitName);

# Hit = [(Skill x 3 + Luck) / 2] + Weapon Hit Rate
# Crit = (Skill / 2) + Weapon's Critical

var units: = {
	"Withburn, the Cleric": 
	{
		"name": "Withburn",
		"speciality": "Magican",
		"unit_type": "Playble",
		"texture referance": "res://art/WithburnSpriteSheet",
		"stats": 
			{
				"hp": 15, 
				"max_hp": 15,
				"strenght": 5, 
				"magic": 10,
				"skill": 10, 
				"speed": 5,
				"defence": 8, 
				"resistance": 8,
				"movement": 5, 
				"luck": 5
			},
		"level_up_stats":
			{
				"max_hp": 2,
				"strenght": 1, 
				"magic": 3,
				"skill": 1, 
				"speed": 1,
				"defence": 1, 
				"resistance": 2,
				"movement": 0, 
				"luck": 1
			},
			
		"weapon": "Staff of the Generic",
		"level": 1,
		"experience": 0
	},
	"Fen, the Warrior": 
	{
		"name": "Fen",
		"speciality": "Fighter",
		"unit_type": "Playble",
		"texture referance": "res://art/FenSpriteSheet",
		"stats": 
			{
				"hp": 20, 
				"max_hp": 20,
				"strenght": 15, 
				"magic": 3,
				"skill": 10, 
				"speed": 7,
				"defence": 12, 
				"resistance": 4,
				"movement": 6, 
				"luck": 4
			},
		"level_up_stats":
			{
				"max_hp": 2,
				"strenght": 2, 
				"magic": 1,
				"skill": 1, 
				"speed": 1,
				"defence": 2, 
				"resistance": 1,
				"movement": 0, 
				"luck": 1
			},
			
		"weapon": "Sword of the Generic",
		"level": 1,
		"experience": 0
	},
	"bandit": 
	{
		"name": "bandi",
		"speciality": "Fighter",
		"unit_type": "Enemy",
		"texture referance": "res://art/BanditSpriteSheet",
		"stats": 
			{
				"hp": 10, "max_hp": 10,
				"strenght": 8, "magic": 1,
				"skill": 4, "speed": 4,
				"defence": 6, "resistance": 6,
				"movement": 5, "luck": 2
			},
		"level_up_stats":
			{
				"max_hp": 2,
				"strenght": 1, "magic": 3,
				"skill": 1, "speed": 1,
				"defence": 1, "resistance": 2,
				"movement": 0, "luck": 1
			},
			
		"weapon": "Club of the Generic",
		"level": 1,
		"experience": 0
	}
}

func attack() -> void:
	pass;

func move() -> void:
	pass;
