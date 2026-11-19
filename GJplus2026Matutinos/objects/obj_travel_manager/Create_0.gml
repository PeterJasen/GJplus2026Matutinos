// Random seed
randomize();

// Language initialization
language_init();
language_import("txt_strings_pt_br.json");
global.current_lingo = "pt_br";

crew_health_max  = 100;
train_health_max = 100;

heal_amount = 10;

coal_per_event  = 1;
ration_interval = 3;
ration_food = 3;
ration_water = 4;
events_since_ration = 0;

// Major-event selection chance
major_event_chance = 45;

// Ration warning
ration_warning = false;
ration_warning_text = "";

// Intro cutscene
intro_duration = 20;
intro_timer = 0;
global.train_intro = 1;

// Debug menu
debug_menu_open = false;
debug_toggle_keys = [vk_backspace];

// End sounds
audio_end_sound_played = false;
end_sound_played = false;

// Journey meter
journey_length = 150;
journey_time = 0;

// Finale cutscene
finale_duration = 8;
finale_timer = 0;
finale_from_x = 0;
finale_end_x = room_width + 600;
finale_ending = "ENDING_NORMAL_WIN";

// Game over / win state
game_over = false;
game_over_reason = "";
game_won = false;
win_ending = "";

debug_game_over_buttons = [
    {label: "LABEL_CREW_ZERO", reason: "REASON_CREW_ZERO"},
    {label: "LABEL_TRAIN_ZERO", reason: "REASON_TRAIN_ZERO"},
    {label: "LABEL_NO_TOOLS", reason: "REASON_NO_TOOLS"},
    {label: "LABEL_NO_FOOD", reason: "REASON_NO_FOOD"},
    {label: "LABEL_NO_WATER", reason: "REASON_NO_WATER"},
    {label: "LABEL_NO_FUEL", reason: "REASON_NO_FUEL"}
];

debug_win_condition_button = [
    {label: "LABEL_NORMAL_WIN", ending: "ENDING_NORMAL_WIN"},
    {label: "LABEL_INDIGENOUS_WIN", ending: "ENDING_INDIGENOUS_WIN"},
    {label: "LABEL_BOTANIST_WIN", ending: "ENDING_BOTANIST_WIN"},
    {label: "LABEL_DOCTOR_WIN", ending: "ENDING_DOCTOR_WIN"}
];

// Consecutive events with zero fuel
coal_zero_events = 0;

// Death animation
death_timer = 0;
death_duration = 6;
death_start_x = 0;


// ============================================================
// STARTING STATE
// ============================================================

make_starting_resources = function() {
    return {
        food: 18,
        water: 20,
        fuel: 16,
        medicine: 4,
        tools: 6,
        crew_health: crew_health_max,
        train_health: train_health_max
    };
};

make_starting_flags = function() {
    return {
        found_provision_crate: false,
        found_leaking_cask: false,
        marked_old_trail: false,
        found_supply_camp: false,
        repaired_engine: false,
        seen_broken_engine: false,
        seen_embankment: false,
        seen_fever: false,
        seen_riverbank: false,
        seen_madeira: false,
        seen_roaring: false,
        seen_old_camp: false,
        found_woodpile: false,
        salvaged_wreck: false,
        found_trackside_cache: false,
        seen_boiler_pressure: false,
        seen_track_washout: false,
        seen_river_bend: false,
        seen_derelict_loco: false
    };
};

resources = make_starting_resources();
world_flags = make_starting_flags();

// Journey progress
journey_leg = 0;

// Travel configuration
travel_state = "menu";
travel_elapsed = 0;
next_event_time = 0;
last_event_id = "";

// Event message and feedback
event_message = "";
message_timer = 0;
event_feedback = [];
feedback_timer = 0;
current_event = undefined;


// ============================================================
// EVENT REQUIREMENTS
// ============================================================

event_is_available = function(_event) {

    if (journey_leg < _event.min_progress) {
        return false;
    }

    // Minimum resources
    var names = variable_struct_get_names(_event.min_resources);

    for (var i = 0; i < array_length(names); i++) {
        var key = names[i];

        if (!variable_struct_exists(resources, key)) {
            show_debug_message("Unknown resource in min_resources: " + key);
            return false;
        }

        if (variable_struct_get(resources, key)
            < variable_struct_get(_event.min_resources, key)) {
            return false;
        }
    }

    // Maximum resources
    names = variable_struct_get_names(_event.max_resources);

    for (var j = 0; j < array_length(names); j++) {
        var max_key = names[j];

        if (!variable_struct_exists(resources, max_key)) {
            show_debug_message("Unknown resource in max_resources: " + max_key);
            return false;
        }

        if (variable_struct_get(resources, max_key)
            > variable_struct_get(_event.max_resources, max_key)) {
            return false;
        }
    }

    // Required flags
    for (var k = 0; k < array_length(_event.required_flags); k++) {
        var required_flag = _event.required_flags[k];

        if (!variable_struct_exists(world_flags, required_flag)) {
            return false;
        }

        if (!variable_struct_get(world_flags, required_flag)) {
            return false;
        }
    }

    // Forbidden flags
    for (var m = 0; m < array_length(_event.forbidden_flags); m++) {
        var forbidden_flag = _event.forbidden_flags[m];

        if (variable_struct_exists(world_flags, forbidden_flag)
            && variable_struct_get(world_flags, forbidden_flag)) {
            return false;
        }
    }

    return true;
};


// ============================================================
// SOUND HELPERS
// ============================================================

play_game_sound = function(_sound, _loop, _volume) {

    var sound_instance = audio_play_sound(_sound, 1, _loop);

    audio_sound_gain(sound_instance, _volume, 0);

    return sound_instance;
};


// ============================================================
// MINOR EVENTS
// ============================================================

minor_events = [

    {
        id: "rain",
        type: "minor",
        title: lang("MINOR_RAIN_TEXT"),
        description: lang("MINOR_RAIN_DESCRIPTION"),
        weight: 8,
        min_progress: 0,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: [],
        effects: [
            {resource: "food", amount: -1},
            {resource: "tools", amount: -1}
        ],
        set_flag: "",
        sound: "sfx_negative"
    },

    {
        id: "mosquito",
        type: "minor",
        title: lang("MINOR_MOSQUITO_TEXT"),
        description: lang("MINOR_MOSQUITO_DESCRIPTION"),
        weight: 7,
        min_progress: 1,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: [],
        effects: [
            {resource: "crew_health", amount: -10}
        ],
        set_flag: "",
        sound: "sfx_negative"
    },

    {
        id: "tree",
        type: "minor",
        title: lang("MINOR_TREE_TEXT"),
        description: lang("MINOR_TREE_DESCRIPTION"),
        weight: 6,
        min_progress: 0,
        min_resources: {tools: 2},
        max_resources: {},
        required_flags: [],
        forbidden_flags: [],
        effects: [
            {resource: "tools", amount: -1},
            {resource: "fuel", amount: -1},
            {resource: "train_health", amount: -10}
        ],
        set_flag: "",
        sound: "sfx_negative"
    },

    {
        id: "find_supplies",
        type: "minor",
        title: lang("MINOR_FIND_SUPPLIES_TEXT"),
        description: lang("MINOR_FIND_SUPPLIES_DESCRIPTION"),
        weight: 5,
        min_progress: 2,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["found_supply_camp"],
        effects: [
            {resource: "food", amount: 3},
            {resource: "medicine", amount: 1}
        ],
        set_flag: "found_supply_camp",
        sound: "sfx_positive"
    },

    {
        id: "murky_water",
        type: "minor",
        title: lang("MINOR_MURKY_WATER_TEXT"),
        description: lang("MINOR_MURKY_WATER_DESCRIPTION"),
        weight: 8,
        min_progress: 1,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: [],
        effects: [
            {resource: "water", amount: -2}
        ],
        set_flag: "",
        sound: "sfx_negative"
    },

    {
        id: "vegetation",
        type: "minor",
        title: lang("MINOR_VEGETATION_TEXT"),
        description: lang("MINOR_VEGETATION_DESCRIPTION"),
        weight: 6,
        min_progress: 3,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: [],
        effects: [
            {resource: "fuel", min_amount: 4, max_amount: 10}
        ],
        set_flag: "",
        sound: "sfx_positive"
    },

    {
        id: "rain_catch",
        type: "minor",
        title: lang("MINOR_RAIN_CATCH_TEXT"),
        description: lang("MINOR_RAIN_CATCH_DESCRIPTION"),
        weight: 5,
        min_progress: 1,
        min_resources: {},
        max_resources: {water: 12},
        required_flags: [],
        forbidden_flags: [],
        effects: [
            {resource: "water", amount: 4}
        ],
        set_flag: "",
        sound: "sfx_positive"
    },

    {
        id: "woodpile",
        type: "minor",
        title: lang("MINOR_WOODPILE_TEXT"),
        description: lang("MINOR_WOODPILE_DESCRIPTION"),
        weight: 4,
        min_progress: 2,
        min_resources: {},
        max_resources: {fuel: 7},
        required_flags: [],
        forbidden_flags: ["found_woodpile"],
        effects: [
            {resource: "fuel", amount: 7}
        ],
        set_flag: "found_woodpile",
        sound: "sfx_positive"
    },

    {
        id: "loose_cargo",
        type: "minor",
        title: lang("MINOR_LOOSE_CARGO_TEXT"),
        description: lang("MINOR_LOOSE_CARGO_DESCRIPTION"),
        weight: 6,
        min_progress: 1,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: [],
        effects: [
            {resource: "food", amount: -2},
            {resource: "tools", amount: -1}
        ],
        set_flag: "",
        sound: "sfx_negative"
    },

    {
        id: "trackside_cache",
        type: "minor",
        title: lang("MINOR_TRACKSIDE_CACHE_TEXT"),
        description: lang("MINOR_TRACKSIDE_CACHE_DESCRIPTION"),
        weight: 4,
        min_progress: 3,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["found_trackside_cache"],
        effects: [
            {resource: "tools", amount: 1},
            {resource: "medicine", amount: 1}
        ],
        set_flag: "found_trackside_cache",
        sound: "sfx_positive"
    },

    {
        id: "food_shortage",
        type: "minor",
        title: lang("MINOR_FOOD_SHORTAGE_TEXT"),
        description: lang("MINOR_FOOD_SHORTAGE_DESCRIPTION"),
        weight: 2,
        min_progress: 3,
        min_resources: {},
        max_resources: {food: 6},
        required_flags: [],
        forbidden_flags: [],
        effects: [],
        set_flag: "",
        sound: "sfx_negative"
    },

    {
        id: "water_shortage",
        type: "minor",
        title: lang("MINOR_WATER_SHORTAGE_TEXT"),
        description: lang("MINOR_WATER_SHORTAGE_DESCRIPTION"),
        weight: 2,
        min_progress: 3,
        min_resources: {},
        max_resources: {water: 8},
        required_flags: [],
        forbidden_flags: [],
        effects: [],
        set_flag: "",
        sound: "sfx_negative"
    },

    {
        id: "provision_crate",
        type: "minor",
        title: lang("MINOR_PROVISION_CRATE_TEXT"),
        description: lang("MINOR_PROVISION_CRATE_DESCRIPTION"),
        weight: 5,
        min_progress: 2,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["found_provision_crate"],
        effects: [
            {resource: "food", amount: 3},
            {resource: "tools", amount: 1}
        ],
        set_flag: "found_provision_crate",
        sound: "sfx_positive"
    },

    {
        id: "leaking_cask",
        type: "minor",
        title: lang("MINOR_LEAKING_CASK_TEXT"),
        description: lang("MINOR_LEAKING_CASK_DESCRIPTION"),
        weight: 6,
        min_progress: 2,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["found_leaking_cask"],
        effects: [
            {resource: "water", amount: -3}
        ],
        set_flag: "found_leaking_cask",
        sound: "sfx_negative"
    }
];


// ============================================================
// MAJOR EVENTS
// ============================================================

major_events = [

    {
        id: "broken_engine",
        title: lang("MAJOR_BROKEN_ENGINE_TEXT"),
        type: "major",
        description: lang("MAJOR_BROKEN_ENGINE_DESCRIPTION"),
        requires_repair: true,
        weight: 5,
        min_progress: 3,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_broken_engine"],
        sound: "sfx_negative",
        choices: [
            {
                text: lang("MAJOR_BROKEN_ENGINE_CHOICE_1_TEXT"),
                min_resources: {tools: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_BROKEN_ENGINE_CHOICE_1_OUTCOME_1"),
                        effects: [
                            {resource: "tools", amount: -2}
                        ],
                        set_flag: ["repaired_engine", "seen_broken_engine"],
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: lang("MAJOR_BROKEN_ENGINE_CHOICE_2_TEXT"),
                min_resources: {tools: 1},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 60,
                        description: lang("MAJOR_BROKEN_ENGINE_CHOICE_2_OUTCOME_1"),
                        effects: [
                            {resource: "tools", amount: -1},
                            {resource: "train_health", amount: -5}
                        ],
                        set_flag: "seen_broken_engine",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 40,
                        description: lang("MAJOR_BROKEN_ENGINE_CHOICE_2_OUTCOME_2"),
                        effects: [
                            {resource: "tools", amount: -1},
                            {resource: "train_health", amount: -15}
                        ],
                        set_flag: "seen_broken_engine",
                        sound: "sfx_negative"
                    }
                ]
            }
        ]
    },

    {
        id: "embankment",
        type: "major",
        title: lang("MAJOR_EMBANKMENT_TEXT"),
        description: lang("MAJOR_EMBANKMENT_DESCRIPTION"),
        weight: 8,
        min_progress: 2,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_embankment"],
        sound: "sfx_negative",
        choices: [
            {
                text: lang("MAJOR_EMBANKMENT_CHOICE_1_TEXT"),
                min_resources: {tools: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 75,
                        description: lang("MAJOR_EMBANKMENT_CHOICE_1_OUTCOME_1"),
                        effects: [
                            {resource: "tools", amount: -2}
                        ],
                        set_flag: "seen_embankment",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 25,
                        description: lang("MAJOR_EMBANKMENT_CHOICE_1_OUTCOME_2"),
                        effects: [
                            {resource: "tools", amount: -2},
                            {resource: "crew_health", amount: -5}
                        ],
                        set_flag: "seen_embankment",
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: lang("MAJOR_EMBANKMENT_CHOICE_2_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 65,
                        description: lang("MAJOR_EMBANKMENT_CHOICE_2_OUTCOME_1"),
                        effects: [
                            {resource: "fuel", amount: -2}
                        ],
                        set_flag: "seen_embankment",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 35,
                        description: lang("MAJOR_EMBANKMENT_CHOICE_2_OUTCOME_2"),
                        effects: [
                            {resource: "tools", amount: -2},
                            {resource: "train_health", amount: -20}
                        ],
                        set_flag: "seen_embankment",
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: lang("MAJOR_EMBANKMENT_CHOICE_3_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_EMBANKMENT_CHOICE_3_OUTCOME_1"),
                        effects: [
                            {resource: "food", amount: -5}
                        ],
                        set_flag: "seen_embankment",
                        sound: "sfx_positive"
                    }
                ]
            }
        ]
    },

    {
        id: "fever",
        type: "major",
        title: lang("MAJOR_FEVER_TEXT"),
        description: lang("MAJOR_FEVER_DESCRIPTION"),
        weight: 7,
        min_progress: 1,
        min_resources: {},
        max_resources: {crew_health: 90},
        required_flags: [],
        forbidden_flags: ["seen_fever"],
        sound: "sfx_negative",
        choices: [
            {
                text: lang("MAJOR_FEVER_CHOICE_1_TEXT"),
                min_resources: {medicine: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_FEVER_CHOICE_1_OUTCOME_1"),
                        effects: [
                            {resource: "medicine", amount: -2},
                            {resource: "crew_health", amount: 10}
                        ],
                        set_flag: "seen_fever",
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: lang("MAJOR_FEVER_CHOICE_2_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_FEVER_CHOICE_2_OUTCOME_1"),
                        effects: [
                            {resource: "crew_health", amount: -20}
                        ],
                        set_flag: "seen_fever",
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: lang("MAJOR_FEVER_CHOICE_3_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_FEVER_CHOICE_3_OUTCOME_1"),
                        effects: [
                            {resource: "food", amount: -3},
                            {resource: "crew_health", amount: 5}
                        ],
                        set_flag: "seen_fever",
                        sound: "sfx_positive"
                    }
                ]
            }
        ]
    },

    {
        id: "riverbank",
        type: "major",
        title: lang("MAJOR_RIVERBANK_TEXT"),
        description: lang("MAJOR_RIVERBANK_DESCRIPTION"),
        weight: 7,
        min_progress: 3,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_riverbank"],
        sound: "sfx_positive",
        choices: [
            {
                text: lang("MAJOR_RIVERBANK_CHOICE_1_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_RIVERBANK_CHOICE_1_OUTCOME_1"),
                        effects: [],
                        set_flag: ["marked_old_trail", "seen_riverbank"],
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: lang("MAJOR_RIVERBANK_CHOICE_2_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_RIVERBANK_CHOICE_2_OUTCOME_1"),
                        effects: [],
                        set_flag: "seen_riverbank",
                        sound: "sfx_positive"
                    }
                ]
            }
        ]
    },

    {
        id: "roaring",
        type: "major",
        title: lang("MAJOR_ROARING_TEXT"),
        description: lang("MAJOR_ROARING_DESCRIPTION"),
        weight: 7,
        min_progress: 4,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_roaring"],
        sound: "sfx_negative",
        choices: [
            {
                text: lang("MAJOR_ROARING_CHOICE_1_TEXT"),
                min_resources: {tools: 1},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_ROARING_CHOICE_1_OUTCOME_1"),
                        effects: [
                            {resource: "tools", amount: -2}
                        ],
                        set_flag: ["seen_madeira", "seen_roaring"],
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: lang("MAJOR_ROARING_CHOICE_2_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 60,
                        description: lang("MAJOR_ROARING_CHOICE_2_OUTCOME_1"),
                        effects: [],
                        set_flag: ["seen_madeira", "seen_roaring"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 40,
                        description: lang("MAJOR_ROARING_CHOICE_2_OUTCOME_2"),
                        effects: [
                            {resource: "food", amount: -3},
                            {resource: "water", amount: -2},
                            {resource: "tools", amount: -1}
                        ],
                        set_flag: ["seen_madeira", "seen_roaring"],
                        sound: "sfx_negative"
                    }
                ]
            }
        ]
    },

    {
        id: "old_camp",
        type: "major",
        title: lang("MAJOR_OLD_CAMP_TEXT"),
        description: lang("MAJOR_OLD_CAMP_DESCRIPTION"),
        weight: 6,
        min_progress: 5,
        min_resources: {},
        max_resources: {},
        required_flags: ["marked_old_trail"],
        forbidden_flags: ["found_supply_camp", "seen_old_camp"],
        sound: "sfx_positive",
        choices: [
            {
                text: lang("MAJOR_OLD_CAMP_CHOICE_1_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 65,
                        description: lang("MAJOR_OLD_CAMP_CHOICE_1_OUTCOME_1"),
                        effects: [
                            {resource: "food", amount: 3},
                            {resource: "tools", amount: 2}
                        ],
                        set_flag: ["found_supply_camp", "seen_old_camp"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 25,
                        description: lang("MAJOR_OLD_CAMP_CHOICE_1_OUTCOME_2"),
                        effects: [],
                        set_flag: "seen_old_camp",
                        sound: "sfx_negative"
                    },
                    {
                        weight: 10,
                        description: lang("MAJOR_OLD_CAMP_CHOICE_1_OUTCOME_3"),
                        effects: [
                            {resource: "crew_health", amount: -5}
                        ],
                        set_flag: "seen_old_camp",
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: lang("MAJOR_OLD_CAMP_CHOICE_2_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_OLD_CAMP_CHOICE_2_OUTCOME_1"),
                        effects: [],
                        set_flag: "seen_old_camp",
                        sound: "sfx_positive"
                    }
                ]
            }
        ]
    },

    {
        id: "river_bend",
        type: "major",
        title: lang("MAJOR_RIVER_BEND_TEXT"),
        description: lang("MAJOR_RIVER_BEND_DESCRIPTION"),
        weight: 7,
        min_progress: 3,
        min_resources: {},
        max_resources: {water: 10},
        required_flags: [],
        forbidden_flags: ["seen_river_bend"],
        sound: "sfx_positive",
        choices: [
            {
                text: lang("MAJOR_RIVER_BEND_CHOICE_1_TEXT"),
                min_resources: {fuel: 1},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_RIVER_BEND_CHOICE_1_OUTCOME_1"),
                        effects: [
                            {resource: "fuel", amount: -1},
                            {resource: "water", amount: 6}
                        ],
                        set_flag: ["seen_madeira", "seen_river_bend"],
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: lang("MAJOR_RIVER_BEND_CHOICE_2_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 70,
                        description: lang("MAJOR_RIVER_BEND_CHOICE_2_OUTCOME_1"),
                        effects: [
                            {resource: "water", amount: 6}
                        ],
                        set_flag: ["seen_madeira", "seen_river_bend"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 30,
                        description: lang("MAJOR_RIVER_BEND_CHOICE_2_OUTCOME_2"),
                        effects: [
                            {resource: "water", amount: 2},
                            {resource: "crew_health", amount: -15}
                        ],
                        set_flag: ["seen_madeira", "seen_river_bend"],
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: lang("MAJOR_RIVER_BEND_CHOICE_3_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_RIVER_BEND_CHOICE_3_OUTCOME_1"),
                        effects: [],
                        set_flag: ["seen_madeira", "seen_river_bend"],
                        sound: "sfx_positive"
                    }
                ]
            }
        ]
    },

    {
        id: "derelict_loco",
        type: "major",
        title: lang("MAJOR_DERELICT_LOCO_TEXT"),
        description: lang("MAJOR_DERELICT_LOCO_DESCRIPTION"),
        weight: 6,
        min_progress: 4,
        min_resources: {},
        max_resources: {fuel: 6},
        required_flags: [],
        forbidden_flags: ["seen_derelict_loco"],
        sound: "sfx_positive",
        choices: [
            {
                text: lang("MAJOR_DERELICT_LOCO_CHOICE_1_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 60,
                        description: lang("MAJOR_DERELICT_LOCO_CHOICE_1_OUTCOME_1"),
                        effects: [
                            {resource: "fuel", amount: 8}
                        ],
                        set_flag: ["salvaged_wreck", "seen_derelict_loco"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 25,
                        description: lang("MAJOR_DERELICT_LOCO_CHOICE_1_OUTCOME_2"),
                        effects: [
                            {resource: "fuel", amount: 3}
                        ],
                        set_flag: ["salvaged_wreck", "seen_derelict_loco"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 15,
                        description: lang("MAJOR_DERELICT_LOCO_CHOICE_1_OUTCOME_3"),
                        effects: [
                            {resource: "fuel", amount: 2},
                            {resource: "crew_health", amount: -5}
                        ],
                        set_flag: ["salvaged_wreck", "seen_derelict_loco"],
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: lang("MAJOR_DERELICT_LOCO_CHOICE_2_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_DERELICT_LOCO_CHOICE_2_OUTCOME_1"),
                        effects: [],
                        set_flag: "seen_derelict_loco",
                        sound: "sfx_positive"
                    }
                ]
            }
        ]
    },

    {
        id: "boiler_pressure",
        type: "major",
        title: lang("MAJOR_BOILER_PRESSURE_TEXT"),
        description: lang("MAJOR_BOILER_PRESSURE_DESCRIPTION"),
        weight: 7,
        min_progress: 2,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_boiler_pressure"],
        sound: "sfx_negative",
        choices: [
            {
                text: lang("MAJOR_BOILER_PRESSURE_CHOICE_1_TEXT"),
                min_resources: {fuel: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_BOILER_PRESSURE_CHOICE_1_OUTCOME_1"),
                        effects: [
                            {resource: "fuel", amount: -2}
                        ],
                        set_flag: "seen_boiler_pressure",
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: lang("MAJOR_BOILER_PRESSURE_CHOICE_2_TEXT"),
                min_resources: {tools: 1},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 80,
                        description: lang("MAJOR_BOILER_PRESSURE_CHOICE_2_OUTCOME_1"),
                        effects: [
                            {resource: "tools", amount: -1}
                        ],
                        set_flag: "seen_boiler_pressure",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 20,
                        description: lang("MAJOR_BOILER_PRESSURE_CHOICE_2_OUTCOME_2"),
                        effects: [
                            {resource: "tools", amount: -1},
                            {resource: "train_health", amount: -20}
                        ],
                        set_flag: "seen_boiler_pressure",
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: lang("MAJOR_BOILER_PRESSURE_CHOICE_3_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 65,
                        description: lang("MAJOR_BOILER_PRESSURE_CHOICE_3_OUTCOME_1"),
                        effects: [
                            {resource: "fuel", amount: -1}
                        ],
                        set_flag: "seen_boiler_pressure",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 35,
                        description: lang("MAJOR_BOILER_PRESSURE_CHOICE_3_OUTCOME_2"),
                        effects: [
                            {resource: "fuel", amount: -1},
                            {resource: "train_health", amount: -15}
                        ],
                        set_flag: "seen_boiler_pressure",
                        sound: "sfx_negative"
                    }
                ]
            }
        ]
    },

    {
        id: "track_washout",
        type: "major",
        title: lang("MAJOR_TRACK_WASHOUT_TEXT"),
        description: lang("MAJOR_TRACK_WASHOUT_DESCRIPTION"),
        weight: 7,
        min_progress: 4,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_track_washout"],
        sound: "sfx_negative",
        choices: [
            {
                text: lang("MAJOR_TRACK_WASHOUT_CHOICE_1_TEXT"),
                min_resources: {tools: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 80,
                        description: lang("MAJOR_TRACK_WASHOUT_CHOICE_1_OUTCOME_1"),
                        effects: [
                            {resource: "tools", amount: -2}
                        ],
                        set_flag: "seen_track_washout",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 20,
                        description: lang("MAJOR_TRACK_WASHOUT_CHOICE_1_OUTCOME_2"),
                        effects: [
                            {resource: "tools", amount: -2},
                            {resource: "train_health", amount: -15}
                        ],
                        set_flag: "seen_track_washout",
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: lang("MAJOR_TRACK_WASHOUT_CHOICE_2_TEXT"),
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: lang("MAJOR_TRACK_WASHOUT_CHOICE_2_OUTCOME_1"),
                        effects: [
                            {resource: "food", amount: -2},
                            {resource: "water", amount: -1}
                        ],
                        set_flag: "seen_track_washout",
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: lang("MAJOR_TRACK_WASHOUT_CHOICE_3_TEXT"),
                min_resources: {fuel: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 65,
                        description: lang("MAJOR_TRACK_WASHOUT_CHOICE_3_OUTCOME_1"),
                        effects: [
                            {resource: "fuel", amount: -2}
                        ],
                        set_flag: "seen_track_washout",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 35,
                        description: lang("MAJOR_TRACK_WASHOUT_CHOICE_3_OUTCOME_2"),
                        effects: [
                            {resource: "fuel", amount: -2},
                            {resource: "train_health", amount: -20}
                        ],
                        set_flag: "seen_track_washout",
                        sound: "sfx_negative"
                    }
                ]
            }
        ]
    }
];


// ============================================================
// EVENT SOUND SYSTEM
// ============================================================

play_event_sound = function(_sound_name) {

    if (is_undefined(_sound_name) || _sound_name == "") {
        return;
    }

    var sound_asset = -1;

    switch (_sound_name) {

        case "sfx_positive":
            sound_asset = sfx_positive;
            break;

        case "sfx_negative":
            sound_asset = sfx_negative;
            break;

        default:
            show_debug_message("UNKNOWN EVENT SOUND: " + _sound_name);
            return;
    }

    if (!audio_system_is_available()) {
        show_debug_message("AUDIO SYSTEM NOT AVAILABLE");
        return;
    }

    if (!audio_sound_is_playable(sound_asset)) {
        show_debug_message("SOUND NOT PLAYABLE: " + _sound_name);
        return;
    }

    var sound_id = audio_play_sound(sound_asset, 10, false, 2.5);

    if (sound_id == -1) {
        show_debug_message("FAILED TO PLAY: " + _sound_name);
    } else {
        show_debug_message("PLAYING: " + _sound_name);
    }
};


// ============================================================
// RESOURCE SYSTEM
// ============================================================

log_resource_change = function(_resource, _amount) {

    for (var i = 0; i < array_length(event_feedback); i++) {
        if (event_feedback[i].resource == _resource) {
            event_feedback[i].amount += _amount;

            if (event_feedback[i].amount == 0) {
                array_delete(event_feedback, i, 1);
            }
            return;
        }
    }

    array_push(event_feedback, {
        resource: _resource,
        amount: _amount
    });
};

begin_feedback = function() {
    event_feedback = [];
    feedback_timer = 8;
};

change_resource = function(_resource, _amount) {

    if (!variable_struct_exists(resources, _resource)) {
        show_debug_message("Unknown resource: " + string(_resource));
        return 0;
    }

    var current = variable_struct_get(resources, _resource);
    var updated = current + _amount;

    if (_resource == "crew_health") {
        updated = clamp(updated, 0, crew_health_max);
    } else if (_resource == "train_health") {
        updated = clamp(updated, 0, train_health_max);
    } else {
        updated = max(0, updated);
    }

    var actual_change = updated - current;
    variable_struct_set(resources, _resource, updated);

    if (actual_change != 0) {
        log_resource_change(_resource, actual_change);
    }

    return actual_change;
};

apply_effects = function(_effects) {

    for (var i = 0; i < array_length(_effects); i++) {
        var effect = _effects[i];
        var amount = 0;

        if (variable_struct_exists(effect, "amount")) {
            amount = effect.amount;
        } else if (
            variable_struct_exists(effect, "min_amount")
            && variable_struct_exists(effect, "max_amount")
        ) {
            amount = irandom_range(effect.min_amount, effect.max_amount);
        } else {
            show_debug_message("Invalid effect: missing amount for " + string(effect.resource));
            continue;
        }

        change_resource(effect.resource, amount);
    }
};

// Player actions
can_use_medicine = function() {
    return (travel_state == "travelling" || travel_state == "major_event")
        && resources.medicine >= 1
        && resources.crew_health < crew_health_max;
};

can_use_tools = function() {
    return (travel_state == "travelling" || travel_state == "major_event")
        && resources.tools >= 1
        && resources.train_health < train_health_max;
};

use_medicine = function() {
    if (!can_use_medicine()) return false;

    begin_feedback();
    change_resource("medicine", -1);
    change_resource("crew_health", heal_amount);
    return true;
};

use_tools = function() {
    if (!can_use_tools()) return false;

    begin_feedback();
    change_resource("tools", -1);
    change_resource("train_health", heal_amount);
    return true;
};

// HUD layout helpers
get_resource_chip = function(_index) {
    return {
        x: 16 + _index * 130,
        y: 16,
        w: 120,
        h: 30
    };
};

get_health_bar = function(_index) {
    return {
        x: 16,
        y: 64 + _index * 38,
        w: 300,
        h: 22
    };
};

get_action_button = function(_index) {
    var bar = get_health_bar(_index);
    return {
        x: bar.x + bar.w + 12,
        y: bar.y - 3,
        w: 230,
        h: bar.h + 6
    };
};


// ============================================================
// CUTSCENE HELPERS
// ============================================================

begin_finale = function() {

    travel_state = "finale";
    finale_timer = 0;
    current_event = undefined;

    if (instance_exists(obj_train_visual)) {
        var train_instance = instance_find(obj_train_visual, 0);
        finale_from_x = (train_instance != noone) ? train_instance.x : 0;
    } else {
        finale_from_x = 0;
    }

    audio_stop_all();
    audio_play_sound(sfx_trainstart, true, false, 0.7);
};


// ============================================================
// EVENT FLOW
// ============================================================

select_available_event = function(_events) {

    var available = [];
    var total_weight = 0;

    for (var i = 0; i < array_length(_events); i++) {
        var candidate = _events[i];

        if (!event_is_available(candidate)) continue;
        if (candidate.id == last_event_id) continue;

        array_push(available, candidate);
        total_weight += candidate.weight;
    }

    if (array_length(available) == 0) {
        for (var j = 0; j < array_length(_events); j++) {
            var fallback_event = _events[j];

            if (event_is_available(fallback_event)) {
                array_push(available, fallback_event);
                total_weight += fallback_event.weight;
            }
        }
    }

    if (array_length(available) == 0 || total_weight <= 0) {
        return undefined;
    }

    var roll = random(total_weight);

    for (var k = 0; k < array_length(available); k++) {
        roll -= available[k].weight;
        if (roll < 0) return available[k];
    }

    return available[array_length(available) - 1];
};

choose_weighted = function(_outcomes) {

    if (array_length(_outcomes) <= 0) {
        show_debug_message("ERROR: Event choice has no outcomes.");
        return undefined;
    }

    var total_weight = 0;

    for (var i = 0; i < array_length(_outcomes); i++) {
        var candidate = _outcomes[i];

        if (!variable_struct_exists(candidate, "weight")) {
            show_debug_message("ERROR: Outcome missing weight at index " + string(i));
            return undefined;
        }

        total_weight += candidate.weight;
    }

    if (total_weight <= 0) {
        show_debug_message("ERROR: Total outcome weight must be greater than zero.");
        return undefined;
    }

    var roll = random(total_weight);

    for (var j = 0; j < array_length(_outcomes); j++) {
        roll -= _outcomes[j].weight;
        if (roll < 0) return _outcomes[j];
    }

    return _outcomes[array_length(_outcomes) - 1];
};

set_world_flag = function(_flag) {

    if (is_undefined(_flag)) return;

    if (is_array(_flag)) {
        for (var i = 0; i < array_length(_flag); i++) {
            set_world_flag(_flag[i]);
        }
        return;
    }

    if (is_string(_flag) && _flag != "") {
        if (variable_struct_exists(world_flags, _flag)) {
            variable_struct_set(world_flags, _flag, true);
        } else {
            show_debug_message("Unknown world flag: " + _flag);
        }
    }
};


// ============================================================
// GAME OVER CHECKS
// ============================================================

check_event_requirements = function(_event) {

    if (variable_struct_exists(_event, "requires_repair") && _event.requires_repair) {
        if (resources.tools <= 0) {
            trigger_game_over("REASON_NO_TOOLS");
            return false;
        }
    }

    return true;
};

check_game_over = function() {

    if (game_over || travel_state == "death") return;

    if (resources.crew_health <= 0) {
        trigger_game_over("REASON_CREW_ZERO");
        return;
    }

    if (resources.train_health <= 0) {
        trigger_game_over("REASON_TRAIN_ZERO");
        return;
    }
};

check_coal_game_over = function() {

    if (game_over || travel_state == "death") return;

    if (resources.fuel <= 0) {
        coal_zero_events++;
    } else {
        coal_zero_events = 0;
    }

    if (coal_zero_events >= 2) {
        trigger_game_over("REASON_NO_FUEL");
    }
};


// ============================================================
// UPKEEP
// ============================================================

consume_upkeep = function() {

    change_resource("fuel", -coal_per_event);

    events_since_ration++;

    if (events_since_ration >= ration_interval) {
        events_since_ration = 0;

        var short_food = (resources.food < ration_food);
        var short_water = (resources.water < ration_water);

        change_resource("food", -ration_food);
        change_resource("water", -ration_water);

        if (short_food || short_water) {

            if (ration_warning) {

                if (short_food && short_water) {
                    trigger_game_over("REASON_NO_FOOD_AND_WATER");
                } else if (short_food) {
                    trigger_game_over("REASON_NO_FOOD");
                } else {
                    trigger_game_over("REASON_NO_WATER");
                }

            } else {
                ration_warning = true;

                if (short_food && short_water) {
                    ration_warning_text = "REASON_NO_FOOD_AND_WATER";
                } else if (short_food) {
                    ration_warning_text = "REASON_NO_FOOD";
                } else {
                    ration_warning_text = "REASON_NO_WATER";
                }
            }

        } else {
            ration_warning = false;
            ration_warning_text = "";
        }
    }
};

complete_event = function() {

    check_game_over();
    if (game_over || travel_state == "death") return;

    consume_upkeep();
    if (game_over || travel_state == "death") return;

    check_coal_game_over();
    if (game_over || travel_state == "death") return;

    current_event = undefined;
    journey_leg++;

    travel_state = "travelling";
    travel_elapsed = 0;
    next_event_time = random_range(8, 15);
};


// ============================================================
// EVENT GENERATOR
// ============================================================

trigger_event = function() {

    var wants_major = (irandom(99) < major_event_chance);
    var selected = undefined;

    if (wants_major) {
        selected = select_available_event(major_events);
        if (is_undefined(selected)) {
            selected = select_available_event(minor_events);
        }
    } else {
        selected = select_available_event(minor_events);
        if (is_undefined(selected)) {
            selected = select_available_event(major_events);
        }
    }

    if (is_undefined(selected)) {
        travel_elapsed = 0;
        next_event_time = random_range(8, 15);
        return;
    }

    last_event_id = selected.id;

    if (!check_event_requirements(selected)) {
        return;
    }

    if (variable_struct_exists(selected, "sound")) {
        play_event_sound(selected.sound);
    }

    if (selected.type == "major") {
        current_event = selected;
        travel_state = "major_event";
    } else {
        begin_feedback();

        if (variable_struct_exists(selected, "effects")) {
            apply_effects(selected.effects);
        }

        if (variable_struct_exists(selected, "set_flag")) {
            set_world_flag(selected.set_flag);
        }

        event_message = selected.title + ": " + selected.description;
        message_timer = 8;

        complete_event();
    }
};


// ============================================================
// CHOICE RESOLVER
// ============================================================

resolve_choice = function(_choice_index) {

    if (is_undefined(current_event)) return;
    if (!variable_struct_exists(current_event, "choices")) return;

    if (_choice_index < 0 || _choice_index >= array_length(current_event.choices)) {
        return;
    }

    var choice = current_event.choices[_choice_index];

    if (!event_is_available(choice)) {
        return;
    }

    var outcome = choose_weighted(choice.outcomes);
    if (is_undefined(outcome)) return;

    if (variable_struct_exists(outcome, "sound") && outcome.sound != "") {
        play_event_sound(outcome.sound);
    } else if (variable_struct_exists(choice, "sound")) {
        play_event_sound(choice.sound);
    }

    begin_feedback();
    apply_effects(outcome.effects);
    set_world_flag(outcome.set_flag);

    event_message = outcome.description;
    message_timer = 6;

    complete_event();
};


// ============================================================
// GAME STATE
// ============================================================

trigger_game_over = function(_reason) {

    if (game_over || game_won || travel_state == "death") {
        return;
    }

    game_over_reason = _reason;
    death_timer = 0;
    death_start_x = 0;

    if (instance_exists(obj_train_visual)) {
        var train_instance = instance_find(obj_train_visual, 0);
        if (train_instance != noone) {
            death_start_x = train_instance.x;
        }
    }

    travel_state = "death";
    current_event = undefined;
    end_sound_played = false;

    show_debug_message("DEATH ANIMATION STARTED: " + _reason);
};

trigger_win = function(_ending) {

    if (game_over || game_won) return;

    game_won = true;
    win_ending = _ending;
    travel_state = "win";
    current_event = undefined;

    show_debug_message("JOURNEY WON: " + win_ending);
};


// ============================================================
// LANGUAGE
// ============================================================

change_language = function() {

    if (global.current_lingo == "en") {
        language_import("txt_strings_pt_br.json");
        global.current_lingo = "pt_br";

    } else if (global.current_lingo == "pt_br") {
        language_import("txt_strings_en.json");
        global.current_lingo = "en";
    }
};


// ============================================================
// START GAME
// ============================================================

start_game = function() {

    game_over = false;
    game_over_reason = "";
    game_won = false;
    win_ending = "";

    coal_zero_events = 0;
    events_since_ration = 0;
    ration_warning = false;
    ration_warning_text = "";

    resources = make_starting_resources();
    world_flags = make_starting_flags();

    journey_leg = 0;

    travel_state = "intro";
    intro_timer = 0;
    global.train_intro = 0;

    end_sound_played = false;
    audio_end_sound_played = false;

    journey_time = 0;
    finale_timer = 0;
    death_timer = 0;

    travel_elapsed = 0;
    next_event_time = random_range(8, 15);
    last_event_id = "";

    event_message = "";
    message_timer = 0;
    event_feedback = [];
    feedback_timer = 0;
    current_event = undefined;
};