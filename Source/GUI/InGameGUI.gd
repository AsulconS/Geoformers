extends Control;

@export var terrain_generator: TerrainGeneratorManager;
@onready var stats: Label = %stats;
@onready var config_btn: Button = %config_btn;
@onready var config_animator: AnimationPlayer = %ConfigAnimator

var config_menu: SettingsMenu = preload("res://Content/Levels/GUI/Settings.tscn").instantiate();


func _ready() -> void:
	config_menu.back_button_down.connect(_on_config_back);


func _process(_delta: float) -> void:
	var fps : int = floori(Engine.get_frames_per_second());
	var chunks_gen : int = terrain_generator.chunks_generated;
	var render_distance : int = terrain_generator.chunk_render_distance;
	stats.set_text("FPS: %d \n Chunks Generated: %d \n Render Distance: %d" % [fps, chunks_gen, render_distance]);


func _on_config_btn_button_down() -> void:
	add_child(config_menu);


func _on_config_back() -> void:
	remove_child(config_menu);
	config_animator.play_backwards("hover_config")

func _on_config_btn_mouse_entered() -> void:
	config_animator.play("hover_config")


func _on_config_btn_mouse_exited() -> void:
	if config_menu.is_inside_tree():
		return
	config_animator.play_backwards("hover_config")
