#!/usr/local/bin/Rscript --vanilla
library(readr)

#MISTy
#remotes::install_github("saezlab/mistyR@devel")
library(mistyR)
library(future)

# data manipulation
library(dplyr)
library(purrr)
library(distances)

# plotting
library(ggplot2)

# multisession
plan(multisession)

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

###### load data #####
data <- read_csv(args[1])
markers <- read_csv(args[2])
results.folder <- args[3]
output <- args[4]


# Filter data
expr <- data %>% select(markers$marker_name[markers$misty == "x"][!is.na(markers$marker_name[markers$misty == "x"])]) #select cant handle NA!!!!!
colnames(expr) <-  sub("-", "_", colnames(expr))
pos <- data %>% select(X_centroid, Y_centroid)

#generating views 
misty.intra <- create_initial_view(expr)
misty.views <- misty.intra %>% add_paraview(pos, l = 10) ##### possible parameter to give to users, lets you adjust the approximation, will speed up computation. See ?add_paraview() #, approx = 1 #####
misty.views <- misty.views %>% add_juxtaview(pos) ##### possible parameter to give to users, lets you adjust the approximation, will speed up computation. See ?add_juxtaview() #, neighbor.thr = ?? #####


#running misty
misty.results <-misty.views %>% run_misty(results.folder = results.folder) %>%
  collect_results()

# Plot gain R2
pdf(paste0(output, "/gain_R2.pdf"))
misty.results %>%
        plot_improvement_stats("gain.R2")
dev.off()

# Plot gain RMSE
pdf(paste0(output, "/gain_RMSE.pdf"))
misty.results %>%
        plot_improvement_stats("gain.RMSE")
dev.off()

# Plot contributions
pdf(paste0(output, "/contributions.pdf"))
misty.results %>% plot_view_contributions()
dev.off()

# Plot result plots for all views:
# Interaction heatmap
for (i in 1:length(unique(misty.results$importances$view))) {
  pdf(paste0(output, "/interaction_heatmap_", 
             sub(".", "_", unique(misty.results$importances$view)[i],fixed = TRUE),
             ".pdf"))
  misty.results %>% 
          plot_interaction_heatmap(view = unique(misty.results$importances$view)[i])
  dev.off()
}

# Contrast heatmap
for (i in 2:length(unique(misty.results$importances$view))) {
  pdf(paste0(output, "/contrast_heatmap_intra_", 
             sub(".", "_", unique(misty.results$importances$view)[i],fixed = TRUE),
             ".pdf"))
  misty.results %>% 
          plot_contrast_heatmap("intra", unique(misty.results$importances$view)[i])
  dev.off()
}

# Interaction communites
for (i in 1:length(unique(misty.results$importances$view))) {
  pdf(paste0(output, "/interaction_communities_", 
             sub(".", "_", unique(misty.results$importances$view)[i],fixed = TRUE),
             ".pdf"))
  misty.results %>% 
          plot_interaction_communities(view = unique(misty.results$importances$view)[i])
  dev.off()
}
