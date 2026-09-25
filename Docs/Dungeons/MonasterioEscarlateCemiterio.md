# Monastério Escarlate: Cemitério

O `MapID` 189 é compartilhado pelas quatro alas do Monastério Escarlate. A tabela `DungeonEncounter` do build `1.60.1.70009` contém sete encontros para o mapa inteiro, mas somente os dois primeiros pertencem ao Cemitério. Este pacote não inclui encontros da Biblioteca, Arsenal ou Catedral.

| Ordem na ala | Ordem no cliente | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---:|---|---:|---:|---|
| 1 | 1 | Interrogator Vishas | 444 | 3983 | Interrogador Vishas |
| 2 | 2 | Bloodmage Thalnos | 2779 | 4543 | Mago Sangrento Thalnos |

## Grau de confirmação

- **Build e mapa compartilhado:** confirmados no cliente local `wow_classic_beta` versão `1.60.1.70009`; `MapID`/`instanceID` 189.
- **Encontros e ordem:** confirmados na tabela `DungeonEncounter`. Vishas e Thalnos ocupam os dois primeiros índices; os outros cinco registros pertencem às demais alas.
- **NPCs e nomes PT-BR:** cruzados com as páginas localizadas do Wowhead Forever.
- **Mecânicas, percurso e inimigos comuns:** referência Classic; validação no Forever pendente. O cliente confirma os encontros, mas não fornece uma tabela de habilidades para esta versão.
- **Raros:** Ashir, o Insone, Campeão Caído e Espinha de Ferro são aparições opcionais sem linha própria em `DungeonEncounter`. Permanecem no guia de inimigos e não aumentam a contagem da ala.
- **NPC de missão:** Vorrel Sengutz é conteúdo explicativo da câmara de tortura, não um chefe ou evento automatizado.

## Percurso

O Cemitério usa o portal da extrema esquerda e não exige a Chave Escarlate. O percurso é linear: câmara de tortura e Vishas, Claustro Abandonado com mortos-vivos e possíveis raros, descida para a Tumba da Honra e Thalnos.

As orientações recomendam puxadas controladas, impedimento de inimigos em fuga e limpeza das áreas de raros. Não são registrados percentuais ou tempos de reaparecimento porque essas informações ainda precisam ser confirmadas no beta.

## Fontes consultadas em 25/09/2026

- [DungeonEncounter — build 1.60.1.70009](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70009)
- [Catálogo do Cemitério no Forever](https://wowforevertalent.com/dungeons/scarlet-monastery-graveyard/)
- [Catálogo geral do cliente Forever](https://wowforevertalents.com/dungeons/)
- [Guia Classic da ala Cemitério](https://www.icy-veins.com/wow-classic/scarlet-monastery-graveyard-dungeon-guide)
- [Estratégia localizada do Monastério Escarlate](https://www.wowhead.com/classic/pt/guide/scarlet-monastery-dungeon-strategy-wow-classic)
- [Interrogador Vishas](https://www.wowhead.com/forever/pt/npc=3983/interrogador-vishas)
- [Mago Sangrento Thalnos](https://www.wowhead.com/forever/pt/npc=4543/mago-sangrento-thalnos)
- [Ashir, o Insone](https://www.wowhead.com/forever/pt/npc=6490/ashir-o-insone)
- [Campeão Caído](https://www.wowhead.com/forever/pt/npc=6488/campeao-caido)
- [Espinha de Ferro](https://www.wowhead.com/forever/pt/npc=6489/espinha-de-ferro)

## Pendências no jogo

- Confirmar os nomes e IDs emitidos por `ENCOUNTER_START`/`ENCOUNTER_END` em Vishas e Thalnos.
- Revisar no beta Imolação, Seta Sombria, Aguilhão Flamejante e Nova de Fogo.
- Confirmar o comportamento de fuga, os conjuradores e os grupos de mortos-vivos da ala.
- Verificar a presença, a grafia e as habilidades dos três raros sem promovê-los a encontros.
- Testar se o compartilhamento do `instanceID` 189 com as demais alas afeta consulta, diário ou avanço automático.
- Testar diário, minipainel, filtros por função, compartilhamento e painel de inimigos.
