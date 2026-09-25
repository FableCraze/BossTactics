-- Data/Forever/Dungeons/ProfundezasNegras.lua
-- WoW Forever beta 1.60.1.70009 (2026-09-25).
-- Encounter IDs/order: DungeonEncounter client table, MapID 48, DifficultyID 201.
-- NPC IDs/PT-BR names: Wowhead Forever, cross-checked against the localized roster.
-- Mechanics/route: Classic references and Forever guide comparison; in-game validation is pending.

local bosses = {
    ["Ghamoo-ra"] = {
        dungeonName = "Profundezas Negras",
        instanceID = 48,
        encounterID = 2761,
        npcID = 4887,
        journalOrder = 1,
        sourceName = "Ghamoo-ra",
        abilities = {
            { title = "Atropelo", description = "Ghamoo-ra atinge jogadores próximos; somente o tanque deve permanecer junto da frente do chefe e os demais devem abrir espaço.", role = "ALL", type = "MOVEMENT" },
            { title = "Carapaça resistente", description = "A armadura de Ghamoo-ra reduz a eficiência do dano físico; mantenha uma rotação sustentável e não comprometa o posicionamento para acelerar a luta.", role = "DPS", type = "UTILITY" },
        },
        tips = {
            "Limpe o acesso à ilha e reúna o grupo antes de iniciar.",
            "Mantenha jogadores de longo alcance separados e fora da área próxima do chefe.",
            "A luta pode demorar por causa da armadura; preserve mana e mantenha ameaça e cura constantes.",
        },
        tldr = {
            "Limpe o acesso e reúna o grupo.",
            "AFASTAR: somente o tanque fica próximo da frente.",
            "Preserve recursos durante a carapaça resistente.",
        },
    },

    ["Lady Sarevess"] = {
        dungeonName = "Profundezas Negras",
        instanceID = 48,
        encounterID = 2762,
        npcID = 4831,
        journalOrder = 2,
        sourceName = "Lady Sarevess",
        abilities = {
            { title = "Auxiliares naga", description = "Controle um dos auxiliares quando possível e elimine o outro antes de concentrar dano em Sarevess.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Raio Bifurcado", description = "Espalhe o grupo e permaneça atrás do chefe para limitar a quantidade de jogadores atingidos pelo ataque elétrico.", role = "ALL", type = "MOVEMENT" },
            { title = "Nova Congelante", description = "Jogadores próximos podem ficar imobilizados; funções de longo alcance devem manter distância e evitar posições que bloqueiem a saída da caverna.", role = "ALL", type = "MOVEMENT" },
            { title = "Lentidão", description = "O alvo afetado deve evitar perseguir Sarevess ou atravessar outros grupos enquanto estiver com a movimentação reduzida.", role = "ALL", type = "UTILITY" },
        },
        tips = {
            "Limpe a caverna e os naga próximos antes de atacar a patrulha de Sarevess.",
            "Marque a ordem dos auxiliares e combine um controle antes da puxada.",
            "O tanque mantém Sarevess voltada para longe; o restante do grupo se distribui atrás dela.",
        },
        tldr = {
            "Limpe a caverna antes da puxada.",
            "Controle um auxiliar e elimine o outro.",
            "ESPALHAR: fique atrás de Sarevess.",
            "LONGO ALCANCE: evite Nova Congelante.",
        },
    },

    ["Gelihast"] = {
        dungeonName = "Profundezas Negras",
        instanceID = 48,
        encounterID = 2763,
        npcID = 6243,
        journalOrder = 3,
        sourceName = "Geilhast",
        abilities = {
            { title = "Rede", description = "A rede imobiliza o alvo e pode deixar o tanque preso perto de outros grupos; limpe a sala e lute em uma área segura.", role = "TANK", type = "MOVEMENT" },
            { title = "Murlocs da câmara", description = "Elimine os murlocs ao redor antes de Gelihast para evitar que a rede transforme a luta em uma puxada múltipla.", role = "ALL", type = "PRIORITY_TARGET" },
        },
        tips = {
            "Gelihast é um desvio que pode ser ignorado no percurso, mas conta como encontro no cliente Forever.",
            "Limpe progressivamente a câmara e espere as patrulhas antes de puxar o chefe.",
            "Não mova o grupo até Gelihast; traga o chefe para uma área já limpa.",
        },
        tldr = {
            "Opcional no percurso; limpe a câmara se decidir enfrentá-lo.",
            "Puxe Gelihast para uma área segura.",
            "TANQUE: não fique preso pela Rede perto de murlocs.",
        },
    },

    ["Lorgus Jett"] = {
        dungeonName = "Profundezas Negras",
        instanceID = 48,
        encounterID = 2764,
        npcID = 12902,
        journalOrder = 4,
        sourceName = "Lorgus Jett",
        abilities = {
            { title = "Raio", description = "Interrompa o lançamento para reduzir o dano de Natureza e impedir que Lorgus pressione jogadores à distância.", role = "ALL", type = "INTERRUPT" },
            { title = "Escudo de Raios", description = "O escudo pune quem ataca Lorgus; remova o benefício com uma habilidade compatível ou modere os ataques enquanto o curador estabiliza o grupo.", role = "ALL", type = "DISPEL" },
        },
        tips = {
            "Lorgus é opcional no percurso e pode aparecer em mais de um ponto; procure-o somente se o grupo quiser o encontro ou a missão associada.",
            "Limpe os cultistas próximos e puxe Lorgus para fora da patrulha.",
            "Combine interrupções para Raio antes de concentrar dano no chefe.",
        },
        tldr = {
            "Opcional: a posição de Lorgus pode variar.",
            "Limpe os cultistas próximos.",
            "INTERROMPER: Raio.",
            "REMOVER: Escudo de Raios quando compatível.",
        },
    },

    ["Velho Serra'kis"] = {
        dungeonName = "Profundezas Negras",
        instanceID = 48,
        encounterID = 2765,
        npcID = 4830,
        journalOrder = 5,
        sourceName = "Old Serra'kis",
        abilities = {
            { title = "Combate submerso", description = "A luta acontece debaixo d'água; acompanhe a barra de fôlego e volte à superfície antes de ficar sem ar.", role = "ALL", type = "MOVEMENT" },
            { title = "Pressão corpo a corpo", description = "Mantenha Serra'kis no tanque enquanto o grupo causa dano sustentado, sem se espalhar a ponto de perder alcance de cura.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Velho Serra'kis é um desvio opcional na seção inundada.",
            "Recupere vida e mana antes de mergulhar; respiração aquática simplifica o encontro, mas não é obrigatória.",
            "Não comece a luta com a barra de fôlego parcialmente consumida.",
        },
        tldr = {
            "Opcional: recupere recursos antes de mergulhar.",
            "FÔLEGO: suba antes de ficar sem ar.",
            "Mantenha alcance entre tanque e curador.",
        },
    },

    ["Senhor do Crepúsculo Kelris"] = {
        dungeonName = "Profundezas Negras",
        instanceID = 48,
        encounterID = 2766,
        npcID = 4832,
        journalOrder = 6,
        sourceName = "Twilight Lord Kelris",
        abilities = {
            { title = "Impacto Mental", description = "Interrompa o lançamento para reduzir o dano de Sombra sobre um jogador e preservar os recursos do curador.", role = "ALL", type = "INTERRUPT" },
            { title = "Sono", description = "Remova o efeito com uma habilidade compatível; se o curador adormecer, uma função híbrida sustenta o tanque até ele voltar a agir.", role = "ALL", type = "DISPEL" },
            { title = "Curador adormecido", description = "Mantenha o tanque com vida segura antes de cada Sono e esteja pronto para assumir cura de emergência.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Limpe os cultistas de toda a sala antes de interromper a meditação de Kelris.",
            "Combine quem interrompe Impacto Mental e quem responde ao Sono.",
            "Depois da luta, recupere vida e mana e ative somente um braseiro por vez; cada um inicia uma nova onda.",
            "Não acione o próximo braseiro enquanto houver inimigos vivos ou jogadores recuperando recursos.",
        },
        tldr = {
            "Limpe a sala antes de atacar Kelris.",
            "INTERROMPER: Impacto Mental.",
            "REMOVER: Sono quando compatível.",
            "Após a luta, ative um braseiro por vez.",
        },
    },

    ["Aku'mai"] = {
        dungeonName = "Profundezas Negras",
        instanceID = 48,
        encounterID = 2767,
        npcID = 4829,
        journalOrder = 7,
        sourceName = "Aku'mai",
        abilities = {
            { title = "Nuvem de Veneno", description = "Saia imediatamente da nuvem e reposicione Aku'mai para manter o espaço seguro; remova efeitos de veneno apenas com uma habilidade compatível.", role = "ALL", type = "MOVEMENT" },
            { title = "Raiva Frenética", description = "Aku'mai aumenta a pressão corpo a corpo quando está enfurecida; o tanque usa mitigação e o grupo concentra dano para encerrar a luta.", role = "TANK", type = "TANK_CD" },
            { title = "Dano intenso no tanque", description = "Comece com mana suficiente e priorize a vida do tanque, especialmente durante a frenética pressão final.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Antes de entrar, conclua as quatro ondas dos braseiros e recupere completamente o grupo.",
            "Limpe as criaturas na sala e deixe espaço para mover Aku'mai para fora das nuvens.",
            "Jogadores de longo alcance devem preservar linha de visão do curador sem permanecer dentro da nuvem.",
            "Guarde mitigação, cura e dano de emergência para Raiva Frenética.",
        },
        tldr = {
            "Entre com o grupo recuperado e a sala limpa.",
            "SAIR: não permaneça na Nuvem de Veneno.",
            "TANQUE: guarde mitigação para Raiva Frenética.",
            "CURADOR: priorize a vida do tanque.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["Profundezas Negras"] = {
    summary = {
        "CAVERNAS INICIAIS: atravesse as ruínas e os trechos de água com o grupo unido; quedas e mergulhos podem ativar inimigos fora da rota.",
        "LAGO DAS TARTARUGAS: derrote Ghamoo-ra e explore os túneis laterais somente se o grupo for fazer Lady Sarevess, as missões ou outros desvios.",
        "CÂMARA DOS MURLOCS: limpe progressivamente para Gelihast e procure Lorgus Jett apenas se o encontro opcional estiver nos objetivos do grupo.",
        "SEÇÃO INUNDADA: acompanhe o fôlego para Velho Serra'kis; Barão Aquanis é um evento opcional de missão e não conta como chefe.",
        "TEMPLO: limpe os cultistas, derrote Kelris e recupere o grupo antes de iniciar o evento final.",
        "BRASEIROS: ative um por vez, elimine completamente cada onda e só então acione o seguinte para abrir a porta de Aku'mai.",
    },
    enemies = {
        { enemy = "Conjuradores das Profundezas", title = "Lançamentos hostis", description = "Marque conjuradores como prioridade e interrompa lançamentos sempre que possível; traga-os para o tanque usando linha de visão.", role = "ALL", type = "INTERRUPT", priority = 1 },
        { enemy = "Murlocs da câmara", title = "Grupos próximos", description = "Puxe poucos por vez para uma área já limpa e controle inimigos adicionais; não avance até Gelihast antes de esvaziar o entorno.", role = "ALL", type = "PRIORITY_TARGET", priority = 1 },
        { enemy = "Elementais da Água", title = "Dano em área", description = "Concentre um elemental por vez para reduzir rapidamente o dano recebido pelo grupo durante as ondas dos braseiros.", role = "ALL", type = "PRIORITY_TARGET", priority = 1 },
        { enemy = "Inimigos que desarmam", title = "Tanque desarmado", description = "DPS devem reduzir a ameaça até o tanque recuperar a arma e restabelecer o controle da puxada.", role = "DPS", type = "UTILITY", priority = 2 },
        { enemy = "Trechos submersos", title = "Controle de fôlego", description = "Mergulhe com o grupo, acompanhe a barra de fôlego e volte à superfície antes de iniciar outra puxada.", role = "ALL", type = "MOVEMENT", priority = 2 },
        { enemy = "Barão Aquanis", title = "Evento opcional de missão", description = "É invocado na Pedra das Profundezas para uma cadeia da Horda; ignore-o quando o grupo não tiver esse objetivo.", role = "ALL", type = "UTILITY", priority = 3 },
    },
}
