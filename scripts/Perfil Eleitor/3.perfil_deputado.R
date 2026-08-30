# ============================================================
# 3. PERFIL POR DEPUTADO
# Agrega o perfil demográfico das seções, ponderado pelos votos
# de cada deputado eleito, e compara com a média do DF
# ============================================================

# Perfil médio de cada deputado, ponderado pelos votos que ele
# recebeu em cada seção (seções onde ele teve mais voto pesam mais)
perfil_por_deputado <- votos_com_perfil %>%
  filter(numero_candidato %in% eleitos$numero_candidato) %>%   # só os 24 eleitos
  group_by(numero_candidato) %>%
  summarise(
    across(starts_with("pct_"), ~ weighted.mean(.x, w = votos, na.rm = TRUE)),  # média ponderada de cada variável demográfica
    total_votos = sum(votos),
    .groups = "drop"
  ) %>%
  left_join(eleitos %>% select(numero_candidato, nome_candidato, sigla_partido), by = "numero_candidato")  # traz nome e partido de volta


# Perfil médio do DF inteiro (referência de comparação)
# Cada seção entra uma vez só (distinct), sem peso de voto,
# pra representar a composição do eleitorado do DF como um todo
media_df <- votos_com_perfil %>%
  filter(cargo == "deputado distrital") %>%
  distinct(zona, secao, .keep_all = TRUE) %>%
  summarise(across(starts_with("pct_"), ~ mean(.x, na.rm = TRUE)))


# Delta: quanto o perfil de cada deputado se desvia da média do DF
# positivo = grupo sobrerrepresentado no eleitorado dele
# negativo = grupo sub-representado
perfil_indexado <- perfil_por_deputado %>%
  mutate(across(
    starts_with("pct_"),
    ~ .x - media_df[[cur_column()]],
    .names = "delta_{.col}"
  ))
