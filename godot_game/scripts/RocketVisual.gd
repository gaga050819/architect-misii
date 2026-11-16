extends Node2D

@export var is_flying: bool = false
@export var staging_stage: int = 0
@export var thrust_power: float = 1.0
@export var altitude_km: float = 0.0

var flame_time: float = 0.0
var booster_l_pos: Vector2 = Vector2.ZERO
var booster_r_pos: Vector2 = Vector2.ZERO
var booster_rot: float = 0.0
var stage1_pos: Vector2 = Vector2.ZERO
var stage1_rot: float = 0.0
var fairing_sep_dist: float = 0.0

func _process(delta: float) -> void:
	flame_time += delta
	if staging_stage >= 1:
		booster_l_pos += Vector2(-45.0, 30.0) * delta
		booster_r_pos += Vector2(45.0, 30.0) * delta
		booster_rot += delta * 0.8
	if staging_stage >= 2:
		stage1_pos += Vector2(0, 95.0) * delta
		stage1_rot += delta * 0.2
	if staging_stage >= 3:
		fairing_sep_dist += delta * 65.0
	queue_redraw()

func _draw() -> void:
	var rocket = DataManager.get_rocket(GameState.rocket_id)
	var boosters = int(rocket.get("boosters", 0))

	var w = 28.0
	var h_stage1 = 140.0
	var h_stage2 = 58.0
	var h_fairing = 65.0

	var vac_factor = clamp(altitude_km / 80.0, 0.0, 1.0)

	if is_flying and thrust_power > 0.0 and staging_stage < 2:
		draw_engine_plume(Vector2(0, 0), w * 0.7, thrust_power, vac_factor)

	if is_flying and thrust_power > 0.0 and staging_stage >= 2:
		var s2_bottom = -h_stage1
		draw_vacuum_plume(Vector2(0, s2_bottom), w * 0.5, thrust_power)

	if staging_stage < 2:
		draw_first_stage(w, h_stage1, stage1_pos, 1.0)
		if boosters > 0:
			draw_side_boosters(w, h_stage1, 1.0)
	else:
		if stage1_pos.y < 450.0:
			var s1_alpha = clamp(1.0 - (stage1_pos.y / 450.0), 0.0, 1.0)
			draw_first_stage(w, h_stage1, stage1_pos, s1_alpha)

	if boosters > 0 and staging_stage >= 1:
		if booster_l_pos.y < 450.0:
			var b_alpha = clamp(1.0 - (booster_l_pos.y / 450.0), 0.0, 1.0)
			draw_side_boosters(w, h_stage1, b_alpha)

	var s2_y = -h_stage1 - h_stage2
	draw_second_stage(w, h_stage2, s2_y)

	var payload_y = s2_y - 25.0
	draw_payload_probe(payload_y)

	if staging_stage < 3:
		draw_fairing(w, h_fairing, s2_y)
	else:
		if fairing_sep_dist < 400.0:
			draw_separating_fairings(w, h_fairing, s2_y)

func draw_engine_plume(origin: Vector2, width_base: float, power: float, vac_blend: float) -> void:
	var flame_len = (70.0 + sin(flame_time * 38.0) * 14.0) * power
	var plume_spread = lerp(width_base * 0.8, width_base * 3.5, vac_blend)

	var outer_poly = PackedVector2Array([
		origin + Vector2(-width_base * 0.5, 0),
		origin + Vector2(width_base * 0.5, 0),
		origin + Vector2(plume_spread, flame_len),
		origin + Vector2(0, flame_len * 1.3),
		origin + Vector2(-plume_spread, flame_len)
	])
	var outer_color = Color(1.0, 0.52, 0.12, lerp(0.88, 0.40, vac_blend))
	draw_polygon(outer_poly, [outer_color])

	var core_poly = PackedVector2Array([
		origin + Vector2(-width_base * 0.3, 0),
		origin + Vector2(width_base * 0.3, 0),
		origin + Vector2(width_base * 0.5, flame_len * 0.65),
		origin + Vector2(0, flame_len * 0.9),
		origin + Vector2(-width_base * 0.5, flame_len * 0.65)
	])
	draw_polygon(core_poly, [Color(1.0, 0.96, 0.55, 0.95)])

	if vac_blend < 0.45:
		for i in range(4):
			var dy = 16.0 + i * 16.0
			var diamond = PackedVector2Array([
				origin + Vector2(0, dy - 6.0),
				origin + Vector2(4.8, dy),
				origin + Vector2(0, dy + 6.0),
				origin + Vector2(-4.8, dy)
			])
			draw_polygon(diamond, [Color(1.0, 1.0, 1.0, 0.92)])

func draw_vacuum_plume(origin: Vector2, width_base: float, power: float) -> void:
	var bell_len = (85.0 + sin(flame_time * 26.0) * 10.0) * power
	var bell_w = width_base * 4.8
	var bell_poly = PackedVector2Array([
		origin + Vector2(-width_base * 0.4, 0),
		origin + Vector2(width_base * 0.4, 0),
		origin + Vector2(bell_w, bell_len * 0.7),
		origin + Vector2(bell_w * 0.6, bell_len),
		origin + Vector2(0, bell_len * 1.15),
		origin + Vector2(-bell_w * 0.6, bell_len),
		origin + Vector2(-bell_w, bell_len * 0.7)
	])
	draw_polygon(bell_poly, [Color(0.32, 0.65, 1.0, 0.60)])

func draw_first_stage(w: float, h: float, offset: Vector2, alpha: float = 1.0) -> void:
	if alpha <= 0.01:
		return
	var s1_top = -h
	var body_rect = Rect2(offset.x - w * 0.5, offset.y + s1_top, w, h)

	draw_rect(body_rect, Color(0.92, 0.94, 0.96, alpha))

	draw_line(Vector2(body_rect.position.x + 3.0, body_rect.position.y), Vector2(body_rect.position.x + 3.0, body_rect.position.y + h), Color(1.0, 1.0, 1.0, 0.9 * alpha), 2.5)
	draw_line(Vector2(body_rect.position.x + w - 3.0, body_rect.position.y), Vector2(body_rect.position.x + w - 3.0, body_rect.position.y + h), Color(0.68, 0.72, 0.78, alpha), 3.0)
	draw_rect(body_rect, Color(0.16, 0.18, 0.22, alpha), false, 1.8)

	var interstage_h = 18.0
	draw_rect(Rect2(offset.x - w * 0.5, offset.y + s1_top, w, interstage_h), Color(0.12, 0.14, 0.16, alpha))

	for t in range(4):
		var ty = offset.y + s1_top + 3.0 + t * 4.0
		draw_line(Vector2(offset.x - w * 0.5, ty), Vector2(offset.x + w * 0.5, ty), Color(0.22, 0.25, 0.30, alpha), 1.0)

	var fin_w = 7.0
	var fin_h = 6.0
	var fin_y = offset.y + s1_top + 6.0
	draw_rect(Rect2(offset.x - w * 0.5 - fin_w, fin_y, fin_w, fin_h), Color(0.25, 0.28, 0.34, alpha))
	draw_rect(Rect2(offset.x + w * 0.5, fin_y, fin_w, fin_h), Color(0.25, 0.28, 0.34, alpha))

	for ring in range(3):
		var ry = offset.y + s1_top + 40.0 + ring * 35.0
		draw_line(Vector2(offset.x - w * 0.5, ry), Vector2(offset.x + w * 0.5, ry), Color(0.70, 0.74, 0.80, alpha), 1.2)

	var leg_w = 4.0
	var leg_h = 42.0
	var leg_y = offset.y - leg_h
	draw_line(Vector2(offset.x - w * 0.5, leg_y), Vector2(offset.x - w * 0.5 - 2.0, offset.y), Color(0.15, 0.16, 0.18, alpha), leg_w)
	draw_line(Vector2(offset.x + w * 0.5, leg_y), Vector2(offset.x + w * 0.5 + 2.0, offset.y), Color(0.15, 0.16, 0.18, alpha), leg_w)

	var engine_y = offset.y
	for n in range(3):
		var nx = offset.x - w * 0.3 + n * (w * 0.3)
		draw_polygon(PackedVector2Array([
			Vector2(nx - 3.5, engine_y),
			Vector2(nx + 3.5, engine_y),
			Vector2(nx + 5.0, engine_y + 9.0),
			Vector2(nx - 5.0, engine_y + 9.0)
		]), [Color(0.20, 0.22, 0.26, alpha)])

func draw_side_boosters(w: float, h: float, alpha: float = 1.0) -> void:
	if alpha <= 0.01:
		return
	var bw = 18.0
	var bh = 110.0
	var by = -bh + stage1_pos.y

	var left_x = -w * 0.5 - bw - 2.0 + booster_l_pos.x
	var left_rect = Rect2(left_x, by + booster_l_pos.y, bw, bh)
	draw_rect(left_rect, Color(0.92, 0.94, 0.96, alpha))
	draw_line(Vector2(left_x + 2, by + booster_l_pos.y), Vector2(left_x + 2, by + booster_l_pos.y + bh), Color(1, 1, 1, alpha), 1.5)
	draw_polygon(PackedVector2Array([
		Vector2(left_x, by + booster_l_pos.y),
		Vector2(left_x + bw, by + booster_l_pos.y),
		Vector2(left_x + bw * 0.5, by + booster_l_pos.y - 22.0)
	]), [Color(0.92, 0.94, 0.96, alpha)])
	draw_rect(left_rect, Color(0.18, 0.20, 0.25, alpha), false, 1.5)

	var right_x = w * 0.5 + 2.0 + booster_r_pos.x
	var right_rect = Rect2(right_x, by + booster_r_pos.y, bw, bh)
	draw_rect(right_rect, Color(0.92, 0.94, 0.96, alpha))
	draw_line(Vector2(right_x + bw - 2, by + booster_r_pos.y), Vector2(right_x + bw - 2, by + booster_r_pos.y + bh), Color(0.68, 0.72, 0.78, alpha), 2.0)
	draw_polygon(PackedVector2Array([
		Vector2(right_x, by + booster_r_pos.y),
		Vector2(right_x + bw, by + booster_r_pos.y),
		Vector2(right_x + bw * 0.5, by + booster_r_pos.y - 22.0)
	]), [Color(0.92, 0.94, 0.96, alpha)])
	draw_rect(right_rect, Color(0.18, 0.20, 0.25, alpha), false, 1.5)

func draw_second_stage(w: float, h: float, top_y: float) -> void:
	var body_rect = Rect2(-w * 0.5, top_y, w, h)
	draw_rect(body_rect, Color(0.94, 0.95, 0.97))
	draw_line(Vector2(body_rect.position.x + 3.0, top_y), Vector2(body_rect.position.x + 3.0, top_y + h), Color(1.0, 1.0, 1.0, 0.9), 2.0)
	draw_rect(body_rect, Color(0.16, 0.18, 0.22), false, 1.6)

	var vac_nozzle = PackedVector2Array([
		Vector2(-4.5, top_y + h),
		Vector2(4.5, top_y + h),
		Vector2(8.5, top_y + h + 15.0),
		Vector2(-8.5, top_y + h + 15.0)
	])
	draw_polygon(vac_nozzle, [Color(0.22, 0.24, 0.28)])
	draw_circle(Vector2(0, top_y + h + 14.0), 5.5, Color(1.0, 0.55, 0.15, 0.7))

func draw_payload_probe(y: float) -> void:
	draw_rect(Rect2(-13.0, y - 13.0, 26.0, 26.0), Color(0.95, 0.82, 0.35))
	draw_rect(Rect2(-13.0, y - 13.0, 26.0, 26.0), Color(0.2, 0.22, 0.26), false, 1.5)
	draw_line(Vector2(-28.0, y), Vector2(-13.0, y), Color(0.15, 0.45, 0.9), 3.5)
	draw_line(Vector2(13.0, y), Vector2(28.0, y), Color(0.15, 0.45, 0.9), 3.5)
	draw_circle(Vector2(0, y - 19.0), 5.0, Color(0.92, 0.94, 0.98))

func draw_fairing(w: float, h: float, base_y: float) -> void:
	var f_w = w * 0.68
	var f_top = base_y - h
	var fairing_poly = PackedVector2Array([
		Vector2(-f_w, base_y),
		Vector2(-f_w, base_y - h * 0.65),
		Vector2(0, f_top),
		Vector2(f_w, base_y - h * 0.65),
		Vector2(f_w, base_y)
	])
	draw_polygon(fairing_poly, [Color(0.96, 0.97, 0.98)])
	draw_line(Vector2(0, f_top), Vector2(0, base_y), Color(0.25, 0.28, 0.32), 1.2)
	draw_polyline(fairing_poly, Color(0.16, 0.18, 0.22), 1.6)

func draw_separating_fairings(w: float, h: float, base_y: float) -> void:
	var f_w = w * 0.68
	var f_top = base_y - h
	var sep_dist = fairing_sep_dist

	var left_poly = PackedVector2Array([
		Vector2(-sep_dist, base_y + sep_dist * 0.3),
		Vector2(-f_w - sep_dist, base_y + sep_dist * 0.3),
		Vector2(-f_w - sep_dist * 1.3, base_y - h * 0.65 + sep_dist * 0.3),
		Vector2(-sep_dist, f_top + sep_dist * 0.3)
	])
	draw_polygon(left_poly, [Color(0.96, 0.97, 0.98)])
	draw_polyline(left_poly, Color(0.18, 0.20, 0.24), 1.4)

	var right_poly = PackedVector2Array([
		Vector2(sep_dist, base_y + sep_dist * 0.3),
		Vector2(f_w + sep_dist, base_y + sep_dist * 0.3),
		Vector2(f_w + sep_dist * 1.3, base_y - h * 0.65 + sep_dist * 0.3),
		Vector2(sep_dist, f_top + sep_dist * 0.3)
	])
	draw_polygon(right_poly, [Color(0.96, 0.97, 0.98)])
	draw_polyline(right_poly, Color(0.18, 0.20, 0.24), 1.4)
