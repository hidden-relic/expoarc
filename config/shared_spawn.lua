--- Settings for shared spawn
-- @config shared spawn

return {
    deconstruction_radius = 128,
    base_radius = 112,
    deconstruction_tile = 'water',
    base_tile = 'landfill',
    resource_tiles = {
        enabled = true,
        resources = {
            {
                enabled = true,
                name = 'iron-ore',
                amount = 5000,
                size = {26, 27},
                offset = {-64,-32}
                -- offset = {-64,-64}
            },
            {
                enabled = true,
                name = 'copper-ore',
                amount = 5000,
                size = {26, 27},
                offset = {-64, 0}
                -- offset = {64, -64}
            },
            {
                enabled = true,
                name = 'stone',
                amount = 5000,
                size = {26, 27},
                offset = {-64, 32}
                -- offset = {-64, 64}
            },
            {
                enabled = true,
                name = 'coal',
                amount = 5000,
                size = {26, 27},
                offset = {-64, -64}
                -- offset = {64, 64}
            },
            {
                enabled = false,
                name = 'uranium-ore',
                amount = 5000,
                size = {26, 27},
                offset = {-64, -96}
                -- offset = {0, 64}
            }
        }
    },
    resource_patches = {
        enabled = true,
        resources = {
            {
                enabled = true,
                name = 'crude-oil',
                num_patches = 4,
                amount = 5000000,
                offset = {-80, -12},
                -- offset = {-12, 64},
                offset_next = {0, 6}
                -- offset_next = {6, 0}
            }
        }
    },
}
