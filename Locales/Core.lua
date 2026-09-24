-- Locales/Core.lua (Boss Tactics)
-- Catálogo exclusivo em português brasileiro.
-- Deve carregar antes do catálogo e do código do addon.

local ADDON_NAME = ...

BossTactics = BossTactics or {}
local BT = BossTactics

-- Keep the installed addon identity in one place. Runtime code must not depend
-- on a development folder name, and CurseForge releases use BossTactics.
BT.ADDON_NAME = ADDON_NAME or BT.ADDON_NAME or "BossTactics"

BT.Locales = {}
BT.CurrentLocale = "ptBR"

--- Register a locale string table.
--- @param code string  Locale code (e.g. "enUS", "deDE")
--- @param strings table  Key-value pairs of localized strings
function BT:RegisterLocale(code, strings)
    if code == "ptBR" then self.Locales.ptBR = strings end
end

function BT:InitLocale()
    self.CurrentLocale = "ptBR"
    if BossTacticsDB then BossTacticsDB.locale = "ptBR" end
end

function BT:L(key)
    local loc = self.Locales.ptBR
    return (loc and loc[key]) or key
end

--- Localize a data field (boss data entries).
--- Supports table format {en="...", enUS="...", deDE="..."} and plain strings.
function BT:Localize(field)
    if field == nil then return nil end
    if type(field) == "table" then
        if field.ptBR then return field.ptBR end
        if field["enUS"] then return field["enUS"] end
        if field.en then return field.en end -- dados antigos e nomes de detecção
        return nil
    end
    return field  -- plain string
end

-- =====================================================================
-- BossData locale overlay system
-- Each BossData_XX.lua registers an overlay table via BT:RegisterBossLocale().
-- After InitLocale(), ApplyBossLocale() merges the current locale's overlay
-- into BT_BossData, replacing English text fields with translated ones.
-- Overlay format per boss:
--   ["Boss Name"] = {
--       abilities = { "Translated title", "Translated desc", ... },  -- paired: title1, desc1, title2, desc2
--       tips = { "tip1", "tip2", ... },
--       tldr = { "tldr1", "tldr2", ... },                           -- plain strings; {text=,difficulty=} entries keep .text replaced by index
--       affixTips = { Tyrannical = { "tip1", "tip2" }, ... },
--   }
-- =====================================================================

BT.BossLocales = {}

-- Blizzard occasionally normalizes localized encounter names between
-- patches. Locale overlays use stable English lookup keys, but these three
-- entries shipped with accented PTR spellings in v3. Keep the old files
-- compatible without forcing duplicate translations.
BT.BossLocaleAliases = {
    ["Välgor and Ezzorak"] = "Vaelgor and Ezzorak",
    ["Chimärus"] = "Chimaerus",
    ["Zän Bladesorrow"] = "Zaen Bladesorrow",
}

function BT:ResolveBossLocaleKey(bossName)
    return self.BossLocaleAliases[bossName] or bossName
end

--- Register a boss data locale overlay.
--- @param code string  Locale code (e.g. "deDE")
--- @param data table   { ["Boss Name"] = { abilities={...}, tips={...}, ... } }
function BT:RegisterBossLocale(code, data)
    local target = self.BossLocales[code]
    if not target then
        self.BossLocales[code] = data
        return
    end
    -- Locale data may be split by season/content family to keep large tactic
    -- packs maintainable. Later packs replace only the fields they provide,
    -- so a tips-only pack cannot discard an earlier TLDR/ability translation.
    for bossName, translated in pairs(data) do
        local existing = target[bossName]
        if type(existing) == "table" and type(translated) == "table" then
            for field, value in pairs(translated) do
                existing[field] = value
            end
        else
            target[bossName] = translated
        end
    end
end

--- Apply the current locale's boss translations onto BT_BossData.
--- Called once after InitLocale + BossData is loaded.
function BT:ApplyBossLocale()
    local loc = self.CurrentLocale
    if not loc or loc == "enUS" then return end

    local overlay = self.BossLocales[loc]
    if not overlay then return end

    local bossData = BT_BossData
    if not bossData then return end

    for bossName, tr in pairs(overlay) do
        local boss = bossData[self:ResolveBossLocaleKey(bossName)]
        -- Reworked encounters can explicitly keep the verified English tactic
        -- until their positional locale overlays are rewritten. Applying an
        -- older overlay with the same array shape would silently show the
        -- wrong mechanic under a new title.
        if boss and (not boss.forceEnglishTactics or tr.verified) then
            -- Abilities: overlay is flat array {title1, desc1, title2, desc2, ...}
            if tr.abilities and boss.abilities then
                for i, ab in ipairs(boss.abilities) do
                    local ti = (i - 1) * 2 + 1
                    if tr.abilities[ti] then ab.title = tr.abilities[ti] end
                    if tr.abilities[ti + 1] then ab.description = tr.abilities[ti + 1] end
                end
            end

            -- Tips: simple indexed array
            if tr.tips and boss.tips then
                for i, tip in ipairs(tr.tips) do
                    if boss.tips[i] then
                        if type(boss.tips[i]) == "table" then
                            boss.tips[i].text = tip
                        else
                            boss.tips[i] = tip
                        end
                    end
                end
            end

            -- TLDR: indexed array, may contain plain strings or {text=, difficulty=}
            if tr.tldr and boss.tldr then
                for i, line in ipairs(tr.tldr) do
                    if boss.tldr[i] then
                        if type(boss.tldr[i]) == "table" then
                            boss.tldr[i].text = line
                        else
                            boss.tldr[i] = line
                        end
                    end
                end
            end

            -- Affix tips: { Tyrannical = { "tip1", "tip2" }, ... }
            if tr.affixTips and boss.affixTips then
                for affix, tips in pairs(tr.affixTips) do
                    if boss.affixTips[affix] then
                        for i, tip in ipairs(tips) do
                            if boss.affixTips[affix][i] then
                                boss.affixTips[affix][i] = tip
                            end
                        end
                    end
                end
            end
        end
    end
end

--- Return built-in boss translation coverage for diagnostics/tests.
--- Custom bosses are user-authored and intentionally excluded.
function BT:GetBossLocaleCoverage(code)
    local bossData = BT_BossData or {}
    local overlay = self.BossLocales[code] or {}
    local covered = {}
    local translated, total = 0, 0

    for bossName in pairs(overlay) do
        covered[self:ResolveBossLocaleKey(bossName)] = true
    end
    for bossName, boss in pairs(bossData) do
        if type(boss) == "table" and not boss.isCustom then
            total = total + 1
            if code == "enUS" or covered[bossName] then
                translated = translated + 1
            end
        end
    end
    return translated, total
end
