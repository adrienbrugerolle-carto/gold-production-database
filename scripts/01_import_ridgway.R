# scripts/01_import_ridgway.R
# Importation des donnees Ridgway (1929) avec lissage

library(tidyverse)
library(stringr)

cat("\n--- IMPORTATION: RIDGWAY (1929) ---\n")

ONCE_TROY_TO_KG <- 0.0311035

# --- 1. Donnees annuelles ---
ridgway_raw <- read_csv("data-raw/raw/Ridgway_1929_years.csv", 
                        show_col_types = FALSE,
                        col_names = FALSE)

headers <- as.character(ridgway_raw[2, ])
headers_clean <- headers[!is.na(headers) & headers != "NA" & headers != "Period"]

years_lines <- ridgway_raw[3:nrow(ridgway_raw), ] %>%
  mutate(X1_char = as.character(X1)) %>%
  filter(str_detect(X1_char, "^[0-9]"))

all_entities <- list()

for (i in 1:length(headers_clean)) {
  entity_name <- headers_clean[i]
  col_index <- i + 1
  
  if (col_index <= ncol(years_lines)) {
    entity_data <- years_lines %>%
      mutate(
        year = as.numeric(X1),
        production_kg = as.numeric(.[[col_index]]) * ONCE_TROY_TO_KG,
        source = "ridgway_annual",
        country = entity_name,
        unit = "kg"
      ) %>%
      filter(!is.na(year), !is.na(production_kg), production_kg > 0) %>%
      select(year, production_kg, source, country, unit)
    
    if (nrow(entity_data) > 0) {
      all_entities[[entity_name]] <- entity_data
    }
  }
}

ridgway_annual <- bind_rows(all_entities, .id = "country_original") %>%
  select(-country_original)

cat("\n  Donnees annuelles :", nrow(ridgway_annual), "observations\n")
cat("  Entités :", n_distinct(ridgway_annual$country), "\n")

save(ridgway_annual, file = "data/ridgway_annual.rda")
cat("  Sauvegarde : data/ridgway_annual.rda\n")

# --- 2. Donnees decennales (LISSAGE) ---
if (file.exists("data-raw/raw/Ridgway_1929_decade.csv")) {
  cat("\n  Importation des donnees decennales (lissage)...\n")
  
  ridgway_dec_raw <- read_csv("data-raw/raw/Ridgway_1929_decade.csv",
                              show_col_types = FALSE,
                              col_names = FALSE)
  
  dec_headers <- as.character(ridgway_dec_raw[2, ])
  dec_headers_clean <- dec_headers[!is.na(dec_headers) & dec_headers != "NA" & dec_headers != "Period"]
  
  dec_lines <- ridgway_dec_raw[3:nrow(ridgway_dec_raw), ] %>%
    mutate(X1_char = as.character(X1)) %>%
    filter(str_detect(X1_char, "^[0-9]"))
  
  all_dec <- list()
  
  for (i in 1:length(dec_headers_clean)) {
    entity_name <- dec_headers_clean[i]
    col_index <- i + 1
    
    if (col_index <= ncol(dec_lines)) {
      
      entity_data <- dec_lines %>%
        mutate(
          period_raw = X1,
          year_start = as.numeric(str_extract(X1, "^[0-9]{4}")),
          year_end = as.numeric(str_extract(X1, "[0-9]{4}$")),
          n_years = year_end - year_start + 1,
          production_total_kg = as.numeric(.[[col_index]]) * ONCE_TROY_TO_KG,
          production_annual_kg = production_total_kg / n_years
        ) %>%
        filter(!is.na(year_start), !is.na(production_total_kg), production_total_kg > 0)
      
      # Creer une observation pour chaque annee de la periode
      expanded_data <- entity_data %>%
        rowwise() %>%
        do({
          tibble(
            year = seq(.$year_start, .$year_end),
            production_kg = .$production_annual_kg,
            source = "ridgway_decadal",
            country = entity_name,
            unit = "kg"
          )
        }) %>%
        ungroup()
      
      if (nrow(expanded_data) > 0) {
        all_dec[[entity_name]] <- expanded_data
      }
    }
  }
  
  ridgway_decadal <- bind_rows(all_dec, .id = "country_original") %>%
    select(-country_original)
  
  cat("  Donnees decennales lissees :", nrow(ridgway_decadal), "observations\n")
  cat("  Entités :", n_distinct(ridgway_decadal$country), "\n")
  
  save(ridgway_decadal, file = "data/ridgway_decadal.rda")
  cat("  Sauvegarde : data/ridgway_decadal.rda\n")
}

cat("--- IMPORTATION RIDGWAY TERMINEE ---\n")