// Toggle debug menu with Backspace
if (keyboard_check_pressed(vk_backspace)) {
    debug_menu_open = !debug_menu_open;
}

if (travel_state == "menu") {
    var menu_gui_w = display_get_gui_width();
    var menu_gui_h = display_get_gui_height();

    var menu_button_left = menu_gui_w / 2 - 120;
    var menu_button_top = menu_gui_h / 2 + 30;

    var menu_mouse_x = device_mouse_x_to_gui(0);
    var menu_mouse_y = device_mouse_y_to_gui(0);

    var clicked_play = mouse_check_button_pressed(mb_left)
        && menu_mouse_x >= menu_button_left
        && menu_mouse_x <= menu_button_left + 240
        && menu_mouse_y >= menu_button_top
        && menu_mouse_y <= menu_button_top + 64;

    if (keyboard_check_pressed(vk_enter)
        || keyboard_check_pressed(vk_space)
        || clicked_play) {

        audio_stop_all();

        audio_play_sound(sfx_trainhowl, 1, false, 1);
        start_game();
    }

    exit;
}


// Intro: train slides in from the left
if (travel_state == "intro") {

    // Skip with Space or Enter
    if (keyboard_check_pressed(vk_space)
        || keyboard_check_pressed(vk_enter)) {

        intro_timer = intro_duration;
    }

    intro_timer += delta_time / 1000000;

    var intro_t = clamp(intro_timer / intro_duration, 0, 1);

    // Calculate the train's animation position
    global.train_intro = 1 - power(1 - intro_t, 1.2);

    // Move the train
    if (instance_exists(obj_train_visual)) {
        with (obj_train_visual) {
            x = lerp(-286, 206, global.train_intro);
        }
    }

    // Finish intro when animation completes or gets skipped
    if (intro_t >= 1) {

        global.train_intro = 1;

        travel_state = "travelling";
        travel_elapsed = 0;
        next_event_time = random_range(8, 15);

        // Stop intro sound and start gameplay audio
        audio_stop_all();

        audio_play_sound(sfx_howling, true, true, 0.7);
        audio_play_sound(sfx_train, true, true, 0.6);
        audio_play_sound(sfx_mainmusic, true, true, 0.7);
    }

    exit;
}


// Finale: the train rolls off to the right, then the victory screen

if (travel_state == "finale") {

    // Space or Enter skips the animation
    if (keyboard_check_pressed(vk_space)
        || keyboard_check_pressed(vk_enter)) {

        finale_timer = finale_duration;

    } else {

        finale_timer += delta_time / 1000000;
    }

    var finale_t = clamp(finale_timer / finale_duration, 0, 1);

    if (instance_exists(obj_train_visual)) {

        var train_id = instance_find(obj_train_visual, 0);

        if (train_id != noone) {
            train_id.x = lerp(
                finale_from_x,
                finale_end_x,
                power(finale_t, 2)
            );
        }
    }

    if (finale_t >= 1) {
        trigger_win(finale_ending);
    }

    exit;
}


// ============================================================
// DEATH ANIMATION
// ============================================================

if (travel_state == "death") {

    // Skip death animation with Space or Enter
    if (keyboard_check_pressed(vk_space)
        || keyboard_check_pressed(vk_enter)) {

        death_timer = death_duration;

    } else {

        death_timer += delta_time / 1000000;
    }

    var death_t = clamp(death_timer / death_duration, 0, 1);

    // Shake the train while it comes to a stop
    var shake_strength = (1 - death_t) * 7;

    if (instance_exists(obj_train_visual)) {

        var train_id = instance_find(obj_train_visual, 0);

        if (train_id != noone) {

            train_id.x = death_start_x
                + sin(death_timer * 50) * shake_strength;
        }
    }

    // Finish the animation
    if (death_t >= 1) {

        // Restore the train's final position
        if (instance_exists(obj_train_visual)) {

            var stopped_train = instance_find(obj_train_visual, 0);

            if (stopped_train != noone) {
                stopped_train.x = death_start_x;
            }
        }

        game_over = true;
        travel_state = "game_over";
    }

    exit;
}

// ============================================================
// DEATH ANIMATION
// ============================================================

if (travel_state == "death") {

    // Skip death animation with Space or Enter
    if (keyboard_check_pressed(vk_space)
        || keyboard_check_pressed(vk_enter)) {

        death_timer = death_duration;

    } else {

        death_timer += delta_time / 1000000;
    }

    var death_t = clamp(death_timer / death_duration, 0, 1);

    // Shake the train while it comes to a stop
    var shake_strength = (1 - death_t) * 7;

    if (instance_exists(obj_train_visual)) {

        var train_id = instance_find(obj_train_visual, 0);

        if (train_id != noone) {

            train_id.x = death_start_x
                + sin(death_timer * 50) * shake_strength;
        }
    }

    // Finish the animation
    if (death_t >= 1) {

        // Restore the train's final position
        if (instance_exists(obj_train_visual)) {

            var stopped_train = instance_find(obj_train_visual, 0);

            if (stopped_train != noone) {
                stopped_train.x = death_start_x;
            }
        }

        game_over = true;
        travel_state = "game_over";
    }

    exit;
}

if (game_over || game_won) {

    // Start the end sound once (not every step)
    if (!end_sound_played) {
        end_sound_played = true;
        audio_stop_all();

        if (game_won) {
            audio_play_sound(sfx_win, true, true, 0.7);
        } else {
            audio_play_sound(sfx_loss, true, false, 0.7);
        }
    }

    var game_over_gui_w = display_get_gui_width();
    var game_over_gui_h = display_get_gui_height();
    var replay_button_left = game_over_gui_w / 2 - 150;
    var replay_button_top = game_over_gui_h / 2 + 105;
    var game_over_mouse_x = device_mouse_x_to_gui(0);
    var game_over_mouse_y = device_mouse_y_to_gui(0);
    var clicked_replay = mouse_check_button_pressed(mb_left)
        && game_over_mouse_x >= replay_button_left && game_over_mouse_x <= replay_button_left + 300
        && game_over_mouse_y >= replay_button_top && game_over_mouse_y <= replay_button_top + 64;

    if (keyboard_check_pressed(vk_enter)
        || keyboard_check_pressed(vk_space)
        || keyboard_check_pressed(ord("R"))
        || clicked_replay) {
        game_over = false;
        game_won = false;
        game_over_reason = "";
        win_ending = "";
        travel_state = "menu";
    }
    exit;
}

var gui_mouse_x = device_mouse_x_to_gui(0);
var gui_mouse_y = device_mouse_y_to_gui(0);

// Heal actions: medicine -> crew health, tools -> train health
// (keyboard: M / R, or click the buttons next to the health bars)
if (keyboard_check_pressed(ord("M"))) {
    use_medicine();
}

if (keyboard_check_pressed(ord("R"))) {
    use_tools();
}

if (mouse_check_button_pressed(mb_left)) {
    for (var i = 0; i < 2; i++) {
        var action_btn = get_action_button(i);

        if (point_in_rectangle(gui_mouse_x, gui_mouse_y,
                action_btn.x, action_btn.y,
                action_btn.x + action_btn.w, action_btn.y + action_btn.h)) {

            if (i == 0) {
                use_medicine();
            } else {
                use_tools();
            }
            exit;
        }
    }
}

// Debug buttons (only clickable while the debug menu is open)
if (debug_menu_open && mouse_check_button_pressed(mb_left)) {

    var debug_gui_w = display_get_gui_width();
    var debug_button_left = debug_gui_w - 255;
    var debug_button_top = 54;
    var debug_button_width = 255;
    var debug_button_height = 38;
    var debug_button_gap = 8;

    for (var i = 0; i < array_length(debug_game_over_buttons); i++) {
        var button_top = debug_button_top + i * (debug_button_height + debug_button_gap);

        if (gui_mouse_x >= debug_button_left
            && gui_mouse_x <= debug_button_left + debug_button_width
            && gui_mouse_y >= button_top
            && gui_mouse_y <= button_top + debug_button_height) {
            trigger_game_over(debug_game_over_buttons[i].reason);
            exit;
        }
    }

    var debug_win_button_top = debug_button_top
        + array_length(debug_game_over_buttons) * (debug_button_height + debug_button_gap)
        + 32;
    for (var i = 0; i < array_length(debug_win_condition_button); i++) {
        var win_button_top = debug_win_button_top + i * (debug_button_height + debug_button_gap);

        if (gui_mouse_x >= debug_button_left
            && gui_mouse_x <= debug_button_left + debug_button_width
            && gui_mouse_y >= win_button_top
            && gui_mouse_y <= win_button_top + debug_button_height) {
			begin_finale();
            finale_ending = debug_win_condition_button[i].ending;
            exit;
        }
    }
}

var dt = delta_time / 1000000;  // Measured in microseconds, dividing by a million turns it into seconds

// Message timer
if (message_timer > 0) {
    message_timer -= dt;
}

if (feedback_timer > 0) {
    feedback_timer -= dt;
}

// Travel progression
if (travel_state == "travelling") {

    travel_elapsed += dt;
    journey_time += dt;   // the meter only runs while travelling (it pauses during major events)

    if (journey_time >= journey_length) {

        begin_finale();

    } else if (travel_elapsed >= next_event_time) {

        trigger_event();
    }
}

// Major event input
if (travel_state == "major_event") {

    if (keyboard_check_pressed(ord("1"))) {
        resolve_choice(0);
    }

    if (keyboard_check_pressed(ord("2"))) {
        resolve_choice(1);
    }

    if (keyboard_check_pressed(ord("3"))) {
        resolve_choice(2);
    }
}
