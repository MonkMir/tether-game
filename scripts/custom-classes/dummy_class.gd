extends RigidBody2D
class_name Dummy
#DESPAWN LOGIC
@onready var player : Node
@onready var area := $Area2D

var attackPower : float


var speedLimit : int = 1850
var currentSpeed : float

func _ready():
	player = get_player()
	area.area_entered.connect(_on_area_entered)


func _physics_process(_delta):
	currentSpeed = linear_velocity.length()
	#What is magic number here?
	attackPower = linear_velocity.length() / 35


func _on_area_entered(_area):
	if _area.is_in_group("enemies"):
		_area.receive_dam_param(attackPower)

func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")
