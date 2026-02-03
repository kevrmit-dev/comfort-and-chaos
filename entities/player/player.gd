extends CharacterBody3D

@export var speed: float = 4.0
@export var camera: Camera3D
@export var turn_speed: float = 10.0  # più alto = gira più veloce

# --- Interactor ---
var current_interactable: Area3D = null

# Cooldown (Timer)
@onready var interact_cooldown: Timer = $InteractCooldown
var can_interact: bool = true

# --- Movement State ---
enum MoveState { IDLE, WALK }
var move_state: MoveState = MoveState.IDLE


func _ready() -> void:
	print("PLAYER SCRIPT LOADED:", get_path())

	# Sicurezza: evita loop se per sbaglio non è one_shot
	if interact_cooldown != null:
		interact_cooldown.one_shot = true


func _set_move_state(new_state: MoveState) -> void:
	if move_state == new_state:
		return

	move_state = new_state
	print("STATE =", "IDLE" if move_state == MoveState.IDLE else "WALK")


func _physics_process(delta: float) -> void:
	if camera == null:
		return

	var input_2d := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	if input_2d == Vector2.ZERO:
		_set_move_state(MoveState.IDLE)

		velocity.x = 0
		velocity.z = 0
		move_and_slide()
	else:
		_set_move_state(MoveState.WALK)

		var cam_basis := camera.global_transform.basis

		var forward := cam_basis.z
		var right := cam_basis.x

		forward.y = 0
		right.y = 0

		forward = forward.normalized()
		right = right.normalized()

		var direction := (right * input_2d.x + forward * input_2d.y).normalized()

		# Movimento
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		move_and_slide()

		# Rotazione Y verso direction (smooth)
		var target_yaw := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

	# --- INTERACT (cooldown 0.3s via Timer + flag) ---
	if Input.is_action_just_pressed("interact"):
		if not can_interact:
			return

		can_interact = false

		if interact_cooldown != null:
			interact_cooldown.start(0.3)

		print("INTERACT da:", get_path())
		print("current_interactable =", current_interactable)

		if current_interactable != null:
			print("INTERACT con:", current_interactable.name)

			var area := current_interactable
			var owner_node := area.get_parent()

			if area.has_method("interact"):
				area.call("interact", self)
			elif owner_node != null and owner_node.has_method("interact"):
				owner_node.call("interact", self)
		else:
			print("INTERACT: nessun oggetto")


# =========================
# TIMER SIGNAL
# =========================

func _on_InteractCooldown_timeout() -> void:
	can_interact = true


# =========================
# INTERACTOR SIGNALS
# =========================

func _on_Interactor_area_entered(area: Area3D) -> void:
	current_interactable = area
	print("Interactor: entrato in ", area.name)


func _on_Interactor_area_exited(area: Area3D) -> void:
	if current_interactable == area:
		current_interactable = null
		print("Interactor: uscito da ", area.name)
