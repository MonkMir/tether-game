extends Control
#WARNING because manager must be active during pause,
#all menu process modes must be set manually.

#Make sure to set focus neighbors on buttons when appropriate

#Copy and paste the duck typing boilerplate in all child menus

#If you wish to avoid debug hell, no script should touch mouse visibility or position
#except this menu manager

const KEYBOARD_AND_JOYPAD_EVENTS : Array[String] = [
	"InputEventJoypadButton",
	 "InputEventJoypadMotion",
	 "InputEventKey",
	]

@export var onready_menu : Control

var default_focus : Control
var mouse_reset_data ## Dynamic to accept Nodes and Vector2

var _menu_stack: Array[Control] = []
var _is_automated_mouse_motion := false
var _joystick_vector := Vector2.ZERO
var _initial_tilt_direction_vector := Vector2.ZERO

@onready var delay_repeat_timer : Timer = %DelayUntilRepeat
@onready var repeat_timer : Timer = %RepeatInterval
# WARNING YO I HAVE NO IDEA IF THIS ONREADY SET UP WORKS. REMOVE TAGS 
# AND PUT T.A.D. IN READY() IF NOT. PREPEND UNDERSCORE. MAYBE MOVE LOGIC TO ONEADY IF POSSIBLE
@onready var tolerance_angle_degrees : int = 50
@onready var dot_tilt_tolerance : float

#region LOGIC LOOPS


func _ready():
	GameState.pause_toggled.connect(_on_pause_toggled)
	
	dot_tilt_tolerance = cos(deg_to_rad(tolerance_angle_degrees))
	
	for node in get_children():
		var menu : Control
		if node is Control:
			menu = node
			menu.hide()
	open_menu(onready_menu)
	
	await get_tree().process_frame
	_initialize_button_animations(self)


func _input(event: InputEvent):
	if _menu_stack.is_empty():
		return
		
	if event is InputEventMouseMotion:
		if _is_automated_mouse_motion:
			_is_automated_mouse_motion = false
			return
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_clear_navigation_focus()
		
	elif event.get_class() in KEYBOARD_AND_JOYPAD_EVENTS:
		if event is InputEventJoypadMotion:
			
			_joystick_vector = Vector2(
				Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
				Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
			)
			var deadzone_percent := 0.30
			var tilt_percent : float = _joystick_vector.length()
			if tilt_percent < deadzone_percent:
				_initial_tilt_direction_vector = Vector2.ZERO
				delay_repeat_timer.stop()
				repeat_timer.stop()
				return
			
			if not _is_stick_in_initial_direction_tolerance():
				_initial_tilt_direction_vector = Vector2.ZERO
			
			if _initial_tilt_direction_vector == Vector2.ZERO:
				delay_repeat_timer.stop()
				repeat_timer.stop()
				
				_initial_tilt_direction_vector = _joystick_vector.normalized()
			
			if delay_repeat_timer.is_stopped() and repeat_timer.is_stopped():
				_navigate_by_vector(_joystick_vector)
				get_viewport().set_input_as_handled()
				delay_repeat_timer.start()
		
		
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and _is_mouse_inside_window():
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			_guarded_mouse_reset()
		
		_focus_default_menu_button()
#endregion

# Split this region further
#region HELPER FUNCTIONS 
# MENU TOGGLING


func open_menu(new_menu: Node) -> void:
	var is_first_opened := false
	if _menu_stack.is_empty():
		is_first_opened = true
	
	_menu_stack.append(new_menu)
	_menu_stack.back().show()
	new_menu.set_menu_properties()
	
	if is_first_opened == true:
		_guarded_mouse_reset()


# Should this be moved into child utilites?
func close_top_menu() -> void:
	if _menu_stack.is_empty():
		return
	
	_menu_stack.back().hide()
	_menu_stack.pop_back()
	
	#the start game while loop would crash w/o this btw
	if not _menu_stack.is_empty(): 
		_menu_stack.back().show()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

# FOCUS & NAVIGATION

func _wake_focus() -> void:
	pass
	#make a unified function to gently wake on default button


func _focus_default_menu_button() -> void:
	if get_viewport().gui_get_focus_owner() == null:
			if default_focus:
				default_focus.grab_focus()


func _find_focusable_buttons(menu_root: Node) -> Array[Control]:
	var found_buttons: Array[Control] = []
	var nodes_to_check: Array[Node] = [menu_root]
	
	while not nodes_to_check.is_empty():
		var current_node : Node = nodes_to_check.pop_front()
		if current_node == null:
			continue
			
		if (
					current_node is Control
					and current_node.focus_mode != Control.FOCUS_NONE
					and current_node.visible
		):
			found_buttons.append(current_node)
			
		nodes_to_check.append_array(current_node.get_children())
		
	return found_buttons


func _is_stick_in_initial_direction_tolerance() -> bool:
	# Tolerance pre-calculated in _ready()
	if _joystick_vector.normalized().dot(_initial_tilt_direction_vector) >= dot_tilt_tolerance:
		return true
	else:
		return false


func _navigate_by_vector(input_vector: Vector2) -> void:
	var current_focus : Control = get_viewport().gui_get_focus_owner()
	if not current_focus:
		if default_focus:
			default_focus.grab_focus()
		return
	
	var all_buttons : Array[Control] = _find_focusable_buttons(_menu_stack.back())
	var best_candidate_button: Control = null
	var highest_score: float = -INF
	
	for button in all_buttons:
		if button == current_focus:
			continue
		
		var vector_to_target := button.global_position - current_focus.global_position
		var distance_to_target : float = vector_to_target.length()
		
		# Divide by zero guard clause
		if is_equal_approx(distance_to_target, 0.0):
				push_warning("Overlapping focus elements detected.")
		
		var dot_product_to_button : float = (
				input_vector.normalized()
				.dot(vector_to_target.normalized())
		)
		var minimum_dot_product_to_button := 0.70
		
		if dot_product_to_button > minimum_dot_product_to_button:
			var candidate_score : float = dot_product_to_button / distance_to_target
			if candidate_score > highest_score:
				
				best_candidate_button = button
				highest_score = candidate_score
				
	if best_candidate_button:
		best_candidate_button.grab_focus()


func _clear_navigation_focus():
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var focused_node : Control = get_viewport().gui_get_focus_owner()
			if focused_node:
				focused_node.release_focus()

# AUTOMATED MOUSE CONTROL

func _get_mouse_reset_position(data) -> Vector2:
	if data is Vector2:
		printerr("_get_mouse_reset_position called redundantly")
		return data
	elif data is Node:
		await RenderingServer.frame_post_draw
		return data.global_position
	else:
		return get_viewport().get_visible_rect().size / 2


func _guarded_mouse_reset() -> void:
	if _is_mouse_inside_window():
		_is_automated_mouse_motion = true
		var final_position : Vector2 = await _get_mouse_reset_position(mouse_reset_data)
		get_viewport().warp_mouse(final_position)


func _is_mouse_inside_window() -> bool:
	var mouse_position : Vector2 = get_viewport().get_mouse_position()
	return get_viewport().get_visible_rect().has_point(mouse_position)

# BUTTON ANIMATION


func _initialize_button_animations(currentNode: Node) -> void:
	const SCALE_FACTOR := Vector2(1.15, 1.15)
	
	if currentNode is Button:
		currentNode.pivot_offset = currentNode.size / 2
		
		currentNode.mouse_entered.connect(_animate_scale.bind(currentNode, SCALE_FACTOR))
		currentNode.focus_entered.connect(_animate_scale.bind(currentNode, SCALE_FACTOR))
		
		currentNode.mouse_exited.connect(_animate_scale.bind(currentNode, Vector2.ONE))
		currentNode.focus_exited.connect(_animate_scale.bind(currentNode, Vector2.ONE))
	
	for child in currentNode.get_children():
		_initialize_button_animations(child)


func _animate_scale(button: Button, targetScale: Vector2) -> void:
	const DURATION := 0.15
	
	var tween := create_tween()
	tween.tween_property(button, "scale", targetScale, DURATION).set_trans(Tween.TRANS_QUAD)
#endregion

#region MENU BUTTON OPERATIONS
# START GAME & LEVEL


func start_game():
	while not _menu_stack.is_empty():
		close_top_menu()
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	GameState.is_pausable = true
	
	# In the future, don't hard code the level 1 preload
	var selected_level : Node2D = preload("res://levels/level_1.tscn").instantiate()
	get_tree().current_scene.add_child(selected_level)


func reload_level():
	var root_node : Node2D = get_tree().current_scene
	var old_level : Node2D = root_node.get_node("Level1") # Hard coded thumbs down 
	
	if old_level:
		old_level.queue_free()
	
	await get_tree().process_frame
	
	var new_level : Node2D = preload("res://levels/level_1.tscn").instantiate()
	root_node.add_child(new_level)
	
# PAUSE HANDLING
# some functionality may still live in pause menu script

func _on_pause_toggled(is_paused: bool):
	if is_paused:
		open_menu($PauseMenu)
	else:
		while $PauseMenu in _menu_stack:
			close_top_menu()

#endregion

# TIMEOUT CALLBACKS

func _on_delay_until_repeat_timeout():
	repeat_timer.start()


func _on_repeat_interval_timeout():
	_navigate_by_vector(_joystick_vector)
