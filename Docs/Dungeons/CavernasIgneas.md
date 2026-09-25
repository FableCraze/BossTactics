# Cavernas Ígneas

A tabela `DungeonEncounter` do cliente no build `1.60.1.69913` confirma estes encontros e esta ordem para o `MapID` 389:

| Ordem | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---|---:|---:|---|
| 1 | Oggleflint | 2732 | 11517 | Pederneiro |
| 2 | Taragaman the Hungerer | 2733 | 11520 | Taragaman, o Famélico |
| 3 | Jergosh the Invoker | 2734 | 11518 | Jergosh, o Invocador |
| 4 | Bazzalan | 2735 | 11519 | Bazzalan |

Os `npcID` e nomes PT-BR foram cruzados com as páginas Forever do Wowhead. As mecânicas foram limitadas ao que relatos específicos do beta descrevem: Cutilar; Nova de Fogo e Gancho; Imolação e Maldição da Fraqueza; Golpe Sinistro e Veneno Mortal, além dos auxiliares dos encontros correspondentes. Um relato de execução do beta também informa que não encontrou mecânicas novas.

## Fontes

- [DungeonEncounter — build 1.60.1.69913](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.69913)
- [Catálogo de Cavernas Ígneas extraído do beta](https://wowforevertalent.com/dungeons/ragefire-chasm/)
- [Guia e rota do beta](https://wowf.io/en/dungeons/ragefire-chasm/guide)
- [Mecânicas observadas no Forever](https://worstguidesever.com/wow-forever-ragefire-chasm-guide/)
- [Pederneiro — Wowhead Forever ptBR](https://www.wowhead.com/forever/pt/npc=11517/pederneiro)
- [Taragaman, o Famélico — Wowhead Forever ptBR](https://www.wowhead.com/forever/pt/npc=11520/taragaman-o-famelico)
- [Jergosh, o Invocador — Wowhead Forever ptBR](https://www.wowhead.com/forever/pt/npc=11518/jergosh-o-invocador)
- [Bazzalan — Wowhead Forever ptBR](https://www.wowhead.com/forever/pt/npc=11519/bazzalan)

## Pendências no jogo

- Confirmar os IDs de feitiço; eles não foram cadastrados porque as fontes públicas não os ligam de forma inequívoca ao build.
- Confirmar `ENCOUNTER_START`/`ENCOUNTER_END` e os nomes PT-BR recebidos.
- Testar entrada, avanço automático, filtros, consulta manual e resumos com perfil limpo e banco existente.
- Adicionar inimigos comuns somente após confirmar suas habilidades.

Nenhum encontro não confirmado deve ser incluído para preencher catálogo. Dados de dificuldade e afixos permanecem ausentes até existir correspondência verificável.
