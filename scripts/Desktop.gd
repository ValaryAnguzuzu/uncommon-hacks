extends Control

# Desktop is the fake computer screen.
#
# General behavior:
# - Dock asks for an app to open.
# - Desktop instances the matching window scene into WindowLayer.
# - If that app is already open, Desktop shows it and brings it to the front.
# - Close buttons hide windows for now, so reopening feels instant.
# - Later, WindowManager can absorb this logic if the system gets more complex.

const APP_RESUME := "resume"
const APP_WORK := "work"
const APP_PREP := "prep"
const APP_PROJECTS := "projects"
const APP_JOBS := "jobs"
const APP_INTERVIEW := "interview"

const WINDOW_OFFSET := Vector2(34, 28)

@onready var window_layer: Control = $WindowLayer
@onready var dock = $Dock

var open_windows: Dictionary = {}
var app_scenes := {
	APP_RESUME: preload("res://ResumeWindow.tscn"),
	APP_WORK: preload("res://WorkWindow.tscn"),
	APP_PREP: preload("res://InterviewPrepWindow.tscn"),
	APP_PROJECTS: preload("res://ProjectsWindow.tscn"),
	APP_JOBS: preload("res://JobBoardWindow.tscn"),
	APP_INTERVIEW: preload("res://InterviewWindow.tscn"),
}


func _ready() -> void:
	dock.open_app_requested.connect(open_app)


func open_app(app_id: String) -> void:
	if open_windows.has(app_id):
		_show_existing_window(app_id)
		return

	if not app_scenes.has(app_id):
		push_warning("No scene registered for app id: %s" % app_id)
		return

	var window: Control = app_scenes[app_id].instantiate()
	window_layer.add_child(window)
	window.position += WINDOW_OFFSET * open_windows.size()
	open_windows[app_id] = window

	_connect_close_button(window)
	_bring_to_front(window)


func _show_existing_window(app_id: String) -> void:
	var window: Control = open_windows[app_id]
	window.show()
	_bring_to_front(window)


func _bring_to_front(window: Control) -> void:
	window_layer.move_child(window, window_layer.get_child_count() - 1)


func _connect_close_button(window: Control) -> void:
	var close_button := window.find_child("CloseButton", true, false) as Button
	if close_button == null:
		return

	var close_callable := Callable(window, "hide")
	if not close_button.pressed.is_connected(close_callable):
		close_button.pressed.connect(close_callable)
