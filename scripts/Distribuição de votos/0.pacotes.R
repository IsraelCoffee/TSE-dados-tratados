# =============================================================================
# 0__Pacotes.R — Instalação e carregamento de pacotes
# =============================================================================

# Lista de pacotes usados no projeto
pacotes <- c(
  "basedosdados", "dplyr", "ggplot2", "scales", "readr",
  "sf", "leaflet", "htmlwidgets", "htmltools", "plotly", "showtext", "stringr"
)

# Instala apenas o que ainda não estiver instalado
pacotes_faltando <- pacotes[!pacotes %in% installed.packages()[, "Package"]]
if (length(pacotes_faltando) > 0) {
  install.packages(pacotes_faltando)
}

# Carrega todos de uma vez
invisible(lapply(pacotes, library, character.only = TRUE))


# Registra as fontes do projeto (precisam estar instaladas no sistema
# ou disponíveis via Google Fonts)
font_add_google("Poppins", "Poppins")
font_add_google("Inter", "Inter")
showtext_auto()

# ============================================================
# PALETA DO PROJETO OIKOS STATS
# ============================================================
azul_escuro   <- "#1A3C5E"
azul_medio    <- "#2D6A9F"
azul_claro    <- "#EAF2FA"
laranja       <- "#E8871E"
laranja_claro <- "#FDECD8"
cinza_fundo   <- "#F4F4F4"
cor_texto     <- "#2C2C2C"
cor_texto_suave <- "#666666"