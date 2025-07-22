extends StaticBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var area: Area3D = $Area3D
@onready var light: SpotLight3D = $SpotLight3D

var is_collected: bool = false
var float_amplitude: float = 0.3
var float_speed: float = 2.0
var initial_position: Vector3

func _ready():
    initial_position = global_position
    area.body_entered.connect(_on_area_entered)

func _process(delta):
    if not is_collected:
        # Float animation
        global_position.y = initial_position.y + sin(Time.get_ticks_msec() * 0.001 * float_speed) * float_amplitude
        
        # Rotate
        rotate_y(delta * 2.0)

func _on_area_entered(body):
    print("Something entered flower area: ", body.name)
    if body.is_in_group("player") and not is_collected:
        print("Player entered flower area - collecting!")
        collect(body)

func collect(player):
    if is_collected:
        return
    
    is_collected = true
    player.collect_flower()
    
    # Play collection effect
    var tween = create_tween()
    tween.parallel().tween_property(self, "scale", Vector3.ZERO, 0.3)
    tween.parallel().tween_property(light, "light_energy", 0.0, 0.3)
    
    await tween.finished
    queue_free()

func interact(player):
    collect(player)
