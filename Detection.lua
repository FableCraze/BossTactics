-- Detection.lua  (Boss Tactics)
-- Boss/dungeon indexes, O(1) lookups, difficulty + affix runtime context,
-- session kill tracking. Ported from BossTactics 3.2.0 with fixes:
--   * DIFFICULTY_MAP[14] = NORMAL (Normal raid) — old code had HEROIC (bug)
--   * detected difficulty lives ONLY in Detection.activeDifficulty (runtime),
--     never written to SavedVariables
--   * affix names resolved via C_ChallengeMode.GetAffixInfo (nil-guarded),
--     affixTips matched by affix ID where possible, name fallback kept

local BT = BossTactics
local D = {}
BT.Detection = D

-- ─── Difficulty mapping (difficultyID → filter tag) ─────────────────────────

D.DIFFICULTY_MAP = {
    [1]  = "NORMAL",   -- Normal dungeon
    [2]  = "HEROIC",   -- Heroic dungeon
    [8]  = "MYTHIC",   -- Mythic Keystone
    [23] = "MYTHIC",   -- Mythic dungeon
    [14] = "NORMAL",   -- Normal raid
    [15] = "HEROIC",   -- Heroic raid
    [16] = "MYTHIC",   -- Mythic raid
    [17] = "LFR",      -- Looking For Raid
}

-- Runtime-only context — never persisted
D.activeDifficulty = nil
D.activeAffixes    = {}
D._killedBosses    = {}   -- [encounterID] = true, session only

-- Legacy affixTips keys are English affix names; map known IDs so
-- name-keyed entries still match on non-English clients.
local LEGACY_AFFIX_NAMES = {
    [9]   = "Tyrannical",   [10]  = "Fortified",
    [11]  = "Bursting",     [12]  = "Raging",
    [13]  = "Bolstering",   [14]  = "Sanguine",
    [123] = "Spiteful",     [124] = "Storming",
    [134] = "Entangling",   [135] = "Afflicted",
    [136] = "Incorporeal",
}

local PTBR_AFFIX_NAMES = {
    [9]   = "Tirânico",     [10]  = "Fortificado",
    [11]  = "Estourando",   [12]  = "Enfurecido",
    [13]  = "Fortalecedor", [14]  = "Sanguíneo",
    [123] = "Rancoroso",    [124] = "Tempestuoso",
    [134] = "Enredante",    [135] = "Aflito",
    [136] = "Incorpóreo",
}

-- ─── Difficulty / affix context ─────────────────────────────────────────────

--- Detect instance difficulty from GetInstanceInfo(). Runtime context only.
function D:DetectInstanceDifficulty()
    local _, _, difficultyID = GetInstanceInfo()
    local detected = self.DIFFICULTY_MAP[difficultyID]
    if detected then
        self.activeDifficulty = detected
    elseif not IsInInstance() then
        self.activeDifficulty = nil
    end
end

--- Refresh the active M+ affix list. Names come from the game API, not a
--- hardcoded table (nil-guarded — API may be unavailable mid-loading).
function D:DetectAffixes()
    wipe(self.activeAffixes)
    if not (C_MythicPlus and C_MythicPlus.GetCurrentAffixes) then return end
    local affixes = C_MythicPlus.GetCurrentAffixes()
    if not affixes then return end
    for _, affix in ipairs(affixes) do
        local apiName
        if C_ChallengeMode and C_ChallengeMode.GetAffixInfo then
            apiName = C_ChallengeMode.GetAffixInfo(affix.id)
        end
        self.activeAffixes[#self.activeAffixes + 1] = {
            id      = affix.id,
            name    = PTBR_AFFIX_NAMES[affix.id] or apiName or tostring(affix.id),
            apiName = apiName,
        }
    end
end

--- Collect affix tips for a boss matching the currently active affixes.
--- Matches by affix ID first (future-proof data), then API name, then the
--- legacy English-name fallback for old entries.
--- @return table  array of { id=?, name=string, tips=table }
function D:GetActiveAffixTips(bossData)
    local out = {}
    if not bossData or not bossData.affixTips then return out end
    for _, affix in ipairs(self.activeAffixes) do
        local tips = bossData.affixTips[affix.id]
            or (affix.apiName and bossData.affixTips[affix.apiName])
            or (LEGACY_AFFIX_NAMES[affix.id] and bossData.affixTips[LEGACY_AFFIX_NAMES[affix.id]])
        if tips then
            out[#out + 1] = { id = affix.id, name = affix.name, tips = tips }
        end
    end
    return out
end

--- Check if an ability/bullet should be visible at the given difficulty.
--- Untagged entries always show. LFR is treated as NORMAL for matching.
function D:AbilityMatchesDifficulty(ability, diffFilter)
    if not diffFilter then return true end           -- no context = show all
    local tag = ability.difficulty
    if not tag then return true end                   -- untagged = show always

    tag = tag:upper()
    if diffFilter == "LFR" then diffFilter = "NORMAL" end
    if tag == diffFilter then return true end          -- exact match

    -- HEROIC+ means show on HEROIC and MYTHIC
    if tag == "HEROIC+" then
        return diffFilter == "HEROIC" or diffFilter == "MYTHIC"
    end

    -- MYTHIC+ is equivalent to MYTHIC (dungeon label variant)
    if tag == "MYTHIC+" then
        return diffFilter == "MYTHIC"
    end

    return false
end

--- Check if an ability's role matches the active role filter.
function D:RoleMatchesFilter(abilityRole, roleFilter)
    local role = (abilityRole or "ALL"):upper()
    local filter = (roleFilter or "ALL"):upper()
    if filter == "ALL" then return true end
    return role == "ALL" or role == filter
end

-- ─── Kill tracking (session only) ───────────────────────────────────────────

function D:ResetKills()
    wipe(self._killedBosses)
end

function D:MarkKilled(encounterID)
    self._killedBosses[encounterID] = true
end

--- Check if a boss key has been killed this session (via its encounterID).
function D:IsBossKilled(bossKey)
    if not bossKey or not BT_BossData then return false end
    local data = BT_BossData[bossKey]
    if not data or not data.encounterID then return false end
    return self._killedBosses[data.encounterID] == true
end

--- Get killed / total count for a dungeon.
function D:GetKillCount(dungeonName)
    local bosses = self:GetBossesForDungeon(dungeonName)
    local killed = 0
    for _, bk in ipairs(bosses) do
        if self:IsBossKilled(bk) then killed = killed + 1 end
    end
    return killed, #bosses
end

-- ─── Boss index — O(1) lookup ───────────────────────────────────────────────

function D:BuildBossIndex()
    self._indexByEncounterID = {}
    self._indexByName        = {}

    if not BT_BossData then return end

    for key, data in pairs(BT_BossData) do
        if type(key) == "number" then
            self._indexByEncounterID[key] = key
        elseif type(key) == "string" then
            self._indexByName[key:lower()] = key
        end

        if type(data) == "table" and data.encounterID then
            self._indexByEncounterID[data.encounterID] = key
        end
    end
end

--- Returns (data, bossKey) so callers can track the canonical key.
function D:GetBossInfo(encounterID, encounterName)
    if not BT_BossData then return nil end

    -- 1. encounterID — O(1)
    if encounterID then
        local key = self._indexByEncounterID and self._indexByEncounterID[encounterID]
        if key and BT_BossData[key] then
            return BT_BossData[key], key
        end
        if BT_BossData[encounterID] then
            return BT_BossData[encounterID], encounterID
        end
    end

    -- 2. Exact name match — O(1)
    if encounterName then
        local nameLower = encounterName:lower()
        local key = self._indexByName and self._indexByName[nameLower]
        if key and BT_BossData[key] then
            return BT_BossData[key], key
        end

        -- 3. Partial match — O(n) fallback, only on index miss
        for lowerKey, origKey in pairs(self._indexByName or {}) do
            if lowerKey:find(nameLower, 1, true) or nameLower:find(lowerKey, 1, true) then
                return BT_BossData[origKey], origKey
            end
        end
    end

    -- No curated data — stay silent
    return nil
end

-- ─── Dungeon index ──────────────────────────────────────────────────────────

--- Build dungeon name → boss key list, plus instanceID → dungeon name map.
function D:BuildDungeonIndex()
    self._indexByDungeon    = {}
    self._indexByInstanceID = {}
    if not BT_BossData then return end

    for key, data in pairs(BT_BossData) do
        if type(data) == "table" and data.dungeonName then
            local dName = data.dungeonName
            if type(dName) == "table" then dName = dName.en or dName.enUS end
            if dName then
                if not self._indexByDungeon[dName] then
                    self._indexByDungeon[dName] = {}
                end
                table.insert(self._indexByDungeon[dName], key)
                if data.instanceID then
                    self._indexByInstanceID[data.instanceID] = dName
                end
            end
        end
    end
end

--- Get boss keys for a dungeon, sorted by journalOrder (falling back to
--- encounterID). encounterIDs are not always sequential in fight order.
function D:GetBossesForDungeon(dungeonName)
    if not self._indexByDungeon or not dungeonName then return {} end
    local bosses = self._indexByDungeon[dungeonName]
    if not bosses then return {} end
    local sorted = {}
    for _, v in ipairs(bosses) do table.insert(sorted, v) end
    table.sort(sorted, function(a, b)
        local da = BT_BossData[a]
        local dbb = BT_BossData[b]
        local ea = da and (da.journalOrder or da.encounterID) or 999999
        local eb = dbb and (dbb.journalOrder or dbb.encounterID) or 999999
        if ea ~= eb then return ea < eb end
        return a < b
    end)
    return sorted
end

--- True if bossKey belongs to dungeonName.
function D:BossBelongsToDungeon(bossKey, dungeonName)
    if not bossKey or not dungeonName then return false end
    local data = BT_BossData and BT_BossData[bossKey]
    if not data then return false end
    local dName = data.dungeonName
    if type(dName) == "table" then dName = dName.en or dName.enUS end
    return dName == dungeonName
end

--- Normalize string for fuzzy matching: lowercase, strip punctuation/quotes/dashes.
--- Multibyte punctuation is stripped as full UTF-8 sequences, not via a byte
--- class (a byte class would eat continuation bytes out of Cyrillic strings).
local function normalizeForMatch(s)
    s = s:lower()
    s = s:gsub("\226\128\152", "")   -- ‘ U+2018
    s = s:gsub("\226\128\153", "")   -- ’ U+2019
    s = s:gsub("\226\128\147", "")   -- – U+2013
    s = s:gsub("\226\128\148", "")   -- — U+2014
    s = s:gsub("['`%-:%.,]", "")
    s = s:gsub("%s+", " ")
    return strtrim(s)
end

--- Detect current dungeon name from GetInstanceInfo().
--- Primary: instanceID lookup (O(1), locale-independent). Fallback: name match.
function D:GetCurrentDungeonName()
    if not self._indexByDungeon then return nil end
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        self._lastUnknownReported = nil
        return nil
    end

    -- Primary: instanceID lookup
    if self._indexByInstanceID then
        local instanceID = select(8, GetInstanceInfo())
        if instanceID and self._indexByInstanceID[instanceID] then
            return self._indexByInstanceID[instanceID]
        end
    end

    -- Fallback: string matching (custom/renamed instances)
    local instanceName = GetInstanceInfo()
    if not instanceName or instanceName == "" then return nil end

    if self._indexByDungeon[instanceName] then
        return instanceName
    end

    local nameLower = instanceName:lower()
    for dName in pairs(self._indexByDungeon) do
        local dLower = dName:lower()
        if dLower:find(nameLower, 1, true) or nameLower:find(dLower, 1, true) then
            return dName
        end
    end

    local nameNorm = normalizeForMatch(instanceName)
    for dName in pairs(self._indexByDungeon) do
        local dNorm = normalizeForMatch(dName)
        if dNorm:find(nameNorm, 1, true) or nameNorm:find(dNorm, 1, true) then
            return dName
        end
    end

    -- No match — surface the instance name so the user can report it.
    -- Gated: this runs on every zone event and toggle, print once per instance.
    if (instanceType == "party" or instanceType == "raid")
        and self._lastUnknownReported ~= instanceName then
        self._lastUnknownReported = instanceName
        print(string.format(BT:L("ERR_UNKNOWN_INSTANCE"), instanceName))
    end
    return nil
end
