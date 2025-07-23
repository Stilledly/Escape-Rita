extends StaticBody3D

@onready var area: Area3D = $Area3D
@onready var interaction_prompt: Label3D = $InteractionPrompt

var player_nearby: bool = false
var emerald_spawned: bool = false

# Emerald spawn locations (random positions around the map)
var emerald_spawn_points: Array[Vector3] = [
    Vector3(0, 13, 0)
]

func _ready():
    area.body_entered.connect(_on_area_entered)
    area.body_exited.connect(_on_area_exited)
    interaction_prompt.visible = false

func _on_area_entered(body):
    if body.is_in_group("player"):
        player_nearby = true
        if body.has_emerald:
            interaction_prompt.text = "Press E to offer emerald"
        else:
            interaction_prompt.text = "Press E to offer flowers"
        interaction_prompt.visible = true

func _on_area_exited(body):
    if body.is_in_group("player"):
        player_nearby = false
        interaction_prompt.visible = false

func interact(player):
    if player.has_emerald:
        if player.give_emerald_to_fox():
            get_tree().change_scene_to_file("res://Escape-Rita/Scenes/MainMenu.tscn")
    else:
        var flowers_dispensed = player.dispense_flowers_to_fox()
        
        if flowers_dispensed and not emerald_spawned:
            spawn_emerald()

func spawn_emerald():
    emerald_spawned = true
    
    # Choose random spawn point
    var spawn_point = emerald_spawn_points[randi() % emerald_spawn_points.size()]
    
    # Load and instantiate emerald
    var emerald_scene = preload("res://Escape-Rita/Scenes/Emerald.tscn")
    var emerald_instance = emerald_scene.instantiate()
    
    # Add to scene
    get_tree().current_scene.add_child(emerald_instance)
    emerald_instance.global_position = spawn_point
