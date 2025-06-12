-- unfinished, barely works
-- do not use this!!

local CrtOB = CrtOB
local SetOB = SetOB
local RetOB = RetOB
local DesOB = DesOB
local floor = math.floor
local random = math.random
local isleftpressed = isleftpressed
local getmouseposition = getmouseposition

local library = {
    accent = {0, 113, 203}, -- default: {127, 72, 163}
    font = {
        index = 29, -- other: 19
        size = 12.8 -- other: 12
    },
    flags = {},
    elements = {},
    drawings = {},
    windows = {}
}

local stop = false
local font = library.font
local flags = library.flags
local accent = library.accent
local elements = library.elements
local drawings = library.drawings
local screensize = getscreendimensions()

local create = function(class, properties)
    if class ~= 'Square' and class ~= 'Image' and class ~= 'Text' then
        return
    end

    local zindex = properties.zIndex or (#drawings + 1)
    local instance = CrtOB(class)

    local parent = properties.Parent or nil
    local children = {}

    local size_udim2 = {
        scale = {0, 0},
        offset = {0, 0}
    }

    local position_udim2 = {
        scale = {0, 0},
        offset = {0, 0}
    }

    local function update_size()
        if parent ~= nil then
            local floored = {
                floor(parent.AbsSize.x * size_udim2.scale[1] + size_udim2.offset[1]),
                floor(parent.AbsSize.y * size_udim2.scale[2] + size_udim2.offset[2])
            }
            SetOB(instance, 'Size', floored)
        else
            local floored = {
                floor(size_udim2.offset[1]),
                floor(size_udim2.offset[2])
            }
            SetOB(instance, 'Size', floored)
        end
    end

    local function update_position()
        if parent ~= nil then
            local floored = {
                floor(parent.AbsPos.x + (parent.AbsSize.x * position_udim2.scale[1] + position_udim2.offset[1])),
                floor(parent.AbsPos.y + (parent.AbsSize.y * position_udim2.scale[2] + position_udim2.offset[2]))
            }
            SetOB(instance, 'Position', floored)
        else
            local floored = {
                floor(position_udim2.offset[1]),
                floor(position_udim2.offset[2])
            }
            SetOB(instance, 'Position', floored)
        end
    end

    for property, value in properties do
        if property == 'Size' then
            if class == 'Text' then
                SetOB(instance, 'Size', value)
            else
                if value[3] then
                    size_udim2.scale = {value[1], value[3]}
                    size_udim2.offset = {value[2], value[4]}
                    update_size()
                else
                    size_udim2.scale = {0, 0}
                    size_udim2.offset = {value[1], value[2]}
                    update_size()
                end
            end
        elseif property == 'Position' then
            if value[3] then
                position_udim2.scale = {value[1], value[3]}
                position_udim2.offset = {value[2], value[4]}
                update_position()
            else
                position_udim2.scale = {0, 0}
                position_udim2.offset = {value[1], value[2]}
                update_position()
            end
        elseif property ~= 'Parent' then
            SetOB(instance, property, value)
        end
    end

    local callbacks = {
        click_began = {},
        click_ended = {}
    }

    local meta = setmetatable({}, {
        __index = function(self, key)
            if key == 'AbsSize' then
                return RetOB(instance, 'Size')
            elseif key == 'AbsPos' then
                return RetOB(instance, 'Position')
            elseif key == 'Size' then
                return size_udim2
            elseif key == 'Position' then
                return position_udim2
            elseif key == 'Refresh' then
                return function()
                    if class == 'Text' then
                        update_position()
                    else
                        update_size()
                        update_position()
                    end
                end
            elseif key == 'GetChildren' then
                return function()
                    return children
                end
            elseif key == 'Parent' then
                return parent
            elseif key == 'Class' then
                return class
            elseif key == 'ClickBegan' then
                return {
                    Connect = function(self, func)
                        local tbl = callbacks.click_began
                        tbl[#tbl + 1] = func
                    end
                }
            elseif key == 'ClickEnded' then
                return {
                    Connect = function(self, func)
                        local tbl = callbacks.click_ended
                        tbl[#tbl + 1] = func
                    end
                }
            elseif key == 'BeginClick' then
                return function()
                    local tbl = callbacks.click_began
                    for _, func in tbl do
                        func()
                    end
                end
            elseif key == 'EndClick' then
                return function()
                    local tbl = callbacks.click_ended
                    for _, func in tbl do
                        func()
                    end
                end
            elseif key == 'CountConnections' then
                local v = 0
                for _ in callbacks.click_began do
                    v = v + 1
                end
                for _ in callbacks.click_ended do
                    v = v + 1
                end
                return v
            elseif key == 'Remove' then
                return function()
                    DesOB(instance)
                end
            else
                return RetOB(instance, key)
            end
        end,

        __newindex = function(self, key, value)
            if key == 'Size' then
                if class == 'Text' then
                    SetOB(instance, 'Size', value)
                else
                    if value[3] then
                        size_udim2.scale = {value[1], value[3]}
                        size_udim2.offset = {value[2], value[4]}
                        update_size()
                    else
                        size_udim2.scale = {0, 0}
                        size_udim2.offset = {value[1], value[2]}
                        update_size()
                    end
                end
            elseif key == 'Position' then
                if value[3] then
                    position_udim2.scale = {value[1], value[3]}
                    position_udim2.offset = {value[2], value[4]}
                    update_position()
                else
                    position_udim2.scale = {0, 0}
                    position_udim2.offset = {value[1], value[2]}
                    update_position()
                end
            elseif key ~= 'Parent' then
                SetOB(instance, key, value)
            end
        end
    })

    if parent then
        local _children = parent:GetChildren()
        _children[#_children+1] = meta
    end

    drawings[#drawings + 1] = {
        meta = meta,
        class = class,
        pressed = false,
        instance = instance
    }

    return meta
end

local getdescendants = function(instance_mt)
    local descendants = {}

    local function search(mt)
        for _, child_mt in mt:GetChildren() do
            descendants[#descendants+1] = child_mt
            search(child_mt)
        end
    end

    for _, child_mt in instance_mt:GetChildren() do
        descendants[#descendants+1] = child_mt
        search(child_mt)
    end

    return descendants
end

spawn(function() -- click handler
    local last_state = false
    while wait(1 / 60) do
        if stop then
            break
        end

        local mouse_position = getmouseposition()
        local is_left_pressed = isleftpressed()

        local topmost_entry = nil
        local topmost_zindex = 0

        for _, entry in drawings do
            local meta = entry.meta
            local class = entry.class
            local instance = entry.instance

            if class ~= 'Text' and RetOB(instance, 'Visible') and meta.CountConnections > 0 then
                local size = RetOB(instance, 'Size')
                local position = RetOB(instance, 'Position')

                if size and position and mouse_position then
                    local inside = mouse_position.x >= position.x and mouse_position.x <= position.x + size.x and mouse_position.y >= position.y and mouse_position.y <= position.y + size.y
                    if not inside then
                        continue
                    end

                    local zindex = RetOB(instance, 'zIndex')
                    if zindex >= topmost_zindex then
                        topmost_zindex = zindex
                        topmost_entry = entry
                    end
                end
            end
        end

        if is_left_pressed and not last_state and topmost_entry and not topmost_entry.pressed then
            topmost_entry.pressed = true
            topmost_entry.meta:BeginClick()
        end

        for _, entry in drawings do
            if not is_left_pressed and entry.pressed then
                entry.pressed = false
                entry.meta:EndClick()
            end
        end

        last_state = is_left_pressed
    end
end)

library.window = function(self, cfg)
    local config = {
        name = cfg.name or 'Window',
        size = cfg.size or {500, 600},
        position = cfg.position or nil
    }

    local window = {
        lastpos = {0, 0},
        visible = true,
        pages = {},
        drawings = {}
    }

    local window_outline = create('Square', {
        Color = {0, 0, 0},
        Size = config.size,
        Position = config.position or {(screensize.x / 2) - (config.size[1] / 2), (screensize.y / 2) - (config.size[2] / 2)},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true
    })
    window.drawings.window_outline = window_outline

    do -- window dragging
        local dragging = false
        local drag_pos = nil

        window_outline.ClickBegan:Connect(function()
            dragging = true
            drag_pos = getmouseposition()
        end)

        window_outline.ClickEnded:Connect(function()
            dragging = false
        end)

        spawn(function()
            while wait(1 / 120) do
                if stop then
                    break
                end

                if dragging then
                    local mousepos = getmouseposition()
                    local diff = {x = mousepos.x - drag_pos.x, y = mousepos.y - drag_pos.y}
                    drag_pos = mousepos
        
                    window_outline.Position = {window_outline.AbsPos.x + diff.x, window_outline.AbsPos.y + diff.y}
        
                    for _, entry in drawings do
                        entry.meta:Refresh()
                    end
                end
            end
        end)
    end

    local window_inline = create('Square', {
        Color = {20, 20, 20},
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = window_outline
    })

    local window_accent = create('Square', {
        Color = accent,
        Size = {1, -2, 0, 2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = window_inline
    })

    local window_accent_dark = create('Square', {
        Color = {accent[1] - 40, accent[2] - 40, accent[3] - 40},
        Size = {1, 0, 0, 1},
        Position = {0, 0, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = window_accent
    })

    local title_gradient = create('Image', {
        Url = 'https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/images/title_gradient.png',
        Color = {255, 255, 255},
        Size = {1, -2, 0, 20},
        Position = {0, 1, 0, 4},
        Transparency = 1,
        Visible = true,
        Parent = window_inline
    })

    local window_contrast = create('Square', {
        Color = {35, 35, 35},
        Size = {1, -2, 1, -25},
        Position = {0, 1, 0, 24},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = window_inline
    })

    local window_title = create('Text', {
        Color = {255, 255, 255},
        Size = font.size,
        Font = font.index,
        Text = config.name,
        Position = {0, 4, 0, 2},
        Outline = true,
        Visible = true,
        Transparency = 1,
        Parent = title_gradient
    })

    local page_outline = create('Square', {
        Color = {0, 0, 0},
        Size = {1, -14, 1, -28},
        Position = {0, 7, 0, 21},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = window_inline
    })

    local page_inline = create('Square', {
        Color = {20, 20, 20},
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = page_outline
    })

    local page_accent = create('Square', {
        Color = accent,
        Size = {1, -2, 0, 2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = page_inline
    })

    local page_accent_dark = create('Square', {
        Color = {accent[1] - 40, accent[2] - 40, accent[3] - 40},
        Size = {1, 0, 0, 1},
        Position = {0, 0, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = page_accent
    })

    local tab_holder = create('Square', {
        Size = {1, -4, 0, 32},
        Position = {0, 2, 0, 5},
        Thickness = 1,
        Transparency = 0,
        Visible = true,
        Filled = true,
        Parent = page_inline
    })
    window.drawings.tab_holder = tab_holder

    local page_holder = create('Square', {
        Color = {35, 35, 35},
        Size = {1, -4, 1, -39},
        Position = {0, 2, 0, 37},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = page_inline
    })
    window.drawings.page_holder = page_holder

    window.fix_tabs = function()
        local spacing = 2
        
        local pages = window.pages
        local count = #pages
        local holder_width = tab_holder.AbsSize.x

        local total_spacing = (count - 1) * spacing
        local base_width = floor((holder_width - total_spacing) / count)
        local remainder = (holder_width - total_spacing) % count

        local pos_offset = 0
        for index, page in pages do
            local page_drawings = page.drawings
            
            local width = base_width + (index <= remainder and 1 or 0)
            page_drawings.tab_fill.Size = {0, width, 0, 30}
            page_drawings.tab_fill.Position = {0, pos_offset, 0, 0}
            
            page_drawings.tab_text:Refresh()
            page_drawings.tab_gradient:Refresh()

            pos_offset = pos_offset + width + spacing
        end
    end

    library.windows[#library.windows+1] = window
    return setmetatable(window, {__index = library})
end

library.page = function(self, cfg)
    local config = {
        name = cfg.name or 'Page'
    }

    local page = {
        sections = {},
        drawings = {}
    }
    self.pages[#self.pages+1] = page

    local tab_fill = create('Square', {
        Color = {30, 30, 30},
        Size = {0, 100, 0, 30},
        Position = {0, 0, 0, 0},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = self.drawings.tab_holder
    })
    page.drawings.tab_fill = tab_fill

    local tab_gradient = create('Image', {
        Url = 'https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/images/tab_gradient.png',
        Color = {255, 255, 255},
        Size = {1, 0, 0, 32},
        Position = {0, 0, 0, 0},
        Transparency = 1,
        Visible = false,
        Parent = tab_fill
    })
    page.drawings.tab_gradient = tab_gradient

    local tab_text = create('Text', {
        Color = {170, 170, 170}, -- tab disabled color
        Size = font.size,
        Font = font.index,
        Text = config.name,
        Position = {0.5, 0, 0, 8},
        Center = true,
        Outline = true,
        Visible = true,
        Transparency = 1,
        Parent = tab_fill
    })
    page.drawings.tab_text = tab_text

    local actual_page = create('Square', {
        Size = {1, -12, 1, -12},
        Position = {0, 6, 0, 6},
        Thickness = 1,
        Transparency = -1,
        Visible = true,
        Filled = true,
        Parent = self.drawings.page_holder
    })
    page.drawings.actual_page = actual_page

    local left = create('Square', {
        Size = {0.5, -3, 1, 0},
        Position = {0, 0, 0, 0},
        Thickness = 1,
        Transparency = -1,
        Visible = false,
        Filled = true,
        Parent = actual_page
    })
    page.drawings.left = left

    local right = create('Square', {
        Size = {0.5, -3, 1, 0},
        Position = {0.5, 3, 0, 0},
        Thickness = 1,
        Transparency = -1,
        Visible = false,
        Filled = true,
        Parent = actual_page
    })
    page.drawings.right = right

    local count = 0
    page.select = function()
        if count ~= 0 then
            return
        end
        for _, _page in self.pages do
            local this_page = _page == page

            local page_drawings = _page.drawings
            for _, desc in getdescendants(page_drawings.actual_page) do
                if desc.Transparency >= 0 then
                    desc.Transparency = this_page and 1 or 0
                end
                
                desc.Visible = this_page and true or false
            end

            page_drawings.tab_gradient.Visible = this_page and true or false
            page_drawings.tab_text.Color = this_page and {255, 255, 255} or {170, 170, 170}
        end
        count = count + 1
    end

    tab_fill.ClickBegan:Connect(function()
        page.select()
    end)

    if #self.pages == 1 then
        page.select()
    end

    self.fix_tabs()
    return setmetatable(page, {__index = library})
end

library.section = function(self, cfg)
    local config = {
        name = cfg.name or 'Section',
        size = cfg.size or {1, 0, 0.5, -3},
        side = cfg.side or 'Left'
    }

    local section = {
        side = config.side,
        type = 'single',
        drawings = {}
    }

    local section_offset = 0
    for _, _section in self.sections do
        if _section.side == config.side then
            section_offset = section_offset + (_section.drawings.section_outline.AbsSize.y + 6)
        end
    end
    self.sections[#self.sections+1] = section

    local page = self.drawings[string.lower(config.side)] or self.drawings['left']
    local visiblity = page.Visible

    local section_outline = create('Square', {
        Color = {0, 0, 0},
        Size = config.size,
        Position = {0, 0, 0, section_offset},
        Thickness = 1,
        Transparency = 1,
        Visible = visiblity,
        Filled = true,
        Parent = page
    })
    section.drawings.section_outline = section_outline

    local section_inline = create('Square', {
        Color = {20, 20, 20},
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = visiblity,
        Filled = true,
        Parent = section_outline
    })

    local section_accent = create('Square', {
        Color = accent,
        Size = {1, -2, 0, 2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = visiblity,
        Filled = true,
        Parent = section_inline
    })

    local section_accent_dark = create('Square', {
        Color = {accent[1] - 40, accent[2] - 40, accent[3] - 40},
        Size = {1, 0, 0, 1},
        Position = {0, 0, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = visiblity,
        Filled = true,
        Parent = section_accent
    })

    local section_gradient = create('Image', {
        Url = 'https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/images/section_gradient.png',
        Color = {255, 255, 255},
        Size = {1, -2, 0, 14},
        Position = {0, 1, 0, 4},
        Transparency = 1,
        Visible = visiblity,
        Parent = section_inline
    })

    local section_name = create('Text', {
        Color = {255, 255, 255},
        Size = font.size,
        Font = font.index,
        Text = config.name,
        Position = {0, 4, 0, 1},
        Outline = true,
        Visible = visiblity,
        Transparency = 1,
        Parent = section_gradient
    })

    local section_contrast = create('Square', {
        Color = {35, 35, 35},
        Size = {1, -2, 1, -19},
        Position = {0, 1, 0, 18},
        Thickness = 1,
        Transparency = 1,
        Visible = visiblity,
        Filled = true,
        Parent = section_inline
    })

    local actual_section = create('Square', {
        Size = {1, -12, 1, -4},
        Position = {0, 6, 0, 4},
        Thickness = 1,
        Transparency = -1,
        Visible = visiblity,
        Filled = true,
        Parent = section_contrast
    })
    section.drawings.actual_section = actual_section

    return setmetatable(section, {__index = library})
end

library.multi_section = function(self, cfg)
    local config = {
        name = cfg.name or 'Section',
        tabs = cfg.tabs or {'Tab 1', 'Tab 2', 'Tab 3'},
        size = cfg.size or {1, 0, 0.5, -3},
        side = cfg.side or 'Left'
    }

    local multi_section = {
        side = config.side,
        sections = {},
        drawings = {}
    }

    local section_offset = 0
    for _, _section in self.sections do
        if _section.side == string.lower(config.side) then
            section_offset = section_offset + (_section.drawings.section_outline.AbsSize.y + 6)
        end
    end
    self.sections[#self.sections+1] = multi_section

    local section_outline = create('Square', {
        Color = {0, 0, 0},
        Size = config.size,
        Position = {0, 0, 0, section_offset},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = self.drawings[string.lower(config.side)] or self.drawings['left']
    })
    multi_section.drawings.section_outline = section_outline

    local section_inline = create('Square', {
        Color = {20, 20, 20},
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = section_outline
    })

    local section_accent = create('Square', {
        Color = accent,
        Size = {1, -2, 0, 2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = section_inline
    })

    local section_accent_dark = create('Square', {
        Color = {accent[1] - 40, accent[2] - 40, accent[3] - 40},
        Size = {1, 0, 0, 1},
        Position = {0, 0, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = section_accent
    })

    local tab_holder = create('Square', {
        Size = {1, -2, 0, 18},
        Position = {0, 1, 0, 4},
        Thickness = 1,
        Transparency = -1,
        Visible = true,
        Filled = true,
        Parent = section_inline
    })

    local section_contrast = create('Square', {
        Color = {35, 35, 35},
        Size = {1, -2, 1, -24},
        Position = {0, 1, 0, 23},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = section_inline
    })

    multi_section.fix_tabs = function()
        local spacing = 1
        
        local tabs = tab_holder:GetChildren()
        local count = #tabs
        local holder_width = tab_holder.AbsSize.x

        local total_spacing = (count - 1) * spacing
        local base_width = floor((holder_width - total_spacing) / count)
        local remainder = (holder_width - total_spacing) % count

        local pos_offset = 0
        for index, tab in tabs do            
            local width = base_width + (index <= remainder and 1 or 0)
            tab.Size = {0, width, 0, 18}
            tab.Position = {0, pos_offset, 0, 0}
            
            for _, child in tab:GetChildren() do
                child:Refresh()
            end

            pos_offset = pos_offset + width + spacing
        end
    end

    for _, tab in config.tabs do
        local section = {
            type = 'multi',
            drawings = {}
        }

        local tab_fill = create('Square', {
            Color = {30, 30, 30},
            Size = {0, 100, 0, 18},
            Position = {0, 0, 0, 0},
            Thickness = 1,
            Transparency = 1,
            Visible = true,
            Filled = true,
            Parent = tab_holder
        })

        local tab_gradient = create('Image', {
            Url = 'https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/images/multi_tab_gradient.png',
            Color = {255, 255, 255},
            Size = {1, 0, 0, 19},
            Position = {0, 0, 0, 0},
            Transparency = -2,
            Visible = false,
            Parent = tab_fill
        })
        section.drawings.tab_gradient = tab_gradient

        local tab_name = create('Text', {
            Color = {170, 170, 170},
            Size = font.size,
            Font = font.index,
            Text = tab,
            Position = {0.5, 0, 0, 3},
            Center = true,
            Outline = true,
            Visible = true,
            Transparency = 1,
            Parent = tab_fill
        })
        section.drawings.tab_name = tab_name

        local actual_section = create('Square', {
            Size = {1, -12, 1, -6},
            Position = {0, 6, 0, 6},
            Thickness = 1,
            Transparency = -2,
            Visible = false,
            Filled = true,
            Parent = section_contrast
        })
        section.drawings.actual_section = actual_section

        multi_section.fix_tabs()

        section.select = function()
            for _, _section in multi_section.sections do
                local this_section = _section == section
                if this_section then
                    actual_section.Visible = true
                    actual_section.Transparency = -1
                    tab_gradient.Visible = true
                    tab_gradient.Transparency = 1
                    tab_name.Color = {255, 255, 255}

                    for _, desc in getdescendants(actual_section) do
                        desc.Visible = true
                        if desc.Transparency ~= -1 then
                            desc.Transparency = 1
                        end
                    end
                else
                    local section_drawings = _section.drawings
                    section_drawings.actual_section.Visible = false
                    section_drawings.actual_section.Transparency = -2
                    section_drawings.tab_gradient.Visible = false
                    section_drawings.tab_gradient.Transparency = -2
                    section_drawings.tab_name.Color = {170, 170, 170}

                    for _, desc in getdescendants(section_drawings.actual_section) do
                        desc.Visible = false
                        if desc.Transparency ~= -1 then
                            desc.Transparency = -2
                        end
                    end
                end
            end
        end

        tab_fill.ClickBegan:Connect(function()
            section.select()
        end)

        multi_section.sections[#multi_section.sections+1] = setmetatable(section, {__index = library})
        if #multi_section.sections == 1 then
            section.select()
        end
    end

    return table.unpack(multi_section.sections)
end

library.toggle = function(self, cfg)
    local config = {
        name = cfg.name or 'Toggle',
        flag = cfg.flag or random(1, 123456),
        state = cfg.state or false,
        unsafe = cfg.unsafe or false,
        callback = cfg.callback or nil
    }

    local toggle = {
        class = 'toggle',
        state = false,
        drawings = {}
    }

    local toggle_offset = 0
    local actual_section = self.drawings.actual_section
    local visiblity = actual_section.Visible

    local default_transparency = 1
    if self.type == 'multi' then
        default_transparency = visiblity and 1 or -2
    end

    for _, element in actual_section:GetChildren() do
        toggle_offset = toggle_offset + (element.AbsSize.y + 4)
    end

    local toggle_holder = create('Square', {
        Size = {1, 0, 0, 12},
        Position = {0, 0, 0, toggle_offset},
        Thickness = 0.2,
        Transparency = -1,
        Filled = true,
        Visible = visiblity,
        Parent = actual_section
    })

    local toggle_name = create('Text', {
        Color = config.unsafe and {245, 239, 120} or {255, 255, 255},
        Size = font.size,
        Font = font.index,
        Text = config.name,
        Position = {0, 16, 0, 0},
        Outline = true,
        Visible = visiblity,
        Transparency = default_transparency,
        Parent = toggle_holder
    })

    local toggle_shadow = create('Square', {
        Color = {30, 30, 30},
        Size = {0, 12, 0, 12},
        Position = {0, 0, 0, 0},
        Thickness = 1,
        Transparency = default_transparency,
        Filled = true,
        Visible = visiblity,
        Parent = toggle_holder
    })

    local toggle_outline = create('Square', {
        Color = {0, 0, 0},
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = default_transparency,
        Filled = true,
        Visible = visiblity,
        Parent = toggle_shadow
    })

    local toggle_gradient = create('Image', {
        Url = 'https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/images/toggle_gradient.png',
        Color = {255, 255, 255},
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Transparency = default_transparency,
        Visible = visiblity,
        Parent = toggle_outline
    })

    local toggle_fill = create('Square', {
        Color = accent,
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = -1,
        Filled = true,
        Visible = visiblity,
        Parent = toggle_outline
    })

    local toggle_overlay = create('Image', {
        Url = 'https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/images/toggle_overlay.png',
        Color = {255, 255, 255},
        Size = {1, 0, 1, 0},
        Position = {0, 0, 0, 0},
        Transparency = -1,
        Visible = visiblity,
        Parent = toggle_fill
    })

    toggle.set = function(boolean)
        if self.drawings.actual_section.Visible then
            toggle_fill.Transparency = boolean and 1 or -1
            toggle_overlay.Transparency = boolean and 1 or -1
        else
            toggle_fill.Transparency = boolean and 2 or -1
            toggle_overlay.Transparency = boolean and 2 or -1
        end

        toggle.state = boolean
        flags[config.flag] = boolean

        if config.callback then
            config.callback(boolean)
        end
    end

    toggle.set(config.state)

    toggle_holder.ClickBegan:Connect(function()
        toggle.set(not toggle.state)
    end)

    elements[config.flag] = toggle
    return setmetatable(toggle, {__index = library})
end

library.button = function(self, cfg)
    local config = {
        name = cfg.name or 'Button',
        callback = cfg.callback or nil
    }

    local button_offset = 0
    local actual_section = self.drawings.actual_section
    local visiblity = actual_section.Visible

    local default_transparency = 1
    if self.type == 'multi' then
        default_transparency = visiblity and 1 or -2
    end 
    
    for _, element in actual_section:GetChildren() do
        button_offset = button_offset + (element.AbsSize.y + 4)
    end

    local button_holder = create('Square', {
        Size = {1, 0, 0, 22},
        Position = {0, 0, 0, button_offset},
        Thickness = 1,
        Transparency = -1,
        Filled = true,
        Visible = visiblity,
        Parent = actual_section
    })

    local button_shadow = create('Square', {
        Color = {30, 30, 30},
        Size = {1, 0, 1, 0},
        Position = {0, 0, 0, 0},
        Thickness = 1,
        Transparency = default_transparency,
        Filled = true,
        Visible = visiblity,
        Parent = button_holder
    })

    local button_outline = create('Square', {
        Color = {0, 0, 0},
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = default_transparency,
        Filled = true,
        Visible = visiblity,
        Parent = button_shadow
    })

    local button_gradient = create('Image', {
        Url = 'https://raw.githubusercontent.com/minions638/severe-lua/refs/heads/main/images/button_gradient.png',
        Color = {255, 255, 255},
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Transparency = default_transparency,
        Visible = visiblity,
        Parent = button_outline
    })

    local button_name = create('Text', {
        Color = {255, 255, 255},
        Size = font.size,
        Font = font.index,
        Text = config.name,
        Position = {0.5, 0, 0, 3},
        Center = true,
        Outline = true,
        Visible = visiblity,
        Transparency = default_transparency,
        Parent = button_gradient
    })

    button_holder.ClickBegan:Connect(function()
        if config.callback then
            config.callback()
        end
    end)
end

spawn(function()
    local last_press = tick()
    while wait(1 / 30) do
        if (tick() - last_press) > 0.5 then
            local pressed_keys = getpressedkeys()
            for _, key in pressed_keys do
                if key == 'End' then
                    for _, window in library.windows do
                        if window.visible then
                            window.lastpos = window.drawings.window_outline.AbsPos
                            window.drawings.window_outline.Position = {10000, 10000}

                            for _, entry in drawings do
                                entry.meta:Refresh()
                            end

                            window.visible = false
                        else
                            window.drawings.window_outline.Position = {window.lastpos.x, window.lastpos.y}

                            for _, entry in drawings do
                                entry.meta:Refresh()
                            end

                            window.visible = true
                        end
                    end
                    last_press = tick()
                end
            end
        end
    end
end)

return library, library.flags
