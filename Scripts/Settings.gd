extends Resource
class_name Settings

@export var meter_scale:float = 2.0
@export var meter_max:int = 1000 ## Meter capacity in mL
@export var meter_decay_rate:float = 0.28 ## Meter decay in mL per second. Set to 0 to disable.
@export var meter_controls:Array[Dictionary] = [
	{
		input_name = "plus5",
		keycode = KEY_KP_9,
		shift_held = false,
		ctrl_held = false,
		alt_held = false,
		amount_to_add = +5
	},
	{
		input_name = "minus5",
		keycode = KEY_KP_7,
		shift_held = false,
		ctrl_held = false,
		alt_held = false,
		amount_to_add = -5
	},
	{
		input_name = "plus25",
		keycode = KEY_KP_9,
		shift_held = true,
		ctrl_held = false,
		alt_held = false,
		amount_to_add = +25
	},
	{
		input_name = "minus25",
		keycode = KEY_KP_7,
		shift_held = true,
		ctrl_held = false,
		alt_held = false,
		amount_to_add = -25
	},]

@export var program_max_fps:int = 30
@export var program_resolution:= Vector2i(416,80)
@export var program_background_color_hex:String = "#00FF00"

@export_file("*.png","*.jpg") var empty_name
