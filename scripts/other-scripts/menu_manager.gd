extends Control
#WARNING because manager must be active during pause,
#all menu process modes must be set manually.

#Make sure to set focus neighbors on buttons when appropriate

#If you wish to avoid debug hell, no script should touch mouse visibility or position
#except this menu manager

const KEYBOARD_AND_JOYPAD_EVENTS : Array = ["InputEventJoypadButton", "InputEventJoypadMotion", "InputEventKey"]

#WARNING These are settings for main menu,
#but should be handled without hard-coding
var defaultFocusButton : Button
var mouseResetPosition : Vector2

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
		#print("Stick and button event")
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.3:
			return
		
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and is_mouse_inside_window():
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			isAutomatedMouseMovement = true
			
			menu_stack.back().set_menu_properties()
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

## FOCUS

func _focus_default_menu_button() -> void:
	if get_viewport().gui_get_focus_owner() == null:
			if defaultFocusButton:
				defaultFocusButton.grab_focus()

func clear_navigation_focus():
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var focusedNode = get_viewport().gui_get_focus_owner()
			if focusedNode:
				focusedNode.release_focus()

## MOUSE 

func _guarded_mouse_reset() -> void:
	#await get_tree().process_frame
	if is_mouse_inside_window():
		isAutomatedMouseMovement = true
		get_viewport().warp_mouse(mouseResetPosition)

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

## START GAME

func start_game():
	while not menu_stack.is_empty():
		close_top_menu()
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	GameState.is_pausable = true
	
	# In the future, don't hard code the level 1 preload
	var selected_level := preload("res://scenes/levels/level_1.tscn").instantiate()
	get_tree().current_scene.add_child(selected_level)


## PAUSE HANDLING

func _on_pause_toggled(is_paused: bool):
	if is_paused:
		open_menu($PauseMenu)
	else:
		while $PauseMenu in menu_stack:
			close_top_menu()
