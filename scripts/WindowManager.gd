extends Node

# WindowManager controls the fake desktop windows.
#
# It should handle desktop UI behavior:
# - opening windows from dock buttons
# - closing windows from close buttons
# - keeping only the right windows visible
# - bringing clicked windows to the front
# - supporting draggable windows later if needed
#
# Dock buttons should talk to WindowManager instead of manually creating or
# hiding windows themselves.
