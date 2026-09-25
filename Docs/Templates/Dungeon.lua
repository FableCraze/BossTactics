-- Modelo documental. Não adicione este arquivo ao BossTactics.toc.
-- Copie-o para Data/Forever/Dungeons/ somente depois de confirmar no cliente
-- a lista, a ordem, os identificadores e as mecânicas da masmorra.

local bosses = {
    ["Nome oficial PT-BR"] = {
        dungeonName = "Nome oficial PT-BR da masmorra",
        -- Inclua apenas identificadores confirmados; nunca use zero.
        -- instanceID = 123,
        -- encounterID = 456,
        -- npcID = 789,
        journalOrder = 1,
        sourceName = "Nome na tabela do cliente",
        abilities = {
            { title = "Mecânica geral", description = "O que acontece e qual ação tomar.", role = "ALL", type = "MOVEMENT" },
            { title = "Mecânica de tanque", description = "Resposta prática do tanque.", role = "TANK", type = "TANK_CD" },
            { title = "Mecânica de cura", description = "Resposta prática do curador.", role = "HEALER", type = "HEALER_CD" },
            { title = "Mecânica de dano", description = "Resposta prática dos DPS.", role = "DPS", type = "INTERRUPT" },
        },
        tips = {
            "Dica curta, prática e sustentada pelas fontes documentadas.",
        },
        tldr = {
            "Instrução curta e acionável.",
            "Segunda instrução.",
            "Terceira instrução.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["Nome oficial PT-BR da masmorra"] = {
    summary = {
        "PERCURSO: orientação textual por setor.",
    },
    enemies = {
        { enemy = "Nome do inimigo", title = "Habilidade", description = "Ameaça e resposta prática.", role = "ALL", type = "INTERRUPT", priority = 1 },
    },
}
