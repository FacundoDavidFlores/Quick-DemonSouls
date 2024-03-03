extends CharacterBody3D
class_name Character_Script
#-------------------------------------------------------------------------------
enum PLAYER_STATE{IDLE, ATTACK}
enum COLLISSION_STATE{GROUND, AIR}
enum JUMP_STATE{LIGHT_JUMP, HEAVY_JUMP, FALL, TERMINAL_VELOCITY}
#-------------------------------------------------------------------------------
@onready var model: Node3D = $"3DGodotRobot"
@export var animation_tree: AnimationTree
@export var collider: CollisionShape3D
#-------------------------------------------------------------------------------
func Kicked():
	print("Kicked")
#-------------------------------------------------------------------------------
