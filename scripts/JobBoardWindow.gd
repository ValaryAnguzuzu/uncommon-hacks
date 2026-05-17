extends PanelContainer

# JobBoardWindow connects resume keywords to job opportunities.
#
# General behavior:
# - Loads job listings from data/jobs.json.
# - Scores each job against PlayerState.resume_keywords.
# - Shows required/nice keywords, missing keywords, and match percentage.
# - Apply is enabled only when match >= match_threshold.
# - Applying records the application and unlocks an interview for that job.

const JOBS_PATH := "res://data/jobs.json"

@onready var close_button: Button = $OuterMargin/WindowStack/TitleBar/CloseButton
@onready var resume_keywords_label: Label = $OuterMargin/WindowStack/BodyPanel/BodyStack/HeaderRow/ResumeKeywordsLabel
@onready var jobs_list: VBoxContainer = $OuterMargin/WindowStack/BodyPanel/BodyStack/ScrollContainer/JobsList

var jobs: Array = []


func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)

	var refresh_callable := Callable(self, "refresh")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	_load_jobs()
	refresh()


func refresh() -> void:
	resume_keywords_label.text = "Resume: %s" % _keywords_summary()
	_render_jobs()


func _load_jobs() -> void:
	var file := FileAccess.open(JOBS_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not load job data: %s" % JOBS_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("Job data must be a JSON array.")
		return

	jobs = parsed


func _render_jobs() -> void:
	_clear_container(jobs_list)

	for job in jobs:
		jobs_list.add_child(_make_job_card(job))


func _make_job_card(job: Dictionary) -> PanelContainer:
	var job_id := str(job.get("id", ""))
	var match_score := _calculate_match(job)
	var threshold := int(job.get("match_threshold", 60))
	var can_apply := match_score >= threshold
	var applied := job_id in PlayerState.applied_jobs
	var interview_unlocked := job_id in PlayerState.unlocked_interviews

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_style(can_apply, applied))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)

	var top_row := HBoxContainer.new()
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_label := Label.new()
	title_label.text = str(job.get("title", "Untitled Role"))
	title_label.add_theme_color_override("font_color", Color(0.06, 0.08, 0.10))

	var company_label := Label.new()
	company_label.text = str(job.get("company", "Unknown Company"))
	company_label.add_theme_color_override("font_color", Color(0.30, 0.35, 0.42))

	var match_label := Label.new()
	match_label.text = "%s%% match" % match_score
	match_label.add_theme_color_override("font_color", _match_color(match_score, threshold))

	title_stack.add_child(title_label)
	title_stack.add_child(company_label)
	top_row.add_child(title_stack)
	top_row.add_child(match_label)

	var required_label := Label.new()
	required_label.text = "Required"
	required_label.add_theme_color_override("font_color", Color(0.10, 0.13, 0.16))

	var required_grid := _make_keyword_grid(job.get("required_keywords", []), true)

	var missing := _missing_keywords(job.get("required_keywords", []))
	var missing_label := Label.new()
	missing_label.text = "Missing: %s" % ("None" if missing.is_empty() else _join_strings(missing))
	missing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	missing_label.add_theme_color_override("font_color", Color(0.45, 0.24, 0.18))

	var nice_label := Label.new()
	nice_label.text = "Nice to have"
	nice_label.add_theme_color_override("font_color", Color(0.10, 0.13, 0.16))

	var nice_grid := _make_keyword_grid(job.get("nice_to_have_keywords", []), false)

	var action_row := HBoxContainer.new()
	var status_label := Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.text = _status_text(can_apply, applied, interview_unlocked, threshold)
	status_label.add_theme_color_override("font_color", Color(0.30, 0.35, 0.42))

	var apply_button := Button.new()
	apply_button.text = "Interview Ready" if interview_unlocked else ("Applied" if applied else "Apply")
	apply_button.disabled = applied or not can_apply
	apply_button.pressed.connect(func(): _apply_to_job(job))

	action_row.add_child(status_label)
	action_row.add_child(apply_button)

	stack.add_child(top_row)
	stack.add_child(required_label)
	stack.add_child(required_grid)
	stack.add_child(missing_label)
	stack.add_child(nice_label)
	stack.add_child(nice_grid)
	stack.add_child(action_row)

	margin.add_child(stack)
	card.add_child(margin)
	return card


func _calculate_match(job: Dictionary) -> int:
	var required: Array = job.get("required_keywords", [])
	var nice: Array = job.get("nice_to_have_keywords", [])
	var total_weight := required.size() * 2 + nice.size()

	if total_weight == 0:
		return 100

	var earned := 0
	for keyword in required:
		if str(keyword) in PlayerState.resume_keywords:
			earned += 2

	for keyword in nice:
		if str(keyword) in PlayerState.resume_keywords:
			earned += 1

	return int(round(float(earned) / float(total_weight) * 100.0))


func _apply_to_job(job: Dictionary) -> void:
	var job_id := str(job.get("id", ""))
	if job_id == "" or job_id in PlayerState.applied_jobs:
		return

	PlayerState.add_application(job_id)
	PlayerState.unlock_interview(job_id)
	refresh()


func _make_keyword_grid(keywords: Array, required: bool) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)

	for keyword in keywords:
		var owned := str(keyword) in PlayerState.resume_keywords
		grid.add_child(_make_chip(str(keyword), owned, required))

	return grid


func _make_chip(text: String, owned: bool, required: bool) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(110, 24)
	chip.add_theme_stylebox_override("panel", _make_chip_style(owned, required))

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.08, 0.12, 0.14))

	chip.add_child(label)
	return chip


func _missing_keywords(keywords: Array) -> Array:
	var missing := []

	for keyword in keywords:
		if str(keyword) not in PlayerState.resume_keywords:
			missing.append(str(keyword))

	return missing


func _keywords_summary() -> String:
	if PlayerState.resume_keywords.is_empty():
		return "None"

	if PlayerState.resume_keywords.size() <= 4:
		return _join_strings(PlayerState.resume_keywords)

	return "%s keywords" % PlayerState.resume_keywords.size()


func _join_strings(values: Array) -> String:
	var text := ""

	for value in values:
		if text != "":
			text += ", "

		text += str(value)

	return text


func _status_text(can_apply: bool, applied: bool, interview_unlocked: bool, threshold: int) -> String:
	if interview_unlocked:
		return "Interview unlocked. Open Interview when ready."

	if applied:
		return "Application sent. Waiting for response."

	if can_apply:
		return "Threshold met. Resume is strong enough to apply."

	return "Need %s%% match to apply." % threshold


func _match_color(match_score: int, threshold: int) -> Color:
	if match_score >= threshold:
		return Color(0.13, 0.48, 0.34)

	if match_score >= threshold - 20:
		return Color(0.70, 0.45, 0.12)

	return Color(0.55, 0.18, 0.16)


func _make_card_style(can_apply: bool, applied: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.90, 0.94, 0.91) if can_apply else Color(0.95, 0.96, 0.98)
	style.border_color = Color(0.32, 0.62, 0.48) if can_apply else Color(0.72, 0.76, 0.82)

	if applied:
		style.bg_color = Color(0.89, 0.92, 0.96)
		style.border_color = Color(0.38, 0.48, 0.64)

	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_right = 7
	style.corner_radius_bottom_left = 7
	return style


func _make_chip_style(owned: bool, required: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.70, 0.92, 0.86) if owned else Color(0.88, 0.90, 0.93)
	style.border_color = Color(0.29, 0.58, 0.52) if owned else Color(0.65, 0.68, 0.74)

	if required and not owned:
		style.bg_color = Color(0.96, 0.86, 0.82)
		style.border_color = Color(0.72, 0.38, 0.30)

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
		child.free()


func _on_close_button_pressed() -> void:
	hide()
