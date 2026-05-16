extends Node

# GameManager coordinates the overall game loop.
#
# It should handle high-level flow:
# - starting a new run
# - ending the week
# - checking win conditions
# - checking lose conditions
# - asking UI scenes to refresh after state changes
#
# GameManager should not contain every detailed rule. For example, project
# progress, job matching, and interview scoring can move into their own systems
# once those mechanics are built.
