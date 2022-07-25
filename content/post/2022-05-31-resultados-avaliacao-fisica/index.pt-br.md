---
title: Visualizando os resultados da avalição física e a diferença entre atletas no RStudio
author: ''
date: '2022-07-20'
slug: resultados-avaliacao-fisica
categories:
  - Tutoriais em R
tags:
  - R
  - Avaliação física
description: ~
image: header.png
math: ~
license: ~
hidden: no
comments: yes
---

Quando avaliamos um grupo de atletas, precisamos saber quais as principais características de cada um(a) e as principais diferenças entre eles(as). Para isso, existem algumas maneiras de processamento e visualização dos dados que nos trazem essas informações de maneira rápida e intuitiva. Hoje nós vamos usar o R para explorar algumas informações antropométricas e de desempenho do [**NBA Draft Combine**](https://www.nba.com/stats/draft/combine/) e visualizar as características de cada atleta em relação ao grupo.

Para isso, passaremos por duas etapas: processamento e visualização dos dados. Na primeira calcularemos uma medida que normalizará os resultados do grupo para que possamos analisar cada atleta em relação a seus pares. Em seguida, alteraremos a estrutura dos nossos dados para uma seja mais amigável para o pacote `ggplot2` construir nossos gráficos.

------------------------------------------------------------------------

### Processando os dados

Eu selecionei as seguintes variáveis: **altura (cm)**, **massa (Kg)**, **envergadura (cm)**, **altura de salto parado (cm)**, **altura de salto em movimento (cm)**, **repetições no supino (n)**, **teste de agilidade (s)** e **sprint (s)**. Depois de carregar os dados no R, vamos dar uma olhada nas primeiras linhas:

``` r
knitr::kable(head(draft,5), format = "html", digits = 2)
```

| Atleta            | Pick |  Ano | Altura (cm) | Envergadura (cm) | Massa (Kg) | Supino (reps) | Agilidade (s) | Sprint (s) | Salto em mov. (cm) | Salto parado (cm) |
|:------------------|-----:|-----:|------------:|-----------------:|-----------:|--------------:|--------------:|-----------:|-------------------:|------------------:|
| Blake Griffin     |    1 | 2009 |      204.47 |           211.46 |     112.49 |            22 |         10.95 |       3.28 |              90.17 |             81.28 |
| Terrence Williams |   11 | 2009 |      195.58 |           205.74 |      96.62 |             9 |         11.15 |       3.18 |              93.98 |             77.47 |
| Gerald Henderson  |   12 | 2009 |      193.04 |           208.92 |      97.52 |             8 |         11.17 |       3.14 |              88.90 |             80.01 |
| Tyler Hansbrough  |   13 | 2009 |      203.84 |           212.09 |     106.14 |            18 |         11.12 |       3.27 |              86.36 |             69.85 |
| Earl Clark        |   14 | 2009 |      204.47 |           219.71 |     103.42 |             5 |         11.17 |       3.35 |              83.82 |             72.39 |

O próximo passo é normalizar essas variáveis para que possamos fazer comparações entre os atletas em relação a média do grupo. Para fazer isso, vamos por etapas. Primeiro, vamos utilizar a função `scale()` para transformar nossas variáveis em Z-Score (a função fará isso separadamente para cada coluna que indicarmos).

``` r
draft[,4:11] <- scale(draft[,4:11])
```

Em seguida, vamos transformar esses valores em T-Scores com a fórmula abaixo.

``` r
draft[,4:11] <- (draft[,4:11] * 10) + 50
```

Temos agora os T-Scores de cada variável para todos os atletas. O valor 50 representa a média do grupo (Z-Score = 0) e a distância de 10 unidades representa 1 desvio-padrão (DP) acima ou abaixo da média. Portanto, no T-Score, é comum que a maior parte dos valores caiam entre 20 e 80 (até 3 DP).

Precisamos lembrar que algumas das variáveis selecionadas estão em tempo (s) e, nos nossos testes, o menor tempo indica um melhor desempenho - ao contrário das outras medidas. Portanto, para que os T-Scores indiquem igualmente a condição de um desempenho "bom" ou "ruim", inverteremos (100 - T-Score) os valores das variáveis medidas em tempo. Dessa forma, temos que valores acima de 50 representam um "desempenho" acima da média. Vamos dar uma olhada no que temos até agora:

``` r
knitr::kable(head(draft,11), format = "html", digits = 1)
```

| Atleta            | Pick |  Ano | Altura (cm) | Envergadura (cm) | Massa (Kg) | Supino (reps) | Agilidade (s) | Sprint (s) | Salto em mov. (cm) | Salto parado (cm) |
|:------------------|-----:|-----:|------------:|-----------------:|-----------:|--------------:|--------------:|-----------:|-------------------:|------------------:|
| Blake Griffin     |    1 | 2009 |        58.8 |             51.9 |       63.4 |          73.8 |          56.8 |       51.5 |               51.0 |              57.9 |
| Terrence Williams |   11 | 2009 |        48.1 |             46.2 |       49.3 |          47.5 |          53.2 |       59.3 |               55.2 |              53.0 |
| Gerald Henderson  |   12 | 2009 |        45.1 |             49.4 |       50.1 |          45.5 |          52.8 |       62.4 |               49.6 |              56.3 |
| Tyler Hansbrough  |   13 | 2009 |        58.0 |             52.5 |       57.8 |          65.7 |          53.7 |       52.3 |               46.8 |              43.2 |
| Earl Clark        |   14 | 2009 |        58.8 |             60.2 |       55.3 |          39.4 |          52.8 |       46.1 |               44.0 |              46.4 |
| Austin Daye       |   15 | 2009 |        62.6 |             60.8 |       40.7 |            NA |          36.2 |       30.5 |               30.0 |              35.0 |
| James Johnson     |   16 | 2009 |        54.2 |             55.7 |       67.1 |          65.7 |          52.1 |       55.4 |               49.6 |              53.0 |
| Jrue Holiday      |   17 | 2009 |        42.8 |             41.1 |       43.6 |          41.4 |          62.3 |       57.0 |               46.8 |              46.4 |
| Ty Lawson         |   18 | 2009 |        30.7 |             25.3 |       42.8 |          57.6 |          56.2 |       64.0 |               53.8 |              48.1 |
| Jeff Teague       |   19 | 2009 |        33.7 |             42.4 |       33.9 |          55.6 |          55.0 |       59.3 |               53.8 |              53.0 |
| Hasheem Thabeet   |    2 | 2009 |        73.2 |             69.7 |       71.1 |            NA |            NA |         NA |                 NA |                NA |

Quase tudo pronto para plotarmos! Antes disso, precisamos colocar os dados em uma estrutura diferente. Ao invés de termos uma coluna para cada variável, nós "empilharemos" essas variáveis e repetiremos as informações que identificam cada atleta (Atleta, Ano e Pick). Para fazer isso, utilizaremos a função `melt()` do pacote `reshape2`. Essa função pede cinco argumentos:

> `x =` O objeto que será modificado
>
> `id.vars =` As variáveis de identificação *(nome, grupo etc)*
>
> `measure.vars =` As variáveis que serão empilhadas
>
> `variable.name =` O nome da nova coluna de variáveis
>
> `value.name =` O nome da nova coluna com os valores de cada variável

``` r
library(reshape2)

df <- melt(draft, # Nossos dados até agora
           id.vars = c("Atleta", "Ano", "Pick"), # Variáveis de identificação
           variable.name = "Variavel", # Nome da coluna das variaveis
           value.name = "TS") # Nome da coluna dos valores de cada variavel
```

> Reparem que eu não especifiquei as measure.vars - a função entende que as colunas que eu não especifiquei como id.vars devem ser consideradas as variáveis a serem "empilhadas".

### Visualizando os dados

Para visualizar esses dados, utlizaremos um ["gráfico de barras circular"](https://r-graph-gallery.com/web-circular-barplot-with-R-and-ggplot2.html) que servirá muito bem aos nossos objetivos. Para construir esse tipo de gráfico, vamos utilizar o pacote `ggplot2` - que está dentro pacote `tidyverse`.

Vamos começar a construir o gráfico utilizando apenas os dados de um atleta. Reparem que no código abaixo eu filtro nossos dados pelo nome do atleta que está na primeira linha. Essa mesma função nos servirá depois para olhar os dados de um atleta específico ou de um grupo de atletas.

``` r
library(tidyverse)

df %>% filter(Atleta %in% head(x = df$Atleta, 1)) %>%
  ggplot() +
  geom_col(aes(x = Variavel, y = TS, fill = TS)) +
  geom_hline(yintercept = 50, linetype = "dashed")
```

<img src="/post/2022-05-31-resultados-avaliacao-fisica/index.pt-br_files/figure-html/unnamed-chunk-8-1.png" width="672" />

Ainda parece meio bagunçado... mas já fizemos alguma coisa. 😅

Desenhamos uma linha pontilhada indicando o valor 50. Então já temos que este atleta está um pouco acima da média na maioria das variáveis. Vamos tornar esse gráfico circular utilizando a função `coord_polar()` e exibir o nome do atleta utilizando a função `facet_wrap()`.

``` r
df %>% filter(Atleta %in% head(x = df$Atleta, 1)) %>%
  ggplot() +
  geom_col(aes(x = Variavel, y = TS, fill = TS)) +
  geom_hline(yintercept = 50, linetype = "dashed") +
  coord_polar(clip = "off") +
  facet_wrap(~Atleta)
```

<img src="/post/2022-05-31-resultados-avaliacao-fisica/index.pt-br_files/figure-html/unnamed-chunk-9-1.png" width="672" />

Estamos chegando lá! Vamos modificar um pouco esse gráfico dando atenção especial aos limites do eixo Y e as cores que indicam a magnitude to T-Score. Como sabemos que a maior parte dos valores cairá entre 20 e 80 (3 DP), podemos definir esses valores como o limite inferior e superior do eixo, respectivamente.

``` r
df %>% filter(Atleta %in% head(x = df$Atleta, 1)) %>%
  ggplot() +
  geom_col(aes(x = Variavel, y = TS, fill = TS), color = "black") +
  geom_hline(yintercept = 50, linetype = "dashed") +
  coord_polar(clip = "off", start = .4) +
  scale_fill_distiller(palette = "RdBu", direction = 1,
                       limits = c(30,80)) +
  scale_y_continuous(
    limits = c(-40, 80),
    expand = c(0, 0),
    breaks = c(20, 40, 60, 80)
  ) + 
  theme_minimal() +
  facet_grid(~Atleta) +
  theme(
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    axis.text.y = element_blank(),
    axis.text.x = element_text(size = 8),
    text = element_text(size = 18),
    legend.position = "none",
    panel.spacing = unit(3, "lines")
  )
```

<img src="/post/2022-05-31-resultados-avaliacao-fisica/index.pt-br_files/figure-html/unnamed-chunk-10-1.png" width="672" />

Agora que construímos o gráfico utilizando as informações de apenas um atleta e de suas características em relação ao grupo avaliado, podemos brincar com as opções de customização do `ggplot2` e plotar um grupo de atletas lado a lado. Para fazer isso, basta alterar a **primeira linha** do gráfico onde utilizamos a função `filter()` para selecionar o primeiro atleta da tabela. Vamos plotar as 3 primeiras escolhas do NBA Draft de 2010 utlizando essa função (linha baixo) - o código completo do gráfico abaixo você encontra no final desse post.

``` r
df %>% filter(Pick %in% c(1:3), Ano == 2010)
```

![](plot2.png)

Vimos que calcular medidas como o Z-Score e T-Score é relativamente fácil no R e elas podem ser muito úteis para comparar os atletas em relação ao grupo avaliado e detectar os "destaques" pra cada variável. Ainda, um gráfico de barras circular pode ser facilmente construído com a função `coord_polar`. A partir daí, podemos brincar com os diferentes parâmetros do `ggplot2` para criar figuras mais eficientes e intuitivas de acordo com os nossos objetivos. Eu recomendo [essa lista de tutoriais](http://r-statistics.co/Top50-Ggplot2-Visualizations-MasterList-R-Code.html) que cobre cada aspecto do `ggplot2`, dependendo tipo de informação que você quer mostrar. Abaixo está a versão final do gráfico, construída alterando alguns desses parâmetros. Bons estudos **🤓**

![](plot.png)

> <details>
>
> <summary>
>
> *Código completo do gráfico (clique para ver):*
>
> </summary>
>
>
> ```r
> library(forcats)
>
> pick.labs = c("Pick #1", "Pick #2", "Pick #3")
> names(pick.labs) <- c(1,2,3)
>
> df %>% filter(Pick %in% c(1:3), Ano == 2010) %>%
>   ggplot() +
>   geom_col(aes(x = Variavel, y = TS, fill = TS), color = "black") +
>   geom_hline(yintercept = 50, linetype = "dashed") +
>   coord_polar(clip = "off", start = .4) +
>   
>   
>   scale_fill_distiller(palette = "RdBu", direction = 1,
>                        limits = c(30,70),
>                        labels = c("Abaixo da média", " ", " ", " ", "Acima da média")) +
>   scale_y_continuous(
>     limits = c(-40, 80),
>     expand = c(0, 0),
>     breaks = c(20, 40, 60, 80)) + 
>   
>   scale_x_discrete(labels=c("Envergadura (cm)" = "Env. (cm)", 
>                             "Salto em mov. (cm)" = "Salto em \n mov. (cm)",
>                             "Salto parado (cm)" = "Salto\nparado(cm)")) +
>   
>   theme_minimal() +
>   
>   facet_wrap(~fct_relevel(Atleta, 'John Wall', 'Evan Turner', 'Derrick Favors') + Pick, 
>              nrow = 1, labeller = labeller(Pick = pick.labs)) +
>   
>   guides(fill=guide_legend(
>     label.position = 'bottom', 
>     title.position = 'top',
>     keywidth=.7,
>     label.theme = element_text(size = 8, color = "black"),
>     title.theme = element_blank(),
>     keyheight= .10,
>     default.unit="inch", 
>     title.hjust = .5,
>     title.vjust = 0,
>     label.vjust = 3,
>     nrow = 1)) +
>
>   theme(
>     # Removendo os títulos e textos dos eixos
>     axis.title = element_blank(),
>     axis.ticks = element_blank(),
>     axis.text.y = element_blank(),
>     axis.text.x = element_text(size = 6, face = "bold", color = "black", vjust = 2),
>     text = element_text(size = 16),
>     legend.position = "bottom",
>     panel.spacing = unit(3, "lines"),
>     legend.spacing.x = unit(0, 'cm'),
>     plot.background = element_rect(fill = "white", color = "white"),
>     strip.text = element_text(size = 12, vjust = 3, face = "bold"),
>   )
> ```
>
> ```
> ## Warning: Removed 1 rows containing missing values (position_stack).
> ```
>
> <img src="/post/2022-05-31-resultados-avaliacao-fisica/index.pt-br_files/figure-html/unnamed-chunk-12-1.png" width="672" />
>
> </details>
