// Variables
carriage_gap = -400

// Bobbing
bob_timer     = 0;
bob_speed     = 0.15;   // how fast it bobs
bob_amount    = 0.06;   // how far the scale swings (0.06 = ±6%)
bob_lerp      = 0.25;   // how snappy the smoothing is (0-1)
yscale_loco   = 1;
yscale_car    = 1;
carriage_phase = 1.2;   // phase offset so the carriage bobs slightly after the loco

// Frame looping (frames advanced per step)
anim_speed    = 0.2;
anim_frame    = 0;

// Stack position as a fraction of the sprite
stack_frac_x = 0.95;
stack_frac_y = 0.10;

// Particle system, drawn just behind the train
smoke_sys = part_system_create();
part_system_depth(smoke_sys, depth -1);
smoke_part = part_type_create();

var _life_min = 110;
var _life_max = 150;
var _life_avg = (_life_min + _life_max) * 0.5;
var _turn = 90 / _life_avg;

part_type_shape(smoke_part, pt_shape_disk); 
part_type_size(smoke_part, 0.10, 0.45, 0.006, 0);  // starts small, slowly grows
part_type_orientation(smoke_part, 0, 360, 2, 0, false);
part_type_color3(smoke_part, c_ltgray, c_gray, c_dkgray);
part_type_alpha3(smoke_part, 0.9, 0.6, 0);         // fades out
part_type_speed(smoke_part, 1.5, 2.5, -0.02, 0);
part_type_direction(smoke_part, 85, 100, 0, 0);    // up and drifting backwards
part_type_gravity(smoke_part, 0.15, 195);         
part_type_life(smoke_part, 90, 130);

smoke_timer = 0;
smoke_rate  = 2;   // steps between puffs (lower = thicker smoke)
