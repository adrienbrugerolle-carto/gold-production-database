# scripts/01_import_tepaske.R (correction de la sauvegarde)

library(tidyverse)
library(stringr)

cat("\n--- IMPORTATION: TEPASKE (2010) ---\n")

tepAske_files <- list.files("data-raw/raw", pattern = "^tepaske_.*\\.csv$", full.names = TRUE)

if (length(tepAske_files) == 0) {
  stop("Aucun fichier TePaske trouve")
}

cat("  Fichiers trouves :", length(tepAske_files), "\n")

all_tepAske <- list()

for (f in tepAske_files) {
  cat("\n  Importation :", basename(f), "\n")
  
  country_name <- str_extract(basename(f), "(?<=tepaske_)[^.]+")
  country_name <- str_replace_all(country_name, "_", " ")
  country_name <- str_to_title(country_name)
  
  raw <- read_csv(f, show_col_types = FALSE, col_names = FALSE)
  
  headers <- as.character(raw[1, ])
  data_rows <- raw[-1, ]
  
  period_col <- which(str_detect(tolower(headers), "decade|period|annee|year|time"))[1]
  if (is.na(period_col)) period_col <- 1
  
  all_country_data <- list()
  
  for (i in 1:nrow(data_rows)) {
    period <- as.character(data_rows[i, period_col])
    if (is.na(period) || period == "NA") next
    
    year <- as.numeric(str_extract(period, "^[0-9]{4}"))
    if (is.na(year)) next
    
    for (j in 1:ncol(data_rows)) {
      if (j == period_col) next
      
      region <- headers[j]
      if (is.na(region) || region == "NA" || region == "") next
      
      value <- as.numeric(data_rows[i, j])
      if (is.na(value) || value == 0) next
      
      all_country_data[[paste0(period, "_", region)]] <- tibble(
        year = year,
        production_kg = value,
        source = "TePaske (2010)",
        country = paste(country_name, region, sep = " - "),
        unit = "kg"
      )
    }
  }
  
  if (length(all_country_data) > 0) {
    country_data <- bind_rows(all_country_data)
    all_tepAske[[country_name]] <- country_data
    cat("    Observations :", nrow(country_data), "\n")
    cat("    Periode :", min(country_data$year), "-", max(country_data$year), "\n")
    cat("    Regions :", n_distinct(country_data$country), "\n")
  } else {
    cat("    Aucune donnee pour ce fichier\n")
  }
}

if (length(all_tepAske) > 0) {
  # Fusionner TOUTES les donnees TePaske en UN seul objet
  tepaske <- bind_rows(all_tepAske)
  
  cat("\n  Total TePaske :", nrow(tepaske), "observations\n")
  cat("  Periode :", min(tepaske$year), "-", max(tepaske$year), "\n")
  cat("  Pays/Regions :", n_distinct(tepaske$country), "\n")
  
  # Sauvegarder avec le bon nom (tepaske, pas tepAske)
  save(tepaske, file = "data/tepaske.rda")
  cat("  Sauvegarde : data/tepaske.rda\n")
} else {
  cat("\n  Aucune donnee TePaske importee\n")
}

cat("--- IMPORTATION TEPASKE TERMINEE ---\n")
