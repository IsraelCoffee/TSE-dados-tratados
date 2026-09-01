# =============================================================================
# 1__importando_dados.R — Importa resultados eleitorais (Base dos Dados)
# =============================================================================

# Defina o seu projeto no Google Cloud
set_billing_id("SEU ID")

# Resultados por candidato, agregados por município e zona eleitoral
# Já filtrado por ano/UF/cargo direto no SQL (mais barato que trazer tudo e filtrar no R)
query <- "
SELECT
    dados.ano as ano,
    dados.turno as turno,
    dados.id_eleicao as id_eleicao,
    dados.tipo_eleicao as tipo_eleicao,
    dados.data_eleicao as data_eleicao,
    dados.sigla_uf AS sigla_uf,
    diretorio_sigla_uf.nome AS sigla_uf_nome,
    dados.id_municipio AS id_municipio,
    diretorio_id_municipio.nome AS id_municipio_nome,
    dados.id_municipio_tse AS id_municipio_tse,
    diretorio_id_municipio_tse.nome AS id_municipio_tse_nome,
    dados.zona as zona,
    dados.cargo as cargo,
    dados.numero_partido as numero_partido,
    dados.sigla_partido as sigla_partido,
    dados.titulo_eleitoral_candidato as titulo_eleitoral_candidato,
    dados.sequencial_candidato as sequencial_candidato,
    dados.numero_candidato as numero_candidato,
    dados.resultado as resultado,
    dados.votos as votos
FROM `basedosdados.br_tse_eleicoes.resultados_candidato_municipio_zona` AS dados
LEFT JOIN (SELECT DISTINCT sigla,nome  FROM `basedosdados.br_bd_diretorios_brasil.uf`) AS diretorio_sigla_uf
    ON dados.sigla_uf = diretorio_sigla_uf.sigla
LEFT JOIN (SELECT DISTINCT id_municipio,nome  FROM `basedosdados.br_bd_diretorios_brasil.municipio`) AS diretorio_id_municipio
    ON dados.id_municipio = diretorio_id_municipio.id_municipio
LEFT JOIN (SELECT DISTINCT id_municipio_tse,nome  FROM `basedosdados.br_bd_diretorios_brasil.municipio`) AS diretorio_id_municipio_tse
    ON dados.id_municipio_tse = diretorio_id_municipio_tse.id_municipio_tse
WHERE
    dados.ano = 2022
    AND dados.sigla_uf = 'DF'
    AND dados.cargo = 'deputado distrital'
"

resultados_zona <- read_sql(query, billing_project_id = get_billing_id())

# Corrige o tipo de "votos" — vem como int64 do BigQuery, e isso
# quebra silenciosamente funções como weighted.mean() e sum() em alguns contextos
resultados_zona <- resultados_zona %>%
  mutate(votos = as.numeric(votos))


# Dicionário: numero_candidato -> nome_candidato, sigla_partido
# (mesma tabela que já usamos antes pra identificar os 24 eleitos)
query_nomes <- "
SELECT DISTINCT numero_candidato, nome_candidato, sigla_partido
FROM `basedosdados.br_tse_eleicoes.resultados_candidato`
WHERE ano = 2022
  AND sigla_uf = 'DF'
  AND cargo = 'deputado distrital'
  AND resultado IN ('eleito por qp', 'eleito por media')
"
nomes_eleitos <- read_sql(query_nomes, billing_project_id = get_billing_id())

query_nomes_nao_eleitos <- "
SELECT DISTINCT numero_candidato, nome_candidato, sigla_partido, resultado
FROM `basedosdados.br_tse_eleicoes.resultados_candidato`
WHERE ano = 2022
  AND sigla_uf = 'DF'
  AND cargo = 'deputado distrital'
  AND resultado IN ('nao eleito', 'suplente')
"
nomes_nao_eleitos <- read_sql(query_nomes_nao_eleitos, billing_project_id = get_billing_id())


# Votos nulos e brancos

query_detalhes <- "
SELECT
    ano, sigla_uf, id_municipio, zona, cargo,
    aptos, comparecimento, abstencoes,
    votos_validos, votos_brancos, votos_nulos,
    votos_nominais, votos_legenda,
    proporcao_comparecimento, proporcao_votos_validos,
    proporcao_votos_brancos, proporcao_votos_nulos
FROM `basedosdados.br_tse_eleicoes.detalhes_votacao_municipio_zona`
WHERE ano = 2022
  AND sigla_uf = 'DF'
  AND cargo = 'deputado distrital'
"
detalhes_zona <- read_sql(query_detalhes, billing_project_id = get_billing_id())

# Corrige tipos int64
detalhes_zona <- detalhes_zona %>%
  mutate(across(
    c(aptos, comparecimento, abstencoes, votos_validos, votos_brancos, votos_nulos, votos_nominais, votos_legenda),
    as.numeric
  ))