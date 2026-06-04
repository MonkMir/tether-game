extends Control
#WARNING because manager must be active during pause,
#all menu process modes must be set manually.

#Make sure to set focus neighbors on buttons when appropriate

#Copy and paste the duck typing boilerplate in all child menus

#If you wish to avoid debug hell, no script should touch mouse visibility or position
#except this menu manager

const KEYBOARD_AND_JOYPAD_EVENTS : Array = ["InputEventJoypadButton", "InputEventJoypadMotion", "InputEventKey"]

var default_focus : Control
var mouse_reset_data

@export var onReadyMenu : Node
@export var menu_stack : Array = []

var isAutomatedMouseMovement : bool = false

func _ready():
	GameState.pause_toggled.connect(_on_pause_toggled)
	
	for menu in get_children():
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
		clear_navigation_focus()
		
	elif event.get_class() in KEYBOARD_AND_JOYPAD_EVENTS:
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.3:
			return
			
		if not _is_navigation_just_pressed(event):
			return
		
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and is_mouse_inside_window():
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			
		_guarded_mouse_reset()
		_focus_default_menu_button()

## MENU NAVIGATION

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
	
	if not menu_stack.is_empty(): #the start game while loop would crash w/o this btw
		menu_stack.back().show()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

## FOCUS & NAVIGATION

func _is_navigation_just_pressed(event: InputEvent) -> bool:
	if event is InputEventJoypadMotion:
		return Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	return event.is_pressed() and not event.is_echo()

func _focus_default_menu_button() -> void:
	if get_viewport().gui_get_focus_owner() == null:
			if default_focus:
				default_focus.grab_focus()

func clear_navigation_focus():
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var focusedNode = get_viewport().gui_get_focus_owner()
			if focusedNode:
				focusedNode.release_focus()

## MOUSE 

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
