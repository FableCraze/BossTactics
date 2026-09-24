UIParent = {}
SlashCmdList = {}

function CopyTable(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, item in pairs(value) do copy[key] = CopyTable(item) end
    return copy
end

function CreateFrame()
    return {
        RegisterEvent = function() end,
        SetScript = function() end,
    }
end

dofile("Locales/Core.lua")
dofile("Locales/ptBR.lua")

BossTactics.Detection = {
    BuildBossIndex = function() end,
    BuildDungeonIndex = function() end,
    DetectAffixes = function() end,
}
BossTactics.MinimapButton = { Create = function() end }
BossTactics.MiniPanel = {
    IsShown = function() return false end,
    Refresh = function() end,
}
BossTactics.RegisterSettingsPanel = function() end

BT_BossData = {
    ["Chefe original"] = { dungeonName = "Cavernas Ígneas", tldr = { "Texto original" } },
}

dofile("Core.lua")
assert(BossTactics.Config.dungeonDifficultySelectionEnabled == false,
    "seleção de dificuldade de masmorra deveria iniciar desativada")

BossTacticsDB = {
    schemaVersion = 4,
    locale = "enUS",
    position = { point = "TOPLEFT", x = 123, y = -45 },
    scale = 1.25,
    alpha = 0.75,
    roleFilter = "HEALER",
    journalNotes = { ["Chefe original"] = { MYTHIC = "ação pessoal çã" } },
    raidPlans = { ["Chefe original"] = { MYTHIC = { blocks = { { text = "plano pessoal" } } } } },
    customBosses = {
        ["Meu chefe"] = {
            isCustom = true,
            dungeonName = "Minha masmorra",
            tldr = { "TANK: texto escrito pelo usuário" },
        },
    },
}

BossTactics:Init()

assert(BossTacticsDB.locale == "ptBR", "idioma migrado não foi fixado")
assert(BossTacticsDB.position.x == 123 and BossTacticsDB.position.y == -45, "posição alterada")
assert(BossTacticsDB.scale == 1.25 and BossTacticsDB.alpha == 0.75, "aparência alterada")
assert(BossTacticsDB.roleFilter == "HEALER", "filtro válido alterado")
assert(BossTacticsDB.journalNotes["Chefe original"].MYTHIC == "ação pessoal çã", "nota alterada")
assert(BossTacticsDB.raidPlans["Chefe original"].MYTHIC.blocks[1].text == "plano pessoal", "plano alterado")
assert(BT_BossData["Meu chefe"].tldr[1] == "TANK: texto escrito pelo usuário", "chefe personalizado alterado")

BossTacticsDB = nil
BossTactics:Init()
assert(BossTacticsDB.locale == "ptBR", "instalação limpa sem ptBR")
assert(BossTacticsDB.roleFilter == "ALL", "filtro padrão incorreto")
assert(BossTacticsDB.schemaVersion == 4, "esquema padrão incorreto")

print("OK: instalação limpa e preservação do banco migrado")
