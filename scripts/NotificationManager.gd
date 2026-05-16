extends Node

# NotificationManager controls feedback popups.
#
# It should handle short-lived player feedback:
# - toast notifications
# - floating point popups
# - action result messages
# - keyword unlock messages
# - application status messages
# - debt, burnout, win, and loss warnings
#
# Other systems should call NotificationManager when something important happens
# instead of each system building its own popup behavior.
