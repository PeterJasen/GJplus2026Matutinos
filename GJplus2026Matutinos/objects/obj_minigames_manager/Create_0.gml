// Random seed
randomize();

// Variables
var room_middle_x = room_width / 2
var room_middle_y = room_height / 2

// Handler
if (room == rm_engine_spin) {
	if (!instance_exists(obj_valve)) {
		show_debug_message("got here")
		instance_create_layer(room_middle_x, room_middle_y, "Instances", obj_valve)
	};
		
	if (!instance_exists(obj_hand)) {
		instance_create_layer(room_middle_x, room_middle_y, "Instances", obj_hand)
		show_debug_message("created hand")
	};
};