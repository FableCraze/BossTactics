# Boss Tactics

Boss Tactics apresenta táticas de chefes e inimigos comuns em português brasileiro. O addon pode acompanhar automaticamente a masmorra ou raide atual, filtrar orientações por função e preparar resumos para compartilhar com o grupo.

## Como abrir

- Clique com o botão esquerdo no ícone do minimapa para abrir o Diário de Chefes.
- Clique com o botão direito no ícone do minimapa para abrir as opções.
- Arraste o ícone para reposicioná-lo ao redor do minimapa.
- Digite `/bosstactics` para abrir ou fechar o Diário de Chefes.
- Digite `/bosstactics ajuda` para mostrar a lista de comandos no chat.

## Minipainel de táticas

Ao entrar em uma instância conhecida, o minipainel pode abrir automaticamente e acompanhar o chefe atual. Durante os encontros, ele exibe as orientações mais importantes de acordo com o filtro de função escolhido.

No cabeçalho e no rodapé do painel você pode:

- alternar entre todas as funções, tanque, curador e DPS;
- avançar ou voltar entre os chefes da instância;
- alternar entre a visualização rápida e a detalhada;
- consultar TLDR, habilidades, dicas e inimigos comuns;
- compartilhar as orientações visíveis no chat;
- abrir o Diário, o Resumo da Raide ou as opções;
- minimizar, fechar, mover ou redimensionar o painel.

Os controles do rodapé aparecem ao passar o mouse. Nas opções, é possível bloquear a posição, ajustar escala, transparência, largura, fonte e comportamento automático.

## Diário de Chefes

O Diário reúne as informações completas da instância. Escolha um chefe na lista lateral e use as abas para consultar:

- visão geral da instância;
- prioridades de inimigos comuns;
- resumo TLDR;
- habilidades;
- dicas e orientações de afixos.

Use os botões de função para filtrar o conteúdo. As caixas de seleção permitem montar um resumo somente com as mecânicas desejadas. Esse resumo pode ser compartilhado no chat ou enviado ao Estúdio do Líder de Raide.

O campo **Anotações pessoais** é salvo localmente para o chefe e a dificuldade atual. O texto não é enviado ao grupo automaticamente.

Nas masmorras, a visualização usa atualmente a dificuldade Normal e o seletor fica oculto. As raides continuam mostrando e respeitando suas dificuldades próprias.

## Painel de inimigos comuns

O painel de inimigos comuns mostra os alvos e habilidades prioritários da masmorra atual. Clique em um inimigo para expandir ou recolher seus detalhes. O conteúdo também respeita o filtro de função.

O painel pode ser aberto ou ocultado pelo minipainel e configurado separadamente nas opções.

## Estúdio do Líder de Raide

O Estúdio transforma as táticas do addon em um plano ordenado para o grupo:

1. Escolha um chefe e adicione as táticas desejadas.
2. Organize os blocos, inclua anotações e preencha atribuições.
3. Revise a saída em formato WoW, Discord ou texto simples.
4. Compartilhe o chefe atual, copie o texto ou exporte o plano.

Os planos são salvos automaticamente. As predefinições ajudam a criar rapidamente um resumo para grupo aleatório ou progressão de guilda. O botão **Desfazer** restaura a versão anterior após alterações importantes.

## Resumo da Raide

O Resumo da Raide é um texto livre por chefe. Use **Editar** para criar ou alterar o conteúdo e **Copiar** para selecionar o texto. Prefixos como `TANQUE:`, `CURADOR:`, `DPS:` e `INTERROMPER:` recebem cores próprias; linhas iniciadas por `## ` formam cabeçalhos.

## Editor de chefes

O editor permite personalizar táticas existentes ou criar chefes próprios. É possível alterar o resumo, as habilidades, as dicas e os dados de identificação. A prévia mostra como o conteúdo aparecerá no painel antes de salvar.

Use **Restaurar padrão** para remover alterações de um chefe distribuído pelo addon. Chefes personalizados também podem ser excluídos pelo editor.

## Importação, exportação e compartilhamento

O editor e o Estúdio possuem ações de importação e exportação. Para importar, cole o pacote, confira a prévia apresentada e confirme. Para exportar ou copiar, use `Ctrl+C` quando o texto estiver selecionado.

O compartilhamento no chat usa o canal adequado ao grupo atual. Se o cliente bloquear o envio direto, o addon abrirá uma janela de cópia para que o texto seja colado manualmente no chat.

## Comandos

| Comando | Ação |
| --- | --- |
| `/bosstactics` | Abre ou fecha o Diário de Chefes. |
| `/bosstactics show` | Abre o minipainel em modo de teste. |
| `/bosstactics hide` | Fecha o minipainel. |
| `/bosstactics test` | Ativa ou desativa a prévia do painel. |
| `/bosstactics test off` | Encerra o modo de teste. |
| `/bosstactics journal` | Abre o Diário de Chefes. |
| `/bosstactics raidlead` | Abre o Estúdio do Líder de Raide. |
| `/bosstactics brief` | Abre o Resumo da Raide. |
| `/bosstactics options` | Abre as opções. |
| `/bosstactics edit` | Abre o editor de chefes. |
| `/bosstactics lock` | Bloqueia ou desbloqueia a posição do minipainel. |
| `/bosstactics reset` | Redefine a posição do minipainel. |
| `/bosstactics resetsize` | Redefine escala, largura e fonte. |
| `/bosstactics fontsize N` | Define a fonte entre 10 e 20. |
| `/bosstactics boss NOME` | Mostra um chefe pelo nome no painel. |
| `/bosstactics chatdebug` | Exibe o diagnóstico de compartilhamento. |

## Modo de teste

Use `/bosstactics test` ou a opção correspondente para experimentar o painel fora de uma luta. Nesse modo, você pode navegar pelos chefes, testar filtros, alternar visualizações e conferir tamanhos, fontes e transparência sem alterar o andamento real da instância.
