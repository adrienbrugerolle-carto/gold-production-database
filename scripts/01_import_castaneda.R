# scripts/01_import_castaneda.R
# Importation des donnees Castaneda (2013)
# Source: data-raw/raw/Castaneda_world_1492_2012.csv

library(tidyverse)

cat("\n--- IMPORTATION: CASTANEDA (2013) ---\n")

if (!file.exists("data-raw/raw/Castaneda_world_1492_2012.csv")) {
  stop("Fichier source non trouve: data-raw/raw/Castaneda_world_1492_2012.csv")
}

castaneda_raw <- read_csv("data-raw/raw/Castaneda_world_1492_2012.csv",
                          show_col_types = FALSE)

castaneda <- castaneda_raw %>%
  rename(
    year = year,
    production_kg = production_tonnes
  ) %>%
  mutate(
    production_kg = production_kg * 1000,  # CORRECTION: tonnes -> kg
    source = "castaneda",
    country = "World",
    unit = "kg"
  ) %>%
  filter(!is.na(year), !is.na(production_kg), production_kg > 0) %>%
  select(year, production_kg, source, country, unit)

cat("  Observations :", nrow(castaneda), "\n")
cat("  Periode :", min(castaneda$year), "-", max(castaneda$year), "\n")

save(castaneda, file = "data/castaneda.rda")
cat("  Sauvegarde : data/castaneda.rda\n")

cat("--- IMPORTATION CASTANEDA TERMINEE ---\n")