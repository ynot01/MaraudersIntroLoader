extends FileDialog

func _on_about_to_popup():
	current_dir = OS.get_system_dir(OS.SYSTEM_DIR_MOVIES)
