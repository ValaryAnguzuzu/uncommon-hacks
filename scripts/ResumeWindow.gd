extends PanelContainer

# ResumeWindow is the player's character sheet.
#
# General behavior:
# - It reads PlayerState and turns the player's progress into a fake resume file.
# - It does not unlock keywords or complete projects by itself.
# - ProjectsWindow and other systems should change PlayerState; this window just
#   refreshes whenever PlayerState.state_changed fires.
# - The layout is intentionally more like an ATS/recruiter scan than a stats box.

@onready var close_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/CloseDot
@onready var zoom_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/ZoomDot
@onready var close_button: Button = $OuterMargin/WindowStack/TitleBar/CloseButton
@onready var title_label: Label = $OuterMargin/WindowStack/TitleBar/TitleLabel
@onready var resume_score_label: Label = $OuterMargin/WindowStack/Body/ScanPanel/ScanStack/ResumeScoreLabel
@onready var score_progress: ProgressBar = $OuterMargin/WindowStack/Body/ScanPanel/ScanStack/ScoreProgress
@onready var signal_label: Label = $OuterMargin/WindowStack/Body/ScanPanel/ScanStack/SignalLabel
@onready var readiness_label: Label = $OuterMargin/WindowStack/Body/ScanPanel/ScanStack/ReadinessLabel
@onready var meta_label: Label = $OuterMargin/WindowStack/Body/ScanPanel/ScanStack/MetaLabel
@onready var summary_label: Label = $OuterMargin/WindowStack/Body/ResumePaper/PaperMargin/PaperStack/SummaryLabel
@onready var keywords_grid: GridContainer = $OuterMargin/WindowStack/Body/ResumePaper/PaperMargin/PaperStack/KeywordsGrid
@onready var projects_list: VBoxContainer = $OuterMargin/WindowStack/Body/ResumePaper/PaperMargin/PaperStack/ProjectsList
@onready var footer_label: Label = $OuterMargin/WindowStack/Body/ResumePaper/PaperMargin/PaperStack/FooterLabel


var _is_expanded: bool = false
var _saved_offsets: Vector4 = Vector4.ZERO


func _ready() -> void:
	close_dot.pressed.connect(_on_close_button_pressed)
	zoom_dot.pressed.connect(func(): _toggle_expand())
	close_button.pressed.connect(_on_close_button_pressed)

	var refresh_callable := Callable(self, "refresh")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	refresh()


func refresh() -> void:
	# Pull fresh values every time so this window never stores stale state.
	var total_score := _get_total_resume_score()

	title_label.text = "Resume.doc - Candidate Build"
	resume_score_label.text = "SCAN SCORE: %s" % total_score
	score_progress.value = min(total_score, int(score_progress.max_value))
	signal_label.text = _get_signal_text()
	readiness_label.text = _get_readiness_summary(total_score)
	meta_label.text = _get_meta_notes()
	summary_label.text = _get_recruiter_summary(total_score)
	footer_label.text = _get_next_move(total_score)

	_render_keywords()
	_render_projects()


func _render_keywords() -> void:
	_clear_container(keywords_grid)

	if PlayerState.resume_keywords.is_empty():
		_add_chip(keywords_grid, "no signal")
		return

	for keyword in PlayerState.resume_keywords:
		_add_chip(keywords_grid, keyword)


func _render_projects() -> void:
	_clear_container(projects_list)

	if PlayerState.completed_projects.is_empty():
		_add_project_card(
			projects_list,
			"Evidence gap",
			"No shipped projects yet. Recruiters are squinting.",
			"Open Projects to turn effort into evidence."
		)
		return

	for project_id in PlayerState.completed_projects:
		_add_project_card(
			projects_list,
			_humanize_id(project_id),
			"Shipped proof added to file.",
			"Impact: resume score and job matching improve."
		)


func _get_total_resume_score() -> int:
	# Temporary display formula until ResumeManager owns scoring.
	var keyword_points := PlayerState.resume_keywords.size() * 10
	var project_points := PlayerState.completed_projects.size() * 25
	return PlayerState.resume_score + keyword_points + project_points


func _get_signal_text() -> String:
	var keyword_count := PlayerState.resume_keywords.size()
	var project_count := PlayerState.completed_projects.size()

	if keyword_count == 1 and project_count == 0:
		return "SIGNAL: one lonely Git tag"

	return "SIGNAL: %s keywords, %s shipped proofs" % [keyword_count, project_count]


func _get_readiness_summary(total_score: int) -> String:
	if total_score < 30:
		return "VERDICT: Draft energy. Needs proof."

	if total_score < 70:
		return "VERDICT: Searchable, but fragile."

	if total_score < 120:
		return "VERDICT: Real candidate signal."

	return "VERDICT: Strong file. Recruiter bait detected."


func _get_recruiter_summary(total_score: int) -> String:
	if total_score < 30:
		return "Thin file, but not hopeless. Right now the resume says potential more than proof."

	if total_score < 70:
		return "Some search terms are landing. Add projects so the keywords look earned."

	if total_score < 120:
		return "The story is forming: skills, evidence, and enough polish to survive a skim."

	return "This reads like someone who has built things, not just listed technologies."


func _get_meta_notes() -> String:
	return "ATS notes:\n- %s applications sent\n- confidence %s%%\n- interview skill %s%%" % [
		PlayerState.applications_sent,
		PlayerState.confidence,
		PlayerState.interview_skill
	]


func _get_next_move(total_score: int) -> String:
	if total_score < 70:
		return "Next move: ship a project and unlock keywords that jobs actually scan for."

	if PlayerState.applications_sent == 0:
		return "Next move: the file is warming up. Start applying before rent notices."

	return "Next move: prep for interviews so the resume does not write checks you cannot cash."


func _add_chip(parent: GridContainer, text: String) -> void:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(110, 26)
	chip.add_theme_stylebox_override("panel", _make_chip_style())

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.08, 0.12, 0.14))

	chip.add_child(label)
	parent.add_child(chip)


func _add_project_card(parent: VBoxContainer, title: String, body: String, detail: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_project_card_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)

	var card_title := Label.new()
	card_title.text = title
	card_title.add_theme_color_override("font_color", Color(0.08, 0.1, 0.13))

	var body_label := Label.new()
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_color_override("font_color", Color(0.18, 0.21, 0.25))

	var detail_label := Label.new()
	detail_label.text = detail
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_color_override("font_color", Color(0.36, 0.42, 0.49))

	stack.add_child(card_title)
	stack.add_child(body_label)
	stack.add_child(detail_label)
	margin.add_child(stack)
	card.add_child(margin)
	parent.add_child(card)


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


func _make_project_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.90, 0.93, 0.96)
	style.border_color = Color(0.70, 0.75, 0.82)
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


func _humanize_id(id: String) -> String:
	var words := id.split("_")

	for index in range(words.size()):
		words[index] = words[index].capitalize()

	return " ".join(words)


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
