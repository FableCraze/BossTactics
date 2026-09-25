-- Data/Forever/Dungeons/UrzalDosTuscos.lua
-- WoW Forever beta 1.60.1.70009 (2026-09-25).
-- Encounter IDs/order: DungeonEncounter client table, MapID 47.
-- NPC IDs/PT-BR names: Wowhead Forever, cross-checked against localized Classic data.
-- Mechanics/route: Classic references; validation in the Forever beta is pending.

local bosses = {
    ["Rugug"] = {
        dungeonName = "Urzal dos Tuscos",
        instanceID = 47,
        encounterID = 2773,
        npcID = 6168,
        journalOrder = 1,
        sourceName = "Roogug",
        abilities = {
            { title = "Raio", description = "Interrompa o lançamento para reduzir o dano mágico e impedir que o curador gaste recursos antes de o elemental ser controlado.", role = "ALL", type = "INTERRUPT" },
            { title = "Evocar Treme-terra", description = "Rugug chama um elemental; controle-o com uma habilidade compatível ou elimine-o antes de voltar ao chefe.", role = "ALL", type = "PRIORITY_TARGET" },
        },
        tips = {
            "Rugug é opcional e fica em um desvio associado a missões de classe de Guerreiro.",
            "Limpe completamente a área e espere as patrulhas antes de puxar o chefe.",
            "Marque o elemental para controle ou foco e mantenha Rugug em uma área já limpa.",
        },
        tldr = {
            "Opcional: limpe a área antes da puxada.",
            "INTERROMPER: Raio.",
            "CONTROLE ou FOCO: Treme-terra evocado.",
        },
    },

    ["Aggem Pragacardo"] = {
        dungeonName = "Urzal dos Tuscos",
        instanceID = 47,
        encounterID = 2774,
        npcID = 4424,
        journalOrder = 2,
        sourceName = "Aggem Thorncurse",
        abilities = {
            { title = "Evocar Espírito de Javali", description = "Aggem chama um guardião para ajudá-lo; o tanque recolhe o novo alvo e os DPS eliminam o espírito antes de retornar ao chefe.", role = "ALL", type = "PRIORITY_TARGET" },
        },
        tips = {
            "Limpe a plataforma e os acessos para que o espírito evocado não divida a ameaça perto de outro grupo.",
            "Mantenha dano concentrado em um alvo por vez e dê ao tanque tempo para recolher cada evocação.",
            "Não há outra fase especial confirmada para esta versão; preserve ameaça e cura sustentadas.",
        },
        tldr = {
            "Limpe a plataforma.",
            "TANQUE: recolha o espírito evocado.",
            "FOCO: Espírito de Javali antes de Aggem.",
        },
    },

    ["Morta-voz Jargba"] = {
        dungeonName = "Urzal dos Tuscos",
        instanceID = 47,
        encounterID = 2775,
        npcID = 4428,
        journalOrder = 3,
        sourceName = "Death Speaker Jargba",
        abilities = {
            { title = "Auxiliares conjuradores", description = "Jargba começa com dois conjuradores; controle pelo menos um antes da puxada e mantenha os alvos controlados longe do dano em área.", role = "ALL", type = "STOP" },
            { title = "Dominar Mente", description = "Um integrante do grupo pode ser controlado; use controle não letal sobre o aliado e concentre dano em Jargba para encerrar a ameaça.", role = "ALL", type = "STOP" },
            { title = "Seta Sombria", description = "Interrompa o lançamento de Jargba para reduzir o dano mágico enquanto os auxiliares estiverem ativos.", role = "ALL", type = "INTERRUPT" },
        },
        tips = {
            "Limpe o entorno e marque Jargba, os dois auxiliares e a ordem de controle antes da puxada.",
            "Controle os conjuradores e priorize Jargba para remover Dominar Mente do encontro o quanto antes.",
            "Se um aliado for dominado, não use dano letal ou efeitos difíceis de cancelar sobre ele.",
            "Reative os controles dos auxiliares quando necessário e elimine-os depois do chefe.",
        },
        tldr = {
            "CONTROLE: um ou dois conjuradores antes da puxada.",
            "FOCO: Jargba para encerrar Dominar Mente.",
            "INTERROMPER: Seta Sombria.",
            "ALIADO DOMINADO: controle sem matar.",
        },
    },

    ["Lorde Supremo Marretusco"] = {
        dungeonName = "Urzal dos Tuscos",
        instanceID = 47,
        encounterID = 2776,
        npcID = 4420,
        journalOrder = 4,
        sourceName = "Overlord Ramtusk",
        abilities = {
            { title = "Couriços do Urzal", description = "Dois guardas acompanham Marretusco; controle-os quando possível ou faça o tanque estabelecer ameaça antes de o grupo escolher o primeiro alvo.", role = "ALL", type = "STOP" },
            { title = "Barragem Giratória", description = "Os guardas atacam ao redor de si; jogadores que não estiverem controlando ou tankando os Couriços devem manter distância.", role = "ALL", type = "MOVEMENT" },
            { title = "Trovoada", description = "Marretusco causa pressão física ao redor do tanque; funções de longo alcance ficam afastadas e o tanque prepara mitigação para a combinação de ataques.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Limpe a plataforma e combine controle para os dois Couriços antes de enfrentar Marretusco.",
            "Se os dois guardas forem controlados, concentre dano no chefe e evite quebrar os controles com efeitos em área.",
            "Sem controle suficiente, elimine um guarda por vez e preserve recursos defensivos para o tanque.",
        },
        tldr = {
            "CONTROLE: Couriços do Urzal.",
            "NÃO QUEBRE: mantenha os guardas controlados.",
            "LONGO ALCANCE: fique fora da Trovoada.",
            "TANQUE: prepare mitigação para a pressão física.",
        },
    },

    ["Agathelos, o Furioso"] = {
        dungeonName = "Urzal dos Tuscos",
        instanceID = 47,
        encounterID = 2777,
        npcID = 4422,
        journalOrder = 5,
        sourceName = "Agathelos the Raging",
        abilities = {
            { title = "Investida", description = "Agathelos pode avançar sobre um jogador afastado; mantenha a área livre, recupere o posicionamento e deixe o tanque retomar ameaça imediatamente.", role = "ALL", type = "MOVEMENT" },
            { title = "Enfurecer", description = "O dano físico aumenta; remova o efeito com uma habilidade compatível ou use mitigação e cura reforçada até a pressão diminuir.", role = "ALL", type = "DISPEL" },
            { title = "Dano concentrado", description = "Priorize a sobrevivência do tanque e mantenha recursos disponíveis para a combinação de Investida e Enfurecer.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Limpe o cercado e os acessos antes de soltar ou atacar Agathelos.",
            "Comece com o tanque estável e recursos de cura disponíveis; o encontro exige mais sobrevivência do que troca de alvos.",
            "Jogadores atingidos pela Investida devem voltar à posição sem atravessar grupos ainda vivos.",
        },
        tldr = {
            "Limpe o cercado e os acessos.",
            "INVESTIDA: recupere a posição com segurança.",
            "REMOVER: Enfurecer quando compatível.",
            "CURADOR: priorize a sobrevivência do tanque.",
        },
    },

    ["Charlga Talhaflanco"] = {
        dungeonName = "Urzal dos Tuscos",
        instanceID = 47,
        encounterID = 2778,
        npcID = 4421,
        journalOrder = 6,
        sourceName = "Charlga Razorflank",
        abilities = {
            { title = "Raio Encadeado", description = "A descarga pode alcançar jogadores próximos; espalhe o grupo na plataforma limpa sem se aproximar das bordas.", role = "ALL", type = "MOVEMENT" },
            { title = "Pureza", description = "Charlga fica temporariamente imune; pare de gastar ataques e recursos ofensivos até a proteção terminar.", role = "ALL", type = "STOP" },
            { title = "Renovar", description = "Interrompa a cura quando possível ou remova o efeito com uma dissipação ofensiva compatível para impedir que a luta se prolongue.", role = "ALL", type = "INTERRUPT" },
        },
        tips = {
            "Limpe a cabana, a plataforma inferior e o caminho de recuo antes de iniciar o encontro.",
            "Puxe Charlga para fora da cabana e lute na plataforma, onde o grupo pode se espalhar e enxergar os lançamentos.",
            "Combine interrupções para Renovar e não desperdice recursos ofensivos durante Pureza.",
            "Depois da vitória, o grupo pode descer para a área inferior e iniciar a escolta opcional de Importador Willix somente quando todos estiverem prontos.",
        },
        tldr = {
            "Puxe Charlga para a plataforma limpa.",
            "ESPALHAR: Raio Encadeado.",
            "PARAR DANO: Pureza.",
            "INTERROMPER ou REMOVER: Renovar.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["Urzal dos Tuscos"] = {
    summary = {
        "ENTRADA: permaneça no nível superior e não salte das passarelas antes de derrotar Charlga; quedas podem separar o grupo.",
        "DESVIO INICIAL: visite Rugug somente se o grupo quiser o encontro opcional e as missões associadas; depois retorne à rota principal.",
        "ROTA PRINCIPAL: avance por Aggem, Jargba e Marretusco usando linha de visão e controle nos grupos com conjuradores.",
        "PLATAFORMAS: depois de Marretusco, verifique a aparição opcional de Arauto da Terra Halmgar sem separar o grupo.",
        "CAVERNA DOS MORCEGOS: atravesse em puxadas pequenas, procure o raro Caçador Cego e siga pelo cercado de Agathelos.",
        "CABANA FINAL: limpe a plataforma antes de enfrentar Charlga Talhaflanco.",
        "ESCOLTA OPCIONAL: após Charlga, reúna o grupo na área inferior, recupere vida e mana e fale com Importador Willix; tanque recolhe inimigos, DPS protegem Willix e o curador, e todos acompanham o NPC até a saída.",
    },
    enemies = {
        { enemy = "Totemista do Urzal", title = "Totem Agarraterra", description = "Destrua imediatamente o totem para liberar jogadores imobilizados antes que a posição forçada atraia outro grupo.", role = "ALL", type = "PRIORITY_TARGET", priority = 1 },
        { enemy = "Poeirento do Urzal", title = "Ventos Envolventes", description = "Interrompa o lançamento sempre que possível e evite enfrentar vários Poeirentos ao mesmo tempo, especialmente sem uma cura de apoio.", role = "ALL", type = "INTERRUPT", priority = 1 },
        { enemy = "Adepto da Cabeça da Morte", title = "Correntes de Gelo", description = "Interrompa o controle e mantenha o grupo longe de patrulhas para que um jogador imobilizado não provoque uma puxada adicional.", role = "ALL", type = "INTERRUPT", priority = 1 },
        { enemy = "Grupos de javatuscos", title = "Conjuradores e fugitivos", description = "Use linha de visão para aproximar inimigos à distância e pare os alvos que tentarem fugir para as passarelas ou grupos vizinhos.", role = "ALL", type = "STOP", priority = 2 },
        { enemy = "Caçador Cego", title = "Raro: Estouro Sônico", description = "Se o raro estiver presente, limpe a caverna, mantenha o curador afastado e preserve recursos enquanto o silêncio em área impedir lançamentos.", role = "ALL", type = "STOP", priority = 3 },
        { enemy = "Arauto da Terra Halmgar", title = "Raro: totens e elemental", description = "Limpe a plataforma, priorize os totens e controle ou elimine o elemental antes de concentrar dano em Halmgar.", role = "ALL", type = "PRIORITY_TARGET", priority = 3 },
        { enemy = "Couriço do Urzal", title = "Raro: Barragem Giratória", description = "Somente o tanque permanece próximo durante a barragem; os demais jogadores se afastam e retomam o dano depois do ataque.", role = "ALL", type = "MOVEMENT", priority = 3 },
    },
}
