extends CharacterBody3D

# Player movement
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var sensitivity: float = 0.003

# Stamina system
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 25.0
@export var stamina_regen_rate: float = 15.0
var current_stamina: float = 100.0

# Game state
var flowers_collected: int = 0
var max_flowers: int = 7
var has_emerald: bool = false
var can_pick_emerald: bool = false

# UI references
@onready var flower_counter: Label = $UI/FlowerCounter
@onready var stamina_bar: ProgressBar = $UI/StaminaBar
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/FlashlightPivot/Flashlight
@onready var interaction_ray: RayCast3D = $Head/InteractionRay
@onready var footstep_timer: Timer = $FootstepTimer

# Audio
var footstep_sounds: Array[AudioStream] = []

func _ready():
    # Capture mouse
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    # Initialize UI
    update_flower_counter()
    update_stamina_bar()
    
    # Connect footstep timer
    footstep_timer.timeout.connect(_play_footstep)

func _input(event):
    # Mouse look
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        # Rotate head up/down
        head.rotate_x(-event.relative.y * sensitivity)
        head.rotation.x = clamp(head.rotation.x, -PI/2, PI/2)
        
        # Rotate body left/right
        rotate_y(-event.relative.x * sensitivity)
    
    # Toggle flashlight
    if Input.is_action_just_pressed("flashlight"):
        flashlight.visible = !flashlight.visible
    
    # Interaction
    if Input.is_action_just_pressed("interact"):
        try_interact()
    
    # Release mouse cursor
    if Input.is_action_just_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
    handle_movement(delta)
    handle_stamina(delta)
    update_stamina_bar()

func handle_movement(delta):
    # Add gravity
    if not is_on_floor():
        velocity += get_gravity() * delta
    
    # Handle jump
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
    
    # Get input direction
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    if direction:
        # Determine speed based on sprint input and stamina
        var is_sprinting = Input.is_action_pressed("sprint") and current_stamina > 0 and is_on_floor()
        var speed = sprint_speed if is_sprinting else walk_speed
        
        # Drain stamina when sprinting
        if is_sprinting:
            current_stamina = max(0, current_stamina - stamina_drain_rate * delta)
        
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        
        # Handle footsteps
        if is_on_floor() and footstep_timer.is_stopped():
            var step_interval = 0.6 if is_sprinting else 0.8
            footstep_timer.wait_time = step_interval
            footstep_timer.start()
    else:
        velocity.x = move_toward(velocity.x, 0, walk_speed)
        velocity.z = move_toward(velocity.z, 0, walk_speed)
        footstep_timer.stop()
    
    move_and_slide()

func handle_stamina(delta):
    # Regenerate stamina when not sprinting
    if not Input.is_action_pressed("sprint") or not is_on_floor():
        current_stamina = min(max_stamina, current_stamina + stamina_regen_rate * delta)

func try_interact():
    if interaction_ray.is_colliding():
        var collider = interaction_ray.get_collider()
        if collider.has_method("interact"):
            collider.interact(self)

func collect_flower():
    flowers_collected += 1
    update_flower_counter()
    print("Collected flower! (" + str(flowers_collected) + "/" + str(max_flowers) + ")")

func dispense_flowers_to_fox():
    print("Attempting to dispense flowers. Current count: ", flowers_collected, " Required: ", max_flowers)
    if flowers_collected >= max_flowers:
        print("Dispensed " + str(flowers_collected) + " flowers to the fox statue!")
        flowers_collected = 0
        update_flower_counter()
        return true
    else:
        print("You need " + str(max_flowers) + " flowers to offer to the fox statue. You have " + str(flowers_collected) + ".")
        return false

func pick_up_emerald():
    has_emerald = true
    print("You picked up the emerald! Return to the fox statue!")
    return true

func give_emerald_to_fox():
    if has_emerald:
        print("Victory! You escaped!")
        # Here you could load a victory scene or show victory UI
        get_tree().paused = true
        return true
    else:
        print("You need the emerald first!")
        return false

func update_flower_counter():
    flower_counter.text = "Flowers: " + str(flowers_collected) + "/" + str(max_flowers)

func update_stamina_bar():
    stamina_bar.value = current_stamina

func _play_footstep():
    # Play footstep sound (you can add audio files later)
    pass

# Called by monster when player is caught
func get_caught():
    print("You were caught! Game Over!")
    # Restart the scene or show game over screen
    get_tree().reload_current_scene()
