
# scripts/01_import_castaneda.R
# Importation des donnees Castaneda (2013)
# Source: data-raw/raw/Castaneda_world_1492_2012.csv

library(tidyverse)

cat("
--- IMPORTATION: CASTANEDA (2013) ---
")

source_file <- "data-raw/raw/Castaneda_world_1492_2012.csv"

if (!file.exists(source_file)) {
  stop("Fichier source non trouve: ", source_file)
}

castaneda_raw <- read_csv(source_file, show_col_types = FALSE)

castaneda <- castaneda_raw %>%
  rename(
    year = year,
    production_kg = production_tonnes
  ) %>%
  mutate(
    production_kg = production_kg * 1000,  # tonnes -> kg
    source = "Castaneda (2013)",
    country = "World",
    unit = "kg"
  ) %>%
  filter(!is.na(year), !is.na(production_kg), production_kg > 0) %>%
  select(year, production_kg, source, country, unit)

cat("  Observations :", nrow(castaneda), "
")
cat("  Periode :", min(castaneda$year), "-", max(castaneda$year), "
")

save(castaneda, file = "data/castaneda.rda")
cat("  Sauvegarde : data/castaneda.rda
")

cat("--- IMPORTATION CASTANEDA TERMINEE ---
")

