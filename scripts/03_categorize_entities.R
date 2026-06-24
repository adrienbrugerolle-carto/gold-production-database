# scripts/03_categorize_entities.R
# Catégorisation des entités spatiales (avec hiérarchie TePaske)

library(tidyverse)

cat("\n=== CATEGORISATION DES ENTITES SPATIALES ===\n")

load("fusion/all_sources.rda")

# 1. Nettoyer les noms des entités TePaske
cat("\n1. Nettoyage des entités TePaske...\n")

tepaske_entities <- combined_data %>%
  filter(source == "tepaske") %>%
  distinct(country) %>%
  mutate(
    # Extraire la hiérarchie
    region = case_when(
      str_detect(country, "Latine America") ~ "Latin America",
      str_detect(country, "Mexico") ~ "Mexico",
      str_detect(country, "Peru") ~ "Peru",
      str_detect(country, "Brazil") ~ "Brazil",
      str_detect(country, "South America") ~ "South America",
      str_detect(country, "Carribean") ~ "Caribbean",
      TRUE ~ "Other"
    ),
    # Niveau hiérarchique
    hierarchy_level = case_when(
      str_detect(country, "Latine America 1493 1810 - ") ~ 1,
      str_detect(country, "Mexico 1521 1810 - ") ~ 2,
      str_detect(country, "Peru 1531 1810 - ") ~ 2,
      str_detect(country, "Brazil 1691 1810 - ") ~ 2,
      str_detect(country, "South America 1533 1810 - ") ~ 2,
      str_detect(country, "Carribean 1493 1555 - ") ~ 2,
      TRUE ~ 1
    ),
    # Nom simplifié
    entity_name = case_when(
      str_detect(country, " - ") ~ str_extract(country, "[^-]+$"),
      TRUE ~ country
    )
  )

cat("   Entités TePaske :", nrow(tepaske_entities), "\n")

# 2. Catégorisation des entités
cat("\n2. Catégorisation...\n")

entity_categories <- combined_data %>%
  distinct(country) %>%
  arrange(country) %>%
  mutate(
    category = case_when(
      # Global
      country %in% c("World", "World total") ~ "global",
      
      # Continents
      country %in% c("Africa", "Asia", "Europe", "North America", "South America", 
                     "Australasia", "Central America & West Indies", "Other Africa") ~ "continent",
      
      # États américains (Craig)
      country %in% c("Alabama", "Alaska", "Arizona", "California", "Colorado", 
                     "Georgia", "Idaho", "Maryland", "Michigan", "Montana", 
                     "Nevada", "New Mexico", "North Carolina", "Oregon", 
                     "Pennsylvania", "South Carolina", "South Dakota", 
                     "Tennessee", "Texas", "Utah", "Vermont", "Virginia", 
                     "Washington", "Wyoming") ~ "us_state",
      
      # Colonies historiques
      str_detect(country, "British|French|Dutch|Portuguese|German|Belgian") & 
        !str_detect(country, "India|East Indies|West Africa") ~ "colony",
      
      # Entités historiques
      country %in% c("Transvaal", "Rhodesia", "Siam", "Chosen", "Tanganyika", 
                     "Czechoslovakia", "Yugoslavia", "Soviet Union", 
                     "German Democratic Rep", "German Federal Republic",
                     "Serbia and Montenegro", "Union South Africa",
                     "Abyssinia") ~ "historical",
      
      # TePaske : régions historiques (niveau 1)
      str_detect(country, "^Latine America 1493 1810 - ") & 
        !str_detect(country, " - ") ~ "historical_region",
      
      # TePaske : détails (niveau 2) - garder comme pays historiques
      str_detect(country, "^Mexico 1521 1810 - ") ~ "historical_state",
      str_detect(country, "^Peru 1531 1810 - ") ~ "historical_state",
      str_detect(country, "^Brazil 1691 1810 - ") ~ "historical_state",
      str_detect(country, "^South America 1533 1810 - ") ~ "historical_state",
      str_detect(country, "^Carribean 1493 1555 - ") ~ "historical_state",
      
      # TePaske : autres
      str_detect(country, "^Latine America|^Mexico|^Peru|^Brazil|^South America|^Carribean") ~ "historical_region",
      
      # Pays modernes (par défaut)
      TRUE ~ "country"
    ),
    
    # Nom moderne
    modern_name = case_when(
      # TePaske mapping
      country %in% c("Latine America 1493 1810 - mexico", "Mexico 1521 1810 - caja_mexico") ~ "Mexico",
      country %in% c("Latine America 1493 1810 - peru", "Peru 1531 1810 - caja_lima") ~ "Peru",
      country %in% c("Latine America 1493 1810 - brazil", "Brazil 1691 1810 - minas_gerais") ~ "Brazil",
      country %in% c("Latine America 1493 1810 - new granada") ~ "Colombia",
      country %in% c("Latine America 1493 1810 - chile", "South America 1533 1810 - chile") ~ "Chile",
      country %in% c("Latine America 1493 1810 - ecuador", "South America 1533 1810 - ecuador") ~ "Ecuador",
      country %in% c("Latine America 1493 1810 - carribean", "Carribean 1493 1555 - cuba") ~ "Caribbean",
      str_detect(country, "Latine America 1493 1810 - other") ~ "Other",
      # États historiques
      country == "Union South Africa" ~ "South Africa",
      country == "Transvaal" ~ "South Africa",
      country == "Rhodesia" ~ "Zimbabwe",
      country == "British Guiana" ~ "Guyana",
      country == "Dutch Guiana" ~ "Suriname",
      country == "French Guiana" ~ "French Guiana",
      country == "British India" ~ "India",
      country == "Dutch East Indies" ~ "Indonesia",
      country == "British East Indies" ~ "Malaysia",
      country == "Indo-China" ~ "Vietnam",
      country == "Chosen" ~ "South Korea",
      country == "Siam" ~ "Thailand",
      country == "Tanganyika" ~ "Tanzania",
      country == "Czechoslovakia" ~ "Czech Republic",
      country == "Yugoslavia" ~ "Serbia",
      country == "Soviet Union" ~ "Russia",
      country == "German Democratic Rep" ~ "Germany",
      country == "German Federal Republic" ~ "Germany",
      country == "Serbia and Montenegro" ~ "Serbia",
      country == "Belgian Congo" ~ "Democratic Republic of Congo",
      country == "British West Africa" ~ "Ghana",
      country == "French West Africa" ~ "Mali",
      country == "German East Africa" ~ "Tanzania",
      country == "Portugese East Africa" ~ "Mozambique",
      country == "Abyssinia" ~ "Ethiopia",
      TRUE ~ country
    ),
    
    # Continent
    continent = case_when(
      country %in% c("Africa", "Algeria", "Angola", "Benin", "Botswana", "Burkina Faso",
                     "Burundi", "Cameroon", "Central African Republic", "Chad", "Congo",
                     "Congo, DRC", "Congo, Democratic Republic", "Cote d'Ivoire",
                     "Egypt", "Equatorial Guinea", "Eritrea", "Eswatini", "Ethiopia",
                     "Gabon", "Ghana", "Guinea", "Ivory Coast", "Kenya", "Liberia",
                     "Madagascar", "Mali", "Mauritania", "Morocco", "Mozambique",
                     "Namibia", "Niger", "Nigeria", "Rwanda", "Senegal", "Sierra Leone",
                     "South Africa", "South Sudan", "Sudan", "Tanzania", "Togo",
                     "Uganda", "Zaire", "Zambia", "Zimbabwe",
                     "Union South Africa", "Transvaal", "Rhodesia", "Belgian Congo",
                     "British West Africa", "French West Africa", "German East Africa",
                     "Portugese East Africa", "Tanganyika", "Abyssinia",
                     "Other Africa") ~ "Africa",
      
      country %in% c("Asia", "China", "India", "Japan", "Korea", "Mongolia",
                     "Myanmar", "Philippines", "Siam", "Taiwan", "Thailand",
                     "Vietnam", "British India", "Dutch East Indies",
                     "British East Indies", "Indo-China", "Chosen",
                     "Malaysia", "Indonesia") ~ "Asia",
      
      country %in% c("Europe", "France", "Germany", "Great Britain", "Greece",
                     "Italy", "Norway", "Portugal", "Romania", "Russia",
                     "Serbia", "Spain", "Sweden", "Turkey", "Ukraine",
                     "United Kingdom", "Austria-Hungary", "Czechoslovakia",
                     "Yugoslavia", "Soviet Union", "German Democratic Rep",
                     "German Federal Republic", "Serbia and Montenegro",
                     "Poland", "Hungary", "Bulgaria") ~ "Europe",
      
      country %in% c("North America", "United States", "Canada", "Mexico",
                     "Alabama", "Alaska", "Arizona", "California", "Colorado",
                     "Georgia", "Idaho", "Maryland", "Michigan", "Montana",
                     "Nevada", "New Mexico", "North Carolina", "Oregon",
                     "Pennsylvania", "South Carolina", "South Dakota",
                     "Tennessee", "Texas", "Utah", "Vermont", "Virginia",
                     "Washington", "Wyoming",
                     "Mexico 1521 1810 - caja_", "Latine America 1493 1810 - mexico") ~ "North America",
      
      country %in% c("South America", "Argentina", "Bolivia", "Brazil", "Chile",
                     "Colombia", "Ecuador", "Peru", "Uruguay", "Venezuela",
                     "British Guiana", "Dutch Guiana", "French Guiana",
                     "Guyana", "Suriname",
                     "Latine America 1493 1810 - peru", "Peru 1531 1810 - caja_",
                     "Brazil 1691 1810 - ", "South America 1533 1810 - ",
                     "Latine America 1493 1810 - new granada",
                     "Latine America 1493 1810 - chile",
                     "Latine America 1493 1810 - ecuador",
                     "Latine America 1493 1810 - other") ~ "South America",
      
      country %in% c("Australasia", "Australia", "New Zealand") ~ "Oceania",
      
      TRUE ~ "Other"
    ),
    
    # Source principale
    main_source = map_chr(country, function(c) {
      src <- combined_data %>%
        filter(country == c) %>%
        count(source, sort = TRUE) %>%
        pull(source) %>%
        first()
      return(src)
    })
  )

# 3. Ajouter les catégories aux données
cat("\n3. Ajout des catégories aux données...\n")

combined_data <- combined_data %>%
  left_join(
    entity_categories %>% select(country, category, modern_name, continent, main_source),
    by = "country"
  )

# 4. Sauvegarder
cat("\n4. Sauvegarde...\n")
save(combined_data, file = "fusion/all_sources.rda")
write_csv(combined_data, "fusion/all_sources.csv")

# 5. Résumé
cat("\n5. Résumé des catégories :\n")
summary <- combined_data %>%
  group_by(category) %>%
  summarise(
    n_entities = n_distinct(country),
    n_observations = n(),
    production_total = round(sum(production_kg, na.rm = TRUE), 0),
    .groups = "drop"
  ) %>%
  arrange(desc(production_total))

print(summary)

# 6. Export du dictionnaire
entity_categories %>%
  write_csv("outputs/entity_dictionary.csv")
cat("\n   Dictionnaire : outputs/entity_dictionary.csv\n")

cat("\n--- CATEGORISATION TERMINEE ---\n")