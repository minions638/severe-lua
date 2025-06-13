local library, flags = loadstring(httpget('https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/cooked%20ui.lua'))()
local window = library:window({name = 'Aftermath - End to open/close', size = {350, 300}}); do
    local settings = window:page({name = 'Settings'}); do
        local zombies, items = settings:multi_section({side = 'Left', size = {1, 0, 1, 0}, tabs = {'Zombies', 'Items'}}); do
            zombies:toggle({name = 'Enabled', flag = 'zombies'})
            zombies:toggle({name = 'Only Special', flag = 'zombies_special'})
            zombies:toggle({name = 'Whitelisted', flag = 'zombies_whitelisted'})

            items:toggle({name = 'Ammo', flag = 'items_ammo'})
            items:toggle({name = 'Weapons', unsafe = true, flag = 'items_weapons'})
            items:toggle({name = 'Repair Kits', flag = 'items_repair_kits'})
        end

        local vehicles, bags = settings:multi_section({side = 'Right', size = {1, 0, 1, -85}, tabs = {'Vehicles', 'Bags'}}); do
            vehicles:toggle({name = 'Enabled', flag = 'vehicles'})

            bags:toggle({name = 'Player Bags', flag = 'player_bags'})
            bags:toggle({name = 'Zombie Bags', flag = 'zombie_bags'})
        end

        local configurations = settings:section({side = 'Right', name = 'Configurations', size = {1, 0, 0, 79}}); do
            configurations:button({name = 'Save Config', callback = function()
                local states = {}
                for k in library.elements do
                    states[k] = library.flags[k]
                end

                writefile('aftermath lua.txt', JSONEncode(states))
                print('saved config')
            end})

            configurations:button({name = 'Load Config', callback = function()
                local success, content = pcall(function()
                    return readfile('aftermath lua.txt')
                end)

                if success then
                    print('loaded config')
                    local decoded = JSONDecode(content)
                    for k, v in decoded do
                        local element = library.elements[k]
                        if element then
                            element.set(v)
                        end
                    end
                end
            end})
        end
    end
end

local meshid = tonumber(httpget('https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/meshid'))
local getmeshid = function(meshpart)
    return getmemoryvalue(meshpart, meshid, 'string')
end

local players = findservice(Game, 'Players')
local workspace = findservice(Game, 'Workspace')

local drops = findfirstchild(findfirstchild(findfirstchild(workspace, 'world_assets'), 'StaticObjects'), 'Misc')
local camera = findfirstchildofclass(workspace, 'Camera')
local zombies = findfirstchild(findfirstchild(workspace, 'game_assets'), 'NPCs')
local characters = findfirstchild(workspace, 'Characters')

local local_player = getlocalplayer()
local local_character = nil

local paths = {
    {name = 'Glock', path = {'Handle2', 'Slide'}},
    {name = 'M1911', path = {'Bullet', 'SKIN01'}},
    {name = 'Makarov', path = {'Static', 'Mag'}},
    {name = 'Desert Eagle', path = {'Static', 'Meshes/DesertEagle_Body', 'SKIN01'}},
    {name = 'Gold Desert Eagle', path = {'Slide', 'SurfaceAppearance'}},
    {name = 'FNX-45', path = {'Static', 'Barrel'}},
    {name = 'S&W .44 Magnum', path = {'Loader'}},
    {name = 'P226', path = {'Static', 'Meshes/SigSaur_Button1'}},
    {name = 'M9', path = {'Mag', 'SKIN02'}},
    {name = 'MK4', path = {'Handle', 'Safety'}},
    {name = 'TEC9', path = {'MovingParts', '9mm', 'Part6'}},

    {name = 'Uzi', path = {'Static', 'Meshes/uzi_better_as_fbx_uzi.001'}},
    {name = 'MP5', path = {'ChargingHandle', 'MP51'}},
    {name = 'P90', path = {'SlideDraw'}},
    {name = 'UMP45', path = {'Gun'}},
    {name = 'Makeshift SMG', path = {'Gas'}},

    {name = 'AR-15', path = {'Bullets', 'Weld'}},
    {name = 'M4A1', path = {'Mag', 'MagVisible', 'Weld'}},
    {name = 'AKM', path = {'Mount'}},
    {name = 'AK-47', path = {'Misc', 'Meshes/AK_Grip'}},
    {name = 'FN-FAL', path = {'Misc', 'Fal'}},
    {name = 'SCAR-H', path = {'Static', 'Scar'}},
    {name = 'MK-18', path = {'Body3'}},
    {name = 'MK-14 EBR', path = {'Body5'}},
    {name = 'MK-47 Mutant', path = {'MK473'}},
    {name = 'Famas', path = {'Meshes/Famas_FamasRBX.001'}},
    {name = 'G36k', path = {'hkey_lp001'}},

    {name = 'SKS', path = {'Static', 'Wood'}},
    {name = 'M110k', path = {'Static', 'Sights'}},
    {name = 'MRAD', path = {'Bolt', 'Bolt'}},
    {name = 'AWM', path = {'Stand'}},
    {name = 'M82A1', path = {'pad_low'}},
    {name = 'SVD', path = {'MagBullet'}},
    {name = 'Mosin Nagant', path = {'BoltBody'}},
    {name = 'M40A1', path = {'Supressor'}},
    {name = 'Remington 700', path = {'BoltVisible'}},
    {name = 'Makeshift Sniper', path = {'Fabric'}},

    {name = 'Renelli M4', path = {'Shotgun'}},
    {name = 'MP-133', path = {'Primary Frame', 'Base'}},
    {name = 'Sawed Off', path = {'Meshes/DoubleBarrelSawedOff_stock_low'}},
    {name = 'Remington 1894', path = {'Barrels'}},
    {name = 'Mossberg 500', path = {'Static', 'Meshes/SM_Mossberg590A1_LP (1)'}},
    {name = 'SPAS-12', path = {'AttachmentReticle', 'RED DOT'}},
    {name = 'Saiga-12', path = {'Static', 'SaigaSP'}},

    {name = 'M249', path = {'Mag', 'MagHandle'}},
    {name = 'PKM', path = {'Static', 'Grip'}},

    {name = 'Makeshift Bow', path = {'Bow', 'bow_mid'}},
    {name = 'Recurve Bow', path = {'Bow', 'Bow'}},
    {name = 'T13 Crossbow', path = {'Arrow'}},
    {name = '10/22 Takedown', path = {'GunParts'}},

    {name = 'Wrench', path = {'Wrench'}}
}

local cache = {
    drops = {},
    players = {},
    zombies = {},
    vehicles = {},
    player_bags = {},
    zombie_bags = {}
}

local meshes = {
    ['rbxassetid://17661257035'] = 'Chinese Zombie',
    ['rbxassetid://11613771301'] = 'Tactical Zombie',
    ['rbxassetid://10058182223'] = 'Weapon Repair Kit',
    ['rbxassetid://8838686715'] = 'Rem .223',
    ['rbxassetid://16828714196'] = '.22 LR',
    ['rbxassetid://7951764278'] = '.308 Win',
    ['rbxassetid://6068549937'] = '.44 Magnum',
    ['rbxassetid://6068551481'] = '9MM Pa.',
    ['rbxassetid://6068551083'] = '.45 ACP',
    ['rbxassetid://6068551303'] = '12 Gauge',
    ['rbxassetid://8905916965'] = '.50 BMG',
    ['rbxassetid://6068550744'] = '7.62 Soviet'
}

local function get_magnitude(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    local dz = (a.z and b.z) and (a.z - b.z) or nil

    if dz then
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    else
        return math.sqrt(dx * dx + dy * dy)
    end
end

local function get_real_name(root_part)
    local root_position = getposition(root_part)

    local player_roots = {}; do
        for _, player in getchildren(players) do
            local character = getcharacter(player)
            if character then
                local server_collider = findfirstchild(character, 'ServerCollider')
                if server_collider then
                    player_roots[#player_roots+1] = server_collider
                end
            end
        end
    end

    local closest_root, closest_distance = nil, 25
    for _, player_root in player_roots do
        local distance = get_magnitude(root_position, getposition(player_root))
        if distance < closest_distance then
            closest_root = player_root
            closest_distance = distance
        end
    end

    if closest_root then
        return getname(getparent(closest_root)) or 'Player'
    else
        return 'Player'
    end
end

local function add_item_data(index, part, name)
    local model_data = {
        Username = name,
        Displayname = name,
        Userid = 0,
        Character = part,
        PrimaryPart = part,
        Humanoid = part,
        Head = part,
        Torso = part,
        LeftArm = part,
        LeftLeg = part,
        RightArm = part,
        RightLeg = part,
        BodyHeightScale = 1,
        RigType = 1,
        Whitelisted = true,
        Archenemies = false,
        Aimbot_Part = part,
        Aimbot_TP_Part = part,
        Triggerbot_Part = part,
        Health = 100,
        MaxHealth = 100
    }

    add_model_data(model_data, index)
end

local function add_drop(drop)
    local drop_string = tostring(drop)
    if getclassname(drop) == 'Model' then
        if flags['items_ammo'] or flags['items_repair_kits'] then
            local main = findfirstchild(drop, 'Main')
            if main and getclassname(main) == 'MeshPart' then
                local meshid = getmeshid(main)
                local name = meshes[meshid]

                if name then
                    if name ~= 'Weapon Repair Kit' then
                        if flags['items_ammo'] then
                            cache.drops[drop_string] = {
                                drop = drop,
                                class = 'ammo'
                            }
                            add_item_data(drop_string, main, name)
                        end
                    elseif flags['items_repair_kits'] then
                        cache.drops[drop_string] = {
                            drop = drop,
                            class = 'repair_kit'
                        }
                        add_item_data(drop_string, main, name)
                    end
                    return
                end
            end
        end

        if flags['items_weapons'] then
            local part = findfirstchildofclass(drop, 'Part') or findfirstchildofclass(drop, 'MeshPart')
            if not part then
                return
            end

            for _, weapon in paths do
                local path = weapon.path
                local depth = drop

                for _, child in path do
                    local found = findfirstchild(depth, child)
                    if found then
                        depth = found
                    else
                        break
                    end
                end

                if depth ~= drop then
                    if getname(depth) == path[#path] then
                        cache.drops[drop_string] = {
                            drop = drop
                        }
                        add_item_data(drop_string, part, weapon.name)
                        return
                    end
                elseif not findfirstchild(drop, 'Main') then
                    cache.drops[drop_string] = {
                        fake = true,
                        drop = drop
                    }
                end
            end
        end
    end
end

local function add_player(character)
    local data = {
        character = character
    }

    local root_part = findfirstchild(character, 'HumanoidRootPart')
    if root_part then
        local name = get_real_name(root_part)
        if name ~= 'Player' then
            local parts = {
                head = findfirstchild(character, 'Head'),
                upper_torso = findfirstchild(character, 'UpperTorso'),
                lower_torso = findfirstchild(character, 'LowerTorso'),
                left_upper_arm = findfirstchild(character, 'LeftUpperArm'),
                left_lower_arm = findfirstchild(character, 'LeftLowerArm'),
                left_hand = findfirstchild(character, 'LeftHand'),
                right_upper_arm = findfirstchild(character, 'RightUpperArm'),
                right_lower_arm = findfirstchild(character, 'RightLowerArm'),
                right_hand = findfirstchild(character, 'RightHand'),
                left_upper_leg = findfirstchild(character, 'LeftUpperLeg'),
                left_lower_leg = findfirstchild(character, 'LeftLowerLeg'),
                left_foot = findfirstchild(character, 'LeftFoot'),
                right_upper_leg = findfirstchild(character, 'RightUpperLeg'),
                right_lower_leg = findfirstchild(character, 'RightLowerLeg'),
                right_foot = findfirstchild(character, 'RightFoot')
            }

            local model_data = {
                Username = name,
                Displayname = name,
                Userid = 0,
                Character = character,
                PrimaryPart = root_part,
                Humanoid = root_part,
                Head = parts.head,
                Torso = parts.upper_torso,
                LeftArm = parts.left_upper_arm,
                LeftLeg = parts.left_upper_leg,
                RightArm = parts.right_upper_arm,
                RightLeg = parts.right_upper_leg,
                BodyHeightScale = 1,
                RigType = 1,
                Whitelisted = false,
                Archenemies = false,
                Aimbot_Part = parts.head,
                Aimbot_TP_Part = parts.head,
                Triggerbot_Part = parts.head,
                Health = 100,
                MaxHealth = 100,
                body_parts_data = {
                    {name = "LowerTorso", part = parts.lower_torso},
                    {name = "LeftUpperArm", part = parts.left_upper_arm},
                    {name = "LeftLowerArm", part = parts.left_hand},
                    {name = "RightUpperArm", part = parts.right_upper_arm},
                    {name = "RightLowerArm", part = parts.right_hand},
                    {name = "LeftUpperLeg", part = parts.left_upper_leg},
                    {name = "LeftLowerLeg", part = parts.left_foot},
                    {name = "RightUpperLeg", part = parts.right_upper_leg},
                    {name = "RightLowerLeg", part = parts.right_foot}
                },
                full_body_data = {
                    {name = 'Head', part = parts.head},
                    {name = "UpperTorso", part = parts.upper_torso},
                    {name = "LowerTorso", part = parts.lower_torso},
                    {name = "LeftUpperArm", part = parts.left_upper_arm},
                    {name = "LeftLowerArm", part = parts.left_lower_arm},
                    {name = "LeftHand", part = parts.left_hand},
                    {name = "RightUpperArm", part = parts.right_upper_arm},
                    {name = "RightLowerArm", part = parts.right_lower_arm},
                    {name = "RightHand", part = parts.right_hand},
                    {name = "LeftUpperLeg", part = parts.left_upper_leg},
                    {name = "LeftLowerLeg", part = parts.left_lower_leg},
                    {name = "LeftFoot", part = parts.left_foot},
                    {name = "RightUpperLeg", part = parts.right_upper_leg},
                    {name = "RightLowerLeg", part = parts.right_lower_leg},
                    {name = "RightFoot", part = parts.right_foot}
                }
            }

            local address = tostring(character)
            data.root_part = root_part

            cache.players[address] = data
            add_model_data(model_data, address)
        end
    end
end

local function add_zombie(character)
    local head = findfirstchild(character, 'Head')
    local root_part = findfirstchild(character, 'HumanoidRootPart')

    if head and root_part then
        local special = false
        local special_name = 'Zombie'

        local equipment = findfirstchild(character, 'Equipment')
        if equipment then
            for _, model in getchildren(equipment) do
                for _, meshpart in getchildren(model) do
                    if getclassname(meshpart) == 'MeshPart' then
                        local name = meshes[getmeshid(meshpart)]
                        if name then
                            special = true
                            special_name = name
                            break
                        end
                    end
                end
            end
        end

        if flags['zombies_special'] and not special then
            return
        end

        local name = special and special_name or 'Zombie ' .. math.random(0, 999)
        local torso = findfirstchild(character, 'Torso')
        local left_arm = findfirstchild(character, 'Left Arm')
        local left_leg = findfirstchild(character, 'Left Leg')
        local right_arm = findfirstchild(character, 'Right Arm')
        local right_leg = findfirstchild(character, 'Right Leg')

        local data = {
            Username = name,
            Displayname = name,
            Userid = 0,
            Character = character,
            PrimaryPart = root_part,
            Humanoid = root_part,
            Head = head,
            Torso = torso,
            LeftArm = left_arm,
            LeftLeg = left_leg,
            RightArm = right_arm,
            RightLeg = right_leg,
            BodyHeightScale = 1,
            RigType = 0,
            Whitelisted = flags['zombies_whitelisted'],
            Archenemies = false,
            Aimbot_Part = head,
            Aimbot_TP_Part = head,
            Triggerbot_Part = head,
            Health = 100,
            MaxHealth = 100,
            body_parts_data = {
                {name = "LowerTorso", part = torso},
                {name = "LeftUpperArm", part = left_arm},
                {name = "LeftLowerArm", part = left_arm},
                {name = "RightUpperArm", part = right_arm},
                {name = "RightLowerArm", part = right_arm},
                {name = "LeftUpperLeg", part = left_leg},
                {name = "LeftLowerLeg", part = left_leg},
                {name = "RightUpperLeg", part = right_leg},
                {name = "RightLowerLeg", part = right_leg}
            },
            full_body_data = {
                {name = 'Head', part = head},
                {name = "UpperTorso", part = torso},
                {name = "LowerTorso", part = torso},
                {name = "LeftUpperArm", part = left_arm},
                {name = "LeftLowerArm", part = left_arm},
                {name = "LeftHand", part = left_arm},
                {name = "RightUpperArm", part = right_arm},
                {name = "RightLowerArm", part = right_arm},
                {name = "RightHand", part = right_arm},
                {name = "LeftUpperLeg", part = left_leg},
                {name = "LeftLowerLeg", part = left_leg},
                {name = "LeftFoot", part = left_leg},
                {name = "RightUpperLeg", part = right_leg},
                {name = "RightLowerLeg", part = right_leg},
                {name = "RightFoot", part = right_leg}
            }
        }

        cache.zombies[tostring(character)] = {special = special, root_part = root_part}
        add_model_data(data, tostring(character))
    end
end

local function add_vehicle(model)
    local chassis = findfirstchild(model, 'Chassis') or findfirstchildofclass(model, 'Part')
    if chassis then
        local model_string = tostring(model)
        cache.vehicles[model_string] = {
            chassis = chassis
        }
        add_item_data(model_string, chassis, 'Vehicle')
    end
end

local function update_cache()
    while true do
        local local_player_character = getcharacter(local_player)
        local local_player_root_part = local_player_character and findfirstchild(local_player_character, 'ServerCollider')
        local local_player_position = local_player_root_part and getposition(local_player_root_part) or getposition(camera)

        local closest_character, closest_distance = nil, 25
        for _, character in getchildren(characters) do
            local root_part = findfirstchild(character, 'HumanoidRootPart')
            if root_part then
                local root_position = getposition(root_part)
                local distance = get_magnitude(root_position, local_player_position)

                if distance < closest_distance then
                    closest_character = character
                    closest_distance = distance
                end
            end

            if character ~= closest_character and not cache.players[tostring(character)] then
                add_player(character)
            end
        end
        local_character = closest_character

        if flags['items_ammo'] or flags['items_weapons'] or flags['items_repair_kits'] then
            for _, drop in getchildren(drops) do
                if not cache.drops[tostring(drop)] then
                    add_drop(drop)
                end
            end
        end

        local vehicles, player_bags, zombie_bags = flags['vehicles'], flags['player_bags'], flags['zombie_bags']
        if vehicles or player_bags or zombie_bags then
            for _, child in getchildren(workspace) do
                if vehicles then
                    if getname(child) == 'WorldModel' and not cache.vehicles[tostring(child)] then
                        add_vehicle(child)
                        continue
                    end
                end

                if player_bags then
                    local child_string = tostring(child)
                    if getname(child) == 'Default' and not cache.player_bags[child_string] then
                        local meshpart = findfirstchildofclass(child, 'MeshPart')
                        if meshpart then
                            cache.player_bags[child_string] = {
                                root_part = meshpart
                            }
                            add_item_data(child_string, meshpart, 'Player Bag')
                            continue
                        end
                    end
                end

                if zombie_bags then
                    local child_string = tostring(child)
                    if getname(child) == 'ZombieGrave' and not cache.zombie_bags[child_string] then
                        local meshpart = findfirstchildofclass(child, 'MeshPart')
                        if meshpart then
                            cache.zombie_bags[child_string] = {
                                root_part = meshpart
                            }
                            add_item_data(child_string, meshpart, 'Zombie Bag')
                            continue
                        end
                    end
                end
            end
        end

        if flags['zombies'] then
            for _, zombie in getchildren(zombies) do
                if not cache.zombies[tostring(zombie)] then
                    add_zombie(zombie)
                end
            end
        end

        wait(0.25)
    end
end

local function update()
    while true do
        for index, player in cache.players do
            local character = player.character
            local root_part = player.root_part
            if character == local_character or not root_part or not isdescendantof(root_part, characters) then
                cache.players[index] = nil
                remove_model_data(index)
            end
        end

        for index, zombie in cache.zombies do
            local special = zombie.special
            local root_part = zombie.root_part
            if flags['zombies_special'] and not special then
                remove_model_data(index)
                cache.zombies[index] = nil
            end

            if not flags['zombies'] or not root_part or not isdescendantof(root_part, zombies) then
                remove_model_data(index)
                cache.zombies[index] = nil
            end
        end

        for index, drop in cache.drops do
            local real = drop.drop
            if drop.fake then
                if not isdescendantof(real, drops) then
                    cache.drops[index] = nil
                end
                continue
            end

            if real then
                if not isdescendantof(real, drops) then
                    cache.drops[index] = nil
                    remove_model_data(index)
                end

                local class = drop.class
                if class then
                    if class == 'ammo' then
                        if not flags['items_ammo'] then
                            cache.drops[index] = nil
                            remove_model_data(index)
                        end
                    else
                        if not flags['items_repair_kits'] then
                            cache.drops[index] = nil
                            remove_model_data(index)
                        end
                    end
                else
                    if not flags['items_weapons'] then
                        cache.drops[index] = nil
                        remove_model_data(index)
                    end
                end
            end
        end

        for index, vehicle in cache.vehicles do
            local chassis = vehicle.chassis
            if chassis then
                if not flags['vehicles'] or not isdescendantof(chassis, workspace) then
                    cache.vehicles[index] = nil
                    remove_model_data(index)
                end
            end
        end

        for index, player_bag in cache.player_bags do
            local root_part = player_bag.root_part
            if not flags['player_bags'] or not root_part or not isdescendantof(root_part, workspace) then
                cache.player_bags[index] = nil
                remove_model_data(index)
            end
        end

        for index, player_bag in cache.zombie_bags do
            local root_part = player_bag.root_part
            if not flags['zombie_bags'] or not root_part or not isdescendantof(root_part, workspace) then
                cache.zombie_bags[index] = nil
                remove_model_data(index)
            end
        end

        wait(0.01)
    end
end

spawn(update_cache)
spawn(update)
