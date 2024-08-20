extends Node
class_name GameSystem_Script
#region VARIABLES
@export var player: Player_Script
@export var playerInfo: Label
@export var pauseLabel: Label
var isSlowMotion: bool = false
#endregion
#-------------------------------------------------------------------------------
#region MONOVEHAVIOUR
func _ready():
	PauseOff()
	NormalMotion()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#-------------------------------------------------------------------------------
func _process(_delta:float):
	playerInfo.text = player.PlayerInfo()
	playerInfo.text += "Is In SlowMotion: "+str(isSlowMotion)+"\n"
	playerInfo.text += str(Engine.get_frames_per_second())+"fps"
	Set_FullScreen()
	Set_Vsync()
	Set_SlowMotion()
	Set_MouseMode()
	Set_ResetGame()
	Input_PauseGame()
#endregion
#-------------------------------------------------------------------------------
#region DEBUG INPUTS
func Set_FullScreen() -> void:
	if(Input.is_action_just_pressed("Debug_FullScreen")):
		var _wm: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		if(_wm == DisplayServer.WINDOW_MODE_FULLSCREEN):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
#-------------------------------------------------------------------------------
func Set_Vsync() -> void:
	if(Input.is_action_just_pressed("Debug_Vsync")):
		var _vs: DisplayServer.VSyncMode = DisplayServer.window_get_vsync_mode()
		if(_vs == DisplayServer.VSYNC_DISABLED):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		elif(_vs == DisplayServer.VSYNC_ENABLED):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
#-------------------------------------------------------------------------------
func Set_MouseMode() -> void:
	if(Input.is_action_just_pressed("Debug_Mouse")):
		var _mm: Input.MouseMode = Input.mouse_mode
		if(_mm == Input.MOUSE_MODE_VISIBLE):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif(_mm == Input.MOUSE_MODE_CAPTURED):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
#-------------------------------------------------------------------------------
func Set_SlowMotion() -> void:
	if(Input.is_action_just_pressed("Debug_SlowMotion")):
		if(isSlowMotion):
			NormalMotion()
		else:
			Engine.time_scale = 0.3
			isSlowMotion = true
#-------------------------------------------------------------------------------
func NormalMotion():
	Engine.time_scale = 1.0
	isSlowMotion = false
#-------------------------------------------------------------------------------
func Set_ResetGame() -> void:
	if(Input.is_action_just_pressed("Debug_Reset")):
		get_tree().reload_current_scene()
#-------------------------------------------------------------------------------
func Input_PauseGame() -> void:
	if(Input.is_action_just_pressed("Input_Pause")):
		if(get_tree().paused):
			PauseOff()
		else:
			pauseLabel.show()
			get_tree().set_deferred("paused", true)
#-------------------------------------------------------------------------------
func PauseOff():
	pauseLabel.hide()
	get_tree().set_deferred("paused", false)
#endregion
#-------------------------------------------------------------------------------
