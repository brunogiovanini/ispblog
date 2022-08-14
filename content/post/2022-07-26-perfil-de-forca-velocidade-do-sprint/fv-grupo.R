library(tidyverse)
library(reshape2)
library(shorts)
library(ggrepel)


# Processando os dados 

sprints <- sprints20m

sprints[,4:6] <- sprints[,4:6]/100

sprints <- na.omit(sprints)

sprints$`5` <- abs(sprints$q_0 - sprints$q_5)/120
sprints$`10` <- abs(sprints$q_0 - sprints$q_10)/120
sprints$`15` <- abs(sprints$q_0 - sprints$q_15)/120
sprints$`20` <- abs(sprints$q_0 - sprints$q_20)/120

sprints <- sprints %>% 
  group_by(Nome) %>% 
  top_n(1, -`20`) %>% 
  ungroup() %>%
  select(Nome, Posição, Altura, Massa, `5`, `10`, `15`, `20`)

sprints <- melt(id.vars = names(.[1:4]), value.name = "Tempo", variable.name = "Distancia")

sprints$Distancia <- as.numeric(levels(sprints$Distancia))[sprints$Distancia]


# Modelagem dos dados

## Criando uma lista com os resultados de todos os atletas
modelos.tc <- list()
n = 1

for (i in unique(sprints$ID)) {
  
  x <- sprints %>% filter(Nome == i)
  
  modelos.tc[[n]] <- model_timing_gates_TC(x[,"Distancia"], x[,"Tempo"])
  
  modelos.tc[[n]][["data"]][["height"]] <- x[,"Altura"]
  modelos.tc[[n]][["data"]][["bodymass"]] <- x[,"Massa"]
  modelos.tc[[n]][["data"]][["nome"]] <- x[,"Nome"]
  modelos.tc[[n]][["data"]][["posicao"]] <- x[,"Posição"]
  
  n = n + 1
  
}

## Criando o perfil F-V de todos os atletas

perfis.fv <- list()

for (i in 1:length(modelos.tc)) {

perfis.fv[[i]] <- make_FV_profile(MSS = modelos.tc[[i]][["parameters"]][["MSS"]],
                                  MAC = modelos.tc[[i]][["parameters"]][["MAC"]],
                                  bodymass = unique(modelos.tc[[i]][["data"]][["bodymass"]]),
                                  bodyheight = unique(modelos.tc[[i]][["data"]][["height"]]), 
                                  frequency = 120)

perfis.fv[[i]][["nome"]] <- unique(modelos.tc[[i]][["data"]][["nome"]])
perfis.fv[[i]][["posicao"]] <- unique(modelos.tc[[i]][["data"]][["posicao"]])


}

## Criando tabela com os dados de todos os atletas

resultados.fv <- data.frame()


for (i in 1:length(perfis.fv)) {
  
  df <- data.frame(Nome = perfis.fv[[i]][["nome"]],
                   `Posição` = perfis.fv[[i]][["posicao"]],
                   F0 = perfis.fv[[i]][["F0_rel"]],
                   V0 = perfis.fv[[i]][["V0"]])
  
  resultados.fv <- rbind(df, resultados.fv)

}


resultados.fv <- merge(resultados.fv, sprints %>% filter(Distancia == 20) %>% select(Nome, Tempo), by = "Nome")



ggplot(resultados.fv)+
  aes(color = Posição) +
  geom_segment(aes(x = 0 , y = F0, xend= V0, yend = 0 ), size = 1, color = "black", alpha = .1)+
  geom_segment(data = subset(resultados.fv, ID == 9), aes(x = 0 , y = F0, xend= V0, yend = 0 ), size = 1, color = "purple") +
  scale_x_continuous(expand = c(0,0))+
  scale_y_continuous(expand = c(0,0))+
  xlab("V0") +
  theme_bw()
  ggsave("plot2.png", scale = 1)


ggplot(resultados.fv)+
  aes(V0, F0, fill = Posição, size = PMAX) +
  #geom_segment(aes(x = 0 , y = F0, xend= V0, yend = 0 ), size = 1)+
  geom_point(shape = 21, alpha = .6) +
  #geom_text_repel(aes(label = ID, color = Posição), box.padding = .5, size = 3) +
  scale_size_continuous(range = c(2,20), limits = c(14, 35)) +
  #scale_x_continuous(expand = c(0,0))+
  #scale_y_continuous(expand = c(0,0))+
  xlab("V0") +
  theme_bw()
  ggsave("plot3.png", scale = 1)

  
  
  
  sprints20m <- sprints20m %>% rename(t_5m = `5`, t_10m = `10`, t_15m = `15`, t_20m = `20`)

  write.csv(x = sprints20m, file = "sprints.csv", fileEncoding = "UTF-8")  
  