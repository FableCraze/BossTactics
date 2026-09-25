# Monastério Escarlate: Biblioteca

O `MapID` 189 é compartilhado pelas quatro alas do Monastério Escarlate. A tabela `DungeonEncounter` do build `1.60.1.70009` contém sete encontros para o mapa inteiro; somente `Houndmaster Loksey` e `Arcanist Doan`, nos índices globais 3 e 4, pertencem à Biblioteca. O `journalOrder` do pacote é local à ala, de 1 a 2.

| Ordem na ala | Ordem no cliente | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---:|---|---:|---:|---|
| 1 | 3 | Houndmaster Loksey | 446 | 3974 | Mestre de Matilha Lobato |
| 2 | 4 | Arcanist Doan | 447 | 6487 | Arcanista Doan |

## Grau de confirmação

- **Build e mapa compartilhado:** confirmados no cliente local `wow_classic_beta` versão `1.60.1.70009`; `MapID`/`instanceID` 189.
- **Encontros e ordem:** confirmados na tabela `DungeonEncounter`. Os registros anteriores pertencem ao Cemitério; os posteriores pertencem ao Arsenal e à Catedral.
- **NPCs e nomes PT-BR:** cruzados com páginas localizadas do Wowhead Forever e do Classic. O cliente localizado usa “Mestre de Matilha Lobato” para `Houndmaster Loksey`.
- **Mecânicas, percurso e inimigos comuns:** referência Classic; validação no Forever pendente. O cliente confirma os encontros, mas não fornece uma tabela de habilidades para esta versão.
- **Chave Escarlate:** o baú após Doan fornece a chave usada pelo Arsenal e pela Catedral. A Biblioteca não exige essa chave.
- **Auxiliares:** os três cães de Lobato fazem parte do encontro e não aumentam a contagem de chefes.

## Percurso

A Biblioteca usa o portal da direita e segue um percurso quase linear. Depois do primeiro corredor, o pátio oferece um desvio lateral para Mestre de Matilha Lobato; a rota principal atravessa as salas da biblioteca até Arcanista Doan.

Conjuradores devem ser trazidos com linha de visão, curas devem ser interrompidas e inimigos em fuga precisam ser parados antes que alcancem outro grupo. A câmara de Doan e o corredor anterior devem estar limpos para permitir o recuo durante Detonação.

## Fontes consultadas em 25/09/2026

- [DungeonEncounter — build 1.60.1.70009](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70009)
- [Guia Classic da Biblioteca — Icy Veins](https://www.icy-veins.com/wow-classic/scarlet-monastery-library-dungeon-guide)
- [Estratégia localizada do Monastério Escarlate](https://www.wowhead.com/classic/pt/guide/scarlet-monastery-dungeon-strategy-wow-classic)
- [Mestre de Matilha Lobato](https://www.wowhead.com/forever/pt/npc=3974/mestre-de-matilha-lobato)
- [Arcanista Doan](https://www.wowhead.com/forever/pt/npc=6487/arcanista-doan)

## Pendências no jogo

- Confirmar os nomes e IDs emitidos por `ENCOUNTER_START`/`ENCOUNTER_END` em Lobato e Doan.
- Revisar Sede de Sangue, Explosão Arcana, Silêncio, Polimorfia, Bolha Arcana e Detonação no beta.
- Confirmar os nomes e comportamentos dos Capelães, Vaticinadores, Senhores das Feras, Monges e cães da ala.
- Verificar o desvio opcional de Lobato e a obtenção da Chave Escarlate após Doan.
- Testar se o `instanceID` 189 compartilhado com as demais alas afeta consulta, diário ou avanço automático.
- Testar diário, minipainel, filtros por função, compartilhamento e painel de inimigos.
