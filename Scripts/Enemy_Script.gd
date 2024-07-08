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
const stateMachine_path: StringName = "parameters/StateMachine/"
const timeScale_path: StringName = "parameters/TimeScale/"
var playback: AnimationNodeStateMachinePlayback
#-------------------------------------------------------------------------------
const animName_Locomotion: StringName = "Locomotion"
const animName_Hurt: StringName = "Hurt"
#-------------------------------------------------------------------------------
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
	AnimationTree_TimeScale(1.0)
	PlayAnimation(animName_Locomotion)
	if(targetPosition.size() > 0):
		navigationAgent.target_position = targetPosition[targetPositionIndex].global_position;
	await NavigateFixer()
#-------------------------------------------------------------------------------
func _physics_process(_delta:float):
	var _playback: AnimationNodeStateMachinePlayback = animation_tree.get(stateMachine_path+animName_Hurt+"/playback")
	label3D.text = ENEMY_STATE.keys()[myENEMY_STATE] +"-"+ playback.get_current_node() +"-"+ _playback.get_current_node()
	match(myENEMY_STATE):
		ENEMY_STATE.PATROLLING:
			Patrolling(_delta)
		ENEMY_STATE.NAVIGATING:
			Navigate()
		ENEMY_STATE.HURT:
			pass
#endregion
#-------------------------------------------------------------------------------
#region CHARACTER FUNCTIONS
func Player_Attack():
	super.Player_Attack()
	myENEMY_STATE = ENEMY_STATE.HURT
	AnimationTree_TimeScale(1.5)
	Nested_Attack()
	timer.start(flashDuration)
#-------------------------------------------------------------------------------
func Nested_Attack():	#NOTA: el state_machine_type del Hurt tiene que estar en Nested
	if(playback.get_current_node() != animName_Hurt):
		PlayAnimation(animName_Hurt)
	var _playback: AnimationNodeStateMachinePlayback = animation_tree.get(stateMachine_path+animName_Hurt+"/playback")
	if(_playback.get_current_node() != animName_Hurt):
		_playback.call_deferred("travel", animName_Hurt)
	else:
		_playback.call_deferred("travel", animName_Hurt+" 2")
#-------------------------------------------------------------------------------
func Nested_Attack2():	#NOTA: No funciona
	var _path: StringName = animName_Hurt+"/"+animName_Hurt
	if(playback.get_current_node() != _path):
		PlayAnimation(_path)
	else:
		PlayAnimation(_path+" 2")
#endregion
#-------------------------------------------------------------------------------
#region STATEMACHINE FUNCTIONS
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
func PlayAnimation(_s:String):
	#playback.travel(_s)
	playback.call_deferred("travel", _s)
#-------------------------------------------------------------------------------
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
	AnimationTree_TimeScale(1.0)
	PlayAnimation(animName_Locomotion)
#endregion
#-------------------------------------------------------------------------------
