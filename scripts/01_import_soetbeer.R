# scripts/01_import_soetbeer.R
# Importation des donnees Soetbeer (1880)

library(tidyverse)

cat("\n--- IMPORTATION: SOETBEER (1880) ---\n")

soetbeer_raw <- read_csv("data-raw/raw/soetbeer_1493_1810_world.csv", 
                         show_col_types = FALSE)

cat("  Colonnes :", paste(names(soetbeer_raw), collapse = ", "), "\n")

# Le fichier a les colonnes: decade, silver_dm, silver_kg, gold_dm, gold_kg
# On veut la colonne gold_kg (production d'or en kg)

soetbeer <- soetbeer_raw %>%
  mutate(
    year = as.numeric(str_extract(decade, "^[0-9]{4}")),
    production_kg = gold_kg,
    source = "Soetbeer (1880)",
    country = "World",
    unit = "kg"
  ) %>%
  filter(!is.na(year), !is.na(production_kg), production_kg > 0) %>%
  select(year, production_kg, source, country, unit)

cat("  Observations :", nrow(soetbeer), "\n")
cat("  Periode :", min(soetbeer$year), "-", max(soetbeer$year), "\n")

save(soetbeer, file = "data/soetbeer.rda")
cat("  Sauvegarde : data/soetbeer.rda\n")

cat("--- IMPORTATION SOETBEER TERMINEE ---\n")
