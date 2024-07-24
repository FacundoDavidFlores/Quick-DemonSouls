extends CharacterBody3D
class_name Character_Script
#-------------------------------------------------------------------------------
#region VARIABLES
enum PLAYER_STATE{IDLE, ATTACK, DODGE, ITEM}
enum COLLISSION_STATE{GROUND, AIR}
enum JUMP_STATE{LIGHT_JUMP, HEAVY_JUMP, FALL, TERMINAL_VELOCITY}
#-------------------------------------------------------------------------------
@onready var model: Node3D = $"model"
#@export var model: Node3D
@export var animation_tree: AnimationTree
@export var collider: CollisionShape3D
#endregion
#-------------------------------------------------------------------------------
#region CHARACTER FUNCTIONS
func Player_Attack():
	print("Kicked")
#endregion
#-------------------------------------------------------------------------------
