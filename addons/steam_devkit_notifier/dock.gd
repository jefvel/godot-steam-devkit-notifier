@tool
extends Control

const CONFIG_FILE = "user://devkit.cfg"
const NOTIFICATION_URL = "http://127.0.0.1:32010/post_event"

@export_category("References")
@export var title_name_path: NodePath
@export var auto_upload_switch_path: NodePath
@export var request_path: NodePath

@onready var title_name = get_node(title_name_path) as LineEdit
@onready var auto_upload_switch = get_node(auto_upload_switch_path) as CheckButton
@onready var request = get_node(request_path) as HTTPRequest

func _ready():
	init_signals()
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE)
	if err == OK:
		title_name.text = config.get_value("dock", "title_name")
		auto_upload_switch.button_pressed = config.get_value("dock", "auto_upload")

func init_signals():
	if DevkitMessenger.devkit_export_ended.is_connected(_on_notify_devkit) == false:
		DevkitMessenger.devkit_export_ended.connect(_on_notify_devkit)
	if request.request_completed.is_connected(_on_request_completed) == false:
		request.request_completed.connect(_on_request_completed)

func _exit_tree():
	if DevkitMessenger.devkit_export_ended.is_connected(_on_notify_devkit):
		DevkitMessenger.devkit_export_ended.disconnect(_on_notify_devkit)
	if request.request_completed.is_connected(_on_request_completed):
		request.request_completed.disconnect(_on_request_completed)

# HTTP Request
func send_notification():
	var json_body = JSON.stringify({
		"type": "build",
		"status": "success",
		"name": title_name.text
	})

	request.request(
		NOTIFICATION_URL,
		[
			"Content-Type: application/json"
		],
		HTTPClient.METHOD_POST,
		json_body
	)

# Signals
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		print("Notification send!")
	else:
		print("Notification failed!")

func _on_notify_devkit():
	if auto_upload_switch.button_pressed == true:
		send_notification()

func _on_send_button_pressed():
	send_notification()

func _on_save_button_pressed():
	var config = ConfigFile.new()
	config.set_value("dock", "title_name", title_name.text)
	config.set_value("dock", "auto_upload", auto_upload_switch.button_pressed)
	config.save(CONFIG_FILE)