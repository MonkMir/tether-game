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

var activeMenu : Node 

var isAutomatedMouseMovement : bool = false

func _ready():
	await get_tree().process_frame
	_initialize_button_animations(self)

func _process(_delta):
	set_active_menu()
	print(activeMenu)

func _input(event: InputEvent):
	if activeMenu == null:
		return
	
	if event is InputEventMouseMotion:
		if isAutomatedMouseMovement:
			isAutomatedMouseMovement = false
			return
		
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
		clear_navigation_focus()
		
	elif event.get_class() in KEYBOARD_AND_JOYPAD_EVENTS:
		print("Stick and button event")
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.3:
			return
		
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and is_mouse_inside_window():
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			isAutomatedMouseMovement = true
			if activeMenu != null:
				activeMenu.update_active_menu_variables()
				reset_mouse_position()
		focus_default_menu_button()



func set_active_menu() -> void:
	var previousMenu = activeMenu 
	var foundVisibleMenu : bool = false
	
	for menu in self.get_children():
		if menu.visible:
			foundVisibleMenu = true
			activeMenu = menu
			break
	
	if !foundVisibleMenu:
		activeMenu = null
	
	# checks for transitions between menus and gameplay
	if previousMenu == null and activeMenu != null:
		activeMenu.update_active_menu_variables()
		if is_mouse_inside_window(): ## THIS IF BLOCK IS WARPING CURSOR IN MENU TO MENU TRANSITION
			isAutomatedMouseMovement = true
			reset_mouse_position()
	elif previousMenu != null and activeMenu == null:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN 
	#elif previousMenu != null and activeMenu != null:
		#activeMenu.update_active_menu_variables()

## FOCUS

func focus_default_menu_button() -> void:
	if get_viewport().gui_get_focus_owner() == null:
			if defaultFocusButton:
				defaultFocusButton.grab_focus()

func clear_navigation_focus():
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var focusedNode = get_viewport().gui_get_focus_owner()
			if focusedNode:
				focusedNode.release_focus()

## MOUSE 

func is_mouse_inside_window() -> bool:
	var mousePosition = get_viewport().get_mouse_position()
	return get_viewport().get_visible_rect().has_point(mousePosition)

func reset_mouse_position():
	get_viewport().warp_mouse(mouseResetPosition)

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
