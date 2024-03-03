extends Character_Script
class_name Enemy_Script
#-------------------------------------------------------------------------------
enum ENEMY_STATE{PATROLLING, NAVIGATING, HURT}
#-------------------------------------------------------------------------------
#region VARIABLES
@export var myENEMY_STATE: ENEMY_STATE = ENEMY_STATE.PATROLLING
#-------------------------------------------------------------------------------
@export var label3D: Label3D
@export var timer: Timer
@export var flashDuration: float
@export var targetPosition: Array[Node3D]
var targetPositionIndex: int = 0
var speed: float = 1.5;
@export var navigationAgent: NavigationAgent3D
@export var pathFollow3D: PathFollow3D
#-------------------------------------------------------------------------------
# Player Animation
const timeScale_path: String = "parameters/TimeScale/"
const stateMachine_path: String = "parameters/StateMachine/"
var playback: AnimationNodeStateMachinePlayback
const animName_Locomotion: String = "Locomotion"
const animName_Hurt: String = "Hurt"
const animWeight: float = 0.2
var animVelocity: Vector2
#endregion
#-------------------------------------------------------------------------------
#region MONOVEHAVIOUR
func _ready():
	playback = animation_tree.get(stateMachine_path+"playback")
	timer.timeout.connect(OnReset)
	navigationAgent.velocity_computed.connect(Velocity_computed)
	#OnReset()
	AnimationTree_TimeScale(0.5)
	playback.travel(animName_Locomotion)
	if(targetPosition.size() > 0):
		navigationAgent.target_position = targetPosition[targetPositionIndex].global_position;
	await NavigateFixer()
#-------------------------------------------------------------------------------
func _physics_process(_delta:float):
	label3D.text = ENEMY_STATE.keys()[myENEMY_STATE]
	match(myENEMY_STATE):
		ENEMY_STATE.PATROLLING:
			Patrolling(_delta)
		ENEMY_STATE.NAVIGATING:
			Navigate()
		ENEMY_STATE.HURT:
			pass
#endregion
#-------------------------------------------------------------------------------
#region STATEMACHINE FUNCTIONS
func Kicked():
	super.Kicked()
	myENEMY_STATE = ENEMY_STATE.HURT
	AnimationTree_TimeScale(1.5)
	playback.travel(animName_Hurt)
	timer.start(flashDuration)
#-------------------------------------------------------------------------------
func Patrolling(_delta:float):
	if(!pathFollow3D):
		return
	AnimationTree_SetBlendPosition1(animName_Locomotion, 0.5)
	pathFollow3D.progress += speed*_delta
#-------------------------------------------------------------------------------
func NavigateFixer():
	set_physics_process(false)
	await get_tree().process_frame
	set_physics_process(true)
#-------------------------------------------------------------------------------
func Navigate():
	if(!navigationAgent.target_position):
		return
	navigationAgent.target_position = targetPosition[targetPositionIndex].global_position;
	var currentPos: Vector3 = NavigationServer3D.map_get_closest_point(get_world_3d().get_navigation_map(), global_position)
	global_position = currentPos
	var nextPos: Vector3 = navigationAgent.get_next_path_position();
	var newVelocity: Vector3 = currentPos.direction_to(nextPos) * speed;
	navigationAgent.velocity = newVelocity
	#-------------------------------------------------------------------------------
	var _distance: float = global_position.distance_to(navigationAgent.target_position)
	if(_distance < 1.0):
		targetPositionIndex+=1
		if(targetPositionIndex >= targetPosition.size()):
			targetPositionIndex = 0
		navigationAgent.target_position = targetPosition[targetPositionIndex].global_position;
	Handle_Rotation(0.1);
	AnimationTree_SetLocomotion(speed*2)
#-------------------------------------------------------------------------------
func Handle_Rotation(_weight:float):
	if(velocity != Vector3.ZERO):
		model.global_rotation.y = lerp_angle(model.global_rotation.y, atan2(velocity.x, velocity.z), _weight)
#endregion
#-------------------------------------------------------------------------------
#region ANIMATION FUNCTIONS
func AnimationTree_TimeScale(_f:float):
	animation_tree[timeScale_path+"scale"] = _f
#-------------------------------------------------------------------------------
func AnimationTree_SetLocomotion(_velocity:float) -> void:
	var _v2: Vector2 = Vector2(velocity.x, velocity.z)
	_v2 = _v2/_velocity
	animVelocity = lerp(animVelocity, _v2, animWeight)
	AnimationTree_SetBlendPosition1(animName_Locomotion, animVelocity.length())
#-------------------------------------------------------------------------------
func AnimationTree_SetBlendPosition1(_s:String, _x:float) -> void:
	animation_tree[stateMachine_path+_s+"/blend_position"] = _x
#endregion
#-------------------------------------------------------------------------------
#region CONNECT FUNCTIONS
func Velocity_computed(safe_velocity:Vector3):
	if(myENEMY_STATE == ENEMY_STATE.NAVIGATING):
		velocity = velocity.move_toward(safe_velocity, 0.25)
		move_and_slide()
#-------------------------------------------------------------------------------
func OnReset():
	myENEMY_STATE = ENEMY_STATE.NAVIGATING
	AnimationTree_TimeScale(0.5)
	playback.travel(animName_Locomotion)
#endregion
