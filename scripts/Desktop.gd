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
const JOBS_PATH := "res://data/jobs.json"

@onready var window_layer: Control = $WindowLayer
@onready var dock = $Dock
@onready var toast_layer: Control = $ToastLayer

var open_windows: Dictionary = {}
var jobs_by_id: Dictionary = {}
var toast_scene := preload("res://ToastNotification.tscn")
var app_scenes := {
	APP_RESUME: preload("res://ResumeWindow.tscn"),
	APP_WORK: preload("res://WorkWindow.tscn"),
	APP_PREP: preload("res://InterviewPrepWindow.tscn"),
	APP_PROJECTS: preload("res://ProjectsWindow.tscn"),
	APP_JOBS: preload("res://JobBoardWindow.tscn"),
	APP_INTERVIEW: preload("res://InterviewWindow.tscn"),
}


func _ready() -> void:
	_load_jobs()
	dock.open_app_requested.connect(open_app)

	var unlock_callable := Callable(self, "_on_interview_unlocked")
	if not PlayerState.interview_unlocked.is_connected(unlock_callable):
		PlayerState.interview_unlocked.connect(unlock_callable)


func open_app(app_id: String) -> void:
	if app_id == APP_INTERVIEW:
		PlayerState.acknowledge_interview_alerts()

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


func _load_jobs() -> void:
	var file := FileAccess.open(JOBS_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not load jobs for desktop notifications: %s" % JOBS_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("Job data must be an array for desktop notifications.")
		return

	for job in parsed:
		if typeof(job) != TYPE_DICTIONARY:
			continue

		var job_id := str(job.get("id", ""))
		if job_id != "":
			jobs_by_id[job_id] = job


func _on_interview_unlocked(job_id: String) -> void:
	var job: Dictionary = jobs_by_id.get(job_id, {})
	var company := str(job.get("company", "Recruiter"))
	var title := str(job.get("title", "Interview"))
	show_toast("New interview request", "%s wants to interview you for %s." % [company, title])


func show_toast(title: String, message: String) -> void:
	var toast := toast_scene.instantiate() as Control
	var toast_index := toast_layer.get_child_count()
	toast_layer.add_child(toast)
	toast.position = Vector2(920, 64 + toast_index * 68)

	var icon_label := toast.find_child("IconLabel", true, false) as Label
	var message_label := toast.find_child("MessageLabel", true, false) as Label

	if icon_label != null:
		icon_label.text = "i"

	if message_label != null:
		message_label.text = "%s\n%s" % [title, message]

	toast.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(toast, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.tween_interval(3.2)
	tween.tween_property(toast, "modulate", Color(1, 1, 1, 0), 0.24)
	tween.tween_callback(toast.queue_free)
