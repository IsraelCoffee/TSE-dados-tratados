# IMPORTANDO AS TABELAS ========================================================7

# Defina o seu projeto no Google Cloud
set_billing_id("SEU ID")


# Para carregar o dado direto no R
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
    dados.secao as secao,
    dados.cargo as cargo,
    dados.numero_partido as numero_partido,
    dados.sigla_partido as sigla_partido,
    dados.sequencial_candidato as sequencial_candidato,
    dados.numero_candidato as numero_candidato,
    dados.titulo_eleitoral_candidato as titulo_eleitoral_candidato,
    dados.votos as votos
FROM `basedosdados.br_tse_eleicoes.resultados_candidato_secao` AS dados
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

votacao_secao <- read_sql(query, billing_project_id = get_billing_id())


# Para carregar o dado direto no R
query <- "
WITH 
dicionario_situacao_biometria AS (
    SELECT
        chave AS chave_situacao_biometria,
        valor AS descricao_situacao_biometria
    FROM `basedosdados.br_tse_eleicoes.dicionario`
    WHERE
        TRUE
        AND nome_coluna = 'situacao_biometria'
        AND id_tabela = 'perfil_eleitorado_secao'
),
dicionario_genero AS (
    SELECT
        chave AS chave_genero,
        valor AS descricao_genero
    FROM `basedosdados.br_tse_eleicoes.dicionario`
    WHERE
        TRUE
        AND nome_coluna = 'genero'
        AND id_tabela = 'perfil_eleitorado_secao'
),
dicionario_estado_civil AS (
    SELECT
        chave AS chave_estado_civil,
        valor AS descricao_estado_civil
    FROM `basedosdados.br_tse_eleicoes.dicionario`
    WHERE
        TRUE
        AND nome_coluna = 'estado_civil'
        AND id_tabela = 'perfil_eleitorado_secao'
),
dicionario_grupo_idade AS (
    SELECT
        chave AS chave_grupo_idade,
        valor AS descricao_grupo_idade
    FROM `basedosdados.br_tse_eleicoes.dicionario`
    WHERE
        TRUE
        AND nome_coluna = 'grupo_idade'
        AND id_tabela = 'perfil_eleitorado_secao'
),
dicionario_instrucao AS (
    SELECT
        chave AS chave_instrucao,
        valor AS descricao_instrucao
    FROM `basedosdados.br_tse_eleicoes.dicionario`
    WHERE
        TRUE
        AND nome_coluna = 'instrucao'
        AND id_tabela = 'perfil_eleitorado_secao'
)
SELECT
    dados.ano as ano,
    dados.sigla_uf AS sigla_uf,
    diretorio_sigla_uf.nome AS sigla_uf_nome,
    dados.id_municipio AS id_municipio,
    diretorio_id_municipio.nome AS id_municipio_nome,
    dados.id_municipio_tse AS id_municipio_tse,
    diretorio_id_municipio_tse.nome AS id_municipio_tse_nome,
    descricao_situacao_biometria AS situacao_biometria,
    dados.zona as zona,
    dados.secao as secao,
    descricao_genero AS genero,
    descricao_estado_civil AS estado_civil,
    descricao_grupo_idade AS grupo_idade,
    descricao_instrucao AS instrucao,
    dados.eleitores as eleitores,
    dados.eleitores_biometria as eleitores_biometria,
    dados.eleitores_deficiencia as eleitores_deficiencia,
    dados.eleitores_inclusao_nome_social as eleitores_inclusao_nome_social
FROM `basedosdados.br_tse_eleicoes.perfil_eleitorado_secao` AS dados
LEFT JOIN (SELECT DISTINCT sigla,nome  FROM `basedosdados.br_bd_diretorios_brasil.uf`) AS diretorio_sigla_uf
    ON dados.sigla_uf = diretorio_sigla_uf.sigla
LEFT JOIN (SELECT DISTINCT id_municipio,nome  FROM `basedosdados.br_bd_diretorios_brasil.municipio`) AS diretorio_id_municipio
    ON dados.id_municipio = diretorio_id_municipio.id_municipio
LEFT JOIN (SELECT DISTINCT id_municipio_tse,nome  FROM `basedosdados.br_bd_diretorios_brasil.municipio`) AS diretorio_id_municipio_tse
    ON dados.id_municipio_tse = diretorio_id_municipio_tse.id_municipio_tse
LEFT JOIN `dicionario_situacao_biometria`
    ON dados.situacao_biometria = chave_situacao_biometria
LEFT JOIN `dicionario_genero`
    ON dados.genero = chave_genero
LEFT JOIN `dicionario_estado_civil`
    ON dados.estado_civil = chave_estado_civil
LEFT JOIN `dicionario_grupo_idade`
    ON dados.grupo_idade = chave_grupo_idade
LEFT JOIN `dicionario_instrucao`
    ON dados.instrucao = chave_instrucao
WHERE
    dados.ano = 2022
    AND dados.sigla_uf = 'DF'
"

perfil_secao <- read_sql(query, billing_project_id = get_billing_id())

perfil_secao <- perfil_secao %>%
  mutate(
    grupo_idade = str_trim(grupo_idade),
    genero = str_trim(genero),
    instrucao = str_trim(instrucao)
  )

query_eleitos <- "
SELECT ano, sigla_uf, cargo, numero_candidato, nome_candidato, sigla_partido, resultado
FROM `basedosdados.br_tse_eleicoes.resultados_candidato`
WHERE ano = 2022
  AND sigla_uf = 'DF'
  AND cargo = 'deputado distrital'
  AND resultado IN ('eleito por qp', 'eleito por media')
"
eleitos <- read_sql(query_eleitos, billing_project_id = get_billing_id())
