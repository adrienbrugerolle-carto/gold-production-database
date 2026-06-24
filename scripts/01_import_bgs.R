# scripts/01_import_bgs.R (version corrigée)

library(tidyverse)

cat("\n--- IMPORTATION: BGS ---\n")

if (!file.exists("data-raw/raw/bgs_1971_2014.csv")) {
  stop("Fichier source non trouve: data-raw/raw/bgs_1971_2014.csv")
}

bgs_raw <- read_csv("data-raw/raw/bgs_1971_2014.csv",
                    show_col_types = FALSE)

cat("  Colonnes disponibles :", paste(names(bgs_raw), collapse = ", "), "\n")

# Colonnes identifiées:
# - year: colonne "year" (timestamp)
# - country: country_trans
# - production: quantity
# - units: units

bgs <- bgs_raw %>%
  mutate(
    year = as.numeric(format(year, "%Y")),
    production_kg = as.numeric(quantity)
  ) %>%
  filter(!is.na(year), !is.na(production_kg), production_kg > 0) %>%
  mutate(
    country = as.character(country_trans),
    source = "bgs",
    unit = "kg"
  ) %>%
  select(year, production_kg, source, country, unit)

cat("  Observations :", nrow(bgs), "\n")
if (nrow(bgs) > 0) {
  cat("  Periode :", min(bgs$year), "-", max(bgs$year), "\n")
  cat("  Pays :", n_distinct(bgs$country), "\n")
}

save(bgs, file = "data/bgs.rda")
cat("  Sauvegarde : data/bgs.rda\n")

cat("--- IMPORTATION BGS TERMINEE ---\n")