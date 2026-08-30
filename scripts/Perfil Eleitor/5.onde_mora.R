# ============================================================
# 5. MORA ONDE (RA / área)
# Mapeia zona eleitoral (TSE) para a área/RA correspondente,
# e identifica de onde vem a maior concentração de votos
# de cada deputado
# ============================================================

zona_para_area <- tibble::tribble(
  ~zona, ~area,
  "1",  "Brasília - Asa Sul",
  "2",  "Paranoá | Varjão | Itapoã | Lago Norte",
  "3",  "Taguatinga",
  "4",  "Santa Maria",
  "5",  "Sobradinho",
  "6",  "Planaltina",
  "8",  "Ceilândia Centro",
  "9",  "Guará",
  "10", "Núcleo Bandeirante | Riacho Fundo | Park Way | Candangolândia",
  "11", "Cruzeiro | Sudoeste | Octogonal",
  "13", "Samambaia",
  "14", "Brasília - Asa Norte",
  "15", "Águas Claras",
  "16", "Ceilândia Norte | Brazlândia",
  "17", "Gama",
  "18", "Lago Sul | Jardim Botânico | São Sebastião",
  "19", "Taguatinga",
  "20", "Ceilândia Sul",
  "21", "Recanto das Emas"
)

# Soma os votos de cada deputado eleito por área (pode ter mais
# de uma zona por área, tipo Taguatinga = zonas 3 e 19)
votos_por_area <- votos_com_perfil %>%
  filter(numero_candidato %in% eleitos$numero_candidato) %>%
  left_join(zona_para_area, by = "zona") %>%
  group_by(numero_candidato, area) %>%
  summarise(votos_area = sum(votos), .groups = "drop")

# Pra cada deputado, pega a área de onde vieram mais votos
mora_onde <- votos_por_area %>%
  group_by(numero_candidato) %>%
  slice_max(votos_area, n = 1) %>%
  ungroup() %>%
  select(numero_candidato, area_destaque = area)

perfil_resumo <- perfil_indexado %>%
  left_join(mora_onde, by = "numero_candidato") %>%
  mutate(
    escolaridade_destaque = escolaridade_destaque,
    idade_destaque = idade_destaque,
    genero_destaque = if_else(delta_pct_genero_feminino > delta_pct_genero_masculino, "mais mulheres", "mais homens")
  ) %>%
  select(nome_candidato, sigla_partido, escolaridade_destaque, idade_destaque, genero_destaque, area_destaque)

write_excel_csv(perfil_resumo, "D://Tabelas tratadas//TSE-dados-tratados//Tabelas finais//perfil-resumo.csv")
