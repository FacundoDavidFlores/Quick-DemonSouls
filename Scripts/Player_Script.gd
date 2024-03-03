extends Character_Script
class_name Player_Script
#region VARIABLES
#-------------------------------------------------------------------------------
# State Machine
var myPLAYER_STATE: PLAYER_STATE = PLAYER_STATE.IDLE
var myCOLLISSION_STATE: COLLISSION_STATE = COLLISSION_STATE.GROUND
var myJUMP_STATE: JUMP_STATE = JUMP_STATE.FALL
#-------------------------------------------------------------------------------
# Player Nodes
@export var foot: Area3D
#-------------------------------------------------------------------------------
# Player Animation
const timeScale_path: String = "parameters/TimeScale/"
const stateMachine_path: String = "parameters/StateMachine/"
var playback: AnimationNodeStateMachinePlayback
const animName_Locomotion: String = "Locomotion"
const animName_Jump: String = "Jump"
const animName_Attack: String = "Attack1"
const animName_Floating: String = "Fall"
const animWeight: float = 0.2
var animVelocity: float
#-------------------------------------------------------------------------------
# Camera Nodes
@export var cameraHolder: Marker3D
@export var cameraPivot: Marker3D
@export var camera: Camera3D
@export_flags_3d_physics var cameraColliderLayer: int
@export_flags_3d_physics var groundColliderLayer: int
const standOffDistance: float = 0.1
const cameraWeight: float = 0.2
#-------------------------------------------------------------------------------
# Inputs
var input_dir: Vector2
var input_dir_raw: Vector2
var input_camera: Vector2
const jumpInput: String = "Input_Jump"
const runInput: String = "Input_Run"
const attackInput: String = "Input_Attack"
#-------------------------------------------------------------------------------
# Playe Variables
const jumpVelocity: float = 14
const terminalVelocity: float = -14
#-------------------------------------------------------------------------------
# Speed
const ground_Speed : float = 5.0
const lightJump_Speed : float = 5.0
const heavyJump_Speed : float = 5.0
const fall_Speed : float = 5.0
const terminalVelocity_Speed : float = 5.0
const run_Speed : float = 8.0
#-------------------------------------------------------------------------------
# Weight
const ground_Weight : float = 0.2
const lightJump_Weight : float = 0.1
const heavyJump_Weight : float = 0.1
const fall_Weight : float = 0.1
const terminalVelocity_Weight : float = 0.1
#-------------------------------------------------------------------------------
# Gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const lightJump_GravityScale : float = 3.0
const heavyJump_GravityScale : float = 6.0
const fall_GravityScale : float = 4.5
#endregion
#-------------------------------------------------------------------------------
#region MONOVEHAVIOUR
func _ready():
	playback = animation_tree.get(stateMachine_path+"playback")
	playback.travel(animName_Locomotion)
	foot.body_entered.connect(KickEvent)
	Anim_FootOff()
#-------------------------------------------------------------------------------
func _process(_delta:float) -> void:
	CameraCollision()
#-------------------------------------------------------------------------------
func _physics_process(_delta:float) -> void:
	input_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Up", "Move_Down")
	input_camera = Input.get_vector("Camera_Left", "Camera_Right", "Camera_Up", "Camera_Down")
	input_dir_raw = input_dir.normalized()
	#-------------------------------------------------------------------------------
	CameraFollow()
	CameraRotation(input_camera.x, input_camera.y, 4.5)
	#-------------------------------------------------------------------------------
	match(myPLAYER_STATE):
		PLAYER_STATE.IDLE:
			Handle_Rotation(0.2)
			#-------------------------------------------------------------------------------
			match(myCOLLISSION_STATE):
				COLLISSION_STATE.GROUND:
					Handle_Movement(ground_Speed, ground_Weight)
					move_and_slide()
					ApplyForce()
					#-------------------------------------------------------------------------------
					if(Input.is_action_just_pressed(attackInput)):
						playback.travel(animName_Attack)
						AnimationTree_TimeScale(1.5)
						myPLAYER_STATE = PLAYER_STATE.ATTACK
						return
					#-------------------------------------------------------------------------------
					if(Input.is_action_just_pressed(jumpInput)):
						velocity.y = jumpVelocity
						playback.travel(animName_Jump)
						myJUMP_STATE = JUMP_STATE.LIGHT_JUMP
						myCOLLISSION_STATE = COLLISSION_STATE.AIR
						return
					#-------------------------------------------------------------------------------
					var _result: Dictionary = GroundCollision(-0.5)
					if(_result):
						#velocity.y = 0.0
						position.y = _result["position"].y
					else:
						EnterFloating()
						myCOLLISSION_STATE = COLLISSION_STATE.AIR
						return
				COLLISSION_STATE.AIR:
					match(myJUMP_STATE):
						JUMP_STATE.LIGHT_JUMP:
							Handle_Movement(lightJump_Speed, lightJump_Weight)
							ApplyGravity(_delta, lightJump_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(Input.is_action_just_released(jumpInput)):
								myJUMP_STATE = JUMP_STATE.HEAVY_JUMP
								return
							#-------------------------------------------------------------------------------
							if(velocity.y <= 0.0):
								EnterFloating()
								return
						JUMP_STATE.HEAVY_JUMP:
							Handle_Movement(heavyJump_Speed, heavyJump_Weight)
							ApplyGravity(_delta, heavyJump_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y <= 0.0):
								EnterFloating()
								return
						JUMP_STATE.FALL:
							Handle_Movement(fall_Speed, fall_Weight)
							ApplyGravity(_delta, fall_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y < terminalVelocity):
								velocity.y = terminalVelocity
								myJUMP_STATE = JUMP_STATE.TERMINAL_VELOCITY
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								EnterGrounded()
								return
						JUMP_STATE.TERMINAL_VELOCITY:
							Handle_Movement(terminalVelocity_Speed, terminalVelocity_Weight)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y > terminalVelocity):
								myJUMP_STATE = JUMP_STATE.FALL
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								EnterGrounded()
								return
		PLAYER_STATE.ATTACK:
			Handle_Movement2(0.0, 0.0, ground_Weight/2.0)
			#-------------------------------------------------------------------------------
			match(myCOLLISSION_STATE):
				COLLISSION_STATE.GROUND:
					move_and_slide()
					#-------------------------------------------------------------------------------
					var _result: Dictionary = GroundCollision(-0.5)
					if(_result):
						#velocity.y = 0.0
						position.y = _result["position"].y
					else:
						myJUMP_STATE = JUMP_STATE.FALL
						myCOLLISSION_STATE = COLLISSION_STATE.AIR
						return
				COLLISSION_STATE.AIR:
					match(myJUMP_STATE):
						JUMP_STATE.LIGHT_JUMP:
							ApplyGravity(_delta, lightJump_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(Input.is_action_just_released(jumpInput)):
								myJUMP_STATE = JUMP_STATE.HEAVY_JUMP
								return
							#-------------------------------------------------------------------------------
							if(velocity.y <= 0.0):
								myJUMP_STATE = JUMP_STATE.FALL
								return
						JUMP_STATE.HEAVY_JUMP:
							ApplyGravity(_delta, heavyJump_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y <= 0.0):
								myJUMP_STATE = JUMP_STATE.FALL
								return
						JUMP_STATE.FALL:
							ApplyGravity(_delta, fall_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y < terminalVelocity):
								velocity.y = terminalVelocity
								myJUMP_STATE = JUMP_STATE.TERMINAL_VELOCITY
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								EnterGround2()
								return
						JUMP_STATE.TERMINAL_VELOCITY:
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y > terminalVelocity):
								myJUMP_STATE = JUMP_STATE.FALL
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								EnterGround2()
								return
#-------------------------------------------------------------------------------
func _input(event):
	if(event is InputEventMouseMotion):
		CameraRotation(event.relative.x, event.relative.y, 0.3)
#endregion
#-------------------------------------------------------------------------------
#region STATEMACHINE FUNCTIONS
func PlayerInfo() -> String:
	var _s: String = "StateMachine: "
	_s += PLAYER_STATE.keys()[myPLAYER_STATE] + " "
	_s += COLLISSION_STATE.keys()[myCOLLISSION_STATE] + " "
	_s += JUMP_STATE.keys()[myJUMP_STATE] + "\n"
	_s += "velocity: "+str(velocity)+"\n"
	_s += "Movement Input: "+str(input_dir)+"\n"
	_s += "animVelocity: "+str(animVelocity)+"\n"
	_s += str(Engine.get_frames_per_second())+"fps"
	return _s
#-------------------------------------------------------------------------------
func EnterFloating():
	playback.travel(animName_Floating)
	myJUMP_STATE = JUMP_STATE.FALL
#-------------------------------------------------------------------------------
func EnterGrounded():
	EnterGround2()
	playback.travel(animName_Locomotion)
#-------------------------------------------------------------------------------
func EnterGround2():
	velocity.y = 0.0
	myCOLLISSION_STATE = COLLISSION_STATE.GROUND
#endregion
#-------------------------------------------------------------------------------
#region PLAYER MOVEMENT
func ApplyGravity(_delta:float, _scale:float) -> void:
	velocity.y -= gravity * _scale * _delta
#-------------------------------------------------------------------------------
func Handle_Movement(_speed:float, _weight:float):
	if(input_dir != Vector2.ZERO):
		var _targetDir: Vector3
		if(Input.is_action_pressed(runInput)):
			_targetDir = cameraHolder.transform.basis.z * input_dir_raw.y
			_targetDir += cameraHolder.transform.basis.x * input_dir_raw.x
			_targetDir.y = 0.0
			_targetDir.normalized()
			Handle_Movement2(_targetDir.x * run_Speed, _targetDir.z * run_Speed, _weight)
			AnimationTree_SetLocomotion2(2.0) 
		else:
			_targetDir = cameraHolder.transform.basis.z * input_dir.y
			_targetDir += cameraHolder.transform.basis.x * input_dir.x
			_targetDir.y = 0.0
			_targetDir.normalized()
			Handle_Movement2(_targetDir.x * _speed, _targetDir.z * _speed, _weight)
			#AnimationTree_SetLocomotion(velocity.z, velocity.x, _speed)
			AnimationTree_SetLocomotion2(_targetDir.length()) 
	else:
		Handle_Movement2(0.0, 0.0, _weight)
		AnimationTree_SetLocomotion2(0.0) 
#-------------------------------------------------------------------------------
func Handle_Movement2(_x:float, _z:float, _weight:float):
	velocity.x = lerp(velocity.x, _x, _weight)
	velocity.z = lerp(velocity.z, _z, _weight)
#-------------------------------------------------------------------------------
func Handle_Rotation(_weight:float):
	if(input_dir != Vector2.ZERO):
		var _targetDir: Vector3
		_targetDir = cameraHolder.transform.basis.z * input_dir_raw.y
		_targetDir += cameraHolder.transform.basis.x * input_dir_raw.x
		_targetDir.y = 0.0
		_targetDir.normalized()
		model.global_rotation.y = lerp_angle(model.global_rotation.y, atan2(_targetDir.x, _targetDir.z), _weight)
#-------------------------------------------------------------------------------
func GroundCollision(_to:float) -> Dictionary:
	var _hitDictionary: Array[Dictionary] = []
	_hitDictionary.push_back(Ground_Raycast_Dictionary(0.0, _to, 0.0))
	var _radius: float = collider.shape.radius * 0.5
	var _dir: float = collider.rotation.y
	var _num: int = 4
	for _i in _num:
		_hitDictionary.push_back(Ground_Raycast_Dictionary(_radius*cos(_dir), _to, _radius*sin(_dir)))
		_dir += 360/float(_num)
	#-------------------------------------------------------------------------------
	for _d in _hitDictionary:
		if(!_d.is_empty()):
			return _d
	return {}
#-------------------------------------------------------------------------------
func Ground_Raycast_Dictionary(_x:float, _to:float, _z:float) -> Dictionary:
	var _query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	_query.from = to_global(Vector3(_x, collider.position.y-collider.shape.height/2.0, _z))
	_query.to = to_global(Vector3(_x, _to, _z))
	_query.collide_with_areas = false
	_query.collide_with_bodies = true
	_query.collision_mask = groundColliderLayer
	#-------------------------------------------------------------------------------
	var _hitDictionary: Dictionary = get_world_3d().direct_space_state.intersect_ray(_query)
	return _hitDictionary
#-------------------------------------------------------------------------------
#Parece que get_rest_info() solo detecto las lineas de los CollisionShapes, no me sirve.
func GroundCollision2(_offset:float, _height:float) -> Dictionary:
	var _shape_rid :RID = PhysicsServer3D.cylinder_shape_create()
	var _half_extents :Vector2 = Vector2(_height, 0.35)
	PhysicsServer3D.shape_set_data(_shape_rid, _half_extents)
	#-------------------------------------------------------------------------------
	var _query :PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	_query.shape_rid = _shape_rid
	_query.collide_with_areas = false
	_query.collide_with_bodies = true
	_query.collision_mask = groundColliderLayer
	#-------------------------------------------------------------------------------
	var _transform: Transform3D = get_global_transform()
	_transform.translated(Vector3.UP*_offset)
	_query.transform = _transform
	#-------------------------------------------------------------------------------
	var _direct_space_state :PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var _result :Dictionary = _direct_space_state.get_rest_info(_query)
	#-------------------------------------------------------------------------------
	PhysicsServer3D.free_rid(_shape_rid)
	return _result
#endregion
#-------------------------------------------------------------------------------
#region CAMERA MOVEMENT
func CameraFollow():
	cameraHolder.position = lerp(cameraHolder.position, position, cameraWeight)
#-------------------------------------------------------------------------------
func CameraRotation(_x:float, _y:float, _scale:float):
	cameraHolder.rotate_y(deg_to_rad(-_x*_scale))
	cameraPivot.rotate_x(deg_to_rad(-_y*_scale))
	cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, deg_to_rad(-70), deg_to_rad(70))
#-------------------------------------------------------------------------------
func CameraCollision():
	var _query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	var _from: Vector3 = cameraPivot.global_position
	_query.from = _from
	_query.to = cameraPivot.to_global(Vector3(0, 0, 4))
	_query.collide_with_areas = false
	_query.collide_with_bodies = true
	_query.collision_mask = cameraColliderLayer
	#-------------------------------------------------------------------------------
	var _hitDictionary: Dictionary = get_world_3d().direct_space_state.intersect_ray(_query)
	if(_hitDictionary):
		camera.position = Vector3(0.0, 0.0, _hitDictionary["position"].distance_to(_from) - standOffDistance)
	else:
		camera.position = Vector3(0, 0, 4)
#endregion
#-------------------------------------------------------------------------------
#region ANIMATION
func AnimationTree_SetLocomotion(_x:float, _y:float, _velocity:float) -> void:
	var _v2: Vector2 = Vector2(_x, _y)
	_v2 = _v2/_velocity
	AnimationTree_SetLocomotion2(_v2.length())
#-------------------------------------------------------------------------------
func AnimationTree_SetLocomotion2(_f:float) -> void:
	animVelocity = lerp(animVelocity, _f, animWeight)
	AnimationTree_SetBlendPosition1(animName_Locomotion, animVelocity)
#-------------------------------------------------------------------------------
func AnimationTree_SetBlendPosition1(_s:String, _x:float) -> void:
	animation_tree[stateMachine_path+_s+"/blend_position"] = _x
#-------------------------------------------------------------------------------
func AnimationTree_SetBlendPosition2(_s:String, _x:float, _y:float) -> void:
	animation_tree[stateMachine_path+_s+"/blend_position"] = Vector2(_x, _y)
#-------------------------------------------------------------------------------
func AnimationTree_TimeScale(_f:float):
	animation_tree[timeScale_path+"scale"] = _f
#endregion
#-------------------------------------------------------------------------------
#region ANIMATION EVENTS
#-------------------------------------------------------------------------------
func Anim_FootOn():
	foot.monitoring = true
#-------------------------------------------------------------------------------
func Anim_FootOff():
	foot.monitoring = false
#-------------------------------------------------------------------------------
func Anim_ExitAttack() -> void:
	#velocity = Vector3.ZERO
	animVelocity = 0.0
	AnimationTree_TimeScale(1.0)
	myPLAYER_STATE = PLAYER_STATE.IDLE
	if(myCOLLISSION_STATE == COLLISSION_STATE.GROUND):
		playback.travel(animName_Locomotion)
	elif(myCOLLISSION_STATE == COLLISSION_STATE.AIR):
		playback.travel(animName_Floating)
#endregion
#-------------------------------------------------------------------------------
#region READY FUNCIONS
func KickEvent(_body:Node3D):
	_body.Kicked()
#endregion
#-------------------------------------------------------------------------------
#region MISC
func ApplyForce():
	for i in get_slide_collision_count():
		var c:KinematicCollision3D = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal() * 0.5)
#endregion
