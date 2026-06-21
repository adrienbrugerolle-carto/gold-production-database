# scripts/01_import_clio.R
# Importation des donnees CLIO INFRA (2015)
# Source: data-raw/raw/Gold_production-historical_V2.csv

library(tidyverse)

cat("\n--- IMPORTATION: CLIO INFRA (2015) ---\n")

# Identifier le fichier
clio_file <- "data-raw/raw/Gold_production-historical_V2.csv"

if (!file.exists(clio_file)) {
  clio_file <- "data-raw/raw/Gold_production-historical.csv"
  if (!file.exists(clio_file)) {
    cat("  Aucun fichier CLIO trouve\n")
    clio <- tibble(
      year = integer(),
      production_kg = numeric(),
      source = character(),
      country = character(),
      unit = character()
    )
    save(clio, file = "data/clio.rda")
    cat("  Fichier vide cree: data/clio.rda\n")
    q(save = "no")
  }
}

cat("  Fichier trouve :", basename(clio_file), "\n")

# Lire le fichier en forçant tous les types
clio_raw <- read_csv(clio_file, show_col_types = FALSE, 
                     col_types = cols(.default = col_character()))

cat("  Dimensions :", nrow(clio_raw), "x", ncol(clio_raw), "\n")

# Identifier les colonnes d'annees
col_names <- names(clio_raw)
metadata_cols <- c("Webmapper code", "Webmapper numeric code", "ccode", 
                   "country name", "start year", "end year")

# Colonnes d'annees (tout ce qui n'est pas metadata et qui est numerique)
year_cols <- col_names[!col_names %in% metadata_cols]
# Garder seulement les colonnes qui sont des nombres
year_cols <- year_cols[!is.na(suppressWarnings(as.numeric(year_cols)))]

cat("  Annees couvertes :", min(as.numeric(year_cols)), "-", max(as.numeric(year_cols)), "\n")
cat("  Nombre d'annees :", length(year_cols), "\n")

# Transformer en format long
cat("  Transformation en format long...\n")

# Convertir toutes les colonnes d'annees en numerique
clio <- clio_raw %>%
  select(country = `country name`, all_of(year_cols)) %>%
  # Convertir toutes les colonnes d'annees en numerique
  mutate(across(all_of(year_cols), ~ as.numeric(.))) %>%
  # Passer en format long
  pivot_longer(
    cols = all_of(year_cols),
    names_to = "year",
    values_to = "production_kg"
  ) %>%
  # Nettoyer
  mutate(
    year = as.numeric(year),
    production_kg = as.numeric(production_kg),
    source = "CLIO INFRA (2015)",
    unit = "kg"
  ) %>%
  filter(!is.na(year), !is.na(production_kg), production_kg > 0) %>%
  select(year, production_kg, source, country, unit) %>%
  arrange(country, year)

cat("  Observations :", nrow(clio), "\n")
if (nrow(clio) > 0) {
  cat("  Periode :", min(clio$year), "-", max(clio$year), "\n")
  cat("  Pays :", n_distinct(clio$country), "\n")
  cat("  Production totale :", round(sum(clio$production_kg, na.rm = TRUE) / 1000, 0), "tonnes\n")
} else {
  cat("  Aucune donnee positive trouvee\n")
}

# Sauvegarde
save(clio, file = "data/clio.rda")
cat("  Sauvegarde : data/clio.rda\n")

cat("--- IMPORTATION CLIO TERMINEE ---\n")