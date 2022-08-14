---
title: Criando perfil de força-velocidade de sprints curtos com o pacote {shorts} no RStudio
author: 'Bruno Giovanini'
date: '2022-08-15'
slug: 'perfil-de-forca-velocidade-do-sprint'
categories:
  - Tutoriais em R 
tags:
  - R
  - Avaliação física
description: 
image: header.png
math: null
license: null
hidden: no
comments: yes
---



`por Vitor Bertoli Nascimento & Bruno Giovanini`

------------------------------------------------------------------------

Sprints curtos são definidos como uma corrida máxima, partindo do repouso, ao longo de uma distância que não resulta em desaceleração no final[^1]. Ou seja, que compreende principalmente a capacidade de aceleração dos atletas - como demanda a maioria dos esportes coletivos[^2]. Avaliar essa capacidade é crucial para monitorar e balizar os treinamentos de corrida.

[^1]: Jovanović, M., & Vescovi, J. (2022). {shorts}: An R Package for Modeling Short Sprints. *International Journal of Strength and Conditioning*, 2(1). <https://doi.org/10.47206/ijsc.v2i1.74>

[^2]: Haugen T.A., Breitschadel F., Seiler S. (2019). Sprint mechanical variables in elite athletes: Are force-velocity profiles sport specific or individual? *PLoS ONE*, 14(7). <https://doi.org/10.1371/journal.pone.0215551>

A avaliação de sprints curtos está presente em muitas baterias de testes e pode ser feita utilizando fotocélulas, análise de vídeo ou outros equipamentos. Além do tempo de sprint, configurações do teste (como a captura de diferentes distâncias) podem fornecer outras variáveis que permitem abordagens mais detalhadas sobre as propriedades mecânicas do sprint.

> Nesse post vamos mostrar uma destas abordagens, criando um perfil de força-velocidade de sprints curtos com o pacote `{shorts}`[^3]. O resultado dessa abordagem vai nos permitir descrever as diferenças individuais dentro do grupo e quantificar os efeitos do treinamento ao longo da temporada.

[^3]: Jovanović, M. (2022). shorts: Short Sprints. R package version 2.0.0.9000. CRAN: [https://CRAN.R-project.org/package=shorts](https://CRAN.R-project.org/package=shorts.), GitHub: <https://github.com/mladenjovanovic/shorts>, DOI: 10.5281/zenodo.3751836

## Nossos dados

Nossos dados são de treze atletas juvenis (15-16 anos) de basquetebol que realizaram um sprint máximo de 20 metros, sendo registrado o tempo a cada 5 metros. A distância da linha de saída até o primeiro par de fotocélulas foi de 0,5 metros. Além disso, nossos dados contém informações sobre altura, massa corporal e posição de jogo dos atletas. Vamos dar uma olhada nas primeiras linhas:


```r
knitr::kable(head(sprints, 5), format = "html", digits = 3)
```

<table>
 <thead>
  <tr>
   <th style="text-align:right;"> ID </th>
   <th style="text-align:left;"> Posição </th>
   <th style="text-align:right;"> Altura </th>
   <th style="text-align:right;"> Massa </th>
   <th style="text-align:right;"> t_5m </th>
   <th style="text-align:right;"> t_10m </th>
   <th style="text-align:right;"> t_15m </th>
   <th style="text-align:right;"> t_20m </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> Armador </td>
   <td style="text-align:right;"> 1.70 </td>
   <td style="text-align:right;"> 79.2 </td>
   <td style="text-align:right;"> 0.950 </td>
   <td style="text-align:right;"> 1.667 </td>
   <td style="text-align:right;"> 2.317 </td>
   <td style="text-align:right;"> 2.892 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> Pivô </td>
   <td style="text-align:right;"> 1.82 </td>
   <td style="text-align:right;"> 85.2 </td>
   <td style="text-align:right;"> 0.942 </td>
   <td style="text-align:right;"> 1.650 </td>
   <td style="text-align:right;"> 2.325 </td>
   <td style="text-align:right;"> 2.942 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> Pivô </td>
   <td style="text-align:right;"> 1.92 </td>
   <td style="text-align:right;"> 86.1 </td>
   <td style="text-align:right;"> 1.067 </td>
   <td style="text-align:right;"> 1.858 </td>
   <td style="text-align:right;"> 2.567 </td>
   <td style="text-align:right;"> 3.242 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> Armador </td>
   <td style="text-align:right;"> 1.73 </td>
   <td style="text-align:right;"> 60.1 </td>
   <td style="text-align:right;"> 0.933 </td>
   <td style="text-align:right;"> 1.625 </td>
   <td style="text-align:right;"> 2.283 </td>
   <td style="text-align:right;"> 2.883 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> Lateral </td>
   <td style="text-align:right;"> 1.88 </td>
   <td style="text-align:right;"> 80.8 </td>
   <td style="text-align:right;"> 0.833 </td>
   <td style="text-align:right;"> 1.533 </td>
   <td style="text-align:right;"> 2.167 </td>
   <td style="text-align:right;"> 2.775 </td>
  </tr>
</tbody>
</table>

Batendo o olho nos dados, percebemos que estão em *wide format* (formato largo). Isso significa que cada variável está em uma coluna separada. As funções do pacote `{shorts}` pedem que os dados de entrada estejam em *long format* (formato longo). [Você pode baixar os dados clicando aqui](/files/sprints.csv).

## Processando os dados

O primeiro passo será passar os dados para formato longo. Para isso, usaremos a função `melt()` do pacote `{reshape2}` ([já usamos essa função antes aqui](/post/resultados-avaliacao-fisica/)). Com essa função, empilhamos os dados de forma que as variáveis de identificação (`id.vars`) se repetem ao longo das colunas empilhadas.


```r
# Carregando o pacote {reshape2}
library(reshape2)

sprints <- melt(data = sprints,
                id.vars = c("ID", "Posição", "Altura", "Massa"),
                variable.name = "Distância",
                value.name = "Tempo")

# Primeiras 5 linhas dos dados
knitr::kable(head(sprints, 5), format = "html", digits = 3)
```

<table>
 <thead>
  <tr>
   <th style="text-align:right;"> ID </th>
   <th style="text-align:left;"> Posição </th>
   <th style="text-align:right;"> Altura </th>
   <th style="text-align:right;"> Massa </th>
   <th style="text-align:left;"> Distância </th>
   <th style="text-align:right;"> Tempo </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:right;"> 1 </td>
   <td style="text-align:left;"> Armador </td>
   <td style="text-align:right;"> 1.70 </td>
   <td style="text-align:right;"> 79.2 </td>
   <td style="text-align:left;"> t_5m </td>
   <td style="text-align:right;"> 0.950 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 2 </td>
   <td style="text-align:left;"> Pivô </td>
   <td style="text-align:right;"> 1.82 </td>
   <td style="text-align:right;"> 85.2 </td>
   <td style="text-align:left;"> t_5m </td>
   <td style="text-align:right;"> 0.942 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:left;"> Pivô </td>
   <td style="text-align:right;"> 1.92 </td>
   <td style="text-align:right;"> 86.1 </td>
   <td style="text-align:left;"> t_5m </td>
   <td style="text-align:right;"> 1.067 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:left;"> Armador </td>
   <td style="text-align:right;"> 1.73 </td>
   <td style="text-align:right;"> 60.1 </td>
   <td style="text-align:left;"> t_5m </td>
   <td style="text-align:right;"> 0.933 </td>
  </tr>
  <tr>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:left;"> Lateral </td>
   <td style="text-align:right;"> 1.88 </td>
   <td style="text-align:right;"> 80.8 </td>
   <td style="text-align:left;"> t_5m </td>
   <td style="text-align:right;"> 0.833 </td>
  </tr>
</tbody>
</table>

Quase tudo pronto. Uma outra exigência das funções do pacote `{shorts}` é que a variável `Distância` seja númerica, indicando a distância correspondente ao tempo. Para transformar o valor da variável ao longo de todo o *data frame*, usaremos a função `ifelse()`. Nessa função precisamos indicar uma expressão lógica e o que a função deve fazer se o resultado dessa expressão for `VERDADEIRO` ou `FALSO`. Podemos aninhar esse tipo de função para alterarmos diferentes valores ao mesmo tempo. Por exemplo:


```r
# Transformando os dados da variável `Distância`
sprints$Distância <- ifelse(sprints$Distância == "t_5m", 5,
                     ifelse(sprints$Distância == "t_10m", 10,
                     ifelse(sprints$Distância == "t_15m", 15, 20)))
```

## Criando o perfil F-V de um atleta

### Adiantando o problema

Para garantir um modelo que faça estimativas acuradas, é necessário que o momento de produção de força inicial seja sincronizado com o momento de início do sprint. O que acontece na prática é um pouco diferente: geralmente os atletas são posicionados um pouco antes do primeiro par de fotocélulas (entre 0,5-1 m). Isso é feito para evitar que as fotocélulas sejam acionadas prematuramente pela elevação de joelhos ou balanço dos braços.

Para "sincronizar" os tempos e solucionar esse problema para o nosso modelo, podemos usar um fator de correção. Este pode ser fixo (0,3 - 0,5 s) ou estimado para cada atleta. Ambas abordagens levam a estimativas menos enviesadas (para detalhes, veja Vescovi & Jovanovic, 2021)[^4]. Correções pequenas demais podem superestimar os resultados enquanto correções muito grandes podem ter o efeito oposto.

[^4]: Vescovi, J.D. Jovanović, M. (2021) Sprint Mechanical Characteristics of Female Soccer Players: A Retrospective Pilot Study to Examine a Novel Approach for Correction of Timing Gate Starts. *Front. Sports Act. Living* 3:629694. doi: 10.3389/fspor.2021.629694

O pacote `{shorts}` oferece ambas as soluções.

### Modelando o desempenho de sprint

Para começar, vamos usar a função `subset()` para ficar com os dados de apenas um atleta.


```r
# Filtrando os dados do atleta de ID 5
atleta <- subset(sprints, ID == 5)
atleta
```

```
   ID Posição Altura Massa Distância     Tempo
5   5 Lateral   1.88  80.8         5 0.8333333
18  5 Lateral   1.88  80.8        10 1.5333333
31  5 Lateral   1.88  80.8        15 2.1666667
44  5 Lateral   1.88  80.8        20 2.7750000
```

Já que usamos fotocélulas (*timing gates*) para registrar o tempo dos sprints, vamos usar a função `model_timing_gates()` para estimar os valores de MSS (*maximal sprint speed*), TAU (*relative acceleration*) e MAC (*maximal acceleration*). Para esse modelo, usaremos um fator de correção fixo de 0,3 segundos, seguindo recomendação da literatura (*veja referência [4]*).


```r
# Carregando o pacote {shorts}
library(shorts)

# Criando o modelo com fator de correção fixo (+ 0.3 s)
modelo <- model_timing_gates(distance = atleta$Distância,
                                time = atleta$Tempo + 0.3)

# Visualizando os parâmetros estimados
print(modelo)
```

```
Estimated model parameters
--------------------------
       MSS        TAU        MAC       PMAX 
 8.1699865  0.6379204 12.8072189 26.1587013 

Model fit estimators
--------------------
         RSE    R_squared       minErr       maxErr    maxAbsErr         RMSE 
 0.011018315  0.999888601 -0.010382357  0.007897303  0.010382357  0.007791125 
         MAE         MAPE 
 0.007581409  0.447156664 
```

```r
# Gráfico simples dos parâmetros estimados ao longo da distância
plot(modelo) + theme_bw()
```

<img src="/post/2022-07-26-perfil-de-forca-velocidade-do-sprint/index.pt-br_files/figure-html/unnamed-chunk-6-1.png" width="672" />

O valor de potência máxima relativa `(PMAX)` é estimado usando `(MSS * MAC) / 4`, desconsiderando a resistência do ar.

### Funções de utilidade

Uma vez que temos os valores de `MSS` e `MAC` estimados, podemos usar a família de funções `predict_()` para predizer relações de tempo-distância, aceleração-distância, velocidade-distância etc. Por exemplo:


```r
# Predizendo aceleração em diferentes distâncias
predict_acceleration_at_distance(distance = atleta$Distância,
                         MSS = modelo$parameters$MSS,
                         MAC = modelo$parameters$MAC)
```

```
[1] 2.1321429 0.7323235 0.2706463 0.1023410
```

Podemos também utilizar a família de funções `find_()` para determinar a distância ou o tempo em que se é atingida 90% da MSS, ou em que ocorre 80% da potência pico. Por exemplo:


```r
# Distância onde se é atingida 90% da velocidade máxima de sprint
find_velocity_critical_distance(MSS = modelo$parameters$MSS,
                                MAC = modelo$parameters$MAC,
                                percent = 0.9)
```

```
[1] 7.309982
```

```r
# Faixa de distância onde ocorre 80% da potência pico
find_power_critical_distance(MSS =modelo$parameters$MSS,
                             MAC =modelo$parameters$MAC, 
                             percent = .8,
                             # Parâmetros adicionais:
                             bodymass = unique(atleta$Massa),
                             bodyheight = unique(atleta$Altura),
                             barometric_pressure = 1015,
                             air_temperature = 30,
                             wind_velocity = 0.5
                             )
```

```
$lower
[1] 0.252922

$upper
[1] 3.12754
```

As funções de utilidade `predict_()` ou `find_()` já serão uma baita mão na roda para planejar os treinamentos de sprint com mais precisão para cada atleta.

### Perfil de força-velocidade

Para criar o perfil de força-velocidade de apenas um atleta, usaremos a função `make_FV_profile()`, que se baseia na abordagem de Samonizo et al. (2016)[^5]. Essa função estima outros parâmetros cinéticos usando os valores de `MSS`, `MAC`, `massa corporal` e algumas informações adicionais. A estrutura da função é similar a de criação do modelo inicial:

[^5]: Samozino P, Rabita G, Dorel S, Slawinski J, Peyrot N, Saez de Villarreal E, Morin J-B. 2016. A simple method for measuring power, force, velocity properties, and mechanical effectiveness in sprint running: Simple method to compute sprint mechanics. Scandinavian Journal of Medicine & Science in Sports 26:648--658. DOI: 10.1111/sms.12490.


```r
# Criando o perfil F-V
perfil.fv <- make_FV_profile(MSS = modelo$parameters$MSS,
                MAC = modelo$parameters$MAC,
                bodymass = unique(atleta$Massa),
                
                bodyheight = unique(atleta$Altura),
                             barometric_pressure = 1015,
                             air_temperature = 30,
                             wind_velocity = 0)

# Visualizando os parâmetros estimados
print(perfil.fv)
```

```
Estimated Force-Velocity Profile
--------------------------------
     bodymass            F0        F0_rel            V0          Pmax 
  80.80000000 1026.96007772   12.70990195    8.37498953 2150.19497458 
Pmax_relative      FV_slope  RFmax_cutoff         RFmax           Drf 
  26.61132394   -1.51760213    0.30000000    0.63392704   -0.13036549 
       RSE_FV       RSE_Drf 
   1.32192250    0.01093529 
```

### Visualização

Vamos utilizar o pacote `{ggplot2}` para plotar uma reta que representa a `FV_slope` - a relação entre `F0_rel` (força máxima teórica) `V0` (velocidade máxima téorica).


```r
library(ggplot2)

# Gráfico do perfil F-V do atleta #5
ggplot() +
  aes() +
  geom_segment(aes(x = 0 , 
                   y = perfil.fv$F0_rel, 
                   xend= perfil.fv$V0, 
                   yend = 0 ), size = 1) +
  geom_text(aes(x = .5, y = 14, hjust = 0,
            label = paste0("Inclinação F-V = ", 
                         round(perfil.fv$FV_slope, 3)))) +
  scale_x_continuous(expand = c(0,0), limits = c(0,10.5))+
  scale_y_continuous(expand = c(0,0), limits = c(0,15))+
  xlab("V0") +
  ylab("F0_rel") +
  theme_bw()
```

<img src="/post/2022-07-26-perfil-de-forca-velocidade-do-sprint/index.pt-br_files/figure-html/unnamed-chunk-10-1.png" width="75%" style="display: block; margin: auto;" />

Alterações na relação F-V podem ser monitoradas para avaliar o efeito do treinamento ao longo da temporada - com atenção às características mais importantes para cada atleta/modalidade. Além disso, podemos dentro desse mesmo gráfico plotar o perfil de outros atletas da equipe para fins de comparação. Vamos repetir os passos anteriores com outro atleta e adicionar novas informações ao gráfico:



<img src="/post/2022-07-26-perfil-de-forca-velocidade-do-sprint/index.pt-br_files/figure-html/unnamed-chunk-12-1.png" width="75%" style="display: block; margin: auto;" />

## Criando o perfil F-V do grupo inteiro

Para esta seção, as funções que criam o modelo e o perfil de força-velocidade são as mesmas da seção anterior. A diferença aqui é que usaremos o controlador de fluxo `for loop` para processar os dados de todos os atletas de uma única vez, resultando em um *data frame* com os dados necessários para avaliar o perfil de cada um.

O primeiro passo será criar uma lista contendo o modelo que estima os valores de `MSS` e `MAC` de todos os atletas.


```r
# Criando uma lista com os resultados de todos os atletas

# Criando uma lista vazia  
modelos <- list()
n = 1

# For loop que alimentará a lista criada acima

for (i in unique(sprints$ID)) {
  
  x <- sprints %>% filter(ID == i)
  
  modelos[[n]] <- model_timing_gates(x[,"Distância"], x[,"Tempo"] + 0.3)
  
  modelos[[n]][["data"]][["height"]] <- x[,"Altura"]
  modelos[[n]][["data"]][["bodymass"]] <- x[,"Massa"]
  modelos[[n]][["data"]][["ID"]] <- x[,"ID"]
  modelos[[n]][["data"]][["posicao"]] <- x[,"Posição"]
  
  n = n + 1
  
}
```

O segundo passo é semelhante ao anterior. Agora que temos uma lista com os resultados de cada atleta. Basta aplicarmos um outro `for loop` que pegará o modelo de cada atleta e criará uma nova lista contendo o perfil F-V de todo o grupo.


```r
# Criando uma lista com o perfil F-V de todos os atletas

# Criando uma lista vazia
perfis.fv <- list()

# For loop que alimentará a lista criada acima
for (i in 1:length(modelos)) {

perfis.fv[[i]] <- make_FV_profile(MSS = modelos[[i]][["parameters"]][["MSS"]],
                                  MAC = modelos[[i]][["parameters"]][["MAC"]],
                                  bodymass = unique(modelos[[i]][["data"]][["bodymass"]]),
                                  bodyheight = unique(modelos[[i]][["data"]][["height"]]))

# Adicionando informações sobre o ID e posição de jogo aos resultados
perfis.fv[[i]][["ID"]] <- unique(modelos[[i]][["data"]][["ID"]])
perfis.fv[[i]][["posicao"]] <- unique(modelos[[i]][["data"]][["posicao"]])

}
```

O último passo será criar um *data frame* apenas com as informações que estamos interessados em avaliar e monitorar. Novamente, usaremos um `for loop` para extrair as informações de cada perfil e alimentar um *data frame* com essas informações.


```r
# Criando data frame com os dados de todos os atletas

# Criando data frame vazio
resultados.fv <- data.frame()

# For loop que alimentará o data frame criado acima
for (i in 1:length(perfis.fv)) {

  # Aqui definimos as variaveis que queremos extrair do perfil F-V
  df <- data.frame(ID = as.character(perfis.fv[[i]][["ID"]]),
                   `Posição` = perfis.fv[[i]][["posicao"]],
                   F0 = perfis.fv[[i]][["F0_rel"]],
                   V0 = perfis.fv[[i]][["V0"]],
                   PMAX = perfis.fv[[i]][["Pmax_relative"]],
                   `Inclinação F-V` = perfis.fv[[i]][["FV_slope"]],
                   RFmax = perfis.fv[[i]][["RFmax"]],
                   DRF = perfis.fv[[i]][["Drf"]])
  
  resultados.fv <- rbind(df, resultados.fv)

}

# Dando uma olhada nos dados (5 primeiras linhas)
knitr::kable(head(resultados.fv, 5), format = "html", digits = 3)
```

<table>
 <thead>
  <tr>
   <th style="text-align:left;"> ID </th>
   <th style="text-align:left;"> Posição </th>
   <th style="text-align:right;"> F0 </th>
   <th style="text-align:right;"> V0 </th>
   <th style="text-align:right;"> PMAX </th>
   <th style="text-align:right;"> Inclinação.F.V </th>
   <th style="text-align:right;"> RFmax </th>
   <th style="text-align:right;"> DRF </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 13 </td>
   <td style="text-align:left;"> Lateral </td>
   <td style="text-align:right;"> 9.816 </td>
   <td style="text-align:right;"> 8.075 </td>
   <td style="text-align:right;"> 19.815 </td>
   <td style="text-align:right;"> -1.216 </td>
   <td style="text-align:right;"> 0.570 </td>
   <td style="text-align:right;"> -0.109 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 12 </td>
   <td style="text-align:left;"> Armador </td>
   <td style="text-align:right;"> 11.377 </td>
   <td style="text-align:right;"> 7.839 </td>
   <td style="text-align:right;"> 22.296 </td>
   <td style="text-align:right;"> -1.451 </td>
   <td style="text-align:right;"> 0.599 </td>
   <td style="text-align:right;"> -0.128 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 11 </td>
   <td style="text-align:left;"> Lateral </td>
   <td style="text-align:right;"> 10.101 </td>
   <td style="text-align:right;"> 8.366 </td>
   <td style="text-align:right;"> 21.126 </td>
   <td style="text-align:right;"> -1.207 </td>
   <td style="text-align:right;"> 0.582 </td>
   <td style="text-align:right;"> -0.107 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 10 </td>
   <td style="text-align:left;"> Lateral </td>
   <td style="text-align:right;"> 9.898 </td>
   <td style="text-align:right;"> 7.535 </td>
   <td style="text-align:right;"> 18.647 </td>
   <td style="text-align:right;"> -1.314 </td>
   <td style="text-align:right;"> 0.562 </td>
   <td style="text-align:right;"> -0.118 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 9 </td>
   <td style="text-align:left;"> Lateral </td>
   <td style="text-align:right;"> 8.904 </td>
   <td style="text-align:right;"> 7.882 </td>
   <td style="text-align:right;"> 17.545 </td>
   <td style="text-align:right;"> -1.130 </td>
   <td style="text-align:right;"> 0.543 </td>
   <td style="text-align:right;"> -0.102 </td>
  </tr>
</tbody>
</table>

### Visualizando perfis F-V do grupo

Agora que temos um *data frame* com os dados necessários, fica mais simples acessarmos os dados para criar maneiras de visualização. Vamos plotar o perfil de todos os atletas em um único gráfico e discriminá-los pela posição de jogo em outro.


```r
# Pacote para arranjar os gráficos
library(gridExtra)


# Perfil F-V de todo o grupo 
geral <- ggplot(resultados.fv)+
  aes(alpha = ID) +
  geom_segment(aes(x = 0 , y = F0, xend= V0, yend = 0 ), size = 1) +
  xlab("V0") +
  scale_x_continuous(expand = c(0,0), limits = c(0,10.5)) +
  scale_y_continuous(expand = c(0,0), limits = c(0,15)) +
  theme_classic() +
  theme(legend.position = "none")

# Perfil F-V por posição de jogo 
por.posicao <- ggplot(resultados.fv)+
  aes(color = Posição) +
  geom_segment(aes(x = 0 , y = F0, xend= V0, yend = 0 ), size = 1) +
  xlab("V0") +
  scale_x_continuous(expand = c(0,0), limits = c(0,10.5)) +
  scale_y_continuous(expand = c(0,0), limits = c(0,15)) +
  theme_classic() +
  theme(legend.position = c(0.9,0.8))

grid.arrange(geral, por.posicao, ncol = 2)
```

<img src="/post/2022-07-26-perfil-de-forca-velocidade-do-sprint/index.pt-br_files/figure-html/unnamed-chunk-16-1.png" width="672" />

Nesse tipo de gráfico, podemos ter uma ideia da variação nas capacidades de produzir força em altas velocidades (`V0`) e de produzir níveis altos de força horizontal (`F0`) dentro do nosso grupo. Para ter a ideia de apenas um atleta em relação ao grupo, podemos criar uma linha que destaca o perfil do atleta selecionado. Por exemplo:


```r
ggplot(resultados.fv)+
  aes() +
  geom_segment(aes(x = 0 , y = F0, xend= V0, yend = 0), 
               size = 1, 
               alpha = .2) +
    geom_segment(data = subset(resultados.fv, ID == "1"),
                 aes(x = 0 , y = F0, xend= V0, yend = 0), 
                 size = 2,
                 color = "red") +
  xlab("V0") +
  scale_x_continuous(expand = c(0,0), limits = c(0,10.2)) +
  scale_y_continuous(expand = c(0,0), limits = c(0,15)) +
  theme_classic() +
  theme(legend.position = "none")
```

<img src="/post/2022-07-26-perfil-de-forca-velocidade-do-sprint/index.pt-br_files/figure-html/unnamed-chunk-17-1.png" width="75%" />

## Implicações no treinamento

Ter o perfil de cada atleta pode ajudar a especificar se o aumento na `PMAX` deve ser causado por aumento na força horizontal produzida em baixa velocidade (`F0`; capacidade de força) ou pelo aumento na força horizontal produzida em alta velocidade (`V0`; capacidade de velocidade). Ou ainda, pelo treinamento em potência ótima (`PMAX`).

Além de utilizar o perfil de cada atleta para especificar o treinamento, as demandas de cada posição e modalidade podem ser consideradas para determinar o conteúdo de treinamento e a distância na qual o sprint deve ser melhorado. Alguns estudos têm mostrado que, quanto menor a distância do sprint curto (e.g. 5-10 m), maior a relação entre o desempenho (em segundos) e a produção de força horizontal (`F0`).

Estratégias como o treinamento de sprints resistidos ou assistidos podem ser efetivas para melhorar a `PMAX`, embora sejam necessárias mais evidências de como manipular esse tipo de treinamento para aumentar especificamente um componente ou o outro.[^6] Outras recomendações envolvem mirar em cada componente olhando para a curva de força-velocidade[^7], independente da direção da força aplicada durante o exercício.

[^6]: Lahti, J., Jiménez-Reyes, P., Cross, M. R., Samozino, P., Chassaing, P., Simond-Cote, B., Ahtiainen, J. P., et al. (2020). Individual Sprint Force-Velocity Profile Adaptations to In-Season Assisted and Resisted Velocity-Based Training in Professional Rugby. *Sports*, *8*(5), 74. <http://dx.doi.org/10.3390/sports8050074>

[^7]: Hicks, D. Schuster, J. G., Samozino, P., Morin, J. B. (2020) Improving Mechanical Effectiveness During Sprint Acceleration: Practical Recommendations and Guidelines. *Strength and Conditioning Journal*, *42*(5), 45-62 doi: 10.1519/SSC.0000000000000519

A avaliação e o treinamento de sprints tem melhorado cada vez mais há muito tempo, por isso vale o lembrete: embora bem interessante, **o perfil de força-velocidade é apenas uma das abordagens para dissecar as características mecânicas da fase de aceleração de sprint e identificar desdobramentos para o treinamento**.

Não tenha só uma ferramenta na caixa. Bons estudos 🤓.
