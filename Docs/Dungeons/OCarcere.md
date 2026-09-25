# O Cárcere

A tabela `DungeonEncounter` do cliente no build `1.60.1.70009` confirma cinco encontros para o `MapID` 34. A ordem do diário não representa integralmente o percurso físico: o arquivo usa a ordem do cliente, enquanto o resumo de percurso descreve as alas e as celas sem prometer uma rota automática.

| Ordem | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---|---:|---:|---|
| 1 | Targorr the Dread | 2756 | 1696 | Targorr, o Horror |
| 2 | Kam Deepfury | 2757 | 1666 | Kam Fundafúria |
| 3 | Hamhock | 2758 | 1717 | Ramoque |
| 4 | Dextren Ward | 2759 | 1663 | Flávio Lúcio |
| 5 | Bazil Thredd | 2760 | 1716 | Basílio Taborda |

## Grau de confirmação

- **Build, instância, encontros e ordem:** confirmados no cliente local e na tabela `DungeonEncounter` do build `1.60.1.70009`.
- **NPCs e nomes PT-BR:** cruzados com páginas localizadas do Wowhead Forever e missões associadas.
- **Quantidade de chefes:** o catálogo Forever consultado lista cinco encontros para O Cárcere.
- **Mecânicas, percurso e inimigos comuns:** referência Classic, comparada ao guia Forever; validação no Forever pendente. O próprio guia comparativo informa que o caminho entre seus pontos ainda não foi verificado no beta.
- **Raro:** Bruegal Ferroque aparece somente no guia de inimigos. Ele não possui registro `DungeonEncounter` para a instância e não aumenta a contagem de chefes.

## Ordem do diário e percurso

`journalOrder` segue a ordem da tabela do cliente: Targorr, Kam, Ramoque, Flávio e Basílio. Para o percurso, o grupo deve puxar inimigos das celas para corredores já limpos, verificar as possíveis celas de Targorr e Kam, limpar a ala de Flávio antes do medo e então preparar espaço para Ramoque e Basílio. A posição variável de alguns chefes e a ausência de validação do caminho no beta impedem registrar uma rota rígida.

## Fontes consultadas em 25/09/2026

- [DungeonEncounter — build 1.60.1.70009](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70009)
- [Catálogo de masmorras do Forever](https://wowforevertalents.com/dungeons/)
- [Guia Classic](https://www.icy-veins.com/wow-classic/the-stockade-dungeon-guide)
- [Estratégia localizada Classic](https://www.wowhead.com/classic/pt/guide/the-stockade-dungeon-strategy-wow-classic)
- [Guia e percurso comparativo do Forever](https://wowf.io/en/dungeons/stockade/guide)
- [Catálogo localizado de O Cárcere](https://www.wowhead.com/forever/pt/zone=717/o-carcere)
- [Targorr, o Horror — missão localizada](https://www.wowhead.com/forever/pt/quest=386/tudo-que-vai)
- [Kam Fundafúria](https://www.wowhead.com/forever/pt/npc=1666/kam-fundafuria)
- [Ramoque](https://www.wowhead.com/forever/pt/npc=1717/ramoque)
- [Flávio Lúcio](https://www.wowhead.com/forever/pt/npc=1663/flavio-lucio)
- [Basílio Taborda](https://www.wowhead.com/forever/pt/npc=1716/basilio-taborda)
- [Bruegal Ferroque](https://www.wowhead.com/forever/pt/npc=1720/bruegal-ferroque)
- [Prisioneiros da rebelião — missão localizada](https://www.wowhead.com/forever/pt/quest=387/sufoque-a-rebeliao)

## Pendências no jogo

- Confirmar os nomes e IDs emitidos por `ENCOUNTER_START`/`ENCOUNTER_END` nos cinco encontros.
- Revisar no beta Surra, Enfurecer, postura e bloqueio de Kam, Cadeia de Raios, Sede de Sangue, Brado Intimidador, Bomba de Fumaça e Brado de Batalha.
- Confirmar as posições variáveis de Targorr e Kam, o comportamento de fuga dos prisioneiros e o reaparecimento de grupos.
- Confirmar a aparição e o nome de Bruegal Ferroque sem promovê-lo a encontro.
- Testar diário, minipainel, filtros por função, compartilhamento, painel de inimigos e avanço automático.
