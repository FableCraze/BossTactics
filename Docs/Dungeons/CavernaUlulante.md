# Caverna Ululante

A tabela `DungeonEncounter` do cliente no build `1.60.1.69977` confirma os oito encontros, IDs e ordem abaixo para o `MapID` 43. Os nomes exibidos são as formas PT-BR do catálogo localizado; `sourceName` conserva o nome da tabela.

| Ordem | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---|---:|---:|---|
| 1 | Lady Anacondra | 585 | 3671 | Lady Sucurina |
| 2 | Lord Cobrahn | 586 | 3669 | Lorde Cobrahn |
| 3 | Kresh | 587 | 3653 | Cresh |
| 4 | Lord Pythas | 588 | 3670 | Lorde Pítias |
| 5 | Skum | 589 | 3674 | Skória |
| 6 | Lord Serpentis | 590 | 3673 | Lorde Serpentis |
| 7 | Verdan the Everliving | 591 | 5775 | Verdan, o Sempre-vivo |
| 8 | Mutanus the Devourer | 592 | 3654 | Mutanus, o Devorador |

## Grau de confirmação

- **Build, instância, encontros e ordem:** confirmados na instalação local e na tabela `DungeonEncounter` do build documentado.
- **NPCs e nomes PT-BR:** IDs do catálogo de criaturas cruzados com o Wowhead Forever localizado.
- **Mecânicas, percurso, inimigos comuns e escolta:** referência Classic; validação no Forever pendente. Páginas intituladas Forever foram usadas somente para comparação.
- **Raro opcional:** Dragão Feérico Anormal aparece apenas no guia de inimigos e não integra `BT_BossData` nem a contagem dos oito encontros.

## Fontes consultadas em 24/09/2026

- [DungeonEncounter — build 1.60.1.69977](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.69977)
- [Catálogo extraído do build](https://wowforevertalents.com/dungeons/wailing-caverns/)
- [Guia Classic](https://www.icy-veins.com/wow-classic/wailing-caverns-dungeon-guide)
- [Guia e percurso comparativo do Forever](https://wowf.io/en/dungeons/wailing-caverns/guide)
- [Mutanus, o Devorador — Wowhead Forever ptBR](https://www.wowhead.com/forever/pt/npc=3654/mutanus-o-devorador)
- [Catálogo localizado](https://www.wowhead.com/pt/zone=718/caverna-ululante)

## Pendências no jogo

- Confirmar nomes e IDs emitidos por `ENCOUNTER_START`/`ENCOUNTER_END`. `npcID` e `sourceName` permanecem documentais.
- Revisar lançamentos, forma de serpente, sono, medo, dano em área e ondas da escolta. Nenhum valor numérico ou regra de dissipação foi cadastrado.
- Confirmar o nome do raro e o comportamento do evento do Discípulo de Naralex.
- Testar diário, minipainel, filtros, compartilhamento, painel de inimigos e avanço.
