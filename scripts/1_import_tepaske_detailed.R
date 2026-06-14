# ============================================================================
# scripts/1_import_tepaske_detailed.R
# Importation des données TePaske au niveau le plus fin (caisses/régions)
# ============================================================================

source("scripts/0_setup.R")

# ----------------------------------------------------------------------------
# 1. Importer tous les fichiers détaillés
# ----------------------------------------------------------------------------

# Mexico (16 caisses)
tepaske_mexico <- read_csv("DATA/tepaske_mexico_1521_1810.csv") %>%
  rename(decade = 1) %>%
  pivot_longer(cols = -decade, names_to = "province", values_to = "production_tonnes") %>%
  mutate(
    year = map_dbl(decade, ~ round(mean(as.numeric(strsplit(.x, "–")[[1]])))),
    country = "Mexico",
    region = "New Spain",
    source = "TePaske"
  ) %>%
  filter(!is.na(production_tonnes), production_tonnes > 0)

# Peru (12 caisses)
tepaske_peru <- read_csv("DATA/tepaske_peru_1531_1810.csv") %>%
  rename(decade = 1) %>%
  pivot_longer(cols = -decade, names_to = "province", values_to = "production_tonnes") %>%
  mutate(
    year = map_dbl(decade, ~ round(mean(as.numeric(strsplit(.x, "–")[[1]])))),
    country = "Peru",
    region = "Viceroyalty of Peru",
    source = "TePaske"
  ) %>%
  filter(!is.na(production_tonnes), production_tonnes > 0)

# Brazil (3 régions)
tepaske_brazil <- read_csv("DATA/tepaske_brazil_1691_1810.csv") %>%
  rename(decade = 1) %>%
  pivot_longer(cols = -decade, names_to = "province", values_to = "production_tonnes") %>%
  mutate(
    year = map_dbl(decade, ~ round(mean(as.numeric(strsplit(.x, "–")[[1]])))),
    country = "Brazil",
    region = "Colonial Brazil",
    source = "TePaske"
  ) %>%
  filter(!is.na(production_tonnes), production_tonnes > 0)

# Caribbean (4 îles)
tepaske_caribbean <- read_csv("DATA/tepaske_carribean_1493_1555.csv") %>%
  rename(decade = 1) %>%
  pivot_longer(cols = -decade, names_to = "island", values_to = "production_tonnes") %>%
  mutate(
    year = map_dbl(decade, ~ round(mean(as.numeric(strsplit(.x, "–")[[1]])))),
    country = island,
    region = "Caribbean",
    source = "TePaske"
  ) %>%
  filter(!is.na(production_tonnes), production_tonnes > 0)

# South America (autres pays)
tepaske_south_america <- read_csv("DATA/tepaske_south_america_1533_1810.csv") %>%
  rename(decade = 1) %>%
  pivot_longer(cols = -decade, names_to = "country", values_to = "production_tonnes") %>%
  mutate(
    year = map_dbl(decade, ~ round(mean(as.numeric(strsplit(.x, "–")[[1]])))),
    region = "South America",
    source = "TePaske"
  ) %>%
  filter(!is.na(production_tonnes), production_tonnes > 0)

# ----------------------------------------------------------------------------
# 2. Fusionner tout le détail
# ----------------------------------------------------------------------------

tepaske_detailed <- bind_rows(
  tepaske_mexico,
  tepaske_peru,
  tepaske_brazil,
  tepaske_caribbean,
  tepaske_south_america
) %>%
  select(year, country, region, province, production_tonnes, source) %>%
  arrange(year, country, province)

# ----------------------------------------------------------------------------
# 3. Statistiques
# ----------------------------------------------------------------------------

cat("\n=== STATISTIQUES TEPASKE (NIVEAU DÉTAILLÉ) ===\n")
cat("Nombre d'observations :", nrow(tepaske_detailed), "\n")
cat("Période couverte :", range(tepaske_detailed$year, na.rm = TRUE), "\n")
cat("Pays :", paste(unique(tepaske_detailed$country), collapse = ", "), "\n")
cat("Nombre de provinces/caisses :", n_distinct(tepaske_detailed$province, na.rm = TRUE), "\n")

cat("\nProduction totale par pays :\n")
tepaske_detailed %>%
  group_by(country) %>%
  summarise(total = sum(production_tonnes, na.rm = TRUE)) %>%
  arrange(desc(total)) %>%
  print()

cat("\nTop 10 provinces/productrices :\n")
tepaske_detailed %>%
  group_by(province, country) %>%
  summarise(total = sum(production_tonnes, na.rm = TRUE)) %>%
  arrange(desc(total)) %>%
  head(10) %>%
  print()

# ----------------------------------------------------------------------------
# 4. Sauvegarde
# ----------------------------------------------------------------------------

write_csv(tepaske_detailed, "data/processed/tepaske_detailed.csv")
saveRDS(tepaske_detailed, "data/processed/tepaske_detailed.rds")

# Aussi une version agrégée par pays pour fusion facile
tepaske_by_country <- tepaske_detailed %>%
  group_by(year, country) %>%
  summarise(production_tonnes = sum(production_tonnes, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(source = "TePaske")

write_csv(tepaske_by_country, "data/processed/tepaske_by_country.csv")
saveRDS(tepaske_by_country, "data/processed/tepaske_by_country.rds")

message("\n1_import_tepaske_detailed.R exécuté avec succès")
