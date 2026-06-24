# scripts/01_import_tepaske.R
# Importation des donnees TePaske (2010)
# 
# STRUCTURE DES DONNEES :
# 1. tepaske_latine_america_1493_1810.csv : Tableau principal avec les grandes regions
#    - Ligne 1 : en-tetes (carribean, mexico, peru, new granada, ecuador, chile, brazil, other)
#    - Lignes suivantes : decennies et valeurs (kg)
# 
# 2. tepaske_mexico_1521_1810.csv : Detail du Mexique (caisses)
# 3. tepaske_peru_1531_1810.csv : Detail du Perou (caisses)
# 4. tepaske_brazil_1691_1810.csv : Detail du Bresil (regions)
# 5. tepaske_south_america_1533_1810.csv : Detail de l'Amerique du Sud
# 6. tepaske_carribean_1493_1555.csv : Detail des Caraibes
#
# Les valeurs sont en kg (kilogrammes) et sont des totaux par decennie.
# Le script calcule la moyenne annuelle en divisant par le nombre d'annees de la decennie.

library(tidyverse)
library(stringr)

cat("\n--- IMPORTATION: TEPASKE (2010) ---\n")

# Fonction pour extraire les donnees d'un fichier TePaske
extract_tepaske_file <- function(file_path, region_name) {
  
  if (!file.exists(file_path)) {
    cat("  Fichier non trouve:", basename(file_path), "\n")
    return(NULL)
  }
  
  raw <- read_csv(file_path, show_col_types = FALSE, col_names = FALSE)
  
  # Ligne 1 = en-tetes (entites spatiales)
  headers <- as.character(raw[1, ])
  headers_clean <- headers[!is.na(headers) & headers != "NA" & headers != "decade"]
  
  # Lignes suivantes = donnees
  data_rows <- raw[-1, ]
  
  # Colonne des decennies
  period_col <- which(str_detect(tolower(headers), "decade|period|annee|year|time"))[1]
  if (is.na(period_col)) period_col <- 1
  
  all_data <- list()
  
  for (i in 1:nrow(data_rows)) {
    period <- as.character(data_rows[i, period_col])
    if (is.na(period) || period == "NA") next
    
    # Extraire les annees de la decennie
    year_start <- as.numeric(str_extract(period, "^[0-9]{4}"))
    if (is.na(year_start)) next
    
    year_end <- as.numeric(str_extract(period, "[0-9]{4}$"))
    if (is.na(year_end)) year_end <- year_start + 9
    
    n_years <- year_end - year_start + 1
    
    # Pour chaque entite (colonne)
    for (j in 1:length(headers_clean)) {
      col_index <- j + 1
      if (col_index > ncol(data_rows)) next
      
      entity_name <- headers_clean[j]
      if (is.na(entity_name) || entity_name == "NA" || entity_name == "") next
      
      value_total <- as.numeric(data_rows[i, col_index])
      if (is.na(value_total) || value_total == 0) next
      
      # Moyenne annuelle sur la decennie
      value_annual <- value_total / n_years
      
      # Repeter sur chaque annee
      for (year in year_start:year_end) {
        all_data[[paste0(year, "_", entity_name)]] <- tibble(
          year = year,
          production_kg = value_annual,
          source = "tepaske",
          country = paste(region_name, entity_name, sep = " - "),
          unit = "kg"
        )
      }
    }
  }
  
  if (length(all_data) > 0) {
    return(bind_rows(all_data))
  } else {
    return(NULL)
  }
}

# --- 1. Fichier principal ---
cat("\n1. Importation du fichier principal...\n")
main_data <- extract_tepaske_file(
  "data-raw/raw/tepaske_latine_america_1493_1810.csv",
  "Latine America 1493 1810"
)

# --- 2. Fichiers detail par pays ---
cat("\n2. Importation des fichiers detail...\n")
mexico_data <- extract_tepaske_file(
  "data-raw/raw/tepaske_mexico_1521_1810.csv",
  "Mexico 1521 1810"
)

peru_data <- extract_tepaske_file(
  "data-raw/raw/tepaske_peru_1531_1810.csv",
  "Peru 1531 1810"
)

brazil_data <- extract_tepaske_file(
  "data-raw/raw/tepaske_brazil_1691_1810.csv",
  "Brazil 1691 1810"
)

south_america_data <- extract_tepaske_file(
  "data-raw/raw/tepaske_south_america_1533_1810.csv",
  "South America 1533 1810"
)

carribean_data <- extract_tepaske_file(
  "data-raw/raw/tepaske_carribean_1493_1555.csv",
  "Carribean 1493 1555"
)

# --- 3. Combinaison ---
cat("\n3. Combinaison des donnees...\n")

all_data <- list(
  main_data,
  mexico_data,
  peru_data,
  brazil_data,
  south_america_data,
  carribean_data
)

# Filtrer les NULL
all_data <- all_data[!sapply(all_data, is.null)]

if (length(all_data) == 0) {
  stop("Aucune donnee TePaske importee")
}

tepaske <- bind_rows(all_data)

cat("  Total observations :", nrow(tepaske), "\n")
cat("  Periode :", min(tepaske$year), "-", max(tepaske$year), "\n")
cat("  Entites :", n_distinct(tepaske$country), "\n")

# --- 4. Sauvegarde ---
cat("\n4. Sauvegarde...\n")
save(tepaske, file = "data/tepaske.rda")
write_csv(tepaske, "data/tepaske.csv")

cat("  Sauvegarde : data/tepaske.rda\n")
cat("  Sauvegarde : data/tepaske.csv\n")

# --- 5. Resume ---
cat("\n5. Resume par entite :\n")
summary <- tepaske %>%
  group_by(country) %>%
  summarise(
    observations = n(),
    min_year = min(year),
    max_year = max(year),
    production_kg = round(sum(production_kg, na.rm = TRUE), 0)
  ) %>%
  arrange(desc(production_kg))

print(summary)

cat("--- IMPORTATION TEPASKE TERMINEE ---\n")