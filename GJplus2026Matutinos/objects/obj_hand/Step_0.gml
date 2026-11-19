// Variables
var _mX = mouse_x
var _mY = mouse_y
	
// Follows mouse
x = _mX
y = _mY

// Sprite handling
if mouse_check_button_pressed(mb_left) {
	sprite_index = 1
}
else sprite_index = 0