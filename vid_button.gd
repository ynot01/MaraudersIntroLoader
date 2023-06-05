extends ColorRect

var vid_path: String

func remove_self():
	var main = get_tree().root.get_child(0)
	main.videos.erase(vid_path)
	main.config.erase_section_key("videos", vid_path)
	main.config.save("user://marauders_loader.cfg")
	queue_free()

func _on_toggle_toggled(button_pressed):
	var main = get_tree().root.get_child(0)
	main.videos[vid_path] = button_pressed
	main.config.set_value("videos", vid_path, button_pressed)
	main.config.save("user://marauders_loader.cfg")

func _on_toggle_gui_input(event):
	if event.is_action_released("right_click") and $Toggle.is_hovered():
		OS.shell_open(vid_path.get_base_dir())
