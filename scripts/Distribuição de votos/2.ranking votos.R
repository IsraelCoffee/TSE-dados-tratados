# ============================================================
# 2__ranking_votos.R
# Rankings de votação (eleitos e não eleitos) e detalhes de
# voto branco/nulo/legenda, a partir das tabelas já importadas
# no script 1 (resultados_zona, detalhes_zona, nomes_eleitos,
# nomes_nao_eleitos)
# ============================================================

### TABELAS ====================================================================

# Filtra só os 24 deputados distritais eleitos (por quociente partidário ou média)
eleitos_zona <- resultados_zona |>
  filter(resultado %in% c("eleito por qp", "eleito por media"))

# Adiciona o nome dos Dep. Eleitos
eleitos_zona <- eleitos_zona |>
  left_join(nomes_eleitos %>% select(numero_candidato, nome_candidato), by = "numero_candidato")

# tab - Resultado das eleições
# Ranking dos 24 eleitos por total de votos (soma de todas as zonas), do mais ao menos votado
resultado_df <- eleitos_zona |>
  group_by(numero_candidato, nome_candidato, sigla_partido) |>
  summarise(total_votos = sum(votos), .groups = "drop") |>
  arrange(desc(total_votos)) |>
  mutate(posicao = row_number()) |>
  relocate(posicao)

# tab - Resultado do voto nos não eleitos
# Mesmo ranking, mas pra quem não foi eleito ("nao eleito") ou ficou como suplente
resultado.nao.eleitos <- resultados_zona |>
  filter(resultado %in% c("nao eleito", "suplente")) |>
  left_join(nomes_nao_eleitos %>% select(numero_candidato, nome_candidato), by = "numero_candidato") |>
  group_by(numero_candidato, nome_candidato, sigla_partido) |>
  summarise(total_votos = sum(votos), .groups = "drop") |>
  arrange(desc(total_votos)) |>
  mutate(posicao = row_number()) |>
  relocate(posicao)

# Análise - voto nulo e branco
# Totais gerais do DF: comparecimento, abstenção, votos válidos (nominal + legenda),
# brancos e nulos — soma de todas as zonas eleitorais
totais_df <- detalhes_zona %>%
  summarise(
    total_aptos = sum(aptos),
    total_comparecimento = sum(comparecimento),
    total_abstencoes = sum(abstencoes),
    total_validos = sum(votos_validos),
    total_brancos = sum(votos_brancos),
    total_nulos = sum(votos_nulos),
    total_nominais = sum(votos_nominais),
    total_legenda = sum(votos_legenda)
  )

### SALVANDO AS TABELAS ========================================================

# Remova os jogos da velha para coloquem seu caminho, subtitua \ por //

# write_excel_csv(resultado_df, "<SEU CAMINHO>//ranking_eleitos.csv")
# write_excel_csv(resultado.nao.eleitos, "<SEU CAMINHO>//ranking_nao_eleitos.csv")
# write_excel_csv(top20_nao_eleitos, "<SEU CAMINHO>//top20_nao_eleitos.csv")
# write_excel_csv(totais_df, "<SEU CAMINHO>//nulos_e_brancos.csv")

### GRÁFICOS ===================================================================

# Ranking de votos nos eleitos ---

resultado_df <- resultado_df |>
  mutate(
    nome_sem_sufixo = str_remove(nome_candidato, "\\s+(Junior|Júnior|Filho|Neto|Neta)$"),
    nome_abrev = paste(word(nome_sem_sufixo, 1), word(nome_sem_sufixo, -1))
  ) |>
  mutate(
    nome_abrev = case_when(
      nome_candidato == "Fábio Felix Silveira" ~ "Fábio Félix",
      TRUE ~ nome_abrev
    )
  )

resultado_df |>
  ggplot(aes(x = total_votos, y = reorder(nome_abrev, total_votos))) +
  geom_col(width = 0.6, fill = azul_medio) +
  geom_text(
    aes(label = label_number(big.mark = ".", decimal.mark = ",")(total_votos)),
    hjust = -0.15, color = cor_texto, family = "Inter", fontface = "bold", size = 3.5
  ) +
  scale_x_continuous(
    labels = NULL,
    expand = expansion(mult = c(0, 0.15))
  ) +
  labs(
    title = "Ranking dos deputados distritais eleitos — DF 2022",
    x = NULL,
    y = NULL,
    caption = "Fonte: TSE / Base dos Dados"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    text = element_text(family = "Inter", color = cor_texto),
    plot.title = element_text(family = "Poppins", face = "bold", size = 16, color = azul_escuro),
    plot.caption = element_text(color = cor_texto_suave, size = 9),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.ticks = element_blank(),
    axis.text.y = element_text(color = cor_texto, size = 10),
    plot.background = element_rect(fill = cinza_fundo, color = NA),
    panel.background = element_rect(fill = cinza_fundo, color = NA)
  )

# Não eleitos TOP 20 ---

menor_eleito <- min(resultado_df$total_votos)

top20_nao_eleitos <- resultado.nao.eleitos |>
  slice_head(n = 20) |>
  mutate(
    nome_sem_sufixo = str_remove(nome_candidato, "\\s+(Junior|Júnior|Filho|Neto|Neta)$"),
    nome_abrev = paste(word(nome_sem_sufixo, 1), word(nome_sem_sufixo, -1))
  ) |>
  mutate(supera_algum_eleito = total_votos > menor_eleito)

top20_nao_eleitos |>
  select(nome_candidato, nome_abrev, total_votos, supera_algum_eleito)


top20_nao_eleitos |>
  ggplot(aes(x = total_votos, y = reorder(nome_abrev, total_votos), fill = supera_algum_eleito)) +
  geom_col(width = 0.6) +
  geom_text(
    aes(label = label_number(big.mark = ".", decimal.mark = ",")(total_votos)),
    hjust = -0.15, color = cor_texto, family = "Inter", fontface = "bold", size = 3.5
  ) +
  scale_fill_manual(values = c("TRUE" = laranja, "FALSE" = azul_medio), guide = "none") +
  scale_x_continuous(labels = NULL, expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Os 20 mais votados que não se elegeram — DF 2022",
    x = NULL, y = NULL,
    caption = "Fonte: TSE / Base dos Dados"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    text = element_text(family = "Inter", color = cor_texto),
    plot.title = element_text(family = "Poppins", face = "bold", size = 16, color = azul_escuro),
    plot.caption = element_text(color = cor_texto_suave, size = 9),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.ticks = element_blank(),
    axis.text.y = element_text(color = cor_texto, size = 10),
    plot.background = element_rect(fill = cinza_fundo, color = NA),
    panel.background = element_rect(fill = cinza_fundo, color = NA)
  )




