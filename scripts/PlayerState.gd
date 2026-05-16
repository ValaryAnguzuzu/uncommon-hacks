extends Node

# PlayerState is the source of truth for the current run.
#
# It should hold the player's changing game data:
# - current week
# - checking/money
# - Discover debt
# - burnout
# - confidence
# - interview skill
# - score
# - resume keywords
# - completed projects
# - applications sent
# - active interviews
#
# Other managers should read from and update PlayerState instead of keeping
# separate copies of these values.
