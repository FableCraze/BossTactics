-- Settings.lua  (Boss Tactics)
-- Options UI. Primary entry: own standalone WoW-native window
-- (ButtonFrameTemplate — Adventure Guide look) via /bosstactics options.
-- The Blizzard Settings canvas category stays registered as a secondary
-- entry point and reuses the same content build.
-- Native widgets only: SettingsCheckboxTemplate (feature-checked, atlas
-- fallback), MinimalSliderWithSteppersTemplate (feature-checked, plain
-- Slider fallback), UIPanelButtonTemplate, native ColorPickerFrame.
-- No OptionsSliderTemplate, no UICheckButtonTemplate.

local BT = BossTactics
local C = BT.Components
local Theme = BT.Theme

local SP = {}
BT.SettingsPanel = SP

SP._refreshers = {}   -- [contentParent] = { fn, fn, ... } — re-sync widget states

-- Compact spacing keeps the two-column layout usable on shorter screens.
local WIDGET_GAP  = 9
local SECTION_GAP = 15
local COLUMN_GAP  = 28
local CURSEFORGE_URL = "https://www.curseforge.com/wow/addons/boss-tactics"

local MENU_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function ShowCurseForgeLink()
    local dialog = SP.curseForgeDialog
    if not dialog then
        dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        SP.curseForgeDialog = dialog
        dialog:SetSize(560, 142)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetBackdrop(MENU_BACKDROP)
        dialog:SetBackdropColor(0.03, 0.03, 0.04, 0.98)
        dialog:SetBackdropBorderColor(0.72, 0.58, 0.20, 1)
        dialog:SetClampedToScreen(true)
        dialog:EnableMouse(true)

        local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 18, -18)
        dialog._title = title

        local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", 2, 2)

        local hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
        dialog._hint = hint

        local edit = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
        edit:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 4, -12)
        edit:SetPoint("RIGHT", dialog, "RIGHT", -22, 0)
        edit:SetHeight(28)
        edit:SetAutoFocus(false)
        edit:SetFontObject(GameFontHighlight)
        edit:SetTextInsets(8, 8, 0, 0)
        edit:SetScript("OnEscapePressed", function() dialog:Hide() end)
        edit:SetScript("OnEnterPressed", function(box) box:HighlightText() end)
        dialog._edit = edit
        if Theme then
            Theme:StyleWindow(dialog)
            Theme:StyleTitle(title)
            Theme:StyleAddonTree(dialog)
        end
    end

    dialog._title:SetText(BT:L("CURSEFORGE_LINK_TITLE"))
    dialog._hint:SetText(BT:L("CURSEFORGE_LINK_HINT"))
    dialog._edit:SetText(CURSEFORGE_URL)
    dialog:Show()
    dialog:Raise()
    dialog._edit:SetFocus()
    dialog._edit:HighlightText()
end

-- ─── Widget factories (native templates with graceful fallbacks) ────────────

local function TemplateExists(name)
    return C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(name) ~= nil
end

--- Gold section header (GameFontNormalLarge).
local function CreateSectionHeader(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    fs:SetTextColor(1, 0.82, 0.18, 1)
    fs:SetText(text)
    return fs
end

--- Clean atlas-based checkbox. We intentionally avoid
--- SettingsCheckboxTemplate: its hover artwork can expand across standalone
--- addon windows under some UI skins. Hit area stays enlarged to 32x32.
local function CreateCheckbox(parent, refreshers, labelText, getter, setter, rowWidth)
    local check = CreateFrame("CheckButton", nil, parent)
    check:SetSize(rowWidth or 420, 24)
    check:SetHitRectInsets(-4, -4, -4, -4)   -- 32x32 click zone
    local box = check:CreateTexture(nil, "ARTWORK")
    box:SetPoint("LEFT", check, "LEFT", 0, 0)
    box:SetSize(24, 24)
    box:SetAtlas("checkbox-minimal")
    local mark = check:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("CENTER", box, "CENTER")
    mark:SetSize(16, 16)
    mark:SetAtlas("checkmark-minimal")
    check:SetCheckedTexture(mark)

    local label = check:CreateFontString(nil, "OVERLAY")
    label:SetFontObject(GameFontHighlight or GameFontNormal)
    label:SetTextColor(1, 1, 1, 1)
    label:SetPoint("LEFT", check, "LEFT", 32, 0)
    label:SetPoint("RIGHT", check, "RIGHT", -4, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetText(labelText)
    check._label = label

    check:SetChecked(getter() and true or false)
    check:SetScript("OnClick", function(btn)
        setter(btn:GetChecked() and true or false)
    end)

    refreshers[#refreshers + 1] = function()
        check:SetChecked(getter() and true or false)
    end
    return check
end

--- Slider: MinimalSliderWithSteppersTemplate when available, else a plain
--- Slider widget with atlas track/thumb. fmt formats the value label.
local function CreateNativeSlider(parent, labelText, minV, maxV, step, getter, setter, fmt, rowWidth)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(rowWidth or 420, 43)

    local label = holder:CreateFontString(nil, "OVERLAY")
    C.ApplyLabelFont(label)
    label:SetPoint("TOPLEFT", 0, 0)
    label:SetText(labelText)

    local valueText = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("TOPRIGHT", 0, 0)

    fmt = fmt or function(v)
        return string.format("%d%%", math.floor(v * 100 + 0.5))
    end
    valueText:SetText(fmt(getter()))

    local steps = math.floor((maxV - minV) / step + 0.5)
    local made = false

    if TemplateExists("MinimalSliderWithSteppersTemplate") then
        local okCreate, slider = pcall(CreateFrame, "Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
        if okCreate and slider then
            local okInit = pcall(function()
                slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
                slider:SetWidth(math.max(240, holder:GetWidth() - 60))
                slider:Init(getter(), minV, maxV, steps, {})
                local ev = (slider.Event and slider.Event.OnValueChanged) or "OnValueChanged"
                slider:RegisterCallback(ev, function(_, value)
                    setter(value)
                    valueText:SetText(fmt(value))
                end, holder)
            end)
            if okInit then
                holder._slider = slider
                made = true
            else
                slider:Hide()   -- half-initialized template — fall back below
            end
        end
    end

    if not made then
        local slider = CreateFrame("Slider", nil, holder)
        slider:SetOrientation("HORIZONTAL")
        slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -10)
        slider:SetSize(math.max(240, holder:GetWidth() - 60), 16)
        slider:SetMinMaxValues(minV, maxV)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)

        local track = slider:CreateTexture(nil, "BACKGROUND")
        track:SetPoint("LEFT", 0, 0)
        track:SetPoint("RIGHT", 0, 0)
        track:SetHeight(6)
        track:SetAtlas("Minimal_SliderBar_Middle", false)

        local thumb = slider:CreateTexture(nil, "ARTWORK")
        thumb:SetSize(20, 19)
        thumb:SetAtlas("Minimal_SliderBar_Button", false)
        slider:SetThumbTexture(thumb)

        slider:SetValue(getter())
        slider:SetScript("OnValueChanged", function(_, value)
            setter(value)
            valueText:SetText(fmt(value))
        end)
        holder._slider = slider
    end

    return holder
end

-- ─── Backdrop color picker (native ColorPickerFrame, with opacity) ──────────

local function OpenBackdropColorPicker(applyFunc, currentColor)
    local db = BT.db
    if not db then return end
    local c = currentColor or db.backdropColor or { r = 0, g = 0, b = 0, a = 0.55 }
    local prev = { r = c.r or 0, g = c.g or 0, b = c.b or 0, a = c.a or 0.55 }

    local function fromPicker()
        local r, g, b
        if ColorPickerFrame.GetColorRGB then
            r, g, b = ColorPickerFrame:GetColorRGB()
        end
        if not r then
            r, g, b = prev.r, prev.g, prev.b
        end
        local a
        if ColorPickerFrame.GetColorAlpha then
            a = ColorPickerFrame:GetColorAlpha()
        elseif OpacitySliderFrame and OpacitySliderFrame.GetValue then
            a = 1 - (OpacitySliderFrame:GetValue() or 0)   -- legacy inverted slider
        end
        applyFunc(r, g, b, a or prev.a)
    end

    local info = {
        r = prev.r, g = prev.g, b = prev.b,
        hasOpacity = true,
        opacity = prev.a,
        swatchFunc = fromPicker,
        opacityFunc = fromPicker,
        cancelFunc = function()
            applyFunc(prev.r, prev.g, prev.b, prev.a)
        end,
        previousValues = { r = prev.r, g = prev.g, b = prev.b, opacity = prev.a },
    }

    if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
        -- modern API (10.2+); pcall-guarded so a signature change falls back
        local ok = pcall(function()
            ColorPickerFrame:SetupColorPickerAndShow(info)
        end)
        if ok then
            if ColorPickerFrame.Raise then ColorPickerFrame:Raise() end
            return
        end
    end
    if ColorPickerFrame then
        -- legacy pattern
        ColorPickerFrame.func = info.swatchFunc
        ColorPickerFrame.opacityFunc = info.opacityFunc
        ColorPickerFrame.cancelFunc = info.cancelFunc
        ColorPickerFrame.hasOpacity = true
        ColorPickerFrame.opacity = 1 - prev.a
        ColorPickerFrame.previousValues = info.previousValues
        if ColorPickerFrame.SetColorRGB then
            ColorPickerFrame:SetColorRGB(prev.r, prev.g, prev.b)
        end
        ColorPickerFrame:Show()
        if ColorPickerFrame.Raise then ColorPickerFrame:Raise() end
    end
end

--- Color swatch row: label + clickable square in the current backdrop color.
--- Disabled (greyed) while the backdrop itself is off.
local function CreateColorSwatchRow(parent, refreshers, rowWidth, modeKey, colorKey, applyLook)
    local db = BT.db
    modeKey = modeKey or "backdropMode"
    colorKey = colorKey or "backdropColor"
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(rowWidth or 420, 28)

    local label = holder:CreateFontString(nil, "OVERLAY")
    C.ApplyLabelFont(label)
    label:SetPoint("LEFT", 36, 0)
    label:SetText(BT:L("OPT_BACKDROP_COLOR"))

    -- Native color-swatch look: gold ring texture + inner color square, so a
    -- black backdrop color doesn't read as an empty checkbox on the dark UI
    local btn = CreateFrame("Button", nil, holder)
    btn:SetSize(26, 26)
    btn:SetPoint("LEFT", 0, 0)
    btn:SetHitRectInsets(-2, -2, -2, -2)
    local ring = btn:CreateTexture(nil, "OVERLAY")
    ring:SetAllPoints()
    ring:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    local inner = btn:CreateTexture(nil, "ARTWORK")
    inner:SetPoint("TOPLEFT", 3, -3)
    inner:SetPoint("BOTTOMRIGHT", -3, 3)
    holder._inner = inner

    local function RefreshSwatch()
        local on = db[modeKey] and true or false
        local c = db[colorKey] or { r = 0, g = 0, b = 0 }
        if on then
            inner:SetColorTexture(c.r or 0, c.g or 0, c.b or 0, 1)
            ring:SetVertexColor(1, 1, 1, 1)
            label:SetAlpha(1)
        else
            inner:SetColorTexture(0.35, 0.35, 0.35, 1)
            ring:SetVertexColor(0.5, 0.5, 0.5, 1)
            label:SetAlpha(0.5)
        end
        btn:SetEnabled(on)
    end

    btn:SetScript("OnClick", function()
        OpenBackdropColorPicker(function(r, g, b, a)
            db[colorKey] = { r = r, g = g, b = b, a = a }
            RefreshSwatch()
            if applyLook then applyLook() end
        end, db[colorKey])
    end)

    RefreshSwatch()
    refreshers[#refreshers + 1] = RefreshSwatch
    holder.RefreshSwatch = RefreshSwatch
    return holder
end

-- ─── Live preview support ───────────────────────────────────────────────────

--- Visual option changed while nothing is on screen: light up test mode so
--- the user actually sees what they're changing.
function SP:EnsurePreview()
    local MP = BT.MiniPanel
    if not MP:IsShown() and not MP.testMode then
        MP:EnterTestMode()
    end
end

--- Re-sync widget states (checkboxes, swatch, role button) on every shown
--- content parent. Called on window/canvas OnShow and by MiniPanel on
--- test-mode toggles.
function SP:RefreshAll()
    for parent, list in pairs(self._refreshers) do
        if parent:IsVisible() then
            for _, fn in ipairs(list) do fn() end
        end
    end
end

-- ─── Shared content build (used by both the window and the canvas) ──────────

function SP:BuildContent(parent)
    local db = BT.db
    if not db then return end
    local MP = BT.MiniPanel

    local refreshers = {}
    self._refreshers[parent] = refreshers

    local availableWidth = math.max(680, math.floor((parent:GetWidth() or 0) + 0.5))
    local panelWidth = math.floor((availableWidth - COLUMN_GAP) / 2)
    local panelPadding = 14
    local columnWidth = panelWidth - panelPadding * 2
    local rightX = panelWidth + COLUMN_GAP
    local generalLeftY, generalRightY = -48, -48
    local miniY, trashY = -48, -48
    local pageWidgets = { GENERAL = {}, APPEARANCE = {} }

    -- The main ButtonFrame already supplies the window border. These content
    -- panels only need a quiet background; another rectangular edge made the
    -- options window look double-framed.
    local panelBackdrop = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
    }
    local generalPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    generalPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    generalPanel:SetWidth(availableWidth)
    generalPanel:SetBackdrop(panelBackdrop)
    generalPanel:SetBackdropColor(0.008, 0.008, 0.012, 0.62)

    local miniPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    miniPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    miniPanel:SetWidth(panelWidth)
    miniPanel:SetBackdrop(panelBackdrop)
    miniPanel:SetBackdropColor(0.008, 0.008, 0.012, 0.62)

    local trashPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    trashPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", rightX, 0)
    trashPanel:SetWidth(panelWidth)
    trashPanel:SetBackdrop(panelBackdrop)
    trashPanel:SetBackdropColor(0.008, 0.008, 0.012, 0.62)

    local generalTitle = generalPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    generalTitle:SetPoint("TOPLEFT", panelPadding, -14)
    generalTitle:SetText(BT:L("OPTIONS_PANEL_GENERAL"))
    generalTitle:SetTextColor(1, 0.82, 0.18, 1)
    local miniTitle = miniPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    miniTitle:SetPoint("TOPLEFT", panelPadding, -14)
    miniTitle:SetText(BT:L("APPEARANCE_MINI_PANEL"))
    miniTitle:SetTextColor(1, 0.82, 0.18, 1)
    local trashTitle = trashPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    trashTitle:SetPoint("TOPLEFT", panelPadding, -14)
    trashTitle:SetText(BT:L("APPEARANCE_TRASH_PANEL"))
    trashTitle:SetTextColor(1, 0.82, 0.18, 1)

    pageWidgets.GENERAL[#pageWidgets.GENERAL + 1] = generalPanel
    pageWidgets.APPEARANCE[#pageWidgets.APPEARANCE + 1] = miniPanel
    pageWidgets.APPEARANCE[#pageWidgets.APPEARANCE + 1] = trashPanel

    local function Track(page, widget)
        pageWidgets[page][#pageWidgets[page] + 1] = widget
        widget:SetWidth(columnWidth)
    end
    local function placeGeneralLeft(widget, gap)
        -- Keep regions above their panel backdrop. Previously FontStrings were
        -- children of the scroll content while this child frame sat above
        -- them, which visibly dimmed section titles and Credits.
        widget:SetParent(generalPanel)
        widget:SetPoint("TOPLEFT", generalPanel, "TOPLEFT", panelPadding, generalLeftY)
        generalLeftY = generalLeftY - math.floor(widget:GetHeight() + (gap or WIDGET_GAP))
        Track("GENERAL", widget)
    end
    local function placeGeneralRight(widget, gap)
        widget:SetParent(generalPanel)
        widget:SetPoint("TOPLEFT", generalPanel, "TOPLEFT", rightX + panelPadding, generalRightY)
        generalRightY = generalRightY - math.floor(widget:GetHeight() + (gap or WIDGET_GAP))
        Track("GENERAL", widget)
    end
    local function placeMini(widget, gap)
        widget:SetParent(miniPanel)
        widget:SetPoint("TOPLEFT", miniPanel, "TOPLEFT", panelPadding, miniY)
        miniY = miniY - math.floor(widget:GetHeight() + (gap or WIDGET_GAP))
        Track("APPEARANCE", widget)
    end
    local function placeTrash(widget, gap)
        widget:SetParent(trashPanel)
        widget:SetPoint("TOPLEFT", trashPanel, "TOPLEFT", panelPadding, trashY)
        trashY = trashY - math.floor(widget:GetHeight() + (gap or WIDGET_GAP))
        Track("APPEARANCE", widget)
    end

    -- ══ LEFT: panel appearance ══
    placeMini(CreateSectionHeader(parent, BT:L("SEC_PANEL")), 8)

    local swatchRow   -- forward ref: backdrop checkbox refreshes the swatch
    placeMini(CreateCheckbox(parent, refreshers, BT:L("OPT_BACKDROP"),
        function() return db.backdropMode end,
        function(v)
            db.backdropMode = v
            if swatchRow then swatchRow.RefreshSwatch() end
            SP:EnsurePreview()
            MP:ApplyLook()
        end, columnWidth))

    swatchRow = CreateColorSwatchRow(parent, refreshers, columnWidth,
        "backdropMode", "backdropColor", function()
            SP:EnsurePreview()
            BT.MiniPanel:ApplyLook()
        end)
    placeMini(swatchRow)

    -- Backdrop opacity: the backdrop's own alpha (separate from panel
    -- opacity, which fades the whole panel including text)
    placeMini(CreateNativeSlider(parent, BT:L("SLIDER_BG_ALPHA"), 0.1, 1.0, 0.05,
        function() return (db.backdropColor and db.backdropColor.a) or 1.0 end,
        function(v)
            db.backdropColor = db.backdropColor or { r = 0, g = 0, b = 0 }
            db.backdropColor.a = v
            SP:EnsurePreview()
            MP:ApplyLook()
        end, nil, columnWidth))

    placeMini(CreateNativeSlider(parent, BT:L("SLIDER_WIDTH"), 240, 440, 10,
        function() return db.panelWidth or 270 end,
        function(v)
            db.panelWidth = math.floor(v + 0.5)
            SP:EnsurePreview()
            MP:ApplyWidth()
        end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end,
        columnWidth))

    placeMini(CreateNativeSlider(parent, BT:L("SLIDER_DETAILED_WIDTH"), 360, 620, 10,
        function() return db.detailedPanelWidth or 420 end,
        function(v)
            db.detailedPanelWidth = math.floor(v + 0.5)
            SP:EnsurePreview()
            MP:ApplyWidth()
        end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end,
        columnWidth))

    placeMini(CreateNativeSlider(parent, BT:L("SLIDER_SCALE"), 0.6, 1.6, 0.05,
        function() return db.scale or 1.0 end,
        function(v)
            db.scale = v
            SP:EnsurePreview()
            MP:ApplyLook()
        end, nil, columnWidth))

    placeMini(CreateNativeSlider(parent, BT:L("SLIDER_ALPHA"), 0.2, 1.0, 0.05,
        function() return db.alpha or 1.0 end,
        function(v)
            db.alpha = v
            SP:EnsurePreview()
            MP:ApplyLook()
        end, nil, columnWidth))

    -- Font face cycle + size (custom font applies on top of font objects;
    -- "Default" face + untouched size = stock look)
    local fontRow = CreateFrame("Frame", nil, parent)
    fontRow:SetSize(columnWidth, 24)
    local fontLabel = fontRow:CreateFontString(nil, "OVERLAY")
    C.ApplyLabelFont(fontLabel)
    fontLabel:SetPoint("LEFT", 0, 0)
    fontLabel:SetText(BT:L("FONT_FACE_LABEL"))

    local fontBtn = CreateFrame("Button", nil, fontRow, "UIPanelButtonTemplate")
    fontBtn:SetSize(math.max(120, columnWidth - 160), 24)
    fontBtn:SetPoint("LEFT", 150, 0)
    local function FaceText()
        for _, entry in ipairs(C.FONT_FACES) do
            if entry.value == db.fontFace then
                return entry.label or BT:L("FONT_DEFAULT")
            end
        end
        return BT:L("FONT_DEFAULT")
    end
    fontBtn:SetText(FaceText())
    fontBtn:SetScript("OnClick", function(btn)
        local idx = 1
        for i, entry in ipairs(C.FONT_FACES) do
            if entry.value == db.fontFace then idx = i break end
        end
        db.fontFace = C.FONT_FACES[(idx % #C.FONT_FACES) + 1].value
        btn:SetText(FaceText())
        SP:EnsurePreview()
        MP:Refresh()
    end)
    refreshers[#refreshers + 1] = function() fontBtn:SetText(FaceText()) end
    placeMini(fontRow)

    placeMini(CreateNativeSlider(parent, BT:L("SLIDER_FONT_SIZE"), 10, 20, 1,
        function() return db.fontSize or 15 end,
        function(v)
            db.fontSize = math.floor(v + 0.5)
            SP:EnsurePreview()
            MP:Refresh()
        end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end,
        columnWidth))

    placeMini(CreateCheckbox(parent, refreshers, BT:L("OPT_LOCK"),
        function() return db.locked end,
        function(v) db.locked = v end, columnWidth), SECTION_GAP)

    -- ══ RIGHT: Behavior + actions ══
    placeGeneralLeft(CreateSectionHeader(parent, BT:L("SEC_BEHAVIOR")), 8)

    placeGeneralLeft(CreateCheckbox(parent, refreshers, BT:L("OPT_AUTO_SHOW"),
        function() return db.autoShowOnEnter end,
        function(v) db.autoShowOnEnter = v end, columnWidth))

    placeGeneralLeft(CreateCheckbox(parent, refreshers, BT:L("OPT_MINIMAP_ICON"),
        function() return db.showMinimapIcon ~= false end,
        function(v)
            db.showMinimapIcon = v
            BT.MinimapButton:SetShown(v)
        end, columnWidth))

    placeGeneralLeft(CreateCheckbox(parent, refreshers, BT:L("OPT_AUTO_ADVANCE"),
        function() return db.autoAdvance end,
        function(v) db.autoAdvance = v end, columnWidth))

    placeGeneralLeft(CreateCheckbox(parent, refreshers, BT:L("OPT_COMBAT_FADE"),
        function() return db.combatFade end,
        function(v)
            db.combatFade = v
            MP:ApplyAlpha()
        end, columnWidth))

    placeGeneralLeft(CreateCheckbox(parent, refreshers, BT:L("OPT_AUTO_HIDE"),
        function() return db.autoHideAfterEncounter end,
        function(v) db.autoHideAfterEncounter = v end, columnWidth))

    placeGeneralLeft(CreateCheckbox(parent, refreshers, BT:L("OPT_TRASH_PANEL"),
        function() return db.showTrashPanel ~= false end,
        function(v)
            db.showTrashPanel = v
            local dungeon = BT.Detection:GetCurrentDungeonName()
            if v and dungeon and BT_TrashData and BT_TrashData[dungeon] then
                BT.TrashPanel:ShowDungeon(dungeon)
            elseif not v and BT.TrashPanel then
                BT.TrashPanel:Hide()
            end
        end, columnWidth))

    placeTrash(CreateSectionHeader(parent, BT:L("SEC_TRASH_PANEL")), 8)

    local trashSwatchRow
    placeTrash(CreateCheckbox(parent, refreshers, BT:L("OPT_BACKDROP"),
        function() return db.trashBackdropMode ~= false end,
        function(v)
            db.trashBackdropMode = v
            if trashSwatchRow then trashSwatchRow.RefreshSwatch() end
            if BT.TrashPanel then BT.TrashPanel:ApplyLook() end
        end, columnWidth))

    trashSwatchRow = CreateColorSwatchRow(parent, refreshers, columnWidth,
        "trashBackdropMode", "trashBackdropColor", function()
            if BT.TrashPanel then BT.TrashPanel:ApplyLook() end
        end)
    placeTrash(trashSwatchRow)

    placeTrash(CreateNativeSlider(parent, BT:L("SLIDER_BG_ALPHA"), 0.1, 1.0, 0.05,
        function() return (db.trashBackdropColor and db.trashBackdropColor.a) or 1.0 end,
        function(v)
            db.trashBackdropColor = db.trashBackdropColor or { r = 0, g = 0, b = 0 }
            db.trashBackdropColor.a = v
            if BT.TrashPanel then BT.TrashPanel:ApplyLook() end
        end, nil, columnWidth))

    placeTrash(CreateNativeSlider(parent, BT:L("SLIDER_TRASH_SCALE"), 0.6, 1.6, 0.05,
        function() return db.trashPanelScale or 1.0 end,
        function(v)
            db.trashPanelScale = v
            if BT.TrashPanel then BT.TrashPanel:ApplyLook() end
        end, nil, columnWidth))

    placeTrash(CreateNativeSlider(parent, BT:L("SLIDER_TRASH_ALPHA"), 0.2, 1.0, 0.05,
        function() return db.trashPanelAlpha or 1.0 end,
        function(v)
            db.trashPanelAlpha = v
            if BT.TrashPanel then BT.TrashPanel:ApplyLook() end
        end, nil, columnWidth))

    local trashFontRow = CreateFrame("Frame", nil, parent)
    trashFontRow:SetSize(columnWidth, 24)
    local trashFontLabel = trashFontRow:CreateFontString(nil, "OVERLAY")
    C.ApplyLabelFont(trashFontLabel)
    trashFontLabel:SetPoint("LEFT", 0, 0)
    trashFontLabel:SetText(BT:L("FONT_FACE_LABEL"))
    local trashFontBtn = CreateFrame("Button", nil, trashFontRow, "UIPanelButtonTemplate")
    trashFontBtn:SetSize(math.max(120, columnWidth - 160), 24)
    trashFontBtn:SetPoint("LEFT", 150, 0)
    local function TrashFaceText()
        for _, entry in ipairs(C.FONT_FACES) do
            if entry.value == db.trashPanelFontFace then
                return entry.label or BT:L("FONT_DEFAULT")
            end
        end
        return BT:L("FONT_DEFAULT")
    end
    trashFontBtn:SetText(TrashFaceText())
    trashFontBtn:SetScript("OnClick", function(btn)
        local idx = 1
        for i, entry in ipairs(C.FONT_FACES) do
            if entry.value == db.trashPanelFontFace then idx = i break end
        end
        db.trashPanelFontFace = C.FONT_FACES[(idx % #C.FONT_FACES) + 1].value
        btn:SetText(TrashFaceText())
        if BT.TrashPanel and BT.TrashPanel:IsShown() then BT.TrashPanel:Refresh() end
    end)
    refreshers[#refreshers + 1] = function() trashFontBtn:SetText(TrashFaceText()) end
    placeTrash(trashFontRow)

    placeTrash(CreateNativeSlider(parent, BT:L("SLIDER_TRASH_FONT_SIZE"), 10, 22, 1,
        function() return db.trashPanelFontSize or 15 end,
        function(v)
            db.trashPanelFontSize = math.floor(v + 0.5)
            if BT.TrashPanel and BT.TrashPanel:IsShown() then BT.TrashPanel:Refresh() end
        end,
        function(v) return string.format("%d px", math.floor(v + 0.5)) end, columnWidth))

    placeTrash(CreateCheckbox(parent, refreshers, BT:L("OPT_LOCK"),
        function() return db.trashPanelLocked end,
        function(v) db.trashPanelLocked = v end, columnWidth), SECTION_GAP)

    placeGeneralLeft(CreateCheckbox(parent, refreshers, BT:L("OPT_QUICK_TIPS"),
        function() return db.showQuickTips ~= false end,
        function(v)
            db.showQuickTips = v
            SP:EnsurePreview()
            MP:Refresh()
        end, columnWidth))

    local channelRow = CreateFrame("Frame", nil, parent)
    channelRow:SetSize(columnWidth, 24)
    local channelLabel = channelRow:CreateFontString(nil, "OVERLAY")
    C.ApplyLabelFont(channelLabel)
    channelLabel:SetPoint("LEFT", 0, 0)
    channelLabel:SetText(BT:L("SHARE_CHANNEL_LABEL"))

    local channelBtn = CreateFrame("Button", nil, channelRow, "UIPanelButtonTemplate")
    channelBtn:SetSize(math.max(120, columnWidth - 160), 24)
    channelBtn:SetPoint("LEFT", 150, 0)
    local channelCycle = { "AUTO", "INSTANCE_CHAT", "PARTY", "RAID", "SAY" }
    local channelLabels = {
        AUTO = "CHANNEL_AUTO", INSTANCE_CHAT = "CHANNEL_INSTANCE",
        PARTY = "CHANNEL_PARTY", RAID = "CHANNEL_RAID", SAY = "CHANNEL_SAY",
    }
    local function ChannelText()
        return BT:L(channelLabels[db.shareChannel or "AUTO"] or "CHANNEL_AUTO")
    end
    channelBtn:SetText(ChannelText())
    channelBtn:SetScript("OnClick", function(btn)
        local current = db.shareChannel or "AUTO"
        local idx = 1
        for i, value in ipairs(channelCycle) do
            if value == current then idx = i break end
        end
        db.shareChannel = channelCycle[(idx % #channelCycle) + 1]
        btn:SetText(ChannelText())
    end)
    refreshers[#refreshers + 1] = function() channelBtn:SetText(ChannelText()) end
    placeGeneralRight(channelRow)

    placeGeneralRight(CreateCheckbox(parent, refreshers, BT:L("OPT_SHARE_SIGNATURE"),
        function() return db.shareSignature ~= false end,
        function(v) db.shareSignature = v end, columnWidth))

    -- Role filter: cycle button with the role atlas icon inline
    local roleRow = CreateFrame("Frame", nil, parent)
    roleRow:SetSize(columnWidth, 24)
    local roleLabel = roleRow:CreateFontString(nil, "OVERLAY")
    C.ApplyLabelFont(roleLabel)
    roleLabel:SetPoint("LEFT", 0, 0)
    roleLabel:SetText(BT:L("ROLE_FILTER_LABEL"))

    local roleBtn = CreateFrame("Button", nil, roleRow, "UIPanelButtonTemplate")
    roleBtn:SetSize(math.max(110, columnWidth - 160), 24)
    roleBtn:SetPoint("LEFT", 150, 0)
    local function RoleText()
        local filter = db.roleFilter or "ALL"
        local key = C.ROLE_LABEL_KEYS[filter] or "ROLE_ALL_SHORT"
        local atlas = C.ROLE_ATLAS[filter]
        if atlas then
            return "|A:" .. atlas .. ":14:14|a " .. BT:L(key)
        end
        return BT:L(key)
    end
    roleBtn:SetText(RoleText())
    roleBtn:SetScript("OnClick", function(btn)
        SP:EnsurePreview()
        MP:CycleRoleFilter()
        btn:SetText(RoleText())
    end)
    refreshers[#refreshers + 1] = function() roleBtn:SetText(RoleText()) end
    placeGeneralRight(roleRow)

    placeGeneralRight(CreateCheckbox(parent, refreshers, BT:L("OPT_TEST_MODE"),
        function() return MP.testMode end,
        function(v)
            if v then MP:EnterTestMode() else MP:ExitTestMode() end
        end, columnWidth), SECTION_GAP)

    placeGeneralRight(CreateSectionHeader(parent, BT:L("SEC_ACTIONS")), 8)

    local actionRow = CreateFrame("Frame", nil, parent)
    actionRow:SetSize(columnWidth, 24)
    local actionWidth = math.floor((columnWidth - 16) / 3)

    local journalBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
    journalBtn:SetSize(actionWidth, 24)
    journalBtn:SetPoint("LEFT", 0, 0)
    journalBtn:SetText(BT:L("BTN_JOURNAL"))
    journalBtn:SetScript("OnClick", function()
        local bossKey = BT.MiniPanel:GetActiveDisplay()
        BT:OpenJournal(bossKey, BT.MiniPanel:GetDisplayDifficulty())
    end)

    local editBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
    editBtn:SetSize(actionWidth, 24)
    editBtn:SetPoint("LEFT", journalBtn, "RIGHT", 8, 0)
    editBtn:SetText(BT:L("BTN_EDIT_BOSS"))
    editBtn:SetScript("OnClick", function()
        local key = BT.MiniPanel:GetActiveDisplay()
        BT:OpenEditor(key)
    end)

    local resetBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
    resetBtn:SetSize(actionWidth, 24)
    resetBtn:SetPoint("LEFT", editBtn, "RIGHT", 8, 0)
    resetBtn:SetText(BT:L("BTN_RESET_POS"))
    resetBtn:SetScript("OnClick", function()
        db.position = { point = "RIGHT", x = -80, y = 60 }
        BT.MiniPanel:ApplyPosition()
        print(BT:L("POSITION_RESET"))
    end)
    if Theme then
        Theme:LayoutButtonBar(actionRow, { journalBtn, editBtn, resetBtn }, columnWidth,
            { buttonOptions = { compact = false } })
    end
    placeGeneralRight(actionRow)

    local briefRow = CreateFrame("Frame", nil, parent)
    briefRow:SetSize(columnWidth, 24)
    local briefBtn = CreateFrame("Button", nil, briefRow, "UIPanelButtonTemplate")
    briefBtn:SetSize(actionWidth, 24)
    briefBtn:SetPoint("LEFT", 0, 0)
    briefBtn:SetText(BT:L("BTN_OPEN_BRIEF"))
    briefBtn:SetScript("OnClick", function()
        BT:OpenRaidBrief(BT.MiniPanel:GetActiveDisplay())
    end)
    placeGeneralRight(briefRow)

    placeGeneralRight(CreateSectionHeader(parent, BT:L("SEC_RAID_BRIEF")), 8)
    local function ApplyBriefLook()
        if BT.RaidBrief and BT.RaidBrief.window then BT.RaidBrief:ApplyLook() end
    end
    placeGeneralRight(CreateNativeSlider(parent, BT:L("SLIDER_BRIEF_SCALE"), 0.7, 1.6, 0.05,
        function() return db.raidBriefScale or 1.0 end,
        function(v) db.raidBriefScale = v; ApplyBriefLook() end,
        function(v) return string.format("%.2f", v) end, columnWidth))
    placeGeneralRight(CreateNativeSlider(parent, BT:L("SLIDER_BRIEF_FONT"), 11, 20, 1,
        function() return db.raidBriefFontSize or 14 end,
        function(v) db.raidBriefFontSize = v; ApplyBriefLook() end,
        function(v) return string.format("%d px", v) end, columnWidth))

    -- Brief font family picker (each row previews its own font)
    do
        local holder = CreateFrame("Frame", nil, parent)
        holder:SetSize(columnWidth, 28)
        local label = holder:CreateFontString(nil, "OVERLAY")
        C.ApplyLabelFont(label)
        label:SetPoint("LEFT", 0, 0)
        label:SetText(BT:L("OPT_BRIEF_FONT"))

        local choices = BT.RaidBrief and BT.RaidBrief.FONT_CHOICES or {}
        local function CurrentLabel()
            local cur = db.raidBriefFont or "Fonts\\ARIALN.TTF"
            for _, item in ipairs(choices) do
                if item.file == cur then return item.label end
            end
            return choices[1] and choices[1].label or "?"
        end

        local button = CreateFrame("Button", nil, holder, "UIPanelButtonTemplate")
        button:SetSize(math.max(150, holder:GetWidth() - 160), 24)
        button:SetPoint("LEFT", label, "LEFT", 150, 0)
        button:SetText(CurrentLabel())

        local menu = CreateFrame("Frame", nil, holder, "BackdropTemplate")
        menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
        menu:SetSize(button:GetWidth(), #choices * 24 + 6)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetBackdrop(MENU_BACKDROP)
        menu:SetBackdropColor(0.03, 0.03, 0.04, 0.98)
        menu:SetBackdropBorderColor(0.45, 0.45, 0.50, 1)
        menu:Hide()

        for i, item in ipairs(choices) do
            local row = CreateFrame("Button", nil, menu)
            row:SetPoint("TOPLEFT", 3, -3 - ((i - 1) * 24))
            row:SetPoint("TOPRIGHT", -3, -3 - ((i - 1) * 24))
            row:SetHeight(24)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight", "ADD")
            local rowText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            rowText:SetPoint("LEFT", 8, 0)
            rowText:SetFont(item.file, 13, "")
            rowText:SetText(item.label)
            row:SetScript("OnClick", function()
                db.raidBriefFont = item.file
                button:SetText(item.label)
                menu:Hide()
                ApplyBriefLook()
            end)
        end

        button:SetScript("OnClick", function()
            if menu:IsShown() then menu:Hide() else menu:Show() end
        end)
        holder:SetScript("OnHide", function() menu:Hide() end)
        placeGeneralRight(holder)
    end

    local panelRow = CreateFrame("Frame", nil, parent)
    panelRow:SetSize(columnWidth, 24)
    local panelBtn = CreateFrame("Button", nil, panelRow, "UIPanelButtonTemplate")
    panelBtn:SetAllPoints()
    local function PanelButtonText()
        return BT:L(MP:IsShown() and "BTN_HIDE_MINI_PANEL" or "BTN_SHOW_MINI_PANEL")
    end
    panelBtn:SetText(PanelButtonText())
    panelBtn:SetScript("OnClick", function(btn)
        if MP:IsShown() then
            if MP.testMode then MP:ExitTestMode(true) end
            MP:HidePanel(true)
        else
            local dungeonName = BT.Detection:GetCurrentDungeonName()
            local lastBossKey = db.lastBossKey
            if dungeonName or (lastBossKey and BT_BossData and BT_BossData[lastBossKey]) then
                MP:Toggle()
            else
                MP:EnterTestMode()
            end
        end
        btn:SetText(PanelButtonText())
    end)
    refreshers[#refreshers + 1] = function() panelBtn:SetText(PanelButtonText()) end
    placeGeneralRight(panelRow)

    local trashPanelRow = CreateFrame("Frame", nil, parent)
    trashPanelRow:SetSize(columnWidth, 24)
    local trashPanelBtn = CreateFrame("Button", nil, trashPanelRow, "UIPanelButtonTemplate")
    trashPanelBtn:SetAllPoints()
    local function TrashPanelButtonText()
        return BT:L(BT.TrashPanel and BT.TrashPanel:IsShown()
            and "BTN_HIDE_TRASH_PANEL" or "BTN_SHOW_TRASH_PANEL")
    end
    trashPanelBtn:SetText(TrashPanelButtonText())
    trashPanelBtn:SetScript("OnClick", function(btn)
        local TP = BT.TrashPanel
        if TP and TP:IsShown() then
            TP:Hide()
        else
            local dungeon = BT.Detection:GetCurrentDungeonName()
            if dungeon and BT_TrashData and BT_TrashData[dungeon] and TP then
                TP:ShowDungeon(dungeon)
            else
                print(BT:L("ERR_NO_INSTANCE"))
            end
        end
        btn:SetText(TrashPanelButtonText())
    end)
    refreshers[#refreshers + 1] = function() trashPanelBtn:SetText(TrashPanelButtonText()) end
    placeGeneralRight(trashPanelRow)

    placeGeneralRight(CreateSectionHeader(parent, BT:L("SEC_CREDITS")), 8)
    local credits = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    credits:SetWidth(columnWidth)
    credits:SetHeight(58)
    credits:SetJustifyH("LEFT")
    credits:SetJustifyV("TOP")
    credits:SetTextColor(0.92, 0.92, 0.92, 1)
    credits:SetText("|cffffffffBoss Tactics|r por |cffffcc00Lovacnapice|r @ Ragnaros EU\n"
        .. "|cffffffffDicas de inimigos comuns|r por |cff66ccffTactyks|r\n"
        .. "|cffffffffTradução francesa histórica dos grupos de inimigos|r: |cff66ccffKahélem|r")
    placeGeneralRight(credits, 0)

    local pageHeights = {
        GENERAL = math.max(-generalLeftY, -generalRightY) + 14,
        APPEARANCE = math.max(-miniY, -trashY) + 14,
    }
    generalPanel:SetHeight(pageHeights.GENERAL)
    miniPanel:SetHeight(pageHeights.APPEARANCE)
    trashPanel:SetHeight(pageHeights.APPEARANCE)
    self._optionsPages = self._optionsPages or {}
    self._optionsPages[parent] = { widgets = pageWidgets, heights = pageHeights }
    return pageHeights.GENERAL
end

function SP:SetOptionsPage(parent, page)
    local info = self._optionsPages and self._optionsPages[parent]
    if not info then return end
    page = page == "APPEARANCE" and "APPEARANCE" or "GENERAL"
    self.optionsPage = page
    for key, widgets in pairs(info.widgets) do
        for _, widget in ipairs(widgets) do widget:SetShown(key == page) end
    end
    parent:SetHeight(math.max(1, info.heights[page] or 1))
    if self.optionsScroll then self.optionsScroll:SetVerticalScroll(0) end
    if self.optionPageButtons then
        for key, button in pairs(self.optionPageButtons) do
            local active = key == page
            button:SetBackdropColor(active and 0.10 or 0.025, active and 0.075 or 0.025,
                active and 0.015 or 0.032, 0.96)
            button:SetBackdropBorderColor(active and 0.95 or 0.22, active and 0.68 or 0.22,
                active and 0.08 or 0.25, active and 0.95 or 0.8)
            button.label:SetTextColor(active and 1 or 0.82, active and 0.86 or 0.82,
                active and 0.18 or 0.86, 1)
            if Theme then Theme:SetSelected(button, active) end
        end
    end
end

-- ─── Standalone options window (primary entry — /bosstactics options) ───────────────

local function BuildContentSafely(parent)
    local ok, contentH = pcall(SP.BuildContent, SP, parent)
    if ok then return contentH end

    parent:Hide()
    local fallback = CreateFrame("Frame", nil, parent:GetParent(), "InsetFrameTemplate")
    fallback:SetAllPoints(parent)
    local title = fallback:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -18)
    title:SetText(BT:L("OPT_BUILD_FAILED_TITLE"))
    local details = fallback:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    details:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    details:SetPoint("TOPRIGHT", -18, -48)
    details:SetJustifyH("LEFT")
    details:SetJustifyV("TOP")
    details:SetWordWrap(true)
    details:SetText(string.format(BT:L("OPT_BUILD_FAILED"), tostring(contentH)))
    local reload = CreateFrame("Button", nil, fallback, "UIPanelButtonTemplate")
    reload:SetSize(120, 24)
    reload:SetPoint("BOTTOMLEFT", 18, 18)
    reload:SetText(BT:L("BTN_RELOAD_UI"))
    reload:SetScript("OnClick", ReloadUI)
    print("|cffff4444Boss Tactics|r: altura inválida do conteúdo: " .. tostring(contentH))
    return nil
end

function SP:GetOptionsWindow()
    if self.window then return self.window end

    -- Named frame: UISpecialFrames (ESC-close) only works with a global frame
    -- name — this is the one sanctioned global exception (documented in
    -- prompt 003; keeps the BossTactics prefix).
    local f = CreateFrame("Frame", "BossTacticsOptionsFrame", UIParent, "ButtonFrameTemplate")
    self.window = f
    local screenWidth = (UIParent and UIParent:GetWidth()) or 1024
    local screenHeight = (UIParent and UIParent:GetHeight()) or 768
    local maxWindowWidth = math.max(620, screenWidth - 40)
    local maxWindowHeight = math.max(480, screenHeight - 40)
    f:SetSize(math.min(940, maxWindowWidth), math.min(640, maxWindowHeight))
    f:SetPoint("CENTER")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)

    -- Title + portrait (Adventure Guide look)
    if f.SetTitle then
        f:SetTitle(BT:L("SETTINGS_TITLE"))
    elseif f.TitleText then
        f.TitleText:SetText(BT:L("SETTINGS_TITLE"))
    end
    local PORTRAIT_ICON = "Interface\\Icons\\INV_Misc_Book_09"   -- journal/tactics book
    if f.SetPortraitToAsset then
        f:SetPortraitToAsset(PORTRAIT_ICON)
    elseif SetPortraitToAsset and f.PortraitContainer and f.PortraitContainer.portrait then
        SetPortraitToAsset(f.PortraitContainer.portrait, PORTRAIT_ICON)
    end

    -- Drag via the title bar
    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", 8, 0)
    drag:SetPoint("TOPRIGHT", -28, 0)
    drag:SetHeight(24)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    -- ESC closes the window
    tinsert(UISpecialFrames, "BossTacticsOptionsFrame")

    local tabBar = CreateFrame("Frame", nil, f)
    if f.Inset then
        tabBar:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", 14, -10)
        tabBar:SetPoint("TOPRIGHT", f.Inset, "TOPRIGHT", -14, -10)
    else
        tabBar:SetPoint("TOPLEFT", 16, -58)
        tabBar:SetPoint("TOPRIGHT", -16, -58)
    end
    tabBar:SetHeight(40)

    self.optionPageButtons = {}
    local previous
    for _, def in ipairs({
        { key = "GENERAL", label = "OPTIONS_PANEL_GENERAL" },
        { key = "APPEARANCE", label = "OPTIONS_PANEL_APPEARANCE" },
    }) do
        local pageKey = def.key
        local button = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        button:SetSize(math.floor(((f:GetWidth() or 940) - 70) / 2), 34)
        if previous then button:SetPoint("LEFT", previous, "RIGHT", 8, 0)
        else button:SetPoint("LEFT", 0, 0) end
        button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        button.label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        button.label:SetAllPoints()
        button.label:SetText(BT:L(def.label))
        button:SetScript("OnClick", function() SP:SetOptionsPage(SP.optionsContent, pageKey) end)
        self.optionPageButtons[pageKey] = button
        previous = button
    end

    -- Both tabs remain scrollable at smaller resolutions and UI scales.
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    if f.Inset then
        scroll:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", 14, -58)
        scroll:SetPoint("BOTTOMRIGHT", f.Inset, "BOTTOMRIGHT", -30, 14)
    else
        scroll:SetPoint("TOPLEFT", 16, -104)
        scroll:SetPoint("BOTTOMRIGHT", -30, 30)
    end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(frame, delta)
        local maxScroll = math.max(0, frame:GetVerticalScrollRange() or 0)
        local nextScroll = frame:GetVerticalScroll() - (delta * 36)
        frame:SetVerticalScroll(math.max(0, math.min(maxScroll, nextScroll)))
    end)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(math.max(680, math.floor((f:GetWidth() or 940) - 76)))
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    self.optionsScroll = scroll
    self.optionsContent = content
    local contentH = BuildContentSafely(content)
    if contentH then self:SetOptionsPage(content, self.optionsPage or "GENERAL") end

    -- Clickable release credit. WoW protects arbitrary external URL launching
    -- from addon code, so the click opens a focused, copy-ready URL dialog.
    local addonName = BT.ADDON_NAME or "BossTactics"
    local ver = C_AddOns and C_AddOns.GetAddOnMetadata
        and C_AddOns.GetAddOnMetadata(addonName, "Version") or "4.2.1"
    local author = C_AddOns and C_AddOns.GetAddOnMetadata
        and C_AddOns.GetAddOnMetadata(addonName, "Author") or "cyberhrc"
    local displayVer = tostring(ver):match("^v?(%d+%.%d+%.?%d*)") or tostring(ver)
    local footerLink = CreateFrame("Button", nil, f)
    footerLink:SetPoint("BOTTOMLEFT", 16, 3)
    footerLink:SetPoint("BOTTOMRIGHT", -16, 3)
    footerLink:SetHeight(22)
    local verText = footerLink:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    verText:SetAllPoints()
    verText:SetJustifyH("CENTER")
    verText:SetText(string.format(
        "Boss Tactics v.%s por %s / Lovacnapice @ Ragnaros EU", displayVer, author))
    footerLink:SetScript("OnClick", ShowCurseForgeLink)
    footerLink:SetScript("OnEnter", function(btn)
        verText:SetTextColor(1, 0.82, 0, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText(BT:L("TOOLTIP_CURSEFORGE"), 1, 1, 1)
        GameTooltip:Show()
    end)
    footerLink:SetScript("OnLeave", function()
        verText:SetTextColor(0.5, 0.5, 0.5, 1)
        GameTooltip:Hide()
    end)

    f:SetScript("OnShow", function() SP:RefreshAll() end)
    if Theme then
        Theme:StyleWindow(f)
        Theme:StyleAddonTree(f)
    end
    f:Hide()
    return f
end

-- ─── Blizzard Settings canvas (secondary entry — ESC > Options > AddOns) ────

function BT:RegisterSettingsPanel()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then
        return
    end

    local panel = CreateFrame("Frame")
    panel.name = "Boss Tactics"
    panel:SetScript("OnShow", function(p)
        if not p._built then
            p._built = true
            local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            title:SetPoint("TOPLEFT", 16, -16)
            title:SetText(BT:L("SETTINGS_TITLE"))

            local description = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -18)
            description:SetPoint("TOPRIGHT", p, "TOPRIGHT", -40, -52)
            description:SetJustifyH("LEFT")
            description:SetJustifyV("TOP")
            description:SetWordWrap(true)
            description:SetText(BT:L("BLIZZARD_SETTINGS_DESC"))

            local open = CreateFrame("Button", nil, p, "UIPanelButtonTemplate")
            open:SetSize(260, 30)
            open:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -20)
            open:SetText(BT:L("BTN_OPEN_OPTIONS"))
            open:SetScript("OnClick", function()
                if InCombatLockdown() then
                    print(BT:L("ERR_IN_COMBAT"))
                    return
                end
                if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then
                    HideUIPanel(SettingsPanel)
                end
                SP:GetOptionsWindow():Show()
            end)

            local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            hint:SetPoint("TOPLEFT", open, "BOTTOMLEFT", 0, -12)
            hint:SetText(BT:L("BLIZZARD_SETTINGS_HINT"))
        end
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Boss Tactics")
    Settings.RegisterAddOnCategory(category)
    self._settingsCategory = category
end

--- /bosstactics options — toggles the standalone window. Blocked in combat.
function BT:OpenSettings()
    if InCombatLockdown() then
        print(self:L("ERR_IN_COMBAT"))
        return
    end
    local w = self.SettingsPanel:GetOptionsWindow()
    if w:IsShown() then
        w:Hide()
    else
        w:Show()
    end
end
