extends StaticBody3D

@onready var area: Area3D = $Area3D
@onready var interaction_prompt: Label3D = $InteractionPrompt

var player_nearby: bool = false
var emerald_spawned: bool = false

# Emerald spawn locations (random positions around the map)
var emerald_spawn_points: Array[Vector3] = [
    Vector3(15, 1.5, -15),
    Vector3(-15, 1.5, 15),
    Vector3(20, 1.5, 5),
    Vector3(-10, 1.5, -20),
    Vector3(5, 1.5, 20),
    Vector3(-20, 1.5, -5),
    Vector3(18, 1.5, 18),
    Vector3(-18, 1.5, -18)
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
    print("Fox statue interaction - Player has emerald: ", player.has_emerald, " Flowers: ", player.flowers_collected)
    
    if player.has_emerald:
        # Player has emerald, complete the game
        if player.give_emerald_to_fox():
            interaction_prompt.text = "Victory! You escaped!"
            await get_tree().create_timer(2.0).timeout
            print("Game completed! Restarting...")
            get_tree().reload_current_scene()
    else:
        # Player wants to dispense flowers
        var flowers_dispensed = player.dispense_flowers_to_fox()
        print("Flowers dispensed: ", flowers_dispensed, " Emerald already spawned: ", emerald_spawned)
        
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
    
    print("The emerald has appeared somewhere on the map! Find it!")
    interaction_prompt.text = "Find the emerald!"
