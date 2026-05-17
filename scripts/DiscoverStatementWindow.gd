extends PanelContainer

# Desktop-only finance statement. This is intentionally not in the dock: it is
# a file on the fake desktop that makes money/debt pressure feel concrete.

@onready var close_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/CloseDot
@onready var zoom_dot: Button = $OuterMargin/WindowStack/TitleBar/WindowControls/ZoomDot
@onready var close_button: Button = $OuterMargin/WindowStack/TitleBar/CloseButton
@onready var balance_label: Label = $OuterMargin/WindowStack/Body/BalanceLabel
@onready var debt_label: Label = $OuterMargin/WindowStack/Body/DiscoverBox/DiscoverMargin/DiscoverStack/DebtLabel
@onready var health_bar: ProgressBar = $OuterMargin/WindowStack/Body/HealthBar


func _ready() -> void:
	close_dot.pressed.connect(hide)
	close_button.pressed.connect(hide)
	zoom_dot.pressed.connect(_toggle_expand)

	var refresh_callable := Callable(self, "refresh")
	if not PlayerState.state_changed.is_connected(refresh_callable):
		PlayerState.state_changed.connect(refresh_callable)

	refresh()


func refresh() -> void:
	balance_label.text = "$%s" % PlayerState.checking_balance
	debt_label.text = "$%s" % PlayerState.debt
	health_bar.value = clampf(float(PlayerState.checking_balance + 200), 0.0, 1000.0)

	if PlayerState.checking_balance < 150:
		balance_label.add_theme_color_override("font_color", Color(1.0, 0.30, 0.30))
	else:
		balance_label.add_theme_color_override("font_color", Color(0.22, 1.0, 0.55))


func _toggle_expand() -> void:
	custom_minimum_size = Vector2(720, 560) if custom_minimum_size.x < 700 else Vector2(560, 500)
