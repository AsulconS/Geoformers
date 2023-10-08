extends Control

@export var terrain_generator: TerrainGeneratorManager
@onready var stats: Label = %stats
@onready var config_btn: Button = %config_btn

var config_menu: SettingsMenu = preload("res://Content/Levels/GUI/Settings.tscn").instantiate()

func _ready() -> void:
	config_menu.back_button_down.connect(_on_config_back)

func _process(delta: float) -> void:
	var fps : int = floori(Engine.get_frames_per_second());
	var chunks_gen : int = terrain_generator.chunks_generated;
	stats.set_text("FPS: %d \n Chunks Generated: %d" % [fps, chunks_gen]);


func _on_config_btn_button_down() -> void:
	add_child(config_menu)
	
func _on_config_back():
	remove_child(config_menu)
