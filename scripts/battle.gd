extends Control

# ────────────────────────────────────────────────────────────
enum State { PLAYER_TURN, ENEMY_TURN, BUSY, OVER }

const SPECIAL_CD     := 3      # 必殺技クールダウン（ターン数）
const DMG_NORMAL     := 0.38   # 通常攻撃倍率
const DMG_SPECIAL    := 0.76   # 必殺技倍率（≒ 通常の2倍）
const GUARD_FACTOR   := 0.40   # 防御時ダメージ係数

var pl: Dictionary           # プレイヤーキャラデータ
var en: Dictionary           # 敵キャラデータ
var pl_hp: int
var en_hp: int
var pl_max: int
var en_max: int
var pl_turn: bool            # true = プレイヤーのターン
var pl_scd := 0              # プレイヤー必殺技 CD
var en_scd := 0
var pl_guard := false        # 防御フラグ（次の被ダメージに適用）
var en_guard := false
var current_state: State

# UI
var pl_big:    Label
var en_big:    Label
var pl_hpbar:  ProgressBar
var en_hpbar:  ProgressBar
var pl_hpval:  Label
var en_hpval:  Label
var log_box:   RichTextLabel
var turn_lbl:  Label
var act_box:   HBoxContainer
var spc_btn:   Button
var res_layer: ColorRect
var res_title: Label
var res_sub:   Label


func _ready() -> void:
	# キャラデータ取得（未選択時はフォールバック）
	if GameManager.selected_character.is_empty():
		pl = (GameManager.CHARACTERS[0] as Dictionary).duplicate()
	else:
		pl = GameManager.selected_character.duplicate()

	# 敵をランダム選択（プレイヤーと異なるキャラ）
	var pool: Array = GameManager.CHARACTERS.filter(
		func(c) -> bool: return c["hiragana"] != pl["hiragana"]
	)
	en = (pool[randi() % pool.size()] as Dictionary).duplicate()

	pl_max = int(pl["hp"]) * 2;  pl_hp = pl_max
	en_max = int(en["hp"]) * 2;  en_hp = en_max

	_build_ui()

	# 先攻判定（SPD が高い方が先手。同値ならランダム）
	if pl["spd"] > en["spd"]:
		pl_turn = true
	elif pl["spd"] < en["spd"]:
		pl_turn = false
	else:
		pl_turn = randi() % 2 == 0

	var first: String = str(pl["name"]) if pl_turn else str(en["name"])
	_log("[color=#bbbbff]%s が先攻！[/color]" % first)

	await _wait(0.6)
	_begin_turn()


# ────────────────────── ターン管理 ──────────────────────────
func _begin_turn() -> void:
	if pl_scd > 0: pl_scd -= 1
	if en_scd > 0: en_scd -= 1
	pl_guard = false
	en_guard = false
	_refresh_action_btns()

	if pl_turn:
		current_state = State.PLAYER_TURN
		turn_lbl.text = "▶ あなたのターン"
		turn_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.55))
		act_box.visible = true
	else:
		current_state = State.ENEMY_TURN
		turn_lbl.text = "▶ %s のターン" % str(en["name"])
		turn_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		act_box.visible = false
		await _wait(0.9)
		_do_enemy_turn()


func _refresh_action_btns() -> void:
	spc_btn.disabled = pl_scd > 0
	spc_btn.text = "★ 必殺技" if pl_scd == 0 else "★ 必殺技（残%dT）" % pl_scd


# ────────────────────── プレイヤー行動 ───────────────────────
func _on_player_action(action: String) -> void:
	if current_state != State.PLAYER_TURN:
		return
	current_state = State.BUSY
	act_box.visible = false
	await _execute_action(pl, en, action, true)
	if current_state == State.OVER:
		return
	pl_turn = false
	await _wait(0.25)
	_begin_turn()


# ────────────────────── 敵AI ────────────────────────────────
func _do_enemy_turn() -> void:
	current_state = State.BUSY
	var r := randf()
	var action: String
	if en_scd == 0 and r < 0.28:
		action = "special"
	elif r < 0.40:
		action = "guard"
	else:
		action = "attack"
	await _execute_action(en, pl, action, false)
	if current_state == State.OVER:
		return
	pl_turn = true
	await _wait(0.25)
	_begin_turn()


# ────────────────────── アクション実行 ───────────────────────
func _execute_action(
	atker: Dictionary,
	defer_: Dictionary,
	action: String,
	by_player: bool
) -> void:
	var ac: String = _color_code(atker["color"] as Color)
	var ah: String = str(atker["hiragana"])

	match action:
		"attack":
			_log("[color=%s]%s[/color] の攻撃！" % [ac, ah])
			await _wait(0.2)
			var dmg: int = _calc_dmg(int(atker["atk"]), DMG_NORMAL)
			await _apply_hit(dmg, not by_player)

		"special":
			if by_player: pl_scd = SPECIAL_CD else: en_scd = SPECIAL_CD
			_log("[color=%s]%s[/color] の [color=#ffee55]必殺技！！[/color]" % [ac, ah])
			var fighter_lbl: Label = pl_big if by_player else en_big
			var tw := create_tween()
			tw.tween_property(fighter_lbl, "modulate", Color(2.0, 1.8, 0.4), 0.15)
			tw.tween_property(fighter_lbl, "modulate", Color.WHITE, 0.25)
			await _wait(0.45)
			var sdmg: int = _calc_dmg(int(atker["atk"]), DMG_SPECIAL)
			await _apply_hit(sdmg, not by_player)

		"guard":
			if by_player: pl_guard = true else: en_guard = true
			_log("[color=%s]%s[/color] は [color=#88ddff]防御[/color] の構え！" % [ac, ah])
			await _wait(0.7)


func _calc_dmg(atk: int, mul: float) -> int:
	return max(1, int(atk * mul * randf_range(0.85, 1.15)))


func _apply_hit(raw_dmg: int, to_player: bool) -> void:
	var is_guarding := pl_guard if to_player else en_guard
	var final_dmg   := int(raw_dmg * GUARD_FACTOR) if is_guarding else raw_dmg

	if is_guarding:
		_log("  ガードで [color=#88ddff]%d[/color] ダメージに軽減！" % final_dmg)
		if to_player: pl_guard = false else: en_guard = false
	else:
		_log("  [color=#ff6655]%d[/color] ダメージ！" % final_dmg)

	# 被弾フラッシュ
	var lbl := pl_big if to_player else en_big
	var tw  := create_tween()
	tw.tween_property(lbl, "modulate", Color(1.8, 0.2, 0.2), 0.07)
	tw.tween_property(lbl, "modulate", Color.WHITE, 0.30)

	await _wait(0.12)

	if to_player:
		pl_hp = max(0, pl_hp - final_dmg)
		_tween_hp(pl_hpbar, pl_hpval, pl_hp, pl_max)
		if pl_hp <= 0:
			await _wait(0.7)
			_end_battle(false)
			return
	else:
		en_hp = max(0, en_hp - final_dmg)
		_tween_hp(en_hpbar, en_hpval, en_hp, en_max)
		if en_hp <= 0:
			await _wait(0.7)
			_end_battle(true)
			return

	await _wait(0.35)


func _end_battle(player_won: bool) -> void:
	current_state = State.OVER
	_log("")
	if player_won:
		_log("[color=#ffdd44]★ 勝利！！ ★[/color]")
	else:
		_log("[color=#888888]…… 敗北 ……[/color]")
	await _wait(1.0)
	_show_result(player_won)


# ────────────────────── UI ヘルパー ─────────────────────────
func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _log(msg: String) -> void:
	log_box.append_text(msg + "\n")


func _tween_hp(bar: ProgressBar, val_lbl: Label, hp: int, max_hp: int) -> void:
	var ratio := float(hp) / float(max_hp)
	var tw := create_tween()
	tw.tween_property(bar, "value", ratio * 100.0, 0.4)
	val_lbl.text = "%d / %d" % [hp, max_hp]

	# HP 残量で色変化
	var fill := StyleBoxFlat.new()
	fill.corner_radius_top_left     = 4
	fill.corner_radius_top_right    = 4
	fill.corner_radius_bottom_left  = 4
	fill.corner_radius_bottom_right = 4
	if ratio > 0.5:
		fill.bg_color = Color(0.2, 0.85, 0.35)
	elif ratio > 0.25:
		fill.bg_color = Color(0.9, 0.75, 0.15)
	else:
		fill.bg_color = Color(0.9, 0.2, 0.2)
	bar.add_theme_stylebox_override("fill", fill)


func _color_code(c: Color) -> String:
	return "#%s" % c.to_html(false)


func _show_result(won: bool) -> void:
	res_title.text = "勝　利！！" if won else "敗　北…"
	res_title.add_theme_color_override("font_color",
		Color(1.0, 0.9, 0.2) if won else Color(0.6, 0.6, 0.7))
	res_sub.text = "%s の勝ち！" % str(pl["name"]) if won else "%s の勝ち…" % str(en["name"])
	res_layer.visible = true


# ────────────────────── UI 構築 ─────────────────────────────
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.05, 0.14)
	add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	_build_top_bar(root_vbox)
	_build_arena(root_vbox)
	_build_bottom_bar(root_vbox)
	_build_result_overlay()


func _build_top_bar(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 120)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.11, 0.08, 0.20)
	panel.add_theme_stylebox_override("panel", sty)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   36)
	margin.add_theme_constant_override("margin_right",  36)
	margin.add_theme_constant_override("margin_top",    14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	# プレイヤー情報カード
	var pl_card := _make_combatant_info(pl)
	pl_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(pl_card)
	pl_hpbar = pl_card.get_meta("hpbar") as ProgressBar
	pl_hpval = pl_card.get_meta("hpval") as Label

	# VS
	var vs_lbl := Label.new()
	vs_lbl.text = "VS"
	vs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	vs_lbl.add_theme_font_size_override("font_size", 22)
	vs_lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
	vs_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vs_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	hbox.add_child(vs_lbl)

	# 敵情報カード
	var en_card := _make_combatant_info(en)
	en_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(en_card)
	en_hpbar = en_card.get_meta("hpbar") as ProgressBar
	en_hpval = en_card.get_meta("hpval") as Label


func _make_combatant_info(data: Dictionary) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 6)

	var name_lbl := Label.new()
	name_lbl.text = "%s「%s」" % [str(data["hiragana"]), str(data["name"])]
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", data["color"] as Color)
	card.add_child(name_lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var hp_tag := Label.new()
	hp_tag.text = "HP"
	hp_tag.add_theme_font_size_override("font_size", 12)
	hp_tag.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	row.add_child(hp_tag)

	var bar := ProgressBar.new()
	bar.max_value = 100.0
	bar.value     = 100.0
	bar.custom_minimum_size = Vector2(0, 20)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false

	var bg_sty := StyleBoxFlat.new()
	bg_sty.bg_color = Color(0.1, 0.08, 0.18)
	bg_sty.corner_radius_top_left     = 4
	bg_sty.corner_radius_top_right    = 4
	bg_sty.corner_radius_bottom_left  = 4
	bg_sty.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_sty)

	var fill_sty := StyleBoxFlat.new()
	fill_sty.bg_color = Color(0.2, 0.85, 0.35)
	fill_sty.corner_radius_top_left     = 4
	fill_sty.corner_radius_top_right    = 4
	fill_sty.corner_radius_bottom_left  = 4
	fill_sty.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_sty)
	row.add_child(bar)

	var max_hp: int = int(data["hp"]) * 2
	var val_lbl := Label.new()
	val_lbl.text = "%d / %d" % [max_hp, max_hp]
	val_lbl.custom_minimum_size = Vector2(84, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	row.add_child(val_lbl)

	card.set_meta("hpbar", bar)
	card.set_meta("hpval", val_lbl)
	return card


func _build_arena(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 0)
	parent.add_child(hbox)

	# プレイヤー大文字エリア
	var pl_area := _make_fighter_display(pl)
	hbox.add_child(pl_area)
	pl_big = pl_area.get_meta("lbl") as Label

	# バトルログ
	var log_panel := PanelContainer.new()
	log_panel.custom_minimum_size = Vector2(280, 0)
	var log_sty := StyleBoxFlat.new()
	log_sty.bg_color = Color(0.08, 0.06, 0.15)
	log_sty.border_color = Color(0.28, 0.2, 0.48)
	log_sty.border_width_left   = 1
	log_sty.border_width_right  = 1
	log_sty.border_width_top    = 0
	log_sty.border_width_bottom = 0
	log_panel.add_theme_stylebox_override("panel", log_sty)
	hbox.add_child(log_panel)

	var log_margin := MarginContainer.new()
	log_margin.add_theme_constant_override("margin_left",   10)
	log_margin.add_theme_constant_override("margin_right",  10)
	log_margin.add_theme_constant_override("margin_top",    10)
	log_margin.add_theme_constant_override("margin_bottom", 10)
	log_panel.add_child(log_margin)

	log_box = RichTextLabel.new()
	log_box.bbcode_enabled = true
	log_box.scroll_following = true
	log_box.add_theme_font_size_override("normal_font_size", 13)
	log_margin.add_child(log_box)

	# 敵大文字エリア
	var en_area := _make_fighter_display(en)
	hbox.add_child(en_area)
	en_big = en_area.get_meta("lbl") as Label


func _make_fighter_display(data: Dictionary) -> Control:
	var container := Control.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = str(data["hiragana"])
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 148)
	lbl.add_theme_color_override("font_color", data["color"] as Color)

	container.add_child(lbl)
	container.set_meta("lbl", lbl)
	return container


func _build_bottom_bar(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 108)
	var sty := StyleBoxFlat.new()
	sty.bg_color = Color(0.10, 0.07, 0.18)
	panel.add_theme_stylebox_override("panel", sty)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   36)
	margin.add_theme_constant_override("margin_right",  36)
	margin.add_theme_constant_override("margin_top",    12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	turn_lbl = Label.new()
	turn_lbl.text = "準備中…"
	turn_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(turn_lbl)

	act_box = HBoxContainer.new()
	act_box.add_theme_constant_override("separation", 16)
	act_box.visible = false
	vbox.add_child(act_box)

	var _mk_btn := func(label: String, color: Color) -> Button:
		var btn := Button.new()
		btn.text = label
		btn.custom_minimum_size = Vector2(168, 44)
		btn.add_theme_font_size_override("font_size", 15)
		var s := StyleBoxFlat.new()
		s.bg_color = color
		s.corner_radius_top_left     = 7
		s.corner_radius_top_right    = 7
		s.corner_radius_bottom_left  = 7
		s.corner_radius_bottom_right = 7
		btn.add_theme_stylebox_override("normal", s)
		var sh := StyleBoxFlat.new()
		sh.bg_color = color.lightened(0.18)
		sh.corner_radius_top_left     = 7
		sh.corner_radius_top_right    = 7
		sh.corner_radius_bottom_left  = 7
		sh.corner_radius_bottom_right = 7
		btn.add_theme_stylebox_override("hover", sh)
		var sp := StyleBoxFlat.new()
		sp.bg_color = color.darkened(0.2)
		sp.corner_radius_top_left     = 7
		sp.corner_radius_top_right    = 7
		sp.corner_radius_bottom_left  = 7
		sp.corner_radius_bottom_right = 7
		btn.add_theme_stylebox_override("pressed", sp)
		return btn

	var atk_btn: Button = _mk_btn.call("⚔ 通常攻撃", Color(0.22, 0.42, 0.72)) as Button
	act_box.add_child(atk_btn)
	atk_btn.pressed.connect(func() -> void: _on_player_action("attack"))

	spc_btn = _mk_btn.call("★ 必殺技", Color(0.50, 0.18, 0.72)) as Button
	act_box.add_child(spc_btn)
	spc_btn.pressed.connect(func() -> void: _on_player_action("special"))

	var grd_btn: Button = _mk_btn.call("🛡 防御", Color(0.18, 0.48, 0.32)) as Button
	act_box.add_child(grd_btn)
	grd_btn.pressed.connect(func() -> void: _on_player_action("guard"))


func _build_result_overlay() -> void:
	res_layer = ColorRect.new()
	res_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	res_layer.color = Color(0.0, 0.0, 0.0, 0.72)
	res_layer.visible = false
	add_child(res_layer)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380, 270)
	panel.position = Vector2(-190, -135)
	var psty := StyleBoxFlat.new()
	psty.bg_color = Color(0.10, 0.07, 0.20)
	psty.border_color = Color(0.50, 0.38, 0.78)
	psty.border_width_left   = 2
	psty.border_width_right  = 2
	psty.border_width_top    = 2
	psty.border_width_bottom = 2
	psty.corner_radius_top_left     = 14
	psty.corner_radius_top_right    = 14
	psty.corner_radius_bottom_left  = 14
	psty.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", psty)
	res_layer.add_child(panel)

	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left",   36)
	inner.add_theme_constant_override("margin_right",  36)
	inner.add_theme_constant_override("margin_top",    36)
	inner.add_theme_constant_override("margin_bottom", 36)
	panel.add_child(inner)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	inner.add_child(vb)

	res_title = Label.new()
	res_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_title.add_theme_font_size_override("font_size", 42)
	vb.add_child(res_title)

	res_sub = Label.new()
	res_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_sub.add_theme_font_size_override("font_size", 15)
	res_sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	vb.add_child(res_sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vb.add_child(spacer)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 14)
	vb.add_child(btn_row)

	var retry := Button.new()
	retry.text = "もう一度"
	retry.custom_minimum_size = Vector2(130, 44)
	retry.add_theme_font_size_override("font_size", 15)
	btn_row.add_child(retry)
	retry.pressed.connect(func() -> void: get_tree().reload_current_scene())

	var menu := Button.new()
	menu.text = "キャラ選択へ"
	menu.custom_minimum_size = Vector2(150, 44)
	menu.add_theme_font_size_override("font_size", 15)
	btn_row.add_child(menu)
	menu.pressed.connect(
		func() -> void: get_tree().change_scene_to_file("res://scenes/character_select.tscn")
	)
