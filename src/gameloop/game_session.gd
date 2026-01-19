class_name GameSession
extends Node

signal worth_changed(new_value: int)

const BET_WIN_MULTIPLIER := 2

enum ShellType {
	LIVE = 0,
	BLANK = 1
}

enum Reason {
	UNKNOWN		= 0,
	WINNER		= 1,
	SELFSHOT	= 2,
	KILLED 		= 3
}

@export var initial_bullets_count: int = 4
@export var target_worth: int = 999
@export var min_reroll_price: int = 5
@export var total_worth: int

@export var modifier_per_bullet: Array[int]

var reroll_price: int:
	get():
		var value := maxi(min_reroll_price, int(total_worth / 20.0))
		return value

var start_time: int
var end_time: int

var worth_spent: int

var round_record_worth: int

var dropped_bullets: int
var total_shots: int
var self_aiming_count: int
var dealer_aiming_count: int
var slot_machine_rolls: int
var player_lives: int = 3
var dealer_lives: int = 3
var current_bet: int = 0

var game_end_reason: Reason

var bullets_in_chamber: int

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func start() -> void:
	start_time = int(Time.get_unix_time_from_system())
	player_lives = 3
	dealer_lives = 3

func stop() -> void:
	end_time = int(Time.get_unix_time_from_system())

func get_playtime_line() -> String:
	var unix_time := end_time - start_time
	var dt := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d:%02d:%02d" % [dt.hour, dt.minute, dt.second]

func make_shot(bullet: Bullet, player: Player, to_dealer: bool) -> int:
	var modifier: int = 1 if to_dealer else get_selfshot_modifier()
	var worth := player.get_chamber_worth()
	var result := modifier * worth
	total_worth += result
	worth_changed.emit(total_worth)
	_update_statistic(bullet, result, to_dealer)
	return result

func update_chamber(chamber: Chamber) -> void:
	bullets_in_chamber = chamber.get_bullet_count()

func get_selfshot_modifier() -> int:
	if bullets_in_chamber < 1:
		return 1
	elif bullets_in_chamber > modifier_per_bullet.size():
		return 0
	
	return modifier_per_bullet[bullets_in_chamber - 1]

func is_target_reached() -> bool:
	return total_worth >= target_worth

func make_roll() -> void:
	slot_machine_rolls += 1

func can_purchase(cost: int) -> bool:
	return total_worth >= cost

func make_purchase(cost: int) -> void:
	total_worth -= cost
	worth_spent += cost
	worth_changed.emit(total_worth)

func get_score_line() -> String:
	return "%s/%s$" % [total_worth, target_worth]

func _update_statistic(bullet: Bullet, worth: int,  to_dealer: bool) -> void:
	if worth > round_record_worth:
		round_record_worth = worth
	
	if bullet:
		total_shots += 1
	
	if to_dealer:
		dealer_aiming_count += 1
	else:
		self_aiming_count += 1

func get_weighted_shell_count() -> int:
	var weighted := [2, 3, 4, 4, 4, 5, 5, 5, 6]
	return weighted[_rng.randi_range(0, weighted.size() - 1)]

func generate_round_shells(count: int) -> Array:
	var shell_count := clampi(count, 2, 6)
	var shells: Array = [ShellType.LIVE, ShellType.BLANK]
	for i in range(shell_count - 2):
		var value := ShellType.LIVE if _rng.randi_range(0, 1) == 0 else ShellType.BLANK
		shells.append(value)
	return shells

func shuffle_shells(shells: Array) -> Array:
	var result := shells.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result
