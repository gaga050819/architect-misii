extends Node2D

@export var scale_factor: float = 2.2
var anim_time: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	var build = GameState.get_current_build()
	var platform = build.get("platform", {})
	var power = build.get("power", {})
	var antenna = build.get("antenna", {})
	var instruments = build.get("instruments", [])
	var plat_type = platform.get("type", "orbiter")

	var s = scale_factor
	var hover = sin(anim_time * 2.2) * 4.0
	var center = Vector2(0, hover)

	var foil_base = Color(0.95, 0.82, 0.35)
	var foil_shade = Color(0.72, 0.56, 0.18)
	var foil_highlight = Color(1.0, 0.94, 0.65)
	var metal_color = Color(0.58, 0.64, 0.72)
	var dark_metal = Color(0.14, 0.16, 0.20)
	var led_green = Color(0.18, 0.94, 0.58)

	var power_id = power.get("id", "solar")
	if power_id.begins_with("solar") or power_id == "solar_large" or power_id == "solar_std" or power_id == "solar_xl":
		var wing_w = 72.0 * s
		var wing_h = 26.0 * s
		var flap = sin(anim_time * 1.5) * 3.0

		draw_solar_wing(Rect2(center.x - 32.0 * s - wing_w, center.y - wing_h * 0.5 + flap, wing_w, wing_h), true, s)
		draw_line(Vector2(center.x - 32.0 * s, center.y + flap), Vector2(center.x - 18.0 * s, center.y), metal_color, 4.5)
		draw_circle(Vector2(center.x - 18.0 * s, center.y), 4.0, dark_metal)

		draw_solar_wing(Rect2(center.x + 32.0 * s, center.y - wing_h * 0.5 - flap, wing_w, wing_h), false, s)
		draw_line(Vector2(center.x + 32.0 * s, center.y - flap), Vector2(center.x + 18.0 * s, center.y), metal_color, 4.5)
		draw_circle(Vector2(center.x + 18.0 * s, center.y), 4.0, dark_metal)

	elif power_id.begins_with("rtg"):
		var rtg_w = 22.0 * s
		var rtg_h = 32.0 * s
		var rtg_rect = Rect2(center.x - 40.0 * s, center.y - rtg_h * 0.5, rtg_w, rtg_h)
		draw_rect(rtg_rect, Color(0.35, 0.38, 0.44))
		draw_rect(rtg_rect, dark_metal, false, 2.0)
		for f in range(6):
			var fy = rtg_rect.position.y + f * (rtg_h / 5.0)
			draw_line(Vector2(rtg_rect.position.x - 5.0, fy), Vector2(rtg_rect.position.x + rtg_w + 5.0, fy), Color(0.22, 0.24, 0.28), 3.0)
			draw_line(Vector2(rtg_rect.position.x - 5.0, fy - 1.0), Vector2(rtg_rect.position.x + rtg_w + 5.0, fy - 1.0), Color(0.5, 0.55, 0.62), 1.0)
		var pulse = 0.6 + sin(anim_time * 5.0) * 0.35
		draw_circle(Vector2(center.x - 29.0 * s, center.y), 7.0 * s * 0.4, Color(1.0, 0.32, 0.15, pulse))
		draw_circle(Vector2(center.x - 29.0 * s, center.y), 3.5 * s * 0.4, Color(1.0, 0.85, 0.3, pulse))

	if plat_type == "rover":
		var body_w = 52.0 * s
		var body_h = 32.0 * s
		var body_rect = Rect2(center.x - body_w * 0.5, center.y - body_h * 0.5, body_w, body_h)
		draw_mli_gold_foil(body_rect)

		var wheel_r = 8.5 * s
		var wheel_y = center.y + 25.0 * s
		var wheel_xs = [center.x - 28.0 * s, center.x, center.x + 28.0 * s]

		draw_line(Vector2(wheel_xs[0], wheel_y - 2.0), Vector2(wheel_xs[1], center.y + 10.0 * s), metal_color, 4.0)
		draw_line(Vector2(wheel_xs[1], center.y + 10.0 * s), Vector2(wheel_xs[2], wheel_y - 2.0), metal_color, 4.0)

		for wx in wheel_xs:
			draw_line(Vector2(wx, center.y + 10.0 * s), Vector2(wx, wheel_y), dark_metal, 4.0)
			draw_wheel_textured(Vector2(wx, wheel_y), wheel_r)

		var mast_base = Vector2(center.x + 16.0 * s, center.y - body_h * 0.5)
		var mast_top = Vector2(center.x + 20.0 * s, center.y - 36.0 * s)
		draw_line(mast_base, mast_top, metal_color, 4.5)
		draw_line(mast_base + Vector2(2, 0), mast_top + Vector2(2, 0), Color(0.85, 0.90, 0.95), 1.5)

		var head_rect = Rect2(mast_top.x - 7.0 * s, mast_top.y - 5.0 * s, 16.0 * s, 10.0 * s)
		draw_rect(head_rect, dark_metal)
		draw_rect(head_rect, Color(0.4, 0.45, 0.52), false, 1.5)

		draw_circle(mast_top + Vector2(1.5 * s, 0), 4.0 * s * 0.7, Color(0.08, 0.12, 0.18))
		draw_circle(mast_top + Vector2(1.5 * s, 0), 3.2 * s * 0.7, Color(0.15, 0.65, 0.95))
		draw_circle(mast_top + Vector2(0.5 * s, -1.0 * s * 0.7), 1.2 * s * 0.7, Color(1, 1, 1, 0.9))

		draw_circle(mast_top + Vector2(6.5 * s, 0), 3.0 * s * 0.7, Color(0.08, 0.12, 0.18))
		draw_circle(mast_top + Vector2(6.5 * s, 0), 2.2 * s * 0.7, Color(0.95, 0.35, 0.15))

	elif plat_type == "lander":
		var top_w = 28.0 * s
		var bot_w = 42.0 * s
		var land_h = 30.0 * s
		var poly = PackedVector2Array([
			Vector2(center.x - top_w, center.y - land_h * 0.5),
			Vector2(center.x + top_w, center.y - land_h * 0.5),
			Vector2(center.x + bot_w, center.y + land_h * 0.5),
			Vector2(center.x - bot_w, center.y + land_h * 0.5)
		])
		draw_polygon(poly, [foil_base])
		draw_polyline(poly, dark_metal, 3.0)

		for i in range(5):
			var t_ratio = float(i) / 4.0
			var ly = center.y - land_h * 0.5 + t_ratio * land_h
			var cur_w = lerp(top_w, bot_w, t_ratio)
			draw_line(Vector2(center.x - cur_w, ly), Vector2(center.x + cur_w, ly), foil_shade, 1.2)
			draw_line(Vector2(center.x - cur_w, ly - 1.0), Vector2(center.x + cur_w, ly - 1.0), foil_highlight, 0.8)

		var leg_span = 58.0 * s
		var leg_bot_y = center.y + 38.0 * s
		draw_line(Vector2(center.x - bot_w * 0.8, center.y + land_h * 0.4), Vector2(center.x - leg_span, leg_bot_y), metal_color, 4.5)
		draw_line(Vector2(center.x - leg_span - 10.0 * s, leg_bot_y), Vector2(center.x - leg_span + 10.0 * s, leg_bot_y), dark_metal, 4.0)

		draw_line(Vector2(center.x + bot_w * 0.8, center.y + land_h * 0.4), Vector2(center.x + leg_span, leg_bot_y), metal_color, 4.5)
		draw_line(Vector2(center.x + leg_span - 10.0 * s, leg_bot_y), Vector2(center.x + leg_span + 10.0 * s, leg_bot_y), dark_metal, 4.0)

		draw_polygon(PackedVector2Array([
			Vector2(center.x - 11.0 * s, center.y + land_h * 0.5),
			Vector2(center.x + 11.0 * s, center.y + land_h * 0.5),
			Vector2(center.x + 15.0 * s, center.y + land_h * 0.5 + 11.0 * s),
			Vector2(center.x - 15.0 * s, center.y + land_h * 0.5 + 11.0 * s)
		]), [dark_metal])

	else:
		var bus_w = 40.0 * s
		var bus_h = 48.0 * s
		var bus_rect = Rect2(center.x - bus_w * 0.5, center.y - bus_h * 0.5, bus_w, bus_h)
		draw_mli_gold_foil(bus_rect)

		draw_circle(center, 14.0 * s * 0.7, Color(0.25, 0.28, 0.35))
		draw_circle(center, 11.0 * s * 0.7, Color(0.65, 0.70, 0.78))
		draw_circle(center, 5.0 * s * 0.7, dark_metal)

		draw_polygon(PackedVector2Array([
			Vector2(center.x - 14.0 * s, center.y + bus_h * 0.5),
			Vector2(center.x + 14.0 * s, center.y + bus_h * 0.5),
			Vector2(center.x + 18.0 * s, center.y + bus_h * 0.5 + 14.0 * s),
			Vector2(center.x - 18.0 * s, center.y + bus_h * 0.5 + 14.0 * s)
		]), [dark_metal])

	var ant_id = antenna.get("id", "omni")
	if ant_id.begins_with("hga"):
		var dish_r = 22.0 * s if ant_id == "hga_large" else 16.0 * s
		var dish_c = Vector2(center.x - 15.0 * s, center.y - 34.0 * s)
		draw_dish_textured(dish_c, dish_r, metal_color, dark_metal)
	else:
		var whip_top = Vector2(center.x, center.y - 42.0 * s)
		draw_line(Vector2(center.x, center.y - 20.0 * s), whip_top, metal_color, 3.5)
		draw_line(Vector2(center.x + 1, center.y - 20.0 * s), whip_top + Vector2(1, 0), Color(1, 1, 1, 0.7), 1.2)
		draw_circle(whip_top, 4.5, Color(0.18, 0.88, 1.0))
		draw_circle(whip_top, 2.0, Color.WHITE)

	var inst_count = instruments.size()
	for i in range(inst_count):
		var ang = (float(i) / max(1.0, float(inst_count))) * TAU
		var ix = center.x + cos(ang) * (26.0 * s)
		var iy = center.y + sin(ang) * (20.0 * s)
		draw_circle(Vector2(ix, iy), 6.0, dark_metal)
		draw_circle(Vector2(ix, iy), 4.5, led_green)
		draw_circle(Vector2(ix, iy), 2.0, Color.WHITE)

func draw_mli_gold_foil(rect: Rect2) -> void:
	var foil_base = Color(0.95, 0.82, 0.35)
	var foil_shade = Color(0.74, 0.58, 0.20)
	var foil_hi = Color(1.0, 0.95, 0.68)
	var dark_metal = Color(0.16, 0.18, 0.22)

	draw_rect(rect, foil_base)

	var cell_w = 12.0
	var cell_h = 10.0
	var cols = int(rect.size.x / cell_w)
	var rows = int(rect.size.y / cell_h)

	for r in range(rows):
		for c in range(cols):
			var cx = rect.position.x + c * cell_w
			var cy = rect.position.y + r * cell_h
			var c_rect = Rect2(cx, cy, cell_w, cell_h)
			draw_line(Vector2(cx, cy), Vector2(cx + cell_w, cy), foil_hi, 0.8)
			draw_line(Vector2(cx, cy), Vector2(cx, cy + cell_h), foil_hi, 0.8)
			draw_line(Vector2(cx + cell_w, cy), Vector2(cx + cell_w, cy + cell_h), foil_shade, 0.8)
			draw_line(Vector2(cx, cy + cell_h), Vector2(cx + cell_w, cy + cell_h), foil_shade, 0.8)

	draw_rect(rect, dark_metal, false, 2.5)

func draw_solar_wing(rect: Rect2, _is_left: bool, _s: float) -> void:
	var dark_bg = Color(0.06, 0.12, 0.24)
	var cell_color = Color(0.14, 0.38, 0.78)
	var busbar_color = Color(0.75, 0.85, 0.95, 0.8)
	var frame_color = Color(0.85, 0.88, 0.92)

	draw_rect(rect, dark_bg)

	var cell_cols = 4
	var cell_rows = 2
	var cw = (rect.size.x - 4.0) / float(cell_cols)
	var ch = (rect.size.y - 4.0) / float(cell_rows)

	for r in range(cell_rows):
		for c in range(cell_cols):
			var cx = rect.position.x + 2.0 + c * cw + 1.0
			var cy = rect.position.y + 2.0 + r * ch + 1.0
			var cell_rect = Rect2(cx, cy, cw - 2.0, ch - 2.0)
			draw_rect(cell_rect, cell_color)
			draw_line(Vector2(cx, cy + (ch - 2.0) * 0.5), Vector2(cx + cw - 2.0, cy + (ch - 2.0) * 0.5), busbar_color, 1.2)
			for f in range(3):
				var fx = cx + (f + 1) * ((cw - 2.0) / 4.0)
				draw_line(Vector2(fx, cy), Vector2(fx, cy + ch - 2.0), Color(0.4, 0.65, 0.9, 0.4), 0.8)

	draw_rect(rect, frame_color, false, 2.0)

func draw_wheel_textured(pos: Vector2, radius: float) -> void:
	var tire_color = Color(0.18, 0.20, 0.24)
	var rim_color = Color(0.68, 0.72, 0.78)
	var spoke_color = Color(0.32, 0.35, 0.40)

	draw_circle(pos, radius, tire_color)
	draw_circle(pos, radius - 2.5, rim_color)
	draw_circle(pos, radius - 5.0, spoke_color)

	for g in range(8):
		var ang = g * (TAU / 8.0)
		var p1 = pos + Vector2(cos(ang), sin(ang)) * (radius - 2.5)
		var p2 = pos + Vector2(cos(ang), sin(ang)) * radius
		draw_line(p1, p2, Color(0.1, 0.1, 0.12), 2.0)

	draw_circle(pos, 3.0, Color(0.14, 0.16, 0.20))
	draw_circle(pos, 1.5, Color.WHITE)

func draw_dish_textured(center: Vector2, radius: float, metal_col: Color, dark_col: Color) -> void:
	draw_arc(center, radius, PI * 0.85, PI * 2.15, 32, Color(0.92, 0.95, 0.98), 4.0)
	draw_arc(center, radius - 2.0, PI * 0.85, PI * 2.15, 32, Color(0.7, 0.75, 0.82), 1.5)

	var rib_count = 6
	for r in range(rib_count):
		var ang = PI * 0.9 + r * ((PI * 1.2) / float(rib_count - 1))
		var pt = center + Vector2(cos(ang), sin(ang)) * radius
		draw_line(center, pt, Color(0.6, 0.65, 0.75, 0.6), 1.2)

	draw_line(center, Vector2(center.x, center.y + 14.0), metal_col, 4.0)
	var horn_pos = center + Vector2(0, -radius * 0.55)
	draw_line(center, horn_pos, dark_col, 2.5)
	draw_line(center + Vector2(-radius * 0.5, 0), horn_pos, Color(0.6, 0.65, 0.72), 1.2)
	draw_line(center + Vector2(radius * 0.5, 0), horn_pos, Color(0.6, 0.65, 0.72), 1.2)
	draw_circle(horn_pos, 4.0, Color(0.2, 0.85, 1.0))
	draw_circle(horn_pos, 2.0, Color.WHITE)
