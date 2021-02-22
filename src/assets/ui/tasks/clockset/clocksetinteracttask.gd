tool
extends InteractTask

signal times_updated(target, current, task_res)

func _init():
	add_networked_func("receive_times", MultiplayerAPI.RPC_MODE_REMOTE)

# warning-ignore:unused_argument
func _complete_task(player_id: int, data: Dictionary):
	sync_task()

# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _can_complete_task(player_id: int, data: Dictionary):
	return get_target_time() == get_current_time()

func _sync_task():
	send_times(get_target_time(), get_current_time())

#func _init_resource(_from: Node):
#	if not get_tree().is_network_server():
#		return
#	target_time = gen_rand_time()
#	current_time = gen_rand_time()
#	emit_signal("times_updated", target_time, current_time, self)

# warning-ignore:unused_argument
func _get_task_data(player_id: int) -> Dictionary:
	var dict: Dictionary = {}
	dict["newText"] = str(get_current_time())
	return dict

func _gen_player_task_data(player_id: int) -> Dictionary:
	var data: Dictionary = {}
	data["target_time"] = gen_rand_time()
	data["current_time"] = gen_rand_time()
	return data

func _registered(_new_task_id: int, new_task_data: Dictionary):
	# calling is_network_server() on task manager because the function does not
	# 	exist in resources
	if TaskManager.get_tree().is_network_server():
		return
	for property in ["target_time", "current_time"]:
		if new_task_data.has(property):
			set(property, new_task_data[property])

func set_target_time(time: int, player_id: int = Network.get_my_id()):
	set_task_data_player_value("target_time", time, player_id)

func get_target_time() -> int:
	return get_task_data_player_value("target_time")

func set_current_time(time: int, player_id: int = Network.get_my_id()):
	set_task_data_player_value("current_time", time, player_id)

func get_current_time() -> int:
	return get_task_data_player_value("current_time")

func gen_rand_time() -> int:
	return normalise_time(randi())

func send_times(target: int, current: int, player_id: int = Network.get_my_id()):
	if task_registered and is_task_global():
		player_id = TaskManager.GLOBAL_TASK_PLAYER_ID
	#print("sending times out to network")
	task_rpc("receive_times", [target, current, player_id])

func receive_times(target: int, current: int, player_id: int):
	print("received times, target: ", target, " current: ", current)
	set_target_time(target, player_id)
	set_current_time(current, player_id)
	emit_signal("times_updated", get_target_time(), get_current_time(), self)

# returns a valid time(from 00:00 to 12:59)
# num can be any value
func normalise_time(num: int) -> int:
	num = num % 1259
	num = roundDown(num, 100) + (num % 100) % 60
	if num < 100:
		# this is military time, so can't have values smaller than 100
		num += 1200
	return num
	
func roundDown(num, step) -> int:
	var normRound = stepify(num, step)
	if normRound > num:
		return normRound - step
	return int(normRound)
