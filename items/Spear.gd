extends Item ## middle click to pick up

@export var throw_force: float = 30.0
@export var damage: int = 10

var has_been_thrown := false
var has_hit := false

# True only when this spear has hit a static world object.
var resting_on_world := false
var is_falling_after_support := false
# The exact spear this spear is resting against.
var supporting_spear: RigidBody3D = null


func throw(direction: Vector3, force: float) -> void:
	has_been_thrown = true
	has_hit = false
	resting_on_world = false
	supporting_spear = null

	# Detach from the player's hand and restore physics.
	prepare_to_throw()

	# Reset support state after preparing the spear.
	resting_on_world = false
	supporting_spear = null

	linear_velocity = direction.normalized() * force


func _physics_process(_delta: float) -> void:
	# Check whether the exact spear supporting this one
	# still exists and remains supported.
	if freeze and not resting_on_world and supporting_spear != null:
		if not is_instance_valid(supporting_spear):
			fall_again()
		elif not supporting_spear.has_stable_support():
			fall_again()

	# Rotate the spear to follow its movement.
# Only rotate while the spear is actually moving through the air.
	if has_been_thrown and not has_hit and not is_falling_after_support:
		if linear_velocity.length() > 0.1:
			look_at(global_position + linear_velocity, Vector3.UP)
			
func on_picked_up() -> void:
	# This spear is no longer supporting other spears.
	resting_on_world = false
	supporting_spear = null
	has_hit = false
	has_been_thrown = false
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
func has_stable_support(visited: Dictionary = {}) -> bool:
	# Prevent circular support chains.
	var id := get_instance_id()

	if visited.has(id):
		return false

	visited[id] = true

	# This spear has directly hit the world.
	if resting_on_world:
		return true

	# Otherwise, its support must be another supported spear.
	if is_instance_valid(supporting_spear):
		if supporting_spear.has_method("has_stable_support"):
			return supporting_spear.has_stable_support(visited)

	return false


func fall_again() -> void:
	freeze = false
	sleeping = false

	has_hit = false
	resting_on_world = false
	supporting_spear = null

	is_falling_after_support = true
	angular_velocity = Vector3.ZERO

	# Tilt the spear so its tip points downward as it falls.
	var down_direction := Vector3.DOWN
	var current_forward := -global_transform.basis.z

	var target_basis := Basis.looking_at(down_direction, Vector3.FORWARD)
	var current_basis := global_transform.basis.orthonormalized()

	# Only adjust orientation once, instead of every physics frame.
	global_transform.basis = target_basis



func _on_body_entered(body: Node3D) -> void:
	# Ignore the player.
	if body.is_in_group("Player"):
		return

	# Ignore collisions if this spear hasn't been thrown
	# or has already settled.
	if not has_been_thrown or has_hit:
		return
	# CASE 1: This spear hit another spear.
	if body.is_in_group("Spear") and body is RigidBody3D:
		var other := body as RigidBody3D

		# Do not stick to a spear that is floating or moving
		# without stable support.
		if not other.has_method("has_stable_support"):
			return

		if not other.has_stable_support():
			return

		# Track the exact spear providing support.
		supporting_spear = other
		resting_on_world = false
		has_hit = true

		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		freeze = true
		return

	# CASE 2: This spear hit the world.
	if body is StaticBody3D:
		resting_on_world = true
		supporting_spear = null
		has_hit = true

		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		freeze = true
		return

	# CASE 3: This spear hit an NPC or another object.
	if body.has_method("take_damage"):
		body.take_damage(damage)

	has_hit = true
	resting_on_world = false
	supporting_spear = null

	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


func _on_pickuparea_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.add_nearby_item(self)


func _on_pickuparea_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.remove_nearby_item(self)
