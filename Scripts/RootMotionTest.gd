extends CharacterBody3D
#-------------------------------------------------------------------------------
@export var animation_tree: AnimationTree
var currentRoot: Quaternion
var rootMotion: Vector3
var rootVelocity: Vector3
#-------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	currentRoot = transform.basis.get_rotation_quaternion()
	rootMotion = animation_tree.get_root_motion_position()
	rootVelocity = currentRoot.normalized() * rootMotion/_delta
#-------------------------------------------------------------------------------
func _physics_process(_delta: float) -> void:
	var _velocity: Vector3 = rootVelocity
	velocity.x = _velocity.x
	velocity.z = _velocity.z
	move_and_slide()
#-------------------------------------------------------------------------------
