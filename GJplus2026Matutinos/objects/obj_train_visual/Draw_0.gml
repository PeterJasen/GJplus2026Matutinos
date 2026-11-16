// Calculate the carriage position
var _carriage_x = x - sprite_get_width(sprt_front_train_sheet) - carriage_gap;

// Wrap frames per sprite (they may have different frame counts)
var _car_frame  = anim_frame mod sprite_get_number(sprt_front_train_sheet);
var _loco_frame = anim_frame mod sprite_get_number(sprt_back_train_sheet);
var _locoloco_frame = anim_frame mod sprite_get_number(sprt_backback_train_sheet);

// Draw the locomotives
draw_sprite_ext(
    sprt_backback_train_sheet,
    _locoloco_frame,
    x - 140,
    y,
    1,
    yscale_locoloco,
    0,
    c_white,
    1
);

draw_sprite_ext(
    sprt_back_train_sheet,
    _loco_frame,
    x,
    y,
    1,
    yscale_loco,
    0,
    c_white,
    1
);

// Draw the carriage
draw_sprite_ext(
    sprt_front_train_sheet,
    _car_frame,
    _carriage_x,
    y,
    1,
    yscale_car,
    0,          // rotation
    c_white,    // blend colour
    1           // alpha
);

