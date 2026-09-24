-- Data/Forever/Dungeons/CavernasIgneas.lua
-- WoW Forever beta 1.60.1.69913 (2026-09-21).
-- Encounter IDs/order: DungeonEncounter client table, MapID 389.
-- NPC IDs/names: Wowhead Forever beta database.
-- Mechanics: beta-specific community runs cross-checked against the client roster.

local bosses = {
    ["Pederneiro"] = {
        dungeonName = "Cavernas Ígneas",
        instanceID = 389,
        encounterID = 2732,
        npcID = 11517,
        journalOrder = 1,
        sourceName = "Oggleflint",
        abilities = {
            { title = "Dois guardas", description = "Controle um dos dois guardas e elimine o outro antes de concentrar dano no chefe.", role = "ALL", type = "MOVEMENT" },
            { title = "Cutilar", description = "Mantenha Pederneiro virado para longe do grupo; o golpe atinge alvos próximos à frente.", role = "TANK", type = "TANK_CD" },
            { title = "Dano inicial", description = "Prepare cura para o tanque enquanto os guardas ainda estiverem vivos; não fique à frente do chefe.", role = "HEALER", type = "HEALER_CD" },
            { title = "Prioridade dos guardas", description = "Use controle de grupo quando disponível, mate os guardas e só então ataque Pederneiro.", role = "DPS", type = "MOVEMENT" },
        },
        tips = {
            "Puxe com espaço para não trazer grupos próximos.",
            "Somente o tanque deve permanecer à frente de Pederneiro.",
            "O encontro fica simples assim que os dois guardas morrem.",
        },
        tldr = {
            "Use Contole de grupo em um guarda e mate o outro antes do chefe.",
            "TANQUE: Vire Pederneiro para longe do grupo.",
            "GRUPO: Não fique na frente do Boss para evitar o Cutilar.",
        },
    },

    ["Taragaman, o Famélico"] = {
        dungeonName = "Cavernas Ígneas",
        instanceID = 389,
        encounterID = 2733,
        npcID = 11520,
        journalOrder = 2,
        sourceName = "Taragaman the Hungerer",
        abilities = {
            { title = "Plataforma de lava", description = "Lute na parte central da plataforma e mantenha distância das bordas para não ser lançado na lava.", role = "ALL", type = "MOVEMENT" },
            { title = "Gancho", description = "Posicione-se com terreno seguro às costas; o golpe lança o alvo para trás.", role = "TANK", type = "TANK_CD" },
            { title = "Nova de Fogo", description = "Recupere rapidamente a vida dos jogadores próximos após o dano em área e vigie o tanque depois de Gancho.", role = "HEALER", type = "HEALER_CD" },
            { title = "Alcance da Nova", description = "DPS de longo alcance devem ficar afastados; corpo a corpo deve manter a vida alta para Nova de Fogo.", role = "DPS", type = "MOVEMENT" },
        },
        tips = {
            "Limpe as patrulhas ao redor antes de iniciar o encontro.",
            "O tanque deve usar o centro e alinhar o empurrão com uma área segura.",
            "Jogadores de longo alcance evitam a Nova de Fogo ficando afastados.",
        },
        tldr = {
            "Fique longe das bordas da plataforma.",
            "TANQUE: receba Gancho com terreno seguro às costas.",
            "LONGO ALCANCE: afaste-se da Nova de Fogo.",
        },
    },

    ["Jergosh, o Invocador"] = {
        dungeonName = "Cavernas Ígneas",
        instanceID = 389,
        encounterID = 2734,
        npcID = 11518,
        journalOrder = 3,
        sourceName = "Jergosh the Invoker",
        abilities = {
            { title = "Dois auxiliares", description = "Controle um auxiliar, elimine o outro e depois concentre o chefe.", role = "ALL", type = "MOVEMENT" },
            { title = "Maldição da Fraqueza", description = "A maldição reduz o dano físico e pode enfraquecer a geração de ameaça; consolide a ameaça antes de o grupo acelerar.", role = "TANK", type = "TANK_CD" },
            { title = "Remoções", description = "Remova Maldição da Fraqueza e Imolação quando sua classe permitir, priorizando o tanque e alvos sob pressão.", role = "HEALER", type = "DISPEL" },
            { title = "Imolação", description = "Interrompa o lançamento para evitar o dano inicial e o efeito de dano periódico.", role = "DPS", type = "INTERRUPT" },
        },
        tips = {
            "Não enfrente o chefe e os dois auxiliares ao mesmo tempo sem controle.",
            "Interromper Imolação reduz bastante a pressão sobre o curador.",
            "Dê tempo ao tanque se Maldição da Fraqueza estiver ativa.",
        },
        tldr = {
            "Controle um auxiliar e mate o outro primeiro.",
            "INTERROMPA: Imolação.",
            "REMOVA: Maldição da Fraqueza e Imolação quando possível.",
        },
    },

    ["Bazzalan"] = {
        dungeonName = "Cavernas Ígneas",
        instanceID = 389,
        encounterID = 2735,
        npcID = 11519,
        journalOrder = 4,
        sourceName = "Bazzalan",
        abilities = {
            { title = "Dois auxiliares", description = "Puxe o auxiliar isolável primeiro; controle o segundo e reduza o número de inimigos ativos.", role = "ALL", type = "MOVEMENT" },
            { title = "Golpe Sinistro", description = "Mantenha Bazzalan estável e use mitigação se sua vida cair; o golpe causa dano físico forte em um alvo.", role = "TANK", type = "TANK_CD" },
            { title = "Veneno Mortal", description = "Remova o veneno do tanque quando sua classe permitir e acompanhe as aplicações enquanto os auxiliares estiverem vivos.", role = "HEALER", type = "DISPEL" },
            { title = "Foco no chefe", description = "Depois de controlar ou eliminar os auxiliares, concentre Bazzalan para reduzir o dano de Golpe Sinistro e Veneno Mortal.", role = "DPS", type = "MOVEMENT" },
        },
        tips = {
            "O auxiliar à esquerda pode ser puxado separadamente antes do chefe.",
            "Controle o auxiliar restante e evite dividir o dano do grupo.",
            "Remova Veneno Mortal sempre que houver um recurso disponível.",
        },
        tldr = {
            "Puxe um auxiliar separado e controle o outro.",
            "CURADOR: remova Veneno Mortal quando possível.",
            "DPS: concentre Bazzalan após controlar os auxiliares.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end
