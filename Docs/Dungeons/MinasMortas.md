# Minas Mortas

A tabela `DungeonEncounter` do cliente no build `1.60.1.70009` confirma os oito encontros abaixo para o `MapID` 36. `journalOrder` segue o `OrderIndex`, não a sequência física: Sr. Castiga é encontrado antes de Capitão Peleverde. Minerador João conta porque possui encontro próprio; Retalhador do Sneed e o canhão são fases ou eventos.

| Ordem | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---|---:|---:|---|
| 1 | Rhahk'Zor | 2741 | 644 | Rhahk'Zor |
| 2 | Sneed | 2742 | 643 | Sneed |
| 3 | Miner Johnson | 3676 | 3586 | Minerador João |
| 4 | Gilnid | 2743 | 1763 | Gilnid |
| 5 | Captain Greenskin | 2744 | 647 | Capitão Peleverde |
| 6 | Mr. Smite | 2745 | 646 | Sr. Castiga |
| 7 | Cookie | 2746 | 645 | Cuca |
| 8 | Edwin VanCleef | 2747 | 639 | Edwin VanCleef |

## Grau de confirmação

- **Build, instância, encontros e ordem:** confirmados no cliente e em `DungeonEncounter` do build documentado.
- **NPCs e nomes PT-BR:** cruzados com o Wowhead Forever e o catálogo do mesmo build.
- **Mecânicas, percurso e inimigos comuns:** referência Classic; validação no Forever pendente.
- **Raro e eventos:** Minerador João integra os oito encontros; Retalhador, patrulha do canhão e demais eventos aparecem somente no conteúdo explicativo.

## Fontes consultadas em 25/09/2026

- [DungeonEncounter — build 1.60.1.70009](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70009)
- [Catálogo extraído do build](https://wowforevertalents.com/dungeons/deadmines/)
- [Guia Classic](https://www.icy-veins.com/wow-classic/deadmines-dungeon-guide)
- [Estratégia localizada Classic](https://www.wowhead.com/classic/pt/guide/deadmines-dungeon-strategy-wow-classic)
- [Guia e percurso comparativo do Forever](https://wowf.io/en/dungeons/deadmines/guide)
- [Catálogo localizado](https://www.wowhead.com/forever/pt/zone=1581/minas-mortas)

## Pendências no jogo

- Confirmar nomes e IDs emitidos por `ENCOUNTER_START`/`ENCOUNTER_END`.
- Revisar lançamentos, controles, invocações, trocas de arma, reforços e comportamento de fuga.
- Confirmar Minerador João, a transição do Retalhador, a patrulha do canhão e a navegação nos conveses.
- Testar diário, minipainel, filtros, compartilhamento, painel de inimigos e avanço.
