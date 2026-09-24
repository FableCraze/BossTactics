BossTactics = {
    Config = { dungeonDifficultySelectionEnabled = false },
    Detection = {
        AbilityMatchesDifficulty = function() return true end,
    },
}

function CreateFrame()
    return {
        RegisterEvent = function() end,
        SetScript = function() end,
    }
end

dofile("Components.lua")

local C = BossTactics.Components
assert(C.ResolveContentDifficulty({ isRaid = false }, "MYTHIC") == "NORMAL",
    "masmorra deveria ser fixada em Normal")
assert(C.ResolveContentDifficulty({ isRaid = true }, "MYTHIC") == "MYTHIC",
    "raide não deveria perder sua dificuldade")
assert(C.ShouldShowDifficultySelector({ isRaid = false }) == false,
    "seletor de masmorra deveria ficar oculto")
BossTactics.Config.dungeonDifficultySelectionEnabled = true
assert(C.ResolveContentDifficulty({ isRaid = false }, "HEROIC") == "HEROIC",
    "opção interna deveria restaurar dificuldades de masmorra")
assert(C.ShouldShowDifficultySelector({ isRaid = false }) == true,
    "opção interna deveria restaurar o seletor")

local casos = {
    ["TANQUE: atual"] = "tank",
    ["CURADOR: atual"] = "healer",
    ["DPS: atual"] = "dps",
    ["INTERROMPER: atual"] = "interrupt",
    ["TANK: antigo"] = "tank",
    ["HEAL: antigo"] = "healer",
    ["HEALER: antigo"] = "healer",
    ["KICK: antigo"] = "interrupt",
    ["INTERRUPT: antigo"] = "interrupt",
}

for linha, esperado in pairs(casos) do
    local funcao, texto = BossTactics.Components.ParseTLDRRole(linha)
    assert(funcao == esperado, linha .. " foi interpretado como " .. tostring(funcao))
    assert(texto == "atual" or texto == "antigo", "prefixo não foi removido")
end

print("OK: prefixos PT-BR e históricos")
