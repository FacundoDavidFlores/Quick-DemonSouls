extends CharacterBody3D
class_name Character_Script
#region VARIABLES
enum PLAYER_STATE{IDLE, ATTACK, DODGE, ITEM, BLOCKING}
enum COLLISSION_STATE{GROUND, AIR}
enum GROUND_STATE{STANDING_STILL, MOVING}
enum JUMP_STATE{LIGHT_JUMP, HEAVY_JUMP, FALL, TERMINAL_VELOCITY}
#-------------------------------------------------------------------------------
@onready var model: Node3D = $"model"
#@export var model: Node3D
@export var gameSystem: GameSystem_Script
@export var animation_tree: AnimationTree
@export var collider: CollisionShape3D
var deltaTimeScale: float = 1
const animName_Copy: StringName = "_copy"
#endregion
#-------------------------------------------------------------------------------
#region MONOVEHAVIOUR
func _physics_process(_delta:float) -> void:
	deltaTimeScale = _delta * 60
#endregion
#-------------------------------------------------------------------------------
#region CHARACTER FUNCTIONS
func Player_Attack():
	print("Kicked")
#endregion
#-------------------------------------------------------------------------------
#region NEW ANIMATION FUNCTIONS
func AnimationTree_BlendSpace1D_Set(_s:StringName, _f:float) -> void:
	animation_tree["parameters/"+_s+"_BlendSpace1D/blend_position"] = _f
#-------------------------------------------------------------------------------
func AnimationTree_BlendSpace1D_Get(_s:StringName) -> float:
	return animation_tree["parameters/"+_s+"_BlendSpace1D/blend_position"]
#-------------------------------------------------------------------------------
func AnimationTree_Blend2_Set(_s:StringName, _f:float) -> void:
	animation_tree["parameters/"+_s+"_Blend2/blend_amount"] = _f
#-------------------------------------------------------------------------------
func AnimationTree_Blend2_Get(_s:StringName) -> float:
	return animation_tree["parameters/"+_s+"_Blend2/blend_amount"]
#-------------------------------------------------------------------------------
func AnimationTree_Blend2_Weight(_s:StringName, _f:float, _weight:float) -> void:
	var _value: float = AnimationTree_Blend2_Get(_s)
	AnimationTree_Blend2_Set(_s, lerp(_value, _f, _weight))
#-------------------------------------------------------------------------------
func AnimationTree_OneShot_Set(_s:StringName, _b:bool) -> void:
	var _path: String = "parameters/"+_s+"_OneShot/request"
	if(_b):
		animation_tree[_path] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	else:
		animation_tree[_path] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT
#-------------------------------------------------------------------------------
func AnimationTree_OneShot_Get(_s:StringName) -> bool:
	return animation_tree["parameters/"+_s+"_OneShot/active"]
#-------------------------------------------------------------------------------
func AnimationTree_Transition_Set(_s:String, _anim:StringName) -> void:
	animation_tree["parameters/"+_s+"_Transition/transition_request"] = _anim
#-------------------------------------------------------------------------------
func AnimationTree_Transition_Get(_anim:StringName) -> StringName:
	return animation_tree["parameters/"+_anim+"_Transition/current_state"]
#-------------------------------------------------------------------------------
func AnimationTree_TimeSeek(_anim:StringName, _f:float) -> void:
	animation_tree["parameters/"+_anim+"_TimeSeek/seek_request"] = _f
#-------------------------------------------------------------------------------
func AnimationTree_TimeScale(_anim:StringName, _f:float) -> void:
	animation_tree["parameters/"+_anim+"_TimeScale/scale"] = _f
#endregion
#-------------------------------------------------------------------------------
#region NEW ANIMATION FUNCTIONS 2
func PlayAnimation_WithCopy(_s:StringName, _anim:StringName) -> void:
	if(AnimationTree_Transition_Get(_s) == _anim):
		_anim+=animName_Copy
	AnimationTree_Transition_Set(_s, _anim)
#-------------------------------------------------------------------------------
func PlayAnimation_InSecond_WithCopy(_s:StringName, _anim:StringName, _f:float) -> void:
	if(AnimationTree_Transition_Get(_s) == _anim):
		_anim+=animName_Copy
	AnimationTree_TimeSeek(_anim, _f)
	AnimationTree_Transition_Set(_s, _anim)
#-------------------------------------------------------------------------------
func AnimationSpeed_WithCopy(_anim:StringName, _f:float):
	AnimationTree_TimeScale(_anim, _f)
	AnimationTree_TimeScale(_anim+animName_Copy, _f)
#-------------------------------------------------------------------------------
func IsInAnimationCopy(_s:StringName, _animName:StringName, _isCopy:bool) -> bool:
	if(_isCopy):
		_animName += animName_Copy
	return IsInAnimation(_s, _animName)
#-------------------------------------------------------------------------------
func IsInAnimation(_s:StringName, _animName:StringName) -> bool:
	if(AnimationTree_Transition_Get(_s) == _animName):
		return true
	else:
		return false
#endregion
#-------------------------------------------------------------------------------
