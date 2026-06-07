extends Control
#WARNING because manager must be active during pause,
#all menu process modes must be set manually.

#Make sure to set focus neighbors on buttons when appropriate

#Copy and paste the duck typing boilerplate in all child menus

#If you wish to avoid debug hell, no script should touch mouse visibility or position
#except this menu manager

@export var onReadyMenu : Node
@export var menu_stack : Array = []
@onready var delay_repeat_timer : Timer = %DelayUntilRepeat
@onready var repeat_timer : Timer = %RepeatInterval

var default_focus : Control
var mouse_reset_data

var isAutomatedMouseMovement : bool = false

const KEYBOARD_AND_JOYPAD_EVENTS : Array = ["InputEventJoypadButton", "InputEventJoypadMotion", "InputEventKey"]

var joystick_vector : Vector2 = Vector2.ZERO
var initial_tilt_direction_vector : Vector2 = Vector2.ZERO
var dot_tilt_tolerance : float

func _ready():
	GameState.pause_toggled.connect(_on_pause_toggled)
	var tolerance_angle_degrees : int = 50
	dot_tilt_tolerance = cos(deg_to_rad(tolerance_angle_degrees))
	
	for node in get_children():
		var menu : Control
		if node is Control:
			menu = node
			menu.hide()
	open_menu(onReadyMenu)
	
	await get_tree().process_frame
	_initialize_button_animations(self)

func _input(event: InputEvent):
	if menu_stack.is_empty():
		return
		
	if event is InputEventMouseMotion:
		if isAutomatedMouseMovement:
			isAutomatedMouseMovement = false
			return
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_clear_navigation_focus()
		
	elif event.get_class() in KEYBOARD_AND_JOYPAD_EVENTS:
		if event is InputEventJoypadMotion:
			var stick_deadzone : float = 0.3
			var current_tilt_proportion = Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)).length()
			if current_tilt_proportion < stick_deadzone:
				initial_tilt_direction_vector = Vector2.ZERO
				delay_repeat_timer.stop()
				repeat_timer.stop()
				return
			
			if not is_stick_in_initial_direction_tolerance():
				initial_tilt_direction_vector = Vector2.ZERO
			
			joystick_vector = Vector2(
				Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
				Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
			)
			
			if initial_tilt_direction_vector == Vector2.ZERO:
				delay_repeat_timer.stop()
				repeat_timer.stop()
				
				initial_tilt_direction_vector = joystick_vector.normalized()
			
			if delay_repeat_timer.is_stopped() and repeat_timer.is_stopped():
				_navigate_by_vector(joystick_vector)
				get_viewport().set_input_as_handled()
				delay_repeat_timer.start()
		
		
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and is_mouse_inside_window():
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			_guarded_mouse_reset()
		
		_focus_default_menu_button()




########################### HELPER FUNCTIONS #########################################


## MENU TOGGLING

func open_menu(new_menu: Node) -> void:
	var is_first_opened : bool = false
	if menu_stack.is_empty():
		is_first_opened = true
	
	menu_stack.append(new_menu)
	menu_stack.back().show()
	new_menu.set_menu_properties()
	
	if is_first_opened == true:
		_guarded_mouse_reset()

func close_top_menu() -> void:
	if menu_stack.is_empty():
		return
	
	menu_stack.back().hide()
	menu_stack.pop_back()
	
	#the start game while loop would crash w/o this btw
	if not menu_stack.is_empty(): 
		menu_stack.back().show()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

## FOCUS & NAVIGATION

func _wake_focus() -> void:
	pass
	#make a unified function to gently wake on default button

func _focus_default_menu_button() -> void:
	if get_viewport().gui_get_focus_owner() == null:
			if default_focus:
				default_focus.grab_focus()

func _find_focusable_buttons(menu_root: Node) -> Array[Control]:
	var found_buttons: Array[Control] = []
	var nodes_to_check: Array = [menu_root]
	
	while not nodes_to_check.is_empty():
		var current_node = nodes_to_check.pop_front()
		if current_node == null:
			continue
			
		if current_node is Control and current_node.focus_mode != Control.FOCUS_NONE and current_node.visible:
			found_buttons.append(current_node)
			
		nodes_to_check.append_array(current_node.get_children())
		
	return found_buttons

func is_stick_in_initial_direction_tolerance() -> bool:
	# Tolerance pre-calculated in _ready()
	if joystick_vector.normalized().dot(initial_tilt_direction_vector) >= dot_tilt_tolerance:
		return true
	else:
		return false
# _navigate_next_by_vector? I may want a more generic name to accept all input devices
func _navigate_by_vector(input_vector: Vector2) -> void:
	var current_focus = get_viewport().gui_get_focus_owner()
	if not current_focus:
		if default_focus:
			default_focus.grab_focus()
		return
	
	var all_buttons = _find_focusable_buttons(menu_stack.back())
	var best_candidate_button: Control = null
	var highest_score: float = -INF
	
	for button in all_buttons:
		if button == current_focus:
			continue
		
		var vector_to_target = button.global_position - current_focus.global_position
		var distance_to_target = vector_to_target.length()
		
		# Divide by zero guard clause
		if is_equal_approx(distance_to_target, 0.0):
				push_warning("Overlapping focus elements detected.")
		
		var dot_product_to_button = input_vector.normalized().dot(vector_to_target.normalized())
		var minimum_dot_product_to_button : float = 0.70
		
		if dot_product_to_button > minimum_dot_product_to_button:
			var candidate_score = dot_product_to_button / distance_to_target
			if candidate_score > highest_score:
				
				best_candidate_button = button
				highest_score = candidate_score
				
	if best_candidate_button:
		best_candidate_button.grab_focus()


func _clear_navigation_focus():
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var focusedNode = get_viewport().gui_get_focus_owner()
			if focusedNode:
				focusedNode.release_focus()

## AUTOMATED MOUSE CONTROL

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
	if is_mouse_inside_window():
		isAutomatedMouseMovement = true
		var _final_position = await _get_mouse_reset_position(mouse_reset_data)
		get_viewport().warp_mouse(_final_position)

func is_mouse_inside_window() -> bool:
	var mousePosition = get_viewport().get_mouse_position()
	return get_viewport().get_visible_rect().has_point(mousePosition)

## BUTTON ANIMATION

const SCALE_FACTOR = Vector2(1.15, 1.15)
const DURATION = 0.15

func _initialize_button_animations(currentNode: Node) -> void:
	if currentNode is Button:
		currentNode.pivot_offset = currentNode.size / 2
		
		currentNode.mouse_entered.connect(_animate_scale.bind(currentNode, SCALE_FACTOR))
		currentNode.focus_entered.connect(_animate_scale.bind(currentNode, SCALE_FACTOR))
		
		currentNode.mouse_exited.connect(_animate_scale.bind(currentNode, Vector2.ONE))
		currentNode.focus_exited.connect(_animate_scale.bind(currentNode, Vector2.ONE))
	
	for child in currentNode.get_children():
		_initialize_button_animations(child)

func _animate_scale(button: Button, targetScale: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(button, "scale", targetScale, DURATION).set_trans(Tween.TRANS_QUAD)


##################### CHILD MENU BUTTON COMMANDS #############################################


## START GAME & LEVEL

func start_game():
	while not menu_stack.is_empty():
		close_top_menu()
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	GameState.is_pausable = true
	
	# In the future, don't hard code the level 1 preload
	var selected_level := preload("res://scenes/levels/level_1.tscn").instantiate()
	get_tree().current_scene.add_child(selected_level)

func reload_level():
	var rootNode = get_tree().current_scene
	var oldLevel = rootNode.get_node("Level1")
	
	if oldLevel:
		oldLevel.queue_free()
	
	await get_tree().process_frame
	
	var newLevel = preload("res://scenes/levels/level_1.tscn").instantiate()
	rootNode.add_child(newLevel)
	
## PAUSE HANDLING
# some functionality may still live in pause menu script

func _on_pause_toggled(is_paused: bool):
	if is_paused:
		open_menu($PauseMenu)
	else:
		while $PauseMenu in menu_stack:
			close_top_menu()

## Timeouts

func _on_delay_until_repeat_timeout():
	repeat_timer.start()


func _on_repeat_interval_timeout():
	_navigate_by_vector(joystick_vector)
