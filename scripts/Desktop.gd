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
const APP_DISCOVER := "discover"
const APP_STATS := "stats"

const WINDOW_OFFSET := Vector2(34, 28)
const JOBS_PATH := "res://data/jobs.json"
const MESSAGES_PATH := "res://data/messages.json"
const WINDOW_MARGIN := Vector2(18, 18)
const TOP_BAR_HEIGHT := 76.0
const DOCK_HEIGHT := 104.0
const SCREEN_MARGIN := 18.0

@onready var window_layer: Control = $WindowLayer
@onready var desktop_icons: Control = $DesktopIcons
@onready var dock = $Dock
@onready var toast_layer: Control = $ToastLayer
@onready var feedback_layer: Control = $FeedbackLayer
@onready var clock_panel: PanelContainer = $ClockPanel
@onready var clock_timer_label: Label = $ClockPanel/ClockMargin/ClockStack/TimerLabel
@onready var clock_sub_label: Label = $ClockPanel/ClockMargin/ClockStack/TimerSubLabel
@onready var message_panel: PanelContainer = $MessagePanel
@onready var message_title_label: Label = $MessagePanel/MessageMargin/MessageStack/MessageTitleLabel
@onready var message_body_label: Label = $MessagePanel/MessageMargin/MessageStack/MessageBodyLabel

var open_windows: Dictionary = {}
var window_spawn_count: int = 0
var active_window: Control
var dragged_window: Control
var jobs_by_id: Dictionary = {}
var toast_scene := preload("res://ToastNotification.tscn")
var coin_texture := preload("res://assets/coins.png")
var last_state_snapshot: Dictionary = {}
var message_bank: Dictionary = {}
var current_message_category: String = ""
var message_tick_seconds: float = 0.0
var message_interval_seconds: float = 2.6
var recent_tip_categories: Array[String] = []
var app_scenes := {
	APP_RESUME: preload("res://ResumeWindow.tscn"),
	APP_WORK: preload("res://WorkWindow.tscn"),
	APP_PREP: preload("res://InterviewPrepWindow.tscn"),
	APP_PROJECTS: preload("res://ProjectsWindow.tscn"),
	APP_JOBS: preload("res://JobBoardWindow.tscn"),
	APP_INTERVIEW: preload("res://InterviewWindow.tscn"),
	APP_DISCOVER: preload("res://DiscoverStatementWindow.tscn"),
	APP_STATS: preload("res://TodayStatsWindow.tscn"),
}
var app_positions := {
	APP_RESUME: Vector2(28, 30),
	APP_WORK: Vector2(72, 62),
	APP_PREP: Vector2(96, 86),
	APP_PROJECTS: Vector2(34, 54),
	APP_JOBS: Vector2(54, 44),
	APP_INTERVIEW: Vector2(116, 76),
	APP_DISCOVER: Vector2(240, 42),
	APP_STATS: Vector2(188, 58),
}
var desktop_icon_data := [
	{"label": "resume.pdf", "app": APP_RESUME, "mark": "📄", "color": Color(0.88, 0.90, 0.92)},
	{"label": "today.txt", "app": APP_STATS, "mark": "📋", "color": Color(0.66, 0.84, 1.0)},
	{"label": "job board", "app": APP_JOBS, "mark": "💼", "color": Color(0.57, 0.78, 0.98)},
	{"label": "discover", "app": APP_DISCOVER, "mark": "💳", "color": Color(1.0, 0.84, 0.40)},
	{"label": "projects", "app": APP_PROJECTS, "mark": "⭐", "color": Color(0.96, 0.78, 0.28)},
	{"label": "prep lab", "app": APP_PREP, "mark": "📘", "color": Color(0.84, 0.72, 1.0)},
	{"label": "work", "app": APP_WORK, "mark": "📅", "color": Color(0.94, 0.76, 0.43)},
	{"label": "interview", "app": APP_INTERVIEW, "mark": "🎤", "color": Color(0.54, 0.94, 0.98)},
]


func _ready() -> void:
	_load_jobs()
	_load_messages()
	_build_desktop_icons()
	_style_clock_panel()
	_style_message_panel()
	_apply_responsive_layout()
	dock.open_app_requested.connect(open_app)
	if dock.has_signal("home_requested"):
		dock.connect("home_requested", Callable(self, "show_home"))
	if dock.has_signal("end_week_requested"):
		dock.connect("end_week_requested", Callable(self, "_on_end_week_requested"))

	last_state_snapshot = _make_state_snapshot()
	var state_callable := Callable(self, "_on_player_state_changed")
	if not PlayerState.state_changed.is_connected(state_callable):
		PlayerState.state_changed.connect(state_callable)

	var unlock_callable := Callable(self, "_on_interview_unlocked")
	if not PlayerState.interview_unlocked.is_connected(unlock_callable):
		PlayerState.interview_unlocked.connect(unlock_callable)

	var manager: Node = _game_manager()
	if manager != null:
		var week_callable := Callable(self, "_on_week_report")
		if not manager.is_connected("week_report", week_callable):
			manager.connect("week_report", week_callable)

		var game_over_callable := Callable(self, "_on_game_over")
		if not manager.is_connected("game_over", game_over_callable):
			manager.connect("game_over", game_over_callable)

	_set_dynamic_message("encouragement")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func _process(delta: float) -> void:
	if PlayerState.has_offer or PlayerState.has_lost:
		return

	message_tick_seconds += delta
	if message_tick_seconds < message_interval_seconds:
		return

	message_tick_seconds = 0.0
	_rotate_live_message()


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
	open_windows[app_id] = window
	_place_window(window, app_id)
	window_spawn_count += 1

	_connect_close_button(window)
	_connect_window_behavior(window)
	_sanitize_window_chrome(window)
	_bring_to_front(window)


func show_home() -> void:
	for window in open_windows.values():
		var control: Control = window as Control
		if control != null:
			control.hide()

	active_window = null
	_set_dynamic_message("encouragement")


func _on_end_week_requested() -> void:
	var manager: Node = _game_manager()
	if manager != null:
		manager.call("end_week")


func _show_existing_window(app_id: String) -> void:
	var window: Control = open_windows[app_id]
	window.show()
	_bring_to_front(window)


func _bring_to_front(window: Control) -> void:
	window_layer.move_child(window, window_layer.get_child_count() - 1)
	_set_active_window(window)


func _set_active_window(window: Control) -> void:
	active_window = window

	for child in window_layer.get_children():
		var child_window: Control = child as Control
		if child_window == null:
			continue

		child_window.modulate = Color(1, 1, 1, 1) if child_window == active_window else Color(0.86, 0.88, 0.92, 1)


func _place_window(window: Control, app_id: String) -> void:
	# Keep each app's authored size, but prevent ugly bottom-glued/offscreen spawns.
	var window_size: Vector2 = window.size
	if window_size == Vector2.ZERO:
		window_size = window.custom_minimum_size

	var base_position: Vector2 = app_positions.get(app_id, Vector2(80, 44)) as Vector2
	var stagger_index: int = floori(float(window_spawn_count) / 2.0) % 3
	var stagger: Vector2 = WINDOW_OFFSET * float(stagger_index)
	window.position = _clamp_window_position(base_position + stagger, window_size)


func _clamp_window_position(position: Vector2, window_size: Vector2) -> Vector2:
	var visible_size: Vector2 = window_layer.size
	var max_position: Vector2 = Vector2(
		max(WINDOW_MARGIN.x, visible_size.x - window_size.x - WINDOW_MARGIN.x),
		max(WINDOW_MARGIN.y, visible_size.y - window_size.y - WINDOW_MARGIN.y)
	)

	return Vector2(
		clampf(position.x, WINDOW_MARGIN.x, max_position.x),
		clampf(position.y, WINDOW_MARGIN.y, max_position.y)
	)


func _apply_responsive_layout() -> void:
	# The fake OS should survive resizing the embedded game window. The desktop
	# keeps desktop icons readable, windows clamped, and the right side free for
	# live encouragement/unlock messages.
	var viewport_size: Vector2 = size
	if viewport_size == Vector2.ZERO:
		return

	var show_message_panel: bool = viewport_size.x >= 980.0
	var message_width: float = clampf(viewport_size.x * 0.24, 280.0, 380.0) if show_message_panel else 0.0
	var workspace_right: float = viewport_size.x - SCREEN_MARGIN - message_width - (SCREEN_MARGIN if show_message_panel else 0.0)
	var workspace_bottom: float = viewport_size.y - DOCK_HEIGHT - SCREEN_MARGIN
	var workspace_width: float = maxf(280.0, workspace_right - SCREEN_MARGIN)
	var workspace_height: float = maxf(260.0, workspace_bottom - TOP_BAR_HEIGHT)

	_set_control_rect(window_layer, Vector2(SCREEN_MARGIN, TOP_BAR_HEIGHT), Vector2(workspace_width, workspace_height))
	_set_control_rect(desktop_icons, window_layer.position, window_layer.size)

	message_panel.visible = show_message_panel
	if show_message_panel:
		var message_x: float = viewport_size.x - message_width - SCREEN_MARGIN
		_set_control_rect(
			message_panel,
			Vector2(message_x, TOP_BAR_HEIGHT + 116.0),
			Vector2(message_width, 146.0)
		)

	var dock_width: float = minf(760.0, maxf(320.0, viewport_size.x - 2.0 * SCREEN_MARGIN))
	if viewport_size.x >= 1180.0:
		dock_width = minf(1100.0, viewport_size.x - 2.0 * SCREEN_MARGIN)

	_set_control_rect(
		dock,
		Vector2((viewport_size.x - dock_width) * 0.5, viewport_size.y - DOCK_HEIGHT),
		Vector2(dock_width, DOCK_HEIGHT - SCREEN_MARGIN)
	)

	var clock_width: float = 178.0
	var clock_x: float = viewport_size.x - clock_width - SCREEN_MARGIN

	_set_control_rect(
		clock_panel,
		Vector2(clock_x, TOP_BAR_HEIGHT + 10.0),
		Vector2(clock_width, 86.0)
	)

	_layout_desktop_icons()
	_reclamp_open_windows()
	_refresh_clock()


func _set_control_rect(control: Control, next_position: Vector2, next_size: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = next_position.x
	control.offset_top = next_position.y
	control.offset_right = next_position.x + next_size.x
	control.offset_bottom = next_position.y + next_size.y


func _reclamp_open_windows() -> void:
	for window in open_windows.values():
		var control: Control = window as Control
		if control == null:
			continue

		var window_size: Vector2 = control.size
		if window_size == Vector2.ZERO:
			window_size = control.custom_minimum_size

		control.position = _clamp_window_position(control.position, window_size)


func _build_desktop_icons() -> void:
	for child in desktop_icons.get_children():
		child.queue_free()

	for data in desktop_icon_data:
		var icon: VBoxContainer = _make_desktop_icon(data)
		desktop_icons.add_child(icon)


func _layout_desktop_icons() -> void:
	var icon_spacing: Vector2 = Vector2(104, 100)

	for index in range(desktop_icons.get_child_count()):
		var icon: Control = desktop_icons.get_child(index) as Control
		if icon == null:
			continue

		if index < 5:
			icon.position = Vector2(16, 18 + index * icon_spacing.y)
		else:
			icon.position = Vector2(120, 18 + (index - 5) * icon_spacing.y)


func _make_desktop_icon(data: Dictionary) -> VBoxContainer:
	var app_id: String = str(data.get("app", ""))
	var icon: VBoxContainer = VBoxContainer.new()
	icon.custom_minimum_size = Vector2(88, 88)
	icon.add_theme_constant_override("separation", 5)
	icon.mouse_filter = Control.MOUSE_FILTER_STOP

	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(66, 58)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.text = str(data.get("mark", "APP"))
	button.add_theme_font_size_override("font_size", 27)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	var icon_color: Color = data.get("color", Color(0.8, 0.85, 0.9)) as Color
	button.add_theme_stylebox_override("normal", _icon_style(icon_color))
	button.add_theme_stylebox_override("hover", _icon_style(Color(0.96, 0.98, 1.0)))
	button.add_theme_stylebox_override("pressed", _icon_style(Color(0.66, 0.74, 0.86)))
	button.pressed.connect(func(): open_app(app_id))

	var label: Label = Label.new()
	label.text = str(data.get("label", "app"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(88, 0)
	label.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0, 0.92))
	label.add_theme_font_size_override("font_size", 13)

	icon.add_child(button)
	icon.add_child(label)
	return icon


func _icon_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.13, 0.16, 0.20, 0.85)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	return style


func _style_clock_panel() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.018, 0.026, 0.84)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.22, 0.32, 0.44, 0.95)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	clock_panel.add_theme_stylebox_override("panel", panel_style)
	clock_sub_label.add_theme_color_override("font_color", Color(0.58, 0.68, 0.82, 1))


func _style_message_panel() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.015, 0.018, 0.026, 0.78)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(0.16, 0.30, 0.48, 0.95)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	message_panel.add_theme_stylebox_override("panel", panel_style)
	message_title_label.add_theme_color_override("font_color", Color(0.42, 0.64, 0.92, 1))
	message_body_label.add_theme_color_override("font_color", Color(0.76, 0.84, 0.95, 1))


func _refresh_clock() -> void:
	clock_timer_label.text = _format_timer(PlayerState.idle_seconds_left)
	clock_timer_label.add_theme_color_override("font_color", _timer_color())


func _format_timer(seconds_left: float) -> String:
	var total_seconds: int = ceili(seconds_left)
	var minutes: int = floori(float(total_seconds) / 60.0)
	var seconds: int = total_seconds % 60
	return "%02d:%02d" % [minutes, seconds]


func _timer_color() -> Color:
	if PlayerState.idle_seconds_left <= 10.0:
		return Color(1.0, 0.34, 0.30)

	if PlayerState.idle_seconds_left <= 25.0:
		return Color(1.0, 0.72, 0.28)

	return Color(0.45, 1.0, 0.72)


func _load_messages() -> void:
	var file := FileAccess.open(MESSAGES_PATH, FileAccess.READ)
	if file == null:
		message_bank = {}
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		message_bank = parsed as Dictionary


func _set_dynamic_message(category: String) -> void:
	var raw_messages: Variant = message_bank.get(category, [])
	var messages: Array = []
	if typeof(raw_messages) == TYPE_ARRAY:
		messages = raw_messages as Array

	if messages.is_empty():
		messages = ["Keep moving. One useful click can change the run."]

	var index: int = randi_range(0, messages.size() - 1)
	current_message_category = category
	message_title_label.text = "💡 TIPS"
	message_body_label.text = str(messages[index])

	message_panel.modulate = Color(1, 1, 1, 0.35)
	var tween: Tween = create_tween()
	tween.tween_property(message_panel, "modulate", Color(1, 1, 1, 1), 0.18)


func _rotate_live_message() -> void:
	_set_dynamic_message(_choose_tip_category())


func _choose_tip_category() -> String:
	# Tips should feel like the game is watching the whole run: money, burnout,
	# project proof, applications, interviews, remaining actions, and time.
	var urgent_categories: Array[String] = []
	var useful_categories: Array[String] = []

	if PlayerState.unlocked_interviews.size() > 0:
		urgent_categories.append("interview")

	if PlayerState.idle_seconds_left <= 18.0:
		urgent_categories.append("timer")

	if PlayerState.checking_balance < 120 or PlayerState.checking_balance < PlayerState.debt_minimum_payment:
		urgent_categories.append("low_money")

	if PlayerState.debt_active or PlayerState.debt > 1300:
		useful_categories.append("debt")

	if PlayerState.burnout >= 72:
		urgent_categories.append("high_burnout")
	elif PlayerState.burnout >= 50:
		useful_categories.append("high_burnout")

	if PlayerState.confidence <= 35:
		useful_categories.append("confidence")

	if PlayerState.action_points_remaining <= 0:
		urgent_categories.append("actions")
	elif PlayerState.completed_projects.is_empty() or PlayerState.resume_keywords.size() < 4:
		useful_categories.append("projects")

	if PlayerState.resume_keywords.size() >= 4 and PlayerState.applications_sent == 0:
		useful_categories.append("jobs")
	elif PlayerState.applications_sent > 0 and PlayerState.unlocked_interviews.is_empty():
		useful_categories.append("applications")

	if PlayerState.score > 0:
		useful_categories.append("score_gain")

	useful_categories.append("encouragement")

	var pool: Array[String] = useful_categories
	if not urgent_categories.is_empty():
		pool = urgent_categories

	return _pick_tip_category(pool)


func _pick_tip_category(pool: Array[String]) -> String:
	if pool.is_empty():
		return "encouragement"

	var filtered_pool: Array[String] = []
	for category in pool:
		if category not in recent_tip_categories:
			filtered_pool.append(category)

	if filtered_pool.is_empty():
		filtered_pool = pool.duplicate()

	var category: String = filtered_pool[randi_range(0, filtered_pool.size() - 1)]
	recent_tip_categories.append(category)
	while recent_tip_categories.size() > 3:
		recent_tip_categories.pop_front()

	return category


func _connect_close_button(window: Control) -> void:
	var close_button: Button = window.find_child("CloseButton", true, false) as Button
	if close_button == null:
		return

	# The colored window dot is the visible close affordance; hide duplicate Xs.
	close_button.visible = false

	var close_callable := Callable(window, "hide")
	if not close_button.pressed.is_connected(close_callable):
		close_button.pressed.connect(close_callable)


func _sanitize_window_chrome(window: Control) -> void:
	# Godot's default Button theme can draw symbols inside tiny mac-style dots.
	# Force the dots to be plain colored circles so the title bars look clean.
	_apply_dot_style(window.find_child("CloseDot", true, false), Color(0.96, 0.33, 0.28))
	_apply_dot_style(window.find_child("ZoomDot", true, false), Color(0.31, 0.78, 0.37))
	_apply_dot_style(window.find_child("MinimizeDot", true, false), Color(0.96, 0.74, 0.24))


func _apply_dot_style(node: Node, color: Color) -> void:
	var control: Control = node as Control
	if control == null:
		return

	control.custom_minimum_size = Vector2(14, 14)
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_right = 7
	style.corner_radius_bottom_left = 7

	if control is Button:
		var button: Button = control as Button
		button.text = ""
		button.icon = null
		button.flat = false
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	elif control is PanelContainer:
		control.add_theme_stylebox_override("panel", style)


func _connect_window_behavior(window: Control) -> void:
	# Make every app window act like a desktop window without requiring each
	# app script to duplicate drag/focus code.
	window.mouse_filter = Control.MOUSE_FILTER_STOP
	window.gui_input.connect(func(event: InputEvent): _on_window_gui_input(window, event))

	var title_bar: Control = window.find_child("TitleBar", true, false) as Control
	if title_bar == null:
		return

	title_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	title_bar.gui_input.connect(func(event: InputEvent): _on_title_bar_gui_input(window, event))


func _on_window_gui_input(window: Control, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_bring_to_front(window)


func _on_title_bar_gui_input(window: Control, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_bring_to_front(window)
			dragged_window = window
		elif dragged_window == window:
			dragged_window = null
		return

	if event is InputEventMouseMotion and dragged_window == window:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		var window_size: Vector2 = window.size
		if window_size == Vector2.ZERO:
			window_size = window.custom_minimum_size

		var target_position: Vector2 = window.position + motion_event.relative
		window.position = _clamp_window_position(target_position, window_size)


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
	_set_dynamic_message("interview")


func _on_week_report(title: String, message: String) -> void:
	show_toast(title, message)
	_set_dynamic_message("week")


func _on_game_over(won: bool, title: String, message: String) -> void:
	show_toast(title, message)
	var tree: SceneTree = get_tree()
	var target_scene: String = "res://WinScreen.tscn" if won else "res://LoseScreen.tscn"
	var tween: Tween = create_tween()
	tween.tween_interval(1.4)
	tween.tween_callback(func(): tree.change_scene_to_file(target_scene))


func _on_player_state_changed() -> void:
	_refresh_clock()

	var next_snapshot: Dictionary = _make_state_snapshot()
	var score_delta: int = int(next_snapshot["score"]) - int(last_state_snapshot.get("score", next_snapshot["score"]))
	if score_delta > 0:
		_spawn_delta_feedback("score", score_delta, " POINTS", Color(0.46, 1.0, 0.68))
		_set_dynamic_message("score_gain")

	if PlayerState.checking_balance < 150:
		_set_dynamic_message("low_money")
	elif PlayerState.burnout >= 70:
		_set_dynamic_message("high_burnout")

	last_state_snapshot = next_snapshot


func _make_state_snapshot() -> Dictionary:
	return {
		"cash": PlayerState.checking_balance,
		"score": PlayerState.score,
		"confidence": PlayerState.confidence,
		"burnout": PlayerState.burnout,
		"ap": PlayerState.action_points_remaining,
		"timer": PlayerState.idle_seconds_left,
	}


func _spawn_delta_feedback(kind: String, delta: int, suffix: String, color: Color) -> void:
	if delta <= 0:
		return

	var prefix := "+" if delta > 0 else ""
	var text := "%s%s%s" % [prefix, delta, suffix]

	var origin: Vector2 = Vector2(size.x * 0.47, TOP_BAR_HEIGHT + 80.0)
	match kind:
		"cash":
			origin = Vector2(size.x * 0.38, TOP_BAR_HEIGHT + 74.0)
		"score":
			origin = Vector2(size.x * 0.58, TOP_BAR_HEIGHT + 74.0)
		"confidence":
			origin = Vector2(size.x * 0.48, TOP_BAR_HEIGHT + 118.0)
		"burnout":
			origin = Vector2(size.x * 0.42, TOP_BAR_HEIGHT + 118.0)

	_spawn_feedback(text, color, origin)


func _spawn_feedback(text: String, color: Color, origin: Vector2) -> void:
	if text == "":
		return

	var coin := TextureRect.new()
	coin.texture = coin_texture
	coin.custom_minimum_size = Vector2(56, 56)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.z_index = 50
	coin.position = origin - Vector2(226, 4)
	coin.modulate = Color(1, 1, 1, 0)
	coin.scale = Vector2(0.55, 0.55)
	feedback_layer.add_child(coin)

	var label := Label.new()
	label.text = text
	label.z_index = 50
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.add_theme_font_size_override("font_size", 38)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(360, 58)
	label.position = origin - Vector2(180, 0)
	label.modulate = Color(1, 1, 1, 0)
	label.scale = Vector2(0.82, 0.82)
	feedback_layer.add_child(label)

	var drift: Vector2 = Vector2(randf_range(-18.0, 18.0), -54.0)
	var tween: Tween = create_tween()
	tween.tween_property(coin, "modulate", Color(1, 1, 1, 1), 0.08)
	tween.parallel().tween_property(coin, "scale", Vector2(0.86, 0.86), 0.12)
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.08)
	tween.parallel().tween_property(label, "scale", Vector2(1.12, 1.12), 0.12)
	tween.tween_interval(0.18)
	tween.tween_property(label, "position", label.position + drift, 0.72)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), 0.72)
	tween.parallel().tween_property(coin, "position", coin.position + drift + Vector2(-18, 0), 0.72)
	tween.parallel().tween_property(coin, "modulate", Color(1, 1, 1, 0), 0.72)
	tween.tween_callback(coin.queue_free)
	tween.tween_callback(label.queue_free)


func show_toast(title: String, message: String) -> void:
	var toast: Control = toast_scene.instantiate() as Control
	var toast_index: int = toast_layer.get_child_count()
	toast_layer.add_child(toast)
	toast.position = Vector2(920, 64 + toast_index * 68)

	var icon_label := toast.find_child("IconLabel", true, false) as Label
	var message_label := toast.find_child("MessageLabel", true, false) as Label

	if icon_label != null:
		icon_label.text = "i"

	if message_label != null:
		message_label.text = "%s\n%s" % [title, message]

	toast.modulate = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	tween.tween_property(toast, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.tween_interval(3.2)
	tween.tween_property(toast, "modulate", Color(1, 1, 1, 0), 0.24)
	tween.tween_callback(toast.queue_free)


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")
