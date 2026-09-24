-- Core.lua  (Boss Tactics)
-- Bootstrap: event frame, DB defaults + merge, slash /bosstactics.
-- Core loop: enter dungeon -> panel shows first unkilled boss;
-- pull -> panel jumps to boss; kill -> auto-advance.

local ADDON_NAME = ...

BossTactics = BossTactics or {}
local BT = BossTactics
BT.ADDON_NAME = ADDON_NAME or BT.ADDON_NAME or "BossTactics"
BT.Config = BT.Config or {}
BT.Config.dungeonDifficultySelectionEnabled = false

-- ─── SavedVariables defaults ────────────────────────────────────────────────
-- Runtime context (detected difficulty, active instance) is NEVER stored here.
-- Only explicit user preferences + panel restore state.
local defaults = {
    schemaVersion   = 4,
    locale          = "ptBR",     -- idioma único; normalizado também em bancos migrados
    position        = { point = "RIGHT", x = -80, y = 60 },
    scale           = 1.0,
    alpha           = 1.0,
    locked          = false,
    backdropMode    = true,       -- subtle readable backdrop for new installs
    backdropColor   = { r = 0, g = 0, b = 0, a = 1.0 },
    panelWidth      = 270,        -- 240–440, slider + resize grip
    detailedPanelWidth = 480,     -- 360–620, separate width for the full view
    fontSize        = 15,
    roleFilter      = "ALL",      -- explicit user filter: ALL/TANK/HEALER/DPS
    autoShowOnEnter = true,
    autoAdvance     = true,
    combatFade      = false,
    combatAlpha     = 0.55,
    autoHideAfterEncounter = false,
    autoHideDelay   = 8,
    shareChannel    = "AUTO",
    shareSignature  = true,        -- append a short Boss Tactics credit to shares
    panelShown      = false,      -- /reload restore: was the panel visible
    panelMinimized  = false,      -- compact title bar; survives /reload
    detailsExpanded = true,       -- Detailed by default; the player can switch to Compact
    detailsTab      = "ABILITIES", -- TLDR / ABILITIES / TIPS
    showQuickTips   = true,       -- show up to 3 practical tips below Compact tactics
    showTrashPanel  = true,       -- show dungeon trash priorities outside boss encounters
    showMinimapIcon = true,
    minimapAngle    = 225,
    trashPanelPosition = { point = "RIGHT", x = -390, y = 60 },
    trashPanelWidth = 330,
    trashPanelHeight = 260,
    trashPanelScale = 1.0,
    trashPanelAlpha = 1.0,
    trashPanelFontSize = 15,
    trashPanelFontFace = nil,
    trashBackdropMode = true,
    trashBackdropColor = { r = 0, g = 0, b = 0, a = 1.0 },
    trashPanelLocked = false,
    journalPosition = { point = "CENTER", x = 0, y = 0 },
    journalWidth    = 1180,
    journalHeight   = 720,
    journalFontScale = 1.2,       -- Shared Journal/Studio readability: 0.8-1.6
    journalNotes    = {},         -- [bossKey][difficulty] = private local note
    raidPlans       = {},         -- [bossKey][difficulty] = Raid Lead Studio plan
    raidStudioPosition = { point = "CENTER", x = 0, y = 0 },
    raidStudioWidth = 1280,
    raidStudioHeight = 760,
    -- lastBossKey (string) is written at runtime; nil default omitted on purpose
}

-- Mantém campos desconhecidos de bancos migrados, repara valores incompatíveis
-- e preenche recursivamente os padrões sem descartar dados do usuário.
local function MergeDefaults(db, source)
    for key, defaultValue in pairs(source) do
        local currentValue = db[key]
        if type(defaultValue) == "table" then
            if type(currentValue) ~= "table" then
                db[key] = CopyTable(defaultValue)
            else
                MergeDefaults(currentValue, defaultValue)
            end
        elseif currentValue == nil or type(currentValue) ~= type(defaultValue) then
            db[key] = defaultValue
        end
    end
end

local function MigrateLegacyDatabase(db)
    if (tonumber(db.schemaVersion) or 0) >= 4 then return end

    -- The old TLDR popup is the closest equivalent to the v4 mini panel.
    -- Prefer its settings when present; older builds without the popup keep
    -- their main panel position/size through the same-name fields.
    if type(db.tldrPopupPosition) == "table" then
        db.position = CopyTable(db.tldrPopupPosition)
    end
    if type(db.tldrPopupWidth) == "number" then
        db.panelWidth = db.tldrPopupWidth
    elseif type(db.frameWidth) == "number" and db.panelWidth == nil then
        db.panelWidth = db.frameWidth
    end
    if type(db.tldrPopupAlpha) == "number" then
        db.alpha = db.tldrPopupAlpha
    elseif type(db.panelAlpha) == "number" and db.alpha == nil then
        db.alpha = db.panelAlpha
    end
    if type(db.tldrPopupFontSize) == "number" then
        db.fontSize = db.tldrPopupFontSize
    elseif type(db.fontSizeBody) == "number" and db.fontSize == nil then
        db.fontSize = db.fontSizeBody
    end
    if type(db.showTldrOnEnter) == "boolean" then
        db.autoShowOnEnter = db.showTldrOnEnter
    elseif type(db.showPanelOnEnter) == "boolean" and db.autoShowOnEnter == nil then
        db.autoShowOnEnter = db.showPanelOnEnter
    end
    if type(db.autoHide) == "boolean" and db.autoHideAfterEncounter == nil then
        db.autoHideAfterEncounter = db.autoHide
    end
    if type(db.minimized) == "boolean" and db.panelMinimized == nil then
        db.panelMinimized = db.minimized
    end
    if type(db.tldrPopupShown) == "boolean" and db.panelShown == nil then
        db.panelShown = db.tldrPopupShown
    end
end

local function NormalizeDatabase(db)
    local validRoles = { ALL = true, TANK = true, HEALER = true, DPS = true }
    local validChannels = {
        AUTO = true, INSTANCE_CHAT = true, PARTY = true, RAID = true, SAY = true,
    }
    if not validRoles[db.roleFilter] then db.roleFilter = "ALL" end
    if not validChannels[db.shareChannel] then db.shareChannel = "AUTO" end

    db.scale = math.max(0.6, math.min(1.6, tonumber(db.scale) or defaults.scale))
    db.alpha = math.max(0.2, math.min(1.0, tonumber(db.alpha) or defaults.alpha))
    db.panelWidth = math.max(240, math.min(440,
        math.floor((tonumber(db.panelWidth) or defaults.panelWidth) + 0.5)))
    db.detailedPanelWidth = math.max(360, math.min(620,
        math.floor((tonumber(db.detailedPanelWidth) or defaults.detailedPanelWidth) + 0.5)))
    db.trashPanelWidth = math.max(220, math.min(700,
        math.floor((tonumber(db.trashPanelWidth) or defaults.trashPanelWidth) + 0.5)))
    db.trashPanelHeight = math.max(100, math.min(700,
        math.floor((tonumber(db.trashPanelHeight) or defaults.trashPanelHeight) + 0.5)))
    db.trashPanelScale = math.max(0.6, math.min(1.6,
        tonumber(db.trashPanelScale) or defaults.trashPanelScale))
    db.trashPanelAlpha = math.max(0.2, math.min(1.0,
        tonumber(db.trashPanelAlpha) or defaults.trashPanelAlpha))
    db.trashPanelFontSize = math.max(10, math.min(22,
        math.floor((tonumber(db.trashPanelFontSize) or defaults.trashPanelFontSize) + 0.5)))
    if type(db.trashBackdropColor) ~= "table" then
        db.trashBackdropColor = CopyTable(defaults.trashBackdropColor)
    end
    local validDetailTabs = { TLDR = true, ABILITIES = true, TIPS = true, TRASH = true }
    if not validDetailTabs[db.detailsTab] then db.detailsTab = defaults.detailsTab end
    db.journalFontScale = math.max(0.8, math.min(1.6,
        tonumber(db.journalFontScale) or defaults.journalFontScale))
    db.minimapAngle = (tonumber(db.minimapAngle) or defaults.minimapAngle) % 360
    if db.fontSize ~= nil then
        db.fontSize = math.max(10, math.min(20,
            math.floor((tonumber(db.fontSize) or 13) + 0.5)))
    end
end

-- ─── Init ────────────────────────────────────────────────────────────────────

local eventFrame = CreateFrame("Frame", nil, UIParent)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == BT.ADDON_NAME then
            BT:Init()
        end

    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID = ...
        BT:OnEncounterStart(encounterID, encounterName, difficultyID)

    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, _, _, success = ...
        BT:OnEncounterEnd(encounterID, encounterName, success)

    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        BT:OnEnteringWorld(isInitialLogin, isReloadingUi)

    elseif event == "ZONE_CHANGED_NEW_AREA" then
        BT:OnZoneChanged()

    elseif event == "CHALLENGE_MODE_START" then
        BT.Detection:DetectAffixes()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        BT.MiniPanel:ApplyAlpha()
    end
end)

function BT:Init()
    if not BossTacticsDB then
        BossTacticsDB = CopyTable(defaults)
    else
        MigrateLegacyDatabase(BossTacticsDB)
        MergeDefaults(BossTacticsDB, defaults)
    end
    NormalizeDatabase(BossTacticsDB)
    BossTacticsDB.locale = "ptBR"
    BossTacticsDB.schemaVersion = 4
    self.db = BossTacticsDB

    self:InitLocale()
    self:ApplyBossLocale()
    self:ApplyCustomBosses()   -- after locale (custom text stays as typed), before indexes

    self.Detection:BuildBossIndex()
    self.Detection:BuildDungeonIndex()
    self.Detection:DetectAffixes()
    self.MinimapButton:Create()

    -- Settings API can change between WoW patches — never let it kill the addon
    local ok, err = pcall(function() self:RegisterSettingsPanel() end)
    if not ok then
        print(string.format(self:L("ERR_SETTINGS_PANEL"), tostring(err)))
    end

    print(self:L("ADDON_LOADED"))
end

-- ─── Custom boss merge (editor data) ────────────────────────────────────────

--- Snapshot of built-in boss tables that have custom overrides, so Revert can
--- restore them. Whole-table copies (not per-field): a custom save may CLEAR a
--- field, and per-field snapshots cannot represent "was nil" vs "not saved".
BT._originalFields = {}

--- Merge db.customBosses into runtime BT_BossData.
--- Built-in override: restore the original snapshot, then apply custom fields
--- on top (field-level) — repeated saves and removed fields stay correct.
--- Unknown key: the custom table becomes the boss (isCustom = true).
function BT:ApplyCustomBosses()
    local db = BossTacticsDB
    if not db or type(db.customBosses) ~= "table" then return end
    if not BT_BossData then BT_BossData = {} end
    self._originalFields = self._originalFields or {}

    for key, custom in pairs(db.customBosses) do
        -- A legacy BossTacticsDB may contain unrelated editor data. Ignore
        -- malformed entries instead of letting one old value stop v4 startup.
        if type(key) == "string" and type(custom) == "table" then
            local builtin = not custom.isCustom and
                (self._originalFields[key] or BT_BossData[key]) or nil
            if builtin then
                if not self._originalFields[key] then
                    self._originalFields[key] = CopyTable(BT_BossData[key])
                end
                local merged = CopyTable(self._originalFields[key])
                for field, value in pairs(custom) do
                    merged[field] = value
                end
                merged.isCustom = nil
                BT_BossData[key] = merged
            else
                custom.isCustom = true
                BT_BossData[key] = custom
            end
        end
    end
end

--- Rebuild lookup indexes after boss data changed (editor save/revert/delete).
function BT:RebuildIndexes()
    self.Detection:BuildBossIndex()
    self.Detection:BuildDungeonIndex()
    if self.MiniPanel:IsShown() then
        self.MiniPanel:Refresh()
    end
end

-- ─── Zone / world handlers ──────────────────────────────────────────────────

--- Shared zone-in logic. Shows/hides the mini panel for the current instance.
--- @param isReload boolean  true when coming from /reload (restore state instead of reset)
function BT:HandleZoneIn(isReload)
    local D = self.Detection
    -- Real zone transition ends any preview (exit first — it restores the
    -- saved difficulty context which DetectInstanceDifficulty then overwrites)
    if self.MiniPanel.testMode then
        self.MiniPanel:ExitTestMode(true)
    end
    D:DetectInstanceDifficulty()

    local dn = D:GetCurrentDungeonName()
    local MP = self.MiniPanel

    if not dn then
        -- Outside any known instance: panel hidden, no empty states.
        -- Leaving an instance ends the session lockout — clear kills.
        if MP.currentDungeon then
            D:ResetKills()
        end
        self._lastAnnouncedDungeon = nil
        MP:SetDungeon(nil)
        MP:HidePanel(false)   -- do not overwrite user's panelShown preference
        if self.TrashPanel then self.TrashPanel:Hide() end
        return
    end

    -- Announce once per dungeon
    if self._lastAnnouncedDungeon ~= dn then
        self._lastAnnouncedDungeon = dn
        local bosses = D:GetBossesForDungeon(dn)
        if #bosses > 0 then
            print(string.format(self:L("FMT_DUNGEON_ANNOUNCE"), dn, #bosses))
        end
    end

    local dungeonChanged = MP.currentDungeon ~= dn
    -- New dungeon = new lockout: clear session kills. NOT on /reload — a
    -- plain re-entry loading screen (wipe-release-runback) must keep kills,
    -- and that case never reaches here because the dungeon didn't change.
    if dungeonChanged and not isReload then
        D:ResetKills()
    end
    MP:SetDungeon(dn)
    local db = self.db

    if db.showTrashPanel ~= false and BT_TrashData and BT_TrashData[dn]
        and self.TrashPanel then
        self.TrashPanel:ShowDungeon(dn)
    elseif self.TrashPanel then
        self.TrashPanel:Hide()
    end
    if isReload and db.panelShown then
        if db.lastBossKey and D:BossBelongsToDungeon(db.lastBossKey, dn) then
            MP:ShowBoss(db.lastBossKey)
        else
            MP:ShowFirstUnkilled(dn)
        end
    elseif dungeonChanged and (db.autoShowOnEnter or db.panelShown) then
        MP:ShowFirstUnkilled(dn)
    elseif MP:IsShown() then
        MP:Refresh()   -- same dungeon, just refresh (difficulty may have changed)
    end
end

function BT:OnEnteringWorld(isInitialLogin, isReloadingUi)
    local D = self.Detection
    D:DetectAffixes()
    -- Kill reset happens in HandleZoneIn on actual dungeon change/exit —
    -- NOT here: this event also fires on the loading screen when running
    -- back into the same instance after a wipe release.
    self:HandleZoneIn(isReloadingUi)
end

function BT:OnZoneChanged()
    self:HandleZoneIn(false)
end

-- ─── Encounter handlers ─────────────────────────────────────────────────────

function BT:OnEncounterStart(encounterID, encounterName, difficultyID)
    if not self.db then return end
    local D = self.Detection
    self.MiniPanel:CancelAutoHide()

    -- A real pull ends any preview; the encounter drives the panel from here
    if self.MiniPanel.testMode then
        self.MiniPanel:ExitTestMode(true)
    end

    -- Runtime difficulty context only — never persisted to DB
    local detected = D.DIFFICULTY_MAP[difficultyID]
    if detected then
        D.activeDifficulty = detected
    end

    local bossInfo, bossKey = D:GetBossInfo(encounterID, encounterName)
    if not bossInfo then return end

    -- Jump the panel to the pulled boss.  An automatic post-encounter hide
    -- deliberately leaves panelShown enabled, so the next pull must reveal
    -- the panel again.  A manually closed panel sets panelShown to false and
    -- remains closed as expected.
    local MP = self.MiniPanel
    if MP:IsShown() or self.db.panelShown then
        MP:ShowBoss(bossKey)
    else
        MP:SetCurrentBoss(bossKey)
    end
end

function BT:OnEncounterEnd(encounterID, encounterName, success)
    if not self.db then return end

    -- Preview entered mid-combat would corrupt the advance path — end it
    if self.MiniPanel.testMode then
        self.MiniPanel:ExitTestMode(true)
    end

    local D = self.Detection
    if success == 1 and encounterID then
        D:MarkKilled(encounterID)
    end

    local MP = self.MiniPanel
    if success == 1 and self.db.autoAdvance then
        self.MiniPanel:AdvanceToNextUnkilled()
    elseif self.MiniPanel:IsShown() then
        self.MiniPanel:Refresh()   -- at least show the killed checkmark
    end

    -- Auto-advance and auto-hide are competing post-kill actions.  Advancing
    -- must win: otherwise we briefly render the next boss and then hide that
    -- panel a few seconds later, which makes auto-advance appear broken.
    -- Keep auto-hide behavior for wipes, failed encounters, and kills where
    -- auto-advance is disabled.
    local advancedAfterKill = success == 1 and self.db.autoAdvance
    if self.db.autoHideAfterEncounter and not advancedAfterKill
        and self.MiniPanel:IsShown() then
        self.MiniPanel:ScheduleAutoHide(self.db.autoHideDelay or 8)
    end
end

-- ─── Slash commands — /bosstactics ──────────────────────────────────────────────────

SLASH_BOSSTACTICS1 = "/bosstactics"

SlashCmdList["BOSSTACTICS"] = function(msg)
    msg = strtrim(msg or "")
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")
    cmd = (cmd or ""):lower()

    local db = BT.db
    local MP = BT.MiniPanel
    if not db then return end

    if cmd == "" then
        BT:OpenJournal()

    elseif cmd == "show" then
        MP:EnterTestMode()

    elseif cmd == "hide" then
        if MP.testMode then MP:ExitTestMode(true) end
        MP:HidePanel(true)

    elseif cmd == "test" then
        if arg:lower() == "off" then
            MP:ExitTestMode()
        else
            MP:ToggleTestMode()
        end

    elseif cmd == "lock" then
        db.locked = not db.locked
        print(BT:L(db.locked and "PANEL_LOCKED" or "PANEL_UNLOCKED"))

    elseif cmd == "reset" then
        db.position = { point = "RIGHT", x = -80, y = 60 }
        MP:ApplyPosition()
        print(BT:L("POSITION_RESET"))

    elseif cmd == "resetsize" then
        db.scale = 1.0
        db.panelWidth = 270
        db.fontSize = 15
        MP:ApplyLook()
        MP:ApplyWidth()

    elseif cmd == "fontsize" and tonumber(arg) then
        db.fontSize = math.max(10, math.min(20, math.floor(tonumber(arg) + 0.5)))
        if MP:IsShown() then MP:Refresh() end

    elseif cmd == "boss" and arg ~= "" then
        local bossInfo, bossKey = BT.Detection:GetBossInfo(nil, arg)
        if bossInfo and bossKey then
            MP:ShowBoss(bossKey)
        else
            print(string.format(BT:L("ERR_BOSS_NOT_FOUND"), arg))
        end

    elseif cmd == "options" or cmd == "config" or cmd == "settings" then
        BT:OpenSettings()

    elseif cmd == "journal" or cmd == "j" then
        BT:OpenJournal()

    elseif cmd == "raidlead" or cmd == "studio" or cmd == "rl" then
        BT:OpenRaidStudio()

    elseif cmd == "brief" then
        BT:OpenRaidBrief(arg ~= "" and arg or nil)

    elseif cmd == "chatdebug" then
        BT.Components.ChatDebug()

    elseif cmd == "edit" or cmd == "editor" then
        local bossKey
        if arg ~= "" then
            local _, foundKey = BT.Detection:GetBossInfo(nil, arg)
            bossKey = foundKey
        end
        BT:OpenEditor(bossKey)

    else
        print(BT:L("HELP_HEADER"))
        print(BT:L("HELP_TOGGLE"))
        print(BT:L("HELP_SHOW"))
        print(BT:L("HELP_HIDE"))
        print(BT:L("HELP_TEST"))
        print(BT:L("HELP_JOURNAL"))
        print(BT:L("HELP_RAID_STUDIO"))
        print(BT:L("HELP_BRIEF"))
        print(BT:L("HELP_OPTIONS"))
        print(BT:L("HELP_EDIT"))
        print(BT:L("HELP_LOCK"))
        print(BT:L("HELP_RESET"))
        print(BT:L("HELP_RESETSIZE"))
        print(BT:L("HELP_FONTSIZE"))
        print(BT:L("HELP_BOSS"))
        print(BT:L("HELP_CHATDEBUG"))
    end
end
