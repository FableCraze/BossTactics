-- Data/Forever/Dungeons/BastilhaPresaNegra.lua
-- WoW Forever beta 1.60.1.70009 (2026-09-25).
-- Encounter IDs/order: DungeonEncounter client table, MapID 33.
-- NPC IDs/PT-BR names: Wowhead Forever, cross-checked against the localized roster.
-- Mechanics/route: Classic references; validation in the Forever beta is pending.

local bosses = {
    ["Rethilgore"] = {
        dungeonName = "Bastilha da Presa Negra",
        instanceID = 33,
        encounterID = 2748,
        npcID = 3914,
        journalOrder = 1,
        sourceName = "Rethilgore",
        abilities = {
            { title = "Drenar Alma", description = "Interrompa a canalização quando possível para encerrar o dano de Sombra sobre o alvo.", role = "ALL", type = "INTERRUPT" },
            { title = "Alvo da drenagem", description = "Recupere o jogador atingido enquanto a canalização estiver ativa e mantenha o tanque estável.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Limpe as celas e inimigos próximos antes de enfrentar Rethilgore.",
            "Depois da luta, liberte o prisioneiro da facção do grupo e acompanhe-o até ele abrir a porta do pátio.",
            "Não avance sozinho enquanto o evento da porta estiver em andamento.",
        },
        tldr = {
            "Limpe a área das celas antes de puxar.",
            "INTERROMPER: Drenar Alma quando possível.",
            "CURADOR: recupere rapidamente o alvo da drenagem.",
            "Após a luta, liberte o prisioneiro para abrir o pátio.",
        },
    },

    ["Garraguda, o Açougueiro"] = {
        dungeonName = "Bastilha da Presa Negra",
        instanceID = 33,
        encounterID = 2749,
        npcID = 3886,
        journalOrder = 2,
        sourceName = "Razorclaw the Butcher",
        abilities = {
            { title = "Drenagem Sanguinária", description = "Os ataques do açougueiro drenam o alvo e ajudam Garraguda a se sustentar; mantenha ameaça e mitigação consistentes.", role = "TANK", type = "TANK_CD" },
            { title = "Pressão sustentada", description = "Mantenha o tanque com vida segura para compensar a drenagem e evite prolongar a luta com inimigos adicionais.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Garraguda é um desvio pela cozinha; limpe a sala e espere patrulhas antes de puxar.",
            "Puxe para uma área já limpa, sem trazer os grupos da sala de jantar.",
            "Não há mudança de fase confirmada: mantenha ameaça, cura e dano constantes.",
        },
        tldr = {
            "Limpe a cozinha e as patrulhas próximas.",
            "TANQUE: mantenha mitigação durante Drenagem Sanguinária.",
            "CURADOR: sustente o tanque durante toda a luta.",
        },
    },

    ["Barão Silverlaine"] = {
        dungeonName = "Bastilha da Presa Negra",
        instanceID = 33,
        encounterID = 2750,
        npcID = 3887,
        journalOrder = 3,
        sourceName = "Baron Silverlaine",
        abilities = {
            { title = "Véu de Sombras", description = "A maldição reduz fortemente a cura recebida; remova-a imediatamente quando o grupo tiver uma habilidade compatível.", role = "ALL", type = "DISPEL" },
            { title = "Cura reduzida", description = "Prepare cura adicional para o alvo de Véu de Sombras e peça apoio de uma função híbrida se a maldição não puder ser removida.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Confirme antes da puxada quem consegue remover maldições.",
            "Mantenha Silverlaine em posição estável e evite iniciar com patrulhas próximas.",
            "Se não houver remoção compatível, preserve recursos defensivos para o período de cura reduzida.",
        },
        tldr = {
            "REMOVER: Véu de Sombras é uma maldição.",
            "CURADOR: prepare cura extra enquanto o efeito estiver ativo.",
            "TANQUE: guarde mitigação se a maldição não puder ser removida.",
        },
    },

    ["Comandante Floraval"] = {
        dungeonName = "Bastilha da Presa Negra",
        instanceID = 33,
        encounterID = 2751,
        npcID = 4278,
        journalOrder = 4,
        sourceName = "Commander Springvale",
        abilities = {
            { title = "Auxiliares", description = "Elimine primeiro o Servo Assombrado e mantenha o Guarda Lamuriento afastado dos conjuradores para reduzir as ameaças ativas.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Gritos do Passado", description = "O Guarda Lamuriento silencia jogadores próximos; curador e DPS de longo alcance devem permanecer afastados dele.", role = "ALL", type = "MOVEMENT" },
            { title = "Luz Sagrada", description = "Interrompa a cura de Floraval para impedir que o encontro se prolongue.", role = "ALL", type = "INTERRUPT" },
            { title = "Martelo da Justiça", description = "O atordoamento pode impedir o tanque de agir; estabilize a ameaça e a vida do grupo até ele recuperar o controle.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Não concentre Floraval enquanto os dois auxiliares ainda pressionam o grupo.",
            "Separe o Guarda Lamuriento do curador e dos demais conjuradores.",
            "Reserve uma interrupção para Luz Sagrada mesmo durante o controle dos auxiliares.",
        },
        tldr = {
            "Elimine os auxiliares antes de Floraval.",
            "AFASTAR: conjuradores ficam longe do Guarda Lamuriento.",
            "INTERROMPER: Luz Sagrada.",
            "TANQUE: prepare-se para Martelo da Justiça.",
        },
    },

    ["Odo, o Vigia Cego"] = {
        dungeonName = "Bastilha da Presa Negra",
        instanceID = 33,
        encounterID = 2752,
        npcID = 4279,
        journalOrder = 5,
        sourceName = "Odo the Blindwatcher",
        abilities = {
            { title = "Morcegos", description = "Recolha os morcegos junto do tanque, vire-os para longe do grupo e elimine-os antes de concentrar Odo.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Raiva Uivante", description = "Odo fica progressivamente mais perigoso; depois dos morcegos, concentre dano nele e mantenha mitigação disponível.", role = "TANK", type = "TANK_CD" },
            { title = "Pico de dano", description = "Acompanhe a pressão crescente no tanque e evite gastar toda a cura antes de Odo estar isolado.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Odo e seus morcegos entram juntos; marque a prioridade antes de iniciar.",
            "Somente o tanque deve permanecer à frente dos morcegos.",
            "Depois dos auxiliares, concentre Odo para limitar a duração da pressão crescente.",
        },
        tldr = {
            "Recolha e elimine os morcegos primeiro.",
            "TANQUE: vire os morcegos para longe do grupo.",
            "Depois, concentre Odo antes que Raiva Uivante aumente a pressão.",
            "CURADOR: preserve recursos para o fim da luta.",
        },
    },

    ["Fenrus, o Devorador"] = {
        dungeonName = "Bastilha da Presa Negra",
        instanceID = 33,
        encounterID = 2753,
        npcID = 4274,
        journalOrder = 6,
        sourceName = "Fenrus the Devourer",
        abilities = {
            { title = "Saliva Tóxica", description = "O veneno causa dano periódico e drena mana; remova-o com uma habilidade compatível, priorizando funções dependentes de mana.", role = "ALL", type = "DISPEL" },
            { title = "Servos do Caos", description = "Após a morte de Fenrus, inimigos adicionais aparecem; reúna o grupo e elimine-os antes de saquear ou recuperar recursos.", role = "ALL", type = "PRIORITY_TARGET" },
        },
        tips = {
            "Entre com recursos suficientes para Fenrus e para o grupo que surge logo depois.",
            "Combine a remoção de veneno antes da puxada.",
            "Não relaxe quando Fenrus morrer: espere os Servos do Caos e deixe o tanque recolhê-los.",
        },
        tldr = {
            "REMOVER: Saliva Tóxica é veneno.",
            "Preserve recursos para os inimigos após o chefe.",
            "TANQUE: recolha os Servos do Caos assim que aparecerem.",
            "DPS: elimine os adicionais antes de saquear.",
        },
    },

    ["Nandos, o Mestre de Lobos"] = {
        dungeonName = "Bastilha da Presa Negra",
        instanceID = 33,
        encounterID = 2754,
        npcID = 3927,
        journalOrder = 7,
        sourceName = "Wolf Master Nandos",
        abilities = {
            { title = "Matilha inicial", description = "Elimine os worgs da sala antes de concentrar Nandos para reduzir a pressão sobre tanque e curador.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Chamados da matilha", description = "Nandos invoca novos worgs e um horror lupino; mude imediatamente a prioridade para cada adicional.", role = "DPS", type = "PRIORITY_TARGET" },
            { title = "Controle da matilha", description = "Recolha cada worg invocado e mantenha-o junto de Nandos sem expor o curador.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Limpe os worgs acessíveis antes de iniciar Nandos.",
            "Marque os adicionais e não divida dano entre vários alvos sem uma prioridade clara.",
            "Mantenha o curador afastado do ponto onde a matilha será reunida.",
        },
        tldr = {
            "Elimine a matilha inicial.",
            "TANQUE: recolha cada worg invocado.",
            "DPS: adicionais sempre antes de Nandos.",
            "Proteja o curador da matilha.",
        },
    },

    ["Arquimago Arugal"] = {
        dungeonName = "Bastilha da Presa Negra",
        instanceID = 33,
        encounterID = 2755,
        npcID = 4275,
        journalOrder = 8,
        sourceName = "Archmage Arugal",
        abilities = {
            { title = "Seta Caótica", description = "Arugal lança ataques de Sombra pesados no alvo atual; o tanque deve manter mitigação e o curador deve sustentar cura frequente.", role = "TANK", type = "TANK_CD" },
            { title = "Porto Sombrio", description = "Arugal se teleporta entre as plataformas; ataque de uma posição com linha de visão do curador e não o persiga de forma desordenada.", role = "ALL", type = "MOVEMENT" },
            { title = "Choque Trovejante", description = "Jogadores próximos sofrem dano e atordoamento; longo alcance deve usar a plataforma e manter distância do chefe.", role = "ALL", type = "MOVEMENT" },
            { title = "Maldição de Arugal", description = "Um jogador fica hostil ao grupo e sob controle de Arugal; interrompa o dano no aliado e use somente uma remoção compatível com maldição.", role = "ALL", type = "DISPEL" },
            { title = "Curador controlado", description = "Se o curador for atingido pela Maldição de Arugal, uma função híbrida deve sustentar o tanque até o controle terminar.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Reúna o grupo na plataforma de entrada para manter linha de visão enquanto Arugal se teleporta.",
            "Jogadores corpo a corpo não devem saltar entre plataformas e perder alcance do curador.",
            "Combine quem remove maldições e quem assume cura de emergência se o curador for controlado.",
            "Mantenha a vida do tanque alta para as sequências de Seta Caótica.",
        },
        tldr = {
            "Use a plataforma e preserve linha de visão do curador.",
            "Não persiga Arugal entre plataformas.",
            "REMOVER: Maldição de Arugal quando compatível.",
            "LONGO ALCANCE: fique fora de Choque Trovejante.",
            "CURADOR: sustente o tanque contra Seta Caótica.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["Bastilha da Presa Negra"] = {
    summary = {
        "CELAS: derrote Rethilgore, liberte o prisioneiro da facção do grupo e acompanhe-o até a porta do pátio.",
        "PÁTIO: avance em puxadas controladas; a cozinha leva a Garraguda e o salão leva a Barão Silverlaine.",
        "ALA INTERNA: elimine os auxiliares de Comandante Floraval e mantenha conjuradores afastados dos Guardas Lamurientos.",
        "TORRES: continue por Odo e prepare-se para os inimigos que surgem imediatamente depois de Fenrus.",
        "MATILHA: limpe os worgs e derrote Nandos antes de subir para a torre final.",
        "ARUGAL: reúna o grupo na plataforma para preservar linha de visão durante os teletransportes.",
    },
    enemies = {
        { enemy = "Guarda Lamuriento", title = "Gritos do Passado", description = "Afaste curador e conjuradores; o grito silencia jogadores próximos e pode interromper a estabilização do grupo.", role = "ALL", type = "MOVEMENT", priority = 1 },
        { enemy = "Lunâmbulo Presa Negra", title = "Escudo Antimagia", description = "Durante a imunidade a magia, conjuradores devem trocar de alvo ou aguardar; dano físico mantém a pressão neste inimigo.", role = "DPS", type = "UTILITY", priority = 1 },
        { enemy = "Servo Assombrado", title = "Espíritos Assombradores", description = "Elimine o servo rapidamente para evitar a maldição que continua evocando espíritos sobre o alvo.", role = "ALL", type = "PRIORITY_TARGET", priority = 1 },
        { enemy = "Servos do Caos", title = "Onda após Fenrus", description = "Não pare para saquear: o tanque recolhe a onda e os DPS concentram um servo por vez.", role = "ALL", type = "PRIORITY_TARGET", priority = 1 },
        { enemy = "Capitão Devoto da Morte", title = "Raro opcional", description = "Este raro pode aparecer antes de Fenrus; enfrente-o somente se estiver presente e o grupo quiser o saque.", role = "ALL", type = "UTILITY", priority = 3 },
        { enemy = "Corcel Vil", title = "Estábulo opcional", description = "Os corcéis do pátio são opcionais e causam forte pressão corpo a corpo; puxe poucos por vez e somente se o grupo decidir limpar o estábulo.", role = "ALL", type = "UTILITY", priority = 3 },
    },
}
