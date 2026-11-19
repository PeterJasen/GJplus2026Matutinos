draw_set_color(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

if (travel_state == "menu") {
    var menu_gui_w = display_get_gui_width();
    var menu_gui_h = display_get_gui_height();
    var menu_button_left = menu_gui_w / 2 - 120;
    var menu_button_top = menu_gui_h / 2 + 30;

    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_rectangle(0, 0, menu_gui_w, menu_gui_h, false);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text(menu_gui_w / 2, menu_gui_h / 2 - 75, lang("MENU_TITLE"));
    draw_set_color(c_gray);
    draw_text(menu_gui_w / 2, menu_gui_h / 2 - 25, lang("MENU_SUBTITLE"));

    draw_set_color(c_white);
    draw_rectangle(menu_button_left, menu_button_top, menu_button_left + 240, menu_button_top + 64, false);
    draw_set_color(c_black);
    draw_text(menu_gui_w / 2, menu_button_top + 32, lang("MENU_PLAY"));
    draw_set_color(c_gray);
    draw_text(menu_gui_w / 2, menu_button_top + 98, lang("MENU_CLICK_PLAY"));

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    exit;
}

// Intro: display skip instruction

// ============================================================
// CUTSCENE INSTRUCTIONS
// ============================================================

if (travel_state == "intro" || travel_state == "finale") {

    var gui_w = display_get_gui_width();
    var gui_h = display_get_gui_height();

    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_text(
        gui_w / 2,
        gui_h - 30,
        lang("MENU_SKIP")
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    exit;
}

// ============================================================
// DEATH ANIMATION SCREEN
// ============================================================

if (travel_state == "death") {

    var gui_w = display_get_gui_width();
    var gui_h = display_get_gui_height();

    var death_t = clamp(death_timer / death_duration, 0, 1);

    // Fade the screen to black
    draw_set_alpha(death_t * 0.8);
    draw_set_color(c_black);

    draw_rectangle(
        0,
        0,
        gui_w,
        gui_h,
        true
    );

    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_text(
        gui_w / 2,
        gui_h - 35,
        lang("MENU_SKIP")
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    exit;
}

// Finale: no HUD
if (travel_state == "finale") {
    exit;
}

var chips = [
    {label: lang("GAME_FOOD"),     value: resources.food,     warn: ration_food},
    {label: lang("GAME_WATER"),    value: resources.water,    warn: ration_water},
    {label: lang("GAME_FUEL"),     value: resources.fuel,     warn: 3},
    {label: lang("GAME_MEDICINE"), value: resources.medicine, warn: 0},
    {label: lang("GAME_TOOLS"),    value: resources.tools,    warn: 0}
];

draw_set_halign(fa_left);
draw_set_valign(fa_middle);

for (var i = 0; i < array_length(chips); i++) {

    var chip = get_resource_chip(i);
    var chip_value = chips[i].value;
    var chip_color = c_white;

    if (chip_value <= 0) {
        chip_color = c_red;
    } else if (chip_value < chips[i].warn) {
        chip_color = c_yellow;
    }

    draw_set_alpha(0.65);
    draw_set_color(c_black);
    draw_rectangle(chip.x, chip.y, chip.x + chip.w, chip.y + chip.h, false);

    draw_set_alpha(1);
    draw_set_color(chip_color);
    draw_rectangle(chip.x, chip.y, chip.x + chip.w, chip.y + chip.h, true);
    draw_text(chip.x + 8, chip.y + chip.h / 2, chips[i].label + ": " + string(chip_value));
}

// ---------- Health bars + action buttons ----------
for (var i = 0; i < 2; i++) {

    var bar = get_health_bar(i);
    var hp     = (i == 0) ? resources.crew_health : resources.train_health;
    var hp_max = (i == 0) ? crew_health_max : train_health_max;
    var hp_name = (i == 0) ? lang("MENU_CREW") : lang("MENU_TRAIN");
    var hp_pct = clamp(hp / hp_max, 0, 1);

    // Bar background
    draw_set_alpha(0.65);
    draw_set_color(c_black);
    draw_rectangle(bar.x, bar.y, bar.x + bar.w, bar.y + bar.h, false);

    // Fill: red when low, green when healthy
    draw_set_alpha(1);
    if (hp_pct > 0) {
        draw_set_color(merge_color(make_color_rgb(190, 40, 40), make_color_rgb(60, 160, 80), hp_pct));
        draw_rectangle(bar.x, bar.y, bar.x + bar.w * hp_pct, bar.y + bar.h, false);
    }

    draw_set_color(c_white);
    draw_rectangle(bar.x, bar.y, bar.x + bar.w, bar.y + bar.h, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(bar.x + bar.w / 2, bar.y + bar.h / 2, hp_name + " " + lang("MENU_HEALTH") + "  " + string(hp) + "/" + string(hp_max));

    // Button: medicine heals the crew, tools repair the train
    var btn = get_action_button(i);
    var btn_enabled = (i == 0) ? can_use_medicine() : can_use_tools();
    var btn_label = (i == 0)
        ? lang("MENU_USE_MEDICINE") + string(heal_amount)
        : lang("MENU_USE_TOOL") + string(heal_amount);

    draw_set_alpha(0.8);
    draw_set_color(btn_enabled ? c_dkgray : c_black);
    draw_rectangle(btn.x, btn.y, btn.x + btn.w, btn.y + btn.h, false);

    draw_set_alpha(1);
    draw_set_color(btn_enabled ? c_white : c_dkgray);
    draw_rectangle(btn.x, btn.y, btn.x + btn.w, btn.y + btn.h, true);

    draw_set_color(btn_enabled ? c_white : c_gray);
    draw_text(btn.x + btn.w / 2, btn.y + btn.h / 2, btn_label);
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);

// ---------- Journey meter (bottom of the screen) ----------
if (travel_state == "travelling" || travel_state == "major_event") {

    var meter_x = 32;
    var meter_w = display_get_gui_width() - 64;
    var meter_h = 20;
    var meter_y = display_get_gui_height() - 48;
    var journey_pct = clamp(journey_time / journey_length, 0, 1);
    var secs_left = ceil(max(0, journey_length - journey_time));
    var secs_text = string(secs_left mod 60);
    if (secs_left mod 60 < 10) secs_text = "0" + secs_text;

    draw_set_alpha(0.65);
    draw_set_color(c_black);
    draw_rectangle(meter_x, meter_y, meter_x + meter_w, meter_y + meter_h, false);

    draw_set_alpha(1);
    if (journey_pct > 0) {
        draw_set_color(make_color_rgb(220, 180, 70));
        draw_rectangle(meter_x, meter_y, meter_x + meter_w * journey_pct, meter_y + meter_h, false);
    }

    draw_set_color(c_white);
    draw_rectangle(meter_x, meter_y, meter_x + meter_w, meter_y + meter_h, true);

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(
        meter_x + meter_w / 2,
        meter_y + meter_h / 2,
        lang("MENU_JOURNEY") + "  " + string(floor(journey_pct * 100)) + "%"
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}

// ---------- Upkeep info / last-chance warning ----------
if (travel_state == "travelling" || travel_state == "major_event") {

    var events_to_ration = ration_interval - events_since_ration;

    if (ration_warning) {

        // A ration check already failed: the next failed one ends the journey
        draw_set_color(c_red);
        draw_text(
            16,
            150,
            lang("MENU_LAST_CHANCE_1") + ration_warning_text + lang("MENU_LAST_CHANCE_2")
            + string(ration_food) + lang("MENU_LAST_CHANCE_3") + string(ration_water) + lang("MENU_LAST_CHANCE_4")
            + string(events_to_ration) + lang("MENU_LAST_CHANCE_5")
        );

    } else {

        draw_set_color(c_gray);
        draw_text(
            16,
            150,
            lang("MENU_ROUTINE_1") + string(coal_per_event) + lang("MENU_ROUTINE_2")
            + string(events_to_ration) + lang("MENU_ROUTINE_3")
            + string(ration_food) + lang("MENU_ROUTINE_4") + string(ration_water) + lang("MENU_ROUTINE_5")
        );
    }

    draw_set_color(c_white);
}

// ---------- Travel status ----------
if (travel_state == "travelling") {

    draw_text(16, 186, lang("MENU_TRAVELLING"));

    draw_text(
        16,
        214,
        lang("MENU_NEXT_EVENT") +
        string_format(max(0, next_event_time - travel_elapsed), 1, 1)
    );
}

// ============================================================
// NOTIFICATION STACK
// ============================================================

var gui_w = display_get_gui_width();

var notification_x = gui_w - 444;
var notification_y = 24;
var notification_w = 420;
var notification_padding = 14;


// ============================================================
// MAJOR EVENT NOTIFICATION
// ============================================================

if (travel_state == "major_event" && !is_undefined(current_event)) {

    var content_w = notification_w - notification_padding * 2;

    var title_h = string_height_ext(current_event.title, -1, content_w);
    var desc_h = string_height_ext(current_event.description, -1, content_w);

    var choices_h = 0;

    for (var i = 0; i < array_length(current_event.choices); i++) {

        var choice = current_event.choices[i];
        var choice_text = string(i + 1) + ". " + choice.text;

        if (!event_is_available(choice)) {
            choice_text += lang("MENU_UNAVAILABLE");
        }

        choices_h += string_height_ext(choice_text, -1, content_w) + 8;
    }

    var box_h = notification_padding * 2
        + title_h + 12
        + desc_h + 16
        + choices_h;

    // Background
    draw_set_alpha(0.90);
    draw_set_color(c_white);
    draw_rectangle(
        notification_x,
        notification_y,
        notification_x + notification_w,
        notification_y + box_h,
        false
    );

    // Border
    draw_set_alpha(1);
    draw_set_color(c_dkgray);
    draw_rectangle(
        notification_x,
        notification_y,
        notification_x + notification_w,
        notification_y + box_h,
        true
    );

    var text_y = notification_y + notification_padding;

    // Title
    draw_set_color(c_black);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    draw_text_ext(
        notification_x + notification_padding,
        text_y,
        current_event.title,
        -1,
        content_w
    );

    text_y += title_h + 12;

    // Description
    draw_set_color(c_dkgray);

    draw_text_ext(
        notification_x + notification_padding,
        text_y,
        current_event.description,
        -1,
        content_w
    );

    text_y += desc_h + 16;

    // Choices
    for (var i = 0; i < array_length(current_event.choices); i++) {

        var choice = current_event.choices[i];
        var available = event_is_available(choice);

        var choice_text = string(i + 1) + ". " + choice.text;

        if (available) {
            draw_set_color(c_black);
        } else {
            draw_set_color(c_gray);
            choice_text += lang("MENU_UNAVAILABLE");
        }

        draw_text_ext(
            notification_x + notification_padding,
            text_y,
            choice_text,
            -1,
            content_w
        );

        text_y += string_height_ext(choice_text, -1, content_w) + 8;
    }

    // Move the next notification below this one
    notification_y += box_h + 12;
}


// ============================================================
// EVENT RESULT NOTIFICATION
// ============================================================

if (message_timer > 0) {

    var box_padding = 14;
    var box_w = notification_w;
    var text_w = box_w - box_padding * 2;

    var text_h = string_height_ext(event_message, -1, text_w);
    var box_h = text_h + box_padding * 2;

    // Background
    draw_set_alpha(0.90);
    draw_set_color(c_white);
    draw_rectangle(
        notification_x,
        notification_y,
        notification_x + box_w,
        notification_y + box_h,
        false
    );

    // Border
    draw_set_alpha(1);
    draw_set_color(c_dkgray);
    draw_rectangle(
        notification_x,
        notification_y,
        notification_x + box_w,
        notification_y + box_h,
        true
    );

    // Message
    draw_set_color(c_black);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    draw_text_ext(
        notification_x + box_padding,
        notification_y + box_padding,
        event_message,
        -1,
        text_w
    );

    notification_y += box_h + 12;
}


// ============================================================
// RESOURCE FEEDBACK NOTIFICATION
// ============================================================

if (feedback_timer > 0) {

    var feedback_count = array_length(event_feedback);

    var feedback_padding = 14;
    var feedback_row_h = 30;

    var feedback_w = notification_w;
    var feedback_h = feedback_padding * 2 + 28
        + max(1, feedback_count) * feedback_row_h;

    // Main background
    draw_set_alpha(0.90);
    draw_set_color(c_black);

    draw_rectangle(
        notification_x,
        notification_y,
        notification_x + feedback_w,
        notification_y + feedback_h,
        false
    );

    // Border
    draw_set_alpha(1);
    draw_set_color(c_white);

    draw_rectangle(
        notification_x,
        notification_y,
        notification_x + feedback_w,
        notification_y + feedback_h,
        true
    );

    // Header
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);

    draw_set_color(c_white);

    draw_text(
        notification_x + feedback_padding,
        notification_y + feedback_padding + 5,
        lang("MENU_RESOURCE_CHANGES")
    );

    // Separator
    draw_set_color(c_gray);

    draw_line(
        notification_x + feedback_padding,
        notification_y + feedback_padding + 18,
        notification_x + feedback_w - feedback_padding,
        notification_y + feedback_padding + 18
    );

    // Resource changes
    if (feedback_count == 0) {

        draw_set_color(c_gray);

        draw_text(
            notification_x + feedback_padding,
            notification_y + feedback_padding + 43,
            lang("MENU_NO_RESOURCES_CHANGED")
        );

    } else {

        for (var i = 0; i < feedback_count; i++) {

            var change = event_feedback[i];

            var resource_name = string_upper(lang("RESOURCE_" + string_upper(change.resource)));

            var amount = change.amount;

            var amount_text = string(amount);
            var row_y = notification_y + feedback_padding + 35
                + (i * feedback_row_h);

            // Gain or loss
            if (amount > 0) {
                draw_set_color(c_lime);
                amount_text = "+" + amount_text;
            } else if (amount < 0) {
                draw_set_color(c_red);
            } else {
                draw_set_color(c_gray);
            }

            // Resource name
            draw_set_halign(fa_left);

            draw_text(
                notification_x + feedback_padding,
                row_y,
                resource_name
            );

            // Amount aligned to the right
            draw_set_halign(fa_right);

            draw_text(
                notification_x + feedback_w - feedback_padding,
                row_y,
                amount_text
            );
        }
    }

    // Move back to default alignment
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    notification_y += feedback_h + 12;
}


// Restore drawing settings
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// ============================================================
// DEBUG MENU (hidden: toggle with the ~ key)
// ============================================================
if (debug_menu_open && !game_over && !game_won) {
    var debug_gui_w = display_get_gui_width();
    var debug_button_left = debug_gui_w - 255;
    var debug_button_top = 54;
    var debug_button_width = 255;
    var debug_button_height = 38;
    var debug_button_gap = 8;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_yellow);
    draw_text(debug_button_left + debug_button_width / 2, 28, "DEBUG: TRIGGER GAME OVER");

    for (var i = 0; i < array_length(debug_game_over_buttons); i++) {
        var button_top = debug_button_top + i * (debug_button_height + debug_button_gap);
        draw_set_color(c_dkgray);
        draw_rectangle(
            debug_button_left,
            button_top,
            debug_button_left + debug_button_width,
            button_top + debug_button_height,
            false
        );
        draw_set_color(c_white);
        draw_text(
            debug_button_left + debug_button_width / 2,
            button_top + debug_button_height / 2,
           lang(debug_game_over_buttons[i].label)
        );
    }

    var debug_win_button_top = debug_button_top
        + array_length(debug_game_over_buttons) * (debug_button_height + debug_button_gap)
        + 32;
    draw_set_color(c_lime);
    draw_text(
        debug_button_left + debug_button_width / 2,
        debug_win_button_top - 16,
        "DEBUG: TRIGGER WIN"
    );

    for (var i = 0; i < array_length(debug_win_condition_button); i++) {
        var win_button_top = debug_win_button_top + i * (debug_button_height + debug_button_gap);
        draw_set_color(c_dkgray);
        draw_rectangle(
            debug_button_left,
            win_button_top,
            debug_button_left + debug_button_width,
            win_button_top + debug_button_height,
            false
        );
        draw_set_color(c_white);
        draw_text(
            debug_button_left + debug_button_width / 2,
            win_button_top + debug_button_height / 2,
            lang(debug_win_condition_button[i].label)
        );
    }

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

if (game_over) {

    var game_over_gui_w = display_get_gui_width();
    var game_over_gui_h = display_get_gui_height();

    // Background image
    draw_set_alpha(1);
    draw_set_color(c_white);

    draw_sprite_stretched(
        sprt_game_overr,
        0,
        0,
        0,
        game_over_gui_w,
        game_over_gui_h
    );

    // Dark full-screen overlay
    draw_set_alpha(0.65);
    draw_set_color(c_black);

    draw_rectangle(
        0, 0,
        game_over_gui_w,
        game_over_gui_h,
        false
    );

    // Main text panel
    var panel_w = min(650, game_over_gui_w - 40);
    var panel_h = 350;

    var panel_x = (game_over_gui_w - panel_w) / 2;
    var panel_y = (game_over_gui_h - panel_h) / 2 - 10;

    draw_set_alpha(0.90);
    draw_set_color(c_black);

    draw_rectangle(
        panel_x,
        panel_y,
        panel_x + panel_w,
        panel_y + panel_h,
        false
    );

    draw_set_alpha(1);
    draw_set_color(c_white);

    draw_rectangle(
        panel_x,
        panel_y,
        panel_x + panel_w,
        panel_y + panel_h,
        true
    );

    // Text
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_color(c_red);

    draw_text(
        game_over_gui_w / 2,
        panel_y + 55,
        lang("MENU_JOURNEY_ENDED")
    );

    draw_set_color(c_white);

    draw_text_ext(
        game_over_gui_w / 2,
        panel_y + 125,
        game_over_reason,
        -1,
        panel_w - 80
    );

    draw_set_color(c_gray);

    draw_text(
        game_over_gui_w / 2,
        panel_y + 210,
        lang("MENU_EXPEDITION_FAILED")
    );

    // Replay button
    var replay_button_left = game_over_gui_w / 2 - 150;
    var replay_button_top = panel_y + 255;

    draw_set_color(c_white);

    draw_rectangle(
        replay_button_left,
        replay_button_top,
        replay_button_left + 300,
        replay_button_top + 55,
        false
    );

    draw_set_color(c_black);

    draw_text(
        game_over_gui_w / 2,
        replay_button_top + 27,
        lang("MENU_REPLAY")
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_set_alpha(1);
}

if (game_won) {

    var win_gui_w = display_get_gui_width();
    var win_gui_h = display_get_gui_height();

    // Background image
    draw_set_alpha(1);
    draw_set_color(c_white);

    draw_sprite_stretched(
        sprt_win_game,
        0,
        0,
        0,
        win_gui_w,
        win_gui_h
    );

    // Dark overlay
    draw_set_alpha(0.55);
    draw_set_color(c_black);

    draw_rectangle(
        0, 0,
        win_gui_w,
        win_gui_h,
        false
    );

    // Main panel
    var panel_w = min(650, win_gui_w - 40);
    var panel_h = 350;

    var panel_x = (win_gui_w - panel_w) / 2;
    var panel_y = (win_gui_h - panel_h) / 2 - 10;

    draw_set_alpha(0.90);
    draw_set_color(c_black);

    draw_rectangle(
        panel_x,
        panel_y,
        panel_x + panel_w,
        panel_y + panel_h,
        false
    );

    draw_set_alpha(1);
    draw_set_color(c_white);

    draw_rectangle(
        panel_x,
        panel_y,
        panel_x + panel_w,
        panel_y + panel_h,
        true
    );

    // Text
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

    draw_set_color(c_lime);

    draw_text(
        win_gui_w / 2,
        panel_y + 55,
        lang("MENU_JOURNEY_COMPLETED")
    );

    draw_set_color(c_white);

    draw_text_ext(
        win_gui_w / 2,
        panel_y + 125,
        win_ending,
        -1,
        panel_w - 80
    );

    draw_set_color(c_gray);

    draw_text(
        win_gui_w / 2,
        panel_y + 210,
        lang("MENU_EXPEDITION_SUCCESSFUL")
    );

    // Replay button
    var replay_button_left = win_gui_w / 2 - 150;
    var replay_button_top = panel_y + 255;

    draw_set_color(c_white);

    draw_rectangle(
        replay_button_left,
        replay_button_top,
        replay_button_left + 300,
        replay_button_top + 55,
        false
    );

    draw_set_color(c_black);

    draw_text(
        win_gui_w / 2,
        replay_button_top + 27,
        lang("MENU_REPLAY")
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_set_alpha(1);
}