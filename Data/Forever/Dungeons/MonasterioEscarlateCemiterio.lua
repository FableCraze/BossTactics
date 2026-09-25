-- Data/Forever/Dungeons/MonasterioEscarlateCemiterio.lua
-- WoW Forever beta 1.60.1.70009 (2026-09-25).
-- Encounter IDs/order: DungeonEncounter client table, MapID 189.
-- NPC IDs/PT-BR names: Wowhead Forever, cross-checked against localized Classic data.
-- Mechanics/route: Classic references; validation in the Forever beta is pending.

local bosses = {
    ["Interrogador Vishas"] = {
        dungeonName = "Monastério Escarlate: Cemitério",
        instanceID = 189,
        encounterID = 444,
        npcID = 3983,
        journalOrder = 1,
        sourceName = "Interrogator Vishas",
        abilities = {
            { title = "Auxiliar Escarlate", description = "Controle ou elimine o humanoide que acompanha Vishas antes de concentrar dano no chefe.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Imolação", description = "O efeito causa dano de Fogo ao longo do tempo; remova-o com uma habilidade compatível ou sustente o alvo até o efeito terminar.", role = "ALL", type = "DISPEL" },
            { title = "Dano periódico", description = "Acompanhe o alvo de Imolação sem perder a estabilidade do tanque, especialmente enquanto o auxiliar ainda estiver ativo.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Limpe a câmara de tortura e espere as patrulhas antes de atacar Vishas.",
            "Marque o auxiliar e combine um controle antes da puxada.",
            "Puxe o encontro para uma área já limpa para impedir que inimigos em fuga tragam outro grupo.",
        },
        tldr = {
            "Limpe a câmara e espere as patrulhas.",
            "Controle ou elimine o auxiliar primeiro.",
            "REMOVER: Imolação quando compatível.",
            "CURADOR: acompanhe o dano periódico.",
        },
    },

    ["Mago Sangrento Thalnos"] = {
        dungeonName = "Monastério Escarlate: Cemitério",
        instanceID = 189,
        encounterID = 2779,
        npcID = 4543,
        journalOrder = 2,
        sourceName = "Bloodmage Thalnos",
        abilities = {
            { title = "Seta Sombria", description = "Interrompa o lançamento para reduzir o dano mágico sobre o alvo e conservar os recursos do curador.", role = "ALL", type = "INTERRUPT" },
            { title = "Aguilhão Flamejante", description = "Thalnos cria uma área de fogo sobre um ponto escolhido; saia da área e abra espaço para que os demais jogadores também se movam.", role = "ALL", type = "MOVEMENT" },
            { title = "Nova de Fogo", description = "A explosão atinge jogadores próximos; funções de longo alcance devem manter distância e os corpo a corpo devem preservar a própria vida.", role = "ALL", type = "MOVEMENT" },
            { title = "Pressão mágica", description = "Mantenha o tanque e os jogadores corpo a corpo estáveis durante as habilidades de fogo, sem gastar toda a mana antes da luta terminar.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Limpe a Tumba da Honra e os acessos antes de iniciar Thalnos.",
            "Mantenha jogadores de longo alcance afastados do espaço corpo a corpo.",
            "Combine interrupções para Seta Sombria e não permaneça no Aguilhão Flamejante.",
            "Não há fase adicional confirmada para esta versão; mantenha ameaça, interrupções e cura sustentadas.",
        },
        tldr = {
            "Limpe a tumba antes da puxada.",
            "INTERROMPER: Seta Sombria.",
            "SAIR: Aguilhão Flamejante.",
            "LONGO ALCANCE: fique fora da Nova de Fogo.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["Monastério Escarlate: Cemitério"] = {
    summary = {
        "ENTRADA: use o portal da extrema esquerda; a ala Cemitério não exige a Chave Escarlate.",
        "CÂMARA DE TORTURA: avance em grupos pequenos, derrote Interrogador Vishas e fale com Vorrel Sengutz somente se o grupo quiser a missão associada.",
        "CLAUSTRO ABANDONADO: siga o percurso linear, controle inimigos que tentem fugir e verifique os mausoléus sem separar o grupo.",
        "RAROS: Ashir, o Insone, Campeão Caído e Espinha de Ferro podem não estar presentes; nenhum deles aumenta o contador de encontros.",
        "TUMBA DA HONRA: limpe a descida e a sala final antes de enfrentar Mago Sangrento Thalnos.",
    },
    enemies = {
        { enemy = "Humanoides Escarlate", title = "Fuga por reforços", description = "Use lentidão, imobilização ou atordoamento e finalize inimigos enfraquecidos antes que alcancem outro grupo.", role = "ALL", type = "STOP", priority = 1 },
        { enemy = "Conjuradores Escarlate", title = "Lançamentos hostis", description = "Interrompa lançamentos e use linha de visão para trazer conjuradores até o tanque sem avançar para o próximo grupo.", role = "ALL", type = "INTERRUPT", priority = 1 },
        { enemy = "Mortos-vivos do cemitério", title = "Grupos próximos", description = "Puxe poucos inimigos por vez para uma área já limpa e controle alvos adicionais quando as patrulhas se aproximarem.", role = "ALL", type = "PRIORITY_TARGET", priority = 2 },
        { enemy = "Ashir, o Insone", title = "Raro: medo e drenagem", description = "Limpe o entorno antes de enfrentá-lo, interrompa Sifão de Alma quando possível e reagrupe o grupo após Aterrorizar.", role = "ALL", type = "INTERRUPT", priority = 3 },
        { enemy = "Campeão Caído", title = "Raro: ataques frontais", description = "Somente o tanque permanece à frente; DPS atacam por trás para evitar Cutilar e preservam vida para a pressão final.", role = "ALL", type = "MOVEMENT", priority = 3 },
        { enemy = "Espinha de Ferro", title = "Raro: veneno e maldição", description = "Saia da Nuvem de Veneno e remova Maldição da Fraqueza somente com uma habilidade compatível.", role = "ALL", type = "DISPEL", priority = 3 },
    },
}
