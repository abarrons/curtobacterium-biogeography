# =============================================================================
# Colors, palettes, and ggplot theme used throughout the analysis
# =============================================================================

reserve_colors <- c(
  "#CBD588", "#5F7FC7", "#FFA500","#DA5724", "#CD9BCD", 
  "#AD6F3B", "#673770","#D14285", "#652926", "#C84248", 
  "#8569D5", "#FFC0CB", "#8A7C64",
  "#0000FF", "#483D8B", "#ADD8E6", "#008B8B", "#8B6508", "#8B0000",
  "#006400", "#D1A33D", "#8B4500", "#A020F0", "#FA8072")

colors <- c(
  "#CBD588", "#5F7FC7", "orange","#DA5724", "#508578", 
  "#AD6F3B", "#673770", "#CD9BCD", "#D14285", "#652926", "#C84248", 
  "#8569D5", "#5E738F","#D1A33D", "#009ACD", "#8A7C64", "#599861", "red",
  "blue", "black", "darkgoldenrod4", "darkcyan", "gray", "#7ECFE8", "yellow", "#8B0000" ,"#006400", "#ADD8E6",
  "#A020F0", "#FFC0CB", "#483D8B","#8B4500", "#FA8072", "#00A400", "#7171FF",  "#B0B038", "#00FF36", "#FF69B4",
  "#CAFF70", "#CD6600", "#B4EEB4","#104E8B", "#E6E6FA")

ecosystem_colors <- c(
  "Oak Woodland" = "#8B5A2B",
  "Desert" = "#B7410E",
  "Coastal Marine" = "#1E6091",
  "Chaparral" = "#6B8E23",
  "Conifer Forest" = "#2E8B57",
  "Grassland" = "#DAA520",
  "Montane" = "#778899"
)

# Climate variable color palettes (underscore-named keys)
clim_palette <- c(
  "MAT" = "#FF6666",
  "T_Iso" = "#FF9999",
  "T_Diurn" = "#FF0000",
  "T_Seas" = "#FFA07A",
  "T_MaxWarmMo" = "#FF7F50",
  "T_Range" = "#DC143C",
  "T_WetQ" = "#8B0A50",
  "T_DryQ" = "#CC0000",
  "T_WarmQ" = "#B22222",
  "T_MinColdMo" = "#990000",
  "T_ColdQ" = "#CD5C5C",
  "MAP" = "#66CCFF",
  "P_WetMo" = "#104E8B",
  "P_DryMo" = "#3399FF",
  "P_WetQ" = "#00688B",
  "P_DryQ" = "#ADD8E6",
  "P_WarmQ" = "#0066CC",
  "P_ColdQ" = "#87CEFA",
  "P_Seas" = "#003399"
)

# Keep legacy name used in original code
clim_pallete <- clim_palette

# Space-named climate palette (used in sections with space-separated variable names)
clim_pallete3 <- c(
  "MAT" = "#FF6666",
  "T Iso" = "#FF9999",
  "T Diurn" = "#FF0000",
  "T Seas" = "#FFA07A",
  "T MaxWarmMo" = "#FF7F50",
  "T Range" = "#DC143C",
  "T WetQ" = "#8B0A50",
  "T DryQ" = "#CC0000",
  "T WarmQ" = "#B22222",
  "T MinColdMo" = "#990000",
  "T ColdQ" = "#CD5C5C",
  "MAP" = "#66CCFF",
  "P WetMo" = "#104E8B",
  "P DryMo" = "#3399FF",
  "P WetQ" = "#00688B",
  "P DryQ" = "#ADD8E6",
  "P WarmQ" = "#0066CC",
  "P ColdQ" = "#87CEFA",
  "P Seas" = "#003399"
)

# All-variable palette: climate (underscore) + litter + PC axes (space-named litter)
allvars_pallete <- c(clim_palette,
  "cellulose" = "#8B4513",
  "crude protein" = "#D2691E",
  "hemicellulose" = "#F4A460",
  "lignin" = "#FFD700",
  "pH" = "black",
  "PC1" = "#E066FF",
  "PC2" = "#AB82FF",
  "PC1 litt" = "#F4A460",
  "PC2 litt" = "#8B4C39")

# Space-named all-variable palette (for sections with space-separated names)
allvars_pallete3 <- c(clim_pallete3,
  "cellulose" = "#8B4513",
  "crude protein" = "#D2691E",
  "hemicellulose" = "#F4A460",
  "lignin" = "#FFD700",
  "pH" = "black",
  "PC1" = "#E066FF",
  "PC2" = "#AB82FF",
  "PC1 litt" = "#F4A460",
  "PC2 litt" = "#8B4C39")

# Underscore litter names (used in dbRDA/PDP sections that refer to crude_protein)
allvars_pallete_4 <- c(clim_palette,
  "cellulose" = "#8B4513",
  "crude_protein" = "#D2691E",
  "hemicellulose" = "#F4A460",
  "lignin" = "#FFD700",
  "pH" = "black",
  "PC1" = "#E066FF",
  "PC2" = "#AB82FF",
  "PC1 litt" = "#F4A460",
  "PC2 litt" = "#8B4C39")

# Used in dbRDA and PDP sections with space-separated climate PCs
allvars_pallete_2 <- c(clim_palette,
  "cellulose" = "#8B4513",
  "crude protein" = "#D2691E",
  "hemicellulose" = "#F4A460",
  "lignin" = "#FFD700",
  "pH" = "black",
  "PC1 clim" = "#E066FF",
  "PC2 clim" = "#AB82FF",
  "PC1 litt" = "#F4A460",
  "PC2 litt" = "#8B4C39")

# ggplot2 theme
apatheme <- theme_minimal(base_size = 10) +
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        axis.line = element_line(),
        text = element_text(family = "Arial"),
        axis.title = element_text(size = 12),
        axis.text = element_text(size = 10),
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 11),
        strip.text = element_text(size = 12))
