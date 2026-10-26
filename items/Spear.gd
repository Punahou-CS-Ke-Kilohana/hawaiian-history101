extends Item ## middle click to pick up

@export var throw_force: float = 30.0
@export var damage: int = 10

var has_been_thrown := false
var has_hit := false

# The body currently supporting this spear.
var supporting_body: Node3D = null
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
	supporting_body = null
	is_falling_after_support = false
	# Detach from the player's hand and restore physics.
	prepare_to_throw()
	linear_velocity = direction.normalized() * force


func _physics_process(_delta: float) -> void:
	if freeze and has_hit:
		if is_instance_valid(supporting_spear):
			if not supporting_spear.has_method("has_stable_support"):
				fall_again()
			elif not supporting_spear.has_stable_support():
				fall_again()

		elif resting_on_world:
			if not is_instance_valid(supporting_body):
				fall_again()

	if has_been_thrown and not has_hit and not is_falling_after_support:
		if linear_velocity.length() > 0.1:
			look_at(global_position + linear_velocity, Vector3.UP)
			
func on_picked_up() -> void:
	# This spear is no longer supporting other spears.
	resting_on_world = false
	supporting_spear = null
	has_hit = false
	has_been_thrown = false
	is_falling_after_support = false
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
		return is_instance_valid(supporting_body)

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
	supporting_body = null

	# Allow the spear to rotate naturally as it falls.
	is_falling_after_support = true

	# Give it a small downward movement so it separates
	# from the spear or surface that was supporting it.
	linear_velocity = Vector3.DOWN * 0.5
	angular_velocity = Vector3.ZERO
func settle_spear() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	sleeping = true


func _on_body_entered(body: Node3D) -> void:
	if body == self or body.is_in_group("Player"):
		return

	if not has_been_thrown or has_hit:
		return

	# Let the tip detector handle valid spear-on-spear hits.
	if body.is_in_group("Spear"):
		return

	# Backup: stop on a world surface if the tip missed it.
	if body is StaticBody3D or body is AnimatableBody3D:
		print("MAIN BODY HIT WORLD: ", body.name)

		supporting_body = body
		supporting_spear = null
		resting_on_world = true
		has_hit = true
		settle_spear()


func _on_pickuparea_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.add_nearby_item(self)


func _on_pickuparea_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.remove_nearby_item(self)


func _on_tip_body_entered(body: Node3D) -> void:
	print("TIP HIT: ", body.name)
	# Ignore the player.
	if body == self or body.is_in_group("Player"):
		return

	if not has_been_thrown or has_hit:
		return

	# Only stick to a spear that already has stable support.
	if body.is_in_group("Spear") and body is RigidBody3D:
		supporting_spear = body as RigidBody3D
		supporting_body = null
		resting_on_world = false
		#if not body.has_method("has_stable_support"):
			#return
#
		#if not body.has_stable_support():
			#return
		#has_hit = true
#
		#settle_spear()
		#return

	# Stick to world surfaces.
	elif body is StaticBody3D or body is AnimatableBody3D:
		print("YO")
		supporting_body = body
		supporting_spear = null
		resting_on_world = true
		#has_hit = true
		#settle_spear()
		#return

	# Damage NPCs without treating them as stable support.
	else:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		else:
			return
		supporting_body = null
		supporting_spear = null
		resting_on_world = false
	has_hit = true
	settle_spear()
