#' SlothBiomass: Interactive Fossil Data Explorer
#'
#' Spatiotemporal visualization of vegetation proxies and megafauna
#' occurrences for Western Amazonia case study.
#'
#' Displays:
#' - Megafauna fossil localities (PBDB)
#' - Pollen/vegetation proxy sites (Neotoma/LAPD)
#' - Time filtering by age/SALMA
#' - Taxon-level information on click

library(shiny)
library(leaflet)
library(DT)
library(plotly)
library(dplyr)
library(sf)
library(httr)
library(jsonlite)

# Null-coalescing operator
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# ============================================================================
# DATA LOADING FUNCTIONS
# ============================================================================

#' Query PBDB for South American megafauna
query_pbdb_megafauna <- function() {
  message("Querying PBDB for megafauna occurrences...")

  # Try to load cached data first
  cache_file <- "data/pbdb_megafauna_cache.rds"
  if (file.exists(cache_file)) {
    message("  Loading from cache...")
    return(readRDS(cache_file))
  }

  # Query PBDB API using JSON format with httr
  base_url <- "https://paleobiodb.org/data1.2/occs/list.json"

  # Key megafauna taxa
  taxa <- c("Xenarthra", "Notoungulata", "Litopterna", "Proboscidea")

  # South America bounding box
  bbox <- "&lngmin=-82&lngmax=-34&latmin=-56&latmax=15"

  all_occs <- data.frame()

  for (taxon in taxa) {
    url <- paste0(base_url,
                  "?base_name=", taxon,
                  bbox,
                  "&max_ma=30&min_ma=0",  # Cenozoic megafauna (Miocene-Holocene)
                  "&show=coords,class,loc,strat,ref",  # Include reference info
                  "&limit=500")

    tryCatch({
      resp <- httr::GET(url, httr::timeout(30))
      if (httr::status_code(resp) == 200) {
        content <- httr::content(resp, "text", encoding = "UTF-8")
        json <- jsonlite::fromJSON(content, flatten = TRUE)
        if (!is.null(json$records) && length(json$records) > 0) {
          occs <- as.data.frame(json$records)
          occs$query_taxon <- taxon
          all_occs <- bind_rows(all_occs, occs)
          message("  ", taxon, ": ", nrow(occs), " occurrences")
        }
      }
      Sys.sleep(0.3)
    }, error = function(e) {
      message("  Error querying ", taxon, ": ", e$message)
    })
  }

  if (nrow(all_occs) > 0) {
    # Clean coordinates and standardize column names
    # PBDB abbreviations: tna=taxon_name, eag=early_age, lag=late_age,
    # fml=family, odl=order, gnl=genus, cll=class
    # ggc=geographic_comments, cc2=country_code, oei=interval, ref=reference, rid=ref_id

    # Add missing columns with defaults before mutate
    if (!"fml" %in% names(all_occs)) all_occs$fml <- NA_character_
    if (!"odl" %in% names(all_occs)) all_occs$odl <- all_occs$query_taxon
    if (!"gnl" %in% names(all_occs)) all_occs$gnl <- NA_character_
    if (!"ggc" %in% names(all_occs)) all_occs$ggc <- NA_character_
    if (!"cc2" %in% names(all_occs)) all_occs$cc2 <- NA_character_
    if (!"oei" %in% names(all_occs)) all_occs$oei <- NA_character_
    if (!"ref" %in% names(all_occs)) all_occs$ref <- NA_character_
    if (!"rid" %in% names(all_occs)) all_occs$rid <- NA_character_

    all_occs <- all_occs %>%
      mutate(
        lng = as.numeric(lng),
        lat = as.numeric(lat),
        max_ma = as.numeric(eag),
        min_ma = as.numeric(lag),
        age_ma = (max_ma + min_ma) / 2,
        age_ka = age_ma * 1000,
        accepted_name = tna,
        family = fml,
        order_name = odl,
        genus = gnl,
        locality = ggc,
        country_code = cc2,
        interval = oei,
        reference = ref,
        ref_id = gsub("ref:", "", rid),
        # Create PBDB link for reference
        pbdb_ref_url = paste0("https://paleobiodb.org/classic/basicRefInfo?reference_no=", ref_id),
        pbdb_occ_url = paste0("https://paleobiodb.org/classic/basicCollectionSearch?occurrence_no=", gsub("occ:", "", oid))
      ) %>%
      filter(!is.na(lng) & !is.na(lat))

    # Cache results
    dir.create("data", showWarnings = FALSE)
    saveRDS(all_occs, cache_file)
    message("  Cached ", nrow(all_occs), " occurrences")
  }

  return(all_occs)
}

#' Query Neotoma for vegetation proxy sites
query_neotoma_vegetation <- function() {
  message("Querying Neotoma for vegetation sites...")

  cache_file <- "data/neotoma_vegetation_cache.rds"
  if (file.exists(cache_file)) {
    message("  Loading from cache...")
    return(readRDS(cache_file))
  }

  # Try neotoma2 package if available
  if (requireNamespace("neotoma2", quietly = TRUE)) {
    tryCatch({
      # Query sites in South America
      sites <- neotoma2::get_sites(
        loc = sf::st_bbox(c(xmin = -82, ymin = -25, xmax = -44, ymax = 12), crs = 4326)
      )
      datasets <- neotoma2::get_datasets(sites, datasettype = "pollen")

      if (length(datasets) > 0) {
        site_info <- neotoma2::sites(datasets)
        df <- data.frame(
          siteid = site_info$siteid,
          sitename = site_info$sitename,
          lat = site_info$lat,
          lng = site_info$long,
          altitude = site_info$altitude,
          stringsAsFactors = FALSE
        )
        df <- df[!is.na(df$lat) & !is.na(df$lng), ]
        message("  Found ", nrow(df), " Neotoma pollen sites")

        if (nrow(df) > 0) {
          dir.create("data", showWarnings = FALSE)
          saveRDS(df, cache_file)
        }
        return(df)
      }
    }, error = function(e) {
      message("  neotoma2 query failed: ", e$message)
    })
  }

  # Fallback: return empty data frame (sample data will be used)
  message("  Using sample vegetation data...")
  return(data.frame())
}

#' Create sample data for demonstration
create_sample_data <- function() {

  # Sample megafauna occurrences (based on real PBDB data patterns)
  megafauna <- data.frame(
    oid = 1:25,
    accepted_name = c(
      "Eremotherium laurillardi", "Eremotherium laurillardi",
      "Glossotherium robustum", "Glossotherium robustum",
      "Notiomastodon platensis", "Notiomastodon platensis", "Notiomastodon platensis",
      "Toxodon platensis", "Toxodon platensis",
      "Glyptodon clavipes", "Glyptodon clavipes",
      "Megatherium americanum",
      "Mixotoxodon larensis",
      "Cuvieronius hyodon",
      "Holmesina occidentalis",
      "Pampatherium humboldti",
      "Scelidotherium leptocephalum",
      "Lestodon armatus",
      "Macrauchenia patachonica",
      "Hippidion principale",
      "Neochoerus sulcidens",
      "Palaeolama major",
      "Hemiauchenia paradoxa",
      "Stegomastodon waringi",
      "Haplomastodon waringi"
    ),
    family = c(
      rep("Megatheriidae", 2), rep("Mylodontidae", 2),
      rep("Gomphotheriidae", 3), rep("Toxodontidae", 2),
      rep("Glyptodontidae", 2), "Megatheriidae",
      "Toxodontidae", "Gomphotheriidae", "Pampatheriidae",
      "Pampatheriidae", "Mylodontidae", "Mylodontidae",
      "Macraucheniidae", "Equidae", "Hydrochoeridae",
      "Camelidae", "Camelidae", "Gomphotheriidae", "Gomphotheriidae"
    ),
    order_name = c(
      rep("Pilosa", 4), rep("Proboscidea", 3), rep("Notoungulata", 2),
      rep("Cingulata", 2), "Pilosa", "Notoungulata", "Proboscidea",
      rep("Cingulata", 2), rep("Pilosa", 2), "Litopterna", "Perissodactyla",
      "Rodentia", rep("Artiodactyla", 2), rep("Proboscidea", 2)
    ),
    lng = c(
      -69.5, -71.2, -58.5, -56.8, -70.1, -65.3, -48.5,
      -58.2, -54.1, -59.3, -57.8, -65.4, -72.5, -68.9,
      -71.8, -62.5, -58.9, -56.2, -57.4, -64.8,
      -55.3, -67.2, -60.1, -46.5, -43.2
    ),
    lat = c(
      -12.5, -15.8, -34.2, -32.5, -13.2, -17.8, -22.5,
      -33.5, -31.2, -34.8, -33.1, -16.5, -8.5, -14.2,
      -11.5, -28.5, -35.2, -34.8, -33.9, -18.5,
      -29.8, -10.5, -25.3, -19.8, -22.5
    ),
    min_ma = c(
      0.012, 0.015, 0.011, 0.013, 0.018, 0.014, 0.020,
      0.012, 0.015, 0.011, 0.014, 0.016, 0.025, 0.022,
      0.030, 0.012, 0.011, 0.013, 0.012, 0.018,
      0.015, 0.035, 0.020, 0.025, 0.028
    ),
    max_ma = c(
      0.126, 0.130, 0.126, 0.130, 0.500, 0.250, 0.780,
      0.126, 0.250, 0.126, 0.250, 0.500, 2.500, 1.800,
      2.500, 0.126, 0.126, 0.130, 0.126, 0.500,
      0.250, 3.600, 1.800, 2.500, 2.500
    ),
    formation = c(
      "Madre de Dios Fm", "Ipururo Fm", "Lujan Fm", "Lujan Fm",
      "Madre de Dios Fm", "Tarija Fm", "Lagoa Santa",
      "Lujan Fm", "Lujan Fm", "Lujan Fm", "Lujan Fm",
      "Tarija Fm", "Urumaco Fm", "Tarija Fm",
      "Solimões Fm", "Lujan Fm", "Lujan Fm", "Lujan Fm",
      "Lujan Fm", "Tarija Fm", "Lujan Fm", "Madre de Dios Fm",
      "Tarija Fm", "Lagoa Santa", "Lagoa Santa"
    ),
    country = c(
      "Peru", "Peru", "Argentina", "Argentina", "Peru", "Bolivia", "Brazil",
      "Argentina", "Argentina", "Argentina", "Argentina", "Bolivia",
      "Venezuela", "Bolivia", "Brazil", "Argentina", "Argentina",
      "Argentina", "Argentina", "Bolivia", "Argentina", "Peru",
      "Bolivia", "Brazil", "Brazil"
    ),
    stringsAsFactors = FALSE
  )

  megafauna$age_ma <- (megafauna$min_ma + megafauna$max_ma) / 2
  megafauna$age_ka <- megafauna$age_ma * 1000
  megafauna$body_mass_kg <- c(
    5000, 5000, 1500, 1500, 6000, 6000, 6000,
    1400, 1400, 1800, 1800, 4000, 1200, 4500,
    250, 180, 800, 2500, 950, 400,
    100, 250, 120, 5500, 5500
  )
  megafauna$guild <- ifelse(megafauna$order_name == "Proboscidea", "megaherbivore",
                            ifelse(megafauna$body_mass_kg > 1000, "megaherbivore", "mesoherbivore"))

  # Sample pollen/vegetation sites with DOI links and detailed taxa

  # Key pollen taxa recorded at each site (based on published records)
  pollen_taxa <- list(
    # Lake Titicaca - Puna grassland
    `1` = list(
      arboreal = c("Polylepis", "Alnus", "Podocarpus"),
      herbs = c("Poaceae", "Asteraceae", "Chenopodiaceae", "Plantago", "Azorella"),
      aquatic = c("Isoetes", "Myriophyllum"),
      key_changes = "Polylepis expansion 3-5 ka; grass-dominated LGM"
    ),
    # Laguna Chaplin - Savanna-forest ecotone
    `2` = list(
      arboreal = c("Moraceae/Urticaceae", "Cecropia", "Alchornea", "Celtis", "Astronium"),
      herbs = c("Poaceae", "Cyperaceae", "Asteraceae", "Curatella"),
      aquatic = c("Mauritia", "Cyperaceae"),
      key_changes = "Forest expansion Holocene; savanna LGM-deglacial"
    ),
    # Lake Pata - Terra firme forest
    `3` = list(
      arboreal = c("Moraceae/Urticaceae", "Sapotaceae", "Melastomataceae", "Myrtaceae", "Euphorbiaceae", "Arecaceae"),
      herbs = c("Poaceae", "Asteraceae"),
      aquatic = c("Cyperaceae"),
      key_changes = "Stable forest throughout; minimal LGM change"
    ),
    # Laguna Bella Vista - Seasonally dry forest
    `4` = list(
      arboreal = c("Anadenanthera", "Astronium", "Gallesia", "Celtis", "Acacia"),
      herbs = c("Poaceae", "Asteraceae", "Amaranthaceae"),
      aquatic = c("Cyperaceae", "Typha"),
      key_changes = "Dry forest stable; fire indicators increase late Holocene"
    ),
    # Laguna Granja - Gallery forest
    `5` = list(
      arboreal = c("Moraceae/Urticaceae", "Cecropia", "Mauritia", "Alchornea"),
      herbs = c("Poaceae", "Cyperaceae", "Asteraceae"),
      aquatic = c("Mauritia", "Sagittaria"),
      key_changes = "Mauritia palm swamp expansion mid-Holocene"
    ),
    # Colônia - Atlantic forest
    `6` = list(
      arboreal = c("Araucaria", "Podocarpus", "Weinmannia", "Myrsine", "Ilex", "Symplocos"),
      herbs = c("Poaceae", "Asteraceae", "Ericaceae"),
      aquatic = c("Cyperaceae", "Sphagnum"),
      key_changes = "Araucaria forest expansion post-LGM; grassland LGM"
    ),
    # Carajás - Rainforest
    `7` = list(
      arboreal = c("Moraceae/Urticaceae", "Cecropia", "Melastomataceae", "Myrtaceae", "Sapotaceae"),
      herbs = c("Poaceae", "Borreria", "Cuphea"),
      aquatic = c("Cyperaceae", "Isoetes"),
      key_changes = "Dry periods with savanna expansion 8-4 ka"
    ),
    # Lake Valencia - Cloud forest
    `8` = list(
      arboreal = c("Podocarpus", "Hedyosmum", "Weinmannia", "Alnus", "Myrica"),
      herbs = c("Poaceae", "Asteraceae", "Ericaceae"),
      aquatic = c("Cyperaceae", "Typha"),
      key_changes = "Montane elements descend during glacials"
    ),
    # Lago do Pires - Cerrado
    `9` = list(
      arboreal = c("Caryocar", "Byrsonima", "Qualea", "Curatella", "Mauritia"),
      herbs = c("Poaceae", "Asteraceae", "Cyperaceae", "Xyris"),
      aquatic = c("Mauritia", "Cyperaceae"),
      key_changes = "Cerrado-gallery forest mosaic throughout Holocene"
    ),
    # Laguna Loma Linda - Várzea
    `10` = list(
      arboreal = c("Cecropia", "Moraceae/Urticaceae", "Mauritia", "Euterpe", "Virola"),
      herbs = c("Poaceae", "Cyperaceae", "Heliconia"),
      aquatic = c("Mauritia", "Montrichardia", "Cyperaceae"),
      key_changes = "Floodplain forest dynamics; várzea expansion mid-Holocene"
    ),
    # Serra do Caparaó - Atlantic forest
    `11` = list(
      arboreal = c("Araucaria", "Podocarpus", "Drimys", "Weinmannia", "Symplocos", "Myrsine"),
      herbs = c("Poaceae", "Asteraceae", "Ericaceae", "Sphagnum"),
      aquatic = c("Cyperaceae", "Isoetes"),
      key_changes = "Campos de altitude during LGM; forest recovery Holocene"
    ),
    # Salitre - Cerrado
    `12` = list(
      arboreal = c("Caryocar", "Byrsonima", "Qualea", "Mauritia", "Podocarpus"),
      herbs = c("Poaceae", "Asteraceae", "Cyperaceae", "Eriocaulaceae"),
      aquatic = c("Mauritia", "Cyperaceae"),
      key_changes = "Cerrado-forest mosaic; wetter conditions early Holocene"
    ),
    # Cromínia - Cerrado-forest
    `13` = list(
      arboreal = c("Mauritia", "Mauritiella", "Caryocar", "Byrsonima", "Myrtaceae"),
      herbs = c("Poaceae", "Cyperaceae", "Asteraceae", "Xyris"),
      aquatic = c("Mauritia", "Typha", "Cyperaceae"),
      key_changes = "Palm swamp development; gallery forest fluctuations"
    ),
    # Laguna Yaguarú - Chiquitano forest
    `14` = list(
      arboreal = c("Anadenanthera", "Astronium", "Schinopsis", "Ceiba", "Acacia"),
      herbs = c("Poaceae", "Asteraceae", "Amaranthaceae"),
      aquatic = c("Cyperaceae", "Typha"),
      key_changes = "Dry forest expansion Holocene; more humid LGM"
    ),
    # Rio Acre - SW Amazon forest
    `15` = list(
      arboreal = c("Moraceae/Urticaceae", "Cecropia", "Alchornea", "Sapotaceae", "Arecaceae", "Bombacaceae"),
      herbs = c("Poaceae", "Asteraceae", "Heliconia"),
      aquatic = c("Mauritia", "Cyperaceae"),
      key_changes = "Terra firme forest stable; bamboo forest dynamics"
    )
  )

  vegetation <- data.frame(
    siteid = 1:15,
    sitename = c(
      "Lake Titicaca", "Laguna Chaplin", "Lake Pata", "Laguna Bella Vista",
      "Laguna Granja", "Colônia", "Carajás", "Lake Valencia",
      "Lago do Pires", "Laguna Loma Linda", "Serra do Caparaó",
      "Salitre", "Cromínia", "Laguna Yaguarú", "Rio Acre"
    ),
    lat = c(
      -15.83, -14.47, -0.27, -13.63, -13.27, -23.87, -6.35, 10.20,
      -17.95, -3.32, -20.43, -19.00, -17.28, -16.33, -10.50
    ),
    lng = c(
      -69.83, -61.08, -66.68, -61.55, -63.85, -46.70, -50.42, -67.73,
      -42.22, -73.32, -41.85, -46.77, -49.42, -63.17, -68.50
    ),
    altitude = c(
      3810, 300, 300, 160, 220, 900, 700, 400,
      390, 180, 1850, 1050, 750, 350, 200
    ),
    country = c(
      "Bolivia/Peru", "Bolivia", "Brazil", "Bolivia", "Bolivia", "Brazil",
      "Brazil", "Venezuela", "Brazil", "Peru", "Brazil", "Brazil",
      "Brazil", "Bolivia", "Brazil"
    ),
    dataset_type = "pollen",
    n_samples = c(85, 120, 95, 78, 65, 180, 145, 55, 42, 38, 75, 88, 92, 68, 45),
    age_range = c(
      "0-25 ka", "0-50 ka", "0-170 ka", "0-40 ka", "0-12 ka",
      "0-130 ka", "0-50 ka", "0-13 ka", "0-10 ka", "0-8 ka",
      "0-35 ka", "0-32 ka", "0-28 ka", "0-20 ka", "0-15 ka"
    ),
    # Numeric age bounds for filtering (in ka)
    age_min_ka = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    age_max_ka = c(25, 50, 170, 40, 12, 130, 50, 13, 10, 8, 35, 32, 28, 20, 15),
    biome_modern = c(
      "Puna", "Cerrado/Chiquitano ecotone", "Tropical rainforest", "Chiquitano dry forest",
      "Cerrado/Amazon ecotone", "Atlantic Forest", "Amazon rainforest", "Montane cloud forest",
      "Cerrado", "Amazon várzea", "Atlantic Forest/Campos", "Cerrado",
      "Cerrado/Gallery forest", "Chiquitano dry forest", "Amazon rainforest"
    ),
    biome_lgm = c(
      "Puna grassland", "Open savanna", "Tropical rainforest", "Dry woodland",
      "Savanna", "Grassland/Araucaria", "Savanna mosaic", "Lower montane forest",
      "Cerrado", "Flooded savanna", "Campos de altitude", "Cerrado/woodland",
      "Cerrado", "Semi-deciduous forest", "Tropical rainforest"
    ),
    dominant_signal = c(
      "Puna grassland", "Savanna-forest ecotone", "Terra firme forest",
      "Seasonally dry forest", "Gallery forest", "Atlantic forest",
      "Rainforest", "Cloud forest", "Cerrado", "Várzea",
      "Atlantic forest", "Cerrado", "Cerrado-forest", "Chiquitano forest",
      "SW Amazon forest"
    ),
    # Primary publication references with DOIs
    reference = c(
      "Paduano et al. 2003. Quat. Res.",
      "Mayle et al. 2000. J. Quat. Sci.",
      "Colinvaux et al. 1996. Science",
      "Burbridge et al. 2004. Palaeogeogr. Palaeoclimatol. Palaeoecol.",
      "Mayle et al. 2000. J. Quat. Sci.",
      "Ledru et al. 2005. Quat. Sci. Rev.",
      "Absy et al. 1991. Quat. Res.",
      "Salgado-Labouriau 1980. Review Palaeobot. Palynol.",
      "Behling 1995. Veg. Hist. Archaeobot.",
      "Behling et al. 1999. Rev. Palaeobot. Palynol.",
      "Behling 1997. Veg. Hist. Archaeobot.",
      "Ledru 1993. Rev. Palaeobot. Palynol.",
      "Salgado-Labouriau et al. 1997. Quat. Res.",
      "Mayle et al. 2000. J. Quat. Sci.",
      "Mayle et al. 2004. Phil. Trans. R. Soc. B"
    ),
    doi = c(
      "10.1016/S0033-5894(03)00030-3",
      "10.1002/1099-1417(200007)15:5<449::AID-JQS543>3.0.CO;2-A",
      "10.1126/science.274.5284.85",
      "10.1016/j.palaeo.2003.12.011",
      "10.1002/1099-1417(200007)15:5<449::AID-JQS543>3.0.CO;2-A",
      "10.1016/j.quascirev.2005.02.004",
      "10.1016/0033-5894(91)90009-T",
      "10.1016/0034-6667(80)90053-7",
      "10.1007/BF00196891",
      "10.1016/S0034-6667(99)00033-1",
      "10.1007/s003340050076",
      "10.1016/0034-6667(93)90021-K",
      "10.1006/qres.1996.1860",
      "10.1002/1099-1417(200007)15:5<449::AID-JQS543>3.0.CO;2-A",
      "10.1098/rstb.2003.1426"
    ),
    neotoma_id = c(
      1642, 1538, 1627, 1535, 1540, 1565, 1522, NA,
      1577, 1591, 1661, 1654, 1568, 1736, NA
    ),
    stringsAsFactors = FALSE
  )

  # Add taxa lists as concatenated strings for display
  vegetation$arboreal_taxa <- sapply(1:15, function(i) paste(pollen_taxa[[as.character(i)]]$arboreal, collapse = ", "))
  vegetation$herb_taxa <- sapply(1:15, function(i) paste(pollen_taxa[[as.character(i)]]$herbs, collapse = ", "))
  vegetation$aquatic_taxa <- sapply(1:15, function(i) paste(pollen_taxa[[as.character(i)]]$aquatic, collapse = ", "))
  vegetation$key_changes <- sapply(1:15, function(i) pollen_taxa[[as.character(i)]]$key_changes)

  # Create DOI URL
  vegetation$doi_url <- paste0("https://doi.org/", vegetation$doi)

  list(megafauna = megafauna, vegetation = vegetation)
}

# ============================================================================
# UI
# ============================================================================

ui <- fluidPage(

  tags$head(
    tags$style(HTML("
      .map-container { min-height: 350px; }
      .sidebar-panel { background: #f8f9fa; padding: 10px; border-radius: 5px; }
      .info-panel { background: white; padding: 8px; border-radius: 5px;
                    box-shadow: 0 2px 5px rgba(0,0,0,0.1); font-size: 12px; }
      h4, h5 { color: #2c3e50; margin-top: 0; }
      h6 { color: #2c3e50; margin: 5px 0; }
      .legend-item { display: flex; align-items: center; margin: 3px 0; font-size: 11px; }
      .legend-dot { width: 10px; height: 10px; border-radius: 50%; margin-right: 6px; }

      /* Compact time button styles */
      .time-btn {
        display: block;
        width: 100%;
        margin: 2px 0;
        padding: 3px 6px;
        font-size: 10px;
        text-align: left;
        border: none;
        border-radius: 3px;
        cursor: pointer;
      }
      .time-btn:hover { filter: brightness(0.9); }
      .time-btn.btn-sm { padding: 2px 5px; font-size: 10px; }

      /* Epoch colors */
      .epoch-holocene { background: #FFF9C4; color: #333; }
      .epoch-pleistocene { background: #FFECB3; color: #333; }
      .epoch-pliocene { background: #FFE0B2; color: #333; }
      .epoch-miocene { background: #FFCCBC; color: #333; }

      /* Climate event styling */
      .climate-btn { background: #BBDEFB; color: #333; }
      .climate-btn:hover { background: #90CAF9; }

      /* Collapsible sections */
      details { margin: 3px 0; }
      details summary { padding: 3px; background: #eee; border-radius: 3px; }
      details[open] summary { background: #ddd; }

      /* Compact form controls */
      .form-group { margin-bottom: 8px; }
      .form-control { font-size: 12px; padding: 4px 8px; height: auto; }
      .checkbox { margin: 3px 0; }

      /* Summary stats styling */
      #summary_stats { font-size: 10px; padding: 5px; margin: 0;
                       background: #fff; max-height: 80px; overflow: hidden; }

      /* Tab pills styling */
      .nav-pills > li > a { padding: 6px 12px; font-size: 12px; }

      /* DataTable compact styling */
      .dataTables_wrapper { font-size: 11px; }
      .dataTables_filter input { font-size: 11px; padding: 3px 6px; }
    "))
  ),

  titlePanel(
    div(
      h3("Western Amazonia Fossil Explorer", style = "margin: 0;"),
      p("Vegetation Proxies & Megafauna Occurrences",
        style = "margin: 0; color: #666; font-size: 14px;")
    )
  ),

  fluidRow(
    # Sidebar with filters (narrower)
    column(2,
      div(class = "sidebar-panel", style = "padding: 10px; font-size: 12px;",

        h5("Time Period", style = "margin: 0 0 8px 0;"),

        # Compact time selector as dropdown groups
        div(style = "margin-bottom: 10px;",
          actionButton("time_all", "All Time", class = "btn btn-sm btn-default",
                       style = "width: 100%; margin-bottom: 5px;"),

          # Climate events dropdown
          tags$details(style = "margin-bottom: 5px;",
            tags$summary(style = "cursor: pointer; font-weight: bold; font-size: 11px;",
                        "Climate Events"),
            div(class = "climate-events", style = "padding: 3px;",
              actionButton("time_lgm", "LGM (26-19 ka)", class = "time-btn climate-btn btn-sm"),
              actionButton("time_hs1", "HS1 (19-15 ka)", class = "time-btn climate-btn btn-sm"),
              actionButton("time_ba", "B-A (15-13 ka)", class = "time-btn climate-btn btn-sm"),
              actionButton("time_yd", "YD (13-11.7 ka)", class = "time-btn climate-btn btn-sm"),
              actionButton("time_eh", "Early Hol.", class = "time-btn climate-btn btn-sm"),
              actionButton("time_mh", "Mid Hol.", class = "time-btn climate-btn btn-sm"),
              actionButton("time_lh", "Late Hol.", class = "time-btn climate-btn btn-sm")
            )
          ),

          # SALMAs dropdown
          tags$details(style = "margin-bottom: 5px;",
            tags$summary(style = "cursor: pointer; font-weight: bold; font-size: 11px;",
                        "SALMAs"),
            div(style = "padding: 3px;",
              tags$small("Pleistocene:", style = "color: #FF8F00;"),
              actionButton("time_lujanian", "Lujanian", class = "time-btn btn-sm epoch-pleistocene"),
              actionButton("time_ensenadan", "Ensenadan", class = "time-btn btn-sm epoch-pleistocene"),
              actionButton("time_uquian", "Uquian", class = "time-btn btn-sm epoch-pleistocene"),
              tags$small("Pliocene:", style = "color: #EF6C00; display: block; margin-top: 3px;"),
              actionButton("time_chapadmalalan", "Chapadmalalan", class = "time-btn btn-sm epoch-pliocene"),
              actionButton("time_montehermosan", "Montehermosan", class = "time-btn btn-sm epoch-pliocene"),
              tags$small("Miocene:", style = "color: #D84315; display: block; margin-top: 3px;"),
              actionButton("time_huayquerian", "Huayquerian", class = "time-btn btn-sm epoch-miocene"),
              actionButton("time_mayoan", "Mayoan", class = "time-btn btn-sm epoch-miocene"),
              actionButton("time_laventan", "Laventan", class = "time-btn btn-sm epoch-miocene"),
              actionButton("time_colloncuran", "Colloncuran", class = "time-btn btn-sm epoch-miocene"),
              actionButton("time_santacrucian", "Santacrucian", class = "time-btn btn-sm epoch-miocene")
            )
          )
        ),

        # Custom slider
        sliderInput("age_range", "Age (ka)", min = 0, max = 30000,
                    value = c(0, 3000), step = 10, width = "100%"),

        hr(style = "margin: 8px 0;"),

        # Filters
        selectInput("taxon_filter", "Taxa", width = "100%",
                    choices = c("All" = "all",
                                "Xenarthra" = "Xenarthra",
                                "Notoungulata" = "Notoungulata",
                                "Proboscidea" = "Proboscidea",
                                "Litopterna" = "Litopterna"),
                    selected = "all"),

        # Layer toggles (inline)
        div(style = "font-size: 11px;",
          checkboxInput("show_megafauna", "Megafauna", value = TRUE, width = "100%"),
          checkboxInput("show_vegetation", "Pollen sites", value = TRUE, width = "100%")
        ),

        hr(style = "margin: 8px 0;"),

        # Symbology
        selectInput("color_by", "Color by:", width = "100%",
                    choices = c("Epoch" = "age_bin",
                                "Order" = "order_name",
                                "Family" = "family",
                                "Interval" = "interval",
                                "Country" = "country_code"),
                    selected = "age_bin"),

        selectInput("size_by", "Size by:", width = "100%",
                    choices = c("Fixed" = "fixed",
                                "Count" = "n_occs"),
                    selected = "fixed"),

        hr(style = "margin: 8px 0;"),

        # Summary (compact)
        verbatimTextOutput("summary_stats"),

        hr(style = "margin: 8px 0;"),

        # Legend
        h6("Legend", style = "margin: 5px 0;"),
        uiOutput("dynamic_legend")
      )
    ),

    # Main content area
    column(10,
      # Map row with locality info panel
      fluidRow(
        column(8,
          div(class = "map-container",
            leafletOutput("fossil_map", height = "420px")
          )
        ),
        column(4,
          # Selected locality info - expanded with more room
          div(class = "info-panel", style = "padding: 12px; height: 420px; overflow-y: auto;",
            h5("Selected Locality", style = "margin: 0 0 10px 0; border-bottom: 1px solid #eee; padding-bottom: 8px;"),
            uiOutput("locality_info")
          )
        )
      ),

      # Data tables row - full width
      fluidRow(
        column(12,
          div(style = "padding: 10px 5px;",
            tabsetPanel(
              id = "data_tabs",
              type = "pills",

              tabPanel("Megafauna Data",
                div(style = "padding-top: 8px;",
                  DT::dataTableOutput("raw_megafauna_table")
                )
              ),

              tabPanel("Taxa Summary",
                div(style = "padding-top: 8px;",
                  DT::dataTableOutput("taxa_table")
                )
              ),

              tabPanel("Pollen Sites",
                div(style = "padding-top: 8px;",
                  DT::dataTableOutput("raw_vegetation_table")
                )
              ),

              tabPanel("Pollen Taxa",
                div(style = "padding-top: 8px;",
                  DT::dataTableOutput("pollen_taxa_table")
                )
              )
            )
          )
        )
      ),

      # Temporal distribution plot - below tables
      fluidRow(
        column(12,
          div(style = "padding: 10px 5px;",
            h5("Temporal Distribution", style = "margin: 0 0 8px 0;"),
            plotlyOutput("temporal_plot", height = "180px")
          )
        )
      )
    )
  )
)

# ============================================================================
# SERVER
# ============================================================================

server <- function(input, output, session) {

  # Track selected time period for styling

  selected_time <- reactiveVal("all")

  # Time ranges for all periods (in ka)
  time_ranges <- list(
    "all" = c(0, 30000),
    # Climate events
    "lh" = c(0, 4),
    "mh" = c(4, 8),
    "eh" = c(8, 11.7),
    "yd" = c(11.7, 13),
    "ba" = c(13, 15),
    "hs1" = c(15, 19),
    "lgm" = c(19, 26),
    # Pleistocene SALMAs
    "lujanian" = c(10, 500),
    "ensenadan" = c(500, 1200),
    "uquian" = c(1200, 2500),
    # Pliocene SALMAs
    "chapadmalalan" = c(3000, 4000),
    "montehermosan" = c(4000, 6800),
    # Miocene SALMAs
    "huayquerian" = c(6800, 9000),
    "mayoan" = c(10000, 11800),
    "laventan" = c(11800, 13800),
    "colloncuran" = c(13800, 15500),
    "santacrucian" = c(16000, 17500)
  )

  # Helper function to update time selection
  update_time_selection <- function(period_id) {
    selected_time(period_id)
    range <- time_ranges[[period_id]]
    updateSliderInput(session, "age_range", value = range)
  }

  # Observers for each time button

  observeEvent(input$time_all, { update_time_selection("all") })
  observeEvent(input$time_lh, { update_time_selection("lh") })
  observeEvent(input$time_mh, { update_time_selection("mh") })
  observeEvent(input$time_eh, { update_time_selection("eh") })
  observeEvent(input$time_yd, { update_time_selection("yd") })
  observeEvent(input$time_ba, { update_time_selection("ba") })
  observeEvent(input$time_hs1, { update_time_selection("hs1") })
  observeEvent(input$time_lgm, { update_time_selection("lgm") })
  observeEvent(input$time_lujanian, { update_time_selection("lujanian") })
  observeEvent(input$time_ensenadan, { update_time_selection("ensenadan") })
  observeEvent(input$time_uquian, { update_time_selection("uquian") })
  observeEvent(input$time_chapadmalalan, { update_time_selection("chapadmalalan") })
  observeEvent(input$time_montehermosan, { update_time_selection("montehermosan") })
  observeEvent(input$time_huayquerian, { update_time_selection("huayquerian") })
  observeEvent(input$time_mayoan, { update_time_selection("mayoan") })
  observeEvent(input$time_laventan, { update_time_selection("laventan") })
  observeEvent(input$time_colloncuran, { update_time_selection("colloncuran") })
  observeEvent(input$time_santacrucian, { update_time_selection("santacrucian") })

  # Load data
  fossil_data <- reactive({
    withProgress(message = "Loading fossil data...", {
      sample_data <- create_sample_data()

      # Try PBDB query for megafauna
      megafauna <- tryCatch({
        df <- query_pbdb_megafauna()
        if (nrow(df) > 0) {
          message("  Using ", nrow(df), " PBDB megafauna occurrences")
          df
        } else {
          message("  PBDB returned no data, using sample megafauna")
          sample_data$megafauna
        }
      }, error = function(e) {
        message("  PBDB query error: ", e$message)
        sample_data$megafauna
      })

      # Try Neotoma query for vegetation
      vegetation <- tryCatch({
        df <- query_neotoma_vegetation()
        if (nrow(df) > 0) {
          message("  Using ", nrow(df), " Neotoma vegetation sites")
          df
        } else {
          message("  Neotoma returned no data, using sample vegetation")
          sample_data$vegetation
        }
      }, error = function(e) {
        message("  Neotoma query error: ", e$message)
        sample_data$vegetation
      })

      list(megafauna = megafauna, vegetation = vegetation)
    })
  })

  # Filtered megafauna data
  filtered_megafauna <- reactive({
    req(fossil_data())
    df <- fossil_data()$megafauna

    # Ensure numeric coordinates and required columns
    df$lng <- as.numeric(df$lng)
    df$lat <- as.numeric(df$lat)
    if (!"family" %in% names(df)) df$family <- NA_character_
    if (!"order_name" %in% names(df)) df$order_name <- df$query_taxon

    # Age filter (convert ka to Ma for comparison)
    age_min_ma <- input$age_range[1] / 1000
    age_max_ma <- input$age_range[2] / 1000

    df <- df %>%
      filter(!is.na(lng) & !is.na(lat)) %>%
      filter(min_ma <= age_max_ma & max_ma >= age_min_ma)

    # Taxon filter
    if (input$taxon_filter != "all") {
      if ("order_name" %in% names(df)) {
        df <- df %>% filter(order_name == input$taxon_filter)
      } else if ("query_taxon" %in% names(df)) {
        df <- df %>% filter(query_taxon == input$taxon_filter)
      }
    }

    df
  })

  # Filtered vegetation data based on time selection
  filtered_vegetation <- reactive({
    req(fossil_data())
    veg <- fossil_data()$vegetation

    # Add default numeric age columns if not present
    if (!"age_min_ka" %in% names(veg)) veg$age_min_ka <- 0
    if (!"age_max_ka" %in% names(veg)) veg$age_max_ka <- 50  # Default to 50 ka

    # Filter by age range - show site if its record overlaps with selected range
    age_min <- input$age_range[1]
    age_max <- input$age_range[2]

    # Site overlaps if: site_min <= selected_max AND site_max >= selected_min
    veg <- veg %>%
      filter(age_min_ka <= age_max & age_max_ka >= age_min)

    veg
  })

  # Selected locality
  selected_locality <- reactiveVal(NULL)

  # Main map
  output$fossil_map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron, group = "Light") %>%
      addProviderTiles(providers$Esri.WorldTopoMap, group = "Terrain") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Satellite") %>%
      setView(lng = -62, lat = -15, zoom = 4) %>%
      addLayersControl(
        baseGroups = c("Light", "Terrain", "Satellite"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      # Add scale bar
      addScaleBar(position = "bottomleft")
  })

  # Update markers when data/filters change
  observe({
    req(fossil_data())

    map <- leafletProxy("fossil_map") %>%
      clearMarkers() %>%
      clearMarkerClusters()

    # Add megafauna occurrences
    if (input$show_megafauna) {
      mega <- filtered_megafauna()

      if (nrow(mega) > 0) {
        # Ensure required columns exist with defaults
        if (!"family" %in% names(mega)) mega$family <- NA
        if (!"interval" %in% names(mega)) mega$interval <- NA
        if (!"country_code" %in% names(mega)) mega$country_code <- NA
        if (!"locality" %in% names(mega)) mega$locality <- NA
        if (!"reference" %in% names(mega)) mega$reference <- NA
        if (!"pbdb_ref_url" %in% names(mega)) mega$pbdb_ref_url <- NA
        if (!"pbdb_occ_url" %in% names(mega)) mega$pbdb_occ_url <- NA

        # Dynamic color based on symbology selection
        color_var <- input$color_by
        if (color_var == "age_bin") {
          # Four epochs: Holocene, Pleistocene, Pliocene, Miocene
          mega$color_group <- case_when(
            mega$age_ma < 0.0117 ~ "Holocene",
            mega$age_ma < 2.58 ~ "Pleistocene",
            mega$age_ma < 5.33 ~ "Pliocene",
            TRUE ~ "Miocene"
          )
          color_pal <- colorFactor(
            c("#FFF176", "#FFB74D", "#FF8A65", "#E57373"),
            domain = c("Holocene", "Pleistocene", "Pliocene", "Miocene")
          )
        } else if (color_var == "order_name") {
          mega$color_group <- mega$order_name
          color_pal <- colorFactor(
            c("#e41a1c", "#377eb8", "#4daf4a", "#984ea3"),
            domain = c("Xenarthra", "Notoungulata", "Proboscidea", "Litopterna")
          )
        } else if (color_var == "family") {
          mega$color_group <- ifelse(is.na(mega$family), "Unknown", mega$family)
          unique_families <- unique(mega$color_group)
          color_pal <- colorFactor(
            colorRampPalette(c("#e41a1c", "#377eb8", "#4daf4a", "#984ea3", "#ff7f00", "#a65628"))(length(unique_families)),
            domain = unique_families
          )
        } else if (color_var == "interval") {
          mega$color_group <- ifelse(is.na(mega$interval), "Unknown", mega$interval)
          unique_intervals <- unique(mega$color_group)
          color_pal <- colorFactor(
            colorRampPalette(c("#1b9e77", "#d95f02", "#7570b3", "#e7298a"))(length(unique_intervals)),
            domain = unique_intervals
          )
        } else if (color_var == "country_code") {
          mega$color_group <- ifelse(is.na(mega$country_code), "Unknown", mega$country_code)
          unique_countries <- unique(mega$color_group)
          color_pal <- colorFactor(
            colorRampPalette(c("#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3"))(length(unique_countries)),
            domain = unique_countries
          )
        } else {
          mega$color_group <- "All"
          color_pal <- colorFactor("#e41a1c", domain = "All")
        }

        mega$color <- color_pal(mega$color_group)

        # Dynamic size
        if (input$size_by == "fixed") {
          mega$radius <- 7
        } else {
          # Count occurrences per locality (approximate by rounding coords)
          mega$loc_key <- paste(round(mega$lng, 2), round(mega$lat, 2))
          loc_counts <- table(mega$loc_key)
          mega$n_at_loc <- as.numeric(loc_counts[mega$loc_key])
          mega$radius <- pmin(5 + log1p(mega$n_at_loc) * 3, 15)
        }

        # Build popup with DOI/reference links
        mega$popup_text <- paste0(
          "<b>", mega$accepted_name, "</b><br>",
          "<span style='color:#666;'>Order: ", mega$order_name, "</span><br>",
          ifelse(!is.na(mega$family) & mega$family != "", paste0("Family: ", mega$family, "<br>"), ""),
          ifelse(!is.na(mega$interval) & mega$interval != "", paste0("Interval: ", mega$interval, "<br>"), ""),
          "Age: ", round(mega$age_ka, 1), " ka<br>",
          ifelse(!is.na(mega$locality) & mega$locality != "", paste0("<br><em>", mega$locality, "</em><br>"), ""),
          "<br><b>Source:</b><br>",
          ifelse(!is.na(mega$reference), paste0("<span style='font-size:11px;'>", substr(mega$reference, 1, 80), "...</span><br>"), ""),
          ifelse(!is.na(mega$pbdb_ref_url),
                 paste0("<a href='", mega$pbdb_ref_url, "' target='_blank'>📄 View Reference</a> | "), ""),
          ifelse(!is.na(mega$pbdb_occ_url),
                 paste0("<a href='", mega$pbdb_occ_url, "' target='_blank'>🔍 PBDB Record</a>"), "")
        )

        map <- map %>%
          addCircleMarkers(
            data = mega,
            lng = ~lng, lat = ~lat,
            radius = ~radius,
            color = ~color,
            fillColor = ~color,
            fillOpacity = 0.7,
            stroke = TRUE,
            weight = 1,
            popup = ~popup_text,
            layerId = ~paste0("mega_", seq_len(nrow(mega))),
            group = "Megafauna"
          )
      }
    }

    # Add vegetation sites (filtered by time)
    if (input$show_vegetation) {
      veg <- filtered_vegetation()

      if (nrow(veg) > 0) {
        # Ensure required columns exist
        if (!"doi_url" %in% names(veg)) veg$doi_url <- NA
        if (!"reference" %in% names(veg)) veg$reference <- NA
        if (!"neotoma_id" %in% names(veg)) veg$neotoma_id <- NA
        if (!"arboreal_taxa" %in% names(veg)) veg$arboreal_taxa <- NA
        if (!"herb_taxa" %in% names(veg)) veg$herb_taxa <- NA
        if (!"key_changes" %in% names(veg)) veg$key_changes <- NA
        if (!"biome_modern" %in% names(veg)) veg$biome_modern <- veg$dominant_signal
        if (!"biome_lgm" %in% names(veg)) veg$biome_lgm <- NA
        if (!"n_samples" %in% names(veg)) veg$n_samples <- NA

        veg$popup_text <- paste0(
          "<b>", veg$sitename, "</b><br>",
          "<span style='color:#2e7d32;'>Pollen record (", veg$n_samples, " samples)</span><br>",
          "Altitude: ", veg$altitude, " m | ", veg$age_range, "<br>",
          "<hr style='margin:5px 0;'>",
          "<b>Modern biome:</b> ", veg$biome_modern, "<br>",
          ifelse(!is.na(veg$biome_lgm), paste0("<b>LGM biome:</b> ", veg$biome_lgm, "<br>"), ""),
          "<hr style='margin:5px 0;'>",
          "<b>Key taxa:</b><br>",
          ifelse(!is.na(veg$arboreal_taxa), paste0("<span style='font-size:11px;'>🌳 ", veg$arboreal_taxa, "</span><br>"), ""),
          ifelse(!is.na(veg$herb_taxa), paste0("<span style='font-size:11px;'>🌿 ", veg$herb_taxa, "</span><br>"), ""),
          "<hr style='margin:5px 0;'>",
          ifelse(!is.na(veg$key_changes), paste0("<em style='font-size:11px;'>", veg$key_changes, "</em><br>"), ""),
          "<br>",
          ifelse(!is.na(veg$doi_url), paste0("<a href='", veg$doi_url, "' target='_blank'>📄 DOI</a>"), ""),
          ifelse(!is.na(veg$neotoma_id),
                 paste0(" | <a href='https://apps.neotomadb.org/explorer/?datasetid=", veg$neotoma_id, "' target='_blank'>🌿 Neotoma</a>"), "")
        )

        map <- map %>%
          addCircleMarkers(
            data = veg,
            lng = ~lng, lat = ~lat,
            radius = 10,
            color = "#4daf4a",
            fillColor = "#4daf4a",
            fillOpacity = 0.7,
            stroke = TRUE,
            weight = 2,
            popup = ~popup_text,
            layerId = ~paste0("veg_", siteid),
            group = "Vegetation"
          )
      }
    }
  })

  # Handle marker clicks
  observeEvent(input$fossil_map_marker_click, {
    click <- input$fossil_map_marker_click
    selected_locality(click$id)
  })

  # Locality info panel
  output$locality_info <- renderUI({
    req(selected_locality())

    loc_id <- selected_locality()

    if (grepl("^mega_", loc_id)) {
      # Megafauna locality
      idx <- as.numeric(gsub("mega_", "", loc_id))
      mega <- filtered_megafauna()
      if (idx <= nrow(mega)) {
        loc <- mega[idx, ]

        tagList(
          h5(loc$accepted_name[1]),
          if ("family" %in% names(loc) && !is.na(loc$family[1]) && loc$family[1] != "") {
            p(strong("Family: "), loc$family[1])
          },
          p(strong("Order: "), loc$order_name[1]),
          if ("interval" %in% names(loc) && !is.na(loc$interval[1]) && loc$interval[1] != "") {
            p(strong("Interval: "), loc$interval[1])
          },
          p(strong("Age: "), round(loc$age_ka[1], 1), " ka BP"),
          if ("locality" %in% names(loc) && !is.na(loc$locality[1]) && loc$locality[1] != "") {
            p(em(loc$locality[1]))
          },
          p(strong("Coordinates: "), round(loc$lat[1], 4), ", ", round(loc$lng[1], 4)),
          hr(),
          if ("reference" %in% names(loc) && !is.na(loc$reference[1])) {
            p(style = "font-size: 11px;", substr(loc$reference[1], 1, 100), "...")
          },
          div(
            if ("pbdb_ref_url" %in% names(loc) && !is.na(loc$pbdb_ref_url[1])) {
              a(href = loc$pbdb_ref_url[1], target = "_blank", "📄 Reference")
            },
            " ",
            if ("pbdb_occ_url" %in% names(loc) && !is.na(loc$pbdb_occ_url[1])) {
              a(href = loc$pbdb_occ_url[1], target = "_blank", "🔍 PBDB")
            }
          )
        )
      }
    } else if (grepl("^veg_", loc_id)) {
      # Vegetation site
      siteid <- as.numeric(gsub("veg_", "", loc_id))
      veg <- fossil_data()$vegetation
      loc <- veg[veg$siteid == siteid, ]

      if (nrow(loc) > 0) {
        tagList(
          h5(loc$sitename[1]),
          p(strong("Pollen record"), " | ", loc$altitude[1], " m"),
          p(strong("Age range: "), loc$age_range[1]),
          if ("n_samples" %in% names(loc) && !is.na(loc$n_samples[1])) {
            p(strong("Samples: "), loc$n_samples[1])
          },
          hr(),
          # Biome information
          if ("biome_modern" %in% names(loc) && !is.na(loc$biome_modern[1])) {
            p(strong("Modern: "), loc$biome_modern[1])
          },
          if ("biome_lgm" %in% names(loc) && !is.na(loc$biome_lgm[1])) {
            p(strong("LGM: "), loc$biome_lgm[1])
          },
          hr(),
          # Taxa lists
          h6("Recorded Taxa:", style = "margin-bottom: 5px;"),
          if ("arboreal_taxa" %in% names(loc) && !is.na(loc$arboreal_taxa[1])) {
            p(style = "font-size: 11px; margin: 2px 0;",
              strong("🌳 Arboreal: "), loc$arboreal_taxa[1])
          },
          if ("herb_taxa" %in% names(loc) && !is.na(loc$herb_taxa[1])) {
            p(style = "font-size: 11px; margin: 2px 0;",
              strong("🌿 Herbs: "), loc$herb_taxa[1])
          },
          if ("aquatic_taxa" %in% names(loc) && !is.na(loc$aquatic_taxa[1])) {
            p(style = "font-size: 11px; margin: 2px 0;",
              strong("💧 Aquatic: "), loc$aquatic_taxa[1])
          },
          hr(),
          # Key findings
          if ("key_changes" %in% names(loc) && !is.na(loc$key_changes[1])) {
            p(em(style = "font-size: 11px;", loc$key_changes[1]))
          },
          hr(),
          # Source links
          if ("reference" %in% names(loc) && !is.na(loc$reference[1])) {
            p(style = "font-size: 10px;", loc$reference[1])
          },
          div(
            if ("doi_url" %in% names(loc) && !is.na(loc$doi_url[1])) {
              a(href = loc$doi_url[1], target = "_blank", "📄 DOI")
            },
            " ",
            if ("neotoma_id" %in% names(loc) && !is.na(loc$neotoma_id[1])) {
              a(href = paste0("https://apps.neotomadb.org/explorer/?datasetid=", loc$neotoma_id[1]),
                target = "_blank", "🌿 Neotoma")
            }
          )
        )
      }
    } else {
      p("Click a marker to see details")
    }
  })

  # Dynamic legend based on symbology
  output$dynamic_legend <- renderUI({
    color_var <- input$color_by

    legend_items <- if (color_var == "age_bin") {
      list(
        list(color = "#FFF176", label = "Holocene (<11.7 ka)"),
        list(color = "#FFB74D", label = "Pleistocene (11.7 ka - 2.58 Ma)"),
        list(color = "#FF8A65", label = "Pliocene (2.58 - 5.33 Ma)"),
        list(color = "#E57373", label = "Miocene (5.33 - 23 Ma)")
      )
    } else if (color_var == "order_name") {
      list(
        list(color = "#e41a1c", label = "Xenarthra"),
        list(color = "#377eb8", label = "Notoungulata"),
        list(color = "#4daf4a", label = "Proboscidea"),
        list(color = "#984ea3", label = "Litopterna")
      )
    } else if (color_var == "family") {
      mega <- filtered_megafauna()
      if (nrow(mega) > 0) {
        families <- unique(na.omit(mega$family))
        colors <- colorRampPalette(c("#e41a1c", "#377eb8", "#4daf4a", "#984ea3", "#ff7f00", "#a65628"))(max(length(families), 1))
        lapply(seq_along(families), function(i) list(color = colors[i], label = families[i]))
      } else {
        list(list(color = "#999", label = "No data"))
      }
    } else if (color_var == "interval") {
      mega <- filtered_megafauna()
      if (nrow(mega) > 0) {
        intervals <- unique(na.omit(mega$interval))
        colors <- colorRampPalette(c("#1b9e77", "#d95f02", "#7570b3", "#e7298a"))(max(length(intervals), 1))
        lapply(seq_along(intervals), function(i) list(color = colors[i], label = intervals[i]))
      } else {
        list(list(color = "#999", label = "No data"))
      }
    } else if (color_var == "country_code") {
      mega <- filtered_megafauna()
      if (nrow(mega) > 0) {
        countries <- unique(na.omit(mega$country_code))
        colors <- colorRampPalette(c("#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3"))(max(length(countries), 1))
        lapply(seq_along(countries), function(i) list(color = colors[i], label = countries[i]))
      } else {
        list(list(color = "#999", label = "No data"))
      }
    } else {
      list(list(color = "#e41a1c", label = "All megafauna"))
    }

    # Add vegetation to legend
    legend_items <- c(legend_items, list(list(color = "#4daf4a", label = "Pollen sites")))

    tagList(
      lapply(legend_items, function(item) {
        div(class = "legend-item",
          div(class = "legend-dot", style = paste0("background: ", item$color, ";")),
          span(item$label)
        )
      })
    )
  })

  # Raw megafauna data table - full occurrence data for verification
  output$raw_megafauna_table <- DT::renderDataTable({
    mega <- filtered_megafauna()

    if (nrow(mega) > 0) {
      # Select key columns for display
      display_cols <- c("accepted_name", "order_name", "family", "age_ka",
                        "interval", "country_code", "lat", "lng")
      available_cols <- intersect(display_cols, names(mega))

      mega %>%
        select(all_of(available_cols)) %>%
        mutate(
          age_ka = round(age_ka, 1),
          lat = round(lat, 3),
          lng = round(lng, 3)
        ) %>%
        rename_with(~ c("Taxon", "Order", "Family", "Age (ka)", "Interval",
                        "Country", "Lat", "Lng")[1:length(available_cols)])
    } else {
      data.frame(Message = "No occurrences match filters")
    }
  }, options = list(
    pageLength = 10,
    dom = 'frtip',
    scrollX = TRUE,
    scrollY = "180px",
    searching = TRUE,
    ordering = TRUE,
    autoWidth = TRUE
  ))

  # Raw vegetation/pollen sites table
  output$raw_vegetation_table <- DT::renderDataTable({
    veg <- filtered_vegetation()

    if (nrow(veg) > 0) {
      # Select key columns for display
      veg %>%
        select(
          Site = sitename,
          Country = country,
          Lat = lat,
          Lng = lng,
          `Alt (m)` = altitude,
          `Age Range` = age_range,
          `Modern Biome` = biome_modern,
          `LGM Biome` = biome_lgm,
          `Arboreal Taxa` = arboreal_taxa,
          `Herb Taxa` = herb_taxa
        ) %>%
        mutate(
          Lat = round(Lat, 3),
          Lng = round(Lng, 3)
        )
    } else {
      data.frame(Message = "No vegetation sites in selected time range")
    }
  }, options = list(
    pageLength = 10,
    dom = 'frtip',
    scrollX = TRUE,
    scrollY = "180px",
    searching = TRUE,
    ordering = TRUE,
    autoWidth = TRUE
  ))

  # Taxa summary table
  output$taxa_table <- DT::renderDataTable({
    mega <- filtered_megafauna()

    if (nrow(mega) > 0) {
      # Ensure family column exists
      if (!"family" %in% names(mega)) mega$family <- mega$order_name

      mega %>%
        group_by(accepted_name, family) %>%
        summarise(
          n_localities = n(),
          age_range = paste0(round(min(age_ka), 0), "-", round(max(age_ka), 0), " ka"),
          .groups = "drop"
        ) %>%
        arrange(family, accepted_name) %>%
        select(Taxon = accepted_name, Family = family,
               `N Localities` = n_localities, `Age Range` = age_range)
    } else {
      data.frame(Message = "No occurrences match filters")
    }
  }, options = list(
    pageLength = 10,
    dom = 'frtip',
    scrollX = TRUE,
    scrollY = "180px",
    searching = TRUE,
    autoWidth = TRUE
  ))

  # Pollen taxa table
  output$pollen_taxa_table <- DT::renderDataTable({
    veg <- filtered_vegetation()

    if (nrow(veg) > 0 && "arboreal_taxa" %in% names(veg)) {
      # Create expanded taxa list from all sites
      taxa_list <- data.frame()

      for (i in 1:nrow(veg)) {
        # Parse arboreal taxa
        if (!is.na(veg$arboreal_taxa[i])) {
          arb <- strsplit(veg$arboreal_taxa[i], ", ")[[1]]
          taxa_list <- rbind(taxa_list, data.frame(
            taxon = arb,
            type = "Arboreal",
            site = veg$sitename[i],
            biome = veg$biome_modern[i],
            stringsAsFactors = FALSE
          ))
        }
        # Parse herb taxa
        if (!is.na(veg$herb_taxa[i])) {
          herbs <- strsplit(veg$herb_taxa[i], ", ")[[1]]
          taxa_list <- rbind(taxa_list, data.frame(
            taxon = herbs,
            type = "Herb/Grass",
            site = veg$sitename[i],
            biome = veg$biome_modern[i],
            stringsAsFactors = FALSE
          ))
        }
      }

      if (nrow(taxa_list) > 0) {
        # Summarize by taxon
        taxa_list %>%
          group_by(taxon, type) %>%
          summarise(
            n_sites = n_distinct(site),
            biomes = paste(unique(biome), collapse = "; "),
            .groups = "drop"
          ) %>%
          arrange(type, desc(n_sites)) %>%
          select(Taxon = taxon, Type = type, `N Sites` = n_sites, Biomes = biomes)
      } else {
        data.frame(Message = "No taxa data available")
      }
    } else {
      data.frame(Message = "No vegetation data loaded")
    }
  }, options = list(
    pageLength = 10,
    dom = 'frtip',
    scrollX = TRUE,
    scrollY = "180px",
    searching = TRUE,
    autoWidth = TRUE
  ))

  # Summary stats
  output$summary_stats <- renderPrint({
    mega <- filtered_megafauna()
    veg <- filtered_vegetation()

    # Time period labels
    period_labels <- c(
      "all" = "All Cenozoic",
      "lh" = "Late Holocene",
      "mh" = "Mid Holocene",
      "eh" = "Early Holocene",
      "yd" = "Younger Dryas",
      "ba" = "Bølling-Allerød",
      "hs1" = "Heinrich Stadial 1",
      "lgm" = "Last Glacial Maximum",
      "lujanian" = "Lujanian SALMA",
      "ensenadan" = "Ensenadan SALMA",
      "uquian" = "Uquian SALMA",
      "chapadmalalan" = "Chapadmalalan SALMA",
      "montehermosan" = "Montehermosan SALMA",
      "huayquerian" = "Huayquerian SALMA",
      "mayoan" = "Mayoan SALMA",
      "laventan" = "Laventan SALMA",
      "colloncuran" = "Colloncuran SALMA",
      "santacrucian" = "Santacrucian SALMA"
    )

    current_period <- selected_time()
    period_name <- period_labels[[current_period]] %||% "Custom"

    cat("Selected:", period_name, "\n")
    cat("Age range:", input$age_range[1], "-", input$age_range[2], "ka\n\n")
    cat("Megafauna occurrences:", nrow(mega), "\n")
    cat("Unique taxa:", length(unique(mega$accepted_name)), "\n")
    cat("Vegetation sites:", nrow(veg), "\n")
  })

  # Temporal distribution plot - harmonized with symbology selection
  output$temporal_plot <- renderPlotly({
    mega <- filtered_megafauna()

    if (nrow(mega) == 0) {
      return(plotly_empty() %>% layout(title = "No data in selected range"))
    }

    # Bin by age - extended for Miocene data
    mega$age_bin <- cut(mega$age_ka,
                        breaks = c(0, 11.7, 126, 2580, 5330, 10000, 17500, 30000),
                        labels = c("Holocene", "L.Pleist", "E.Pleist",
                                   "Pliocene", "L.Miocene", "M.Miocene", "E.Miocene"),
                        include.lowest = TRUE)

    # Get color grouping based on symbology selection
    color_var <- input$color_by

    if (color_var == "age_bin") {
      # Four epochs matching map symbology
      mega$color_group <- case_when(
        mega$age_ma < 0.0117 ~ "Holocene",
        mega$age_ma < 2.58 ~ "Pleistocene",
        mega$age_ma < 5.33 ~ "Pliocene",
        TRUE ~ "Miocene"
      )
      color_palette <- c("Holocene" = "#FFF176", "Pleistocene" = "#FFB74D",
                         "Pliocene" = "#FF8A65", "Miocene" = "#E57373")
      legend_title <- "Epoch"
    } else if (color_var == "order_name") {
      mega$color_group <- mega$order_name
      color_palette <- c("Xenarthra" = "#e41a1c", "Notoungulata" = "#377eb8",
                         "Proboscidea" = "#4daf4a", "Litopterna" = "#984ea3")
      legend_title <- "Order"
    } else if (color_var == "family") {
      mega$color_group <- ifelse(is.na(mega$family) | mega$family == "", "Unknown", mega$family)
      unique_families <- unique(mega$color_group)
      colors <- colorRampPalette(c("#e41a1c", "#377eb8", "#4daf4a", "#984ea3", "#ff7f00", "#a65628"))(length(unique_families))
      color_palette <- setNames(colors, unique_families)
      legend_title <- "Family"
    } else if (color_var == "interval") {
      mega$color_group <- ifelse(is.na(mega$interval) | mega$interval == "", "Unknown", mega$interval)
      unique_intervals <- unique(mega$color_group)
      colors <- colorRampPalette(c("#1b9e77", "#d95f02", "#7570b3", "#e7298a", "#66a61e"))(length(unique_intervals))
      color_palette <- setNames(colors, unique_intervals)
      legend_title <- "Interval"
    } else if (color_var == "country_code") {
      mega$color_group <- ifelse(is.na(mega$country_code) | mega$country_code == "", "Unknown", mega$country_code)
      unique_countries <- unique(mega$color_group)
      colors <- colorRampPalette(c("#8dd3c7", "#ffffb3", "#bebada", "#fb8072", "#80b1d3", "#fdb462"))(length(unique_countries))
      color_palette <- setNames(colors, unique_countries)
      legend_title <- "Country"
    } else {
      mega$color_group <- "All"
      color_palette <- c("All" = "#e41a1c")
      legend_title <- ""
    }

    # Summarize by age bin and color group
    age_summary <- mega %>%
      group_by(age_bin, color_group) %>%
      summarise(n = n(), .groups = "drop")

    # Create stacked bar plot
    p <- plot_ly(age_summary, x = ~age_bin, y = ~n, color = ~color_group,
                 colors = color_palette, type = "bar") %>%
      layout(
        barmode = "stack",
        xaxis = list(title = "Age Interval", categoryorder = "array",
                     categoryarray = c("Holocene", "L.Pleist", "E.Pleist",
                                       "Pliocene", "L.Miocene", "M.Miocene", "E.Miocene")),
        yaxis = list(title = "Number of Occurrences"),
        legend = list(title = list(text = legend_title), orientation = "h", y = -0.2),
        margin = list(t = 30, b = 80)
      )

    p
  })
}

# ============================================================================
# RUN APP
# ============================================================================

shinyApp(ui = ui, server = server)
