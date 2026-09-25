-- Data/Forever/Dungeons/CavernaUlulante.lua
-- WoW Forever beta 1.60.1.69977 (2026-09-24).
-- Encounter IDs/order: DungeonEncounter client table, MapID 43.
-- NPC IDs/PT-BR names: Wowhead Forever, cross-checked against the localized roster.
-- Mechanics/route: Classic references; validation in the Forever beta is pending.

local bosses = {
    ["Lady Sucurina"] = {
        dungeonName = "Caverna Ululante",
        instanceID = 43,
        encounterID = 585,
        npcID = 3671,
        journalOrder = 1,
        sourceName = "Lady Anacondra",
        abilities = {
            { title = "Toque de Cura", description = "Interrompa o lançamento para impedir que Sucurina recupere a vida de um aliado.", role = "ALL", type = "INTERRUPT" },
            { title = "Sono do Druida", description = "Interrompa o lançamento; se alguém adormecer, remova o efeito quando o grupo tiver uma habilidade compatível.", role = "ALL", type = "DISPEL" },
            { title = "Aura de Espinhos", description = "Ataques corpo a corpo contra Sucurina devolvem dano ao atacante; DPS próximos devem acompanhar a própria vida e evitar dano desnecessário.", role = "DPS", type = "UTILITY" },
        },
        tips = {
            "Limpe os inimigos próximos antes de puxar; Sucurina pode estar cercada por outros grupos.",
            "Combine uma ordem de interrupção para Toque de Cura e Sono do Druida.",
            "Não acelere ataques corpo a corpo se Aura de Espinhos estiver pressionando a cura.",
        },
        tldr = {
            "Limpe os inimigos ao redor antes de iniciar.",
            "INTERROMPER: Toque de Cura e Sono do Druida.",
            "DPS: controle o dano corpo a corpo durante Aura de Espinhos.",
            "CURADOR: remova o sono quando sua habilidade for compatível.",
        },
    },

    ["Lorde Cobrahn"] = {
        dungeonName = "Caverna Ululante",
        instanceID = 43,
        encounterID = 586,
        npcID = 3669,
        journalOrder = 2,
        sourceName = "Lord Cobrahn",
        abilities = {
            { title = "Auxiliares", description = "Controle ou elimine os auxiliares antes de concentrar Cobrahn, reduzindo o número de ameaças ativas.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Toque de Cura", description = "Interrompa a cura para não prolongar o encontro nem aumentar a pressão sobre os recursos do grupo.", role = "ALL", type = "INTERRUPT" },
            { title = "Sono do Druida", description = "Interrompa o lançamento; se o controle entrar, remova-o quando houver uma habilidade compatível disponível.", role = "ALL", type = "DISPEL" },
            { title = "Forma de Serpente", description = "Quando Cobrahn se transformar, estabilize a ameaça e use mitigação para suportar a pressão corpo a corpo maior.", role = "TANK", type = "TANK_CD" },
            { title = "Pressão após a transformação", description = "Reserve mana e uma cura rápida para o tanque durante a Forma de Serpente.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Espere a patrulha se afastar e controle os auxiliares antes de atacar Cobrahn.",
            "Defina quem interrompe a cura e quem cobre o Sono do Druida.",
            "Tanque e curador devem guardar recursos para a transformação em serpente.",
        },
        tldr = {
            "Controle ou elimine os auxiliares primeiro.",
            "INTERROMPER: Toque de Cura e Sono do Druida.",
            "TANQUE: guarde mitigação para a Forma de Serpente.",
            "CURADOR: preserve mana para a transformação.",
        },
    },

    ["Cresh"] = {
        dungeonName = "Caverna Ululante",
        instanceID = 43,
        encounterID = 587,
        npcID = 3653,
        journalOrder = 3,
        sourceName = "Kresh",
        abilities = {
            { title = "Encontro opcional", description = "Cresh é neutro e pode ser ignorado; ataque apenas quando o grupo decidir enfrentar o chefe opcional pelo saque.", role = "ALL", type = "UTILITY" },
            { title = "Combate prolongado", description = "Mantenha ameaça estável e cura sustentada enquanto o grupo causa dano, sem esperar mudanças de fase.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Puxe Cresh para uma posição segura, fora da rota de patrulhas e de outros grupos.",
            "Confirme que todos estão prontos antes de atacar, pois ele não é hostil inicialmente.",
            "Não há fase especial confirmada: mantenha o combate simples e consistente.",
        },
        tldr = {
            "Opcional: só ataque se o grupo quiser enfrentá-lo.",
            "Puxe para uma área segura.",
            "TANQUE: mantenha ameaça estável.",
            "CURADOR: sustente o tanque durante todo o combate.",
        },
    },

    ["Lorde Pítias"] = {
        dungeonName = "Caverna Ululante",
        instanceID = 43,
        encounterID = 588,
        npcID = 3670,
        journalOrder = 4,
        sourceName = "Lord Pythas",
        abilities = {
            { title = "Grupo inicial", description = "Controle ou elimine os inimigos que acompanham Pítias antes de concentrar dano no chefe.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Toque de Cura", description = "Interrompa a cura sempre que for lançada para evitar que o encontro se prolongue.", role = "ALL", type = "INTERRUPT" },
            { title = "Sono do Druida", description = "Interrompa o lançamento; se um jogador adormecer, remova o efeito quando houver uma habilidade compatível.", role = "ALL", type = "DISPEL" },
            { title = "Trovoada", description = "Jogadores de longo alcance devem permanecer afastados da área ao redor de Pítias para evitar o ataque em área.", role = "DPS", type = "MOVEMENT" },
        },
        tips = {
            "Não divida o dano entre Pítias e todos os auxiliares; reduza primeiro o número de inimigos ativos.",
            "Combine interrupções para não deixar Toque de Cura livre enquanto o grupo responde ao sono.",
            "DPS de longo alcance e curador devem usar o espaço disponível fora da área de Trovoada.",
        },
        tldr = {
            "Controle o grupo inicial antes de focar Pítias.",
            "INTERROMPER: Toque de Cura e Sono do Druida.",
            "DPS: longo alcance fica afastado de Trovoada.",
            "CURADOR: remova o sono quando sua habilidade for compatível.",
        },
    },

    ["Skória"] = {
        dungeonName = "Caverna Ululante",
        instanceID = 43,
        encounterID = 589,
        npcID = 3674,
        journalOrder = 5,
        sourceName = "Skum",
        abilities = {
            { title = "Raio Encadeado", description = "O raio pode saltar entre jogadores próximos; espalhem-se para limitar a cadeia e reduzir o dano recebido pelo grupo.", role = "ALL", type = "MOVEMENT" },
            { title = "Recuperação do grupo", description = "Recupere a vida dos alvos atingidos pela cadeia antes que outro lançamento pressione o grupo.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Skória é opcional e pode ser ignorado se o grupo não quiser o saque.",
            "Use o espaço ao redor para não agrupar todos os possíveis saltos do raio.",
            "Espere a vida do grupo se recuperar antes de continuar a puxada após o encontro.",
        },
        tldr = {
            "Opcional: enfrente apenas se o grupo decidir.",
            "Espalhem-se para limitar Raio Encadeado.",
            "CURADOR: recupere o grupo entre os lançamentos.",
        },
    },

    ["Lorde Serpentis"] = {
        dungeonName = "Caverna Ululante",
        instanceID = 43,
        encounterID = 590,
        npcID = 3673,
        journalOrder = 6,
        sourceName = "Lord Serpentis",
        abilities = {
            { title = "Toque de Cura", description = "Interrompa a cura para manter o progresso do grupo e conservar recursos.", role = "ALL", type = "INTERRUPT" },
            { title = "Sono do Druida", description = "Interrompa o lançamento; se o controle atingir alguém, remova-o quando houver uma habilidade compatível.", role = "ALL", type = "DISPEL" },
            { title = "Controle em função essencial", description = "Se o tanque ou o curador adormecer, estabilize os inimigos e evite gastar todos os recursos até a função voltar a agir.", role = "ALL", type = "UTILITY" },
        },
        tips = {
            "Defina uma rotação simples para Toque de Cura e mantenha uma interrupção de reserva para o sono.",
            "Não gaste todos os recursos de sobrevivência de uma vez; preserve uma resposta caso tanque ou curador seja controlado.",
            "Mantenha Serpentis separado de Verdan para não iniciar os dois encontros juntos.",
        },
        tldr = {
            "INTERROMPER: Toque de Cura e Sono do Druida.",
            "Guarde uma resposta para sono no tanque ou curador.",
            "Não puxe Verdan junto com Serpentis.",
        },
    },

    ["Verdan, o Sempre-vivo"] = {
        dungeonName = "Caverna Ululante",
        instanceID = 43,
        encounterID = 591,
        npcID = 5775,
        journalOrder = 7,
        sourceName = "Verdan the Everliving",
        abilities = {
            { title = "Golpes pesados", description = "Verdan pressiona fortemente o tanque; mantenha mitigação ativa e evite expor outros jogadores aos ataques corpo a corpo.", role = "TANK", type = "TANK_CD" },
            { title = "Cura desde o início", description = "Comece o encontro com mana disponível e prepare cura no tanque assim que Verdan alcançar o combate corpo a corpo.", role = "HEALER", type = "HEALER_CD" },
            { title = "Trepadeiras Agarradoras", description = "O ataque atinge e imobiliza jogadores próximos; longo alcance deve permanecer afastado da área ao redor de Verdan.", role = "ALL", type = "MOVEMENT" },
        },
        tips = {
            "Espere o curador recuperar mana antes da puxada; este encontro pune falta de recursos.",
            "O tanque deve iniciar preparado para dano alto, sem depender de uma cura tardia.",
            "Jogadores de longo alcance devem usar a distância para evitar a área de dano e imobilização.",
        },
        tldr = {
            "Entre com vida e mana recuperadas.",
            "TANQUE: use mitigação desde o início.",
            "CURADOR: comece a curar assim que Verdan alcançar o tanque.",
            "DPS: longo alcance fica fora de Trepadeiras Agarradoras.",
        },
    },

    ["Mutanus, o Devorador"] = {
        dungeonName = "Caverna Ululante",
        instanceID = 43,
        encounterID = 592,
        npcID = 3654,
        journalOrder = 8,
        sourceName = "Mutanus the Devourer",
        abilities = {
            { title = "Ondas do ritual", description = "Antes de Mutanus aparecer, controle os inimigos adicionais e priorize os que ameaçarem o Discípulo de Naralex ou o curador.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Pesadelo de Naralex", description = "Interrompa o lançamento quando possível; se alguém adormecer, use somente uma resposta compatível com este efeito, sem presumir que funciona como o sono dos druidas.", role = "ALL", type = "INTERRUPT" },
            { title = "Aterrorizar", description = "O medo retira temporariamente um jogador do controle; estabilize a ameaça e a vida do grupo até ele voltar a agir.", role = "ALL", type = "UTILITY" },
            { title = "Trovoada", description = "Jogadores de longo alcance devem ficar afastados de Mutanus para evitar o dano em área ao redor dele.", role = "ALL", type = "MOVEMENT" },
            { title = "Recuperação após controles", description = "Recupere rapidamente a vida do grupo depois de medo, sono ou dano em área antes de retomar o ritmo normal.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Derrote Lady Sucurina, Lorde Cobrahn, Lorde Pítias e Lorde Serpentis antes de voltar à entrada para iniciar a escolta.",
            "Reúna o grupo, recupere vida e mana e combine quem falará com o Discípulo de Naralex.",
            "Durante a escolta, acompanhe o Discípulo: o tanque recolhe as ondas e os DPS priorizam ameaças ao NPC e ao curador.",
            "Chegue ao ritual com recursos disponíveis; Mutanus aparece depois das ondas do evento.",
            "Longo alcance deve permanecer afastado do chefe e o grupo deve estabilizar após cada controle.",
        },
        tldr = {
            "Prepare vida, mana e funções antes de iniciar a escolta.",
            "Proteja o Discípulo de Naralex durante todas as ondas.",
            "INTERROMPER: Pesadelo de Naralex quando possível.",
            "DPS: longo alcance fica afastado de Trovoada.",
            "CURADOR: estabilize o grupo após sono, medo e dano em área.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["Caverna Ululante"] = {
    summary = {
        "PERCURSO: na caverna inicial, limpe os anéis superiores e encontre Lady Sucurina.",
        "OESTE: siga o rio e as passagens sinuosas até Lorde Cobrahn; volte ao rio depois da luta.",
        "LESTE: passe por Cresh, Lorde Pítias e Skória; continue pelas galerias elevadas até Lorde Serpentis e Verdan.",
        "RETORNO: use a descida para o rio e volte à entrada depois de derrotar os quatro Lordes da Presa.",
        "ESCOLTA: reúna o grupo, recupere vida e mana e combine quem falará com o Discípulo de Naralex.",
        "PROTEÇÃO: acompanhe o Discípulo; o tanque recolhe as ondas e os DPS protegem o NPC e o curador.",
    },
    enemies = {
        { enemy = "Druida da Presa", title = "Toque de Cura", description = "Interrompa a cura; distribua as interrupções quando houver mais de um druida no grupo.", role = "ALL", type = "INTERRUPT", priority = 1 },
        { enemy = "Druida da Presa", title = "Sono do Druida", description = "Interrompa o lançamento e remova o sono quando o grupo tiver uma habilidade compatível.", role = "ALL", type = "DISPEL", priority = 1 },
        { enemy = "Escolta de Naralex", title = "Proteção do Discípulo", description = "Acompanhe o evento sem se adiantar: o tanque recolhe os inimigos e os DPS priorizam quem ameaçar o Discípulo ou o curador.", role = "ALL", type = "PRIORITY_TARGET", priority = 1 },
        { enemy = "Escolta de Naralex", title = "Preparação do grupo", description = "Antes de iniciar, reúna todos, recupere vida e mana e confirme quem falará com o Discípulo.", role = "ALL", type = "UTILITY", priority = 2 },
        { enemy = "Dragão Feérico Anormal", title = "Raro opcional", description = "Este raro pode aparecer nas galerias orientais; enfrente-o apenas se estiver presente e o grupo quiser o saque.", role = "ALL", type = "UTILITY", priority = 3 },
    },
}
