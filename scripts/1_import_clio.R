# ============================================================================
# scripts/1_import_clio.R - VERSION CORRIGÉE (gestion des virgules)
# ============================================================================

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 1. Lecture du fichier CLIO V2 avec conversion automatique
# ----------------------------------------------------------------------------

# Lire en spécifiant que toutes les colonnes sont texte d'abord
clio_raw <- read_csv("DATA/Gold_production-historical_V2.csv", 
                     col_types = cols(.default = col_character()))

# Renommer les premières colonnes
names(clio_raw)[1:6] <- c("webmapper_code", "webmapper_numeric", "ccode", 
                          "country_name", "start_year", "end_year")

# Supprimer les lignes avec country_name vide
clio_clean <- clio_raw %>%
  filter(!is.na(country_name), country_name != "", country_name != "country name") %>%
  select(-webmapper_code, -webmapper_numeric)

# ----------------------------------------------------------------------------
# 2. Convertir toutes les colonnes années en numérique (gérer les virgules)
# ----------------------------------------------------------------------------

# Fonction pour convertir une chaîne avec virgule en nombre
clean_number <- function(x) {
  if(is.character(x)) {
    # Remplacer la virgule par un point (séparateur décimal)
    x <- gsub(",", ".", x)
    # Supprimer les espaces
    x <- gsub(" ", "", x)
    # Convertir en numérique
    return(as.numeric(x))
  }
  return(as.numeric(x))
}

# Identifier les colonnes années
year_cols <- names(clio_clean)[-(1:4)]

# Appliquer la conversion à toutes les colonnes années
clio_clean <- clio_clean %>%
  mutate(across(all_of(year_cols), ~clean_number(.)))

# ----------------------------------------------------------------------------
# 3. Conversion en format long (annuel)
# ----------------------------------------------------------------------------

clio_long <- clio_clean %>%
  pivot_longer(
    cols = all_of(year_cols),
    names_to = "year",
    values_to = "production_tonnes"
  ) %>%
  mutate(
    year = as.numeric(year),
    production_tonnes = as.numeric(production_tonnes)
  ) %>%
  filter(!is.na(production_tonnes), production_tonnes > 0) %>%
  arrange(country_name, year)

# ----------------------------------------------------------------------------
# 4. Statistiques
# ----------------------------------------------------------------------------

cat("\n=== STATISTIQUES CLIO V2 ===\n")
cat("Nombre de pays/entités :", n_distinct(clio_long$country_name), "\n")
cat("Nombre d'observations :", nrow(clio_long), "\n")
cat("Période couverte :", range(clio_long$year, na.rm = TRUE), "\n")
cat("Production totale :", sum(clio_long$production_tonnes, na.rm = TRUE), "tonnes\n")

# Top 10 producteurs
top_clio <- clio_long %>%
  group_by(country_name) %>%
  summarise(total = sum(production_tonnes, na.rm = TRUE)) %>%
  arrange(desc(total)) %>%
  head(10)

cat("\nTop 10 producteurs CLIO :\n")
print(top_clio)

# Vérifier USA
usa_clio <- clio_long %>%
  filter(country_name == "United States") %>%
  select(year, production_tonnes)

cat("\nUSA (CLIO) - premières et dernières années :\n")
print(head(usa_clio, 10))
print(tail(usa_clio, 10))

# ----------------------------------------------------------------------------
# 5. Sauvegarde
# ----------------------------------------------------------------------------

write_csv(clio_long, "data/processed/clio_production_long.csv")
saveRDS(clio_long, "data/processed/clio_production_long.rds")

message("\n1_import_clio.R exécuté avec succès")

