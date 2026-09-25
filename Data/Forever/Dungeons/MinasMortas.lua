-- Data/Forever/Dungeons/MinasMortas.lua
-- WoW Forever beta 1.60.1.70009 (2026-09-25).
-- Encounter IDs/order: DungeonEncounter client table, MapID 36.
-- NPC IDs/PT-BR names: Wowhead Forever, cross-checked against the localized roster.
-- Mechanics/route: Classic references; validation in the Forever beta is pending.

local bosses = {
    ["Rhahk'Zor"] = {
        dungeonName = "Minas Mortas",
        instanceID = 36,
        encounterID = 2741,
        npcID = 644,
        journalOrder = 1,
        sourceName = "Rhahk'Zor",
        abilities = {
            { title = "Vigias Défias", description = "Puxe e elimine os dois vigias antes do chefe; use controle de grupo se eles entrarem no combate junto com Rhahk'Zor.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Batida de Rhahk'Zor", description = "O alvo atual é atingido e atordoado; o tanque deve manter a ameaça antes do golpe e o curador deve preparar cura para o período sem reação.", role = "TANK", type = "TANK_CD" },
            { title = "Cura durante o atordoamento", description = "Mantenha o tanque com vida segura antes da Batida e recupere-o enquanto ele não puder agir.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Limpe os Vigias Défias e espere qualquer patrulha se afastar antes de puxar o chefe.",
            "Dê tempo para o tanque consolidar a ameaça; Batida de Rhahk'Zor impede sua reação por um curto período.",
            "Depois da luta, olhe para o caminho já percorrido antes de saquear ou recuperar mana: patrulhas podem chegar por trás.",
        },
        tldr = {
            "Elimine os dois vigias antes do chefe.",
            "TANQUE: consolide ameaça antes de Batida de Rhahk'Zor.",
            "CURADOR: prepare cura para o tanque atordoado.",
            "Confira patrulhas atrás do grupo após a luta.",
        },
    },

    ["Sneed"] = {
        dungeonName = "Minas Mortas",
        instanceID = 36,
        encounterID = 2742,
        npcID = 643,
        journalOrder = 2,
        sourceName = "Sneed",
        abilities = {
            { title = "Retalhador do Sneed", description = "Destrua primeiro a máquina; Sneed salta para fora quando ela é derrotada e o combate continua sem uma pausa garantida.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Aterrorizar", description = "O Retalhador pode fazer jogadores fugirem sem controle; limpe toda a sala para que o medo não leve o grupo a outros inimigos.", role = "ALL", type = "UTILITY" },
            { title = "Desarmar", description = "Sneed pode desarmar o tanque depois de sair da máquina; DPS devem aguardar a ameaça se estabilizar antes de acelerar.", role = "DPS", type = "STOP" },
            { title = "Transição para Sneed", description = "Recupere o controle do chefe assim que ele sair do Retalhador e mantenha recursos para a continuação imediata da luta.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Limpe todos os Entalhadores Goblins da sala antes de iniciar; Aterrorizar pode levar jogadores até eles.",
            "Preserve vida e mana durante o Retalhador, pois Sneed entra em combate logo depois.",
            "Após a transição, deixe o tanque reconstruir ameaça, especialmente se estiver desarmado.",
        },
        tldr = {
            "Limpe toda a sala antes de puxar.",
            "Destrua o Retalhador; Sneed sai em seguida.",
            "TANQUE: recupere Sneed imediatamente na transição.",
            "DPS: espere a ameaça durante Desarmar.",
        },
    },

    ["Minerador João"] = {
        dungeonName = "Minas Mortas",
        instanceID = 36,
        encounterID = 3676,
        npcID = 3586,
        journalOrder = 3,
        sourceName = "Miner Johnson",
        abilities = {
            { title = "Raro opcional", description = "Minerador João aparece em uma passagem lateral e pode não estar presente; desvie da rota somente se o grupo quiser enfrentá-lo.", role = "ALL", type = "UTILITY" },
            { title = "Mineradores Défias", description = "Elimine os mineradores próximos antes de atacar João para não aumentar a pressão inicial sobre o tanque.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Perfurar Armadura", description = "O efeito reduz a proteção do tanque; use mitigação e mantenha ameaça estável enquanto ele estiver vulnerável.", role = "TANK", type = "TANK_CD" },
            { title = "Tanque vulnerável", description = "Priorize a vida do tanque durante Perfurar Armadura e evite dividir cura com inimigos deixados vivos.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Procure o raro na passagem lateral depois de Rhahk'Zor; ele pode não aparecer em todas as visitas.",
            "Puxe os Mineradores Défias separadamente sempre que possível.",
            "Não há fase especial confirmada: depois dos auxiliares, concentre sobrevivência do tanque e dano constante.",
        },
        tldr = {
            "Raro opcional: pode não estar presente.",
            "Elimine os mineradores próximos primeiro.",
            "TANQUE: use mitigação durante Perfurar Armadura.",
            "CURADOR: priorize o tanque enquanto a armadura estiver reduzida.",
        },
    },

    ["Gilnid"] = {
        dungeonName = "Minas Mortas",
        instanceID = 36,
        encounterID = 2743,
        npcID = 1763,
        journalOrder = 4,
        sourceName = "Gilnid",
        abilities = {
            { title = "Engenheiro Goblínico", description = "Controle ou elimine o engenheiro que acompanha Gilnid antes que ele invoque outro inimigo mecânico.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Evocar Golem de Controle Remoto", description = "Interrompa a invocação do engenheiro; se ela terminar, mude a prioridade para o novo inimigo e estabilize o grupo.", role = "ALL", type = "INTERRUPT" },
            { title = "Metal Derretido", description = "Interrompa o lançamento de Gilnid para evitar dano periódico e a redução de movimento e de velocidade de ataque no alvo.", role = "ALL", type = "INTERRUPT" },
        },
        tips = {
            "Limpe a fundição ao redor e não inicie Gilnid com outros goblins ativos.",
            "Combine quem interrompe Metal Derretido e quem cobre a invocação do engenheiro.",
            "Se o golem for invocado, reduza imediatamente o número de inimigos ativos em vez de dividir dano sem prioridade.",
        },
        tldr = {
            "Limpe a fundição antes de puxar.",
            "Controle ou elimine o Engenheiro Goblínico.",
            "INTERROMPER: Evocar Golem e Metal Derretido.",
            "Priorize o golem se a invocação terminar.",
        },
    },

    ["Capitão Peleverde"] = {
        dungeonName = "Minas Mortas",
        instanceID = 36,
        encounterID = 2744,
        npcID = 647,
        journalOrder = 5,
        sourceName = "Captain Greenskin",
        abilities = {
            { title = "Guardas da tripulação", description = "Puxe o grupo para uma área controlada e elimine os guardas antes de concentrar dano no Capitão Peleverde.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Cutilada", description = "Mantenha Peleverde virado para longe do grupo; somente o tanque deve permanecer diante dele.", role = "TANK", type = "MOVEMENT" },
            { title = "Arpão Envenenado", description = "Interrompa o lançamento quando possível; se o veneno atingir alguém, remova-o somente com uma habilidade compatível.", role = "ALL", type = "DISPEL" },
        },
        tips = {
            "Limpe o convés por etapas e evite iniciar o chefe junto com outros grupos da embarcação.",
            "O tanque deve posicionar o chefe de costas para o grupo para limitar Cutilada.",
            "Combine interrupção e remoção de veneno para que Arpão Envenenado não pressione o curador.",
        },
        tldr = {
            "Elimine os guardas antes do capitão.",
            "TANQUE: vire Peleverde para longe do grupo.",
            "INTERROMPER: Arpão Envenenado quando possível.",
            "REMOVER: o veneno com uma habilidade compatível.",
        },
    },

    ["Sr. Castiga"] = {
        dungeonName = "Minas Mortas",
        instanceID = 36,
        encounterID = 2745,
        npcID = 646,
        journalOrder = 6,
        sourceName = "Mr. Smite",
        abilities = {
            { title = "Guardas Negros", description = "Elimine os dois guardas antes de pressionar Castiga; deixá-los vivos torna perigosos os períodos em que o grupo fica atordoado.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Pisada do Castiga", description = "A Pisada atordoa o grupo enquanto Castiga busca outra arma; reagrupe-se e deixe o tanque recuperar a ameaça quando ele voltar.", role = "ALL", type = "UTILITY" },
            { title = "Troca de armas", description = "Cada troca altera a pressão corpo a corpo; mantenha mitigação disponível e reposicione Castiga de costas para o grupo.", role = "TANK", type = "TANK_CD" },
            { title = "Recuperação após a Pisada", description = "Use o intervalo da troca para recuperar a vida do grupo e prepare cura no tanque antes que Castiga retome os ataques.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Puxe Castiga e seus guardas para longe de outros inimigos do cais.",
            "Mate os Guardas Negros antes de forçar a primeira troca de armas.",
            "Não persiga o chefe de forma desordenada durante Pisada do Castiga; reagrupe e retome somente após o tanque recuperar controle.",
        },
        tldr = {
            "Elimine os Guardas Negros primeiro.",
            "Pisada atordoa o grupo durante a troca de armas.",
            "TANQUE: recupere ameaça quando Castiga voltar.",
            "CURADOR: estabilize o grupo antes da retomada dos ataques.",
        },
    },

    ["Cuca"] = {
        dungeonName = "Minas Mortas",
        instanceID = 36,
        encounterID = 2746,
        npcID = 645,
        journalOrder = 7,
        sourceName = "Cookie",
        abilities = {
            { title = "Culinária do Cuca", description = "Interrompa a preparação para impedir que Cuca recupere vida e prolongue o combate.", role = "ALL", type = "INTERRUPT" },
            { title = "Borrifo de Ácido", description = "O ataque pressiona um alvo à distância; o curador deve recuperar a vítima antes de outro lançamento.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Cuca é um chefe bônus na cozinha da embarcação; limpe os inimigos próximos antes de atacá-lo.",
            "Mantenha uma interrupção reservada para Culinária do Cuca.",
            "Puxe Cuca para uma área já limpa, longe dos inimigos do convés inferior.",
        },
        tldr = {
            "Chefe bônus: limpe a cozinha primeiro.",
            "INTERROMPER: Culinária do Cuca.",
            "CURADOR: recupere o alvo de Borrifo de Ácido.",
        },
    },

    ["Edwin VanCleef"] = {
        dungeonName = "Minas Mortas",
        instanceID = 36,
        encounterID = 2747,
        npcID = 639,
        journalOrder = 8,
        sourceName = "Edwin VanCleef",
        abilities = {
            { title = "Guardiões das Sombras Défias", description = "Revele e elimine os guardas que iniciam o encontro com VanCleef; use controle de grupo para reduzir a pressão inicial.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Aliados de VanCleef", description = "Novos aliados entram durante o combate; tanque deve recolhê-los e DPS devem eliminá-los antes de voltar ao chefe.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Surra", description = "VanCleef pode encadear ataques contra o alvo atual; mantenha mitigação e ameaça estáveis durante a sequência.", role = "TANK", type = "TANK_CD" },
            { title = "Pressão dos reforços", description = "Proteja o curador quando os aliados surgirem e recupere o grupo antes de voltar a concentrar dano no chefe.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Limpe o convés e a cabine ao redor antes de iniciar o encontro final.",
            "Marque uma ordem para os guarda-costas e preserve controle de grupo para os reforços posteriores.",
            "Não ignore aliados para terminar VanCleef: o tanque os recolhe e os DPS reduzem primeiro o número de ameaças.",
            "Mantenha o curador afastado do ponto onde os auxiliares são reunidos.",
        },
        tldr = {
            "Controle e elimine os guarda-costas primeiro.",
            "TANQUE: recolha cada grupo de reforços.",
            "DPS: priorize os aliados antes de voltar ao chefe.",
            "CURADOR: fique afastado dos auxiliares e estabilize o grupo.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["Minas Mortas"] = {
    summary = {
        "TÚNEIS: avance até Rhahk'Zor e confira o caminho atrás do grupo antes de recuperar mana após a luta.",
        "DESVIO OPCIONAL: procure Minerador João na passagem lateral depois de Rhahk'Zor; continue sem desviar se o raro não estiver presente.",
        "SERRARIA: limpe toda a sala do Retalhador do Sneed para que Aterrorizar não leve jogadores a outro grupo.",
        "FUNDIÇÃO: controle engenheiros, derrote Gilnid e use a pólvora no canhão somente com o grupo reunido para a patrulha seguinte.",
        "CAIS: elimine Sr. Castiga e seus guardas antes de subir na embarcação.",
        "NAVIO: limpe a cozinha para Cuca, avance pelos conveses até Capitão Peleverde e termine na cabine de Edwin VanCleef.",
    },
    enemies = {
        { enemy = "Artífice de Borrasca Défias", title = "Nova Congelante", description = "Interrompa o lançamento quando possível e puxe o grupo para perto do tanque para que a imobilização não separe jogadores da linha de frente.", role = "ALL", type = "INTERRUPT", priority = 1 },
        { enemy = "Engenheiro Goblínico", title = "Evocar Golem de Controle Remoto", description = "Interrompa a invocação ou controle o engenheiro; se o golem aparecer, trate-o como alvo prioritário.", role = "ALL", type = "INTERRUPT", priority = 1 },
        { enemy = "Inimigo em fuga", title = "Fuga para outro grupo", description = "Reduza a velocidade ou finalize inimigos com pouca vida antes que alcancem outra patrulha.", role = "DPS", type = "STOP", priority = 1 },
        { enemy = "Patrulha Défias", title = "Ataque pela retaguarda", description = "Observe o caminho já percorrido, especialmente após chefes, antes de saquear ou recuperar vida e mana.", role = "ALL", type = "UTILITY", priority = 2 },
        { enemy = "Evento do canhão", title = "Patrulha após a explosão", description = "Reúna o grupo e recupere recursos antes de disparar; o tanque deve estar pronto para recolher os inimigos que chegam depois da abertura da porta.", role = "ALL", type = "UTILITY", priority = 2 },
    },
}
