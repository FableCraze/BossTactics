# Gnomeregan

O pacote representa exclusivamente a versão Normal de cinco jogadores. A tabela `DungeonEncounter` do build `1.60.1.70009` também contém linhas legadas e da versão de raide da Temporada da Descoberta para o mesmo mapa; somente as cinco linhas com `DifficultyID` 201 foram usadas.

| Ordem | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---|---:|---:|---|
| 1 | Grubbis | 2768 | 7361 | Grúdio |
| 2 | Viscous Fallout | 2769 | 7079 | Precipitação Radioativa Viscosa |
| 3 | Electrocutioner 6000 | 2770 | 6235 | Eletrocutor 6000 |
| 4 | Crowd Pummeler 9-60 | 2771 | 6229 | Espanca-gente 9-60 |
| 5 | Mekgineer Thermaplugg | 2772 | 7800 | Mecangenheiro Termaplugue |

## Grau de confirmação

- **Build, mapa e dificuldade:** confirmados no cliente local `wow_classic_beta` versão `1.60.1.70009`; `MapID`/`instanceID` 90 e `DifficultyID` 201.
- **Encontros e ordem:** confirmados na tabela `DungeonEncounter` do build. Os IDs 2768–2772 são distintos e pertencem à dificuldade Normal.
- **NPCs e nomes PT-BR:** cruzados com páginas localizadas do Wowhead Forever e do Classic.
- **Mecânicas, percurso e inimigos comuns:** referência Classic; validação no Forever pendente. Não foram importadas as fases e habilidades da versão de raide da Temporada da Descoberta.
- **Raro:** Embaixador Ferro Negro é uma aparição opcional sem linha própria na dificuldade Normal. Permanece no guia de inimigos e não aumenta a contagem.
- **Evento:** Mestre de Explosão Emi Pavio Curto inicia o evento que leva a Grúdio. O NPC e as ondas não são encontros adicionais nem automações do addon.

## Percurso e preparação

No Salão das Engrenagens, siga primeiro pela esquerda para o evento opcional de Emi e Grúdio. Retorne à área aberta, desça para Precipitação Radioativa Viscosa e continue pela Zona Limpa até a Baía de Lançamento e Eletrocutor 6000. Faça o desvio pelos Laboratórios de Engenharia para Espanca-gente 9-60, volte ao túnel principal e atravesse os grupos Ferro Negro até o Tribunal dos Engenhoqueiros e Termaplugue.

O evento de Emi deve começar somente depois de o grupo recuperar vida e mana. O tanque recolhe as ondas, os DPS protegem a NPC e o curador, e todos acompanham o avanço. Essa explicação não cria um encontro fictício nem afirma condições de reinício ainda não confirmadas no beta.

No encontro final, os responsáveis pelos seis dispensadores devem ser combinados antes da puxada. Acionar o botão correspondente impede novas Bombinhas Andantes daquele dispensador; bombas já liberadas continuam prioritárias.

## Separação da versão de raide

As linhas de `DungeonEncounter` com `DifficultyID` 198, incluindo Viveiro Mecânico e identificadores diferentes para os demais chefes, não pertencem a este pacote. Mecânicas sazonais como trajes, múltiplas fases e tipos adicionais de bomba foram deliberadamente excluídas.

## Fontes consultadas em 25/09/2026

- [DungeonEncounter — build 1.60.1.70009](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70009)
- [Guia Classic da Icy Veins](https://www.icy-veins.com/wow-classic/gnomeregan-dungeon-guide)
- [Estratégia localizada do Wowhead Classic](https://www.wowhead.com/classic/pt/guide/gnomeregan-dungeon-strategy-wow-classic)
- [Missões de Gnomeregan no Forever](https://www.wowhead.com/forever/pt/quests/dungeons/gnomeregan)
- [Grúdio](https://www.wowhead.com/forever/pt/npc=7361/grudio)
- [Precipitação Radioativa Viscosa](https://www.wowhead.com/forever/pt/npc=7079/precipitacao-radioativa-viscosa)
- [Eletrocutor 6000](https://www.wowhead.com/forever/pt/npc=6235/eletrocutor-6000)
- [Espanca-gente 9-60](https://www.wowhead.com/forever/pt/npc=6229/espanca-gente-9-60)
- [Mecangenheiro Termaplugue](https://www.wowhead.com/forever/pt/npc=7800/mecangenheiro-termaplugue)
- [Embaixador Ferro Negro](https://www.wowhead.com/forever/pt/npc=6228/embaixador-ferro-negro)

## Pendências no jogo

- Confirmar os cinco nomes e IDs emitidos por `ENCOUNTER_START`/`ENCOUNTER_END`.
- Revisar Raio Encadeado, Megavolt, Choque, Golpe em Arco, Espanca-gente, Pisotear, Repelir e os dispensadores.
- Confirmar a grafia de Mestre de Explosão Emi Pavio Curto, Mordelis e dos inimigos comuns no cliente ptBR.
- Verificar o comportamento do evento de Emi sem presumir regras de reinício.
- Confirmar a presença e as habilidades do Embaixador Ferro Negro sem promovê-lo a encontro.
- Testar diário, minipainel, filtros por função, compartilhamento, avanço automático e painel de inimigos.
