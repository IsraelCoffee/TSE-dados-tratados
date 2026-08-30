
votacao_secao <- votacao_secao %>%
  mutate(votos = as.numeric(votos))

# Criando as tabelas Idades, Genêro e Escolaridade

perfil_idade <- perfil_secao %>%
  group_by(zona, secao, grupo_idade) %>%
  summarise(eleitores = sum(eleitores), .groups = "drop") %>%
  group_by(zona, secao) %>%
  mutate(pct = eleitores / sum(eleitores)) %>%
  ungroup() %>%
  select(zona, secao, grupo_idade, pct) %>%
  pivot_wider(names_from = grupo_idade, values_from = pct, names_prefix = "pct_idade_", values_fill = 0)

perfil_genero <- perfil_secao %>%
  group_by(zona, secao, genero) %>%
  summarise(eleitores = sum(eleitores), .groups = "drop") %>%
  group_by(zona, secao) %>%
  mutate(pct = eleitores / sum(eleitores)) %>%
  ungroup() %>%
  select(zona, secao, genero, pct) %>%
  pivot_wider(names_from = genero, values_from = pct, names_prefix = "pct_genero_", values_fill = 0)

perfil_instrucao <- perfil_secao %>%
  group_by(zona, secao, instrucao) %>%
  summarise(eleitores = sum(eleitores), .groups = "drop") %>%
  group_by(zona, secao) %>%
  mutate(pct = eleitores / sum(eleitores)) %>%
  ungroup() %>%
  select(zona, secao, instrucao, pct) %>%
  pivot_wider(names_from = instrucao, values_from = pct, names_prefix = "pct_instrucao_", values_fill = 0)

# Junta as três tabelas Idades, Genêro e Escolaridade

perfil_wide <- perfil_idade %>%
  left_join(perfil_genero, by = c("zona", "secao")) %>%
  left_join(perfil_instrucao, by = c("zona", "secao")) %>%
  clean_names() %>%
  select(-matches("invalido"), -matches("nao_informado"))

# Cruzamento com as votações
# Tabela final para análise

votos_com_perfil <- votacao_secao %>%
  filter(cargo == "deputado distrital") %>%
  inner_join(perfil_wide, by = c("zona", "secao"))
