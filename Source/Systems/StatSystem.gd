extends Label


func _process(_delta : float):
	var fps : int = floori(Engine.get_frames_per_second());
	var chunks_gen : int = $"/root/Main/TerrainGeneratorManager".chunks_generated;
	set_text("FPS: %d \n Chunks Generated: %d" % [fps, chunks_gen]);
