extends Control

# Draws lightweight project icons directly in Godot.
#
# The Projects UI does not rely on external image assets yet. Instead, each
# project card passes an icon type from projects.json, and this control draws a
# small symbolic picture that matches the project category.

var icon_type := "portfolio"
var icon_color := Color(0.49, 0.78, 1.0)


func setup(next_icon_type: String, next_color: Color) -> void:
	icon_type = next_icon_type
	icon_color = next_color
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, icon_color)

	var ink := Color(0.05, 0.07, 0.09, 0.92)
	var soft := Color(1, 1, 1, 0.28)
	var center := size * 0.5

	match icon_type:
		"dashboard":
			_draw_dashboard(ink, soft)
		"full_stack":
			_draw_stack(ink, soft)
		"ai":
			_draw_ai(ink, soft)
		"market":
			_draw_market(ink, soft)
		"tracker":
			_draw_tracker(ink, soft)
		"dsa":
			_draw_graph(ink, soft)
		"api":
			_draw_api(ink, soft)
		"cloud":
			_draw_cloud(ink, soft)
		"mobile":
			_draw_mobile(ink, soft)
		"security":
			_draw_security(ink, soft)
		"oss":
			_draw_oss(ink, soft)
		"accessibility":
			_draw_accessibility(ink, soft)
		"chat":
			_draw_chat(ink, soft)
		"product":
			_draw_product(ink, soft)
		_:
			_draw_portfolio(ink, soft)

	draw_circle(center + Vector2(size.x * 0.34, -size.y * 0.32), 18, soft)


func _draw_portfolio(ink: Color, _soft: Color) -> void:
	var monitor := Rect2(size.x * 0.22, size.y * 0.24, size.x * 0.56, size.y * 0.38)
	draw_rect(monitor, ink, false, 4)
	draw_line(Vector2(size.x * 0.38, size.y * 0.72), Vector2(size.x * 0.62, size.y * 0.72), ink, 4)
	draw_line(Vector2(size.x * 0.5, size.y * 0.62), Vector2(size.x * 0.5, size.y * 0.72), ink, 4)


func _draw_dashboard(ink: Color, _soft: Color) -> void:
	for index in range(4):
		var height := size.y * (0.22 + index * 0.09)
		var x := size.x * (0.24 + index * 0.13)
		draw_rect(Rect2(x, size.y * 0.72 - height, size.x * 0.08, height), ink)
	draw_line(Vector2(size.x * 0.2, size.y * 0.76), Vector2(size.x * 0.82, size.y * 0.76), ink, 3)


func _draw_stack(ink: Color, _soft: Color) -> void:
	for index in range(3):
		var offset := Vector2(index * 10, index * 10)
		draw_rect(Rect2(size.x * 0.24 + offset.x, size.y * 0.24 + offset.y, size.x * 0.44, size.y * 0.24), ink, false, 4)


func _draw_ai(ink: Color, _soft: Color) -> void:
	var points := [
		Vector2(size.x * 0.28, size.y * 0.34),
		Vector2(size.x * 0.54, size.y * 0.26),
		Vector2(size.x * 0.72, size.y * 0.5),
		Vector2(size.x * 0.42, size.y * 0.68)
	]
	for index in range(points.size()):
		draw_line(points[index], points[(index + 1) % points.size()], ink, 3)
		draw_circle(points[index], 8, ink)


func _draw_market(ink: Color, _soft: Color) -> void:
	draw_rect(Rect2(size.x * 0.22, size.y * 0.38, size.x * 0.56, size.y * 0.34), ink, false, 4)
	draw_line(Vector2(size.x * 0.2, size.y * 0.38), Vector2(size.x * 0.32, size.y * 0.22), ink, 4)
	draw_line(Vector2(size.x * 0.8, size.y * 0.38), Vector2(size.x * 0.68, size.y * 0.22), ink, 4)
	draw_line(Vector2(size.x * 0.32, size.y * 0.22), Vector2(size.x * 0.68, size.y * 0.22), ink, 4)


func _draw_tracker(ink: Color, _soft: Color) -> void:
	for index in range(3):
		var y := size.y * (0.3 + index * 0.16)
		draw_circle(Vector2(size.x * 0.28, y), 6, ink)
		draw_line(Vector2(size.x * 0.4, y), Vector2(size.x * 0.74, y), ink, 4)


func _draw_graph(ink: Color, _soft: Color) -> void:
	var a := Vector2(size.x * 0.28, size.y * 0.64)
	var b := Vector2(size.x * 0.5, size.y * 0.3)
	var c := Vector2(size.x * 0.72, size.y * 0.64)
	draw_line(a, b, ink, 4)
	draw_line(b, c, ink, 4)
	draw_line(a, c, ink, 4)
	draw_circle(a, 8, ink)
	draw_circle(b, 8, ink)
	draw_circle(c, 8, ink)


func _draw_api(ink: Color, _soft: Color) -> void:
	draw_circle(Vector2(size.x * 0.32, size.y * 0.5), 14, ink)
	draw_circle(Vector2(size.x * 0.68, size.y * 0.5), 14, ink)
	draw_line(Vector2(size.x * 0.42, size.y * 0.5), Vector2(size.x * 0.58, size.y * 0.5), ink, 6)
	draw_line(Vector2(size.x * 0.5, size.y * 0.34), Vector2(size.x * 0.5, size.y * 0.66), ink, 4)


func _draw_cloud(ink: Color, _soft: Color) -> void:
	draw_circle(Vector2(size.x * 0.36, size.y * 0.54), 18, ink)
	draw_circle(Vector2(size.x * 0.52, size.y * 0.44), 24, ink)
	draw_circle(Vector2(size.x * 0.66, size.y * 0.56), 16, ink)
	draw_rect(Rect2(size.x * 0.32, size.y * 0.54, size.x * 0.38, size.y * 0.14), ink)


func _draw_mobile(ink: Color, _soft: Color) -> void:
	draw_rect(Rect2(size.x * 0.36, size.y * 0.18, size.x * 0.28, size.y * 0.64), ink, false, 5)
	draw_circle(Vector2(size.x * 0.5, size.y * 0.74), 4, ink)


func _draw_security(ink: Color, _soft: Color) -> void:
	var points := PackedVector2Array([
		Vector2(size.x * 0.5, size.y * 0.18),
		Vector2(size.x * 0.72, size.y * 0.3),
		Vector2(size.x * 0.66, size.y * 0.64),
		Vector2(size.x * 0.5, size.y * 0.78),
		Vector2(size.x * 0.34, size.y * 0.64),
		Vector2(size.x * 0.28, size.y * 0.3)
	])
	draw_polygon(points, PackedColorArray([ink]))


func _draw_oss(ink: Color, _soft: Color) -> void:
	var top := Vector2(size.x * 0.5, size.y * 0.24)
	var left := Vector2(size.x * 0.34, size.y * 0.64)
	var right := Vector2(size.x * 0.66, size.y * 0.64)
	draw_line(top, left, ink, 4)
	draw_line(top, right, ink, 4)
	draw_circle(top, 8, ink)
	draw_circle(left, 8, ink)
	draw_circle(right, 8, ink)


func _draw_accessibility(ink: Color, _soft: Color) -> void:
	draw_circle(Vector2(size.x * 0.5, size.y * 0.24), 8, ink)
	draw_line(Vector2(size.x * 0.26, size.y * 0.4), Vector2(size.x * 0.74, size.y * 0.4), ink, 5)
	draw_line(Vector2(size.x * 0.5, size.y * 0.34), Vector2(size.x * 0.5, size.y * 0.72), ink, 5)
	draw_line(Vector2(size.x * 0.5, size.y * 0.52), Vector2(size.x * 0.32, size.y * 0.76), ink, 5)
	draw_line(Vector2(size.x * 0.5, size.y * 0.52), Vector2(size.x * 0.68, size.y * 0.76), ink, 5)


func _draw_chat(ink: Color, _soft: Color) -> void:
	draw_rect(Rect2(size.x * 0.22, size.y * 0.28, size.x * 0.42, size.y * 0.26), ink, false, 4)
	draw_rect(Rect2(size.x * 0.36, size.y * 0.5, size.x * 0.42, size.y * 0.26), ink, false, 4)


func _draw_product(ink: Color, _soft: Color) -> void:
	draw_rect(Rect2(size.x * 0.28, size.y * 0.28, size.x * 0.44, size.y * 0.44), ink, false, 4)
	draw_line(Vector2(size.x * 0.34, size.y * 0.5), Vector2(size.x * 0.46, size.y * 0.62), ink, 4)
	draw_line(Vector2(size.x * 0.46, size.y * 0.62), Vector2(size.x * 0.68, size.y * 0.38), ink, 4)
