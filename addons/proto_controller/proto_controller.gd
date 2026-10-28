extends CharacterBody3D

##movement variables
@export var can_move : bool = true
@export var has_gravity : bool = true
@export var can_jump : bool = true
@export var can_sprint : bool = false
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
##var GlobalSettings.mouse_sensitivity
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0 ## do we want this?

@export_group("Movement Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
@export var input_talk : String = "dialogue"
@export var input_close_talk: String = "ui_close_dialog"

@export_group("General Actions") ##talk, attack,ect

@export_group("inventory")
var inventory: Array[Item] = []

@export var item_hold_point: Node3D

@export_group("throw")
@export var min_throw_force: float = 10.0
@export var max_throw_force: float = 30.0
@export var max_charge_time: float = 2.0

@export var min_roll_force: float = 10.0
@export var max_roll_force: float = 30.0

var throw_charge_time: float = 0.0
var is_charging_throw: bool = false

var roll_charge_time: float = 0.0
var is_charging_roll: bool = false

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var dialogue_lock: bool = true

var is_in_dialogue: bool = false
## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var actionable_finder: Area3D = $Direction/ActionableFinder

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# For loading the touch control buttons in menus
	if DisplayServer.is_touchscreen_available():
		GlobalSettings.show_ui_buttons_changed.connect(_on_show_ui_buttons_changed)
	else:
		$CanvasLayer.visible = false
		$CanvasLayer.offset.x = 1150

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dialogue"):
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			velocity = Vector3.ZERO
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			actionables[0].action()
			return
		
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	if dialogue_lock:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	# Gravity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Completely stop player-controlled movement during dialogue
	if not can_move:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# Jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Sprint
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Movement
	var input_dir := Input.get_vector(
		input_left,
		input_right,
		input_forward,
		input_back
	)

	var move_dir := (
		transform.basis *
		Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	if move_dir:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * GlobalSettings.sensitivity
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * GlobalSettings.sensitivity
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false


func _on_dialogue_started(_resource: DialogueResource) -> void:
	dialogue_lock = true
	can_move = false
	can_jump = false
	can_sprint = false
	can_freefly = false
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	is_in_dialogue = true
	is_charging_throw = false
	throw_charge_time = 0.0

func _on_dialogue_ended(_resource: DialogueResource) -> void:
	dialogue_lock = false
	can_move = true
	is_in_dialogue = false
	can_jump = true
	can_sprint = true
	can_freefly = true
	capture_mouse()


# For hiding the touch control buttons in menus
func _on_show_ui_buttons_changed(new_value: bool):
	$CanvasLayer.visible = new_value
	if !new_value:
		$CanvasLayer.offset.x = 1150
	else:
		$CanvasLayer.offset.x = 0
		
func _process(delta: float) -> void:
	if is_charging_throw:
		throw_charge_time += delta
		throw_charge_time = min(throw_charge_time, max_charge_time)
#item equipment 
var equipped_item: Item
var nearby_items: Array[Item] = []

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pickup"):
		pickup_item()
	if event.is_action_pressed("throw") and not event.is_echo():
		if equipped_item != null and equipped_item.has_method("throw"):
			is_charging_throw = true
			throw_charge_time = 0.0
	if event.is_action_released("throw"):
		throw_equipped_item()
		
	if event.is_action_pressed("roll") and not event.is_echo():
		if equipped_item != null and equipped_item.has_method("roll"):
			is_charging_roll = true
			roll_charge_time = 0.0

	if event.is_action_released("roll"):
		roll_equipped_item()

func equip_item(item: Item) -> void:
	print("A. equip_item started")

	if item_hold_point == null:
		print("ERROR: item_hold_point is NULL!")
		return
	if not inventory.has(item):
		inventory.append(item)
	if equipped_item != null and equipped_item != item:
		var previous_item := equipped_item
		previous_item.prepare_to_throw()
	equipped_item = item
	item.equip_to(item_hold_point)

func add_nearby_item(item: Item) -> void:
	if not nearby_items.has(item):
		nearby_items.append(item)

func pickup_item() -> void:
	if equipped_item != null and is_instance_valid(equipped_item):
		print("Already holding a spear!")
		return

	nearby_items = nearby_items.filter(func(item): return is_instance_valid(item))

	if nearby_items.is_empty():
		print("No nearby items!")
		return

	var item: Item = nearby_items[0]
	item.pickup(self)

func remove_nearby_item(item: Item) -> void:
	nearby_items.erase(item)

#spear 
func throw_equipped_item() -> void:
	if is_in_dialogue:
		is_charging_throw = false
		throw_charge_time = 0.0
		return
	if equipped_item == null:
		is_charging_throw = false
		throw_charge_time = 0.0
		return
	if not equipped_item.has_method("throw"):
		is_charging_throw = false
		throw_charge_time = 0.0
		return 
	var camera: Camera3D = get_viewport().get_camera_3d()
	var charge_ratio: float = clampf(throw_charge_time / max_charge_time, 0.0,1)
	var force: float = lerpf(min_throw_force, max_throw_force, charge_ratio)
	var direction : Vector3 = -camera.global_transform.basis.z
	equipped_item.throw(direction,force)
	equipped_item = null
	is_charging_throw = false
	throw_charge_time = 0.0
	

func roll_equipped_item() -> void:
	if is_in_dialogue or equipped_item == null:
		is_charging_roll = false
		roll_charge_time = 0.0
		return

	if not equipped_item.has_method("roll"):
		is_charging_roll = false
		roll_charge_time = 0.0
		return

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var charge_ratio := clampf(
		roll_charge_time / max_charge_time, 0.0, 1.0
	)
	var force := lerpf(min_roll_force, max_roll_force, charge_ratio)

	var direction := -camera.global_transform.basis.z
	direction.y = 0.0
	direction = direction.normalized()

	equipped_item.roll(direction, force)

	equipped_item = null
	is_charging_roll = false
	roll_charge_time = 0.0
	
