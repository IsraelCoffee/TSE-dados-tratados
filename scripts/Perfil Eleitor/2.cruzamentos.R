# ============================================================
# 2. CRUZAMENTO DE TABELAS
# Transforma o perfil do eleitorado (formato longo, uma linha
# por seção x categoria) em formato largo (uma linha por seção),
# e junta com a votação por candidato e seção
# ============================================================

# Corrige o tipo de "votos" — vem como int64 do BigQuery, e isso
# quebra silenciosamente funções como weighted.mean() mais na frente
votacao_secao <- votacao_secao %>%
  mutate(votos = as.numeric(votos))

# Criando as tabelas Idades, Gênero e Escolaridade
# Cada uma: soma eleitores por categoria dentro da seção, calcula
# a % que aquela categoria representa na seção, e pivota pra
# formato largo (uma coluna por categoria). values_fill = 0 garante
# que seção sem eleitor numa categoria vire 0, não NA
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

# Junta as três tabelas (Idade, Gênero e Escolaridade) numa só,
# uma linha por seção, com nomes de coluna limpos (sem espaço/acento)
# e removendo categorias de "ruído de cadastro" (inválido / não informado)
perfil_wide <- perfil_idade %>%
  left_join(perfil_genero, by = c("zona", "secao")) %>%
  left_join(perfil_instrucao, by = c("zona", "secao")) %>%
  clean_names() %>%
  select(-matches("invalido"), -matches("nao_informado"))

# Cruzamento com as votações
# Junta a votação de cada candidato por seção com o perfil
# demográfico daquela seção — essa é a tabela final de análise
# (uma linha por candidato x seção, já com votos + perfil lado a lado)
votos_com_perfil <- votacao_secao %>%
  filter(cargo == "deputado distrital") %>%
  inner_join(perfil_wide, by = c("zona", "secao"))
