-- Data/Forever/Dungeons/MonasterioEscarlateBiblioteca.lua
-- WoW Forever beta 1.60.1.70009 (2026-09-25).
-- Encounter IDs/order: DungeonEncounter client table, MapID 189.
-- NPC IDs/PT-BR names: Wowhead Forever, cross-checked against localized Classic data.
-- Mechanics/route: Classic references; validation in the Forever beta is pending.

local bosses = {
    ["Mestre de Matilha Lobato"] = {
        dungeonName = "Monastério Escarlate: Biblioteca",
        instanceID = 189,
        encounterID = 446,
        npcID = 3974,
        journalOrder = 1,
        sourceName = "Houndmaster Loksey",
        abilities = {
            { title = "Cães Rastreadores Escarlates", description = "Lobato começa acompanhado por três feras; controle uma quando possível, o tanque mantém as demais e os DPS eliminam os cães antes do chefe.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Sede de Sangue", description = "O efeito aumenta a pressão física de Lobato e dos cães; remova-o com uma dissipação ofensiva compatível ou use controle e mitigação até o efeito terminar.", role = "ALL", type = "DISPEL" },
            { title = "Múltiplos atacantes", description = "Estabeleça ameaça sobre Lobato e os cães antes que o grupo use dano em área; prepare mitigação se vários alvos permanecerem ativos.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Lobato fica em uma sala lateral depois do primeiro corredor e é opcional para concluir o percurso até Doan.",
            "Limpe o pátio e a entrada da sala antes de atacar para impedir que um cão ou jogador alcance outro grupo.",
            "Marque os cães, combine controle de fera quando disponível e dê tempo para o tanque estabelecer ameaça.",
            "Não concentre dano em Lobato enquanto os cães estiverem soltos sobre o curador ou os DPS.",
        },
        tldr = {
            "Opcional: limpe o pátio antes da sala lateral.",
            "CONTROLE: mantenha um cão fora da luta quando possível.",
            "FOCO: elimine os cães antes de Lobato.",
            "REMOVER: Sede de Sangue com dissipação compatível.",
        },
    },

    ["Arcanista Doan"] = {
        dungeonName = "Monastério Escarlate: Biblioteca",
        instanceID = 189,
        encounterID = 447,
        npcID = 6487,
        journalOrder = 2,
        sourceName = "Arcanist Doan",
        abilities = {
            { title = "Explosão Arcana", description = "A explosão atinge jogadores próximos de Doan; funções de longo alcance permanecem afastadas e os corpo a corpo preservam a própria vida.", role = "ALL", type = "MOVEMENT" },
            { title = "Silêncio", description = "O efeito impede lançamentos ao redor do chefe; curador e conjuradores mantêm distância para continuar agindo durante a pressão sobre o grupo.", role = "ALL", type = "MOVEMENT" },
            { title = "Polimorfia", description = "Doan retira temporariamente um jogador da luta; remova o efeito somente com uma habilidade compatível e mantenha tanque e curador protegidos enquanto o alvo estiver controlado.", role = "ALL", type = "DISPEL" },
            { title = "Bolha Arcana e Detonação", description = "Quando Doan se proteger e anunciar o fogo purificador, pare de atacá-lo e afaste-se imediatamente; retorne apenas depois que a detonação terminar.", role = "ALL", type = "MOVEMENT" },
        },
        tips = {
            "Limpe a câmara de Doan e o corredor anterior antes de iniciar o combate.",
            "Mantenha o chefe em uma posição que permita ao grupo recuar para as bordas ou para o corredor sem atrair inimigos.",
            "Curador e conjuradores devem ficar fora do espaço corpo a corpo para reduzir o impacto de Explosão Arcana e Silêncio.",
            "Depois da luta, saqueie a Chave Escarlate no baú da sala; ela dá acesso ao Arsenal e à Catedral, mas não é requisito para a Biblioteca.",
        },
        tldr = {
            "LONGO ALCANCE: fique afastado do chefe.",
            "REMOVER: Polimorfia somente com habilidade compatível.",
            "BOLHA E AVISO: pare o dano e afaste-se.",
            "VOLTAR: ataque após a Detonação.",
            "SAQUEAR: pegue a Chave Escarlate no baú.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["Monastério Escarlate: Biblioteca"] = {
    summary = {
        "ENTRADA: use o portal da direita; a Biblioteca não exige a Chave Escarlate.",
        "PRIMEIRO CORREDOR: use linha de visão para aproximar conjuradores e impeça inimigos enfraquecidos de fugir para outro grupo.",
        "PÁTIO: siga pela passagem lateral para o encontro opcional com Mestre de Matilha Lobato ou atravesse para continuar a ala.",
        "BIBLIOTECA: avance em grupos pequenos, interrompa curas e ataques à distância e não lute perto de salas ainda ocupadas.",
        "CÂMARA FINAL: limpe o corredor e a sala de Arcanista Doan; após a vitória, recolha a Chave Escarlate no baú.",
    },
    enemies = {
        { enemy = "Capelão Escarlate", title = "Cura e Palavra de Poder: Escudo", description = "Interrompa a cura e remova o escudo com uma dissipação ofensiva compatível antes de retomar o dano no restante do grupo.", role = "ALL", type = "INTERRUPT", priority = 1 },
        { enemy = "Inimigos Escarlates em fuga", title = "Busca por reforços", description = "Use lentidão, imobilização ou atordoamento e finalize o alvo antes que ele alcance outra sala ou patrulha.", role = "ALL", type = "STOP", priority = 1 },
        { enemy = "Vaticinador Escarlate", title = "Bola de Fogo", description = "Interrompa o lançamento ou use linha de visão para trazer o conjurador até o tanque sem avançar para o próximo grupo.", role = "ALL", type = "INTERRUPT", priority = 2 },
        { enemy = "Senhor das Feras Escarlate", title = "Matilha vinculada", description = "Controle um cão quando possível, dê tempo para o tanque reunir a matilha e elimine as feras sem espalhar ameaça.", role = "ALL", type = "PRIORITY_TARGET", priority = 2 },
        { enemy = "Monge Escarlate", title = "Chute", description = "Curador e conjuradores evitam permanecer junto ao monge para reduzir interrupções; o tanque mantém o inimigo longe da retaguarda.", role = "ALL", type = "MOVEMENT", priority = 2 },
    },
}
