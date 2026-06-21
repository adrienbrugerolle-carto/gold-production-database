# scripts/01_import_craig.R (version corrigée)
# Importation des donnees Craig & Rimstidt (1998)

library(tidyverse)

cat("\n--- IMPORTATION: CRAIG & RIMSTIDT (1998) ---\n")

# Lire le fichier avec col_names = TRUE pour voir la structure
craig_test <- read_csv("data-raw/raw/craig_states_1799_1995_V2.csv", 
                       show_col_types = FALSE)

cat("  Colonnes :", paste(names(craig_test), collapse = ", "), "\n")
cat("  Dimensions :", nrow(craig_test), "x", ncol(craig_test), "\n")

# Re-lire avec col_names = FALSE pour tout avoir en brut
craig_raw <- read_csv("data-raw/raw/craig_states_1799_1995_V2.csv", 
                      show_col_types = FALSE, 
                      col_names = FALSE)

# Afficher les premières lignes pour debug
cat("  Premieres lignes (brut) :\n")
print(head(craig_raw, 5))

# La premiere ligne contient les annees (colonne 1 = NA, colonnes 2:25 = annees)
years <- as.numeric(craig_raw[1, 2:ncol(craig_raw)])
years <- years[!is.na(years)]
cat("  Annees trouvees :", length(years), "(", min(years), "-", max(years), ")\n")

# Les lignes suivantes contiennent les etats
all_craig <- list()

for (i in 2:nrow(craig_raw)) {
  state_name <- as.character(craig_raw[i, 1])
  if (!is.na(state_name) && state_name != "NA" && state_name != "") {
    # Les valeurs commencent à la colonne 2
    values <- as.numeric(craig_raw[i, 2:ncol(craig_raw)])
    values <- values[!is.na(values)]
    
    if (length(values) > 0 && sum(values, na.rm = TRUE) > 0) {
      # S'assurer que values et years ont la même longueur
      n_obs <- min(length(values), length(years))
      
      state_data <- tibble(
        year = years[1:n_obs],
        production_kg = values[1:n_obs] * 0.0311035,  # onces -> kg
        source = "Craig & Rimstidt (1998)",
        country = state_name,
        unit = "kg"
      ) %>%
        filter(!is.na(year), !is.na(production_kg), production_kg > 0)
      
      if (nrow(state_data) > 0) {
        all_craig[[state_name]] <- state_data
        cat("    ", state_name, ":", nrow(state_data), "observations\n")
      }
    }
  }
}

craig <- bind_rows(all_craig)

cat("\n  Total Craig :", nrow(craig), "observations\n")
if (nrow(craig) > 0) {
  cat("  Periode :", min(craig$year), "-", max(craig$year), "\n")
  cat("  Pays :", n_distinct(craig$country), "\n")
} else {
  cat("  Aucune donnee Craig importee\n")
}

save(craig, file = "data/craig.rda")
cat("  Sauvegarde : data/craig.rda\n")

cat("--- IMPORTATION CRAIG TERMINEE ---\n")
