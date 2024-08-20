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
@export var footBox: Node3D
#-------------------------------------------------------------------------------
# Player Animation
const animName_BaseBody: StringName = "BaseBody"
const animName_UpperBody: StringName = "UpperBody"
const animName_BaseBody2: StringName = "BaseBody2"
const animName_UpperBody2: StringName = "UpperBody2"
#-------------------------------------------------------------------------------
const animName_Empty: StringName = ""
const animName_Locomotion: StringName = "Locomotion"
const animName_Jump: StringName = "Jump"
const animName_Dodge: StringName = "Dodge"
const animName_Attack: StringName = "Attack"
const animName_Floating: StringName = "Fall"
const animName_Item: StringName = "Potion"
#-------------------------------------------------------------------------------
var attack_playback: AnimationNodeStateMachinePlayback
const animName_Combo1: StringName = "Combo1"
const animName_Combo2: StringName = "Combo2"
const animName_Combo3: StringName = "Combo3"
#-------------------------------------------------------------------------------
const animWeight: float = 0.1
const blendWeight: float = 0.1
const framesInOneSecond: float = 60
var animVelocity: Vector2
var currentVelocity: Vector3
#-------------------------------------------------------------------------------
# Camera Nodes
@export var cameraHolder: Marker3D
@export var cameraPivot: Marker3D
@export var camera: Camera3D
@export_flags_3d_physics var cameraColliderLayer: int
@export_flags_3d_physics var groundColliderLayer: int
const standOffDistance: float = 0.1
const cameraWeight: float = 0.2
const cameraAngleMin: float = -70
const cameraAngleMax: float = 70
var cameraZ: float
#-------------------------------------------------------------------------------
@export var lockOn_Area3D: Area3D
@export var lockOn_Collider: CollisionShape3D
@export var lockOn_Texture: TextureRect
@export var cameraCurrentTarget: Area3D
var isLockOn: bool = false
#-------------------------------------------------------------------------------
# Inputs
var input_dir: Vector2
var input_dir_raw: Vector2
var input_camera: Vector2
const jumpInput: String = "Input_Jump"
const runInput: String = "Input_Run"
const attackInput: String = "Input_Attack"
const itemInput: String = "Input_Item"
const dodgeInput: String = "Input_Dodge"
const lockOnInput: String = "Input_LockOn"
#-------------------------------------------------------------------------------
var comboCounter: int = 0
var isInSlowMotion: bool = false
const comboSlowMotion: float = 0.5
const comboFastMotion: float = 1.4
#-------------------------------------------------------------------------------
var canRotate:bool = false
#-------------------------------------------------------------------------------
# Playe Variables
const jumpVelocity: float = 11
const terminalVelocity: float = -10
#-------------------------------------------------------------------------------
# Speed
const ground_Speed : float = 3.5
const lightJump_Speed : float = 3.5
const heavyJump_Speed : float = 3.5
const fall_Speed : float = 3.5
const terminalVelocity_Speed : float = 3.5
const run_Speed : float = 7
#-------------------------------------------------------------------------------
const ground_OffSet: float = -0.2
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
	cameraZ = camera.position.z
	#-------------------------------------------------------------------------------
	attack_playback = animation_tree.get("parameters/Attack/playback")
	AnimationTree_Transition_Set(animName_BaseBody, animName_Locomotion)
	#-------------------------------------------------------------------------------
	foot.body_entered.connect(KickEvent)
	#-------------------------------------------------------------------------------
	CloseHurtBox()
	LockOff()
#-------------------------------------------------------------------------------
func _process(_delta:float) -> void:
	CameraCollision()
#-------------------------------------------------------------------------------
func _physics_process(_delta:float) -> void:
	input_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Up", "Move_Down")
	input_camera = Input.get_vector("Camera_Left", "Camera_Right", "Camera_Up", "Camera_Down")
	input_dir_raw = input_dir.normalized()
	#-------------------------------------------------------------------------------
	Camera_StateMachine(_delta, input_camera.x, input_camera.y, 4.5)
	#-------------------------------------------------------------------------------
	var _currentRoot:Quaternion = transform.basis.get_rotation_quaternion()
	var _rootMotion: Vector3 = animation_tree.get_root_motion_position()
	#NOTA: No se porque _delta no sirve con _rootMotion abajo, pero esto arregla si utilizo root motion para movermi personaje.
	var _rootVelocity: Vector3 = _currentRoot.normalized() * _rootMotion/get_process_delta_time()
	#-------------------------------------------------------------------------------
	match(myPLAYER_STATE):
		PLAYER_STATE.IDLE:
			#-------------------------------------------------------------------------------
			AnimationTree_Blend2_Weight(animName_BaseBody2, 0.0, blendWeight)
			AnimationTree_Blend2_Weight(animName_UpperBody2, 0.0, blendWeight)
			#-------------------------------------------------------------------------------
			match(myCOLLISSION_STATE):
				COLLISSION_STATE.GROUND:
					Handle_Rotation(_delta, 0.15)
					Handle_Movement(_delta, ground_Speed, run_Speed, ground_Weight)
					ApplyForce()
					#-------------------------------------------------------------------------------
					if(Input.is_action_pressed(dodgeInput)):
						Start_from_IDLE_to_DODGE()
						return
					#-------------------------------------------------------------------------------
					if(Input.is_action_pressed(attackInput)):
						Start_Attack()
						return
					#-------------------------------------------------------------------------------
					if(Input.is_action_pressed(jumpInput)):
						Start_Jump()
						return
					#-------------------------------------------------------------------------------
					if(Input.is_action_pressed(itemInput)):
						Start_Item()
						return
					#-------------------------------------------------------------------------------
					#Note: El "is_on_floor()" del propio Juego
					#if(is_on_floor()):
					#	move_and_slide()
					#else:
					#	Enter_Fall()
					#	return
					#-------------------------------------------------------------------------------
					#Note: Mi version de "is_on_floor()"
					var _result: Dictionary = GroundCollision(ground_OffSet)
					if(_result):
						ApplyGround(_result)
					else:
						Enter_Fall()
						return
				#-------------------------------------------------------------------------------
				COLLISSION_STATE.AIR:
					Handle_Rotation(_delta, 0.15)
					#-------------------------------------------------------------------------------
					if(Input.is_action_pressed(dodgeInput)):
						Start_from_IDLE_to_DODGE()
						return
					#-------------------------------------------------------------------------------
					match(myJUMP_STATE):
						JUMP_STATE.LIGHT_JUMP:
							Handle_Movement(_delta, lightJump_Speed, run_Speed, lightJump_Weight)
							ApplyGravity(_delta, lightJump_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(Input.is_action_just_released(jumpInput)):
								Enter_from_LightJump_to_HeavyJump()
								return
							#-------------------------------------------------------------------------------
							if(velocity.y <= 0.0):
								Enter_from_Jump_to_Fall()
								return
						#-------------------------------------------------------------------------------
						JUMP_STATE.HEAVY_JUMP:
							Handle_Movement(_delta, heavyJump_Speed, run_Speed, heavyJump_Weight)
							ApplyGravity(_delta, heavyJump_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y <= 0.0):
								Enter_from_Jump_to_Fall()
								return
						#-------------------------------------------------------------------------------
						JUMP_STATE.FALL:
							Handle_Movement(_delta, fall_Speed, run_Speed, fall_Weight)
							ApplyGravity(_delta, fall_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y < terminalVelocity):
								Enter_from_Fall_to_TerminalVelocity()
								return
							#-------------------------------------------------------------------------------
							#Note: El "is_on_floor()" del propio Juego
							#if(is_on_floor()):
							#	Enter_Ground_Old()
							#	return
							#-------------------------------------------------------------------------------
							#Note: Mi version de "is_on_floor()"
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								Enter_Ground(_result)
								return
						#-------------------------------------------------------------------------------
						JUMP_STATE.TERMINAL_VELOCITY:
							Handle_Movement(_delta, terminalVelocity_Speed, run_Speed, terminalVelocity_Weight)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y > terminalVelocity):
								Enter_from_TerminalVelocity_to_Fall()
								return
							#-------------------------------------------------------------------------------
							#Note: El "is_on_floor()" del propio Juego
							#if(is_on_floor()):
							#	Enter_Ground_Old()
							#	return
							#-------------------------------------------------------------------------------
							#Note: Mi version de "is_on_floor()"
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								Enter_Ground(_result)
								return
							#-------------------------------------------------------------------------------
						#-------------------------------------------------------------------------------
					#-------------------------------------------------------------------------------
				#-------------------------------------------------------------------------------
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		PLAYER_STATE.DODGE:
			Handle_Movement2(_delta, currentVelocity.x, currentVelocity.z, ground_Weight/2)
			Roll_Rotation(_delta, 0.2)
			#-------------------------------------------------------------------------------
			AnimationTree_Blend2_Weight(animName_BaseBody2, 1.0, blendWeight)
			AnimationTree_Blend2_Weight(animName_UpperBody2, 0.0, blendWeight)
			#-------------------------------------------------------------------------------
			match(myCOLLISSION_STATE):
				COLLISSION_STATE.GROUND:
					ApplyForce()
					#-------------------------------------------------------------------------------
					var _result: Dictionary = GroundCollision(ground_OffSet)
					if(_result):
						ApplyGround(_result)
					else:
						Enter_Fall()
						return
				#-------------------------------------------------------------------------------
				COLLISSION_STATE.AIR:
					match(myJUMP_STATE):
						JUMP_STATE.FALL:
							ApplyGravity(_delta, fall_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y < terminalVelocity):
								Enter_from_Fall_to_TerminalVelocity()
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								Enter_Ground(_result)
								return
						#-------------------------------------------------------------------------------
						JUMP_STATE.TERMINAL_VELOCITY:
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y > terminalVelocity):
								Enter_from_TerminalVelocity_to_Fall()
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								Enter_Ground(_result)
								return
						#-------------------------------------------------------------------------------
					#-------------------------------------------------------------------------------
				#-------------------------------------------------------------------------------
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		PLAYER_STATE.ATTACK:
			ApplyRootMotion(_delta, _rootVelocity)
			Handle_Combos()
			#-------------------------------------------------------------------------------
			AnimationTree_Blend2_Weight(animName_BaseBody2, 1.0, blendWeight)
			AnimationTree_Blend2_Weight(animName_UpperBody2, 0.0, blendWeight)
			#-------------------------------------------------------------------------------
			if(Input.is_action_pressed(dodgeInput)):
				if(isInSlowMotion):
					Start_from_ATTACK_to_DODGE()
					return
			#-------------------------------------------------------------------------------
			match(myCOLLISSION_STATE):
				COLLISSION_STATE.GROUND:
					ApplyForce()
					#-------------------------------------------------------------------------------
					var _result: Dictionary = GroundCollision(ground_OffSet)
					if(_result):
						ApplyGround(_result)
					else:
						Enter_Fall()
						return
				#-------------------------------------------------------------------------------
				COLLISSION_STATE.AIR:
					match(myJUMP_STATE):
						JUMP_STATE.FALL:
							ApplyGravity(_delta, fall_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y < terminalVelocity):
								Enter_from_Fall_to_TerminalVelocity()
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								Enter_Ground(_result)
								return
						#-------------------------------------------------------------------------------
						JUMP_STATE.TERMINAL_VELOCITY:
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y > terminalVelocity):
								Enter_from_TerminalVelocity_to_Fall()
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								Enter_Ground(_result)
								return
						#-------------------------------------------------------------------------------
					#-------------------------------------------------------------------------------
				#-------------------------------------------------------------------------------
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
		PLAYER_STATE.ITEM:
			Handle_Rotation(_delta, 0.15)
			Handle_Movement(_delta, ground_Speed, run_Speed, ground_Weight)
			#-------------------------------------------------------------------------------
			AnimationTree_Blend2_Weight(animName_BaseBody2, 0.0, blendWeight)
			AnimationTree_Blend2_Weight(animName_UpperBody2, 1.0, blendWeight)
			#-------------------------------------------------------------------------------
			match(myCOLLISSION_STATE):
				COLLISSION_STATE.GROUND:
					ApplyForce()
					#-------------------------------------------------------------------------------
					var _result: Dictionary = GroundCollision(ground_OffSet)
					if(_result):
						ApplyGround(_result)
					else:
						Enter_Fall()
						return
				#-------------------------------------------------------------------------------
				COLLISSION_STATE.AIR:
					match(myJUMP_STATE):
						JUMP_STATE.FALL:
							ApplyGravity(_delta, fall_GravityScale)
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y < terminalVelocity):
								Enter_from_Fall_to_TerminalVelocity()
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								Enter_Ground(_result)
								return
						#-------------------------------------------------------------------------------
						JUMP_STATE.TERMINAL_VELOCITY:
							move_and_slide()
							#-------------------------------------------------------------------------------
							if(velocity.y > terminalVelocity):
								Enter_from_TerminalVelocity_to_Fall()
								return
							#-------------------------------------------------------------------------------
							var _result: Dictionary = GroundCollision(0.0)
							if(_result):
								Enter_Ground(_result)
								return
						#-------------------------------------------------------------------------------
					#-------------------------------------------------------------------------------
				#-------------------------------------------------------------------------------
			#-------------------------------------------------------------------------------
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func _input(event):
	if(event is InputEventMouseMotion and !isLockOn):
		CameraRotation(event.relative.x, event.relative.y, 0.3)
#endregion
#-------------------------------------------------------------------------------
#region STATEMACHINE FUNCTIONS
func PlayerInfo() -> String:
	var _s: String = ""
	_s += "Player State: "+PLAYER_STATE.keys()[myPLAYER_STATE] + "\n"
	_s += "Collision State: "+COLLISSION_STATE.keys()[myCOLLISSION_STATE] + "\n"
	_s += "Jump State: "+JUMP_STATE.keys()[myJUMP_STATE] + "\n"
	_s += "#------------------------------------------------------"+"\n"
	_s += animName_BaseBody+"_Transition: "+str(AnimationTree_Transition_Get(animName_BaseBody))+"\n"
	_s += animName_UpperBody+"_Transition: "+str(AnimationTree_Transition_Get(animName_UpperBody))+"\n"
	_s += animName_BaseBody2+"_Blend2: "+str(AnimationTree_Blend2_Get(animName_BaseBody2))+"\n"
	_s += animName_BaseBody2+"_Transition: "+str(AnimationTree_Transition_Get(animName_BaseBody2))+"\n"
	_s += animName_UpperBody2+"_Blend2: "+str(AnimationTree_Blend2_Get(animName_UpperBody2))+"\n"
	_s += animName_UpperBody2+"_Transition: "+str(AnimationTree_Transition_Get(animName_UpperBody2))+"\n"
	_s += "#------------------------------------------------------"+"\n"
	_s += "Anim Velocity: "+str(animVelocity)+"\n"
	_s += "Anim Magnitude: "+str(animVelocity.length())+"\n"
	_s += "#------------------------------------------------------"+"\n"
	_s += "Velocity: "+str(velocity)+"\n"
	var _v2 = Vector2(velocity.x, velocity.z)
	_s += "Magnitud: "+str(_v2.length())+"\n"
	_s += "Current Velocity: "+str(currentVelocity)+"\n"
	_s += "Movement Input: "+str(input_dir)+"\n"
	_s += "Combo Counter: "+str(comboCounter)+"\n"
	_s += "Can Rotate: "+str(canRotate)+"\n"
	_s += "Is Lock On: "+str(isLockOn)+"\n"
	_s += "Target Lock On: "+str(cameraCurrentTarget)+"\n"
	return _s
#-------------------------------------------------------------------------------
func Start_from_IDLE_to_DODGE():
	Start_DODGE_Common()
	Roll_Movement(run_Speed)
	move_and_slide()
#-------------------------------------------------------------------------------
func Start_from_ATTACK_to_DODGE():
	AnimationSpeed_WithCopy(animName_Combo1, 1.0)
	Start_DODGE_Common()
	comboCounter = 0
	Roll_Movement(run_Speed)
#-------------------------------------------------------------------------------
func Start_DODGE_Common():
	myPLAYER_STATE = PLAYER_STATE.DODGE
	myJUMP_STATE = JUMP_STATE.FALL
	PlayAnimation_WithCopy(animName_BaseBody2,animName_Dodge)
#-------------------------------------------------------------------------------
func Start_Attack():
	myPLAYER_STATE = PLAYER_STATE.ATTACK
	currentVelocity = velocity
	comboCounter = 0
	isInSlowMotion = false
	canRotate = false
	CloseHurtBox()
	AnimationSpeed_WithCopy(animName_Combo1, comboFastMotion)
	PlayAnimation_WithCopy(animName_BaseBody2, animName_Combo1)
	#AnimationTree_TimeScale(animName_Combo1, comboFastMotion)
	#AnimationTree_Transition_Set(animName_BaseBody2, animName_Combo1)
	move_and_slide()
#-------------------------------------------------------------------------------
func Start_Jump():
	velocity.y = jumpVelocity
	myCOLLISSION_STATE = COLLISSION_STATE.AIR
	myJUMP_STATE = JUMP_STATE.LIGHT_JUMP
	AnimationTree_Transition_Set(animName_BaseBody, animName_Jump)
	move_and_slide()
#-------------------------------------------------------------------------------
func Start_Item():
	myPLAYER_STATE = PLAYER_STATE.ITEM
	PlayAnimation_InSecond_WithCopy(animName_UpperBody2, animName_Item, 1.8)
	#AnimationTree_TimeSeek(animName_Item, 1.8)
	#AnimationTree_Transition_Set(animName_UpperBody2, animName_Item)
	myJUMP_STATE = JUMP_STATE.FALL
	move_and_slide()
#-------------------------------------------------------------------------------
func Enter_Fall():
	myCOLLISSION_STATE = COLLISSION_STATE.AIR
	myJUMP_STATE = JUMP_STATE.FALL
	AnimationTree_Transition_Set(animName_BaseBody, animName_Floating)
	move_and_slide()
#-------------------------------------------------------------------------------
func Enter_Ground(_result:Dictionary):
	velocity.y = 0.0
	myCOLLISSION_STATE = COLLISSION_STATE.GROUND
	AnimationTree_Transition_Set(animName_BaseBody, animName_Locomotion)
#-------------------------------------------------------------------------------
func Enter_Ground_Old():
	myCOLLISSION_STATE = COLLISSION_STATE.GROUND
	AnimationTree_Transition_Set(animName_BaseBody, animName_Locomotion)
#-------------------------------------------------------------------------------
func Enter_from_LightJump_to_HeavyJump():
	myJUMP_STATE = JUMP_STATE.HEAVY_JUMP
#-------------------------------------------------------------------------------
func Enter_from_Jump_to_Fall():
	AnimationTree_Transition_Set(animName_BaseBody, animName_Floating)
	myJUMP_STATE = JUMP_STATE.FALL
#-------------------------------------------------------------------------------
func Enter_from_Fall_to_TerminalVelocity():
	velocity.y = terminalVelocity
	myJUMP_STATE = JUMP_STATE.TERMINAL_VELOCITY
#-------------------------------------------------------------------------------
func Enter_from_TerminalVelocity_to_Fall():
	myJUMP_STATE = JUMP_STATE.FALL
#endregion
#-------------------------------------------------------------------------------
#region PLAYER MOVEMENT
func ApplyGravity(_delta:float, _scale:float) -> void:
	velocity.y -= gravity * _scale * _delta
#-------------------------------------------------------------------------------
func ApplyGround(_result:Dictionary):
	velocity.y = 0.0
	position.y = _result["position"].y
	move_and_slide()
#-------------------------------------------------------------------------------
func ApplyRootMotion(_delta:float, _rootVelocity: Vector3):
	var _f: float = 0.1 * framesInOneSecond * _delta
	currentVelocity = lerp(currentVelocity, Vector3.ZERO, _f)
	var _velocity: Vector3 = currentVelocity + _rootVelocity
	velocity.x = _velocity.x
	velocity.z = _velocity.z
	#-------------------------------------------------------------------------------
	if(canRotate):
		Handle_Rotation(_delta, 0.15)
#-------------------------------------------------------------------------------
func Handle_Combos():
	if(Input.is_action_just_pressed(attackInput)):
		comboCounter += 1
		if(isInSlowMotion):
			AnimationSpeed_WithCopy(animName_Combo1, comboFastMotion)
			isInSlowMotion = false
#-------------------------------------------------------------------------------
func Handle_Movement(_delta:float, _normalSpeed:float, _runSpeed:float, _weight:float):
	if(input_dir != Vector2.ZERO):
		var _targetDir: Vector3
		if(Input.is_action_pressed(runInput)):
			_targetDir = cameraHolder.transform.basis.z * input_dir_raw.y
			_targetDir += cameraHolder.transform.basis.x * input_dir_raw.x
			_targetDir.y = 0.0
			_targetDir.normalized()
			Handle_Movement2(_delta, _targetDir.x * _runSpeed, _targetDir.z * _runSpeed, _weight)
			AnimationTree_SetLocomotion2(_delta, _targetDir.x * 2.0, _targetDir.z * 2.0)
		else:
			_targetDir = cameraHolder.transform.basis.z * input_dir.y
			_targetDir += cameraHolder.transform.basis.x * input_dir.x
			_targetDir.y = 0.0
			_targetDir.normalized()
			Handle_Movement2(_delta, _targetDir.x * _normalSpeed, _targetDir.z * _normalSpeed, _weight)
			#AnimationTree_SetLocomotion(velocity.x, velocity.z, _normalSpeed)	#Esta linea si quiero que cuando choque con una pared, la animacion cambie.
			AnimationTree_SetLocomotion2(_delta, _targetDir.x, _targetDir.z) 
	else:
		Handle_Movement2(_delta, 0.0, 0.0, _weight)
		AnimationTree_SetLocomotion2(_delta, 0.0, 0.0)
#-------------------------------------------------------------------------------
func Handle_Movement2(_delta:float, _x:float, _z:float, _weight:float):
	var _f: float = _weight * framesInOneSecond * _delta
	velocity.x = lerp(velocity.x, _x, _f)
	velocity.z = lerp(velocity.z, _z, _f)
#-------------------------------------------------------------------------------
func Roll_Movement(_speed:float):
	if(input_dir != Vector2.ZERO):
		var _targetDir: Vector3
		_targetDir = cameraHolder.transform.basis.z * input_dir_raw.y
		_targetDir += cameraHolder.transform.basis.x * input_dir_raw.x
		_targetDir.y = 0.0
		_targetDir.normalized()
		currentVelocity = _targetDir * _speed
	else:
		var currentRoot: Quaternion = transform.basis.get_rotation_quaternion()
		currentVelocity = currentRoot.normalized()* Vector3.BACK * _speed
#-------------------------------------------------------------------------------
func Roll_Rotation(_delta:float, _weight:float):
	var _f: float = _weight * framesInOneSecond * _delta
	global_rotation.y = lerp_angle(global_rotation.y, atan2(currentVelocity.x, currentVelocity.z), _f)
#-------------------------------------------------------------------------------
func Handle_Rotation(_delta:float, _weight:float):
	if(input_dir != Vector2.ZERO):
		var _targetDir: Vector3
		_targetDir = cameraHolder.transform.basis.z * input_dir_raw.y
		_targetDir += cameraHolder.transform.basis.x * input_dir_raw.x
		_targetDir.y = 0.0
		_targetDir.normalized()
		var _f: float = _weight * framesInOneSecond * _delta
		global_rotation.y = lerp_angle(global_rotation.y, atan2(_targetDir.x, _targetDir.z), _f)
#-------------------------------------------------------------------------------
func GroundCollision(_to:float) -> Dictionary:
	var _hitDictionary: Array[Dictionary] = []
	#-------------------------------------------------------------------------------
	var _d0: Dictionary = Ground_Raycast_Dictionary(0.0, _to, 0.0)
	if(!_d0.is_empty()):
		_hitDictionary.push_back(_d0)
	#-------------------------------------------------------------------------------
	var _radius: float = 0.1
	var _dir: float = collider.rotation.y
	var _num: int = 4
	for _i in _num:
		var _ang = deg_to_rad(_dir)
		var _di: Dictionary = Ground_Raycast_Dictionary(_radius*cos(_ang), _to, _radius*sin(_ang))
		if(!_di.is_empty()):
			_hitDictionary.push_back(_di)
		_dir += 360/float(_num)
	#-------------------------------------------------------------------------------
	if(_hitDictionary.size() > 0):
		var _d: Dictionary = _hitDictionary[0]
		for _i in range(1, _hitDictionary.size()):
			if(!_hitDictionary[_i].is_empty()):
				if(_d["position"].y < _hitDictionary[_i]["position"].y):
					_d = _hitDictionary[_i]
		return _d
	else:
		return {}
#-------------------------------------------------------------------------------
func GroundCollisionB(_to:float) -> Dictionary:
	var _hitDictionary: Array[Dictionary] = []
	#-------------------------------------------------------------------------------
	var _d0: Dictionary = Ground_Raycast_Dictionary(0.0, _to, 0.0)
	if(!_d0.is_empty()):
		_hitDictionary.push_back(_d0)
	#-------------------------------------------------------------------------------
	var _radius: float = collider.shape.radius * 0.5
	var _dir: float = collider.rotation.y
	var _num: int = 4
	for _i in _num:
		var _ang = deg_to_rad(_dir)
		var _di: Dictionary = Ground_Raycast_Dictionary(_radius*cos(_ang), _to, _radius*sin(_ang))
		if(!_di.is_empty()):
			_hitDictionary.push_back(_di)
		_dir += 360/float(_num)
	#-------------------------------------------------------------------------------
	if(_hitDictionary.size() > 0):
		return _hitDictionary[0]
	else:
		return {}
#-------------------------------------------------------------------------------
func Ground_Raycast_Dictionary(_x:float, _down:float, _z:float) -> Dictionary:
	var _query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	#var _from: Vector3 = to_global(Vector3(_x, collider.position.y-collider.shape.height/2.0, _z))
	var _from: Vector3 = to_global(Vector3(_x, 0.3, _z))
	var _to: Vector3 = to_global(Vector3(_x, _down, _z))
	_query.from = _from
	_query.to = _to
	_query.collide_with_areas = false
	_query.collide_with_bodies = true
	_query.collision_mask = groundColliderLayer
	#-------------------------------------------------------------------------------
	var _hitDictionary: Dictionary = get_world_3d().direct_space_state.intersect_ray(_query)
	Ground_Raycast_Drawline(_hitDictionary, _from, _to)		#NOTA: Si no necesito el debug line, puedo borrar esta linea.
	return _hitDictionary
#-------------------------------------------------------------------------------
func Ground_Raycast_Drawline(_d:Dictionary, _from:Vector3, _to:Vector3):
	if(_d.is_empty()):
		DrawDebug_Line(_from, _to, Color.RED, 1)
	else:
		var _pos: Vector3 = _d["position"]
		var _normal: Vector3 = _pos+_d["normal"]
		DrawDebug_Line(_from, _to, Color.GREEN, 1)
		DrawDebug_Line(_pos, _normal, Color.YELLOW, 1)
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
func Camera_StateMachine(_delta:float, _x:float, _y:float, _scale:float):
	CameraFollow(_delta)
	#-------------------------------------------------------------------------------
	match(isLockOn):
		true:
			if(!Is_LockOn_InRange(cameraCurrentTarget)):
				LockOff()
				return
			if(Input.is_action_just_pressed(lockOnInput)):
				cameraCurrentTarget = null
				LockOff()
				return
			CameraLockOn(_delta)
			LockOn_DotManager()
		#-------------------------------------------------------------------------------
		false:
			if(Input.is_action_just_pressed(lockOnInput)):
				cameraCurrentTarget = Check_for_LockOn()
				if(cameraCurrentTarget != null):
					isLockOn = true
					LockOn_DotManager()
					lockOn_Texture.show()
					return
			CameraRotation(_x, _y, _scale)
		#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func LockOff():
	lockOn_Texture.hide()
	isLockOn = false
#-------------------------------------------------------------------------------
func CameraFollow(_delta:float):
	var _f:float = cameraWeight * framesInOneSecond * _delta
	cameraHolder.position = lerp(cameraHolder.position, position, _f)
#-------------------------------------------------------------------------------
func CameraRotation(_x:float, _y:float, _scale:float):
	cameraHolder.rotate_y(deg_to_rad(-_x*_scale))
	cameraPivot.rotate_x(deg_to_rad(-_y*_scale))
	cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, deg_to_rad(cameraAngleMin), deg_to_rad(cameraAngleMax))
#-------------------------------------------------------------------------------
func CameraLockOn(_delta:float):
	var _from: Vector3 = cameraPivot.global_position
	var _to: Vector3 = cameraCurrentTarget.global_position
	var _v3: Vector3 = _to- _from
	var _hypotenuse: float = pow(pow(_v3.x,2)+pow(_v3.z,2),0.5)
	#-------------------------------------------------------------------------------
	var _f: float = 0.2 * framesInOneSecond * _delta
	cameraHolder.rotation.y = lerp_angle(cameraHolder.rotation.y, atan2(-_v3.x, -_v3.z), _f)
	cameraPivot.rotation.x = lerp_angle(cameraPivot.rotation.x, atan2(_v3.y, _hypotenuse), _f)
	cameraPivot.rotation.x = clamp(cameraPivot.rotation.x, deg_to_rad(cameraAngleMin), deg_to_rad(cameraAngleMax))
	#-------------------------------------------------------------------------------
	#DrawDebug_Line(_to, _from, Color.RED, 1)
#-------------------------------------------------------------------------------
func CameraCollision():
	var _query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	var _from: Vector3 = cameraPivot.global_position
	_query.from = _from
	_query.to = cameraPivot.to_global(Vector3(0, 0, cameraZ))
	_query.collide_with_areas = false
	_query.collide_with_bodies = true
	_query.collision_mask = cameraColliderLayer
	#-------------------------------------------------------------------------------
	var _hitDictionary: Dictionary = get_world_3d().direct_space_state.intersect_ray(_query)
	if(_hitDictionary):
		camera.position = Vector3(0.0, 0.0, _hitDictionary["position"].distance_to(_from) - standOffDistance)
	else:
		camera.position = Vector3(0, 0, cameraZ)
#-------------------------------------------------------------------------------
func Check_for_LockOn() -> Area3D:
	var _lockOn_List: Array[Area3D] = lockOn_Area3D.get_overlapping_areas()
	var _size: int = _lockOn_List.size()
	if(_size > 0):
		var _l : Area3D = _lockOn_List[0]
		var _v3: Vector3 = lockOn_Area3D.global_position
		for _i in range(1, _size):
			var _li : Area3D = _lockOn_List[_i]
			var _d: float = _v3.distance_to(_l.global_position)
			var _di: float = _v3.distance_to(_li.global_position)
			if(_di < _d):
				_l = _li
		return _l
	else:
		return null
#-------------------------------------------------------------------------------
func Is_LockOn_InRange(_target: Area3D) -> bool:
	var _v3: Vector3 = lockOn_Area3D.global_position
	var _d: float = _v3.distance_to(_target.global_position)
	#-------------------------------------------------------------------------------
	if(_target == null):
		return false
	#-------------------------------------------------------------------------------
	if(_d > lockOn_Collider.shape.radius):
		return false
	#-------------------------------------------------------------------------------
	return true
#-------------------------------------------------------------------------------
func LockOn_DotManager():
	var _pos: Vector2 = camera.unproject_position(cameraCurrentTarget.global_position)
	_pos -= lockOn_Texture.size/2
	lockOn_Texture.global_position = _pos
#endregion
#-------------------------------------------------------------------------------
#region ANIMATION FUNCTIONS
func AnimationTree_SetLocomotion(_delta:float, _x:float, _y:float, _velocity:float) -> void:
	var _v2: Vector2 = Vector2(_x, _y)
	_v2 = _v2/_velocity
	AnimationTree_SetLocomotion2(_delta, _v2.x, _v2.y)
#-------------------------------------------------------------------------------
func AnimationTree_SetLocomotion2(_delta:float, _x:float, _y:float) -> void:
	var _f: float = animWeight * framesInOneSecond * _delta
	animVelocity = lerp(animVelocity, Vector2(_x,_y), _f)
	AnimationTree_BlendSpace1D_Set("Locomotion", animVelocity.length())
#-------------------------------------------------------------------------------
func IsInStateAnimationCopy(_state:PLAYER_STATE, _s:StringName, _animName:StringName, _isCopy:bool) -> bool:
	if(_state == myPLAYER_STATE):
		return IsInAnimationCopy(_s, _animName, _isCopy)
	else:
		return false
#endregion
#-------------------------------------------------------------------------------
#region ANIMATION EVENTS
func Anim_Dodge_ExitDodge(_isCopy:bool):
	if(IsInStateAnimationCopy(PLAYER_STATE.DODGE, animName_BaseBody2, animName_Dodge, _isCopy)):
		comboCounter = 0
		#animVelocity = Vector2.ZERO
		if(AnimationTree_Transition_Get(animName_BaseBody) == animName_Jump):
			AnimationTree_Transition_Set(animName_BaseBody, animName_Floating)
		myPLAYER_STATE = PLAYER_STATE.IDLE
#-------------------------------------------------------------------------------
func Anim_Item_ExitItem(_isCopy:bool):
	if(IsInStateAnimationCopy(PLAYER_STATE.ITEM, animName_UpperBody2, animName_Item, _isCopy)):
		myPLAYER_STATE = PLAYER_STATE.IDLE
#-------------------------------------------------------------------------------
func Anim_Attack_CanRotate(_canRotate:bool, _isCopy:bool):
	if(IsInStateAnimationCopy(PLAYER_STATE.ATTACK, animName_BaseBody2, animName_Combo1, _isCopy)):
		canRotate = _canRotate
#-------------------------------------------------------------------------------
func Anim_Attack_OpenHurtBox(_isCopy:bool):
	if(IsInStateAnimationCopy(PLAYER_STATE.ATTACK, animName_BaseBody2, animName_Combo1, _isCopy)):
		foot.monitoring = true
		footBox.show()
#-------------------------------------------------------------------------------
func Anim_Attack_CloseHurtBox(_isCopy:bool):
	if(IsInStateAnimationCopy(PLAYER_STATE.ATTACK, animName_BaseBody2, animName_Combo1, _isCopy)):
		CloseHurtBox()
#-------------------------------------------------------------------------------
func CloseHurtBox():
	foot.monitoring = false
	footBox.hide()
#-------------------------------------------------------------------------------
func Anim_Attack_SlowMotion(_max:int, _isCopy:bool):
	if(IsInStateAnimationCopy(PLAYER_STATE.ATTACK, animName_BaseBody2, animName_Combo1, _isCopy) and comboCounter < _max):
		isInSlowMotion = true
		AnimationSpeed_WithCopy(animName_Combo1, comboSlowMotion)
#-------------------------------------------------------------------------------
func Anim_Attack_FastMotion(_max:int, _isCopy:bool):
	if(IsInStateAnimationCopy(PLAYER_STATE.ATTACK, animName_BaseBody2, animName_Combo1, _isCopy)):
		isInSlowMotion = false
		AnimationSpeed_WithCopy(animName_Combo1, comboFastMotion)
#-------------------------------------------------------------------------------
func Anim_Attack_ExitCombo(_max:int, _isCopy:bool):
	if(IsInStateAnimationCopy(PLAYER_STATE.ATTACK, animName_BaseBody2, animName_Combo1, _isCopy) and comboCounter < _max):
		ExitAttack_Common()
#-------------------------------------------------------------------------------
func Anim_Attack_ExitAttack(_isCopy:bool):
	if(IsInStateAnimationCopy(PLAYER_STATE.ATTACK, animName_BaseBody2, animName_Combo1, _isCopy)):
		ExitAttack_Common()
#-------------------------------------------------------------------------------
func ExitAttack_Common():
	CloseHurtBox()
	comboCounter = 0
	#animVelocity = Vector2.ZERO
	AnimationSpeed_WithCopy(animName_Combo1, 1.0)
	myPLAYER_STATE = PLAYER_STATE.IDLE
#endregion
#-------------------------------------------------------------------------------
#region READY FUNCIONS
func KickEvent(_body:Node3D):
	if(_body.has_method("Player_Attack")):
		_body.Player_Attack()
#endregion
#-------------------------------------------------------------------------------
#region MISC
func ApplyForce():
	for i in get_slide_collision_count():
		var c:KinematicCollision3D = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal() * 1.0)
#-------------------------------------------------------------------------------
func DrawDebug_Line(pos1: Vector3, pos2: Vector3, color = Color.WHITE_SMOKE, persist_ms = 0):
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	#-------------------------------------------------------------------------------
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	#-------------------------------------------------------------------------------
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(pos1)
	immediate_mesh.surface_add_vertex(pos2)
	immediate_mesh.surface_end()
	#-------------------------------------------------------------------------------
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	#-------------------------------------------------------------------------------
	return await final_cleanup(mesh_instance, persist_ms)
#-------------------------------------------------------------------------------
func final_cleanup(mesh_instance: MeshInstance3D, persist_ms: float):
	get_tree().get_root().add_child(mesh_instance)
	if persist_ms == 1:
		await get_tree().physics_frame
		mesh_instance.queue_free()
	elif persist_ms > 0:
		await get_tree().create_timer(persist_ms).timeout
		mesh_instance.queue_free()
	else:
		return mesh_instance
#endregion
#-------------------------------------------------------------------------------
