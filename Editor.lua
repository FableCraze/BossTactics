-- Editor.lua  (Boss Tactics)
-- In-game boss editor: edit tactics of built-in bosses (field-level override)
-- and create fully custom bosses. One window, one form — text-based formats
-- instead of the old form-per-ability approach.
--
-- Data flow: form -> db.customBosses[key] -> BT:ApplyCustomBosses() (restore
-- original + apply fields) -> BT:RebuildIndexes(). Originals snapshot lives
-- in BT._originalFields so Revert can restore built-ins.

local BT = BossTactics
local C = BT.Components
local Theme = BT.Theme

local ED = {}
BT.Editor = ED

ED.selectedKey = nil   -- nil = "new boss" form
ED.dirty = false
ED._loadingForm = false

-- Layout constants
local LIST_W    = 230
local FORM_X    = 246
local FIELD_H   = 24
local ROW_GAP   = 8
local COL_GAP   = 14

-- Keep the editor on the same locale-safe Blizzard font objects as Options.
-- A direct font path (especially ARIALN.TTF) looks compressed at several UI
-- scales and does not follow the client's locale-specific font choice.
local function ApplyEditorFont(region, large)
    local fontObject = large and (GameFontHighlightLarge or GameFontHighlight)
        or (GameFontHighlight or GameFontNormal)
    if not fontObject then return end
    region:SetFontObject(fontObject)
    local path, size, flags = fontObject:GetFont()
    local scale = (BT.db and tonumber(BT.db.journalFontScale))
        or C.DEFAULT_WORKSPACE_FONT_SCALE or 1.2
    scale = math.max(0.8, math.min(1.6, scale))
    if path and size and region.SetFont then
        region:SetFont(path, math.max(8, math.floor(size * scale + 0.5)), flags or "")
    end
end

-- Reverse of C.DIFF_SHORT: "[H+]" line tag -> "HEROIC+"
local DIFF_FROM_SHORT = {}
for full, short in pairs(C.DIFF_SHORT) do
    DIFF_FROM_SHORT[short] = full
end

-- ─── Serialization: data <-> editable text ──────────────────────────────────

--- One bullet per line; table-form bullets get a "[H+] " style prefix.
local function TldrToText(tldr)
    local lines = {}
    for _, b in ipairs(tldr or {}) do
        if type(b) == "table" then
            local short = b.difficulty and C.DIFF_SHORT[b.difficulty:upper()]
            local tag = short and ("[" .. short .. "] ") or ""
            lines[#lines + 1] = tag .. (BT:Localize(b.text) or "")
        else
            lines[#lines + 1] = BT:Localize(b) or ""
        end
    end
    return table.concat(lines, "\n\n")
end

--- Parse "[H+] text" / plain lines back into the tldr array format.
local function ParseTldrText(text)
    local out = {}
    for line in (text or ""):gmatch("[^\r\n]+") do
        line = strtrim(line)
        if line ~= "" then
            local tag, rest = line:match("^%[([%a%+]+)%]%s*(.+)$")
            local full = tag and DIFF_FROM_SHORT[tag:upper()]
            if full and rest then
                out[#out + 1] = { text = rest, difficulty = full }
            else
                out[#out + 1] = line
            end
        end
    end
    return out
end

--- One ability per line: TYPE|ROLE|Title|Description|Phase.
--- TYPE/ROLE/Phase optional; difficulty is a "[H+]" style tag at the start of
--- Title (same syntax as TLDR lines) — both round-trip built-in data without
--- loss. Description must not contain "|".
local function AbilitiesToText(abilities)
    local lines = {}
    for _, ab in ipairs(abilities or {}) do
        local short = ab.difficulty and C.DIFF_SHORT[ab.difficulty:upper()]
        local title = (short and ("[" .. short .. "] ") or "") .. (BT:Localize(ab.title) or "")
        local line = (ab.type or "") .. "|" .. (ab.role or "") .. "|"
            .. title .. "|" .. (BT:Localize(ab.description) or "")
        if ab.phase ~= nil then
            line = line .. "|" .. tostring(ab.phase)
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n\n")
end

local function ParseAbilitiesText(text)
    local out = {}
    for line in (text or ""):gmatch("[^\r\n]+") do
        line = strtrim(line)
        if line ~= "" then
            local t, r, title, desc, phase = line:match("^([^|]*)|([^|]*)|([^|]*)|([^|]*)|(.*)$")
            if not t then
                t, r, title, desc = line:match("^([^|]*)|([^|]*)|([^|]*)|(.*)$")
            end
            if not t then
                t, r, title = line:match("^([^|]*)|([^|]*)|(.*)$")
            end
            if not t then
                t, r, title = "", "", line
            end
            local ab = { title = strtrim(title or "") }
            t = strtrim(t):upper()
            r = strtrim(r):upper()
            if r == "HEAL" then r = "HEALER" end
            if t ~= "" then ab.type = t end
            if r ~= "" and r ~= "ALL" then ab.role = r end
            desc = strtrim(desc or "")
            if desc ~= "" then ab.description = desc end
            phase = strtrim(phase or "")
            if phase ~= "" then ab.phase = tonumber(phase) or phase end
            -- Difficulty tag on the title, TLDR-style: "[H+] Title"
            local tag, rest = ab.title:match("^%[([%a%+]+)%]%s*(.+)$")
            local full = tag and DIFF_FROM_SHORT[tag:upper()]
            if full and rest then
                ab.difficulty = full
                ab.title = rest
            end
            if ab.title ~= "" then
                out[#out + 1] = ab
            end
        end
    end
    return out
end

local function TipsToText(tips, affixTips)
    local lines = {}
    for _, tip in ipairs(tips or {}) do
        local text = type(tip) == "table" and tip.text or tip
        if text and text ~= "" then lines[#lines + 1] = "TIP|" .. BT:Localize(text) end
    end
    local affixes = {}
    for affix in pairs(affixTips or {}) do affixes[#affixes + 1] = affix end
    table.sort(affixes, function(a, b) return tostring(a) < tostring(b) end)
    for _, affix in ipairs(affixes) do
        for _, tip in ipairs(affixTips[affix] or {}) do
            lines[#lines + 1] = "AFFIX|" .. tostring(affix) .. "|" .. (BT:Localize(tip) or "")
        end
    end
    return table.concat(lines, "\n")
end

local function ParseTipsText(text)
    local tips, affixTips = {}, {}
    for line in (text or ""):gmatch("[^\r\n]+") do
        line = strtrim(line)
        if line ~= "" then
            local affix, tip = line:match("^AFFIX|([^|]+)|(.+)$")
            if affix and tip then
                affix = strtrim(affix)
                affixTips[affix] = affixTips[affix] or {}
                affixTips[affix][#affixTips[affix] + 1] = strtrim(tip)
            else
                local plain = line:match("^TIP|(.+)$") or line
                tips[#tips + 1] = strtrim(plain)
            end
        end
    end
    return tips, affixTips
end

-- ─── Widget helpers ─────────────────────────────────────────────────────────

local function CreateLabeledInput(parent, labelText, x, y, width)
    local label = parent:CreateFontString(nil, "OVERLAY")
    C.ApplyLabelFont(label)
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(labelText)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, FIELD_H)
    eb:SetPoint("TOPLEFT", x + 130, y + 3)
    ApplyEditorFont(eb, true)
    eb:SetAutoFocus(false)
    eb:SetScript("OnEscapePressed", function(e) e:ClearFocus() end)
    return eb
end

--- Multiline text area: inset + scrollframe + editbox. Returns inset, editbox.
local function CreateMultilineEditor(parent, x, y, width, height)
    local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    inset:SetPoint("TOPLEFT", x, y)
    inset:SetSize(width, height)

    local sf = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 6, -6)
    sf:SetPoint("BOTTOMRIGHT", -26, 6)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    ApplyEditorFont(eb, true)
    if eb.SetSpacing then eb:SetSpacing(4) end
    eb:SetWidth(width - 36)
    eb:SetScript("OnEscapePressed", function(e) e:ClearFocus() end)
    sf:SetScrollChild(eb)

    -- Clicking anywhere in the area focuses the editbox
    sf:EnableMouse(true)
    sf:SetScript("OnMouseDown", function() eb:SetFocus() end)

    return inset, eb
end

-- ─── Window ─────────────────────────────────────────────────────────────────

function ED:SetDirty(dirty)
    self.dirty = dirty and true or false
    if self.saveBtn then
        self.saveBtn:SetText(BT:L("BTN_SAVE") .. (self.dirty and " *" or ""))
        if Theme then Theme:FitButton(self.saveBtn, { compact = true }) end
    end
end

function ED:ApplyWorkspaceFonts()
    for _, region in ipairs({ self.nameEB, self.dungeonEB, self.encIdEB,
        self.tldrEB, self.abilitiesEB, self.tipsEB }) do
        if region then ApplyEditorFont(region, true) end
    end
    for _, region in ipairs({ self.formatHint, self.parsedPreview,
        self.liveSubtitle, self.liveMode }) do
        if region then ApplyEditorFont(region, false) end
    end
    for _, region in ipairs({ self.livePreviewTitle, self.liveBossTitle }) do
        if region then ApplyEditorFont(region, true) end
    end
end

function ED:SetFormError(message)
    self.formError = message
    self:UpdateParsedPreview()
end

function ED:GetFormSignature()
    if not self.nameEB then return "" end
    return table.concat({
        self.nameEB:GetText() or "",
        self.dungeonEB:GetText() or "",
        self.encIdEB:GetText() or "",
        tostring(self.formSeason or 0),
        self.formIsRaid and "1" or "0",
        self.tldrEB:GetText() or "",
        self.abilitiesEB:GetText() or "",
        self.tipsEB:GetText() or "",
    }, "\031")
end

function ED:SyncDirty()
    if self._loadingForm then return end
    self:SetDirty(self:GetFormSignature() ~= (self._baselineSignature or ""))
end

function ED:HandleFormChanged()
    if self._loadingForm then return end
    self.formError = nil
    self:UpdateParsedPreview()
    if self._dirtySyncPending then return end
    self._dirtySyncPending = true
    C_Timer.After(0, function()
        ED._dirtySyncPending = false
        ED:SyncDirty()
    end)
end

function ED:PromptUnsaved(action)
    self._pendingAction = action
    local dialog = self.unsavedDialog
    if not dialog then
        dialog = CreateFrame("Frame", nil, self.window, "InsetFrameTemplate")
        self.unsavedDialog = dialog
        dialog:SetSize(440, 132)
        dialog:SetPoint("CENTER")
        dialog:SetFrameStrata("DIALOG")
        dialog:SetFrameLevel((self.window:GetFrameLevel() or 1) + 20)
        dialog:EnableMouse(true)

        local shade = dialog:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetColorTexture(0.02, 0.02, 0.02, 0.96)

        local message = dialog:CreateFontString(nil, "OVERLAY")
        C.ApplyLabelFont(message)
        message:SetPoint("TOPLEFT", 18, -18)
        message:SetPoint("TOPRIGHT", -18, -18)
        message:SetJustifyH("CENTER")
        message:SetWordWrap(true)
        message:SetText(BT:L("ED_UNSAVED_PROMPT"))

        local function Finish(saveFirst, discardChanges)
            if saveFirst and not ED:Save() then return end
            if discardChanges then ED:FillForm(ED.selectedKey) end
            dialog:Hide()
            local pending = ED._pendingAction
            ED._pendingAction = nil
            if pending then pending() end
        end

        local save = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        save:SetSize(105, 24)
        save:SetPoint("BOTTOMLEFT", 45, 18)
        save:SetText(BT:L("BTN_SAVE"))
        save:SetScript("OnClick", function() Finish(true, false) end)

        local discard = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        discard:SetSize(105, 24)
        discard:SetPoint("LEFT", save, "RIGHT", 16, 0)
        discard:SetText(BT:L("BTN_DISCARD"))
        discard:SetScript("OnClick", function() Finish(false, true) end)

        local cancel = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
        cancel:SetSize(105, 24)
        cancel:SetPoint("LEFT", discard, "RIGHT", 16, 0)
        cancel:SetText(CANCEL or BT:L("BTN_CANCEL"))
        cancel:SetScript("OnClick", function()
            ED._pendingAction = nil
            dialog:Hide()
        end)
        if Theme then
            Theme:StyleSurface(dialog, "window", true)
            Theme:StyleAddonTree(dialog)
        end
    end
    dialog:Show()
    return false
end

function ED:RequestSelection(key)
    if key == self.selectedKey then return true end
    if self.dirty then
        return self:PromptUnsaved(function() self:FillForm(key) end)
    end
    self:FillForm(key)
    return true
end

function ED:RequestClose()
    local function Close()
        ED._allowHide = true
        ED.window:Hide()
    end
    if self.dirty then
        return self:PromptUnsaved(Close)
    end
    Close()
    return true
end

function ED:GetWindow()
    if self.window then return self.window end

    -- Named frame: UISpecialFrames (ESC-close) requires a global name —
    -- sanctioned exception, same as the options window.
    local f = CreateFrame("Frame", "BossTacticsEditorFrame", UIParent, "ButtonFrameTemplate")
    self.window = f
    local screenW = UIParent:GetWidth() or 1024
    local screenH = UIParent:GetHeight() or 768
    local windowW = math.min(1240, math.max(960, screenW - 32))
    local windowH = math.min(740, math.max(660, screenH - 32))
    local contentRight = windowW - 42
    local previewW = math.min(300, math.max(260, math.floor(contentRight * 0.30)))
    local mainW = contentRight - FORM_X - COL_GAP - previewW
    local previewX = FORM_X + mainW + COL_GAP
    self.mainW = mainW
    f:SetSize(windowW, windowH)
    f:SetPoint("CENTER")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)

    if f.SetTitle then
        f:SetTitle(BT:L("ED_TITLE"))
    elseif f.TitleText then
        f.TitleText:SetText(BT:L("ED_TITLE"))
    end
    local PORTRAIT_ICON = "Interface\\Icons\\INV_Misc_Book_09"
    if f.SetPortraitToAsset then
        f:SetPortraitToAsset(PORTRAIT_ICON)
    elseif SetPortraitToAsset and f.PortraitContainer and f.PortraitContainer.portrait then
        SetPortraitToAsset(f.PortraitContainer.portrait, PORTRAIT_ICON)
    end

    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", 8, 0)
    drag:SetPoint("TOPRIGHT", -28, 0)
    drag:SetHeight(24)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    tinsert(UISpecialFrames, "BossTacticsEditorFrame")

    local content = CreateFrame("Frame", nil, f)
    if f.Inset then
        content:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", 10, -10)
        content:SetPoint("BOTTOMRIGHT", f.Inset, "BOTTOMRIGHT", -10, 10)
    else
        content:SetPoint("TOPLEFT", 14, -64)
        content:SetPoint("BOTTOMRIGHT", -14, 30)
    end
    self.content = content

    -- ── Left: shared boss list widget (search + dungeon groups, pooled) ──
    self.bossList = C.CreateBossList(content, LIST_W, function(key)
        return ED:RequestSelection(key)
    end)
    self.bossList.frame:SetPoint("TOPLEFT", 0, 0)
    self.bossList.frame:SetPoint("BOTTOMLEFT", 0, 0)

    -- ── Right: form ──
    local y = 0
    local inputW = math.max(210, mainW - 130)
    self.nameEB = CreateLabeledInput(content, BT:L("ED_NAME"), FORM_X, y, inputW)
    y = y - (FIELD_H + ROW_GAP)
    self.dungeonEB = CreateLabeledInput(content, BT:L("ED_DUNGEON"), FORM_X, y, inputW)
    y = y - (FIELD_H + ROW_GAP)
    self.encIdEB = CreateLabeledInput(content, BT:L("ED_ENCID"), FORM_X, y, 100)
    self.encIdEB:SetNumeric(true)
    y = y - (FIELD_H + ROW_GAP)

    local seasonLabel = content:CreateFontString(nil, "OVERLAY")
    C.ApplyLabelFont(seasonLabel)
    seasonLabel:SetPoint("TOPLEFT", FORM_X, y)
    seasonLabel:SetText(BT:L("ED_SEASON"))
    self.seasonBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    self.seasonBtn:SetSize(100, 22)
    self.seasonBtn:SetPoint("TOPLEFT", FORM_X + 85, y + 3)
    self.seasonBtn:SetScript("OnClick", function()
        ED.formSeason = ED.formSeason == 2 and 1 or (ED.formSeason == 1 and 0 or 2)
        ED:UpdateMetaButtons()
        ED:SyncDirty()
        ED:UpdateParsedPreview()
    end)

    local typeLabel = content:CreateFontString(nil, "OVERLAY")
    C.ApplyLabelFont(typeLabel)
    typeLabel:SetPoint("TOPLEFT", FORM_X + mainW - 150, y)
    typeLabel:SetText(BT:L("ED_CONTENT_TYPE"))
    self.typeBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    self.typeBtn:SetSize(95, 22)
    self.typeBtn:SetPoint("TOPLEFT", FORM_X + mainW - 95, y + 3)
    self.typeBtn:SetScript("OnClick", function()
        ED.formIsRaid = not ED.formIsRaid
        ED:UpdateMetaButtons()
        ED:SyncDirty()
        ED:UpdateParsedPreview()
    end)
    y = y - (FIELD_H + ROW_GAP + 6)

    local tabs = CreateFrame("Frame", nil, content)
    tabs:SetPoint("TOPLEFT", FORM_X, y)
    tabs:SetSize(mainW, 26)
    self.tabButtons = {}
    local tabDefs = {
        { key = "TLDR", label = "ED_TAB_TLDR" },
        { key = "ABILITIES", label = "ED_TAB_ABILITIES" },
        { key = "TIPS", label = "ED_TAB_TIPS" },
    }
    for i, def in ipairs(tabDefs) do
        local tabKey = def.key
        local btn = CreateFrame("Button", nil, tabs, "UIPanelButtonTemplate")
        btn:SetSize(115, 24)
        btn:SetPoint("LEFT", (i - 1) * 120, 0)
        btn:SetText(BT:L(def.label))
        btn:SetScript("OnClick", function() ED:SetActiveTab(tabKey) end)
        self.tabButtons[tabKey] = btn
    end

    local hint = content:CreateFontString(nil, "OVERLAY")
    self.formatHint = hint
    ApplyEditorFont(hint, false)
    hint:SetTextColor(0.722, 0.702, 0.655, 1)
    hint:SetPoint("TOPLEFT", FORM_X, y - 30)
    hint:SetWidth(mainW)
    hint:SetJustifyH("LEFT")
    hint:SetWordWrap(true)

    local chipBar = CreateFrame("Frame", nil, content)
    self.chipBar = chipBar
    chipBar:SetPoint("TOPLEFT", FORM_X, y - 58)
    chipBar:SetSize(mainW, 48)
    self.chipsByTab = { TLDR = {}, ABILITIES = {}, TIPS = {} }
    local function MakeChip(tab, label, insertText, width)
        local btn = CreateFrame("Button", nil, chipBar, "UIPanelButtonTemplate")
        btn:SetSize(width or 72, 22)
        btn:SetText(label)
        btn._insertText = insertText
        btn:SetScript("OnClick", function(b)
            local eb = ED:GetActiveEditBox()
            if eb then eb:Insert(b._insertText) eb:SetFocus() end
        end)
        local list = ED.chipsByTab[tab]
        list[#list + 1] = btn
    end
    MakeChip("TLDR", "TANQUE:", "TANQUE: ", 78)
    MakeChip("TLDR", "CURADOR:", "CURADOR: ", 82)
    MakeChip("TLDR", "DPS:", "DPS: ", 62)
    MakeChip("TLDR", "INTERROMPER:", "INTERROMPER: ", 105)
    MakeChip("TLDR", "[H+]", "[H+] ", 58)
    MakeChip("TLDR", "[M]", "[M] ", 54)
    MakeChip("TLDR", "[M+]", "[M+] ", 58)

    local types = {
        { "INTERRUPT", "Interromper" }, { "SOAK", "Absorver" }, { "MOVEMENT", "Mover" },
        { "DISPEL", "Dissipar" }, { "TANK_CD", "Recarga do tanque" }, { "HEALER_CD", "Recarga do curador" },
    }
    for _, entry in ipairs(types) do
        local meta = C.ABILITY_TYPES[entry[1]] or {}
        MakeChip("ABILITIES", (meta.icon or "") .. entry[2], entry[1] .. "|ALL|", 92)
    end
    MakeChip("TIPS", "Tip", "TIP|", 80)
    MakeChip("TIPS", "Tyrannical", "AFFIX|Tyrannical|", 120)

    -- Fixed bottom action area. Preview and editors anchor above it, so they
    -- can never overlap the buttons at any supported window height.
    local actionBar = CreateFrame("Frame", nil, content, "InsetFrameTemplate")
    self.actionBar = actionBar
    actionBar:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", FORM_X, 0)
    actionBar:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)
    actionBar:SetHeight(58)

    local previewInset = CreateFrame("Frame", nil, content, "InsetFrameTemplate")
    self.livePreview = previewInset
    previewInset:SetPoint("TOPLEFT", content, "TOPLEFT", previewX, 0)
    previewInset:SetPoint("BOTTOMRIGHT", actionBar, "TOPRIGHT", 0, 8)
    local previewTitle = previewInset:CreateFontString(nil, "OVERLAY")
    self.livePreviewTitle = previewTitle
    ApplyEditorFont(previewTitle, true)
    previewTitle:SetTextColor(0.788, 0.643, 0.298, 1)
    previewTitle:SetPoint("TOPLEFT", 10, -10)
    previewTitle:SetText(BT:L("ED_LIVE_PREVIEW"))

    local bossTitle = previewInset:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ApplyEditorFont(bossTitle, true)
    self.liveBossTitle = bossTitle
    bossTitle:SetPoint("TOPLEFT", previewTitle, "BOTTOMLEFT", 0, -12)
    bossTitle:SetWidth(previewW - 20)
    bossTitle:SetJustifyH("LEFT")
    bossTitle:SetWordWrap(true)

    local subtitle = previewInset:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyEditorFont(subtitle, false)
    self.liveSubtitle = subtitle
    subtitle:SetPoint("TOPLEFT", bossTitle, "BOTTOMLEFT", 0, -4)
    subtitle:SetWidth(previewW - 20)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWordWrap(true)

    local mode = previewInset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyEditorFont(mode, false)
    self.liveMode = mode
    mode:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
    mode:SetTextColor(1, 0.82, 0, 1)

    local divider = previewInset:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.35, 0.35, 0.35, 0.7)
    divider:SetHeight(1)
    divider:SetWidth(previewW - 20)
    divider:SetPoint("TOPLEFT", mode, "BOTTOMLEFT", 0, -7)

    local previewScroll = CreateFrame("ScrollFrame", nil, previewInset, "UIPanelScrollFrameTemplate")
    self.livePreviewScroll = previewScroll
    previewScroll:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -8)
    previewScroll:SetPoint("BOTTOMRIGHT", previewInset, "BOTTOMRIGHT", -24, 10)
    local previewChild = CreateFrame("Frame", nil, previewScroll)
    self.livePreviewChild = previewChild
    previewChild:SetSize(previewW - 42, 1)
    previewScroll:SetScrollChild(previewChild)

    local previewText = previewChild:CreateFontString(nil, "OVERLAY")
    ApplyEditorFont(previewText, false)
    previewText:SetTextColor(1, 1, 1, 1)
    self.parsedPreview = previewText
    previewText:SetPoint("TOPLEFT", 0, 0)
    previewText:SetPoint("TOPRIGHT", 0, 0)
    previewText:SetJustifyH("LEFT")
    previewText:SetJustifyV("TOP")
    previewText:SetWordWrap(true)
    if previewText.SetSpacing then previewText:SetSpacing(4) end

    local editorY = y - 112
    local tldrInset, tldrEB = CreateMultilineEditor(content, FORM_X, editorY, mainW, 100)
    local abInset, abilitiesEB = CreateMultilineEditor(content, FORM_X, editorY, mainW, 100)
    local tipsInset, tipsEB = CreateMultilineEditor(content, FORM_X, editorY, mainW, 100)
    self.tldrInset, self.tldrEB = tldrInset, tldrEB
    self.abilitiesInset, self.abilitiesEB = abInset, abilitiesEB
    self.tipsInset, self.tipsEB = tipsInset, tipsEB
    for _, inset in ipairs({ tldrInset, abInset, tipsInset }) do
        inset:ClearAllPoints()
        inset:SetPoint("TOPLEFT", content, "TOPLEFT", FORM_X, editorY)
        inset:SetPoint("BOTTOMRIGHT", actionBar, "TOPLEFT", mainW, 8)
    end

    local function FormChanged() ED:HandleFormChanged() end
    for _, editBox in ipairs({ self.nameEB, self.dungeonEB, self.encIdEB,
        tldrEB, abilitiesEB, tipsEB }) do
        editBox:HookScript("OnTextChanged", FormChanged)
    end
    self.activeTab = "TLDR"
    self:SetActiveTab("TLDR")

    -- ── Buttons (two clean rows inside the fixed action bar) ──
    local function MakeButton(text, width, anchorTo, handler)
        local btn = CreateFrame("Button", nil, actionBar, "UIPanelButtonTemplate")
        btn:SetSize(width, 22)
        btn:SetText(text)
        if anchorTo then
            btn:SetPoint("LEFT", anchorTo, "RIGHT", 5, 0)
        else
            btn:SetPoint("BOTTOMLEFT", actionBar, "BOTTOMLEFT", 8, 5)
        end
        btn:SetScript("OnClick", handler)
        return btn
    end

    self.saveBtn    = MakeButton(BT:L("BTN_SAVE"), 80, nil, function() ED:Save() end)
    self.revertBtn  = MakeButton(BT:L("BTN_REVERT"), 110, self.saveBtn, function() ED:Revert() end)
    self.deleteBtn  = MakeButton(BT:L("BTN_DELETE"), 75, self.revertBtn, function() ED:Delete() end)
    self.newBtn     = MakeButton(BT:L("BTN_NEW"), 90, self.deleteBtn, function() ED:RequestSelection(nil) end)
    self.previewBtn = MakeButton(BT:L("BTN_PREVIEW"), 110, self.newBtn, function() ED:Preview() end)

    -- Second row: import/export (module loads after this file — resolve at click)
    self.exportBtn = CreateFrame("Button", nil, actionBar, "UIPanelButtonTemplate")
    self.exportBtn:SetSize(120, 22)
    self.exportBtn:SetText(BT:L("BTN_EXPORT"))
    self.exportBtn:SetPoint("TOPLEFT", actionBar, "TOPLEFT", 8, -5)
    self.exportBtn:SetScript("OnClick", function()
        if BT.ImportExport then BT.ImportExport:ExportBoss(ED.selectedKey) end
    end)
    self.exportAllBtn = MakeButton(BT:L("BTN_EXPORT_ALL"), 145, self.exportBtn, function()
        if BT.ImportExport then BT.ImportExport:ExportAll() end
    end)
    self.importBtn = MakeButton(BT:L("BTN_IMPORT"), 90, self.exportAllBtn, function()
        if BT.ImportExport then BT.ImportExport:ShowImportDialog() end
    end)

    f:SetScript("OnShow", function()
        ED:ApplyWorkspaceFonts()
        ED:RefreshList()
        ED:UpdateButtons()
    end)
    f:SetScript("OnHide", function()
        if ED.dirty and not ED._allowHide then
            C_Timer.After(0, function()
                f:Show()
                ED:PromptUnsaved(function()
                    ED._allowHide = true
                    f:Hide()
                end)
            end)
        else
            ED._allowHide = false
        end
    end)
    if f.CloseButton then
        f.CloseButton:SetScript("OnClick", function() ED:RequestClose() end)
    end
    self:FillForm(self.selectedKey)
    if Theme then
        Theme:StyleWindow(f)
        Theme:StyleAddonTree(f)
        Theme:StyleTitle(self.livePreviewTitle)
        Theme:LayoutButtonBar(actionBar,
            { self.saveBtn, self.revertBtn, self.deleteBtn, self.newBtn, self.previewBtn,
              self.exportBtn, self.exportAllBtn, self.importBtn },
            math.max(320, actionBar:GetWidth() or 600),
            { buttonOptions = { compact = true }, minHeight = 58 })
    end
    f:Hide()
    return f
end

function ED:GetActiveEditBox()
    if self.activeTab == "ABILITIES" then return self.abilitiesEB end
    if self.activeTab == "TIPS" then return self.tipsEB end
    return self.tldrEB
end

function ED:UpdateMetaButtons()
    if not self.seasonBtn or not self.typeBtn then return end
    local seasonKey = self.formSeason == 2 and "ED_SEASON_2"
        or (self.formSeason == 1 and "ED_SEASON_1" or "ED_SEASON_OTHER")
    self.seasonBtn:SetText(BT:L(seasonKey))
    self.typeBtn:SetText(BT:L(self.formIsRaid and "ED_TYPE_RAID" or "ED_TYPE_DUNGEON"))
end

function ED:SetActiveTab(tab)
    if tab ~= "TLDR" and tab ~= "ABILITIES" and tab ~= "TIPS" then tab = "TLDR" end
    self.activeTab = tab
    if self.livePreviewScroll then self.livePreviewScroll:SetVerticalScroll(0) end

    if self.tldrInset then self.tldrInset:SetShown(tab == "TLDR") end
    if self.abilitiesInset then self.abilitiesInset:SetShown(tab == "ABILITIES") end
    if self.tipsInset then self.tipsInset:SetShown(tab == "TIPS") end

    for key, button in pairs(self.tabButtons or {}) do
        button:SetEnabled(key ~= tab)
        if Theme then Theme:SetSelected(button, key == tab) end
    end

    local hintKeys = {
        TLDR = "ED_TLDR_HINT",
        ABILITIES = "ED_AB_HINT",
        TIPS = "ED_TIPS_HINT",
    }
    if self.formatHint then self.formatHint:SetText(BT:L(hintKeys[tab])) end

    for key, chips in pairs(self.chipsByTab or {}) do
        local chipX, chipY = 0, 0
        for _, chip in ipairs(chips) do
            chip:ClearAllPoints()
            if key == tab then
                local chipW = chip:GetWidth()
                if chipX > 0 and chipX + chipW > (self.mainW or 400) then
                    chipX = 0
                    chipY = -24
                end
                chip:SetPoint("TOPLEFT", self.chipBar, "TOPLEFT", chipX, chipY)
                chip:Show()
                chipX = chipX + chipW + 4
            else
                chip:Hide()
            end
        end
    end

    self:UpdateParsedPreview()
end

function ED:UpdateParsedPreview()
    if not self.parsedPreview then return end

    local name = strtrim(self.nameEB and self.nameEB:GetText() or "")
    self.liveBossTitle:SetText(name ~= "" and name or BT:L("ED_NEW_BOSS_LABEL"))
    local subtitle = {}
    local dungeon = strtrim(self.dungeonEB and self.dungeonEB:GetText() or "")
    if dungeon ~= "" then subtitle[#subtitle + 1] = dungeon end
    local seasonKey = self.formSeason == 2 and "ED_SEASON_2"
        or (self.formSeason == 1 and "ED_SEASON_1" or "ED_SEASON_OTHER")
    subtitle[#subtitle + 1] = BT:L(seasonKey)
    subtitle[#subtitle + 1] = BT:L(self.formIsRaid and "ED_TYPE_RAID" or "ED_TYPE_DUNGEON")
    local encID = strtrim(self.encIdEB and self.encIdEB:GetText() or "")
    if encID ~= "" then subtitle[#subtitle + 1] = "ID " .. encID end
    self.liveSubtitle:SetText(table.concat(subtitle, "  •  "))

    local modeKeys = {
        TLDR = "ED_TAB_TLDR",
        ABILITIES = "ED_TAB_ABILITIES",
        TIPS = "ED_TAB_TIPS",
    }
    self.liveMode:SetText(BT:L(modeKeys[self.activeTab] or "ED_TAB_TLDR"))

    local function ResizePreview()
        if not ED.livePreviewChild or not ED.parsedPreview then return end
        local textH = ED.parsedPreview:GetStringHeight() or 1
        local viewH = ED.livePreviewScroll and ED.livePreviewScroll:GetHeight() or 1
        ED.livePreviewChild:SetHeight(math.max(textH + 8, viewH))
    end

    if self.formError then
        self.parsedPreview:SetText(self.formError)
        ResizePreview()
        return
    end

    local lines = {}
    if self.activeTab == "ABILITIES" then
        local abilities = ParseAbilitiesText(self.abilitiesEB and self.abilitiesEB:GetText() or "")
        for _, ability in ipairs(abilities) do
            local title = C.FormatAbilityTitle(ability)
            if ability.phase ~= nil then
                title = title .. "  |cff999999[P" .. tostring(ability.phase) .. "]|r"
            end
            local description = BT:Localize(ability.description) or ""
            lines[#lines + 1] = title
                .. (description ~= "" and ("\n|cffdddddd" .. description .. "|r") or "")
        end
    elseif self.activeTab == "TIPS" then
        local tips, affixTips = ParseTipsText(self.tipsEB and self.tipsEB:GetText() or "")
        for _, tip in ipairs(tips) do
            lines[#lines + 1] = "|cff66b3ff•|r  " .. (BT:Localize(tip) or "")
        end
        local affixes = {}
        for affix in pairs(affixTips) do affixes[#affixes + 1] = affix end
        table.sort(affixes, function(a, b) return tostring(a) < tostring(b) end)
        for _, affix in ipairs(affixes) do
            for _, tip in ipairs(affixTips[affix] or {}) do
                lines[#lines + 1] = "|cffffcc00" .. tostring(affix) .. ":|r "
                    .. (BT:Localize(tip) or "")
            end
        end
    else
        local bullets = ParseTldrText(self.tldrEB and self.tldrEB:GetText() or "")
        for _, bullet in ipairs(bullets) do
            local bulletText, difficulty = C.ResolveTLDRBullet(bullet)
            local role, clean = C.ParseTLDRRole(bulletText)
            lines[#lines + 1] = C.FormatBullet({
                text = clean, role = role, difficulty = difficulty,
            })
        end
    end

    self.parsedPreview:SetText(lines[1] and table.concat(lines, "\n\n")
        or BT:L("ED_PREVIEW_EMPTY"))
    ResizePreview()
    C_Timer.After(0, ResizePreview)
end

-- ─── Boss list (shared widget — see Components.CreateBossList) ──────────────

function ED:RefreshList()
    if not self.bossList then return end
    self.bossList.selectedKey = self.selectedKey
    self.bossList:Refresh()
end

-- ─── Form ───────────────────────────────────────────────────────────────────

--- Fill the form for a boss key, or clear it for a new boss (key = nil).
function ED:FillForm(key)
    local data = key and BT_BossData and BT_BossData[key]
    if key and not data then key = nil end
    self.selectedKey = key
    self._loadingForm = true
    self.formError = nil

    if data then
        self.nameEB:SetText(key)
        self.dungeonEB:SetText(C.ResolveDungeonName(data) or "")
        self.encIdEB:SetText(data.encounterID and tostring(data.encounterID) or "")
        self.formSeason = C.ResolveSeason(data) or 0
        self.formIsRaid = data.isRaid and true or false
        self.tldrEB:SetText(TldrToText(data.tldr))
        self.abilitiesEB:SetText(AbilitiesToText(data.abilities))
        self.tipsEB:SetText(TipsToText(data.tips, data.affixTips))
    else
        self.nameEB:SetText("")
        self.dungeonEB:SetText("")
        self.encIdEB:SetText("")
        self.formSeason = 2
        self.formIsRaid = false
        self.tldrEB:SetText("")
        self.abilitiesEB:SetText("")
        self.tipsEB:SetText("")
    end

    self:UpdateMetaButtons()
    self._baselineSignature = self:GetFormSignature()
    self._loadingForm = false
    self:SyncDirty()
    self:SetActiveTab(self.activeTab or "TLDR")
    self:UpdateButtons()
    self:RefreshList()
end

function ED:UpdateButtons()
    if not self.window then return end
    local key = self.selectedKey
    local data = key and BT_BossData and BT_BossData[key]
    local isCustom = data and data.isCustom and true or false
    local isOverride = key and BT.db and BT.db.customBosses
        and BT.db.customBosses[key] and BT._originalFields[key] and true or false

    self.revertBtn:SetEnabled(isOverride)
    self.deleteBtn:SetEnabled(isCustom)
    self.previewBtn:SetEnabled(data and true or false)
    -- Name is the data key: editable only for new or custom bosses
    self.nameEB:SetEnabled((not key or isCustom) and true or false)
    self:SetDirty(self.dirty)
end

-- ─── Actions ────────────────────────────────────────────────────────────────

function ED:Save()
    local db = BT.db
    if not db then return false end

    local name = strtrim(self.nameEB:GetText() or "")
    if name == "" then
        local message = BT:L("ED_ERR_NAME_EMPTY")
        self:SetFormError(message)
        print(message)
        return false
    end

    local key = self.selectedKey
    local isNew = key == nil
    local isRename = key ~= nil and key ~= name

    if (isNew or isRename) and BT_BossData and BT_BossData[name] then
        local message = string.format(BT:L("ED_ERR_DUPLICATE"), name)
        self:SetFormError(message)
        print(message)
        return false
    end

    local encText = strtrim(self.encIdEB:GetText() or "")
    local encID
    if encText ~= "" then
        encID = tonumber(encText)
        if not encID then
            local message = BT:L("ED_ERR_ENCID")
            self:SetFormError(message)
            print(message)
            return false
        end
    end

    db.customBosses = db.customBosses or {}

    -- Rename: only possible for custom bosses (name field disabled otherwise)
    if isRename then
        db.customBosses[key] = nil
        if BT_BossData then BT_BossData[key] = nil end
        key = name
    elseif isNew then
        key = name
    end

    local tips, affixTips = ParseTipsText(self.tipsEB:GetText())
    local custom = {
        tldr      = ParseTldrText(self.tldrEB:GetText()),
        abilities = ParseAbilitiesText(self.abilitiesEB:GetText()),
        tips      = tips,
        affixTips = affixTips,
        isRaid    = self.formIsRaid and true or false,
    }
    if self.formSeason == 1 or self.formSeason == 2 then custom.season = self.formSeason end
    local dungeon = strtrim(self.dungeonEB:GetText() or "")
    if dungeon ~= "" then custom.dungeonName = dungeon end
    if encID then custom.encounterID = encID end

    -- Built-in target = has (or will get) an original snapshot; else custom
    local isBuiltin = BT._originalFields[key] ~= nil
        or (BT_BossData and BT_BossData[key] and not BT_BossData[key].isCustom)
    if not isBuiltin then
        custom.isCustom = true
    end

    db.customBosses[key] = custom
    BT:ApplyCustomBosses()
    BT:RebuildIndexes()

    self.selectedKey = key
    self:FillForm(key)
    print(string.format(BT:L("ED_SAVED"), key))
    return true
end

--- Restore a built-in boss to its shipped data (drops the override).
function ED:Revert()
    local key = self.selectedKey
    local db = BT.db
    if not key or not db or not db.customBosses or not db.customBosses[key] then return end
    if not BT._originalFields[key] then return end   -- not a built-in override

    db.customBosses[key] = nil
    BT_BossData[key] = CopyTable(BT._originalFields[key])
    BT._originalFields[key] = nil
    BT:RebuildIndexes()

    self:FillForm(key)
    print(string.format(BT:L("ED_REVERTED"), key))
end

--- Delete a fully custom boss (built-ins can only be reverted).
function ED:Delete()
    local key = self.selectedKey
    local data = key and BT_BossData and BT_BossData[key]
    if not data or not data.isCustom then return end

    BT.db.customBosses[key] = nil
    BT_BossData[key] = nil
    BT:RebuildIndexes()

    self:FillForm(nil)
    print(string.format(BT:L("ED_DELETED"), key))
end

--- Show the selected boss in the mini panel via test mode.
function ED:Preview()
    if self.selectedKey then
        BT.MiniPanel:PreviewBoss(self.selectedKey)
    end
end

-- ─── Entry point ────────────────────────────────────────────────────────────

--- /bosstactics edit [boss] and the options window button. Blocked in combat.
function BT:OpenEditor(bossKey)
    if InCombatLockdown() then
        print(self:L("ERR_IN_COMBAT"))
        return
    end
    local w = ED:GetWindow()
    if w:IsShown() and not bossKey then
        ED:RequestClose()
        return
    end
    w:Show()
    if bossKey and BT_BossData and BT_BossData[bossKey] then
        ED:RequestSelection(bossKey)
    end
end
