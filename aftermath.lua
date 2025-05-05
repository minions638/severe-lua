--// services
local players = findservice(Game, 'Players')
local workspace = findservice(Game, 'Workspace')
 
--// variables
local drops = findfirstchild(findfirstchild(findfirstchild(workspace, 'world_assets'), 'StaticObjects'), 'Misc')
local camera = findfirstchild(workspace, 'Camera')
local zombies = findfirstchild(findfirstchild(workspace, 'game_assets'), 'NPCs')
local characters = findfirstchild(workspace, 'Characters')
local localplayer = getlocalplayer()
local closest_to_camera = nil

local function getmagnitude(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    local dz = (a.z and b.z) and (a.z - b.z) or nil

    if dz then
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    else
        return math.sqrt(dx * dx + dy * dy)
    end
end

local function getplayername(model)
    local model_root = findfirstchild(model, 'HumanoidRootPart')
    if not model_root then
        return 'Player ' .. math.random(0, 999)
    end

    local roots = {}
    for _, player in getchildren(players) do
        local character = getcharacter(player)
        if (character ~= nil) and (getparent(character) == workspace) then
            local rootpart = findfirstchild(character, 'ServerCollider')
            if rootpart then
                roots[#roots+1] = rootpart
            end
        end
    end

    local closest, dist = nil, 25
    for _, root in roots do
        local diff = getmagnitude(getposition(model_root), getposition(root))
        if diff < dist then
            closest = root
            dist = diff
        end
    end

    if closest then
        return getname(getparent(closest))
    end

    return 'Player ' .. math.random(0, 999)
end

local cache = {}
local function setup_entity(primary, class)
    local temp = {
        primary = primary,
        class = class
    }

    local rootpart = findfirstchild(primary, 'HumanoidRootPart')
    if not rootpart then
        return
    end

    local head = findfirstchild(primary, 'Head')
    if not head then
        return
    end

    if class == 'zombie' then
        local name = 'Zombie ' .. math.random(0, 999)
        local torso = findfirstchild(primary, 'Torso')
        local left_arm = findfirstchild(primary, 'Left Arm')
        local left_leg = findfirstchild(primary, 'Left Leg')
        local right_arm = findfirstchild(primary, 'Right Arm')
        local right_leg = findfirstchild(primary, 'Right Leg')

        local data = {
            Username = name,
            Displayname = name,
            Userid = 0,
            Character = primary,
            PrimaryPart = rootpart,
            Humanoid = rootpart,
            Head = head,
            Torso = torso,
            LeftArm = left_arm,
            LeftLeg = left_leg,
            RightArm = right_arm,
            RightLeg = right_leg,
            BodyHeightScale = 1,
            RigType = 0,
            Whitelisted = false,
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
        
        temp.name = name
        add_model_data(data, tostring(primary))
    elseif class == 'player' then
        local name = getplayername(primary)
        local upper_torso = findfirstchild(primary, 'UpperTorso')
        local lower_torso = findfirstchild(primary, 'LowerTorso')
        local left_upper_arm = findfirstchild(primary, 'LeftUpperArm')
        local left_lower_arm = findfirstchild(primary, 'LeftLowerArm')
        local left_hand = findfirstchild(primary, 'LeftHand')
        local right_upper_arm = findfirstchild(primary, 'RightUpperArm')
        local right_lower_arm = findfirstchild(primary, 'RightLowerArm')
        local right_hand = findfirstchild(primary, 'RightHand')
        local left_upper_leg = findfirstchild(primary, 'LeftUpperLeg')
        local left_lower_leg = findfirstchild(primary, 'LeftLowerLeg')
        local left_foot = findfirstchild(primary, 'LeftFoot')
        local right_upper_leg = findfirstchild(primary, 'RightUpperLeg')
        local right_lower_leg = findfirstchild(primary, 'RightLowerLeg')
        local right_foot = findfirstchild(primary, 'RightFoot')

        local data = {
            Username = name,
            Displayname = name,
            Userid = 0,
            Character = primary,
            PrimaryPart = rootpart,
            Humanoid = rootpart,
            Head = head,
            Torso = upper_torso,
            LeftArm = left_upper_arm,
            LeftLeg = left_upper_leg,
            RightArm = right_upper_arm,
            RightLeg = right_upper_leg,
            BodyHeightScale = 1,
            RigType = 1,
            Whitelisted = false,
            Archenemies = false,
            Aimbot_Part = head,
            Aimbot_TP_Part = head,
            Triggerbot_Part = head,
            Health = 100,
            MaxHealth = 100,
            body_parts_data = {
                {name = "LowerTorso", part = lower_torso},
                {name = "LeftUpperArm", part = left_upper_arm},
                {name = "LeftLowerArm", part = left_hand},
                {name = "RightUpperArm", part = right_upper_arm},
                {name = "RightLowerArm", part = right_hand},
                {name = "LeftUpperLeg", part = left_upper_leg},
                {name = "LeftLowerLeg", part = left_foot},
                {name = "RightUpperLeg", part = right_upper_leg},
                {name = "RightLowerLeg", part = right_foot}
            },
            full_body_data = {
                {name = 'Head', part = head},
                {name = "UpperTorso", part = upper_torso},
                {name = "LowerTorso", part = lower_torso},
                {name = "LeftUpperArm", part = left_upper_arm},
                {name = "LeftLowerArm", part = left_lower_arm},
                {name = "LeftHand", part = left_hand},
                {name = "RightUpperArm", part = right_upper_arm},
                {name = "RightLowerArm", part = right_lower_arm},
                {name = "RightHand", part = right_hand},
                {name = "LeftUpperLeg", part = left_upper_leg},
                {name = "LeftLowerLeg", part = left_lower_leg},
                {name = "LeftFoot", part = left_foot},
                {name = "RightUpperLeg", part = right_upper_leg},
                {name = "RightLowerLeg", part = right_lower_leg},
                {name = "RightFoot", part = right_foot}
            }
        }
        
        temp.name = name
        add_model_data(data, tostring(primary))
    end

    temp.rootpart = rootpart
    cache[tostring(primary)] = temp
end

local function setup_cache()
    while wait(1 / 30) do
        local all_players = {}
        for _, model in getchildren(characters) do
            all_players[#all_players+1] = model
            if (model ~= closest_to_camera) and (not cache[tostring(model)]) then
                setup_entity(model, 'player')
            end
        end

        if not is_team_check_active() then
            for _, model in getchildren(zombies) do
                if not cache[tostring(model)] then
                    setup_entity(model, 'zombie')
                end
            end
        end

        local local_character = getcharacter(localplayer)
        local local_rootpart = findfirstchild(local_character, 'ServerCollider')
        local local_position = local_rootpart and getposition(local_rootpart) or getposition(camera)

        local closest, dist = nil, 20
        for _, player in all_players do
            local rootpart = findfirstchild(player, 'HumanoidRootPart')
            if rootpart then
                local rootpos = getposition(rootpart)
                local diff = getmagnitude(local_position, rootpos)

                if diff < dist then
                    closest = player
                    dist = diff
                end
            end
        end

        closest_to_camera = closest
        table.clear(all_players)
    end
end

local function updater()
    while wait(1 / 240) do        
        for index, entry in cache do
            local class = entry.class
            if class == 'zombie' then
                local primary = entry.primary
                local rootpart = entry.rootpart
                if is_team_check_active() or (not rootpart) or (not isdescendantof(primary, workspace)) then
                    remove_model_data(index)
                    cache[index] = nil
                    continue
                end
            elseif class == 'player' then
                local primary = entry.primary
                local rootpart = entry.rootpart
                if (primary == closest_to_camera) or (not rootpart) or (not isdescendantof(primary, workspace)) then
                    remove_model_data(index)
                    cache[index] = nil
                    continue
                end
            end
        end
    end
end

clear_model_data()
spawn(setup_cache)
spawn(updater)