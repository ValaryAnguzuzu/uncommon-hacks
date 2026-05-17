extends PanelContainer

# ProjectsWindow is a visual project picker.
#
# General behavior:
# - Project definitions live in data/projects.json.
# - Each project has a picture color/label and a keyword pool.
# - The window rolls a small keyword set for each project and shows those
#   keywords directly under the project picture.
# - There is no description/detail panel here by design. Jobs will read the
#   keywords later through the job data/matching system.

const PROJECTS_PATH := "res://data/projects.json"
const PROJECT_ICON_SCRIPT := preload("res://scripts/ProjectIcon.gd")
const BASE_SCORE_REWARD := 20
const BASE_RESUME_SCORE_REWARD := 25
const BASE_BURNOUT_COST := 7

@onready var close_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/CloseDot
@onready var zoom_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/ZoomDot
@onready var close_button: Button = $OuterMargin/WindowStack/TitleBar/CloseButton
@onready var project_grid: GridContainer = $OuterMargin/WindowStack/BodyPanel/BodyStack/ScrollContainer/ProjectGrid

var projects: Array = []
var rolled_keywords: Dictionary = {}


var _is_expanded: bool = false
var _saved_offsets: Vector4 = Vector4.ZERO


func _ready() -> void:
	close_dot.pressed.connect(_on_close_button_pressed)
	zoom_dot.pressed.connect(func(): _toggle_expand())
	close_button.pressed.connect(_on_close_button_pressed)

	var refresh_callable := Callable(self, "refresh")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	_load_projects()
	_roll_project_keywords()
	refresh()


func refresh() -> void:
	_render_project_grid()


func _load_projects() -> void:
	var file := FileAccess.open(PROJECTS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not load project data: %s" % PROJECTS_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Project data must be a JSON array.")
		return

	projects = parsed


func _roll_project_keywords() -> void:
	# Roll once per window lifetime so cards do not change while the player reads.
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for project in projects:
		var project_id := str(project.get("id", ""))
		rolled_keywords[project_id] = _pick_keywords(
			project.get("keyword_pool", []),
			int(project.get("keyword_count", 3)),
			rng
		)


func _render_project_grid() -> void:
	_clear_container(project_grid)

	for project in projects:
		project_grid.add_child(_make_project_card(project))


func _make_project_card(project: Dictionary) -> PanelContainer:
	var project_id := str(project.get("id", ""))
	var completed := project_id in PlayerState.completed_projects
	var keywords: Array = rolled_keywords.get(project_id, [])

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 250)
	card.add_theme_stylebox_override("panel", _make_card_style(completed))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)

	var picture := _make_project_picture(project)

	var name_label := Label.new()
	name_label.text = str(project.get("name", "Untitled Project"))
	name_label.add_theme_color_override("font_color", Color(0.08, 0.10, 0.13))

	var keyword_grid := GridContainer.new()
	keyword_grid.columns = 2
	keyword_grid.add_theme_constant_override("h_separation", 6)
	keyword_grid.add_theme_constant_override("v_separation", 6)

	for keyword in keywords:
		keyword_grid.add_child(_make_chip(str(keyword)))

	var button := Button.new()
	button.text = "Shipped" if completed else "Ship"
	button.disabled = completed
	button.pressed.connect(func(): _ship_project(project))

	stack.add_child(picture)
	stack.add_child(name_label)
	stack.add_child(keyword_grid)
	stack.add_child(button)
	margin.add_child(stack)
	card.add_child(margin)

	return card


func _ship_project(project: Dictionary) -> void:
	var project_id := str(project.get("id", ""))
	if project_id == "" or project_id in PlayerState.completed_projects:
		return

	PlayerState.complete_project(project_id)
	PlayerState.add_burnout(BASE_BURNOUT_COST)
	PlayerState.add_score(BASE_SCORE_REWARD)
	PlayerState.add_resume_score(BASE_RESUME_SCORE_REWARD)

	for keyword in rolled_keywords.get(project_id, []):
		PlayerState.add_keyword(str(keyword))

	refresh()


func _pick_keywords(pool: Array, count: int, rng: RandomNumberGenerator) -> Array:
	var available := pool.duplicate()
	var picked := []

	while not available.is_empty() and picked.size() < count:
		var index := rng.randi_range(0, available.size() - 1)
		picked.append(available[index])
		available.remove_at(index)

	return picked


func _make_project_picture(project: Dictionary) -> VBoxContainer:
	var picture_stack := VBoxContainer.new()
	picture_stack.add_theme_constant_override("separation", 4)

	var icon := Control.new()
	icon.custom_minimum_size = Vector2(0, 104)
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.set_script(PROJECT_ICON_SCRIPT)
	icon.call(
		"setup",
		str(project.get("icon_type", "portfolio")),
		Color.html(str(project.get("image_color", "#7CC7FF")))
	)

	var label := Label.new()
	label.text = str(project.get("image_label", "PROJECT"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.20, 0.24, 0.29))

	picture_stack.add_child(icon)
	picture_stack.add_child(label)
	return picture_stack


func _make_chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(92, 24)
	chip.add_theme_stylebox_override("panel", _make_chip_style())

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.08, 0.12, 0.14))

	chip.add_child(label)
	return chip


func _make_card_style(completed: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.90, 0.93, 0.96) if completed else Color(0.95, 0.96, 0.98)
	style.border_color = Color(0.40, 0.68, 0.58) if completed else Color(0.72, 0.76, 0.82)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_right = 7
	style.corner_radius_bottom_left = 7
	return style


func _make_chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.70, 0.92, 0.86)
	style.border_color = Color(0.29, 0.58, 0.52)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	return style


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()


func _toggle_expand() -> void:
	if not _is_expanded:
		_saved_offsets = Vector4(offset_left, offset_top, offset_right, offset_bottom)
		anchor_left = 0.0
		anchor_top = 0.0
		anchor_right = 1.0
		anchor_bottom = 1.0
		offset_left = 8.0
		offset_top = 40.0
		offset_right = -8.0
		offset_bottom = -76.0
	else:
		anchor_left = 0.0
		anchor_top = 0.0
		anchor_right = 0.0
		anchor_bottom = 0.0
		offset_left = _saved_offsets.x
		offset_top = _saved_offsets.y
		offset_right = _saved_offsets.z
		offset_bottom = _saved_offsets.w
	_is_expanded = not _is_expanded


func _on_close_button_pressed() -> void:
	hide()
