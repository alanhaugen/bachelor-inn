extends OmniLight3D

var timer : float = 0;
var n : float = 0.0;
var flame : float;

func _process(deltatime:float) -> void :

	if timer <= 0:
		#Kjør kode for å oppdatere lyset;
		timer = 0.2; #Hvor ofte lyset skal oppdatere seg
		n += 1*0.2
		flame = 1 + sin(n) * cos(n*6.5) / 1.5
		light_energy = flame;
	timer -= deltatime; 
