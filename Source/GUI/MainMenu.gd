extends Control;

@export var simulation_scene: PackedScene;
@onready var main_container: Panel = %MainContainer;
@onready var point_light_2d: PointLight2D = %PointLight2D
@onready var animator: AnimationPlayer = $Animator

var settings_menu: SettingsMenu = preload("res://Content/Levels/GUI/Settings.tscn").instantiate();


func _ready() -> void:
	settings_menu.back_button_down.connect(_on_settings_back);


func _process(delta: float) -> void:
	point_light_2d.global_position = get_global_mouse_position()


func _on_simulate_button_down() -> void:
	animator.play("fadeout")
	await animator.animation_finished
	get_tree().change_scene_to_packed(simulation_scene);


func _on_settings_button_down() -> void:
	remove_child(main_container)
	add_child(settings_menu)


func _on_exit_button_down() -> void:
	get_tree().quit();


func _on_settings_back() -> void:
	remove_child(settings_menu);
	add_child(main_container);
