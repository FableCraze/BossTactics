# Profundezas Negras

A tabela `DungeonEncounter` do cliente no build `1.60.1.70009` contém vários conjuntos legados para o `MapID` 48. O pacote usa exclusivamente as sete linhas da dificuldade Normal para cinco jogadores (`DifficultyID` 201), que são as mesmas listadas pelo catálogo atual do Forever.

| Ordem | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---|---:|---:|---|
| 1 | Ghamoo-ra | 2761 | 4887 | Ghamoo-ra |
| 2 | Lady Sarevess | 2762 | 4831 | Lady Sarevess |
| 3 | Geilhast | 2763 | 6243 | Gelihast |
| 4 | Lorgus Jett | 2764 | 12902 | Lorgus Jett |
| 5 | Old Serra'kis | 2765 | 4830 | Velho Serra'kis |
| 6 | Twilight Lord Kelris | 2766 | 4832 | Senhor do Crepúsculo Kelris |
| 7 | Aku'mai | 2767 | 4829 | Aku'mai |

## Grau de confirmação

- **Build e instância:** confirmados no cliente local `wow_classic_beta` versão `1.60.1.70009`.
- **Encontros e ordem:** confirmados nas linhas `2761`–`2767` da tabela `DungeonEncounter`, `MapID` 48 e `DifficultyID` 201.
- **NPCs e nomes PT-BR:** cruzados com o catálogo localizado do Wowhead Forever. A tabela do cliente escreve `Geilhast`, enquanto o NPC localizado permanece `Gelihast`; o addon conserva as duas formas nos campos apropriados.
- **Mecânicas, percurso e inimigos comuns:** referência Classic comparada ao guia Forever; validação no Forever pendente. O cliente não inclui uma tabela de diário com essas habilidades.
- **Opcionais:** Gelihast, Lorgus Jett e Velho Serra'kis podem ser desviados no percurso, mas integram os sete encontros do cliente. Barão Aquanis e o evento dos quatro braseiros ficam apenas no guia de percurso e inimigos.

## Percurso e evento final

O caminho passa pelas cavernas iniciais, pelo lago de Ghamoo-ra, pelos túneis de Sarevess, pela câmara dos murlocs e pela seção inundada antes do templo. Depois de Kelris, o grupo deve recuperar vida e mana e acionar os quatro braseiros individualmente. Cada ativação inicia uma onda; a porta de Aku'mai só deve ser aberta depois que todas forem concluídas.

Não há mapa ou automação de navegação. A posição variável de Lorgus Jett e os desvios opcionais são descritos em texto, sem prometer uma rota fixa.

## Fontes consultadas em 25/09/2026

- [DungeonEncounter — build 1.60.1.70009](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70009)
- [Catálogo extraído do cliente Forever](https://wowforevertalents.com/dungeons/blackfathom-deeps/)
- [Catálogo localizado de Profundezas Negras](https://www.wowhead.com/forever/pt/zone=719/profundezas-negras)
- [Guia e percurso comparativo do Forever](https://wowf.io/en/dungeons/blackfathom-deeps/guide)
- [Guia Classic da Icy Veins](https://www.icy-veins.com/wow-classic/blackfathom-deeps-dungeon-guide)
- [Estratégia Classic do Wowhead](https://www.wowhead.com/classic/guide/blackfathom-deeps-dungeon-strategy-wow-classic)
- [Ghamoo-ra](https://www.wowhead.com/forever/pt/npc=4887/ghamoo-ra)
- [Lady Sarevess](https://www.wowhead.com/forever/pt/npc=4831/lady-sarevess)
- [Gelihast](https://www.wowhead.com/forever/pt/npc=6243/gelihast)
- [Lorgus Jett](https://www.wowhead.com/forever/pt/npc=12902/lorgus-jett)
- [Velho Serra'kis](https://www.wowhead.com/forever/pt/npc=4830/velho-serrakis)
- [Senhor do Crepúsculo Kelris](https://www.wowhead.com/forever/pt/npc=4832/senhor-do-crepusculo-kelris)
- [Aku'mai](https://www.wowhead.com/forever/pt/npc=4829/akumai)

## Pendências no jogo

- Confirmar os nomes e IDs emitidos por `ENCOUNTER_START`/`ENCOUNTER_END` nos sete encontros da dificuldade Normal.
- Revisar no beta Atropelo, habilidades de Sarevess, Rede, Raio e Escudo de Raios, Sono, Impacto Mental, Nuvem de Veneno e Raiva Frenética.
- Confirmar a grafia apresentada pelo evento de Gelihast, as posições possíveis de Lorgus Jett e os desvios opcionais.
- Validar o comportamento dos quatro braseiros, suas ondas e a abertura da porta final sem promover o evento a chefe.
- Confirmar Barão Aquanis como evento opcional de missão e mantê-lo fora do contador.
- Testar diário, minipainel, filtros por função, compartilhamento, painel de inimigos e avanço automático.
