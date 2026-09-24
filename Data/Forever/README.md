# Base de guias — WoW Forever

Esta pasta contém somente dados confirmados para o WoW Forever. `Init.lua` cria as três raízes esperadas pelo addon (`BT_BossData`, `BT_TrashData` e `BT_RaidBriefData`) sem substituir tabelas já existentes. Cada arquivo em `Dungeons/` acrescenta seus registros a `BT_BossData`. O conteúdo de `Templates/` é documentação e não deve entrar no `.toc`.

## Versão verificada

- Cliente local: WoW Forever beta `1.60.1.69913`, produto `wow_classic_beta`, conferido em `World of Warcraft/.build.info` em 21/09/2026.
- Interface do addon: `16001`, correspondente à linha `1.60.1` instalada.
- Cavernas Ígneas: `MapID`/`instanceID` 389.

## Cavernas Ígneas

A tabela `DungeonEncounter` do próprio cliente, no build `1.60.1.69913`, confirma estes encontros e esta ordem:

| Ordem | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---|---:|---:|---|
| 1 | Oggleflint | 2732 | 11517 | Pederneiro |
| 2 | Taragaman the Hungerer | 2733 | 11520 | Taragaman, o Famélico |
| 3 | Jergosh the Invoker | 2734 | 11518 | Jergosh, o Invocador |
| 4 | Bazzalan | 2735 | 11519 | Bazzalan |

Os `npcID` e nomes ptBR foram cruzados com as páginas Forever do Wowhead. As mecânicas foram limitadas ao que os relatos específicos do beta descrevem: Cutilar; Nova de Fogo e Gancho; Imolação e Maldição da Fraqueza; Golpe Sinistro e Veneno Mortal, além dos auxiliares presentes nos três encontros correspondentes. Um relato de execução do beta também informa que não encontrou mecânicas novas.

Fontes consultadas:

- [DungeonEncounter — build 1.60.1.69913](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.69913)
- [Catálogo de Cavernas Ígneas extraído do beta](https://wowforevertalent.com/dungeons/ragefire-chasm/)
- [Guia e rota do beta](https://wowf.io/en/dungeons/ragefire-chasm/guide)
- [Mecânicas observadas no Forever](https://worstguidesever.com/wow-forever-ragefire-chasm-guide/)
- [Pederneiro — Wowhead Forever ptBR](https://www.wowhead.com/forever/pt/npc=11517/pederneiro)
- [Taragaman, o Famélico — Wowhead Forever ptBR](https://www.wowhead.com/forever/pt/npc=11520/taragaman-o-famelico)
- [Jergosh, o Invocador — Wowhead Forever ptBR](https://www.wowhead.com/forever/pt/npc=11518/jergosh-o-invocador)
- [Bazzalan — Wowhead Forever ptBR](https://www.wowhead.com/forever/pt/npc=11519/bazzalan)

## Pendências de validação no jogo

- Confirmar em uma execução controlada do beta os IDs de feitiço usados pelos NPCs; eles não foram cadastrados porque as fontes públicas não os ligam de forma inequívoca a este build.
- Confirmar o disparo de `ENCOUNTER_START`/`ENCOUNTER_END` para os quatro encontros e os nomes recebidos no cliente ptBR. Os `encounterID` acima já permitem o reconhecimento independente do idioma quando os eventos são emitidos.
- Testar entrada na instância, avanço automático, filtros `ALL`/`TANK`/`HEALER`/`DPS`, consulta manual e resumos com perfil limpo e com `BossTacticsDB` existente.
- Guias de inimigos comuns ficam para uma etapa posterior.

Nenhum encontro não confirmado deve ser incluído apenas para preencher o catálogo. Dados de dificuldade e afixos também permanecem ausentes até existir correspondência verificável no beta.
