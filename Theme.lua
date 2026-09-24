-- Theme.lua (Boss Tactics)
-- Tema local preto e dourado. Nenhuma função ou template global do WoW é alterado.

local BT = BossTactics
local unpack = unpack or table.unpack
local Theme = {}
BT.Theme = Theme

Theme.colors = {
    background = { 0.063, 0.063, 0.063, 1 }, -- #101010
    panel      = { 0.098, 0.098, 0.098, 1 }, -- #191919
    field      = { 0.133, 0.133, 0.133, 1 }, -- #222222
    gold       = { 0.788, 0.643, 0.298, 1 }, -- #C9A44C
    goldHover  = { 0.894, 0.776, 0.459, 1 }, -- #E4C675
    text       = { 0.949, 0.933, 0.898, 1 }, -- #F2EEE5
    muted      = { 0.722, 0.702, 0.655, 1 }, -- #B8B3A7
    disabled   = { 0.38, 0.37, 0.34, 1 },
    pressed    = { 0.16, 0.14, 0.09, 1 },
}

Theme.spacing = {
    xs = 4, sm = 8, md = 12, lg = 16,
    buttonPadX = 12,
    buttonPadY = 5,
    rowGap = 6,
    border = 1,
}

local WHITE = "Interface\\Buttons\\WHITE8X8"

local function SetColor(texture, color, alpha)
    if texture and color then
        texture:SetColorTexture(color[1], color[2], color[3], alpha or color[4] or 1)
    end
end

local function EnsureBackground(frame, layer, subLevel)
    if not frame._btThemeBackground then
        frame._btThemeBackground = frame:CreateTexture(nil, layer or "BACKGROUND", nil, subLevel or -7)
        frame._btThemeBackground:SetTexture(WHITE)
        frame._btThemeBackground:SetAllPoints()
    end
    return frame._btThemeBackground
end

local function EnsureBorders(frame)
    if frame._btThemeBorders then return frame._btThemeBorders end
    local borders = {}
    for i = 1, 4 do
        borders[i] = frame:CreateTexture(nil, "BORDER")
        borders[i]:SetTexture(WHITE)
    end
    borders[1]:SetPoint("TOPLEFT")
    borders[1]:SetPoint("TOPRIGHT")
    borders[1]:SetHeight(1)
    borders[2]:SetPoint("BOTTOMLEFT")
    borders[2]:SetPoint("BOTTOMRIGHT")
    borders[2]:SetHeight(1)
    borders[3]:SetPoint("TOPLEFT")
    borders[3]:SetPoint("BOTTOMLEFT")
    borders[3]:SetWidth(1)
    borders[4]:SetPoint("TOPRIGHT")
    borders[4]:SetPoint("BOTTOMRIGHT")
    borders[4]:SetWidth(1)
    frame._btThemeBorders = borders
    return borders
end

function Theme:SetBorderColor(frame, color, alpha)
    for _, border in ipairs(EnsureBorders(frame)) do SetColor(border, color, alpha) end
end

function Theme:StyleSurface(frame, kind, accent)
    if not frame or frame._btThemeSurfaceKind == kind and frame._btThemeAccent == accent then return end
    frame._btThemeSurfaceKind = kind
    frame._btThemeAccent = accent
    if frame.SetBackdrop then
        frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        local fill = kind == "field" and self.colors.field
            or kind == "window" and self.colors.background or self.colors.panel
        frame:SetBackdropColor(fill[1], fill[2], fill[3], fill[4])
        local border = accent and self.colors.gold or self.colors.muted
        frame:SetBackdropBorderColor(border[1], border[2], border[3], accent and 0.95 or 0.28)
    else
        local fill = kind == "field" and self.colors.field
            or kind == "window" and self.colors.background or self.colors.panel
        SetColor(EnsureBackground(frame), fill)
        self:SetBorderColor(frame, accent and self.colors.gold or self.colors.muted,
            accent and 0.95 or 0.28)
    end
end

local function HideDecoration(region)
    if region and region.SetAlpha then region:SetAlpha(0) end
end

function Theme:StyleWindow(frame)
    if not frame then return end
    self:StyleSurface(frame, "window", true)
    HideDecoration(frame.Bg)
    HideDecoration(frame.TitleBg)
    HideDecoration(frame.PortraitContainer)
    HideDecoration(frame.NineSlice)
    if frame.Inset then
        HideDecoration(frame.Inset.Bg)
        HideDecoration(frame.Inset.NineSlice)
        self:StyleSurface(frame.Inset, "panel", false)
    end
    local title = frame.TitleText or frame.title or frame.titleFS
    if title and title.SetTextColor then
        title:SetTextColor(unpack(self.colors.gold))
    end
end

function Theme:StyleTitle(fontString)
    if fontString and fontString.SetTextColor then
        fontString:SetTextColor(unpack(self.colors.gold))
    end
end

function Theme:StyleSecondaryText(fontString)
    if fontString and fontString.SetTextColor then
        fontString:SetTextColor(unpack(self.colors.muted))
    end
end

function Theme:StyleEditBox(editBox)
    if not editBox or editBox._btThemeEdit then return end
    editBox._btThemeEdit = true
    local parent = editBox:GetParent()
    if parent and parent.GetObjectType and parent:GetObjectType() ~= "ScrollFrame" then
        self:StyleSurface(parent, "field", false)
    end
    SetColor(EnsureBackground(editBox), self.colors.field)
    self:SetBorderColor(editBox, self.colors.muted, 0.25)
    if editBox.SetTextColor then editBox:SetTextColor(unpack(self.colors.text)) end
    if editBox.SetCursorColor then editBox:SetCursorColor(unpack(self.colors.goldHover)) end
    if editBox.SetHighlightColor then editBox:SetHighlightColor(0.45, 0.34, 0.12, 0.9) end
    editBox:HookScript("OnEditFocusGained", function(box)
        Theme:SetBorderColor(box, Theme.colors.gold, 0.95)
    end)
    editBox:HookScript("OnEditFocusLost", function(box)
        Theme:SetBorderColor(box, Theme.colors.muted, 0.25)
    end)
end

local function ButtonFontString(button)
    return button.GetFontString and button:GetFontString() or button.label
end

local function HideButtonArtwork(button)
    -- WoW 12.x não aceita mais nil em Set*Texture. Ocultamos somente as
    -- regiões do próprio botão; o tema preto e dourado passa a ser a única
    -- camada visual sem modificar templates ou recursos globais do cliente.
    for _, getter in ipairs({ "GetNormalTexture", "GetPushedTexture",
        "GetHighlightTexture", "GetDisabledTexture" }) do
        local method = button[getter]
        local texture = method and method(button)
        if texture and texture.SetAlpha then texture:SetAlpha(0) end
    end
    for _, key in ipairs({ "Left", "Middle", "Right" }) do
        local texture = button[key]
        if texture and texture.SetAlpha then texture:SetAlpha(0) end
    end
end

function Theme:FitButton(button, options)
    if not button then return 0, 0 end
    options = options or {}
    local compact = options.compact == true
    local minHeight = options.minHeight or (compact and 22 or 26)
    local fontString = ButtonFontString(button)
    local iconWidth = tonumber(options.iconWidth) or tonumber(button._btIconWidth) or 0
    local width = tonumber(options.minWidth) or (compact and 22 or 48)
    local height = minHeight
    if fontString then
        fontString:SetWordWrap(options.wrap == true)
        if fontString.SetNonSpaceWrap then fontString:SetNonSpaceWrap(options.wrap == true) end
        local naturalWidth = math.ceil(fontString:GetStringWidth() or 0)
        local maxWidth = tonumber(options.maxWidth)
        if maxWidth and options.wrap and naturalWidth + iconWidth + self.spacing.buttonPadX * 2 > maxWidth then
            fontString:SetWidth(math.max(20, maxWidth - iconWidth - self.spacing.buttonPadX * 2))
            width = maxWidth
        else
            width = math.max(width, naturalWidth + iconWidth + self.spacing.buttonPadX * 2)
        end
        height = math.max(minHeight, math.ceil(fontString:GetStringHeight() or 0) + self.spacing.buttonPadY * 2)
    end
    if options.maxWidth and not options.wrap then width = math.min(width, options.maxWidth) end
    button:SetSize(width, height)
    button._btMeasuredWidth, button._btMeasuredHeight = width, height
    return width, height
end

function Theme:StyleButton(button, options)
    if not button then return end
    options = options or {}
    if not button._btThemeButton then
        button._btThemeButton = true
        button._btNormal = button:CreateTexture(nil, "BACKGROUND")
        button._btNormal:SetAllPoints()
        button._btHover = button:CreateTexture(nil, "BACKGROUND", nil, 1)
        button._btHover:SetAllPoints()
        button._btHover:Hide()
        button._btPressed = button:CreateTexture(nil, "BACKGROUND", nil, 2)
        button._btPressed:SetAllPoints()
        button._btPressed:Hide()
        button._btSelected = button:CreateTexture(nil, "BORDER", nil, 2)
        button._btSelected:SetPoint("BOTTOMLEFT", 2, 1)
        button._btSelected:SetPoint("BOTTOMRIGHT", -2, 1)
        button._btSelected:SetHeight(2)
        SetColor(button._btSelected, self.colors.gold)
        button._btSelected:Hide()
        self:SetBorderColor(button, self.colors.muted, 0.3)
        button:HookScript("OnEnter", function(btn)
            if btn:IsEnabled() then btn._btHover:Show() end
        end)
        button:HookScript("OnLeave", function(btn)
            btn._btHover:Hide()
            btn._btPressed:Hide()
        end)
        button:HookScript("OnMouseDown", function(btn)
            if btn:IsEnabled() then btn._btPressed:Show() end
        end)
        button:HookScript("OnMouseUp", function(btn) btn._btPressed:Hide() end)
        button:HookScript("OnEnable", function(btn) Theme:RefreshButtonState(btn) end)
        button:HookScript("OnDisable", function(btn) Theme:RefreshButtonState(btn) end)
    end
    HideButtonArtwork(button)
    button._btPrimary = options.primary == true
    SetColor(button._btNormal, button._btPrimary and self.colors.gold or self.colors.panel,
        button._btPrimary and 0.28 or 1)
    SetColor(button._btHover, self.colors.goldHover, button._btPrimary and 0.28 or 0.16)
    SetColor(button._btPressed, self.colors.pressed, 1)
    local fs = ButtonFontString(button)
    if fs and fs.SetTextColor then fs:SetTextColor(unpack(self.colors.text)) end
    self:RefreshButtonState(button)
    if options.fit ~= false and fs then self:FitButton(button, options) end
end

function Theme:RefreshButtonState(button)
    if not button or not button._btThemeButton then return end
    HideButtonArtwork(button)
    local enabled = button:IsEnabled()
    local fs = ButtonFontString(button)
    if fs and fs.SetTextColor then
        fs:SetTextColor(unpack(enabled and self.colors.text or self.colors.disabled))
    end
    button._btNormal:SetDesaturated(not enabled)
    if not enabled then
        button._btHover:Hide()
        button._btPressed:Hide()
        self:SetBorderColor(button, self.colors.disabled, 0.2)
    else
        self:SetBorderColor(button,
            button._btThemeSelected and self.colors.gold or self.colors.muted,
            button._btThemeSelected and 0.95 or 0.3)
    end
end

function Theme:SetSelected(button, selected)
    if not button then return end
    if not button._btThemeButton then self:StyleButton(button, { fit = false }) end
    button._btThemeSelected = selected and true or false
    button._btSelected:SetShown(button._btThemeSelected)
    self:RefreshButtonState(button)
end

function Theme:LayoutButtonBar(bar, buttons, availableWidth, options)
    if not bar then return 0 end
    options = options or {}
    local gap = options.gap or self.spacing.sm
    local rowGap = options.rowGap or self.spacing.rowGap
    local x, y, rowHeight, rows = 0, 0, 0, 1
    local maxWidth = math.max(1, tonumber(availableWidth) or bar:GetWidth() or 1)
    for _, button in ipairs(buttons or {}) do
        if button and button:IsShown() then
            local width, height = self:FitButton(button, options.buttonOptions)
            if x > 0 and x + width > maxWidth then
                x = 0
                y = y + rowHeight + rowGap
                rowHeight = 0
                rows = rows + 1
            end
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", bar, "TOPLEFT", x, -y)
            x = x + width + gap
            rowHeight = math.max(rowHeight, height)
        end
    end
    local totalHeight = y + rowHeight
    bar:SetHeight(math.max(options.minHeight or 0, totalHeight))
    return totalHeight, rows
end

function Theme:StyleAddonTree(root)
    if not root then return end
    local function Visit(frame)
        if not frame then return end
        local objectType = frame.GetObjectType and frame:GetObjectType()
        if objectType == "Button" or objectType == "CheckButton" then
            if ButtonFontString(frame) then Theme:StyleButton(frame, { compact = frame:GetHeight() <= 22 }) end
        elseif objectType == "EditBox" then
            Theme:StyleEditBox(frame)
        elseif frame.GetBackdrop and frame:GetBackdrop() then
            Theme:StyleSurface(frame, "panel", false)
        end
        if frame.GetChildren then
            for _, child in ipairs({ frame:GetChildren() }) do Visit(child) end
        end
    end
    Visit(root)
end
