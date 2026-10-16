extends SceneTree
## Captures a rendered frame of VectorGameTable to dev/vector_table_v1.png for visual QA inspection.

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var table_scene = load("res://ui/vector_table/VectorGameTable.tscn")
	if table_scene == null:
		push_error("Failed to load VectorGameTable.tscn")
		quit(1)
		return

	var table = table_scene.instantiate()
	root.add_child(table)

	# Run several frames so layout, fonts, and springs settle
	for _i in range(12):
		await process_frame

	await RenderingServer.frame_post_draw

	var img: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("dev")
	var err := img.save_png("dev/vector_table_v1.png")
	print("VECTOR_CAPTURE saved to dev/vector_table_v1.png err=", err)

	table.queue_free()
	for _i in range(2):
		await process_frame
	quit(0 if err == OK else 1)
