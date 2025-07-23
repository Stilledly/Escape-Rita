extends Control

func _ready():
    $AspectRatioContainer/CenterContainer/VBoxContainer/Play.connect("pressed", Callable(self, "_on_play_pressed"))
    $AspectRatioContainer/CenterContainer/VBoxContainer/Settings.connect("pressed", Callable(self, "_on_settings_pressed"))
    $AspectRatioContainer/CenterContainer/VBoxContainer/Quit.connect("pressed", Callable(self, "_on_quit_pressed"))
    
func _on_play_pressed() -> void:
    get_tree().change_scene_to_file("res://Escape-Rita/Scenes/Main.tscn")

func _on_settings_pressed() -> void:
    get_tree().change_scene_to_file("res://Escape-Rita/Scenes/MainMenu.tscn")

func _on_quit_pressed() -> void:
    get_tree().quit()
