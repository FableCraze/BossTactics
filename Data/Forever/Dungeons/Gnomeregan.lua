-- Data/Forever/Dungeons/Gnomeregan.lua
-- WoW Forever beta 1.60.1.70009 (2026-09-25).
-- Encounter IDs/order: DungeonEncounter client table, MapID 90, DifficultyID 201.
-- NPC IDs/PT-BR names: Wowhead Forever, cross-checked against localized Classic data.
-- Mechanics/route: Classic references; validation in the Forever beta is pending.

local bosses = {
    ["Grúdio"] = {
        dungeonName = "Gnomeregan",
        instanceID = 90,
        encounterID = 2768,
        npcID = 7361,
        journalOrder = 1,
        sourceName = "Grubbis",
        abilities = {
            { title = "Mordelis", description = "O basilisco acompanha Grúdio no fim do evento; o tanque mantém os dois inimigos sob controle e o grupo elimina Mordelis sem espalhar ameaça.", role = "ALL", type = "PRIORITY_TARGET" },
            { title = "Pressão sobre o tanque", description = "Estabilize o tanque enquanto Grúdio e Mordelis estiverem ativos ao mesmo tempo; não deixe o dano do evento consumir todos os recursos antes do chefe aparecer.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Grúdio é opcional e aparece no fim do evento iniciado com Mestre de Explosão Emi Pavio Curto.",
            "Reúna o grupo e recupere vida e mana antes de iniciar; proteja Emi durante as ondas de troggs.",
            "O tanque recolhe cada onda e os DPS impedem que inimigos alcancem Emi ou o curador.",
            "Quando Grúdio e Mordelis surgirem, mantenha o combate na área já limpa e concentre o grupo em um alvo por vez.",
        },
        tldr = {
            "Opcional: fale com Emi somente com o grupo pronto.",
            "Proteja Emi durante todas as ondas.",
            "TANQUE: controle Grúdio e Mordelis.",
            "FOCO: elimine Mordelis sem espalhar ameaça.",
        },
    },

    ["Precipitação Radioativa Viscosa"] = {
        dungeonName = "Gnomeregan",
        instanceID = 90,
        encounterID = 2769,
        npcID = 7079,
        journalOrder = 2,
        sourceName = "Viscous Fallout",
        abilities = {
            { title = "Combate direto", description = "Não há fase especial confirmada para a versão Normal; mantenha ameaça estável, cura sustentada e dano concentrado no chefe.", role = "ALL", type = "UTILITY" },
            { title = "Pressão sustentada", description = "Acompanhe a vida do tanque e do grupo sem gastar toda a mana de uma vez; inimigos próximos tornam a luta muito mais perigosa.", role = "HEALER", type = "HEALER_CD" },
        },
        tips = {
            "Limpe os elementais e troggs próximos e espere a patrulha antes de atacar.",
            "Puxe o chefe para uma posição segura, distante dos demais grupos da área inferior.",
            "Evite acrescentar habilidades da versão de raide da Temporada da Descoberta a este encontro de cinco jogadores.",
        },
        tldr = {
            "Limpe o entorno e espere a patrulha.",
            "Puxe para uma área segura.",
            "Mantenha ameaça e cura sustentadas.",
        },
    },

    ["Eletrocutor 6000"] = {
        dungeonName = "Gnomeregan",
        instanceID = 90,
        encounterID = 2770,
        npcID = 6235,
        journalOrder = 3,
        sourceName = "Electrocutioner 6000",
        abilities = {
            { title = "Raio Encadeado", description = "A descarga pode alcançar jogadores próximos uns dos outros; espalhe o grupo sem recuar para inimigos ainda vivos.", role = "ALL", type = "MOVEMENT" },
            { title = "Megavolt", description = "Prepare cura para a pressão elétrica sobre o grupo e estabilize os jogadores antes de voltar a economizar mana.", role = "HEALER", type = "HEALER_CD" },
            { title = "Choque", description = "O tanque mantém o chefe voltado para uma área segura e usa mitigação quando a sequência de dano elétrico ameaçar sua vida.", role = "TANK", type = "TANK_CD" },
        },
        tips = {
            "Limpe a plataforma e os acessos antes de iniciar o combate.",
            "Distribua os jogadores ao redor da área sem ocupar rampas ou bordas perigosas.",
            "A Chave da Oficina obtida neste encontro permite usar a entrada lateral em visitas futuras; ela não altera a ordem editorial do diário.",
        },
        tldr = {
            "Limpe a plataforma e os acessos.",
            "ESPALHAR: reduza o encadeamento elétrico.",
            "CURADOR: prepare-se para Megavolt.",
            "TANQUE: mitigue a sequência de dano.",
        },
    },

    ["Espanca-gente 9-60"] = {
        dungeonName = "Gnomeregan",
        instanceID = 90,
        encounterID = 2771,
        npcID = 6229,
        journalOrder = 4,
        sourceName = "Crowd Pummeler 9-60",
        abilities = {
            { title = "Espanca-gente", description = "O golpe pode arremessar jogadores; lute com as costas para uma parede e nunca deixe uma borda atrás do grupo.", role = "ALL", type = "MOVEMENT" },
            { title = "Golpe em Arco", description = "O tanque mantém o chefe voltado para longe do grupo; DPS e curador evitam permanecer à frente.", role = "ALL", type = "MOVEMENT" },
            { title = "Pisotear", description = "Jogadores de longo alcance ficam afastados do espaço corpo a corpo para evitar dano desnecessário ao redor do chefe.", role = "ALL", type = "MOVEMENT" },
        },
        tips = {
            "Limpe a passarela superior dos Laboratórios de Engenharia antes da puxada.",
            "Escolha uma parede segura para o tanque e confirme que nenhum jogador ficará de costas para a queda.",
            "Depois de um empurrão, recupere o posicionamento antes de retomar o dano total.",
        },
        tldr = {
            "Limpe a passarela antes da luta.",
            "COSTAS NA PAREDE: evite ser arremessado.",
            "NÃO FIQUE À FRENTE: Golpe em Arco.",
            "LONGO ALCANCE: fique fora de Pisotear.",
        },
    },

    ["Mecangenheiro Termaplugue"] = {
        dungeonName = "Gnomeregan",
        instanceID = 90,
        encounterID = 2772,
        npcID = 7800,
        journalOrder = 5,
        sourceName = "Mekgineer Thermaplugg",
        abilities = {
            { title = "Bombinhas Andantes", description = "Os dispensadores liberam bombas que perseguem o grupo e explodem ao se aproximar; DPS de longo alcance devem destruí-las antes que alcancem jogadores reunidos.", role = "DPS", type = "PRIORITY_TARGET" },
            { title = "Dispensadores ativos", description = "Quando um dispensador abrir, um jogador previamente combinado aciona o botão correspondente para interromper novas bombas sem abandonar uma ameaça imediata.", role = "ALL", type = "UTILITY" },
            { title = "Repelir", description = "O golpe afasta o alvo e pode alterar a ameaça; o tanque luta com espaço seguro às costas e recupera o chefe imediatamente após o empurrão.", role = "TANK", type = "TANK_CD" },
            { title = "Explosões", description = "Espalhe o grupo o suficiente para que uma bomba não atinja vários jogadores e priorize a recuperação antes de voltar ao chefe.", role = "ALL", type = "MOVEMENT" },
        },
        tips = {
            "Limpe o Tribunal dos Engenhoqueiros e recupere vida e mana antes da puxada.",
            "Divida previamente os seis dispensadores entre jogadores móveis e determine quem fará a cobertura.",
            "Botões interrompem novas bombas do dispensador correspondente; bombas que já saíram continuam sendo alvos prioritários.",
            "Não use as fases, trajes ou tipos adicionais de bomba da versão de raide da Temporada da Descoberta.",
        },
        tldr = {
            "Combine responsáveis pelos dispensadores.",
            "BOTÃO: feche o dispensador ativo.",
            "FOCO: destrua Bombinhas Andantes soltas.",
            "ESPALHAR: limite as explosões.",
            "TANQUE: recupere ameaça após Repelir.",
        },
    },
}

for bossName, bossData in pairs(bosses) do
    BT_BossData[bossName] = bossData
end

BT_TrashData["Gnomeregan"] = {
    summary = {
        "SALÃO DAS ENGRENAGENS: siga primeiro pela esquerda para o evento opcional de Emi e Grúdio; depois retorne e desça para Precipitação Radioativa Viscosa.",
        "ZONA LIMPA: use o setor seguro para reagrupar, recuperar recursos e organizar missões antes de continuar.",
        "BAÍA DE LANÇAMENTO: avance até Eletrocutor 6000 sem lutar perto das bordas e sem deixar Sistemas de Alerta Móvel chamarem reforços.",
        "LABORATÓRIOS DE ENGENHARIA: use a passagem lateral para Espanca-gente 9-60 e depois retorne à rota principal.",
        "TÚNEL FINAL: elimine Agentes Ferro Negro e suas minas; o Embaixador Ferro Negro pode aparecer como raro opcional.",
        "TRIBUNAL DOS ENGENHOQUEIROS: limpe a sala, recupere recursos e combine os dispensadores antes de Mecangenheiro Termaplugue.",
    },
    enemies = {
        { enemy = "Sistema de Alerta Móvel", title = "Alerta de intruso", description = "Troque imediatamente para o sistema e destrua-o antes que o alerta convoque sentinelas adicionais.", role = "ALL", type = "PRIORITY_TARGET", priority = 1 },
        { enemy = "Agente Ferro Negro", title = "Mina Terrestre Ferro Negro", description = "Priorize o agente e destrua a mina antes que seja armada; depois de armada, afaste o grupo em vez de atravessá-la.", role = "ALL", type = "PRIORITY_TARGET", priority = 1 },
        { enemy = "Nulificador Arcano X-21", title = "Barreira refletora", description = "Pare feitiços ofensivos enquanto a barreira refletora estiver ativa e retome o dano mágico somente quando for seguro.", role = "ALL", type = "STOP", priority = 1 },
        { enemy = "Grupos irradiados e mecânicos", title = "Puxadas próximas", description = "Puxe poucos inimigos por vez para uma área já limpa, controle alvos adicionais e espere patrulhas antes de avançar.", role = "ALL", type = "PRIORITY_TARGET", priority = 2 },
        { enemy = "Embaixador Ferro Negro", title = "Raro: fogo e auxiliar", description = "Se o raro estiver presente, limpe o túnel, interrompa Bola de Fogo e elimine o Servo Flamejante antes de concentrar dano no embaixador.", role = "ALL", type = "INTERRUPT", priority = 3 },
    },
}
