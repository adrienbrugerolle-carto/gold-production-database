# scripts/01_import_soetbeer.R
# Importation des donnees Soetbeer (1880)
# Source: data-raw/raw/soetbeer_1493_1810_world.csv

library(tidyverse)

cat("\n--- IMPORTATION: SOETBEER (1880) ---\n")

if (!file.exists("data-raw/raw/soetbeer_1493_1810_world.csv")) {
  stop("Fichier source non trouve: data-raw/raw/soetbeer_1493_1810_world.csv")
}

soetbeer_raw <- read_csv("data-raw/raw/soetbeer_1493_1810_world.csv",
                         show_col_types = FALSE)

# Detection automatique des colonnes
col_names <- names(soetbeer_raw)

year_col <- col_names[str_detect(tolower(col_names), "year|annee|an|decade")][1]
if (is.na(year_col)) year_col <- col_names[1]

prod_col <- col_names[str_detect(tolower(col_names), "production|prod|tonnes|or|gold|kg")][1]
if (is.na(prod_col)) prod_col <- col_names[2]

soetbeer <- soetbeer_raw %>%
  mutate(
    year = as.numeric(str_extract(.[[year_col]], "^[0-9]{4}")),
    production_kg = as.numeric(.[[prod_col]]) * 1000  # CORRECTION: tonnes -> kg
  ) %>%
  filter(!is.na(year), !is.na(production_kg), 
         production_kg > 0, year > 1400, year < 2030) %>%
  mutate(
    country = "World",
    source = "soetbeer",
    unit = "kg"
  ) %>%
  select(year, production_kg, source, country, unit)

cat("  Observations :", nrow(soetbeer), "\n")
cat("  Periode :", min(soetbeer$year), "-", max(soetbeer$year), "\n")

save(soetbeer, file = "data/soetbeer.rda")
cat("  Sauvegarde : data/soetbeer.rda\n")

cat("--- IMPORTATION SOETBEER TERMINEE ---\n")