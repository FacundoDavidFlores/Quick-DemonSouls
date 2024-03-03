extends Node3D
@export var pathFollow3D: Path3D
@export var enemy: Array[Enemy_Script]
@export var targetPosition: Array[Marker3D]
#-------------------------------------------------------------------------------
func Start():
	for _e in enemy:
		for _t in targetPosition:
			_e.targetPosition.push_back(_t)
#-------------------------------------------------------------------------------
