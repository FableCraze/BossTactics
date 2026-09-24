-- Data/Forever/Templates/Dungeon.lua
-- Modelo apenas para documentação. Não adicione este arquivo ao BossTactics.toc.
-- Copie-o para Data/Forever/Dungeons/ somente depois de confirmar no cliente
-- a lista, a ordem, os identificadores e as mecânicas da masmorra.

-- Cada arquivo de masmorra acrescenta dados à tabela criada por Forever/Init.lua.
-- Nunca atribua uma tabela nova a BT_BossData aqui.
local bosses = {
    ["Nome oficial do chefe no cliente-alvo"] = {
        dungeonName = "Nome oficial da masmorra no cliente-alvo",
        instanceID = 0,       -- ID de mapa/instância de GetInstanceInfo(), confirmado
        encounterID = 0,      -- ID de DungeonEncounter, confirmado
        npcID = 0,            -- ID de criatura/NPC, confirmado
        journalOrder = 1,     -- ordem do encontro na tabela do cliente
        sourceName = "Nome na tabela do cliente quando diferente da chave exibida",
        abilities = {
            { title = "Mecânica geral", description = "Resposta prática.", role = "ALL", type = "MOVEMENT" },
            { title = "Mecânica de tanque", description = "Resposta prática.", role = "TANK", type = "TANK_CD" },
            { title = "Mecânica de cura", description = "Resposta prática.", role = "HEALER", type = "HEALER_CD" },
            { title = "Mecânica de dano", description = "Resposta prática.", role = "DPS", type = "INTERRUPT" },
        },
        tips = {
            "Dica curta e confirmada.",
        },
        tldr = {
            "Resumo curto e acionável.",
        },
        -- difficulty e affixTips ficam ausentes até o beta oferecer modos ou
        -- mecânicas correspondentes e eles serem confirmados no cliente.
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end
