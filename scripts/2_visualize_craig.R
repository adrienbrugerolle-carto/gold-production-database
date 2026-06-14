# ============================================================================
# 2_visualize_craig.R
# Visualisation des donnees Craig & Rimstidt (1998)
# Production d'or aux Etats-Unis (1804-1995)
# ============================================================================

# ----------------------------------------------------------------------------
# 1. Preparation
# ----------------------------------------------------------------------------

source("scripts/0_setup.R")

# Lecture des donnees propres
craig_states <- readRDS(here("data", "processed", "craig_states.rds"))

# ----------------------------------------------------------------------------
# 2. Production totale US par an
# ----------------------------------------------------------------------------

total_us <- craig_states %>%
  group_by(year) %>%
  summarise(production_oz = sum(production_oz, na.rm = TRUE), .groups = "drop")

# Graphique 1 : Production totale US (1804-1995)
p1 <- ggplot(total_us, aes(x = year, y = production_oz)) +
  geom_line(color = "#D4AF37", size = 0.8) +
  labs(
    title = "Production d'or aux Etats-Unis (1804-1995)",
    subtitle = "Source: Craig & Rimstidt (1998)",
    x = "Annee",
    y = "Production (onces troy)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

ggsave(here("outputs", "figures", "us_total_production.png"), p1, width = 10, height = 6)

message("Graphique 1 sauvegarde : us_total_production.png")

# ----------------------------------------------------------------------------
# 3. Production par etat (top 5)
# ----------------------------------------------------------------------------

# Identifier les 5 etats les plus producteurs
top5_states <- craig_states %>%
  group_by(state) %>%
  summarise(total = sum(production_oz, na.rm = TRUE)) %>%
  arrange(desc(total)) %>%
  slice(1:5) %>%
  pull(state)

message("Top 5 etats producteurs : ", paste(top5_states, collapse = ", "))

# Filtrer les donnees pour ces 5 etats
top5_data <- craig_states %>%
  filter(state %in% top5_states)

# Graphique 2 : Production des 5 principaux etats
p2 <- ggplot(top5_data, aes(x = year, y = production_oz, color = state)) +
  geom_line(size = 0.7) +
  labs(
    title = "Production d'or par etat (top 5)",
    subtitle = "Source: Craig & Rimstidt (1998)",
    x = "Annee",
    y = "Production (onces troy)",
    color = "Etat"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  ) +
  scale_color_manual(values = c("#D4AF37", "#B8860B", "#CD7F32", "#8B7355", "#A0522D"))

ggsave(here("outputs", "figures", "top5_states_production.png"), p2, width = 10, height = 6)

message("Graphique 2 sauvegarde : top5_states_production.png")

# ----------------------------------------------------------------------------
# 4. Production de la Californie et du Nevada (comparaison)
# ----------------------------------------------------------------------------

ca_nv_data <- craig_states %>%
  filter(state %in% c("California", "Nevada"))

p3 <- ggplot(ca_nv_data, aes(x = year, y = production_oz, color = state)) +
  geom_line(size = 0.8) +
  labs(
    title = "Production d'or : Californie vs Nevada",
    subtitle = "Source: Craig & Rimstidt (1998)",
    x = "Annee",
    y = "Production (onces troy)",
    color = "Etat"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    legend.position = "bottom"
  )

ggsave(here("outputs", "figures", "california_vs_nevada.png"), p3, width = 10, height = 6)

message("Graphique 3 sauvegarde : california_vs_nevada.png")

# ----------------------------------------------------------------------------
# 5. Heatmap de production par decennie
# ----------------------------------------------------------------------------

decade_data <- craig_states %>%
  mutate(decade = floor(year / 10) * 10) %>%
  group_by(decade, state) %>%
  summarise(production_oz = sum(production_oz, na.rm = TRUE), .groups = "drop") %>%
  filter(!is.na(decade))

# Top 12 etats pour le heatmap
top12_states <- decade_data %>%
  group_by(state) %>%
  summarise(total = sum(production_oz)) %>%
  arrange(desc(total)) %>%
  slice(1:12) %>%
  pull(state)

decade_filtered <- decade_data %>%
  filter(state %in% top12_states)

p4 <- ggplot(decade_filtered, aes(x = decade, y = reorder(state, desc(state)), fill = production_oz)) +
  geom_tile() +
  scale_fill_gradient(low = "#FFF8DC", high = "#D4AF37", trans = "log10", 
                      name = "Production (onces)", labels = scales::comma) +
  labs(
    title = "Production d'or par decennie et par etat (top 12)",
    subtitle = "Source: Craig & Rimstidt (1998) - Echelle logarithmique",
    x = "Decennie",
    y = "Etat"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(here("outputs", "figures", "decade_heatmap.png"), p4, width = 12, height = 8)

message("Graphique 4 sauvegarde : decade_heatmap.png")

# ----------------------------------------------------------------------------
# 6. Message final
# ----------------------------------------------------------------------------

message("\n========================================")
message("Visualisations generees avec succes")
message("Dossier de sortie : ", dir_figures)
message("Fichiers crees :")
message("  - us_total_production.png")
message("  - top5_states_production.png")
message("  - california_vs_nevada.png")
message("  - decade_heatmap.png")
message("========================================")