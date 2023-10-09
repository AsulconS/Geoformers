class_name SettingsMenu;
extends Control;


signal back_button_down;

@onready var render_distance_slider: HSlider = %RenderDistanceSlider;
@onready var render_distance_label: Label = %RenderDistance;


func _ready() -> void:
	render_distance_label.text = str(render_distance_slider.value);


func _on_render_distance_slider_value_changed(value: float) -> void:
	render_distance_label.text = str(render_distance_slider.value);


func _on_save_button_down() -> void:
	GeneratorConfig.chunk_render_distance = render_distance_slider.value;
	emit_signal("back_button_down");


func _on_back_button_down() -> void:
	emit_signal("back_button_down");
