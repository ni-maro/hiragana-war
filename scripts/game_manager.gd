extends Node

const CHARACTERS = [
	{
		"hiragana": "あ", "name": "和の戦士", "type": "バランス型",
		"hp": 80, "atk": 70, "spd": 70,
		"desc": "すべてのステータスが均整のとれた戦士。\n初心者にも扱いやすい。",
		"color": Color(0.4, 0.6, 1.0)
	},
	{
		"hiragana": "い", "name": "疾風の剣士", "type": "スピード型",
		"hp": 60, "atk": 75, "spd": 95,
		"desc": "素早い連続攻撃を得意とする剣士。\n低い体力をスピードで補う。",
		"color": Color(0.2, 0.9, 0.6)
	},
	{
		"hiragana": "う", "name": "海神の盾", "type": "タンク型",
		"hp": 100, "atk": 55, "spd": 45,
		"desc": "圧倒的な防御力を誇る守護者。\n粘り強い戦いが得意。",
		"color": Color(0.2, 0.5, 0.95)
	},
	{
		"hiragana": "え", "name": "炎の魔道士", "type": "アタック型",
		"hp": 55, "atk": 100, "spd": 60,
		"desc": "強力な魔法で一撃必殺を狙う。\n体力は低いが攻撃力は最高峰。",
		"color": Color(0.95, 0.35, 0.2)
	},
	{
		"hiragana": "お", "name": "大地の賢者", "type": "バランス型",
		"hp": 75, "atk": 80, "spd": 55,
		"desc": "古代の知恵を持つ賢者。\n攻撃と防御のバランスが良い。",
		"color": Color(0.6, 0.85, 0.25)
	},
	{
		"hiragana": "か", "name": "雷鳴の忍者", "type": "スピード型",
		"hp": 65, "atk": 85, "spd": 90,
		"desc": "電光石火の攻撃を繰り出す忍者。\n攻撃とスピードが高い。",
		"color": Color(0.95, 0.85, 0.15)
	},
	{
		"hiragana": "き", "name": "霧の暗殺者", "type": "アタック型",
		"hp": 50, "atk": 98, "spd": 82,
		"desc": "闇に潜む暗殺者。一撃の破壊力は\n計り知れない。上級者向け。",
		"color": Color(0.6, 0.2, 0.85)
	},
	{
		"hiragana": "く", "name": "鋼鉄の巨人", "type": "タンク型",
		"hp": 98, "atk": 65, "spd": 37,
		"desc": "鉄壁の守りを持つ巨人。\nゆっくりだが確実にダメージを与える。",
		"color": Color(0.6, 0.65, 0.7)
	},
	{
		"hiragana": "け", "name": "天空の騎士", "type": "バランス型",
		"hp": 72, "atk": 76, "spd": 72,
		"desc": "空を駆ける騎士。機動力と攻撃力を\n兼ね備えた頼れる存在。",
		"color": Color(0.3, 0.8, 0.95)
	},
]

var selected_character_index: int = 0
var selected_character: Dictionary = {}
