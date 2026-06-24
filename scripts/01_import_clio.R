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

# Lire le fichier
clio_raw <- read_csv(clio_file, show_col_types = FALSE, 
                     col_types = cols(.default = col_character()))

cat("  Dimensions :", nrow(clio_raw), "x", ncol(clio_raw), "\n")

# Identifier les colonnes d'annees
col_names <- names(clio_raw)
metadata_cols <- c("Webmapper code", "Webmapper numeric code", "ccode", 
                   "country name", "start year", "end year")

year_cols <- col_names[!col_names %in% metadata_cols]
year_cols <- year_cols[!is.na(suppressWarnings(as.numeric(year_cols)))]

cat("  Annees couvertes :", min(as.numeric(year_cols)), "-", max(as.numeric(year_cols)), "\n")
cat("  Nombre d'annees :", length(year_cols), "\n")

# Transformer en format long
cat("  Transformation en format long...\n")

clio <- clio_raw %>%
  select(country = `country name`, all_of(year_cols)) %>%
  mutate(across(all_of(year_cols), ~ as.numeric(.))) %>%
  pivot_longer(
    cols = all_of(year_cols),
    names_to = "year",
    values_to = "production_tonnes"
  ) %>%
  mutate(
    year = as.numeric(year),
    production_kg = production_tonnes * 1000,  # CORRECTION: tonnes -> kg
    source = "clio",
    unit = "kg"
  ) %>%
  filter(!is.na(year), !is.na(production_kg), production_kg > 0) %>%
  select(year, production_kg, source, country, unit) %>%
  arrange(country, year)

cat("  Observations :", nrow(clio), "\n")
if (nrow(clio) > 0) {
  cat("  Periode :", min(clio$year), "-", max(clio$year), "\n")
  cat("  Pays :", n_distinct(clio$country), "\n")
}

save(clio, file = "data/clio.rda")
cat("  Sauvegarde : data/clio.rda\n")

cat("--- IMPORTATION CLIO TERMINEE ---\n")