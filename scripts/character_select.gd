extends Control

const COLS := 3

var selected_index: int = 0
var character_cards: Array[Button] = []
var card_overlays: Array[ColorRect] = []

var info_hiragana: Label
var info_name: Label
var info_type: Label
var info_desc: Label
var hp_bar: ProgressBar
var hp_val: Label
var atk_bar: ProgressBar
var atk_val: Label
var spd_bar: ProgressBar
var spd_val: Label


func _ready() -> void:
	_build_ui()
	_select_character(0)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.07, 0.05, 0.14)
	add_child(bg)

	var main := HBoxContainer.new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_theme_constant_override("separation", 0)
	add_child(main)

	# ── 左パネル ──────────────────────────────────────
	var left_margin := MarginContainer.new()
	left_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_margin.add_theme_constant_override("margin_left",   48)
	left_margin.add_theme_constant_override("margin_right",  24)
	left_margin.add_theme_constant_override("margin_top",    40)
	left_margin.add_theme_constant_override("margin_bottom", 40)
	main.add_child(left_margin)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 18)
	left_margin.add_child(left)

	var game_title := Label.new()
	game_title.text = "ひらがな戦争"
	game_title.add_theme_font_size_override("font_size", 14)
	game_title.add_theme_color_override("font_color", Color(0.6, 0.5, 0.85))
	left.add_child(game_title)

	var select_title := Label.new()
	select_title.text = "キャラクター選択"
	select_title.add_theme_font_size_override("font_size", 32)
	select_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	left.add_child(select_title)

	var sep_line := ColorRect.new()
	sep_line.custom_minimum_size = Vector2(0, 2)
	sep_line.color = Color(0.4, 0.3, 0.65, 0.8)
	left.add_child(sep_line)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	left.add_child(grid)

	for i in range(GameManager.CHARACTERS.size()):
		var card := _make_card(i)
		grid.add_child(card)
		character_cards.append(card)

	var hints := Label.new()
	hints.text = "← → ↑ ↓ キーで選択　／　Enter で決定"
	hints.add_theme_font_size_override("font_size", 12)
	hints.add_theme_color_override("font_color", Color(0.5, 0.5, 0.65))
	left.add_child(hints)

	# ── 右パネル ──────────────────────────────────────
	var right_margin := MarginContainer.new()
	right_margin.custom_minimum_size = Vector2(300, 0)
	right_margin.add_theme_constant_override("margin_left",   24)
	right_margin.add_theme_constant_override("margin_right",  48)
	right_margin.add_theme_constant_override("margin_top",    40)
	right_margin.add_theme_constant_override("margin_bottom", 40)
	main.add_child(right_margin)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 16)
	right_margin.add_child(right)

	var info_panel := PanelContainer.new()
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = Color(0.12, 0.08, 0.22)
	info_style.border_color = Color(0.35, 0.25, 0.55)
	info_style.border_width_left   = 2
	info_style.border_width_right  = 2
	info_style.border_width_top    = 2
	info_style.border_width_bottom = 2
	info_style.corner_radius_top_left     = 12
	info_style.corner_radius_top_right    = 12
	info_style.corner_radius_bottom_left  = 12
	info_style.corner_radius_bottom_right = 12
	info_panel.add_theme_stylebox_override("panel", info_style)
	right.add_child(info_panel)

	var info_inner := MarginContainer.new()
	info_inner.add_theme_constant_override("margin_left",   28)
	info_inner.add_theme_constant_override("margin_right",  28)
	info_inner.add_theme_constant_override("margin_top",    28)
	info_inner.add_theme_constant_override("margin_bottom", 28)
	info_panel.add_child(info_inner)

	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 12)
	info_inner.add_child(info_vbox)

	info_hiragana = Label.new()
	info_hiragana.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_hiragana.add_theme_font_size_override("font_size", 100)
	info_vbox.add_child(info_hiragana)

	info_name = Label.new()
	info_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_name.add_theme_font_size_override("font_size", 20)
	info_name.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	info_vbox.add_child(info_name)

	info_type = Label.new()
	info_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_type.add_theme_font_size_override("font_size", 13)
	info_type.add_theme_color_override("font_color", Color(0.65, 0.75, 1.0))
	info_vbox.add_child(info_type)

	var div1 := ColorRect.new()
	div1.custom_minimum_size = Vector2(0, 1)
	div1.color = Color(0.35, 0.25, 0.55, 0.8)
	info_vbox.add_child(div1)

	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 10)
	info_vbox.add_child(stats_box)

	var hp_pair  := _make_stat_row(stats_box, "HP ", Color(0.25, 0.9, 0.35))
	hp_bar  = hp_pair[0] as ProgressBar;  hp_val  = hp_pair[1] as Label
	var atk_pair := _make_stat_row(stats_box, "ATK", Color(0.95, 0.35, 0.25))
	atk_bar = atk_pair[0] as ProgressBar; atk_val = atk_pair[1] as Label
	var spd_pair := _make_stat_row(stats_box, "SPD", Color(0.25, 0.65, 0.95))
	spd_bar = spd_pair[0] as ProgressBar; spd_val = spd_pair[1] as Label

	var div2 := ColorRect.new()
	div2.custom_minimum_size = Vector2(0, 1)
	div2.color = Color(0.35, 0.25, 0.55, 0.8)
	info_vbox.add_child(div2)

	info_desc = Label.new()
	info_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_desc.add_theme_font_size_override("font_size", 13)
	info_desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.9))
	info_vbox.add_child(info_desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(spacer)

	# 決定ボタン
	var confirm_btn := Button.new()
	confirm_btn.text = "決　定"
	confirm_btn.custom_minimum_size = Vector2(0, 56)
	confirm_btn.add_theme_font_size_override("font_size", 20)

	var _mk_sty := func(bg: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.corner_radius_top_left     = 8
		s.corner_radius_top_right    = 8
		s.corner_radius_bottom_left  = 8
		s.corner_radius_bottom_right = 8
		return s

	confirm_btn.add_theme_stylebox_override("normal",  _mk_sty.call(Color(0.35, 0.2,  0.65)) as StyleBoxFlat)
	confirm_btn.add_theme_stylebox_override("hover",   _mk_sty.call(Color(0.45, 0.3,  0.78)) as StyleBoxFlat)
	confirm_btn.add_theme_stylebox_override("pressed", _mk_sty.call(Color(0.25, 0.15, 0.5))  as StyleBoxFlat)
	right.add_child(confirm_btn)
	confirm_btn.pressed.connect(_on_confirm)


func _make_card(index: int) -> Button:
	var data: Dictionary = GameManager.CHARACTERS[index]

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(128, 128)
	btn.focus_mode = Control.FOCUS_NONE

	var _card_sty := func(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.border_width_left   = bw
		s.border_width_right  = bw
		s.border_width_top    = bw
		s.border_width_bottom = bw
		s.corner_radius_top_left     = 10
		s.corner_radius_top_right    = 10
		s.corner_radius_bottom_left  = 10
		s.corner_radius_bottom_right = 10
		return s

	btn.add_theme_stylebox_override("normal",  _card_sty.call(Color(0.12, 0.09, 0.22), Color(0.3, 0.22, 0.5),  2) as StyleBoxFlat)
	btn.add_theme_stylebox_override("hover",   _card_sty.call(Color(0.18, 0.13, 0.32), data["color"] as Color, 2) as StyleBoxFlat)
	btn.add_theme_stylebox_override("pressed", _card_sty.call(Color(0.22, 0.16, 0.40), data["color"] as Color, 3) as StyleBoxFlat)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(1.0, 0.92, 0.4, 0.12)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	btn.add_child(overlay)
	card_overlays.append(overlay)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var hira := Label.new()
	hira.text = str(data["hiragana"])
	hira.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hira.add_theme_font_size_override("font_size", 54)
	hira.add_theme_color_override("font_color", data["color"] as Color)
	hira.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hira)

	var name_lbl := Label.new()
	name_lbl.text = str(data["name"])
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.85))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	btn.pressed.connect(func() -> void: _select_character(index))
	return btn


func _make_stat_row(parent: VBoxContainer, label_text: String, bar_color: Color) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(38, 0)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.88))
	row.add_child(lbl)

	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.custom_minimum_size = Vector2(0, 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.1, 0.2)
	bar_bg.corner_radius_top_left     = 4
	bar_bg.corner_radius_top_right    = 4
	bar_bg.corner_radius_bottom_left  = 4
	bar_bg.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = bar_color
	bar_fill.corner_radius_top_left     = 4
	bar_fill.corner_radius_top_right    = 4
	bar_fill.corner_radius_bottom_left  = 4
	bar_fill.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", bar_fill)

	row.add_child(bar)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size = Vector2(32, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", bar_color)
	row.add_child(val_lbl)

	return [bar, val_lbl]


func _select_character(index: int) -> void:
	selected_index = index
	var data: Dictionary = GameManager.CHARACTERS[index]

	info_hiragana.text = str(data["hiragana"])
	info_hiragana.add_theme_color_override("font_color", data["color"] as Color)
	info_name.text = str(data["name"])
	info_type.text = "[ " + str(data["type"]) + " ]"
	info_desc.text = str(data["desc"])

	hp_bar.value  = float(data["hp"]);   hp_val.text  = str(data["hp"])
	atk_bar.value = float(data["atk"]);  atk_val.text = str(data["atk"])
	spd_bar.value = float(data["spd"]);  spd_val.text = str(data["spd"])

	for i in range(character_cards.size()):
		if i == selected_index:
			character_cards[i].modulate = Color.WHITE
			card_overlays[i].visible = true
		else:
			character_cards[i].modulate = Color(0.6, 0.6, 0.72)
			card_overlays[i].visible = false


func _on_confirm() -> void:
	GameManager.selected_character_index = selected_index
	GameManager.selected_character = GameManager.CHARACTERS[selected_index].duplicate()
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	var new_index := selected_index
	match event.keycode:
		KEY_LEFT:
			if selected_index % COLS > 0:
				new_index = selected_index - 1
		KEY_RIGHT:
			if selected_index % COLS < COLS - 1 and selected_index + 1 < GameManager.CHARACTERS.size():
				new_index = selected_index + 1
		KEY_UP:
			if selected_index >= COLS:
				new_index = selected_index - COLS
		KEY_DOWN:
			if selected_index + COLS < GameManager.CHARACTERS.size():
				new_index = selected_index + COLS
		KEY_ENTER, KEY_KP_ENTER:
			_on_confirm()
			return

	if new_index != selected_index:
		_select_character(new_index)
		get_viewport().set_input_as_handled()
