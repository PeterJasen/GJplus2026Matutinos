if global.train_intro < 0.1 {
	part_particles_clear(smoke_sys)
}

// Bob: lerp each scale toward a sine-wave target
bob_timer += bob_speed;

var _target_loco = 1 + sin(bob_timer) * bob_amount;
var _target_car  = 1 + sin(bob_timer - carriage_phase) * bob_amount;
var _target_locoloco = 1 + sin(bob_timer - (carriage_phase * 3)) * bob_amount

yscale_locoloco = lerp(yscale_loco, _target_locoloco, bob_lerp);
yscale_loco = lerp(yscale_loco, _target_loco, bob_lerp);
yscale_car  = lerp(yscale_car,  _target_car,  bob_lerp);

// Advance animation
anim_frame += anim_speed;

//Smoke effect
var _xscale_car_step = 1 + (1 - yscale_car) * 0.5;

var _w = sprite_get_width(sprt_back_train_sheet);
var _h = sprite_get_height(sprt_back_train_sheet);

var _stack_x = x + (_w * stack_frac_x - sprite_get_xoffset(sprt_front_train_sheet)) * _xscale_car_step + 180;
var _stack_y = y + (_h * stack_frac_y - sprite_get_yoffset(sprt_front_train_sheet)) * yscale_car;

// Emit puffs on a timer
smoke_timer++;
if (smoke_timer >= smoke_rate) {
    smoke_timer = 0;
    part_particles_create(smoke_sys, _stack_x + random_range(-2, 2), _stack_y, smoke_part, 1);
}