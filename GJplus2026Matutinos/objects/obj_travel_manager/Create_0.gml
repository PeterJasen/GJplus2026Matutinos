// Random seed
randomize();

crew_health_max  = 100;
train_health_max = 100;

heal_amount = 10;        // 1 medicine = +20 crew health, 1 tool = +20 train health

coal_per_event  = 1;     // fuel burned after every event
ration_interval = 3;     // the crew eats and drinks every 3 events
ration_food = 3;
ration_water = 4;
events_since_ration = 0;

// Major-event selection chance (35% of event rolls, when eligible)
major_event_chance = 45;

// After a failed ration check the crew gets ONE last chance:
ration_warning = false;
ration_warning_text = "";

// Intro cutscene
intro_duration = 20;
intro_timer = 0;
global.train_intro = 1;  // 0 = off-screen left, 1 = final position

// Debug menu
debug_menu_open = false;
debug_toggle_keys = [vk_backspace];

// End sounds must only start once
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
finale_ending = "Normal Ending";

// Game over / win state
game_over = false;
game_over_reason = "";
game_won = false;
win_ending = "";

debug_game_over_buttons = [
    {label: "CREW HEALTH ZERO", reason: "The crew's health has reached zero."},
    {label: "TRAIN HEALTH ZERO", reason: "The locomotive was wrecked beyond repair."},
    {label: "NO REPAIR TOOLS", reason: "A repair was needed, but no tools were available."},
    {label: "NO FOOD", reason: "The crew ran out of food."},
    {label: "NO WATER", reason: "The crew ran out of water."},
    {label: "OUT OF FUEL", reason: "The locomotive ran out of fuel for two consecutive events."}
];

debug_win_condition_button = [
    {label: "WIN GAME, NORMAL ENDING", ending: "Normal Ending"},
    {label: "WIN GAME, INDIGENOUS ENDING", ending: "Indigenous Ending"},
    {label: "WIN GAME, BOTANIST ENDING", ending: "Botanist Ending"},
    {label: "WIN GAME, DOCTOR ENDING", ending: "Doctor Ending"}
];

// Consecutive events with zero fuel
coal_zero_events = 0;

// Death animation
// Step Event should animate this state, then set game_over = true
// and travel_state = "game_over" when the animation finishes.
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

// Journey progress (number of completed events)
journey_leg = 0;

// Travel configuration
travel_state = "menu";
travel_elapsed = 0;
next_event_time = random_range(4, 8);
last_event_id = "";

// Event message and feedback
event_message = "";
message_timer = 0;
event_feedback = [];
feedback_timer = 0;
current_event = undefined;

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

// Plays a sound with a chosen volume.
// Returns the sound instance, so it can be controlled later.
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
        title: "The Afternoon Rain",
        description: "Rain soaks the supplies and damages equipment.",
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
        title: "Mosquitoes at Dusk",
        description: "A crew member develops a fever.",
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
        title: "A Fallen Giant",
        description: "A massive tree blocks the tracks.",
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
        title: "The Forgotten Supplies",
        description: "The crew discovers abandoned provisions.",
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
        title: "The Murky Water",
        description: "Some drinking water has become contaminated.",
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
        title: "An Unusual Sound",
        description: "Something moves through the vegetation... But the crew discovers usable fuel nearby.",
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
        title: "A Welcome Downpour",
        description: "The crew collects rainwater in every barrel they can find.",
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
        title: "The Abandoned Woodpile",
        description: "Firewood stacked beside the tracks by a previous crew.",
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
        title: "Unsecured Cargo",
        description: "A sudden jolt sends unsecured supplies crashing against the carriage walls.",
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
        title: "A Small Discovery",
        description: "The crew discovers a forgotten crate of useful equipment beside the railway.",
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
    // Shortage warnings are minor, automatic events, so they belong in this pool.
    {
        id: "food_shortage",
        type: "minor",
        title: "Empty Food Supplies",
        description: "The food stores are running dangerously low.",
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
        title: "Water Supplies Running Low",
        description: "The remaining drinking water will not last much longer.",
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
    title: "An Abandoned Provision Crate",
    description: "A sealed crate has been left beside the railway. Some of its contents are still usable.",
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
	    title: "A Leaking Water Cask",
	    description: "One of the water barrels has cracked. Several litres have already been lost.",
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
},
];

// ============================================================
// MAJOR EVENTS
// ============================================================

major_events = [
    {
        id: "broken_engine",
        title: "The Engine Breaks Down",
        type: "major",
        description: "The locomotive has suffered a mechanical failure. The crew needs spare tools to get it moving again.",
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
                text: "Repair the engine properly",
                min_resources: {tools: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The engine roars back to life.",
                        effects: [
                            {resource: "tools", amount: -2}
                        ],
                        set_flag: ["repaired_engine", "seen_broken_engine"],
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: "Improvise a rough patch",
                min_resources: {tools: 1},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 60,
                        description: "The patch holds, for now.",
                        effects: [
                            {resource: "tools", amount: -1},
                            {resource: "train_health", amount: -5}
                        ],
                        set_flag: "seen_broken_engine",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 40,
                        description: "The patch barely holds and the engine is badly strained.",
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
        title: "The Unstable Embankment",
        description: "The ground beneath the railway is collapsing.",
        weight: 8,
        min_progress: 2,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_embankment"],
        sound: "sfx_negative",
        choices: [
            {
                text: "Reinforce the embankment",
                min_resources: {tools: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 75,
                        description: "The repairs hold.",
                        effects: [
                            {resource: "tools", amount: -2}
                        ],
                        set_flag: "seen_embankment",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 25,
                        description: "The repairs fail. Someone gets hurt.",
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
                text: "Attempt to cross slowly",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 65,
                        description: "The train crosses safely.",
                        effects: [
                            {resource: "fuel", amount: -2}
                        ],
                        set_flag: "seen_embankment",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 35,
                        description: "The train suffers damage.",
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
                text: "Stop and wait",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The crew waits for safer conditions.",
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
        title: "Fever in the Passenger Car",
        description: "A passenger has developed a severe fever.",
        weight: 7,
        min_progress: 1,
        min_resources: {},
        max_resources: {crew_health: 90},
        required_flags: [],
        forbidden_flags: ["seen_fever"],
        sound: "sfx_negative",
        choices: [
            {
                text: "Use medical supplies",
                min_resources: {medicine: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The treatment helps the passenger.",
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
                text: "Continue travelling",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The passenger's condition worsens.",
                        effects: [
                            {resource: "crew_health", amount: -20}
                        ],
                        set_flag: "seen_fever",
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: "Rest for the day",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The passenger recovers somewhat.",
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
        title: "Signs Along the Riverbank",
        description: "A maintained trail leads into the forest. Someone lives nearby.",
        weight: 7,
        min_progress: 3,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_riverbank"],
        sound: "sfx_positive",
        choices: [
            {
                text: "Observe from a respectful distance",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The crew records the trail and leaves it undisturbed.",
                        effects: [],
                        set_flag: ["marked_old_trail", "seen_riverbank"],
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: "Continue without approaching",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The train continues along the railway.",
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
        title: "The Roaring Madeira",
        description: "The river's rapids shake the cargo as the train passes nearby.",
        weight: 7,
        min_progress: 4,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_roaring"],
        sound: "sfx_negative",
        choices: [
            {
                text: "Secure the cargo",
                min_resources: {tools: 1},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The cargo is secured.",
                        effects: [
                            {resource: "tools", amount: -2}
                        ],
                        set_flag: ["seen_madeira", "seen_roaring"],
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: "Continue immediately",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 60,
                        description: "Nothing is lost.",
                        effects: [],
                        set_flag: ["seen_madeira", "seen_roaring"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 40,
                        description: "Some supplies fall from the cargo.",
                        effects: [
                            {resource: "food", amount: -3},
                            {resource: "water", amount: -2},
							{resource: "tools", amount: -1},
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
        title: "The Old Work Camp",
        description: "The crew discovers the remains of an old construction camp.",
        weight: 6,
        min_progress: 5,
        min_resources: {},
        max_resources: {},
        required_flags: ["marked_old_trail"],
        forbidden_flags: ["found_supply_camp", "seen_old_camp"],
        sound: "sfx_positive",
        choices: [
            {
                text: "Search the camp",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 65,
                        description: "Useful equipment and food are recovered.",
                        effects: [
                            {resource: "food", amount: 3},
                            {resource: "tools", amount: 2}
                        ],
                        set_flag: ["found_supply_camp", "seen_old_camp"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 25,
                        description: "The camp has already been emptied.",
                        effects: [],
                        set_flag: "seen_old_camp",
                        sound: "sfx_negative"
                    },
                    {
                        weight: 10,
                        description: "An accident injures a crew member.",
                        effects: [
                            {resource: "crew_health", amount: -5}
                        ],
                        set_flag: "seen_old_camp",
                        sound: "sfx_negative"
                    }
                ]
            },
            {
                text: "Leave the camp",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The train continues its journey.",
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
        title: "A Quiet Bend in the Madeira",
        description: "The river runs calm here. The barrels could use a refill.",
        weight: 7,
        min_progress: 3,
        min_resources: {},
        max_resources: {water: 10},
        required_flags: [],
        forbidden_flags: ["seen_river_bend"],
        sound: "sfx_positive",
        choices: [
            {
                text: "Boil the water before storing it",
                min_resources: {fuel: 1},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The water is clean and the barrels are full.",
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
                text: "Fill the barrels straight from the river",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 70,
                        description: "The water looks clear enough. The barrels are full.",
                        effects: [
                            {resource: "water", amount: 6}
                        ],
                        set_flag: ["seen_madeira", "seen_river_bend"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 30,
                        description: "The water was foul. Most of it is unusable and the crew falls ill.",
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
                text: "Continue without stopping",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The train rolls on past the river.",
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
        title: "The Derelict Locomotive",
        description: "A rusted locomotive sits abandoned on a siding. Its tender may still hold fuel.",
        weight: 6,
        min_progress: 4,
        min_resources: {},
        max_resources: {fuel: 6},
        required_flags: [],
        forbidden_flags: ["seen_derelict_loco"],
        sound: "sfx_positive",
        choices: [
            {
                text: "Salvage fuel from the tender",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 60,
                        description: "The tender still holds plenty of usable fuel.",
                        effects: [
                            {resource: "fuel", amount: 8}
                        ],
                        set_flag: ["salvaged_wreck", "seen_derelict_loco"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 25,
                        description: "Mostly rust and ash, but a little fuel is salvaged.",
                        effects: [
                            {resource: "fuel", amount: 3}
                        ],
                        set_flag: ["salvaged_wreck", "seen_derelict_loco"],
                        sound: "sfx_positive"
                    },
                    {
                        weight: 15,
                        description: "Part of the wreck collapses. Someone gets hurt, but some fuel is saved.",
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
                text: "Leave it alone",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The crew moves on.",
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
        title: "Dangerous Boiler Pressure",
        description: "The boiler pressure is rising beyond its normal operating range. The engineer needs to act quickly.",
        weight: 7,
        min_progress: 2,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_boiler_pressure"],
        sound: "sfx_negative",
        choices: [
            {
                text: "Vent the excess pressure",
                min_resources: {fuel: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The engineer releases the pressure. The boiler returns to normal.",
                        effects: [
                            {resource: "fuel", amount: -2}
                        ],
                        set_flag: "seen_boiler_pressure",
                        sound: "sfx_positive"
                    }
                ]
            },
            {
                text: "Reinforce the valve",
                min_resources: {tools: 1},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 80,
                        description: "The reinforcement holds. The engine is safe.",
                        effects: [
                            {resource: "tools", amount: -1}
                        ],
                        set_flag: "seen_boiler_pressure",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 20,
                        description: "The valve gives way during the repair. The train suffers damage.",
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
                text: "Continue travelling and hope for the best",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 65,
                        description: "The pressure eventually stabilizes.",
                        effects: [
                            {resource: "fuel", amount: -1}
                        ],
                        set_flag: "seen_boiler_pressure",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 35,
                        description: "The boiler overheats. The locomotive suffers serious damage.",
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
        title: "A Washed-Out Railway",
        description: "Heavy rain has damaged the ground supporting the tracks. The locomotive cannot proceed safely without a decision.",
        weight: 7,
        min_progress: 4,
        min_resources: {},
        max_resources: {},
        required_flags: [],
        forbidden_flags: ["seen_track_washout"],
        sound: "sfx_negative",
        choices: [
            {
                text: "Repair the damaged section",
                min_resources: {tools: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 80,
                        description: "The crew reinforces the railway successfully.",
                        effects: [
                            {resource: "tools", amount: -2}
                        ],
                        set_flag: "seen_track_washout",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 20,
                        description: "The ground gives way during the work. The locomotive is damaged.",
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
                text: "Wait for the water to recede",
                min_resources: {},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 100,
                        description: "The crew waits for safer conditions, consuming precious provisions.",
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
                text: "Cross slowly using extra fuel",
                min_resources: {fuel: 2},
                max_resources: {},
                min_progress: 0,
                required_flags: [],
                forbidden_flags: [],
                sound: "",
                outcomes: [
                    {
                        weight: 65,
                        description: "The locomotive crosses the damaged section carefully.",
                        effects: [
                            {resource: "fuel", amount: -2}
                        ],
                        set_flag: "seen_track_washout",
                        sound: "sfx_positive"
                    },
                    {
                        weight: 35,
                        description: "The weakened ground damages the locomotive during the crossing.",
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
// Assign a sound by its exact asset name, as a string:
// sound: "sfx_rain"
// Leave sound: "" for silence.

play_event_sound = function(_sound_name) {

    if (is_undefined(_sound_name) || _sound_name == "") {
        return;
    }

    var sound_asset = -1;

    // Map the string to a direct Sound Asset reference.
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

// Adds a change to the on-screen feedback list (merges entries of the same resource)
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
    feedback_timer = 6;
};

// Changes one resource, applies limits, logs the real change. Returns the real change.
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

// Supports fixed amounts or random ranges:
// {resource: "fuel", amount: -1}
// {resource: "fuel", min_amount: 2, max_amount: 6}
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

// Player actions: medicine heals crew, tools repair train
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

// HUD layout helpers (shared by Draw GUI and Step)
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

    // If only the immediately previous event is available, allow it again.
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

// Accepts "", one flag name, or an array of flag names.
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
            trigger_game_over("A repair was needed, but no tools were available.");
            return false;
        }
    }

    return true;
};

check_game_over = function() {

    if (game_over || travel_state == "death") return;

    if (resources.crew_health <= 0) {
        trigger_game_over("The crew's health has reached zero.");
        return;
    }

    if (resources.train_health <= 0) {
        trigger_game_over("The locomotive was wrecked beyond repair.");
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
        trigger_game_over("The locomotive ran out of fuel for two consecutive events.");
    }
};

// ============================================================
// UPKEEP
// ============================================================

consume_upkeep = function() {

    // Coal is consumed after every completed event.
    change_resource("fuel", -coal_per_event);

    // Food and water are consumed every ration_interval events.
    events_since_ration++;

    if (events_since_ration >= ration_interval) {
        events_since_ration = 0;

        var short_food = (resources.food < ration_food);
        var short_water = (resources.water < ration_water);

        // Consume whatever remains; values cannot go below zero.
        change_resource("food", -ration_food);
        change_resource("water", -ration_water);

        if (short_food || short_water) {
            var missing = "food";

            if (short_food && short_water) {
                missing = "food and water";
            } else if (short_water) {
                missing = "water";
            }

            if (ration_warning) {
                trigger_game_over("The crew ran out of " + missing + ".");
            } else {
                ration_warning = true;
                ration_warning_text = missing;
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

    // Requirements that may start the death sequence before the event begins.
    if (!check_event_requirements(selected)) {
        return;
    }

    // Event sound plays when the event appears (minor or major).
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
        message_timer = 6;

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

    // Outcome sound takes priority; otherwise use the selected choice's sound.
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

    // Start the death animation once. The Step Event should set game_over=true
    // and travel_state="game_over" after the death animation finishes.
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
