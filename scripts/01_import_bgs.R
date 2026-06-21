# scripts/01_import_bgs.R
# Importation des donnees BGS (British Geological Survey)

library(tidyverse)

cat("\n--- IMPORTATION: BGS ---\n")

bgs_raw <- read_csv("data-raw/raw/bgs_1971_2014.csv", 
                    show_col_types = FALSE)

cat("  Colonnes disponibles :", paste(names(bgs_raw), collapse = ", "), "\n")

# Colonnes identifiees:
# - year: colonne "year" (mais c'est un timestamp)
# - country: country_trans
# - production: quantity
# - units: units

bgs <- bgs_raw %>%
  mutate(
    # Extraire l'annee du timestamp
    year = as.numeric(format(year, "%Y")),
    production_kg = quantity,
    source = "BGS (British Geological Survey)",
    country = country_trans,
    unit = units
  ) %>%
  filter(!is.na(year), !is.na(production_kg), production_kg > 0) %>%
  select(year, production_kg, source, country, unit)

cat("  Observations :", nrow(bgs), "\n")
cat("  Periode :", min(bgs$year), "-", max(bgs$year), "\n")
cat("  Pays :", n_distinct(bgs$country), "\n")

save(bgs, file = "data/bgs.rda")
cat("  Sauvegarde : data/bgs.rda\n")

cat("--- IMPORTATION BGS TERMINEE ---\n")
