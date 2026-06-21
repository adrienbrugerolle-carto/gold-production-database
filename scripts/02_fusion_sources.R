# scripts/02_fusion_sources.R
# Fusion de toutes les sources (incluant CLIO)

library(tidyverse)

cat("\n--- FUSION DES SOURCES ---\n")

dir.create("fusion", showWarnings = FALSE)

# Liste de toutes les sources (AJOUT de CLIO)
source_files <- c(
  "ridgway_annual",
  "ridgway_decadal",
  "castaneda",
  "tepaske",
  "soetbeer",
  "bgs",
  "clio"  # AJOUT
)

all_data <- list()

for (src in source_files) {
  file_path <- paste0("data/", src, ".rda")
  if (file.exists(file_path)) {
    load(file_path)
    data <- get(src)
    # Ne garder que si le dataset n'est pas vide
    if (nrow(data) > 0) {
      all_data[[src]] <- data
      cat("  ", src, ":", nrow(data), "observations\n")
    } else {
      cat("  ", src, ": dataset vide (ignore)\n")
    }
  } else {
    cat("  ", src, ": fichier non trouve\n")
  }
}

if (length(all_data) == 0) {
  stop("Aucune source trouvee")
}

# Fusion
combined_data <- bind_rows(all_data, .id = "source")

# Sauvegarde de toutes les sources
save(combined_data, file = "fusion/all_sources.rda")
cat("\n  Sauvegarde : fusion/all_sources.rda\n")

# --- Donnees finales avec selection des sources ---
final_data <- combined_data %>%
  filter(
    source %in% c("ridgway_annual", "castaneda", "bgs", "tepaske", "soetbeer", "clio") |
      source == "ridgway_decadal"
  ) %>%
  group_by(country, year) %>%
  slice_max(order_by = case_when(
    source == "bgs" ~ 7,              # BGS le plus recent
    source == "clio" ~ 6,             # CLIO INFRA
    source == "ridgway_annual" ~ 5,   # Ridgway annuel
    source == "castaneda" ~ 4,        # Castaneda
    source == "tepaske" ~ 3,          # TePaske
    source == "soetbeer" ~ 2,         # Soetbeer
    source == "ridgway_decadal" ~ 1,  # Ridgway decenal
    TRUE ~ 0
  ), n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(country, year)

save(final_data, file = "fusion/final.rda")
cat("  Sauvegarde : fusion/final.rda\n")

# Resume
cat("\n--- RESUME ---\n")
cat("  Toutes les sources :", nrow(combined_data), "observations\n")
cat("  Donnees finales :", nrow(final_data), "observations\n")
cat("  Periode :", min(final_data$year), "-", max(final_data$year), "\n")
cat("  Pays :", n_distinct(final_data$country), "\n")

# Sources dans le jeu final
cat("\n  Sources dans le jeu final :\n")
final_data %>%
  group_by(source) %>%
  summarise(
    observations = n(),
    min_year = min(year),
    max_year = max(year)
  ) %>%
  arrange(desc(observations)) %>%
  print()

cat("--- FUSION TERMINEE ---\n")