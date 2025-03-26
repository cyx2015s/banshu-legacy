local char_set = require("char_set")
local materials = require("materials")
require("util")
local sizes = {"1x1", "1x2", "2x2"}

local function make_item(size, material, order)
    local size_x = tonumber(size:sub(1, 1)) or 1
    local size_y = tonumber(size:sub(3, 3)) or 1
    local index = size_x + size_y - 1
    local repr
    if index == 1 then repr = "小" end
    if index == 2 then repr = "中" end
    if index == 3 then repr = "大" end
    local icon_path1 = "__banshu__/graphics/" ..
                           tostring(utf8_char_to_code(repr)) .. ".png"
    local icon_path2 = "__base__/graphics/icons/" .. material.item .. ".png"
    local item = {
        type = "item",
        name = "banshu-" .. material.name .. "-" .. size,
        localised_name = {
            "entity-name.banshu", {"banshu-material." .. material.name},
            {"banshu-size." .. size}
        },
        icons = {{icon = icon_path1, icon_size = 128, tint = material.tint}},
        icon_size = 128,
        tint = material.tint,
        subgroup = "banshu",
        order = "f[banshu]-" .. order,
        stack_size = 100,
        place_result = "banshu-" .. material.name .. "-" .. size .. "-0",
    }
    local recipe1 = {
        type = "recipe",
        name = "banshu-" .. material.name .. "-" .. size,
        category = "crafting",
        enabled = true,
        energy_required = 0.25,
        icons = {
            {icon = icon_path1, icon_size = 128, tint = material.tint},
            {icon = icon_path2, icon_size = 64, scale = 0.25, shift = {8, -8}}
        },
        ingredients = {
            {type = "item", name = material.item, amount = size_x * size_y}
        },
        results = {
            {
                type = "item",
                name = "banshu-" .. material.name .. "-" .. size,
                amount = 1
            }
        },
        allow_as_intermediate = false,
        auto_recycle = false,
        allow_quality = false
    }
    local recipe2 = {
        type = "recipe",
        category = "crafting",
        subgroup = "banshu-recycle",
        name = "banshu-recycle-" .. material.name .. "-" .. size,
        localised_name = {
            "recipe-name.banshu-recycle", item.localised_name,
            {"item-name." .. material.item}
        },
        enabled = true,
        energy_required = 0.25,
        icons = {
            {icon = icon_path2, icon_size = 64}, {
                icon = icon_path1,
                icon_size = 128,
                tint = material.tint,
                scale = 0.125,
                shift = {8, -8}
            }
        },
        results = {
            {type = "item", name = material.item, amount = size_x * size_y}
        },
        ingredients = {
            {
                type = "item",
                name = "banshu-" .. material.name .. "-" .. size,
                amount = 1
            }
        },
        allow_decomposition = false,
        show_amount_in_title = false,
        always_show_products = true,
        auto_recycle = false,
        allow_quality = false
    }

    return item, recipe1, recipe2
end

local function create_items(material)
    for k, v in ipairs(sizes) do
        local order = string.char(97 + k)
        local item, recipe1, recipe2 = make_item(v, material, order)
        data:extend({item, recipe1, recipe2})
    end
end

local function make_variant(char_id, size, material)
    local scale
    if size == "1x1" then scale = 0.25 end
    if size == "1x2" then scale = 0.5 end
    if size == "2x2" then scale = 0.5 end
    -- if size == "2x3" then
    --     scale = 0.75
    -- end
    -- if size == "3x3" then
    --     scale = 0.75
    -- end
    -- if size == "2x4" then
    --     scale = 1
    -- end
    -- if size == "4x4" then
    --     scale = 1
    -- end
    local filename = "__banshu__/graphics/" .. char_id .. ".png"
    return {
        filename = filename,
        width = 128,
        height = 128,
        frame_count = 1,
        scale = scale,
        tint = material.tint
    }
end

local function create_entity(material)
    for _, size in pairs(sizes) do
        local item = "banshu-" .. material.name .. "-" .. size
        local last_batch_id = nil
        local cur_batch_id = nil
        local char_id = 0
        local cur_entity = nil
        local k = nil
        local size_x = tonumber(size:sub(1, 1)) or 1
        local size_y = tonumber(size:sub(3, 3)) or 1
        for _, c in ipairs(char_set) do
            k = utf8_char_to_code(c)
            cur_batch_id = math.floor(k / 255)
            local name = "banshu-" .. material.name .. "-" .. size .. "-" ..
                             tostring(cur_batch_id)
            if last_batch_id == nil or last_batch_id ~= cur_batch_id then
                if cur_entity ~= nil then
                    while #cur_entity.pictures < 255 do
                        cur_entity.pictures[#cur_entity.pictures + 1] =
                            make_variant(-1, size, material)
                    end
                    data:extend{cur_entity}
                end
                last_batch_id = cur_batch_id
                cur_entity = {
                    name = name,
                    type = "simple-entity-with-owner",
                    icon = "__banshu__/graphics/-1.png",
                    localised_name = {
                        "entity-name.banshu",
                        {"banshu-material." .. material.name},
                        {"banshu-size." .. size}, {c}
                    },
                    icon_size = 64,
                    flags = {
                        'placeable-neutral', 'player-creation', 'not-rotatable',
                        'not-flammable'
                    },
                    minable = {
                        hardness = 0,
                        mining_time = 0.1 * math.max(size_x, size_y),
                        -- result = material.item,
                        -- count = size_x * size_y,
                        result = item
                    },
                    render_layer = "floor",
                    collision_mask = {
                        layers = {
                            item = true,
                            meltable = true,
                            object = true,
                            player = true,
                            water_tile = true,
                            is_object = true,
                            is_lower_object = true
                        }
                    },
                    resistances = {{type = "fire", percent = 100}},
                    pictures = {},
                    placeable_by = {item = item, count = 1},
                    max_health = 25 * size_x * size_y,
                    collision_box = {
                        {-0.4 * size_x, -0.4 * size_y},
                        {0.4 * size_x, 0.4 * size_y}
                    },
                    selection_box = {
                        {-0.5 * size_x, -0.5 * size_y},
                        {0.5 * size_x, 0.5 * size_y}
                    },
                    corpse = "small-remnants",
                    hidden_in_factoriopedia = true
                }
            end
            if cur_entity ~= nil then
                char_id = utf8_char_to_code(c)
                while #cur_entity.pictures ~= mod(char_id, 255) do
                    cur_entity.pictures[#cur_entity.pictures + 1] =
                        make_variant(-1, size, material)
                end
                cur_entity.pictures[#cur_entity.pictures + 1] = make_variant(
                                                                    char_id,
                                                                    size,
                                                                    material)
            end
        end
        if cur_entity ~= nil and cur_entity.pictures then
            data:extend{cur_entity}
        end
    end
end

for _, material in pairs(materials) do
    create_items(material)
    create_entity(material)
end

-- os.execute("chcp 65001")
-- for k, v in ipairs(char_set) do
--     print(k, v)
-- end
