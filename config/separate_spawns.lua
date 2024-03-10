local chunk_size = 32
local sec = 60
local min = sec*60
local hr = min*60

local config = {
    technology_price_multiplier = 1.75,
    new_player_items = {
        ["pistol"]=1,
        ["firearm-magazine"]=20,
        ["iron-plate"]=16,
        ["burner-mining-drill"] = 2,
        ["stone-furnace"] = 2,
    },
    respawn_player_items = {
        ["pistol"]=1,
        ["firearm-magazine"]=10
    },
    logging = {
        decon_logfile = "log/decon.log",
        shoot_logfile = "log/shoot.log"
    },
    spawn_radius = chunk_size*3,
    spawn_trees = true,
    near_distance = {
        min = chunk_size*50,
        max = chunk_size*100
    },
    far_distance = {
        min = chunk_size*150,
        max = chunk_size*300
    },
    distance_from_another_player = chunk_size*50,
    zones = {
        green_zone = {
            radius = chunk_size*16,
            probability = 10,
            instant_death = true,
            full_downgrade = false
        },
        yellow_zone = {
            radius = chunk_size*24,
            probability = 7,
            instant_death = false,
            full_downgrade = true
        },
        red_zone = {
            radius = chunk_size*32,
            probability = 5,
            instant_death = false,
            full_downgrade = false
        }
    },
    minimum_online_time = 15*min
}
config.resources = {
    water = {
        offset = {
            x = -8,
            y = -78
        },
        length = 16
    },
    ["crude-oil"] =
    {
        num_patches = 4,
        amount = 1080000,
        x_offset_start = -8,
        y_offset_start = 78,
        x_offset_next = 6,
        y_offset_next = 0
    },
    ore = {
        size = 22,
        random = {
            enabled = true,
            radius = 0.75*config.spawn_radius,
            angle_offset = 2.285,
            angle_final = 4.57
        },
        tiles = {
            ["iron-ore"] = {
                amount = 2500,
                -- area = {{}, {}} -- in case we don't want random, supply this
            },
            ["copper-ore"] = {
                amount = 2500,
                -- area = {{}, {}}
            },
            ["coal"] = {
                amount = 2500,
                -- area = {{}, {}}
            },
            ["stone"] = {
                amount = 2500,
                -- area = {{}, {}}
            },
        }
    }
}
config.player_settings = {
    ["shared_spawn"] = {
        enabled = false,
    }
}
return config