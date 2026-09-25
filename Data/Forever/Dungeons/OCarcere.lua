-- Data/Forever/Dungeons/OCarcere.lua
-- WoW Forever beta 1.60.1.70009 (2026-09-25).
-- Encounter IDs/order: DungeonEncounter client table, MapID 34.
-- NPC IDs/PT-BR names: Wowhead Forever, cross-checked against localized quests/roster.
-- Mechanics/route: Classic references and Forever guide comparison; in-game validation is pending.

local bosses = {
    ["Targorr, o Horror"] = {
        dungeonName = "O Cárcere",
        instanceID = 34,
        encounterID = 2756,
        npcID = 1696,
        journalOrder = 1,
        sourceName = "Targorr the Dread",
        abilities = {
            { title = "Surra", description = "Targorr pode realizar ataques corpo a corpo adicionais; o tanque mantém mitigação e o curador se prepara para uma sequência repentina de dano.", role = "TANK", type = "TANK_CD" },
            { title = "Enfurecer", description = "Quando Targorr se enfurecer, concentre o dano no chefe e use recursos defensivos para atravessar o aumento de pressão.", role = "ALL", type = "UTILITY" },
        },
        tips = {
            "Targorr pode aparecer em diferentes celas do primeiro corredor; confira cada cela sem separar o grupo.",
            "Puxe os prisioneiros próximos para o corredor e limpe a área antes de iniciar o chefe.",
            "Não há fase adicional confirmada: preserve recursos para Enfurecer e mantenha ameaça e cura constantes.",
        },
        tldr = {
            "Limpe a cela e o corredor antes de puxar.",
            "TANQUE: prepare mitigação para Surra.",
            "Concentre o chefe quando Enfurecer começar.",
        },
    },

    ["Kam Fundafúria"] = {
        dungeonName = "O Cárcere",
        instanceID = 34,
        encounterID = 2757,
        npcID = 1666,
        journalOrder = 2,
        sourceName = "Kam Deepfury",
        abilities = {
            { title = "Postura Defensiva", description = "Kam assume uma postura resistente; mantenha dano sustentado e não comprometa o posicionamento tentando acelerar a luta.", role = "DPS", type = "UTILITY" },
            { title = "Bloqueio Aprimorado", description = "Ataques bloqueados prolongam a luta; mantenha a pressão de forma segura enquanto o tanque conserva o controle da cela.", role = "ALL", type = "UTILITY" },
            { title = "Batida de Escudo", description = "O golpe de escudo pressiona o alvo atual; o tanque usa mitigação e o curador mantém margem de vida para o impacto.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Kam pode aparecer em diferentes celas; procure-o enquanto limpa o percurso, sem avançar sozinho.",
            "Retire os demais prisioneiros da cela antes da puxada.",
            "Mantenha a luta no corredor já limpo para evitar que o grupo atraia outra cela.",
        },
        tldr = {
            "Limpe os prisioneiros ao redor de Kam.",
            "TANQUE: prepare mitigação para Batida de Escudo.",
            "Mantenha dano sustentado durante Postura Defensiva.",
        },
    },

    ["Ramoque"] = {
        dungeonName = "O Cárcere",
        instanceID = 34,
        encounterID = 2758,
        npcID = 1717,
        journalOrder = 3,
        sourceName = "Hamhock",
        abilities = {
            { title = "Cadeia de Raios", description = "O raio pode saltar entre jogadores próximos; espalhe o grupo e recupere os alvos atingidos antes da próxima sequência.", role = "ALL", type = "MOVEMENT" },
            { title = "Sede de Sangue", description = "Ramoque aumenta sua pressão ofensiva; o tanque mantém mitigação e o grupo concentra dano para não prolongar esse período.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Limpe o corredor e a entrada da sala antes de enfrentar Ramoque.",
            "Jogadores de longo alcance devem ocupar posições separadas sem se aproximar de celas ainda ocupadas.",
            "O curador deve recuperar o grupo após Cadeia de Raios sem perder a estabilidade do tanque.",
        },
        tldr = {
            "ESPALHAR: limite os saltos de Cadeia de Raios.",
            "Não se afaste para perto de celas ainda ocupadas.",
            "TANQUE: use mitigação durante Sede de Sangue.",
            "CURADOR: recupere o grupo entre as cadeias.",
        },
    },

    ["Flávio Lúcio"] = {
        dungeonName = "O Cárcere",
        instanceID = 34,
        encounterID = 2759,
        npcID = 1663,
        journalOrder = 4,
        sourceName = "Dextren Ward",
        abilities = {
            { title = "Brado Intimidador", description = "O brado faz jogadores perderem o controle e correrem; limpe as celas próximas antes da luta e reagrupe assim que o medo terminar.", role = "ALL", type = "STOP" },
            { title = "Golpear", description = "O golpe aumenta a pressão sobre o alvo atual; o tanque mantém Flávio voltado para si e o curador preserva uma margem segura de vida.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Limpe completamente as celas e corredores próximos antes de puxar Flávio Lúcio.",
            "Lute em uma área já limpa para que jogadores amedrontados não tragam outro grupo.",
            "Depois do Brado Intimidador, o tanque deve restabelecer o controle antes que os DPS retomem todo o dano.",
        },
        tldr = {
            "Limpe todas as celas próximas antes da luta.",
            "MEDO: reagrupe após Brado Intimidador.",
            "TANQUE: restabeleça a ameaça antes do dano total.",
        },
    },

    ["Basílio Taborda"] = {
        dungeonName = "O Cárcere",
        instanceID = 34,
        encounterID = 2760,
        npcID = 1716,
        journalOrder = 5,
        sourceName = "Bazil Thredd",
        abilities = {
            { title = "Bomba de Fumaça", description = "A bomba atordoa e impede ações por um período; entre com o tanque estável e recupere o controle do encontro assim que o efeito terminar.", role = "ALL", type = "STOP" },
            { title = "Brado de Batalha", description = "O brado reforça a pressão de Basílio; mantenha mitigação e cura sustentadas em vez de gastar todos os recursos antes da Bomba de Fumaça.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Limpe a sala final e espere o grupo recuperar vida e recursos antes da puxada.",
            "Mantenha a vida do tanque alta para que o grupo atravesse com segurança o atordoamento de Bomba de Fumaça.",
            "Após o atordoamento, o tanque restabelece ameaça e posicionamento antes que o grupo retome dano total.",
        },
        tldr = {
            "Entre com a sala limpa e o grupo recuperado.",
            "CURADOR: mantenha o tanque estável antes da Bomba de Fumaça.",
            "Após o atordoamento, restabeleça ameaça e posição.",
            "TANQUE: preserve mitigação para a pressão sustentada.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["O Cárcere"] = {
    summary = {
        "ENTRADA: reúna o grupo no corredor e puxe os prisioneiros para fora das celas, sem avançar até os grupos.",
        "ANEL DE CELAS: procure Targorr e Kam nas celas indicadas pelo cliente; as posições podem variar e ninguém deve explorar sozinho.",
        "ALA OCIDENTAL: limpe as celas ao redor de Flávio Lúcio antes do Brado Intimidador.",
        "ALA ORIENTAL: espalhe-se com segurança para Ramoque e prossiga para Basílio Taborda somente depois de limpar a sala final.",
        "RETORNO: inimigos podem reaparecer; verifique corredores já percorridos antes de recuar.",
    },
    enemies = {
        { enemy = "Prisioneiros do Cárcere", title = "Fuga por reforços", description = "Muitos inimigos tentam fugir quando estão enfraquecidos; use lentidão, imobilização ou atordoamento e finalize-os antes que alcancem outra cela.", role = "ALL", type = "STOP", priority = 1 },
        { enemy = "Prisioneiros do Cárcere", title = "Puxada para o corredor", description = "O tanque traz cada grupo para uma área já limpa; o restante do grupo espera no corredor para não ativar outras celas.", role = "TANK", type = "MOVEMENT", priority = 1 },
        { enemy = "Patrulhas e grupos das celas", title = "Controle de puxada", description = "Espere a patrulha e concentre um grupo por vez; controles e medos perto de celas ocupadas podem transformar a puxada em vários grupos.", role = "ALL", type = "UTILITY", priority = 2 },
        { enemy = "Corredores já limpos", title = "Reaparecimento de inimigos", description = "Ao retornar ou recuperar uma falha, confirme se os grupos reapareceram antes de atravessar o corredor.", role = "ALL", type = "UTILITY", priority = 2 },
        { enemy = "Bruegal Ferroque", title = "Raro opcional", description = "Procure-o nas celas durante o percurso; enfrente-o somente se estiver presente e o grupo decidir fazer o desvio.", role = "ALL", type = "UTILITY", priority = 3 },
    },
}
