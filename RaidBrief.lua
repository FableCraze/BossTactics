-- RaidBrief.lua  (Boss Tactics)
-- Raid Brief window: one boss at a time, plain-text tactics with role-colored
-- lines. Content comes from BT_RaidBriefData defaults and is user-editable
-- per boss (overrides live in BossTacticsDB.raidBriefs[bossKey]).
--
-- Line markup (shared conventions with the TLDR parser):
--   TANQUE: / CURADOR: / DPS: / INTERROMPER: -> linha colorida por função
--   "## text"                     -> section header
--   anything else                 -> plain bullet line

local BT = BossTactics
local C = BT.Components
local Theme = BT.Theme
local RB = {}
BT.RaidBrief = RB

local WINDOW_W, WINDOW_H = 600, 560

local LINE_COLORS = {
    TANQUE = "|cff4fa8ff",
    CURADOR = "|cff4fd15a",
    INTERROMPER = "|cffffcc00",
    TANK   = "|cff4fa8ff",
    HEAL   = "|cff4fd15a",
    DPS    = "|cffff8a4d",
    KICK   = "|cffffcc00",
    SOAK   = "|cffff9933",
    STACK  = "|cffff7ac8",
    SPREAD = "|cff33cccc",
}
local PREFIX_ORDER = { "TANQUE", "CURADOR", "DPS", "INTERROMPER" }
local HEADER_COLOR = "|cffb98ae8"
local PLAIN_COLOR  = "|cffd8d4c8"
local BULLET       = "\226\128\162 "   -- •

-- ─── Data access ────────────────────────────────────────────────────────────

--- Dungeon of a boss, English key (brief keys are English boss names).
local function DungeonOf(key)
    local data = BT_BossData and BT_BossData[key]
    local name = data and data.dungeonName
    if type(name) == "table" then name = name.en or name.enUS end
    return name
end

--- Every boss that has a brief, in curated order, plus user-added ones.
function RB:GetAllKeys()
    local keys, seen = {}, {}
    local data = BT_RaidBriefData
    for _, key in ipairs(data and data.order or {}) do
        keys[#keys + 1] = key
        seen[key] = true
    end
    -- User-edited briefs for bosses outside the curated order stay reachable.
    local db = BT.db
    if db and db.raidBriefs then
        for key in pairs(db.raidBriefs) do
            local base = key:match("^(.-)@") or key
            if not seen[base] then
                keys[#keys + 1] = base
                seen[base] = true
            end
        end
    end
    return keys
end

--- The list the window pages through. Inside a known instance it holds only
--- that instance's bosses, so the counter lines up with the mini panel;
--- everywhere else it is the full list.
function RB:GetKeys()
    local all = self:GetAllKeys()
    local dungeon = BT.Detection and BT.Detection.GetCurrentDungeonName
        and BT.Detection:GetCurrentDungeonName()
    if not dungeon then return all end

    local scoped = {}
    for _, key in ipairs(all) do
        if DungeonOf(key) == dungeon then scoped[#scoped + 1] = key end
    end
    return #scoped > 0 and scoped or all
end

function RB:GetDefault(key)
    local data = BT_RaidBriefData
    local entry = data and data.briefs and data.briefs[key]
    if type(entry) == "string" then return entry end
    if type(entry) == "table" then
        local loc = BT.CurrentLocale
        return entry[loc] or entry.enUS or entry.hrHR
    end
    return nil
end

--- Custom briefs are stored per boss and per language ("Boss@hrHR"): editing
--- the English text must not replace the Croatian one.
local function CustomKey(key)
    return key .. "@" .. tostring(BT.CurrentLocale or "enUS")
end

function RB:GetText(key)
    local db = BT.db
    local store = db and db.raidBriefs
    if store then
        local custom = store[CustomKey(key)]
        -- Guias sem sufixo e guias salvos sob idiomas antigos continuam acessíveis.
        if type(custom) ~= "string" or custom == "" then custom = store[key] end
        if type(custom) ~= "string" or custom == "" then
            for _, locale in ipairs({ "enUS", "deDE", "esES", "frFR", "ruRU", "hrHR" }) do
                custom = store[key .. "@" .. locale]
                if type(custom) == "string" and custom ~= "" then break end
            end
        end
        if type(custom) == "string" and custom ~= "" then return custom, true end
    end
    return self:GetDefault(key) or "", false
end

function RB:SetText(key, text)
    local db = BT.db
    if not db then return end
    db.raidBriefs = db.raidBriefs or {}
    text = strtrim(text or "")
    local default = strtrim(self:GetDefault(key) or "")
    db.raidBriefs[key] = nil                -- drop any pre-language leftover
    if text == "" or text == default then
        db.raidBriefs[CustomKey(key)] = nil  -- back to built-in default
    else
        db.raidBriefs[CustomKey(key)] = text
    end
end

-- ─── Rendering ──────────────────────────────────────────────────────────────

local function ColorizeLine(line)
    line = strtrim(line)
    if line == "" then return " " end
    local header = line:match("^##%s*(.+)$")
    if header then
        return HEADER_COLOR .. header .. "|r"
    end
    local prefix = line:match("^(%u+):")
    if prefix then
        local color = LINE_COLORS[prefix]
            or (prefix == "HEALER" and LINE_COLORS.HEAL)
            or (prefix == "INTERRUPT" and LINE_COLORS.KICK)
        if color then return color .. line .. "|r" end
    end
    return PLAIN_COLOR .. BULLET .. line .. "|r"
end

function RB:BuildRendered(text)
    local out = {}
    for line in tostring(text or ""):gmatch("[^\r\n]+") do
        out[#out + 1] = ColorizeLine(line)
    end
    return table.concat(out, "\n")
end

-- ─── Window ─────────────────────────────────────────────────────────────────

function RB:CurrentKey()
    return self.keys and self.keys[self.index or 1]
end

function RB:Select(index)
    local total = #self.keys
    if total == 0 then return end
    if index < 1 then index = total elseif index > total then index = 1 end
    self.index = index
    self:SetEditing(false)
    self:Refresh()
end

function RB:Refresh()
    local f = self.window
    if not f then return end
    local key = self:CurrentKey()
    if not key then
        f.navTitle:SetText("--")
        f.text:SetText("")
        return
    end
    f.navTitle:SetText(string.format("%d / %d  \226\128\148  %s",
        self.index, #self.keys, key))
    local text, isCustom = self:GetText(key)
    if self.editing then
        f.viewInset:Hide()
        f.editInset:Show()
        f.editBox:SetText(text)
        local chips = {}
        for _, key in ipairs(PREFIX_ORDER) do
            chips[#chips + 1] = LINE_COLORS[key] .. key .. ":|r"
        end
        chips[#chips + 1] = HEADER_COLOR .. "## naslov|r"
        f.editHint:SetText(table.concat(chips, "   "))
    else
        f.editInset:Hide()
        f.viewInset:Show()
        if text == "" then
            f.text:SetText("|cff999999" .. BT:L("RB_EMPTY") .. "|r")
        else
            f.text:SetText(self:BuildRendered(text))
        end
        self:SyncViewHeight()
        f.scroll:SetVerticalScroll(0)
    end
    f.hintRow:SetShown(self.editing)
    f.customTag:SetShown(isCustom and not self.editing)
    f.editBtn:SetShown(not self.editing)
    f.copyBtn:SetShown(not self.editing)
    f.saveBtn:SetShown(self.editing)
    f.cancelBtn:SetShown(self.editing)
    f.resetBtn:SetShown(self.editing and self:GetDefault(key) ~= nil)
end

--- FontStrings have no OnSizeChanged; measure the rendered text explicitly
--- so the scroll range matches the content.
function RB:SyncViewHeight()
    local f = self.window
    if not f then return end
    local w = f.scroll:GetWidth()
    if w and w > 0 then
        f.text:SetWidth(w)
        f.scroll:GetScrollChild():SetWidth(w)
    end
    f.scroll:GetScrollChild():SetHeight((f.text:GetStringHeight() or 0) + 8)
end

--- Apply user options: whole-window scale, saved size and body font size.
-- ARIALN is the plain "chat" sans; per-locale font substitution keeps it
-- readable on ruRU/asian clients.
local BODY_FONT = "Fonts\\ARIALN.TTF"

--- Fonts offered in the options picker. All ship with every client and are
--- substituted per-locale (ruRU/zh/ko) automatically.
RB.FONT_CHOICES = {
    { file = "Fonts\\ARIALN.TTF",   label = "Arial Narrow" },
    { file = "Fonts\\FRIZQT__.TTF", label = "Friz Quadrata" },
    { file = "Fonts\\MORPHEUS.TTF", label = "Morpheus" },
    { file = "Fonts\\SKURRI.TTF",   label = "Skurri" },
}

function RB:ApplyLook()
    local f = self.window
    if not f then return end
    local db = BT.db
    f:SetScale((db and db.raidBriefScale) or 1.0)
    f:SetSize((db and db.raidBriefW) or WINDOW_W, (db and db.raidBriefH) or WINDOW_H)
    local size = (db and db.raidBriefFontSize) or 14
    local font = (db and db.raidBriefFont) or BODY_FONT
    f.text:SetFont(font, size, "")
    f.editBox:SetFont(font, size, "")
    self:SyncViewHeight()
end

function RB:SetEditing(editing)
    self.editing = editing and true or false
end

function RB:StartEdit(highlightForCopy)
    local f = self.window
    if not f then return end
    self:SetEditing(true)
    self:Refresh()
    f.editBox:SetFocus()
    if highlightForCopy then
        f.editBox:HighlightText()
        f.editBox:SetCursorPosition(0)
    end
end

function RB:SaveEdit()
    local key = self:CurrentKey()
    if key and self.window then
        self:SetText(key, self.window.editBox:GetText())
    end
    self:SetEditing(false)
    self:Refresh()
end

function RB:CancelEdit()
    self:SetEditing(false)
    self:Refresh()
end

function RB:ResetToDefault()
    local key = self:CurrentKey()
    if key then
        local db = BT.db
        if db and db.raidBriefs then
            db.raidBriefs[key] = nil
            db.raidBriefs[CustomKey(key)] = nil
        end
        if self.window then
            self.window.editBox:SetText(self:GetDefault(key) or "")
        end
    end
end

function RB:CreateWindow()
    local f = CreateFrame("Frame", "BossTacticsRaidBriefFrame", UIParent, "ButtonFrameTemplate")
    self.window = f
    f:SetSize(WINDOW_W, WINDOW_H)
    f:SetPoint("CENTER")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetResizable(true)
    if f.SetResizeBounds then
        f:SetResizeBounds(460, 380, 1000, 920)
    elseif f.SetMinResize then
        f:SetMinResize(460, 380)
        f:SetMaxResize(1000, 920)
    end
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:Hide()

    if f.SetTitle then
        f:SetTitle(BT:L("RB_TITLE"))
    elseif f.TitleText then
        f.TitleText:SetText(BT:L("RB_TITLE"))
    end
    local PORTRAIT_ICON = "Interface\\Icons\\INV_Misc_Note_06"
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

    tinsert(UISpecialFrames, "BossTacticsRaidBriefFrame")

    local content = CreateFrame("Frame", nil, f)
    if f.Inset then
        content:SetPoint("TOPLEFT", f.Inset, "TOPLEFT", 8, -8)
        content:SetPoint("BOTTOMRIGHT", f.Inset, "BOTTOMRIGHT", -8, 8)
    else
        content:SetPoint("TOPLEFT", 12, -62)
        content:SetPoint("BOTTOMRIGHT", -12, 12)
    end

    -- Nav row: ◀  i / n — Boss  ▶
    local nav = CreateFrame("Frame", nil, content)
    nav:SetPoint("TOPLEFT")
    nav:SetPoint("TOPRIGHT")
    nav:SetHeight(24)

    local prevBtn = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    prevBtn:SetSize(26, 22)
    prevBtn:SetPoint("LEFT")
    prevBtn:SetText("<")
    prevBtn:SetScript("OnClick", function() RB:Select((RB.index or 1) - 1) end)

    local nextBtn = CreateFrame("Button", nil, nav, "UIPanelButtonTemplate")
    nextBtn:SetSize(26, 22)
    nextBtn:SetPoint("RIGHT")
    nextBtn:SetText(">")
    nextBtn:SetScript("OnClick", function() RB:Select((RB.index or 1) + 1) end)

    f.navTitle = nav:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.navTitle:SetPoint("LEFT", prevBtn, "RIGHT", 8, 0)
    f.navTitle:SetPoint("RIGHT", nextBtn, "LEFT", -8, 0)
    f.navTitle:SetJustifyH("CENTER")

    f.customTag = nav:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.customTag:SetPoint("TOP", f.navTitle, "BOTTOM", 0, 1)
    f.customTag:SetText(BT:L("RB_CUSTOM_TAG"))

    -- Prefix palette on its own row, visible only while editing.
    local hintRow = CreateFrame("Frame", nil, content)
    f.hintRow = hintRow
    hintRow:SetPoint("TOPLEFT", nav, "BOTTOMLEFT", 0, -4)
    hintRow:SetPoint("TOPRIGHT", nav, "BOTTOMRIGHT", 0, -4)
    hintRow:SetHeight(16)
    hintRow:Hide()

    f.editHint = hintRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.editHint:SetPoint("LEFT", 2, 0)
    f.editHint:SetJustifyH("LEFT")

    local FOOTER = 30

    -- View mode: inset + scroll + one wrapped FontString
    local viewInset = CreateFrame("Frame", nil, content, "InsetFrameTemplate")
    f.viewInset = viewInset
    viewInset:SetPoint("TOPLEFT", nav, "BOTTOMLEFT", 0, -6)
    viewInset:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, FOOTER)

    local scroll = CreateFrame("ScrollFrame", nil, viewInset, "UIPanelScrollFrameTemplate")
    f.scroll = scroll
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(1, 1)
    scroll:SetScrollChild(child)

    f.text = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.text:SetPoint("TOPLEFT")
    f.text:SetJustifyH("LEFT")
    f.text:SetJustifyV("TOP")
    f.text:SetWordWrap(true)
    if f.text.SetSpacing then f.text:SetSpacing(4) end
    scroll:SetScript("OnSizeChanged", function(_, w)
        f.text:SetWidth(w)
        child:SetWidth(w)
        RB:SyncViewHeight()
    end)

    -- Edit mode: inset + scroll + multiline editbox
    local editInset = CreateFrame("Frame", nil, content, "InsetFrameTemplate")
    f.editInset = editInset
    editInset:SetPoint("TOPLEFT", hintRow, "BOTTOMLEFT", 0, -4)
    editInset:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, FOOTER)
    editInset:Hide()

    local esf = CreateFrame("ScrollFrame", nil, editInset, "UIPanelScrollFrameTemplate")
    esf:SetPoint("TOPLEFT", 8, -8)
    esf:SetPoint("BOTTOMRIGHT", -28, 8)

    local eb = CreateFrame("EditBox", nil, esf)
    f.editBox = eb
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject(ChatFontNormal)
    if eb.SetSpacing then eb:SetSpacing(3) end
    eb:SetScript("OnEscapePressed", function() RB:CancelEdit() end)
    esf:SetScrollChild(eb)
    esf:SetScript("OnSizeChanged", function(_, w) eb:SetWidth(w) end)
    esf:EnableMouse(true)
    esf:SetScript("OnMouseDown", function() eb:SetFocus() end)

    -- Footer buttons
    local function MakeButton(text, onClick)
        local btn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        btn:SetSize(96, 22)
        btn:SetText(text)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    f.editBtn = MakeButton(BT:L("RB_BTN_EDIT"), function() RB:StartEdit(false) end)
    f.editBtn:SetPoint("BOTTOMLEFT")
    f.copyBtn = MakeButton(BT:L("RB_BTN_COPY"), function() RB:StartEdit(true) end)
    f.copyBtn:SetPoint("LEFT", f.editBtn, "RIGHT", 6, 0)

    f.saveBtn = MakeButton(BT:L("BTN_SAVE"), function() RB:SaveEdit() end)
    f.saveBtn:SetPoint("BOTTOMLEFT")
    f.cancelBtn = MakeButton(BT:L("RB_BTN_CANCEL"), function() RB:CancelEdit() end)
    f.cancelBtn:SetPoint("LEFT", f.saveBtn, "RIGHT", 6, 0)
    f.resetBtn = MakeButton(BT:L("BTN_REVERT"), function() RB:ResetToDefault() end)
    f.resetBtn:SetPoint("BOTTOMRIGHT")
    f.resetBtn:SetWidth(140)

    -- Resize grip (bottom-right); saved size is reapplied on open
    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        local db = BT.db
        if db then
            db.raidBriefW = math.floor(f:GetWidth() + 0.5)
            db.raidBriefH = math.floor(f:GetHeight() + 0.5)
        end
        RB:SyncViewHeight()
    end)

    -- No legend in view mode: the colored prefix palette only matters while
    -- editing, and it already sits above the editor there.
    if Theme then
        Theme:StyleWindow(f)
        Theme:StyleAddonTree(f)
        Theme:StyleTitle(f.navTitle)
    end
end

--- Open the Raid Brief window, optionally on a specific boss key.
function BT:OpenRaidBrief(bossKey)
    if not RB.window then RB:CreateWindow() end
    RB.keys = RB:GetKeys()
    if #RB.keys == 0 then return end

    local index = RB.index or 1
    -- Explicit request, else the boss currently shown in the mini panel.
    local want = bossKey
    if not want and BT.MiniPanel and BT.MiniPanel.GetActiveDisplay then
        want = BT.MiniPanel:GetActiveDisplay()
    end
    if want then
        for i, key in ipairs(RB.keys) do
            if key == want or key:lower() == tostring(want):lower() then
                index = i
                break
            end
        end
    end
    RB.index = math.min(index, #RB.keys)
    RB:SetEditing(false)
    RB:ApplyLook()
    RB.window:Show()
    RB:Refresh()
end
