extends CharacterBody3D

enum State {
    PATROLLING,
    CHASING,
    SEARCHING,
    INVESTIGATING
}

# Monster properties
@export var patrol_speed: float = 2.0
@export var chase_speed: float = 5.0
@export var search_speed: float = 3.0
@export var detection_range: float = 50.0
@export var vision_angle: float = 180.0
@export var hearing_range: float = 8.0

# State management
var current_state: State = State.PATROLLING
var player: CharacterBody3D
var last_known_player_position: Vector3
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var search_timer: float = 0.0
var max_search_time: float = 10.0

# Navigation
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var vision_ray: RayCast3D = $VisionRay
@onready var detection_area: Area3D = $PlayerDetectionArea
@onready var patrol_timer: Timer = $PatrolTimer
@onready var chase_timer: Timer = $ChaseTimer
@onready var lose_player_timer: Timer = $LosePlayerTimer
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var eyes: Node3D = $Eyes

func _ready():
    # Find player
    player = get_tree().get_first_node_in_group("player")
    if not player:
        push_error("No player found! Make sure to add player to 'player' group.")
    
    # Set up patrol points (you can customize these)
    setup_patrol_points()
    
    # Connect signals
    detection_area.body_entered.connect(_on_body_entered)
    detection_area.body_exited.connect(_on_body_exited)
    patrol_timer.timeout.connect(_on_patrol_timer_timeout)
    chase_timer.timeout.connect(_on_chase_timer_timeout)
    lose_player_timer.timeout.connect(_on_lose_player_timer_timeout)
    
    # Start patrolling
    set_next_patrol_target()

func _physics_process(delta):
    handle_state(delta)
    handle_movement(delta)
    update_vision_direction()

func handle_state(delta):
    match current_state:
        State.PATROLLING:
            handle_patrolling(delta)
        State.CHASING:
            handle_chasing(delta)
        State.SEARCHING:
            handle_searching(delta)
        State.INVESTIGATING:
            handle_investigating(delta)

func handle_patrolling(delta):
    # Check if reached patrol point
    if nav_agent.is_navigation_finished():
        patrol_timer.start()
    
    # Always check for player in vision and hearing range
    if can_see_player():
        print("Monster can see player - starting chase!")
        start_chasing()
    elif player and global_position.distance_to(player.global_position) < hearing_range:
        # Investigate if player is close (heard movement)
        print("Monster heard player - investigating!")
        start_investigating(player.global_position)

func handle_chasing(delta):
    if player:
        # Simplified direct movement toward player
        var direction_to_player = (player.global_position - global_position).normalized()
        
        # Set velocity directly toward player
        velocity.x = direction_to_player.x * chase_speed
        velocity.z = direction_to_player.z * chase_speed
        
        # Face the player
        look_at(player.global_position, Vector3.UP)
        
        print("Direct chase - Direction: ", direction_to_player, " Velocity: ", velocity)
        
        # Also update nav agent target for future use
        nav_agent.target_position = player.global_position
        last_known_player_position = player.global_position
        
        # Check if can see player
        if can_see_player():
            lose_player_timer.start()
        
        # Check if caught player
        if global_position.distance_to(player.global_position) < 2.0:
            catch_player()
    
    # If haven't seen player in a while, start searching
    if lose_player_timer.is_stopped():
        start_searching()

func handle_searching(delta):
    search_timer += delta
    
    # Search around last known position
    if nav_agent.is_navigation_finished():
        # Pick a random search point around last known position
        var random_offset = Vector3(
            randf_range(-8, 8),
            0,
            randf_range(-8, 8)
        )
        nav_agent.target_position = last_known_player_position + random_offset
    
    # Check if found player again
    if can_see_player():
        start_chasing()
    
    # Also check distance - if close to player, start chasing even without vision
    if player and global_position.distance_to(player.global_position) < 5.0:
        start_chasing()
    
    # Give up searching after max time
    if search_timer >= max_search_time:
        start_patrolling()

func handle_investigating(delta):
    # Move to investigation point
    if nav_agent.is_navigation_finished():
        # Look around for a bit then return to patrolling
        await get_tree().create_timer(2.0).timeout
        start_patrolling()
    
    # Check if found player
    if can_see_player():
        start_chasing()

func handle_movement(delta):
    # Add gravity
    if not is_on_floor():
        velocity += get_gravity() * delta
    
    # For chasing, we set velocity directly in handle_chasing
    # For other states, use navigation
    if current_state != State.CHASING:
        if not nav_agent.is_navigation_finished():
            # Get movement direction
            var next_location = nav_agent.get_next_path_position()
            var direction = (next_location - global_position).normalized()
            
            # Set speed based on state
            var speed = patrol_speed
            match current_state:
                State.SEARCHING:
                    speed = search_speed
                State.INVESTIGATING:
                    speed = search_speed
            
            velocity.x = direction.x * speed
            velocity.z = direction.z * speed
            
            # Rotate to face movement direction
            if direction.length() > 0:
                look_at(global_position + direction, Vector3.UP)
        else:
            velocity.x = move_toward(velocity.x, 0, patrol_speed)
            velocity.z = move_toward(velocity.z, 0, patrol_speed)
    
    move_and_slide()

func can_see_player() -> bool:
    if not player:
        return false
    
    var distance_to_player = global_position.distance_to(player.global_position)
    if distance_to_player > detection_range:
        return false
    
    # Check if player is in vision cone
    var direction_to_player = (player.global_position - global_position).normalized()
    var forward_direction = -transform.basis.z.normalized()
    var angle = rad_to_deg(forward_direction.angle_to(direction_to_player))
    
    if angle > vision_angle / 2:
        return false
    
    # Raycast to check for obstacles
    vision_ray.target_position = to_local(player.global_position)
    vision_ray.force_raycast_update()
    
    if vision_ray.is_colliding():
        var collider = vision_ray.get_collider()
        return collider == player
    
    return true

func start_chasing():
    if current_state != State.CHASING:
        current_state = State.CHASING
        chase_timer.start()
        patrol_timer.stop()
        lose_player_timer.start()
        print("Monster started chasing!")
        
        # Immediately set target to player position
        if player:
            nav_agent.target_position = player.global_position
        print("Monster started chasing!")

func start_searching():
    current_state = State.SEARCHING
    search_timer = 0.0
    chase_timer.stop()
    lose_player_timer.stop()
    print("Monster lost player, searching...")

func start_patrolling():
    current_state = State.PATROLLING
    search_timer = 0.0
    chase_timer.stop()
    lose_player_timer.stop()
    set_next_patrol_target()
    print("Monster returned to patrolling")

func start_investigating(position: Vector3):
    current_state = State.INVESTIGATING
    nav_agent.target_position = position
    patrol_timer.stop()
    print("Monster investigating sound at: ", position)

func catch_player():
    if player and player.has_method("get_caught"):
        player.get_caught()

func setup_patrol_points():
    # Default patrol points - you can customize these based on your level
    patrol_points = [
        Vector3(0, 0, 0),
        Vector3(10, 0, 0),
        Vector3(10, 0, 10),
        Vector3(0, 0, 10),
        Vector3(-10, 0, 10),
        Vector3(-10, 0, 0),
        Vector3(-10, 0, -10),
        Vector3(0, 0, -10)
    ]

func set_next_patrol_target():
    if patrol_points.size() > 0:
        nav_agent.target_position = patrol_points[current_patrol_index]
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func update_vision_direction():
    # Make eyes look in movement direction
    if velocity.length() > 0.1:
        var look_direction = velocity.normalized()
        eyes.look_at(global_position + look_direction, Vector3.UP)

func _on_body_entered(body):
    if body == player:
        print("Player entered detection area")

func _on_body_exited(body):
    if body == player:
        print("Player exited detection area")

func _on_patrol_timer_timeout():
    set_next_patrol_target()

func _on_chase_timer_timeout():
    # Update chase target frequently
    if player and current_state == State.CHASING:
        nav_agent.target_position = player.global_position

func _on_lose_player_timer_timeout():
    if current_state == State.CHASING and not can_see_player():
        start_searching()

# Called when player makes noise (footsteps, etc.)
func hear_sound(sound_position: Vector3):
    var distance = global_position.distance_to(sound_position)
    if distance <= hearing_range:
        if current_state == State.PATROLLING:
            start_investigating(sound_position)
