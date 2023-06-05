extends TextureRect

# videos[video_path] = checked
var videos = {}

@onready var vidButtonScene = load("res://vid_button.tscn")
@onready var config = ConfigFile.new()
func _ready() -> void:
	var err = config.load("user://marauders_loader.cfg")
	if err != OK:
		return
	
	if not config.has_section("videos"):
		return
	for vid_path in config.get_section_keys("videos"):
		if vid_path.is_absolute_path() and FileAccess.file_exists(vid_path):
			var is_on = config.get_value("videos", vid_path, false)
			videos[vid_path] = is_on
			var vid_button = vidButtonScene.instantiate()
			$VideoScroll/VideoContainer.add_child(vid_button)
			vid_button.get_node("Toggle").text = vid_path.get_basename().right(-vid_path.rfind("/")-1)
			vid_button.get_node("Toggle").button_pressed = is_on
			vid_button.vid_path = vid_path
			vid_button.get_node("Remove").pressed.connect(vid_button.remove_self, CONNECT_ONE_SHOT)
		else:
			config.erase_section_key("videos", vid_path)

func _on_import_pressed():
	$ImportVideos.popup_centered(Vector2i(700,500))

func _on_import_videos_files_selected(paths):
	for vid_path in paths:
		if videos.has(vid_path):
			continue
		config.set_value("videos", vid_path, true)
		config.save("user://marauders_loader.cfg")
		videos[vid_path] = true
		var vid_button = vidButtonScene.instantiate()
		$VideoScroll/VideoContainer.add_child(vid_button)
		vid_button.get_node("Toggle").text = vid_path.get_basename().right(-vid_path.rfind("/")-1)
		vid_button.get_node("Toggle").button_pressed = true
		vid_button.vid_path = vid_path
		vid_button.get_node("Remove").pressed.connect(vid_button.remove_self, CONNECT_ONE_SHOT)

func _on_boot_pressed():
	if config.has_section("game"):
		call_deferred("run_game")
	else:
		$InfoFindGame.popup_centered(Vector2i(500,200))

func _on_confirmation_dialog_confirmed():
	$FindGame.popup_centered(Vector2i(700,500))

func _on_find_game_file_selected(path):
	config.set_value("game", "path", path)
	config.save("user://marauders_loader.cfg")
	call_deferred("run_game")

func validate_executable(path) -> bool:
	if path.get_extension() != "exe":
		return false
	var dir = DirAccess.open(path.get_base_dir()+"/RaidGame/Content/Movies/")
	if not dir or DirAccess.get_open_error() != OK:
		return false
	if not dir.file_exists("LoadingScreen.mp4") and not dir.file_exists("BackupLoadingScreen.mp4"):
		return false
	return true


func run_game():
	var game_path = config.get_value("game", "path")
	if game_path == null or not validate_executable(game_path):
		config.erase_section("game")
		$FalseGame.call_deferred("popup_centered", Vector2i(500,200))
		return
	# backup default loading screen
	var dir = DirAccess.open(game_path.get_base_dir()+"/RaidGame/Content/Movies/")
	if not dir.file_exists("BackupLoadingScreen.mp4"):
		var copy_err = DirAccess.copy_absolute(game_path.get_base_dir()+"/RaidGame/Content/Movies/LoadingScreen.mp4", game_path.get_base_dir()+"/RaidGame/Content/Movies/BackupLoadingScreen.mp4")
		if copy_err != OK:
			$FalseGame.call_deferred("popup_centered", Vector2i(500,200))
			return
	# select random video
	var selections: Array = []
	for video in videos:
		if videos[video]:
			selections.append(video)
	dir = DirAccess.open(game_path.get_base_dir()+"/RaidGame/Content/Movies/")
	if selections.is_empty() or selections[0] == "":
		# restore video to default
		var copy_err = DirAccess.copy_absolute(game_path.get_base_dir()+"/RaidGame/Content/Movies/BackupLoadingScreen.mp4", game_path.get_base_dir()+"/RaidGame/Content/Movies/LoadingScreen.mp4")
		if copy_err != OK:
			$FalseGame.call_deferred("popup_centered", Vector2i(500,200))
			return
	else:
		var selection = selections.pick_random()
		# begin placing selected video in place of the old one
		var copy_err = DirAccess.copy_absolute(selection, game_path.get_base_dir()+"/RaidGame/Content/Movies/LoadingScreen.mp4")
		if copy_err != OK:
			$FalseGame.call_deferred("popup_centered", Vector2i(500,200))
			return
	OS.shell_open("steam://rungameid/1789480") # Marauders gameid
	get_tree().quit()

func _on_label_gui_input(event):
	if event.is_action_released("right_click") and $Instructions/Label.get_local_mouse_position().y > 0:
		OS.shell_open(OS.get_user_data_dir())
