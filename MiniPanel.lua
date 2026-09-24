-- MiniPanel.lua  (Boss Tactics)
-- The core feature: an Objective-Tracker-style mini panel showing
-- role-filtered TLDR tactics for the current boss.
--
-- Design: dark readable backdrop by default, named font objects only, atlas
-- role icons, mouseover-only navigation and actions.
-- State: the panel owns its own currentBossKey/currentDungeon — synced with
-- Detection via explicit calls, never via shared mutable state.

local BT = BossTactics
local C = BT.Components
local D = BT.Detection
local Theme = BT.Theme

local MP = {}
BT.MiniPanel = MP

MP.currentBossKey = nil
MP.currentDungeon = nil
-- Session-only study filter selected in Journal. A live instance difficulty
-- always takes priority so the combat panel cannot show the wrong tactics.
MP.manualDifficulty = nil

-- Preview/test mode (never persisted — no DB writes, no kill tracking)
MP.testMode = false
MP._testSavedDifficulty = nil
MP._testBossList  = nil   -- all boss keys, sorted by dungeon + journal order
MP._testBossKey   = nil
MP._testSynthetic = nil   -- synthetic boss data when the DB has no rich boss
local NotifySettingsPanel

-- Layout constants (unscaled — user sizing goes through db.scale).
-- Width is user-configurable (db.panelWidth); the PanelWidth()/TextWidth()
-- getters replace the old fixed-width constants everywhere.
local PAD       = 6
local LINE_GAP  = 6
local FOOTER_H  = 50
local TAB_BAR_H = 24
local HEADER_FULL_CONTROLS_W = 116
local HEADER_MIN_CONTROLS_W  = 40
-- Boss nav (< >) sits at the right end of the subtitle row: the header never
-- moves, while the footer shifts with the amount of text on screen.
local HEADER_NAV_W = 38
local MIN_W, MAX_W, DEFAULT_W = 240, 440, 270
local DETAIL_MIN_W, DETAIL_MAX_W, DETAIL_DEFAULT_W = 360, 620, 420

local function PanelWidth()
    local db = BT.db or {}
    local detailed = db.detailsExpanded and not db.panelMinimized
    local w = detailed and (db.detailedPanelWidth or DETAIL_DEFAULT_W)
        or (db.panelWidth or DEFAULT_W)
    local minW = detailed and DETAIL_MIN_W or MIN_W
    local maxW = detailed and DETAIL_MAX_W or MAX_W
    if w < minW then w = minW end
    if w > maxW then w = maxW end
    return w
end

local function TextWidth()
    return PanelWidth() - PAD * 2
end

-- Chat prefill + channel resolve live in Components (shared with the journal)
local ResolveChannel = C.ResolveChannel

-- ─── Test mode helpers ──────────────────────────────────────────────────────

local function ResolveDungeonName(data)
    local dName = data and data.dungeonName
    if type(dName) == "table" then dName = dName.en or dName.enUS end
    return dName
end

local function NormalizeManualDifficulty(difficulty)
    if difficulty == "LFR" then return "NORMAL" end
    if difficulty == "NORMAL" or difficulty == "HEROIC" or difficulty == "MYTHIC" then
        return difficulty
    end
    return nil
end

--- All boss keys in the database, sorted by dungeon name then journal order.
local function BuildTestBossList()
    local keys = {}
    if not BT_BossData then return keys end
    for k, v in pairs(BT_BossData) do
        if type(k) == "string" and type(v) == "table" and v.tldr then
            keys[#keys + 1] = k
        end
    end
    table.sort(keys, function(a, b)
        local da, dbb = BT_BossData[a], BT_BossData[b]
        local na = ResolveDungeonName(da) or ""
        local nb = ResolveDungeonName(dbb) or ""
        if na ~= nb then return na < nb end
        -- journalOrder is the authoritative in-dungeon order; encounterIDs
        -- are not always assigned sequentially (e.g. Kings' Rest: Council of
        -- Tribes 2140 is fought after Mchimba 2142).
        local ea = da.journalOrder or da.encounterID or 999999
        local eb = dbb.journalOrder or dbb.encounterID or 999999
        if ea ~= eb then return ea < eb end
        return a < b
    end)
    return keys
end

--- Find a demo boss with rich TLDR. Ideal: all four role prefixes + at least
--- one difficulty-tagged bullet. No boss in the current database has all
--- four, so this scores candidates (distinct roles ×2 + diff tag) and takes
--- the best real boss. Deterministic (sorted list order). Returns nil only
--- when the database is empty — then the synthetic fallback is used.
local function FindDemoBossKey(sortedKeys)
    local bestKey, bestScore = nil, -1
    for _, k in ipairs(sortedKeys) do
        local roles = {}
        local roleCount = 0
        local hasDiff = false
        for _, b in ipairs(BT_BossData[k].tldr) do
            local text, diff = C.ResolveTLDRBullet(b)
            if diff then hasDiff = true end
            local role = C.ParseTLDRRole(text)
            if role ~= "general" and not roles[role] then
                roles[role] = true
                roleCount = roleCount + 1
            end
        end
        local score = roleCount * 2 + (hasDiff and 1 or 0)
        if roleCount == 4 and hasDiff then
            return k   -- the ideal boss — take it immediately
        end
        if score > bestScore then
            bestKey, bestScore = k, score
        end
    end
    return bestKey
end

--- Synthetic fallback: one bullet of every type + difficulty-tagged bullets.
local function BuildSyntheticTestBoss()
    return {
        dungeonName = "Boss Tactics",
        tldr = {
            "Leve as áreas perigosas para as bordas e preserve espaço na sala.",
            "TANQUE: use uma recarga defensiva no golpe forte.",
            "CURADOR: use uma recarga importante no dano de raide.",
            "DPS: cause dano explosivo durante a transição.",
            "INTERROMPER: interrompa o lançamento prioritário.",
            { text = "Somente no Normal.",  difficulty = "NORMAL" },
            { text = "Heroico ou superior.", difficulty = "HEROIC+" },
            { text = "Somente no Mítico.", difficulty = "MYTHIC" },
        },
    }
end

-- ─── Frame construction (once — refresh path never creates frames) ──────────

function MP:Create()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", nil, UIParent)
    self.frame = f
    f:SetSize(PanelWidth(), 80)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(false)   -- body is click-through, tracker-style

    -- Optional dark backdrop (default off)
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetColorTexture(0, 0, 0, 0.55)
    f.bg:SetPoint("TOPLEFT", -4, 4)
    f.bg:SetPoint("BOTTOMRIGHT", 4, -4)
    f.bg:Hide()

    -- Header drag region (whole header)
    local header = CreateFrame("Button", nil, f)
    f.header = header
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(30)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if not (BT.db and BT.db.locked) then
            f:StartMoving()
        end
    end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        MP:SavePosition()
    end)

    -- Title: boss name, gold, like a quest title in the tracker
    -- (width leaves room for role, abilities, minimize and close controls)
    f.title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    f.title:SetPoint("TOPLEFT", PAD, -2)
    f.title:SetWidth(TextWidth() - HEADER_FULL_CONTROLS_W)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    header:SetScript("OnEnter", function(h)
        local text = f.title:GetText()
        if text and f.title:GetStringWidth() > f.title:GetWidth() then
            GameTooltip:SetOwner(h, "ANCHOR_TOP")
            GameTooltip:SetText(text, 1, 0.82, 0)
            GameTooltip:Show()
        end
    end)
    header:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Subtitle: difficulty • X/Y • dungeon. Full width — the role button sits
    -- in the TITLE row, so this row below it can use the whole panel width.
    f.subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -2)
    f.subtitle:SetWidth(TextWidth() - HEADER_NAV_W)
    f.subtitle:SetJustifyH("LEFT")
    f.subtitle:SetWordWrap(false)

    local function MakeHeaderButton(label, tooltipKey, onClick)
        local btn = CreateFrame("Button", nil, header)
        btn:SetSize(16, 16)
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.label:SetPoint("CENTER")
        btn.label:SetText(label)
        btn._tooltipKey = tooltipKey
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.12)
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function(b)
            GameTooltip:SetOwner(b, "ANCHOR_TOP")
            GameTooltip:SetText(BT:L(b._tooltipKey), 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return btn
    end

    local closeBtn = MakeHeaderButton("X", "TOOLTIP_PANEL_CLOSE", function()
        MP:ClosePanel()
    end)
    f.closeBtn = closeBtn
    closeBtn:SetPoint("TOPRIGHT", -2, -1)
    closeBtn.label:SetTextColor(1, 0.35, 0.35, 1)

    local minimizeBtn = MakeHeaderButton("-", "TOOLTIP_PANEL_MINIMIZE", function()
        MP:ToggleMinimized()
    end)
    f.minimizeBtn = minimizeBtn
    minimizeBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -2, 0)

    -- Compact / Detailed mode toggle. A clear word replaces the old A+/A-
    -- shorthand, which looked like a font-size or minimize control.
    local detailsBtn = CreateFrame("Button", nil, header)
    f.detailsBtn = detailsBtn
    detailsBtn:SetSize(54, 16)
    detailsBtn:SetPoint("TOPRIGHT", minimizeBtn, "TOPLEFT", -2, 0)
    detailsBtn.icon = detailsBtn:CreateTexture(nil, "ARTWORK")
    detailsBtn.icon:SetSize(14, 14)
    detailsBtn.icon:SetPoint("CENTER")
    detailsBtn.icon:Hide()
    detailsBtn.label = detailsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detailsBtn.label:SetPoint("CENTER")
    detailsBtn.label:SetTextColor(1, 0.82, 0)
    local detailsHL = detailsBtn:CreateTexture(nil, "HIGHLIGHT")
    detailsHL:SetAllPoints()
    detailsHL:SetColorTexture(1, 1, 1, 0.12)
    detailsBtn:SetScript("OnClick", function() MP:ToggleDetails() end)
    detailsBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        local expanded = BT.db and BT.db.detailsExpanded
        GameTooltip:SetText(BT:L(expanded and "TOOLTIP_DETAILS_HIDE" or "TOOLTIP_DETAILS_SHOW"), 1, 1, 1)
        GameTooltip:Show()
    end)
    detailsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Role filter toggle: small role icon aligned with the title row
    local roleBtn = CreateFrame("Button", nil, header)
    f.roleBtn = roleBtn
    roleBtn:SetSize(16, 16)
    roleBtn:SetPoint("TOPRIGHT", detailsBtn, "TOPLEFT", -2, 0)
    roleBtn.icon = roleBtn:CreateTexture(nil, "ARTWORK")
    roleBtn.icon:SetSize(14, 14)
    roleBtn.icon:SetPoint("CENTER")
    roleBtn.label = roleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    roleBtn.label:SetPoint("CENTER")
    roleBtn:SetScript("OnClick", function() MP:CycleRoleFilter() end)
    roleBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        local filter = (BT.db and BT.db.roleFilter) or "ALL"
        local labelKey = C.ROLE_LABEL_KEYS[filter] or "ROLE_ALL_SHORT"
        GameTooltip:SetText(string.format(BT:L("TOOLTIP_ROLE_FILTER"), BT:L(labelKey)), 1, 1, 1)
        GameTooltip:Show()
    end)
    roleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Detailed mode navigation. Only one content family is visible at a time,
    -- keeping the panel readable instead of stacking every section vertically.
    local tabBar = CreateFrame("Frame", nil, f)
    f.tabBar = tabBar
    tabBar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", PAD, -2)
    tabBar:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
    tabBar:SetHeight(TAB_BAR_H)
    tabBar:Hide()
    f.tabs = {}

    local function MakeDetailsTab(key)
        local btn = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
        btn:SetHeight(20)
        btn._detailKey = key
        btn:SetScript("OnClick", function() MP:SetDetailsTab(key) end)
        f.tabs[key] = btn
        return btn
    end

    MakeDetailsTab("TLDR")
    MakeDetailsTab("ABILITIES")
    MakeDetailsTab("TIPS")
    MakeDetailsTab("TRASH")

    -- Boss nav on the subtitle row: fixed position, unlike the footer which
    -- moves up and down with the amount of text.
    local function MakeNavButton(label, tooltipKey, direction)
        local btn = CreateFrame("Button", nil, header)
        btn:SetSize(16, 16)
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.label:SetPoint("CENTER")
        btn.label:SetText(label)
        btn.label:SetTextColor(1, 0.82, 0)
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.12)
        btn:SetScript("OnClick", function() MP:Nav(direction) end)
        btn:SetScript("OnEnter", function(b)
            GameTooltip:SetOwner(b, "ANCHOR_TOP")
            GameTooltip:SetText(BT:L(tooltipKey), 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return btn
    end

    -- Anchored to the subtitle so they ride the second header line, not the
    -- title row where close/minimize live.
    f.prevBtn = MakeNavButton("<", "TOOLTIP_PREV_BOSS", -1)
    f.prevBtn:SetPoint("LEFT", f.subtitle, "RIGHT", 2, 0)
    f.nextBtn = MakeNavButton(">", "TOOLTIP_NEXT_BOSS", 1)
    f.nextBtn:SetPoint("LEFT", f.prevBtn, "RIGHT", 2, 0)

    -- Mouseover-only action footer. Controls no longer compete with the title.
    local footer = CreateFrame("Frame", nil, f)
    f.footer = footer
    footer:SetPoint("BOTTOMLEFT", 0, 2)
    footer:SetPoint("BOTTOMRIGHT", 0, 2)
    footer:SetHeight(FOOTER_H)
    footer:Hide()

    local controls = CreateFrame("Frame", nil, footer)
    f.controls = controls
    controls:SetPoint("BOTTOMLEFT", footer, "BOTTOMLEFT", 0, 0)
    controls:SetPoint("BOTTOMRIGHT", footer, "BOTTOMRIGHT", 0, 0)
    controls:SetHeight(20)

    -- Persistent quick controls on the first footer row. Trash controls the
    -- companion window; Tips controls whether tips appear in the Quick view.
    local quickControls = CreateFrame("Frame", nil, footer)
    f.quickControls = quickControls
    quickControls:SetPoint("TOPLEFT", footer, "TOPLEFT", PAD, 0)
    quickControls:SetPoint("TOPRIGHT", footer, "TOPRIGHT", -PAD, 0)
    quickControls:SetHeight(19)

    local function MakeQuickButton(tooltipKey, onClick)
        local btn = CreateFrame("Button", nil, quickControls, "UIPanelButtonTemplate")
        btn:SetHeight(18)
        btn._tooltipKey = tooltipKey
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function(b)
            GameTooltip:SetOwner(b, "ANCHOR_TOP")
            GameTooltip:SetText(BT:L(b._tooltipKey), 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        return btn
    end

    f.quickTrashBtn = MakeQuickButton("TOOLTIP_QUICK_TRASH", function()
        MP:ToggleTrashPanel()
    end)
    f.quickTrashBtn:SetPoint("TOPLEFT")

    f.quickTipsBtn = MakeQuickButton("TOOLTIP_QUICK_TIPS", function()
        MP:ToggleQuickTips()
    end)
    f.quickTipsBtn:SetPoint("TOPRIGHT")
    local initialQuickW = math.floor((TextWidth() - 3) / 2)
    f.quickTrashBtn:SetWidth(initialQuickW)
    f.quickTipsBtn:SetWidth(TextWidth() - initialQuickW - 3)

    -- Anchor helper frame at controls' right edge
    local anchor = CreateFrame("Frame", nil, controls)
    anchor:SetSize(1, 1)
    anchor:SetPoint("RIGHT", controls, "RIGHT", -20, 0)

    -- Journal (book) button — raid-leader flow: panel -> click -> journal
    local journalBtn = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    f.journalBtn = journalBtn
    journalBtn:SetSize(24, 18)
    journalBtn:SetText("|TInterface\\Icons\\INV_Misc_Book_09:12:12|t")
    journalBtn:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
    journalBtn:SetScript("OnClick", function()
        local bossKey, _, _, isTrash = MP:GetActiveDisplay()
        if isTrash then
            bossKey = MP.currentBossKey
                or (MP.currentDungeon and D:GetBossesForDungeon(MP.currentDungeon)[1])
            if BT.Journal then BT.Journal.view = "TRASH" end
        end
        BT:OpenJournal(bossKey, MP:GetDisplayDifficulty())
    end)
    journalBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        GameTooltip:SetText(BT:L("TOOLTIP_JOURNAL"), 1, 1, 1)
        GameTooltip:Show()
    end)
    journalBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Raid Brief (note) button, next to the Journal book
    local briefBtn = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    f.briefBtn = briefBtn
    briefBtn:SetSize(24, 18)
    briefBtn:SetText("|TInterface\\Icons\\INV_Misc_Note_06:12:12|t")
    briefBtn:SetPoint("RIGHT", journalBtn, "LEFT", -2, 0)
    briefBtn:SetScript("OnClick", function()
        BT:OpenRaidBrief(MP:GetActiveDisplay())
    end)
    briefBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        GameTooltip:SetText(BT:L("TOOLTIP_QUICK_BRIEF"), 1, 1, 1)
        GameTooltip:Show()
    end)
    briefBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local shareBtn = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    f.shareBtn = shareBtn
    shareBtn:SetSize(52, 18)
    shareBtn:SetText(BT:L("BTN_SHARE"))
    local shareFS = shareBtn:GetFontString()
    if shareFS then
        shareBtn:SetWidth(math.max(40, shareFS:GetStringWidth() + 16))
    end
    shareBtn:SetPoint("RIGHT", briefBtn, "LEFT", -2, 0)
    shareBtn:SetScript("OnClick", function() MP:ShareCurrentTab() end)
    shareBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        local ch = ResolveChannel()
        local mode = MP:GetShareMode()
        local tooltipKey = mode == "ABILITIES" and "TOOLTIP_SHARE_ABILITIES"
            or mode == "TIPS" and "TOOLTIP_SHARE_TIPS"
            or "TOOLTIP_SHARE_TLDR"
        GameTooltip:SetText(string.format(BT:L(tooltipKey), ch:lower()))
        GameTooltip:Show()
    end)
    shareBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local optionsBtn = CreateFrame("Button", nil, controls, "UIPanelButtonTemplate")
    f.optionsBtn = optionsBtn
    optionsBtn:SetSize(62, 18)
    optionsBtn:SetText(BT:L("BTN_OPTIONS"))
    local optionsFS = optionsBtn:GetFontString()
    if optionsFS then
        optionsBtn:SetWidth(math.max(54, optionsFS:GetStringWidth() + 16))
    end
    optionsBtn:SetPoint("RIGHT", shareBtn, "LEFT", -2, 0)
    optionsBtn:SetScript("OnClick", function() BT:OpenSettings() end)
    optionsBtn:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_TOP")
        GameTooltip:SetText(BT:L("TOOLTIP_OPTIONS"), 1, 1, 1)
        GameTooltip:Show()
    end)
    optionsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Scrollable body below the header. In TLDR-only mode the scroll region
    -- always matches the content height (no clipping, no mouse — identical to
    -- anchoring lines directly on the panel). The height cap + mousewheel
    -- activate only in expanded details mode.
    local scroll = CreateFrame("ScrollFrame", nil, f)
    f.scroll = scroll
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    scroll:SetPoint("RIGHT", f, "RIGHT", 0, 0)
    scroll:SetHeight(10)
    scroll:EnableMouseWheel(false)
    scroll:SetScript("OnMouseWheel", function(s, delta)
        local maxScroll = math.max(0, (f._contentH or 0) - s:GetHeight())
        local target = s:GetVerticalScroll() - delta * 30
        if target < 0 then target = 0 end
        if target > maxScroll then target = maxScroll end
        s:SetVerticalScroll(target)
    end)

    local content = CreateFrame("Frame", nil, scroll)
    f.content = content
    content:SetSize(PanelWidth(), 10)
    scroll:SetScrollChild(content)

    -- Separator between TLDR bullets and ability cards (expanded mode only)
    f.separator = content:CreateTexture(nil, "ARTWORK")
    f.separator:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    f.separator:SetHeight(1)
    f.separator:Hide()

    -- Pools — the refresh path only acquires/releases, never creates
    self.linePool = CreateFontStringPool(content, "ARTWORK", 0, "GameFontHighlight")
    self.cardPool = CreateFramePool("Frame", content)

    -- Resize grip (bottom-right, mouseover-only): manual X-axis drag — width
    -- only, height stays auto. Manual handler instead of StartSizing so it
    -- can't fight the SetHeight calls from Refresh. Respects db.locked.
    local grip = CreateFrame("Button", nil, f)
    f.grip = grip
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", 2, -2)
    grip:SetFrameLevel(f:GetFrameLevel() + 5)
    grip.tex = grip:CreateTexture(nil, "OVERLAY")
    grip.tex:SetAllPoints()
    grip.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip.tex:SetAlpha(0.6)
    grip:Hide()

    local resizeStartX, resizeStartW
    local resizeElapsed = 0
    grip:SetScript("OnMouseDown", function(g, btn)
        if btn ~= "LeftButton" then return end
        if BT.db and BT.db.locked then return end
        g._resizing = true
        resizeStartX = GetCursorPosition() / f:GetEffectiveScale()
        resizeStartW = f:GetWidth()
        resizeElapsed = 0
    end)
    grip:SetScript("OnMouseUp", function(g)
        if not g._resizing then return end
        g._resizing = false
        MP:ApplyWidth()   -- final clean re-layout at the released width
    end)
    grip:SetScript("OnUpdate", function(g, dt)
        if not g._resizing then return end
        resizeElapsed = resizeElapsed + dt
        if resizeElapsed < 0.05 then return end
        resizeElapsed = 0
        local cx = GetCursorPosition() / f:GetEffectiveScale()
        local detailed = BT.db and BT.db.detailsExpanded
        local minW = detailed and DETAIL_MIN_W or MIN_W
        local maxW = detailed and DETAIL_MAX_W or MAX_W
        local key = detailed and "detailedPanelWidth" or "panelWidth"
        local w = math.floor(resizeStartW + (cx - resizeStartX) + 0.5)
        if w < minW then w = minW end
        if w > maxW then w = maxW end
        if BT.db and w ~= BT.db[key] then
            BT.db[key] = w
            MP:ApplyWidth()
        end
    end)

    -- Hover watcher (throttled): show footer + grip only while the mouse is
    -- over the panel (grip stays while a resize drag is in progress).
    local elapsed = 0
    f:SetScript("OnUpdate", function(frame, dt)
        elapsed = elapsed + dt
        if elapsed < 0.1 then return end
        elapsed = 0
        local over = frame:IsMouseOver(6, -6, -6, 6)
        if over ~= frame._hovered then
            frame._hovered = over
            MP:ApplyHoverLayout()
        end
        local db = BT.db or {}
        grip:SetShown((over and not db.locked and not db.panelMinimized)
            or grip._resizing or false)
    end)

    f:Hide()
    if Theme then
        Theme:StyleSurface(f, "window", true)
        Theme:StyleAddonTree(f)
        Theme:StyleTitle(f.title)
    end
    self:ApplyPosition()
    self:ApplyLook()
    return f
end

-- ─── Position (single representation: {point, x, y}) ────────────────────────

function MP:ApplyHoverLayout()
    local f = self.frame
    if not f then return end
    local db = BT.db or {}
    local minimized = db.panelMinimized
    -- Detailed mode is an intentional study view, so its actions remain
    -- visible. Compact mode keeps the tracker-like mouseover footer.
    local show = not minimized and (db.detailsExpanded or f._hovered) and true or false
    if f.footer then f.footer:SetShown(show) end
    local extra = show and (FOOTER_H + 2) or 0
    f:SetHeight((f._baseHeight or 80) + extra)
end

function MP:ApplyPosition()
    local f = self.frame
    if not f then return end
    local pos = (BT.db and BT.db.position) or { point = "RIGHT", x = -80, y = 60 }
    f:ClearAllPoints()
    f:SetPoint(pos.point or "RIGHT", UIParent, pos.point or "RIGHT", pos.x or 0, pos.y or 0)
end

--- Normalize the dragged position to a TOPLEFT anchor (content grows down,
--- top edge stays fixed when the panel height changes) and save {point, x, y}.
function MP:SavePosition()
    local f = self.frame
    if not f or not BT.db then return end
    local left, top = f:GetLeft(), f:GetTop()
    if not left or not top then return end
    local fscale = f:GetEffectiveScale()
    local uscale = UIParent:GetEffectiveScale()
    -- Convert UIParent's top edge into this frame's coordinate space
    local y = top - (UIParent:GetTop() or 0) * uscale / fscale
    BT.db.position = { point = "TOPLEFT", x = left, y = y }
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", left, y)
end

function MP:ApplyLook()
    local f = self.frame
    if not f then return end
    local db = BT.db or {}
    f:SetScale(db.scale or 1.0)
    self:ApplyAlpha()
    f.bg:Hide()
    if f._btThemeBackground then
        local c = db.backdropColor
        local alpha = db.backdropMode and (c and c.a or 0.55) or 0
        f._btThemeBackground:SetColorTexture(0.063, 0.063, 0.063, alpha)
    end
end

--- Apply normal or combat opacity without changing the saved panel opacity.
function MP:ApplyAlpha()
    local f = self.frame
    if not f then return end
    local db = BT.db or {}
    local alpha = db.alpha or 1.0
    if db.combatFade and InCombatLockdown and InCombatLockdown() then
        alpha = db.combatAlpha or 0.55
    end
    f:SetAlpha(alpha)
end

--- Re-apply the configurable width to the frame and all header elements;
--- pooled line/card widths are re-set by the Refresh that follows.
function MP:ApplyWidth()
    local f = self.frame
    if not f then return end
    f:SetWidth(PanelWidth())
    local minimized = BT.db and BT.db.panelMinimized
    f.title:SetWidth(TextWidth()
        - (minimized and HEADER_MIN_CONTROLS_W or HEADER_FULL_CONTROLS_W))
    f.subtitle:SetWidth(TextWidth() - HEADER_NAV_W)
    f.content:SetWidth(PanelWidth())
    if f.quickTrashBtn and f.quickTipsBtn then
        local quickW = math.floor((TextWidth() - 3) / 2)
        f.quickTrashBtn:SetWidth(quickW)
        f.quickTipsBtn:SetWidth(TextWidth() - quickW - 3)
    end
    if f.tabBar and f.tabs then
        local tabW = math.floor((TextWidth() - 4) / 3)
        local ordered = { f.tabs.TLDR, f.tabs.ABILITIES, f.tabs.TIPS }
        for i, tab in ipairs(ordered) do
            tab:ClearAllPoints()
            tab:SetWidth(i == 3 and (TextWidth() - (tabW * 2) - 4) or tabW)
            if i == 1 then
                tab:SetPoint("TOPLEFT", f.tabBar, "TOPLEFT", 0, -1)
            else
                tab:SetPoint("LEFT", ordered[i - 1], "RIGHT", 2, 0)
            end
        end
    end
    self:Refresh()
end

-- ─── State ──────────────────────────────────────────────────────────────────

function MP:IsShown()
    return self.frame ~= nil and self.frame:IsShown()
end

--- Difficulty used by every mini-panel renderer/share path. In a live
--- instance Detection wins; outside an instance the Journal selection wins;
--- a fresh standalone panel defaults to Normal.
function MP:GetDisplayDifficulty()
    local _, data = self:GetActiveDisplay()
    return C.ResolveContentDifficulty(data,
        D.activeDifficulty or self.manualDifficulty or "NORMAL")
end

--- Update the session-only study filter without touching runtime detection or
--- SavedVariables. Used while comparing N/H/M tactics in the Journal.
function MP:SetManualDifficulty(difficulty)
    local normalized = NormalizeManualDifficulty(difficulty)
    if not normalized or normalized == self.manualDifficulty then return end
    self.manualDifficulty = normalized
    if self:IsShown() then self:Refresh() end
end

--- Set the active dungeon context. nil = outside any known instance.
function MP:SetDungeon(dungeonName)
    self.currentDungeon = dungeonName
    if dungeonName and self.currentBossKey
        and not D:BossBelongsToDungeon(self.currentBossKey, dungeonName) then
        self.currentBossKey = nil
    end
end

--- Update boss state without touching visibility (used while panel is hidden).
function MP:SetCurrentBoss(bossKey)
    if not bossKey or not (BT_BossData and BT_BossData[bossKey]) then return end
    self.currentBossKey = bossKey
    local dName = ResolveDungeonName(BT_BossData[bossKey])
    if dName then self.currentDungeon = dName end
    if BT.db then BT.db.lastBossKey = bossKey end
end

-- ─── Show / hide ────────────────────────────────────────────────────────────

function MP:ShowBoss(bossKey, difficulty)
    if not bossKey or not (BT_BossData and BT_BossData[bossKey]) then return end
    local normalized = NormalizeManualDifficulty(difficulty)
    if normalized then self.manualDifficulty = normalized end
    self:CancelAutoHide()
    self:Create()
    self:SetCurrentBoss(bossKey)
    if BT.db then BT.db.panelShown = true end
    self.frame:Show()
    self:Refresh()
    if NotifySettingsPanel then NotifySettingsPanel() end
end

--- Show the first unkilled boss of a dungeon (all killed -> last boss).
function MP:ShowFirstUnkilled(dungeonName)
    local bosses = D:GetBossesForDungeon(dungeonName)
    if #bosses == 0 then return end
    local target
    for _, bk in ipairs(bosses) do
        if not D:IsBossKilled(bk) then
            target = bk
            break
        end
    end
    self:ShowBoss(target or bosses[#bosses])
end

--- @param userInitiated boolean  true = remember the choice in panelShown
function MP:HidePanel(userInitiated)
    self:CancelAutoHide()
    if self.frame then self.frame:Hide() end
    if userInitiated and BT.db then
        BT.db.panelShown = false
    end
    if NotifySettingsPanel then NotifySettingsPanel() end
end

function MP:UpdateQuickButtons()
    local f = self.frame
    if not f or not f.quickTrashBtn or not f.quickTipsBtn then return end
    local trashShown = BT.TrashPanel and BT.TrashPanel:IsShown()
    local tipsShown = not (BT.db and BT.db.showQuickTips == false)
    f.quickTrashBtn:SetText(BT:L(trashShown and "QUICK_TRASH_ON" or "QUICK_TRASH_OFF"))
    f.quickTipsBtn:SetText(BT:L(tipsShown and "QUICK_TIPS_ON" or "QUICK_TIPS_OFF"))
    local trashFS = f.quickTrashBtn:GetFontString()
    local tipsFS = f.quickTipsBtn:GetFontString()
    if trashFS then
        trashFS:SetTextColor(trashShown and 0.35 or 0.65,
            trashShown and 1.00 or 0.65, trashShown and 0.45 or 0.65)
    end
    if tipsFS then
        tipsFS:SetTextColor(tipsShown and 0.35 or 0.65,
            tipsShown and 1.00 or 0.65, tipsShown and 0.45 or 0.65)
    end
end

function MP:ToggleTrashPanel()
    local panel = BT.TrashPanel
    if not panel then return end
    if panel:IsShown() then
        panel:Hide()
    else
        local dungeon = D:GetCurrentDungeonName() or self.currentDungeon
        if dungeon and BT_TrashData and BT_TrashData[dungeon] then
            panel:ShowDungeon(dungeon, self:GetDisplayDifficulty())
        else
            print(BT:L("ERR_NO_INSTANCE"))
        end
    end
    self:UpdateQuickButtons()
end

function MP:ToggleQuickTips()
    if not BT.db then return end
    BT.db.showQuickTips = BT.db.showQuickTips == false
    self:Refresh()
    if NotifySettingsPanel then NotifySettingsPanel() end
end

function MP:ClosePanel()
    if self.testMode then self:ExitTestMode(true) end
    self:HidePanel(true)
end

function MP:ToggleMinimized()
    local db = BT.db
    if not db then return end
    db.panelMinimized = not db.panelMinimized
    self:ApplyWidth()
end

function MP:UpdateMinimizeButton()
    local f = self.frame
    if not f or not f.minimizeBtn then return end
    local minimized = BT.db and BT.db.panelMinimized
    f.minimizeBtn.label:SetText(minimized and "+" or "-")
    f.minimizeBtn._tooltipKey = minimized
        and "TOOLTIP_PANEL_RESTORE" or "TOOLTIP_PANEL_MINIMIZE"
end

function MP:CancelAutoHide()
    self._autoHideToken = (self._autoHideToken or 0) + 1
end

function MP:ScheduleAutoHide(delay)
    self:CancelAutoHide()
    local token = self._autoHideToken
    C_Timer.After(tonumber(delay) or 8, function()
        if MP._autoHideToken ~= token or MP.testMode then return end
        MP:HidePanel(false)
    end)
end

function MP:Toggle()
    if self.testMode then
        self:ExitTestMode()
        return
    end
    if self:IsShown() then
        self:HidePanel(true)
        return
    end
    local db = BT.db or {}
    local dn = D:GetCurrentDungeonName()
    if dn then
        self:SetDungeon(dn)
        if db.lastBossKey and D:BossBelongsToDungeon(db.lastBossKey, dn) then
            self:ShowBoss(db.lastBossKey)
        else
            self:ShowFirstUnkilled(dn)
        end
    elseif db.lastBossKey and BT_BossData and BT_BossData[db.lastBossKey] then
        -- Outside a known instance: only an explicit last boss, never empty states
        self:ShowBoss(db.lastBossKey)
    else
        print(BT:L("ERR_NO_INSTANCE"))
    end
end

-- ─── Test / preview mode ────────────────────────────────────────────────────
-- Forces MYTHIC difficulty context (saved/restored — DB untouched), shows a
-- rich demo boss anywhere, nav cycles through ALL bosses in the database.

NotifySettingsPanel = function()
    local SP = BT.SettingsPanel
    if SP and SP.RefreshAll then SP:RefreshAll() end
end

function MP:EnterTestMode()
    if self.testMode then return end
    self:Create()
    self.testMode = true
    self._testSavedDifficulty = D.activeDifficulty
    D.activeDifficulty = "MYTHIC"

    self._testBossList = BuildTestBossList()
    local demo = FindDemoBossKey(self._testBossList)
    if demo then
        self._testBossKey = demo
        self._testSynthetic = nil
    else
        self._testBossKey = nil
        self._testSynthetic = BuildSyntheticTestBoss()
    end

    self.frame:Show()   -- direct Show — db.panelShown must stay untouched
    self:Refresh()
    NotifySettingsPanel()
end

--- @param skipRestore boolean  true = caller handles visibility (zone/encounter
--- handlers exit preview and then drive the panel themselves)
function MP:ExitTestMode(skipRestore)
    if not self.testMode then return end
    self.testMode = false
    D.activeDifficulty = self._testSavedDifficulty
    self._testSavedDifficulty = nil
    self._testBossList = nil
    self._testBossKey = nil
    self._testSynthetic = nil

    if not skipRestore then
        -- Return to real state: panel back if it was legitimately visible,
        -- hidden otherwise (outside a known instance = hidden, no empty states)
        local db = BT.db or {}
        local dn = D:GetCurrentDungeonName()
        if dn and db.panelShown then
            self:SetDungeon(dn)
            if db.lastBossKey and D:BossBelongsToDungeon(db.lastBossKey, dn) then
                self:ShowBoss(db.lastBossKey)
            else
                self:ShowFirstUnkilled(dn)
            end
        else
            self:HidePanel(false)
        end
    end
    NotifySettingsPanel()
end

function MP:ToggleTestMode()
    if self.testMode then
        self:ExitTestMode()
    else
        self:EnterTestMode()
    end
end

--- Preview a specific boss in the panel via the test mode mechanism
--- (used by the editor's Preview button). DB state stays untouched.
function MP:PreviewBoss(bossKey)
    if not bossKey or not (BT_BossData and BT_BossData[bossKey]) then return end
    if not self.testMode then
        self:EnterTestMode()
    end
    self._testBossList = BuildTestBossList()   -- may contain freshly saved bosses
    self._testSynthetic = nil
    self._testBossKey = bossKey
    self:Refresh()
end

--- The boss currently being displayed: (key, data, dungeonName).
--- Test mode reads test state; normal mode reads the panel's own state.
function MP:GetActiveDisplay()
    if self.testMode then
        if self._testSynthetic then
            return BT:L("TEST_BOSS"), self._testSynthetic, ResolveDungeonName(self._testSynthetic)
        end
        local key = self._testBossKey
        local data = key and BT_BossData and BT_BossData[key]
        return key, data, ResolveDungeonName(data)
    end
    local key = self.currentBossKey
    local data = key and BT_BossData and BT_BossData[key]
    return key, data, self.currentDungeon
end

-- ─── Navigation ─────────────────────────────────────────────────────────────

--- Prev/next boss with wraparound. Normal mode: inside the current dungeon.
--- Test mode: through ALL bosses in the database.
function MP:Nav(direction)
    if self.testMode then
        local list = self._testBossList
        if not list or #list == 0 then return end
        local currentIdx = 1
        for i, bk in ipairs(list) do
            if bk == self._testBossKey then
                currentIdx = i
                break
            end
        end
        local newIdx = currentIdx + direction
        if newIdx < 1 then newIdx = #list end
        if newIdx > #list then newIdx = 1 end
        self._testBossKey = list[newIdx]
        self._testSynthetic = nil
        self:Refresh()
        return
    end

    local dungeonName = self.currentDungeon
    if not dungeonName then return end
    local bosses = D:GetBossesForDungeon(dungeonName)
    if #bosses == 0 then return end

    local currentIdx = 1
    for i, bk in ipairs(bosses) do
        if bk == self.currentBossKey then
            currentIdx = i
            break
        end
    end

    local newIdx = currentIdx + direction
    if newIdx < 1 then newIdx = #bosses end
    if newIdx > #bosses then newIdx = 1 end

    self:ShowBoss(bosses[newIdx])
end

--- After a kill: advance to the next unkilled boss (wraparound search).
--- Updates state even while hidden so reopening lands on the right boss.
function MP:AdvanceToNextUnkilled()
    local dungeonName = self.currentDungeon
    local bosses = dungeonName and D:GetBossesForDungeon(dungeonName) or {}
    if #bosses == 0 then
        if self:IsShown() then self:Refresh() end
        return
    end

    local currentIdx = 1
    for i, bk in ipairs(bosses) do
        if bk == self.currentBossKey then
            currentIdx = i
            break
        end
    end

    for offset = 1, #bosses do
        local idx = ((currentIdx - 1 + offset) % #bosses) + 1
        local bk = bosses[idx]
        if not D:IsBossKilled(bk) then
            if self:IsShown() then
                self:ShowBoss(bk)
            else
                self:SetCurrentBoss(bk)
            end
            return
        end
    end

    -- All killed — refresh so the current boss shows its killed mark
    if self:IsShown() then self:Refresh() end
end

-- ─── Role filter ────────────────────────────────────────────────────────────

function MP:CycleRoleFilter()
    local db = BT.db
    if not db then return end
    local current = db.roleFilter or "ALL"
    local nextIdx = 1
    for i, r in ipairs(C.ROLE_CYCLE) do
        if r == current then
            nextIdx = (i % #C.ROLE_CYCLE) + 1
            break
        end
    end
    db.roleFilter = C.ROLE_CYCLE[nextIdx]
    self:Refresh()
end

function MP:UpdateRoleButton()
    local f = self.frame
    if not f then return end
    local filter = (BT.db and BT.db.roleFilter) or "ALL"
    local atlas = C.ROLE_ATLAS[filter]
    if atlas then
        f.roleBtn.icon:SetAtlas(atlas)
        f.roleBtn.icon:Show()
        f.roleBtn.label:SetText("")
    else
        f.roleBtn.icon:Hide()
        f.roleBtn.label:SetText(BT:L("ROLE_ALL_SHORT"))
    end
end

-- ─── Refresh (pooled — no frame creation in this path) ──────────────────────

local DETAIL_TABS = { "TLDR", "ABILITIES", "TIPS", "TRASH" }
local DETAIL_TAB_LABELS = {
    TLDR = "PANEL_TAB_QUICK",
    ABILITIES = "PANEL_TAB_ABILITIES",
    TIPS = "PANEL_TAB_TIPS",
    TRASH = "JN_SEC_TRASH",
}

local function CurrentDetailsTab()
    local tab = BT.db and BT.db.detailsTab or "ABILITIES"
    if tab ~= "TLDR" and tab ~= "ABILITIES" and tab ~= "TIPS" and tab ~= "TRASH" then
        tab = "ABILITIES"
    end
    return tab
end

function MP:GetShareMode()
    local expanded = BT.db and BT.db.detailsExpanded
    return expanded and CurrentDetailsTab() or "TLDR"
end

function MP:UpdateShareButton()
    local btn = self.frame and self.frame.shareBtn
    if not btn then return end
    local mode = self:GetShareMode()
    local expanded = BT.db and BT.db.detailsExpanded
    local labelKey = not expanded and "BTN_SHARE"
        or mode == "ABILITIES" and "BTN_SHARE_ABILITIES"
        or mode == "TIPS" and "BTN_SHARE_TIPS"
        or "BTN_SHARE_TLDR"
    btn:SetText(BT:L(labelKey))
    local fs = btn:GetFontString()
    local width = fs and (fs:GetStringWidth() + 16) or 52
    btn:SetWidth(math.max(46, math.min(expanded and 132 or 72, width)))
end

local function ResolveTipText(tip)
    if type(tip) == "table" then
        return BT:Localize(tip.text) or ""
    end
    return BT:Localize(tip) or ""
end

-- Active affixes take priority. Outside a live M+ key the configured groups
-- remain available for study, with their affix names shown explicitly.
local function BuildAffixGroups(data)
    local active = D:GetActiveAffixTips(data)
    if #active > 0 then return active end

    local groups = {}
    for key, tips in pairs((data and data.affixTips) or {}) do
        if type(tips) == "table" and #tips > 0 then
            groups[#groups + 1] = { id = key, name = tostring(key), tips = tips }
        end
    end
    table.sort(groups, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return groups
end

function MP:SetDetailsTab(tab)
    if not BT.db then return end
    if tab ~= "TLDR" and tab ~= "ABILITIES" and tab ~= "TIPS" and tab ~= "TRASH" then return end
    BT.db.detailsTab = tab
    self:Refresh()
end

function MP:UpdateDetailsTabs(counts)
    local f = self.frame
    if not f or not f.tabs then return end
    local current = CurrentDetailsTab()
    local gaps = (#DETAIL_TABS - 1) * 2
    local tabW = math.floor((TextWidth() - gaps) / #DETAIL_TABS)
    local previous
    for index, key in ipairs(DETAIL_TABS) do
        local btn = f.tabs[key]
        btn:ClearAllPoints()
        btn:SetWidth(index == #DETAIL_TABS
            and (TextWidth() - tabW * (#DETAIL_TABS - 1) - gaps) or tabW)
        if previous then
            btn:SetPoint("LEFT", previous, "RIGHT", 2, 0)
        else
            btn:SetPoint("TOPLEFT", f.tabBar, "TOPLEFT", 0, -1)
        end
        previous = btn
        btn:SetText(BT:L(DETAIL_TAB_LABELS[key]) .. " " .. tostring(counts[key] or 0))
        local fs = btn:GetFontString()
        if key == current then
            btn:LockHighlight()
            if fs then fs:SetTextColor(1, 0.82, 0) end
        else
            btn:UnlockHighlight()
            if fs then fs:SetTextColor(1, 1, 1) end
        end
        if Theme then Theme:SetSelected(btn, key == current) end
    end
end

function MP:Refresh()
    local f = self.frame
    if not f then return end
    local bossKey, data, dungeon, isTrash = self:GetActiveDisplay()
    if not data then
        if not self.testMode then
            self:HidePanel(false)
        end
        return
    end

    local db = BT.db or {}

    -- Fonts: base font objects + optional user face/size customization
    C.ApplyPanelFont(f.title, "title", GameFontNormalMed2 or GameFontNormal)
    C.ApplyPanelFont(f.subtitle, "small", GameFontHighlightSmall)

    -- Header
    f.title:SetText(bossKey or BT:L("UNKNOWN_BOSS"))

    -- Segment order: [TEST] • diff • X/Y • killed • dungeon — dungeon LAST so
    -- it truncates gracefully while counter and difficulty stay visible.
    local segs = {}
    if self.testMode then
        segs[#segs + 1] = "|cffff8800[TEST]|r"
    end
    local diff = self:GetDisplayDifficulty()
    if diff then
        local labelKey = C.DIFF_LABEL_KEYS[diff]
        local label = labelKey and BT:L(labelKey) or diff
        local color = C.DIFF_COLORS[diff]
        segs[#segs + 1] = color and (color .. label .. "|r") or label
    end
    if self.testMode then
        -- X/Y across the whole database (nav cycles all bosses in preview);
        -- no dungeon segment — the context is the whole database
        local list = self._testBossList
        if list and #list > 1 and self._testBossKey then
            local idx = 1
            for i, bk in ipairs(list) do
                if bk == self._testBossKey then idx = i break end
            end
            segs[#segs + 1] = idx .. "/" .. #list
        end
    else
        local bosses = dungeon and D:GetBossesForDungeon(dungeon) or {}
        if not isTrash and #bosses > 1 then
            local idx = 1
            for i, bk in ipairs(bosses) do
                if bk == bossKey then idx = i break end
            end
            segs[#segs + 1] = idx .. "/" .. #bosses
        end
        if not isTrash and D:IsBossKilled(bossKey) then
            segs[#segs + 1] = "|cff33cc33" .. BT:L("KILLED_LABEL") .. "|r"
        end
        if dungeon then
            segs[#segs + 1] = dungeon
        end
    end
    f.subtitle:SetText(table.concat(segs, " |cff666666\226\128\162|r "))

    local minimized = db.panelMinimized and true or false
    local expanded = db.detailsExpanded and true or false
    f:SetWidth(PanelWidth())
    f.content:SetWidth(PanelWidth())
    f.title:SetWidth(TextWidth()
        - (minimized and HEADER_MIN_CONTROLS_W or HEADER_FULL_CONTROLS_W))
    f.subtitle:SetShown(not minimized)
    f.detailsBtn:SetShown(not minimized)
    f.roleBtn:SetShown(not minimized)
    -- The nav rides the subtitle row, so it goes away with it.
    f.prevBtn:SetShown(not minimized)
    f.nextBtn:SetShown(not minimized)
    self:UpdateMinimizeButton()

    if minimized then
        self.linePool:ReleaseAll()
        self.cardPool:ReleaseAll()
        f.separator:Hide()
        f.tabBar:Hide()
        f.scroll:Hide()
        f.footer:Hide()
        f.grip:Hide()
        f._contentH = 0
        f.header:SetHeight(22)
        f._baseHeight = 22
        f:SetHeight(22)
        self:ApplyLook()
        return
    end
    f.scroll:Show()
    f.tabBar:SetShown(expanded)

    -- Measure header
    local titleH = f.title:GetStringHeight()
    if not titleH or titleH < 1 then titleH = 14 end
    local subH = f.subtitle:GetStringHeight()
    if not subH or subH < 1 then subH = 10 end
    local headerH = 2 + titleH + 2 + subH + 6
    f.header:SetHeight(headerH)

    -- Resolve all three content families once. Compact renders TLDR directly;
    -- Detailed renders only the selected tab and exposes the counts up front.
    local filtered = C.FilterTLDRBullets(data.tldr, diff, db.roleFilter)
    local abilities = C.FilterAbilities(data.abilities, diff, db.roleFilter)
    local affixGroups = BuildAffixGroups(data)
    local tips = data.tips or {}
    local trashData = dungeon and BT_TrashData and BT_TrashData[dungeon]
    local trashSummary = trashData
        and C.FilterTLDRBullets(trashData.summary, diff, db.roleFilter) or {}
    local trashEnemies = trashData
        and C.FilterAbilities(trashData.enemies, diff, db.roleFilter) or {}
    local affixTipCount = 0
    for _, group in ipairs(affixGroups) do
        affixTipCount = affixTipCount + #(group.tips or {})
    end
    if expanded then
        self:UpdateDetailsTabs({
            TLDR = #filtered,
            ABILITIES = #abilities,
            TIPS = #tips + affixTipCount,
            TRASH = #trashSummary,
        })
    end

    f.scroll:ClearAllPoints()
    if expanded then
        f.scroll:SetPoint("TOPLEFT", f.tabBar, "BOTTOMLEFT", -PAD, -2)
    else
        f.scroll:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT", 0, -2)
    end
    f.scroll:SetPoint("RIGHT", f, "RIGHT", 0, 0)

    local content = f.content
    self.linePool:ReleaseAll()
    self.cardPool:ReleaseAll()
    f.separator:Hide()

    local y = 0

    local function PlaceLine(text, fontKind, fontObject, gap)
        local fs = self.linePool:Acquire()
        fs:ClearAllPoints()
        C.ApplyPanelFont(fs, fontKind or "body", fontObject or GameFontHighlight)
        fs:SetWidth(TextWidth())
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("TOP")
        fs:SetWordWrap(true)
        fs:SetNonSpaceWrap(true)
        fs:SetText(text)
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
        fs:Show()
        local h = fs:GetStringHeight()
        if not h or h < 1 then h = 12 end
        y = y - h - (gap or LINE_GAP)
    end

    local function PlaceAbility(ab)
        local card = self.cardPool:Acquire()
        card:ClearAllPoints()
        if not card.title then
            card.title = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            card.title:SetPoint("TOPLEFT", 0, 0)
            card.title:SetJustifyH("LEFT")
            card.title:SetJustifyV("TOP")
            card.title:SetWordWrap(true)
            card.desc = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            card.desc:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -3)
            card.desc:SetJustifyH("LEFT")
            card.desc:SetJustifyV("TOP")
            card.desc:SetWordWrap(true)
            card.desc:SetNonSpaceWrap(true)
        end
        C.ApplyPanelFont(card.title, "body", GameFontHighlight)
        C.ApplyPanelFont(card.desc, "small", GameFontHighlightSmall)
        card.title:SetWidth(TextWidth())
        local phase = ab.phase and (" |cff66ccff" ..
            string.format(BT:L("JN_PHASE"), tostring(ab.phase)) .. "|r") or ""
        card.title:SetText(C.FormatAbilityTitle(ab) .. phase)
        card.desc:SetWidth(TextWidth())
        card.desc:SetText(BT:Localize(ab.description) or "")

        local cardTitleH = card.title:GetStringHeight()
        if not cardTitleH or cardTitleH < 1 then cardTitleH = 12 end
        local descH = card.desc:GetStringHeight()
        if not descH or descH < 1 then descH = 0 end
        local cardH = cardTitleH + (descH > 0 and (3 + descH) or 0)
        card:SetSize(TextWidth(), cardH)
        card:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
        card:Show()
        y = y - cardH - (LINE_GAP + 2)
    end

    local activeTab = expanded and CurrentDetailsTab() or "TLDR"
    if activeTab == "TLDR" then
        if #filtered == 0 then
            PlaceLine("|cff888888" .. BT:L("NO_TLDR_DATA") .. "|r")
        else
            local compactLimit = isTrash and not expanded and 3 or #filtered
            for index, entry in ipairs(filtered) do
                if index > compactLimit then break end
                PlaceLine(C.FormatBullet(entry))
            end
            if isTrash and not expanded and #filtered > compactLimit then
                PlaceLine(string.format("|cffffcc00%s|r",
                    string.format(BT:L("PANEL_SHOW_MORE"), #filtered - compactLimit)),
                    "small", GameFontHighlightSmall, 4)
            end
        end

        -- Compact mode can include a small practical-tip footer. Keep it to
        -- three entries so the quick panel remains useful; FULL/Tips
        -- continues to expose the complete list.
        if not expanded and db.showQuickTips ~= false and #tips > 0 then
            y = y - 1
            f.separator:ClearAllPoints()
            f.separator:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, y)
            f.separator:SetPoint("TOPRIGHT", content, "TOPRIGHT", -PAD, y)
            f.separator:Show()
            y = y - 7
            PlaceLine("|cffffcc00" .. BT:L("JN_SEC_TIPS") .. "|r",
                "small", GameFontNormalSmall, 4)
            local placedTips = 0
            for _, tip in ipairs(tips) do
                local text = ResolveTipText(tip)
                if text ~= "" then
                    PlaceLine("|cff66ccff\226\128\162|r  " .. text,
                        "small", GameFontHighlightSmall, 4)
                    placedTips = placedTips + 1
                    if placedTips >= 3 then break end
                end
            end
            if #tips > placedTips then
                PlaceLine(string.format("|cffffcc00%s|r",
                    string.format(BT:L("PANEL_SHOW_MORE"), #tips - placedTips)),
                    "small", GameFontHighlightSmall, 4)
            end
        end
    elseif activeTab == "ABILITIES" then
        if #abilities > 0 then
            for _, ab in ipairs(abilities) do
                PlaceAbility(ab)
            end
        else
            PlaceLine("|cff888888" .. BT:L("NO_ABILITIES_DATA") .. "|r")
        end
    elseif activeTab == "TRASH" then
        if #trashSummary == 0 and #trashEnemies == 0 then
            PlaceLine("|cff888888" .. BT:L("JN_NO_TRASH_DATA") .. "|r")
        else
            for _, entry in ipairs(trashSummary) do
                PlaceLine(C.FormatBullet(entry))
            end
            if #trashEnemies > 0 then
                y = y - 3
                PlaceLine("|cffffcc00" .. BT:L("JN_TRASH_ENEMIES") .. "|r",
                    "body", GameFontNormal, 4)
                for _, entry in ipairs(trashEnemies) do
                    PlaceAbility(entry)
                end
            end
        end
    else
        local placed = false
        for _, tip in ipairs(tips) do
            local text = ResolveTipText(tip)
            if text ~= "" then
                PlaceLine("|cff66ccff\226\128\162|r  " .. text)
                placed = true
            end
        end
        if #affixGroups > 0 then
            if placed then y = y - 2 end
            PlaceLine("|cffffcc00" .. BT:L("JN_SEC_AFFIXES") .. "|r", "body", GameFontNormal, 4)
            for _, group in ipairs(affixGroups) do
                PlaceLine("|cffffcc00" .. tostring(group.name or group.id or "") .. "|r",
                    "small", GameFontNormalSmall, 3)
                for _, tip in ipairs(group.tips or {}) do
                    local text = ResolveTipText(tip)
                    if text ~= "" then
                        PlaceLine("|cff999999\226\128\162|r  " .. text,
                            "small", GameFontHighlightSmall, 4)
                        placed = true
                    end
                end
            end
        end
        if not placed then
            PlaceLine("|cff888888" .. BT:L("NO_TIPS_DATA") .. "|r")
        end
    end

    -- Sizing: content always keeps its full height, but the visible region is
    -- capped to the screen in both compact and expanded mode. Previously only
    -- expanded mode enabled scrolling, so a long compact TLDR could extend
    -- below the screen and make its final bullets/tips unreachable.
    local contentH = -y
    f._contentH = contentH
    content:SetSize(PanelWidth(), math.max(contentH, 1))

    local scrollH = contentH
    local needScroll = false
    local scale = db.scale or 1.0
    local maxTotal = (UIParent:GetHeight() or 768) * 0.7 / scale
    local chromeH = headerH + PAD + 8
    if expanded then
        chromeH = chromeH + TAB_BAR_H + FOOTER_H
    end
    local maxScrollH = maxTotal - chromeH
    if scrollH > maxScrollH and maxScrollH > 40 then
        scrollH = maxScrollH
        needScroll = true
    end
    f.scroll:SetHeight(math.max(scrollH, 1))
    f.scroll:EnableMouseWheel(needScroll)
    f.scroll:SetVerticalScroll(0)

    local bodyTop = expanded and (TAB_BAR_H + 4) or 2
    f._baseHeight = headerH + bodyTop + scrollH + PAD
    self:ApplyHoverLayout()
    self:UpdateRoleButton()
    self:UpdateDetailsButton()
    self:UpdateShareButton()
    self:UpdateQuickButtons()
    self:ApplyLook()
end

-- ─── Details toggle (TLDR-only ⇄ TLDR + ability cards) ─────────────────────

function MP:ToggleDetails()
    local db = BT.db
    if not db then return end
    db.detailsExpanded = not db.detailsExpanded
    self:ApplyWidth()
end

function MP:UpdateDetailsButton()
    local f = self.frame
    if not f then return end
    local expanded = BT.db and BT.db.detailsExpanded
    f.detailsBtn.icon:Hide()
    f.detailsBtn.label:SetText(BT:L(expanded and "PANEL_MODE_COMPACT" or "PANEL_MODE_FULL"))
end

-- ─── Share current Compact/FULL tab ─────────────────────────────────────────

--- Build a single plain-text TLDR summary line for chat.
local ROLE_CHAT_PREFIX = {
    tank = "TANQUE: ", healer = "CURADOR: ", dps = "DPS: ", interrupt = "INTERROMPER: ",
}

function MP:ShareTLDR()
    local bossKey, data = self:GetActiveDisplay()
    if not data then return end

    local db = BT.db or {}
    local filtered = C.FilterTLDRBullets(data.tldr, self:GetDisplayDifficulty(), db.roleFilter)
    if #filtered == 0 then return end

    local parts = {}
    for _, entry in ipairs(filtered) do
        parts[#parts + 1] = (ROLE_CHAT_PREFIX[entry.role] or "") .. entry.text
    end
    C.SendChatParts(tostring(bossKey), parts, ResolveChannel())
end

local ABILITY_CHAT_ROLE_PREFIX = {
    TANK = "TANQUE: ", HEALER = "CURADOR: ", DPS = "DPS: ",
}

function MP:ShareAbilities()
    local bossKey, data = self:GetActiveDisplay()
    if not data then return end

    local db = BT.db or {}
    local abilities = C.FilterAbilities(data.abilities,
        self:GetDisplayDifficulty(), db.roleFilter)
    if #abilities == 0 then return end

    local parts = {}
    for _, ability in ipairs(abilities) do
        local title = BT:Localize(ability.title) or ""
        local description = BT:Localize(ability.description) or ""
        local diff = ability.difficulty and C.DIFF_SHORT[ability.difficulty]
        local prefix = ABILITY_CHAT_ROLE_PREFIX[ability.role] or ""
        if diff then prefix = prefix .. "[" .. diff .. "] " end
        if ability.phase then
            prefix = prefix .. "[" ..
                string.format(BT:L("JN_PHASE"), tostring(ability.phase)) .. "] "
        end
        if ability.type then prefix = prefix .. "[" .. ability.type .. "] " end
        local text = prefix .. title
        if description ~= "" then text = text .. ": " .. description end
        parts[#parts + 1] = text
    end
    C.SendChatParts(tostring(bossKey) .. " " .. BT:L("JN_SEC_ABILITIES"),
        parts, ResolveChannel())
end

function MP:ShareTips()
    local bossKey, data = self:GetActiveDisplay()
    if not data then return end

    local parts = {}
    for _, tip in ipairs(data.tips or {}) do
        local text = ResolveTipText(tip)
        if text ~= "" then parts[#parts + 1] = text end
    end

    -- Only active affixes are shared. Outside a live key FULL/Tips may show
    -- every prepared affix group for study; sharing all of those would create
    -- an unexpected wall of chat messages.
    for _, group in ipairs(D:GetActiveAffixTips(data)) do
        local name = tostring(group.name or group.id or BT:L("JN_SEC_AFFIXES"))
        for _, tip in ipairs(group.tips or {}) do
            local text = ResolveTipText(tip)
            if text ~= "" then parts[#parts + 1] = name .. ": " .. text end
        end
    end

    if #parts == 0 then return end
    C.SendChatParts(tostring(bossKey) .. " " .. BT:L("JN_SEC_TIPS"),
        parts, ResolveChannel())
end

function MP:ShareCurrentTab()
    local mode = self:GetShareMode()
    if mode == "ABILITIES" then
        self:ShareAbilities()
    elseif mode == "TIPS" then
        self:ShareTips()
    elseif mode == "TRASH" then
        local trash = self.currentDungeon and BT_TrashData
            and BT_TrashData[self.currentDungeon]
        local filtered = trash and C.FilterTLDRBullets(trash.summary,
            self:GetDisplayDifficulty(), (BT.db and BT.db.roleFilter) or "ALL") or {}
        local parts = {}
        for _, entry in ipairs(filtered) do
            parts[#parts + 1] = (ROLE_CHAT_PREFIX[entry.role] or "") .. entry.text
        end
        if #parts > 0 then
            C.SendChatParts(self.currentDungeon .. " " .. BT:L("JN_SEC_TRASH"),
                parts, ResolveChannel())
        end
    else
        self:ShareTLDR()
    end
end
