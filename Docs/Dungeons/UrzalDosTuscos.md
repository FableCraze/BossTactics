# Urzal dos Tuscos

O pacote representa os seis encontros presentes na tabela `DungeonEncounter` do build `1.60.1.70009`. Raros sem linha própria e a escolta de Importador Willix permanecem como conteúdo explicativo, sem aumentar a contagem de chefes.

| Ordem | Nome na tabela do cliente | encounterID | npcID | Nome ptBR usado |
|---:|---|---:|---:|---|
| 1 | Roogug | 2773 | 6168 | Rugug |
| 2 | Aggem Thorncurse | 2774 | 4424 | Aggem Pragacardo |
| 3 | Death Speaker Jargba | 2775 | 4428 | Morta-voz Jargba |
| 4 | Overlord Ramtusk | 2776 | 4420 | Lorde Supremo Marretusco |
| 5 | Agathelos the Raging | 2777 | 4422 | Agathelos, o Furioso |
| 6 | Charlga Razorflank | 2778 | 4421 | Charlga Talhaflanco |

## Grau de confirmação

- **Build e mapa:** confirmados no cliente local `wow_classic_beta` versão `1.60.1.70009`; `MapID`/`instanceID` 47.
- **Encontros e ordem:** confirmados na tabela `DungeonEncounter`; os seis IDs são distintos e aparecem nos índices de 1 a 6.
- **NPCs e nomes PT-BR:** cruzados com páginas localizadas do Wowhead Forever e do Classic.
- **Mecânicas, percurso e inimigos comuns:** referência Classic; validação no Forever pendente. Nenhum valor de dano, distância, duração ou percentual foi cadastrado.
- **Raros:** Caçador Cego, Arauto da Terra Halmgar e Couriço do Urzal podem não estar presentes e não possuem linha em `DungeonEncounter`. Permanecem no guia de inimigos.
- **Escolta:** Importador Willix é um NPC de missão depois da rota principal. A orientação não cria encontro ou automação e não afirma que uma falha exija reiniciar a instância.

## Percurso

Permaneça nas passarelas superiores até derrotar Charlga. Rugug ocupa um desvio opcional; a rota principal segue por Aggem, Jargba e Marretusco. Depois, atravesse as plataformas onde Halmgar pode aparecer, passe pela caverna do Caçador Cego, enfrente Agathelos e suba até a cabana de Charlga.

Depois da chefe final, o grupo pode descer para a área inferior e iniciar a escolta de Willix. Antes de falar com ele, reúna todos e recupere vida e mana. Durante o trajeto, o tanque recolhe inimigos, os DPS protegem o NPC e o curador, e o grupo acompanha o avanço sem se dividir.

## Fontes consultadas em 25/09/2026

- [DungeonEncounter — build 1.60.1.70009](https://wago.tools/db2/DungeonEncounter/csv?build=1.60.1.70009)
- [Guia Classic da Icy Veins](https://www.icy-veins.com/wow-classic/razorfen-kraul-dungeon-guide)
- [Estratégia localizada do Wowhead Classic](https://www.wowhead.com/classic/pt/guide/razorfen-kraul-dungeon-strategy-wow-classic)
- [Missão de Importador Willix no Forever](https://www.wowhead.com/forever/pt/quest=1144/importador-willix)
- [Rugug](https://www.wowhead.com/forever/pt/npc=6168/rugug)
- [Aggem Pragacardo](https://www.wowhead.com/forever/pt/npc=4424/aggem-pragacardo)
- [Morta-voz Jargba](https://www.wowhead.com/forever/pt/npc=4428/morta-voz-jargba)
- [Lorde Supremo Marretusco](https://www.wowhead.com/forever/pt/npc=4420/lorde-supremo-marretusco)
- [Agathelos, o Furioso](https://www.wowhead.com/forever/pt/npc=4422/agathelos-o-furioso)
- [Charlga Talhaflanco](https://www.wowhead.com/forever/pt/npc=4421/charlga-talhaflanco)
- [Caçador Cego](https://www.wowhead.com/forever/pt/npc=4425/cacador-cego)
- [Arauto da Terra Halmgar](https://www.wowhead.com/forever/pt/npc=4842/arauto-da-terra-halmgar)

## Pendências no jogo

- Confirmar os seis nomes e IDs emitidos por `ENCOUNTER_START`/`ENCOUNTER_END`.
- Revisar todas as habilidades registradas, especialmente Dominar Mente, os auxiliares de Marretusco, Enfurecer e Pureza.
- Confirmar a grafia e o comportamento dos Totemistas, Poeirentos, Adeptos e três raros.
- Verificar o percurso superior, os desvios opcionais e o evento de Importador Willix.
- Testar consulta por nome, avanço automático, diário, minipainel, filtros, compartilhamento e painel de inimigos.
