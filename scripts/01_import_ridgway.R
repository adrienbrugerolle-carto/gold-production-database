# scripts/01_import_ridgway.R
# Importation des donnees Ridgway (1929)

library(tidyverse)
library(stringr)

cat("\n--- IMPORTATION: RIDGWAY (1929) ---\n")

ONCE_TROY_TO_KG <- 0.0311035

# --- Donnees annuelles ---
cat("  Importation des donnees annuelles...\n")

ridgway_annual_raw <- read_csv("data-raw/raw/Ridgway_1929_years.csv", 
                               show_col_types = FALSE,
                               col_names = FALSE)

ridgway_annual <- ridgway_annual_raw %>%
  mutate(X1_char = as.character(X1)) %>%
  filter(str_detect(X1_char, "^[0-9]")) %>%
  mutate(
    year = as.numeric(X1),
    production_kg = as.numeric(X2) * ONCE_TROY_TO_KG,
    source = "ridgway_annual",
    country = "World",
    unit = "kg"
  ) %>%
  filter(!is.na(year), !is.na(production_kg), year > 0) %>%
  select(year, production_kg, source, country, unit)

cat("    Observations :", nrow(ridgway_annual), "\n")
cat("    Periode :", min(ridgway_annual$year), "-", max(ridgway_annual$year), "\n")

save(ridgway_annual, file = "data/ridgway_annual.rda")
cat("  Sauvegarde : data/ridgway_annual.rda\n")

# --- Donnees decennales (CORRIGEES: diviser par 10) ---
if (file.exists("data-raw/raw/Ridgway_1929_decade.csv")) {
  cat("  Importation des donnees decennales...\n")
  
  ridgway_decadal_raw <- read_csv("data-raw/raw/Ridgway_1929_decade.csv",
                                  show_col_types = FALSE,
                                  col_names = FALSE)
  
  ridgway_decadal <- ridgway_decadal_raw %>%
    mutate(X1_char = as.character(X1)) %>%
    filter(str_detect(X1_char, "^[0-9]")) %>%
    mutate(
      year = as.numeric(str_extract(X1, "^[0-9]{4}")),
      production_kg = (as.numeric(X2) * ONCE_TROY_TO_KG) / 10,  # Division par 10
      source = "ridgway_decadal",
      country = "World",
      unit = "kg",
      period_raw = X1
    ) %>%
    filter(!is.na(year), !is.na(production_kg), year > 0) %>%
    select(year, production_kg, source, country, unit)
  
  cat("    Observations :", nrow(ridgway_decadal), "\n")
  cat("    Periode :", min(ridgway_decadal$year), "-", max(ridgway_decadal$year), "\n")
  cat("    NOTE: Donnees decennales divisees par 10 pour moyenne annuelle\n")
  
  save(ridgway_decadal, file = "data/ridgway_decadal.rda")
  cat("  Sauvegarde : data/ridgway_decadal.rda\n")
} else {
  cat("  Fichier decennal non trouve\n")
}

cat("--- IMPORTATION RIDGWAY TERMINEE ---\n")