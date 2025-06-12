local library, flags = loadstring(httpget('https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/cooked%20ui.lua'))()
local window = library:window({name = 'Aftermath - End to open/close', size = {350, 300}}); do
    local settings = window:page({name = 'Settings'}); do
        local zombies, items = settings:multi_section({side = 'Left', size = {1, 0, 1, 0}, tabs = {'Zombies', 'Items'}}); do
            zombies:toggle({name = 'Enabled', flag = 'zombies'})
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

local cache = {
    drops = {},
    players = {},
    zombies = {},
    vehicles = {},
    player_bags = {},
    zombie_bags = {}
}

local meshes = {
    ['rbxassetid://10058182223'] = 'Weapon Repair Kit',
    ['rbxassetid://8838686715'] = '.223 Rem',
    ['rbxassetid://16828714196'] = '.22 LR',
    ['rbxassetid://7951764278'] = '.308 Win',
    ['rbxassetid://6068549937'] = '.44 Magnum',
    ['rbxassetid://6068551481'] = '9mm Para',
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
                            add_item_data(drop_string, main, name)
                            cache.drops[drop_string] = {
                                drop = drop,
                                class = 'ammo'
                            }
                        end
                    elseif flags['items_repair_kits'] then
                        add_item_data(drop_string, main, name)
                        cache.drops[drop_string] = {
                            drop = drop,
                            class = 'repair_kit'
                        }
                    end
                    return
                end
            end
        end

        if not flags['items_weapons'] then
            return
        end

        local Wrench = findfirstchild(drop, 'Wrench')
        if Wrench then
            add_item_data(drop_string, Wrench, 'Wrench')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local part = findfirstchildofclass(drop, 'Part') or findfirstchildofclass(drop, 'MeshPart')
        if not part then
            return
        end

        local Barret50 = findfirstchild(drop, 'pad_low')
        if Barret50 then
            add_item_data(drop_string, part, 'Barret50')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local RenelliM4 = findfirstchild(drop, 'Shotgun')
        if RenelliM4 then
            add_item_data(drop_string, part, 'Renelli M4')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local Makarov = findfirstchild(drop, 'Static')
        if Makarov then
            local Mag = findfirstchild(Makarov, 'Mag')
            if Mag then
                add_item_data(drop_string, part, 'Makarov')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local AR15 = findfirstchild(drop, 'Bullets')
        if AR15 then
            local Weld = findfirstchild(AR15, 'Weld')
            if Weld then
                add_item_data(drop_string, part, 'AR15')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local DesertEagleGold = findfirstchild(drop, 'Slide')
        if DesertEagleGold then
            local SurfaceAppearance = findfirstchild(DesertEagleGold, 'SurfaceAppearance')
            if SurfaceAppearance then
                add_item_data(drop_string, part, 'Gold Desert Eagle')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local MK18 = findfirstchild(drop, 'Body3')
        if MK18 then
            add_item_data(drop_string, part, 'MK18')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local SVD = findfirstchild(drop, 'MagBullet')
        if SVD then
            add_item_data(drop_string, part, 'SVD')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local SKS = findfirstchild(drop, 'bolt')
        if SKS then
            add_item_data(drop_string, part, 'SKS')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local M110K = findfirstchild(drop, 'Static')
        if M110K then
            local Sights = findfirstchild(M110K, 'Sights')
            if Sights then
                add_item_data(drop_string, part, 'M110K')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local AWM = findfirstchild(drop, 'Stand')
        if AWM then
            add_item_data(drop_string, part, 'AWM')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local M4A1 = findfirstchild(drop, 'Mag')
        if M4A1 then
            local MagVisible = findfirstchild(M4A1, 'MagVisible')
            if MagVisible then
                local Weld = findfirstchild(MagVisible, 'Weld')
                if Weld then
                    add_item_data(drop_string, part, 'M4A1')
                    cache.drops[drop_string] = {
                        drop = drop
                    }
                    return
                end
            end
        end

        local MRAD = findfirstchild(drop, 'Bolt')
        if MRAD then
            local Bolt = findfirstchild(MRAD, 'Bolt')
            if Bolt then
                add_item_data(drop_string, part, 'MRAD')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local M249 = findfirstchild(drop, 'Mag')
        if M249 then
            local MagHandle = findfirstchild(M249, 'MagHandle')
            if MagHandle then
                add_item_data(drop_string, part, 'M249')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local Glock = findfirstchild(drop, 'Handle2')
        if Glock then
            local Slide = findfirstchild(Glock, 'Slide')
            if Slide then
                add_item_data(drop_string, part, 'Glock')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local FNX45 = findfirstchild(drop, 'Static')
        if FNX45 then
            local Barrel = findfirstchild(FNX45, 'Barrel')
            if Barrel then
                add_item_data(drop_string, part, 'FNX45')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local AKM = findfirstchild(drop, 'Mount')
        if AKM then
            add_item_data(drop_string, part, 'AKM')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local MK47 = findfirstchild(drop, 'MK473')
        if MK47 then
            add_item_data(drop_string, part, 'MK47')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local Scrap_SMG = findfirstchild(drop, 'Gas')
        if Scrap_SMG then
            add_item_data(drop_string, part, 'Scrap SMG')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local UZI = findfirstchild(drop, 'Static')
        if UZI then
            local Meshes = findfirstchild(UZI, 'Meshes')
            if Meshes then
                local uziPart = findfirstchild(Meshes, 'uzi_better_as_fbx_uzi.001')
                if uziPart then
                    add_item_data(drop_string, part, 'UZI')
                    cache.drops[drop_string] = {
                        drop = drop
                    }
                    return
                end
            end
        end

        local SCAR = findfirstchild(drop, 'Static')
        if SCAR then
            local Scar = findfirstchild(SCAR, 'Scar')
            if Scar then
                add_item_data(drop_string, part, 'SCAR')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local RevolverNew = findfirstchild(drop, 'Loader')
        if RevolverNew then
            add_item_data(drop_string, part, 'Magnum')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local SawedOff = findfirstchild(drop, 'Meshes/DoubleBarrelSawedOff_stock_low')
        if SawedOff then
            add_item_data(drop_string, part, 'Sawed Off')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local PKM = findfirstchild(drop, 'Static')
        if PKM then
            local Grip = findfirstchild(PKM, 'Grip')
            if Grip then
                add_item_data(drop_string, part, 'PKM')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local M40A1 = findfirstchild(drop, 'Supressor')
        if M40A1 then
            add_item_data(drop_string, part, 'M40A1')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local MP5 = findfirstchild(drop, 'ChargingHandle')
        if MP5 then
            local MP51 = findfirstchild(MP5, 'MP51')
            if MP51 then
                add_item_data(drop_string, part, 'MP5')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local Famas = findfirstchild(drop, 'Meshes/Famas_FamasRBX.001')
        if Famas then
            add_item_data(drop_string, part, 'Famas')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local Saiga = findfirstchild(drop, 'Static')
        if Saiga then
            local SaigaSP = findfirstchild(Saiga, 'SaigaSP')
            if SaigaSP then
                add_item_data(drop_string, part, 'Saiga')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local M1911 = findfirstchild(drop, 'Bullet')
        if M1911 then
            local SKIN01 = findfirstchild(M1911, 'SKIN01')
            if SKIN01 then
                add_item_data(drop_string, part, 'M1911')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local FAL = findfirstchild(drop, 'Misc')
        if FAL then
            local Fal = findfirstchild(FAL, 'Fal')
            if Fal then
                add_item_data(drop_string, part, 'FAL')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local BowAndArrowRecurve = findfirstchild(drop, 'Bow')
        if BowAndArrowRecurve then
            local Bow2 = findfirstchild(BowAndArrowRecurve, 'Bow')
            if Bow2 then
                add_item_data(drop_string, part, 'Bow Recurve')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local Sporter = findfirstchild(drop, 'GunParts')
        if Sporter then
            add_item_data(drop_string, part, 'Sporter')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local Crossbow = findfirstchild(drop, 'Arrow')
        if Crossbow then
            add_item_data(drop_string, part, 'Crossbow')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local UMP45 = findfirstchild(drop, 'Gun')
        if UMP45 then
            add_item_data(drop_string, part, 'UMP45')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local DesertEagle = findfirstchild(drop, 'Static')
        if DesertEagle then
            local Body = findfirstchild(DesertEagle, 'Meshes/DesertEagle_Body')
            if Body then
                local SKIN01 = findfirstchild(Body, 'SKIN01')
                if SKIN01 then
                    add_item_data(drop_string, part, 'Desert Eagle')
                    cache.drops[drop_string] = {
                        drop = drop
                    }
                    return
                end
            end
        end

        local AK47 = findfirstchild(drop, 'Misc')
        if AK47 then
            local Grip = findfirstchild(AK47, 'Meshes/AK_Grip')
            if Grip then
                add_item_data(drop_string, part, 'AK47')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local DoubleBarrelShotgun = findfirstchild(drop, 'Barrels')
        if DoubleBarrelShotgun then
            add_item_data(drop_string, part, 'Double Barrel Shotgun')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local Shotgun = findfirstchild(drop, 'Primary Frame')
        if Shotgun then
            local Base = findfirstchild(Shotgun, 'Base')
            if Base then
                add_item_data(drop_string, part, 'Shotgun')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local MK14 = findfirstchild(drop, 'Body5')
        if MK14 then
            add_item_data(drop_string, part, 'MK14')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local MosinNagant = findfirstchild(drop, 'BoltBody')
        if MosinNagant then
            add_item_data(drop_string, part, 'Mosin Nagant')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local Tec9 = findfirstchild(drop, 'MovingParts')
        if Tec9 then
            local mm9 = findfirstchild(Tec9, '9mm')
            if mm9 then
                local Part6 = findfirstchild(mm9, 'Part6')
                if Part6 then
                    add_item_data(drop_string, part, 'Tec9')
                    cache.drops[drop_string] = {
                        drop = drop
                    }
                    return
                end
            end
        end

        local BowAndArrow = findfirstchild(drop, 'Bow')
        if BowAndArrow then
            local bow_mid = findfirstchild(BowAndArrow, 'bow_mid')
            if bow_mid then
                add_item_data(drop_string, part, 'Bow')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local SPAS12 = findfirstchild(drop, 'AttachmentReticle')
        if SPAS12 then
            local RedDot = findfirstchild(SPAS12, 'RED DOT')
            if RedDot then
                add_item_data(drop_string, part, 'SPAS12')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local HuntingRifle = findfirstchild(drop, 'BoltVisible')
        if HuntingRifle then
            add_item_data(drop_string, part, 'Hunting Rifle')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local P226 = findfirstchild(drop, 'Static')
        if P226 then
            local Button1 = findfirstchild(P226, 'Meshes/SigSaur_Button1')
            if Button1 then
                add_item_data(drop_string, part, 'P226')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local M9 = findfirstchild(drop, 'Mag')
        if M9 then
            local SKIN02 = findfirstchild(M9, 'SKIN02')
            if SKIN02 then
                add_item_data(drop_string, part, 'M9')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local MK4 = findfirstchild(drop, 'Handle')
        if MK4 then
            local Safety = findfirstchild(MK4, 'Safety')
            if Safety then
                add_item_data(drop_string, part, 'MK4')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local Mossberg = findfirstchild(drop, 'Static')
        if Mossberg then
            local Moss = findfirstchild(Mossberg, 'Meshes/SM_Mossberg590A1_LP (1)')
            if Moss then
                add_item_data(drop_string, part, 'Mossberg')
                cache.drops[drop_string] = {
                    drop = drop
                }
                return
            end
        end

        local P90 = findfirstchild(drop, 'SlideDraw')
        if P90 then
            add_item_data(drop_string, part, 'P90')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local G36k = findfirstchild(drop, 'hkey_lp001')
        if G36k then
            add_item_data(drop_string, part, 'G36k')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        local Scrap_Sniper = findfirstchild(drop, 'Fabric')
        if Scrap_Sniper then
            add_item_data(drop_string, part, 'Scrap Sniper')
            cache.drops[drop_string] = {
                drop = drop
            }
            return
        end

        cache.drops[drop_string] = {
            drop = drop
        }
    end
end

local function add_player(character)
    local data = {
        real_name = false,
        character = character
    }

    local root_part = findfirstchild(character, 'HumanoidRootPart')
    if root_part then
        local name = get_real_name(root_part)
        if name ~= 'Player' then
            data.real_name = true
        end

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
        add_model_data(model_data, address)

        data.parts = parts
        data.root_part = root_part
        cache.players[address] = data
    end
end

local function add_zombie(character)
    local head = findfirstchild(character, 'Head')
    local root_part = findfirstchild(character, 'HumanoidRootPart')

    if head and root_part then
        local name = 'Zombie ' .. math.random(0, 999)
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

        cache.zombies[tostring(character)] = {root_part = root_part}
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
            if character ~= local_character and root_part and isdescendantof(root_part, workspace) then
                if not player.real_name then
                    local real_name = get_real_name(root_part)
                    if real_name ~= 'Player' then
                        player.real_name = true
                        remove_model_data(index)

                        local parts = player.parts
                        local model_data = {
                            Username = real_name,
                            Displayname = real_name,
                            Userid = 0,
                            Character = player.character,
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
                        
                        add_model_data(model_data, index)
                    end
                end
            else
                remove_model_data(index)
                cache.players[index] = nil
            end
        end

        for index, zombie in cache.zombies do
            local root_part = zombie.root_part
            if not flags['zombies'] or not root_part or not isdescendantof(root_part, workspace) then
                remove_model_data(index)
                cache.zombies[index] = nil
            end
        end

        for index, drop in cache.drops do
            local real = drop.drop
            if drop.fake then
                if not isdescendantof(real, workspace) then
                    cache.drops[index] = nil
                    continue
                end
            end

            if real then
                if not isdescendantof(real, workspace) then
                    remove_model_data(index)
                    cache.drops[index] = nil
                end

                local class = drop.class
                if class then
                    if class == 'ammo' then
                        if not flags['items_ammo'] then
                            remove_model_data(index)
                            cache.drops[index] = nil
                        end
                    else
                        if not flags['items_repair_kits'] then
                            remove_model_data(index)
                            cache.drops[index] = nil
                        end
                    end
                else
                    if not flags['items_weapons'] then
                        remove_model_data(index)
                        cache.drops[index] = nil
                    end
                end
            end
        end

        for index, vehicle in cache.vehicles do
            local chassis = vehicle.chassis
            if chassis then
                if not flags['vehicles'] or not isdescendantof(chassis, workspace) then
                    remove_model_data(index)
                    cache.vehicles[index] = nil
                end
            end
        end

        for index, player_bag in cache.player_bags do
            local root_part = player_bag.root_part
            if not flags['player_bags'] or not root_part or not isdescendantof(root_part, workspace) then
                remove_model_data(index)
                cache.player_bags[index] = nil
            end
        end

        for index, player_bag in cache.zombie_bags do
            local root_part = player_bag.root_part
            if not flags['zombie_bags'] or not root_part or not isdescendantof(root_part, workspace) then
                remove_model_data(index)
                cache.zombie_bags[index] = nil
            end
        end

        wait(0.01)
    end
end

spawn(update_cache)
spawn(update)
