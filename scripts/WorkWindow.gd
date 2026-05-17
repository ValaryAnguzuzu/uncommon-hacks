extends PanelContainer

# WorkWindow is the first gameplay window.
#
# General behavior:
# - Each button represents one weekly action the player can take.
# - For now, actions write directly to PlayerState so we can test the full loop.
# - Later, these button handlers should call GameManager or ActionManager, and
#   those managers can decide costs, limits, notifications, and loss checks.
# - PlayerState emits state_changed after each helper call, so TopMenuBar should
#   refresh automatically when these buttons are pressed.

const SIDE_GIG_PAY := 180

@onready var close_button: Button = $Content/TitleBar/CloseButton
@onready var blast_applications_button: Button = $Content/BlastApplicationsButton
@onready var side_gig_button: Button = $Content/SideGigButton
@onready var network_button: Button = $Content/NetworkButton
@onready var rest_button: Button = $Content/RestButton


func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	blast_applications_button.pressed.connect(_on_blast_applications_button_pressed)
	side_gig_button.pressed.connect(_on_side_gig_button_pressed)
	network_button.pressed.connect(_on_network_button_pressed)
	rest_button.pressed.connect(_on_rest_button_pressed)


func _on_close_button_pressed() -> void:
	# Hiding keeps the node around. WindowManager can own real open/close later.
	hide()


func _on_blast_applications_button_pressed() -> void:
	# More applications, but emotionally expensive.
	for application in range(5):
		PlayerState.add_application()

	PlayerState.add_burnout(12)
	PlayerState.add_confidence(-5)
	PlayerState.add_score(10)


func _on_side_gig_button_pressed() -> void:
	# Money goes up, but the player pays for it with burnout.
	PlayerState.add_money(SIDE_GIG_PAY)
	PlayerState.add_burnout(8)
	PlayerState.add_confidence(-2)
	PlayerState.add_score(5)


func _on_network_button_pressed() -> void:
	# Networking improves confidence but still costs energy.
	PlayerState.add_confidence(8)
	PlayerState.add_burnout(4)
	PlayerState.add_score(8)


func _on_rest_button_pressed() -> void:
	# Rest does not progress the job search, but it restores the player.
	PlayerState.add_burnout(-18)
	PlayerState.add_confidence(4)
