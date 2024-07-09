extends Control

var base_dir:= OS.get_executable_path().get_base_dir()
var settings_path:String = str(base_dir, "/Settings.cfg")

var decay_timer:float = 0.0
var settings:= get_settings()
var playing_shake:bool = false
var inputs:Array[StringName] = []

@onready var bar = $Inner
@onready var stream_player = $Sound

@onready var meter:Texture = load("res://Sprites/meter_progress.png")
@onready var under:Texture = load("res://Sprites/meter_under.png")
@onready var over:Texture = load("res://Sprites/meter_over.png")
@onready var sound:AudioStream = load("res://Audio/failed.ogg")

# Called when the node enters the scene tree for the first time.
func _ready():
	#-- Set up input map
	for i:Dictionary in settings.meter_controls:
		var event:= InputEventKey.new()
		GDScript.new()
		event.physical_keycode = OS.find_keycode_from_string(i.keycode)
		event.shift_pressed = i.shift_held
		event.ctrl_pressed = i.ctrl_held
		event.alt_pressed = i.alt_held
		InputMap.add_action(i.input_name)
		InputMap.action_add_event(i.input_name,event)
		inputs.append(i.input_name)
		print(event.as_text_physical_keycode())
	get_node("/root/GlobalInput/GlobalInputCSharp").InitializeActionDictionary()
	
	#-- Custom files
	const textures = {
		"meter_progress_sprite" : &"meter",
		"meter_under_sprite" : &"under",
		"meter_over_sprite" : &"over"}
	
	# Overwrite default texture values for valid files
	for i in textures.keys():
		var path = str(base_dir,settings.get(i))
		print(path)
		if FileAccess.file_exists(path) and load_external_texture(path):
			set(textures.get(i),load_external_texture(path));
	
	# Overwrite default value for audio file
	var audio_path = str(base_dir,settings.get("meter_full_sfx"))
	if FileAccess.file_exists(audio_path) and load_external_stream(audio_path):
		sound = load_external_stream(audio_path)
	
	# Set textures
	bar.texture_over = over
	bar.texture_under = under
	bar.texture_progress = meter
	stream_player.stream = sound
	
	#-- Meter Settings
	bar.max_value = settings.meter_max
	scale = Vector2(settings.meter_scale,settings.meter_scale)
	bar.texture_progress_offset = settings.meter_inner_offset
	
	#-- Program Settings
	ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color",Color.html(settings.program_background_color_hex))
	ProjectSettings.set_setting("application/run/max_fps",settings.program_max_fps)
	DisplayServer.window_set_size(settings.program_resolution)
	center_window()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#-- Meter decay
	var rate = settings.meter_decay_rate
	if rate > 0.0:
		decay_timer += _delta
		while decay_timer > 1:
			decay_timer -= 1;
			bar.value -= rate
	
	#-- Input check
	for i in inputs.size():
		if GlobalInput.is_action_just_pressed(inputs[i]):
			meter_add(settings.meter_controls[i].amount_to_add)
	
	#-- Center in window
	global_position = get_window().size * .5


func get_settings() -> Dictionary:
	# I really cant just get all the values as a dictionary man wtf
	const properties:= {
		"Meter" : [
			"meter_sound_muted",
			"meter_full_sound_volume",
			"meter_shake_magnitude",
			"meter_shake_speed",
			"meter_shake_amount",
			"meter_scale",
			"meter_inner_offset",
			"meter_max",
			"meter_decay_rate",
			"meter_controls",],
		"Program" : [
			"program_max_fps",
			"program_resolution",
			"program_background_color_hex",],
		"Customization" : [
			"meter_progress_sprite",
			"meter_under_sprite",
			"meter_over_sprite",
			"meter_full_sfx"],}
	
	var cfg:ConfigFile
	var dict = {}
	
	# Load ConfigFile at settings_path or create new
	if !FileAccess.file_exists(settings_path):
		cfg = create_config()
	else:
		cfg = ConfigFile.new() 
		var err:Error = cfg.load(settings_path)
		if err != OK:
			get_tree().quit()
	
	# Add config values to a dictionary, return dictionary
	for section in properties.keys():
		for key in properties.get(section):
			dict[key] = cfg.get_value(section,key)
	return dict

## thanks u/mrcdk (I stole this from them)
func center_window() -> void:
	var window = get_window()
	var screen = window.current_screen
	var screen_rect = DisplayServer.screen_get_usable_rect(screen)
	var window_size = window.get_size_with_decorations()
	window.position = screen_rect.position + (screen_rect.size / 2 - window_size / 2)

func create_config() -> ConfigFile:
	print("d")
	const sections = ["Meter","Program","Customization"]
	const property_meter:= {
		meter_sound_muted = false,
		meter_full_sound_volume = 0,
		meter_shake_magnitude = 1.0,
		meter_shake_speed = 0.95,
		meter_shake_amount = 2,
		meter_scale = 2.0,
		meter_inner_offset = Vector2i(3,3),
		meter_max = 1000,
		meter_decay_rate = 0.28,
		meter_controls = [
			{
				input_name = "plus5",
				keycode = "Kp 6",
				shift_held = false,
				ctrl_held = false,
				alt_held = false,
				amount_to_add = +5
			},
			{
				input_name = "minus5",
				keycode = "Kp 4",
				shift_held = false,
				ctrl_held = false,
				alt_held = false,
				amount_to_add = -5
			},
			{
				input_name = "plus25",
				keycode = "Kp 9",
				shift_held = false,
				ctrl_held = false,
				alt_held = false,
				amount_to_add = +25
			},
			{
				input_name = "minus25",
				keycode = "Kp 7",
				shift_held = false,
				ctrl_held = false,
				alt_held = false,
				amount_to_add = -25
			},]}
	const property_program:= {
		program_max_fps = 30,
		program_resolution = Vector2i(416,80),
		program_background_color_hex = "#00FF00",}
	const property_customization:={
		meter_over_sprite = "/Sprites/meter_over.png",
		meter_progress_sprite = "/Sprites/meter_progress.png",
		meter_under_sprite = "/Sprites/meter_under.png",
		meter_full_sfx = "/Audio/full.ogg"}
	const list:= [property_meter,property_program,property_customization]
	
	var cfg = ConfigFile.new()
	for i in 3:
		for key in list[i]:
			cfg.set_value(sections[i],key,list[i].get(key))
	cfg.save(settings_path)
	print(settings_path)
	
	return cfg

# Yes id rather do this than use animationplayer nodes
# I just really dont like those. sorry. Not really.
func shake() -> void:
	var a:int = settings.meter_shake_amount
	var t:float = 1.01 - clampf(settings.meter_shake_speed,0.0,1.0)
	var m:float = settings.meter_shake_magnitude
	var initial:Vector2 = position
	if m <= 0:
		return
	
	playing_shake = true
	
	# Shake
	for i in a:
		@warning_ignore("confusable_local_declaration")
		var tween = create_tween()
		tween.tween_property(self,"position",Vector2(initial.x + m * (a - i),position.y),t)
		tween.play(); await(tween.finished); tween.stop()
		tween.tween_property(self,"position",Vector2(initial.x - m * (a - i),position.y),t)
		tween.play(); await(tween.finished); tween.stop()
	
	# Return to inital position
	var tween = create_tween()
	tween.tween_property(self,"position",initial,t)
	tween.play(); await(tween.finished)
	
	playing_shake = false

func meter_add(amt:int) -> void:
	if bar.value + amt > bar.max_value:
		if !playing_shake and settings.meter_shake_magnitude > 0:
			shake()
		if !settings.meter_sound_muted:
			stream_player.stop()
			stream_player.play()
	bar.value += amt

func load_external_texture(path) -> Texture:
	var texture = Image.new(); texture.load(path)
	return ImageTexture.create_from_image(texture)

func load_external_stream(path:String) -> AudioStream:
	var stream:AudioStream
	var ext = path.get_extension()
	
	match ext:
		"ogg":
			stream = AudioStreamOggVorbis.load_from_file(path)
		#region WAV & MP3 (broken)
		#-- This approach doesnt work i think the file headers are fucking it up
		#-- So for now I guess it only does ogg files :/
		#
		# Get bytes of file and write to AudioStreamWAV/MP3
		# Only Vorbis has the load_from_file() function >:(
		#"wav":
			#stream = AudioStreamWAV.new()
			#var wav = FileAccess.open(path,FileAccess.READ)
			#stream.data = wav.get_file_as_bytes(path)
			#
		#"mp3":
			#stream = AudioStreamMP3.new()
			#var mp3 = FileAccess.open(path,FileAccess.READ)
			#var data = mp3.get_buffer(mp3.get_length()).to_int64_array()
			#
			#for i in data: # subtract 128 to set to Signed PCM8
				#data[i] -= 128
			#stream.data = data
		#endregion
		_:
			return null
	
	return stream
