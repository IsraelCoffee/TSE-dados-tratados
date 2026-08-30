# ============================================================
# 4. RESUMO POR CATEGORIA (destaque)
# Pra cada deputado, identifica a categoria de escolaridade e
# de faixa etária mais sobrerrepresentada (maior delta vs. DF),
# e se o eleitorado dele pende mais pra mulheres ou homens
# ============================================================

# nomes das colunas de delta de cada dimensão, definidos ANTES do mutate
instrucao_cols <- names(perfil_indexado) %>% str_subset("^delta_pct_instrucao")
idade_cols <- names(perfil_indexado) %>%
  str_subset("^delta_pct_idade") %>%
  str_subset("90_a_94|95_a_99|100_anos", negate = TRUE)  # remove faixas com pouquíssimos eleitores

# pra cada linha (deputado), acha a coluna com maior delta
escolaridade_destaque <- apply(perfil_indexado[instrucao_cols], 1, function(x) {
  str_remove(instrucao_cols[which.max(x)], "delta_pct_instrucao_")
})

idade_destaque <- apply(perfil_indexado[idade_cols], 1, function(x) {
  str_remove(idade_cols[which.max(x)], "delta_pct_idade_")
})

# monta o resumo final
perfil_resumo <- perfil_indexado %>%
  mutate(
    escolaridade_destaque = escolaridade_destaque,
    idade_destaque = idade_destaque,
    genero_destaque = if_else(delta_pct_genero_feminino > delta_pct_genero_masculino, "mais mulheres", "mais homens")
  ) %>%
  select(nome_candidato, sigla_partido, escolaridade_destaque, idade_destaque, genero_destaque)

perfil_resumo
