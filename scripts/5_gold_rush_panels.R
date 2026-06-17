# ============================================================================
# scripts/5_gold_rush_panels.R
# Planche avec grille adaptative
# ============================================================================

source("scripts/0_setup.R")
library(patchwork)

all_entities <- readRDS("data/processed/gold_production_all_entities.rds")
all_events <- readRDS("data/processed/gold_rush_detected.rds")

cat("Événements à visualiser:", nrow(all_events), "\n")

create_event_plot <- function(event_row, all_data) {
  
  plot_data <- all_data %>%
    filter(entity == event_row$entity, parent == event_row$parent,
           year >= event_row$start_year - 15, year <= event_row$end_year + 15) %>%
    arrange(year)
  
  if(nrow(plot_data) == 0) return(NULL)
  
  mean_before <- mean(plot_data$production_tonnes[plot_data$year < event_row$start_year], na.rm = TRUE)
  
  bar_color <- ifelse(event_row$type == "Rush (pic aigu)", "gold", "lightblue")
  
  ggplot(plot_data, aes(x = year, y = production_tonnes)) +
    annotate("rect", xmin = event_row$start_year, xmax = event_row$end_year, 
             ymin = -Inf, ymax = Inf, alpha = 0.3, fill = bar_color) +
    geom_line(color = "steelblue", linewidth = 1.2) +
    geom_point(size = 1.2) +
    geom_point(data = subset(plot_data, year == event_row$peak_year), 
               color = "red", size = 4, shape = 18) +
    geom_hline(yintercept = mean_before, linetype = "dashed", color = "gray40", alpha = 0.7) +
    labs(title = paste0(event_row$entity, " (", event_row$parent, ")"),
         subtitle = paste(event_row$type, "| Pic:", round(event_row$peak_production, 1), "t/an | Durée:", event_row$duration, "ans"),
         x = "Année", y = "Tonnes") +
    theme_minimal() +
    theme(plot.title = element_text(size = 9, face = "bold"),
          plot.subtitle = element_text(size = 7),
          axis.title = element_text(size = 7),
          axis.text = element_text(size = 6))
}

# Génération des graphiques
dir.create("outputs/figures/rush_panels", showWarnings = FALSE, recursive = TRUE)

event_plots <- list()
for(i in 1:nrow(all_events)) {
  p <- create_event_plot(all_events[i, ], all_entities)
  if(!is.null(p)) {
    event_plots[[i]] <- p
    ggsave(paste0("outputs/figures/rush_panels/", 
                  gsub(" ", "_", all_events$entity[i]), "_", 
                  gsub(" ", "_", all_events$type[i]), ".png"), 
           p, width = 7, height = 4)
    cat("✓", i, "-", all_events$entity[i], "(", all_events$type[i], ")\n")
  }
}

# Planche avec grille adaptative
if(length(event_plots) > 0) {
  
  # Calculer les dimensions de la grille
  n_plots <- length(event_plots)
  n_cols <- 4
  n_rows <- ceiling(n_plots / n_cols)
  
  cat("\nGrille:", n_rows, "lignes x", n_cols, "colonnes =", n_rows * n_cols, "places\n")
  
  # Créer la planche
  planche <- wrap_plots(event_plots, ncol = n_cols) +
    plot_annotation(title = "Ruées et booms miniers (37 événements)",
                    subtitle = "Fond jaune = pic aigu (rush) | Fond bleu = plateau durable (boom)")
  
  # Sauvegarde avec hauteur adaptée
  height_plot <- 4 + (n_rows - 5) * 3  # Ajustement dynamique
  ggsave("outputs/figures/gold_rush_planche.png", planche, 
         width = 16, height = max(20, height_plot), limitsize = FALSE)
  
  cat("✓ Planche: outputs/figures/gold_rush_planche.png (", n_plots, "graphiques)\n")
  
  # Version PDF
  ggsave("outputs/figures/gold_rush_planche.pdf", planche, 
         width = 16, height = max(20, height_plot), limitsize = FALSE)
  cat("✓ PDF: outputs/figures/gold_rush_planche.pdf\n")
}

cat("\n5_gold_rush_panels.R exécuté\n")