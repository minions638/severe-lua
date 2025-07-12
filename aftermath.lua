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

    local index = #drawings + 1
    local zindex = properties.zIndex or index
    local instance = Drawing.new(class)

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
            instance.Size = floored
        else
            local floored = {
                floor(size_udim2.offset[1]),
                floor(size_udim2.offset[2])
            }
            instance.Size = floored
        end
    end

    local function update_position()
        if parent ~= nil then
            local floored = {
                floor(parent.AbsPos.x + (parent.AbsSize.x * position_udim2.scale[1] + position_udim2.offset[1])),
                floor(parent.AbsPos.y + (parent.AbsSize.y * position_udim2.scale[2] + position_udim2.offset[2]))
            }
            instance.Position = floored
        else
            local floored = {
                floor(position_udim2.offset[1]),
                floor(position_udim2.offset[2])
            }
            instance.Position = floored
        end
    end

    for property, value in properties do
        if property == 'Size' then
            if class == 'Text' then
                instance.Size = value
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
            instance[property] = value
        end
    end

    local callbacks = {
        click_began = {},
        click_ended = {}
    }

    local meta = setmetatable({}, {
        __index = function(self, key)
            if key == 'AbsSize' then
                return instance.Size
            elseif key == 'AbsPos' then
                return instance.Position
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
                    instance:Remove()
                    drawings[index] = nil
                end
            else
                return instance[key]
            end
        end,

        __newindex = function(self, key, value)
            if key == 'Size' then
                if class == 'Text' then
                    instance.Size = value
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
                instance[key] = value
            end
        end
    })

    if parent then
        local _children = parent:GetChildren()
        _children[#_children+1] = meta
    end

    drawings[index] = {
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

            if class ~= 'Text' and instance.Visible and meta.CountConnections > 0 then
                local size = instance.Size
                local position = instance.Position

                if size and position and mouse_position then
                    local inside = mouse_position.x >= position.x and mouse_position.x <= position.x + size.x and mouse_position.y >= position.y and mouse_position.y <= position.y + size.y
                    if not inside then
                        continue
                    end

                    local zindex = instance.zIndex
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
    
    page.select = function()
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

local window = library:window({name = 'Aftermath (End key toggles menu)', size = {350, 300}}); do
    local settings = window:page({name = 'Options'}); do
        local zombies = settings:section({side = 'Left', size = {1, 0, 0, 75}, name = 'Zombies'}); do
            zombies:toggle({name = 'Enabled', flag = 'zombies'})
            zombies:toggle({name = 'Only Special', flag = 'zombies_special'})
            zombies:toggle({name = 'Whitelisted', flag = 'zombies_whitelisted'})
        end

        local items = settings:section({side = 'Left', size = {1, 0, 0, 91}, name = 'Items'}); do
            items:toggle({name = 'Ammo', flag = 'items_ammo'})
            items:toggle({name = 'Weapons', flag = 'items_weapons'})
            items:toggle({name = 'Medical', flag = 'items_medical'})
            items:toggle({name = 'Repair Kits', flag = 'items_repair_kits'})
        end

        local misc = settings:section({side = 'Right', size = {1, 0, 1, 0}, name = 'Misc.'}); do
            misc:toggle({name = 'Vehicles', flag = 'vehicles'})

            misc:toggle({name = 'Player Bags', flag = 'player_bags'})
            misc:toggle({name = 'Zombie Bags', flag = 'zombie_bags'})

            misc:toggle({name = 'Weapon Viewer', flag = 'weapon_viewer'})
        end
    end

    local configs = window:page({name = 'Other'}); do
        local configurations = configs:section({side = 'Left', name = 'Configs', size = {2, 6, 0, 79}}); do
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
    {name = 'MRAD', path = {'Misc', 'Meshes/Rifle_sbg_precision_rifle_01_buttstock.001'}},
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
    {name = 'T13 Crossbow', path = {'CrossbowExport'}},
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

    ['rbxassetid://8396080506'] = {'Antibiotics', 'medical'},
    ['rbxassetid://10335143460'] = {'Bandage', 'medical'},
    ['rbxassetid://1307827852'] = {'Healing Salve', 'medical'},
    ['rbxassetid://11614286909'] = {'Dressed Bandage', 'medical'},
    ['rbxassetid://6684852280'] = {'Medkit', 'medical'},
    ['rbxassetid://8838686703'] = {'Large Medkit', 'medical'},
    ['rbxassetid://8838678182'] = {'Leg Splint', 'medical'},
    ['rbxassetid://74587642250157'] = {'Sam Splint', 'medical'},
    ['rbxassetid://14245480179'] = {'Tourniquet', 'medical'},

    ['rbxassetid://10058182223'] = {'Weapon Repair Kit', 'repair_kit'},

    ['rbxassetid://8838686715'] = {'Rem .223', 'ammo'},
    ['rbxassetid://16828714196'] = {'.22 LR', 'ammo'},
    ['rbxassetid://7951764278'] = {'.308 Win', 'ammo'},
    ['rbxassetid://6068549937'] = {'.44 Magnum', 'ammo'},
    ['rbxassetid://6068551481'] = {'9MM Pa.', 'ammo'},
    ['rbxassetid://6068551083'] = {'.45 ACP', 'ammo'},
    ['rbxassetid://6068551303'] = {'12 Gauge', 'ammo'},
    ['rbxassetid://8905916965'] = {'.50 BMG', 'ammo'},
    ['rbxassetid://6068550744'] = {'7.62 Soviet', 'ammo'}
}

local viewer = {}; do
    viewer.player = nil

    local last_pos = {6, 6}
    viewer.main = create('Square', {
        Color = {0, 0, 0},
        Size = {100, 50},
        Position = {10000, 10000},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true
    })

    local dragging = false
    local drag_pos = nil

    do -- window dragging
        viewer.main.ClickBegan:Connect(function()
            dragging = true
            drag_pos = getmouseposition()
        end)

        viewer.main.ClickEnded:Connect(function()
            dragging = false
        end)

        spawn(function()
            while wait(1 / 120) do
                if dragging then
                    local mousepos = getmouseposition()
                    local diff = {x = mousepos.x - drag_pos.x, y = mousepos.y - drag_pos.y}
                    drag_pos = mousepos

                    last_pos = {viewer.main.AbsPos.x + diff.x, viewer.main.AbsPos.y + diff.y}
                    viewer.main.Position = {viewer.main.AbsPos.x + diff.x, viewer.main.AbsPos.y + diff.y}

                    for _, entry in library.drawings do
                        entry.meta:Refresh()
                    end
                end
            end
        end)
    end

    local inline = create('Square', {
        Color = {20, 20, 20},
        Size = {1, -2, 1, -2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = viewer.main
    })

    local window_accent = create('Square', {
        Color = library.accent,
        Size = {1, -2, 0, 2},
        Position = {0, 1, 0, 1},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = inline
    })

    local window_accent_dark = create('Square', {
        Color = {library.accent[1] - 40, library.accent[2] - 40, library.accent[3] - 40},
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
        Parent = inline
    })

    local window_contrast = create('Square', {
        Color = {35, 35, 35},
        Size = {1, -2, 1, -25},
        Position = {0, 1, 0, 24},
        Thickness = 1,
        Transparency = 1,
        Visible = true,
        Filled = true,
        Parent = inline
    })

    local window_title = create('Text', {
        Color = {255, 255, 255},
        Size = library.font.size,
        Font = library.font.index,
        Text = 'Placeholder',
        Position = {0, 4, 0, 2},
        Outline = true,
        Visible = true,
        Transparency = 1,
        Parent = title_gradient
    })

    local past = {}
    viewer.set = function(name, active, weapons)
        if #weapons > 0 then
            for _, v in past do
                v:Remove()
            end
            past = {}

            viewer.player = name
            window_title.Text = name
            viewer.main.Position = last_pos

            local size = math.floor(window_title.TextBounds.x)

            local offset = 0
            if active then
                offset = offset + 14
                local text = create('Text', {
                    Color = {255, 255, 255},
                    Size = library.font.size,
                    Font = library.font.index,
                    Text = 'Active: ' .. active,
                    Position = {0, 4, 0, 2 + offset},
                    Outline = true,
                    Visible = true,
                    Transparency = 1,
                    Parent = title_gradient
                })

                local floor_bounds = math.floor(text.TextBounds.x)
                if floor_bounds > size then
                    size = floor_bounds
                end

                past[#past+1] = text
            end

            for _, weapon in weapons do
                offset = offset + 14
                local text = create('Text', {
                    Color = {255, 255, 255},
                    Size = library.font.size,
                    Font = library.font.index,
                    Text = 'Inactive: ' .. weapon,
                    Position = {0, 4, 0, 2 + offset},
                    Outline = true,
                    Visible = true,
                    Transparency = 1,
                    Parent = title_gradient
                })

                local floor_bounds = math.floor(text.TextBounds.x)
                if floor_bounds > size then
                    size = floor_bounds
                end

                past[#past+1] = text
            end

            viewer.main.Size = {size + 14, active and 32 + (14 * #weapons) + 7 or 18 + (14 * #weapons) + 7}

            for _, drawing in library.drawings do
                drawing.meta:Refresh()
            end
        else
            dragging = false
            viewer.main.Position = {10000, 10000}
            viewer.player = nil

            for _, v in past do
                v:Remove()
            end
            past = {}

            for _, drawing in library.drawings do
                drawing.meta:Refresh()
            end
        end
    end
end

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

local function get_weapons(character)
    local active, weapons = nil, {}

    local solve = function(model)
        for _, weapon in paths do
            local path = weapon.path
            local depth = model

            for _, child in path do
                local found = findfirstchild(depth, child)
                if found then
                    depth = found
                else
                    break
                end
            end

            if getname(depth) == path[#path] then
                return weapon.name
            end
        end
    end

    for _, child in getchildren(character) do
        if getname(child) == 'WorldModel' then
            local name = solve(child)
            if name then
                active = name
            end
        elseif getname(child) == 'WorldModelInactive' then
            local name = solve(child)
            if name then
                weapons[#weapons+1] = name
            end
        end
    end

    return active, weapons
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
        local main = findfirstchild(drop, 'Main') or findfirstchild(drop, 'main') or findfirstchild(drop, 'bondage')
        if main and getclassname(main) == 'MeshPart' then
            local meshid = getmeshid(main)
            local found = meshes[meshid]

            if found then
                local class = found[2]
                if class == 'medical' then
                    if flags['items_medical'] then
                        cache.drops[drop_string] = {
                            drop = drop,
                            class = 'medical'
                        }
                        add_item_data(drop_string, main, found[1])
                    end
                elseif class == 'ammo' then
                    if flags['items_ammo'] then
                        cache.drops[drop_string] = {
                            drop = drop,
                            class = 'ammo'
                        }
                        add_item_data(drop_string, main, found[1])
                    end
                elseif class == 'repair_kit' then
                    if flags['items_repair_kits'] then
                        cache.drops[drop_string] = {
                            drop = drop,
                            class = 'repair_kit'
                        }
                        add_item_data(drop_string, main, found[1])
                    end
                end

                return
            end
        end

        if flags['items_weapons'] then
            local part = findfirstchildofclass(drop, 'Part') or findfirstchildofclass(drop, 'MeshPart')
            if part then
                for _, weapon in paths do
                    local path = weapon.path
                    local depth = drop

                    for _, _child in path do
                        local found = findfirstchild(depth, _child)
                        if found then
                            depth = found
                        else
                            break
                        end
                    end

                    if getname(depth) == path[#path] then
                        cache.drops[drop_string] = {
                            drop = drop
                        }
                        add_item_data(drop_string, part, weapon.name)

                        return
                    end
                end

                cache.drops[drop_string] = {
                    fake = true,
                    drop = drop
                }
            elseif not main then
                cache.drops[drop_string] = {
                    fake = true,
                    drop = drop
                }
            end
        end
    else
        cache.drops[drop_string] = {
            fake = true,
            drop = drop
        }
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
            data.parts = parts
            data.name = name

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

        if flags['weapon_viewer'] then
            local closest, dist = nil, 1250
            local mouse_pos = getmouseposition()

            for _, player in cache.players do
                local head = player.parts.head
                local position = getposition(head)
                local screenpoint = worldtoscreenpoint(position)

                local distance = get_magnitude(mouse_pos, screenpoint)
                if distance < dist then
                    dist = distance
                    closest = player
                end
            end

            if closest then
                if closest.name ~= viewer.player then
                    local active, weapons = get_weapons(closest.character)
                    viewer.set(closest.name, active, weapons)
                end
            else
                if viewer.player then
                    viewer.set('', '', {})
                end
            end
        else
            if viewer.player then
                viewer.set('', '', {})
            end
        end

        wait(0.1)
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
                    continue
                end

                local class = drop.class
                if class then
                    if class == 'medical' then
                         if not flags['items_medical'] then
                            cache.drops[index] = nil
                            remove_model_data(index)
                        end
                    elseif class == 'ammo' then
                        if not flags['items_ammo'] then
                            cache.drops[index] = nil
                            remove_model_data(index)
                        end
                    elseif class == 'repair_kit' then
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
