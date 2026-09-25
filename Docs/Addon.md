# Addon e formato dos dados

Boss Tactics apresenta táticas de chefes e inimigos comuns em português brasileiro. O pacote Forever mantém identificadores confirmados separados de estratégias que ainda dependem de referências Classic.

## Versão verificada

- Cliente local: WoW Forever beta `1.60.1.70009`, produto `wow_classic_beta`, conferido em `World of Warcraft/.build.info` em 25/09/2026.
- Interface do addon: `16001`, correspondente à linha `1.60.1` instalada.
- Cavernas Ígneas: `MapID`/`instanceID` 389.
- Caverna Ululante: `MapID`/`instanceID` 43.
- Minas Mortas: `MapID`/`instanceID` 36.
- Bastilha da Presa Negra: `MapID`/`instanceID` 33.
- O Cárcere: `MapID`/`instanceID` 34.
- Profundezas Negras: `MapID`/`instanceID` 48 (`DifficultyID` 201 para a versão Normal de cinco jogadores).
- Monastério Escarlate: Cemitério: `MapID`/`instanceID` 189, compartilhado com as demais alas; somente os encontros 444 e 2779 pertencem a este pacote.
- Monastério Escarlate: Biblioteca: `MapID`/`instanceID` 189, compartilhado com as demais alas; somente os encontros 446 e 447 pertencem a este pacote.
- Gnomeregan: `MapID`/`instanceID` 90 (`DifficultyID` 201 para a versão Normal de cinco jogadores); linhas da versão de raide foram excluídas.
- Urzal dos Tuscos: `MapID`/`instanceID` 47; somente os seis encontros confirmados na tabela do cliente entram no contador.

## Organização

- `Data/Forever/Init.lua` cria `BT_BossData`, `BT_TrashData` e `BT_RaidBriefData` sem substituir tabelas existentes.
- Cada arquivo em `Data/Forever/Dungeons/` acrescenta seus registros individualmente a `BT_BossData` e, quando aplicável, registra `BT_TrashData` com a mesma chave de masmorra.
- `Docs/Dungeons/` contém evidências, fontes e pendências por masmorra.
- `Docs/Templates/` contém modelos de contribuição e nunca entra no manifesto.
- `OBSOLETOS/` e `Arquivo/` permanecem fora do carregamento.

## Regras de identificação

- `instanceID` corresponde ao mapa/instância retornado pelo cliente, não ao ID de zona externa.
- `encounterID` vem da tabela `DungeonEncounter` do build documentado.
- `npcID` e `sourceName` são documentais: a detecção atual utiliza nome e `encounterID`.
- Identificadores não confirmados devem ser omitidos. Não use `0`, IDs de Retail ou valores presumidos.
- `journalOrder` segue a ordem editorial da tabela do cliente, mesmo quando o percurso físico encontra chefes em outra sequência; divergências devem ser registradas no documento da masmorra.
- A dificuldade de masmorras permanece Normal. `difficulty` e `affixTips` ficam ausentes até existir correspondência confirmada no cliente-alvo.

## Conteúdo editorial

- `abilities` explica o que acontece, quem age e qual resposta tomar, sempre com `role` e `type` aceitos.
- `tips` cobre preparação, posicionamento, prioridades e erros frequentes.
- `tldr` contém de três a cinco instruções curtas.
- Orientações de função são incluídas somente quando forem úteis.
- Valores de dano, distância, duração, percentuais e regras de dissipação não são cadastrados sem confirmação adequada.
- Mecânicas sustentadas apenas por Classic recebem a indicação “referência Classic; validação no Forever pendente”.

## Validação mínima

- Validar sintaxe e carregamento de todos os arquivos do manifesto.
- Garantir que novos registros preservem as tabelas e masmorras já existentes.
- Conferir campos obrigatórios, papéis, tipos, ordem e ausência de `encounterID` duplicado.
- Confirmar que fases, raros sem encontro e eventos explicativos não aumentem a contagem de chefes.
- No jogo, testar nomes PT-BR, `ENCOUNTER_START`/`ENCOUNTER_END`, avanço, diário, minipainel, filtros, compartilhamento e painel de inimigos.
- Testes de Lua não substituem a validação dentro do cliente.
