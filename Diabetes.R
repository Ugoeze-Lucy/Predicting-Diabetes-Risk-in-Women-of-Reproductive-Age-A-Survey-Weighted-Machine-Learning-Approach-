# =============================================================================
# NHANES 2017-2018 | Diabetes Risk Prediction Project
# Phase 1: Data Loading, Merging, and Saving
# =============================================================================

# --- 1. Load required packages -----------------------------------------------
library(haven)
library(dplyr)

# --- 2. Set the working directory -------------------------------------------
setwd("C:/Users/Ugoeze/Downloads/Diabetes_Risk_Prediction")

# --- 3. Load all 13 XPT files ------------------------------------------------
demo  <- read_xpt("DEMO_J.XPT")   # Demographics + survey weights
bmx   <- read_xpt("BMX_J.XPT")    # BMI and anthropometric measures
bpx   <- read_xpt("BPX_J.XPT")    # Blood pressure readings
ghb   <- read_xpt("GHB_J.XPT")    # HbA1c (primary outcome variable)
glu   <- read_xpt("GLU_J.XPT")    # Fasting plasma glucose (outcome)
hdl   <- read_xpt("HDL_J.XPT")    # HDL cholesterol
trigly <- read_xpt("TRIGLY_J.XPT") # Triglycerides and LDL cholesterol
diq   <- read_xpt("DIQ_J.XPT")    # Self-reported diabetes diagnosis
paq   <- read_xpt("PAQ_J.XPT")    # Physical activity
smq   <- read_xpt("SMQ_J.XPT")    # Smoking status
alq   <- read_xpt("ALQ_J.XPT")    # Alcohol use
hiq   <- read_xpt("HIQ_J.XPT")    # Health insurance
rhq   <- read_xpt("RHQ_J.XPT")    # Reproductive health (gestational diabetes)

# --- 4. Check dimensions of each file after loading --------------------------
cat("DEMO_J:  ", nrow(demo),   "rows,", ncol(demo),   "columns\n")
cat("BMX_J:   ", nrow(bmx),    "rows,", ncol(bmx),    "columns\n")
cat("BPX_J:   ", nrow(bpx),    "rows,", ncol(bpx),    "columns\n")
cat("GHB_J:   ", nrow(ghb),    "rows,", ncol(ghb),    "columns\n")
cat("GLU_J:   ", nrow(glu),    "rows,", ncol(glu),    "columns\n")
cat("HDL_J:   ", nrow(hdl),    "rows,", ncol(hdl),    "columns\n")
cat("TRIGLY_J:", nrow(trigly), "rows,", ncol(trigly), "columns\n")
cat("DIQ_J:   ", nrow(diq),    "rows,", ncol(diq),    "columns\n")
cat("PAQ_J:   ", nrow(paq),    "rows,", ncol(paq),    "columns\n")
cat("SMQ_J:   ", nrow(smq),    "rows,", ncol(smq),    "columns\n")
cat("ALQ_J:   ", nrow(alq),    "rows,", ncol(alq),    "columns\n")
cat("HIQ_J:   ", nrow(hiq),    "rows,", ncol(hiq),    "columns\n")
cat("RHQ_J:   ", nrow(rhq),    "rows,", ncol(rhq),    "columns\n")

# --- 5. Merge all files on SEQN using sequential left joins ------------------
nhanes_raw <- demo |>
  left_join(bmx,    by = "SEQN") |>
  left_join(bpx,    by = "SEQN") |>
  left_join(ghb,    by = "SEQN") |>
  left_join(glu,    by = "SEQN") |>
  left_join(hdl,    by = "SEQN") |>
  left_join(trigly, by = "SEQN") |>
  left_join(diq,    by = "SEQN") |>
  left_join(paq,    by = "SEQN") |>
  left_join(smq,    by = "SEQN") |>
  left_join(alq,    by = "SEQN") |>
  left_join(hiq,    by = "SEQN") |>
  left_join(rhq,    by = "SEQN")

# --- 6. Check the merged dataset ---------------------------------------------
cat("Merged dataset dimensions:", nrow(nhanes_raw), "rows,", ncol(nhanes_raw), "columns\n")

# Confirm SEQN is unique (no duplicate participants)
cat("Unique SEQN values:", n_distinct(nhanes_raw$SEQN), "\n")

# --- 7. Save merged raw dataset ------------------------------------------
saveRDS(nhanes_raw, file = "nhanes_raw_merged.rds")

cat("File saved successfully as nhanes_raw_merged.rds\n")


# =============================================================================
# Phase 2: Analytic Population Definition
# =============================================================================

# --- 1. Load merged raw dataset ------------------------------------------
nhanes_raw <- readRDS("nhanes_raw_merged.rds")

# --- 2. Check the sex and age variables before filtering ---------------------
cat("Sex variable (RIAGENDR) distribution:\n")
table(nhanes_raw$RIAGENDR, useNA = "always")

cat("\nAge variable (RIDAGEYR) — summary:\n")
summary(nhanes_raw$RIDAGEYR)

# --- 3. Apply the analytic population filters ---------------------------------
nhanes_women <- nhanes_raw |>
  filter(
    RIAGENDR == 2,        # Female only (1 = Male, 2 = Female in NHANES coding)
    RIDAGEYR >= 18,       # Aged 18 or older
    RIDAGEYR <= 49,       # Aged 49 or younger
    !is.na(WTMEC2YR),    # Must have a valid MEC exam weight
    WTMEC2YR > 0          # Weight must be greater than zero (excludes ineligible participants)
  )

# --- 4. Check the filtered dataset dimensions --------------------------------
cat("Analytic population (women 18-49):", nrow(nhanes_women), "rows,", ncol(nhanes_women), "columns\n")

# --- 5. Confirm the filters worked correctly ---------------------------------
cat("\nSex distribution after filter :\n")
table(nhanes_women$RIAGENDR, useNA = "always")

cat("\nAge range after filter:\n")
cat("  Minimum age:", min(nhanes_women$RIDAGEYR), "\n")
cat("  Maximum age:", max(nhanes_women$RIDAGEYR), "\n")

cat("\nSurvey weight summary (WTMEC2YR):\n")
summary(nhanes_women$WTMEC2YR)

# --- 6. Save the analytic population -----------------------------------------
saveRDS(nhanes_women, file = "nhanes_women_1849.rds")

cat("\nAnalytic population saved as nhanes_women_1849.rds\n")

# =============================================================================
# Phase 3: Outcome Variable Definition
# =============================================================================

# --- 1. Load the analytic population -----------------------------------------
nhanes_women <- readRDS("nhanes_women_1849.rds")

# --- 2. Inspect the three outcome source variables ---------------------------
# HbA1c (from GHB file)
cat("HbA1c (LBXGH) summary:\n")
summary(nhanes_women$LBXGH)
cat("Missing HbA1c:", sum(is.na(nhanes_women$LBXGH)), "\n\n")

# Fasting glucose (from GLU file)
cat("Fasting glucose (LBXGLU) summary:\n")
summary(nhanes_women$LBXGLU)
cat("Missing fasting glucose:", sum(is.na(nhanes_women$LBXGLU)), "\n\n")

# Self-reported diabetes diagnosis (from DIQ file)
cat("Self-reported diabetes (DIQ010) distribution:\n")
table(nhanes_women$DIQ010, useNA = "always")
cat("\n")

# --- 3. Recode special missing values in DIQ010 ------------------------------
# NHANES codes 7 (Refused) and 9 (Don't know) are not true responses
# They must be converted to NA before using this variable in outcome definition

nhanes_women <- nhanes_women |>
  mutate(
    DIQ010_clean = case_when(
      DIQ010 == 1 ~ 1,   # Yes — told by doctor they have diabetes → keep as positive
      DIQ010 == 2 ~ 2,   # No → keep as negative
      DIQ010 == 3 ~ 3,   # Borderline — will handle separately below
      DIQ010 %in% c(7, 9) ~ NA_real_,  # Refused / Don't know → missing
      TRUE ~ NA_real_    # Anything else unexpected → also missing
    )
  )

cat("DIQ010_clean distribution after recoding:\n")
table(nhanes_women$DIQ010_clean, useNA = "always")

# --- 4. Define the outcome variable ------------------------------------------
# Decision documented here:
# POSITIVE class (diabetes = 1) defined as ANY of the following:
#   a) HbA1c >= 6.5%          (ADA threshold for diabetes diagnosis)
#   b) Fasting glucose >= 126 mg/dL  (ADA threshold for diabetes diagnosis)
#   c) Self-reported doctor diagnosis (DIQ010_clean == 1)
#
# PREDIABETES decision:
#   Participants with HbA1c 5.7-6.4% but no other diabetes criterion
#   are classified as NEGATIVE (0) for this binary model.
#   Rationale: The aim is to predict confirmed diabetes, not prediabetes.
#   Prediabetes will be noted as a limitation and future direction.
#
# NEGATIVE class (diabetes = 0):
#   All others who do not meet any positive criterion above.
#
# Participants where ALL three source variables are missing will be NA
# and will be handled during imputation in Phase 5.

nhanes_women <- nhanes_women |>
  mutate(
    diabetes = case_when(
      
      # Positive class — any one criterion is sufficient
      LBXGH >= 6.5                          ~ 1,  # HbA1c criterion
      LBXGLU >= 126                         ~ 1,  # Fasting glucose criterion
      DIQ010_clean == 1                     ~ 1,  # Self-report criterion
      
      # Negative class — none of the positive criteria met
      (is.na(LBXGH) | LBXGH < 6.5) &
        (is.na(LBXGLU) | LBXGLU < 126) &
        DIQ010_clean == 2                   ~ 0,
      
      # Borderline/prediabetes with no confirmed diabetes criterion → negative
      (is.na(LBXGH) | LBXGH < 6.5) &
        (is.na(LBXGLU) | LBXGLU < 126) &
        DIQ010_clean == 3                   ~ 0,
      
      # Everything else → NA (will be addressed in Phase 5)
      TRUE                                  ~ NA_real_
    )
  )

# --- 5. Check the outcome variable distribution ------------------------------
cat("Diabetes outcome variable distribution:\n")
table(nhanes_women$diabetes, useNA = "always")

cat("\nOutcome as proportions:\n")
prop.table(table(nhanes_women$diabetes)) |> round(3)

# --- 6. Cross-tabulate the three source variables to audit overlap -----------
cat("\nCross-tab: HbA1c-based diabetes vs self-reported diagnosis:\n")
table(
  HbA1c_diabetes  = nhanes_women$LBXGH >= 6.5,
  Self_reported    = nhanes_women$DIQ010_clean == 1,
  useNA            = "always"
)

# --- 7. Save the dataset with outcome variable defined -----------------------
saveRDS(nhanes_women, file = "nhanes_women_outcome.rds")

cat("\nDataset with outcome variable saved as nhanes_women_outcome.rds\n")

# =============================================================================
# Phase 4: Variable Selection and Codebook Review
# =============================================================================

# --- 1. Load the dataset with outcome defined ---------------------------------
nhanes_women <- readRDS("nhanes_women_outcome.rds")


# --- 2. Define the variables to keep -----------------------------------------
# These are organised by domain for clarity.
# Every variable kept here must have a documented reason.

vars_to_keep <- c(
  
  # --- Survey design variables (must always be retained) ---
  "SEQN",          # Respondent ID — unique identifier
  "WTMEC2YR",      # MEC exam survey weight — required for all weighted analysis
  "SDMVSTRA",      # Masked variance stratum — required for survey design
  "SDMVPSU",       # Masked variance PSU — required for survey design
  
  # --- Outcome variable ---
  "diabetes",      # Binary outcome: 1 = diabetic, 0 = non-diabetic
  
  # --- Outcome source variables (kept for audit trail) ---
  "LBXGH",         # HbA1c (%) — primary outcome source
  "LBXGLU",        # Fasting plasma glucose (mg/dL) — outcome source
  "DIQ010_clean",  # Self-reported diabetes diagnosis (cleaned) — outcome source
  
  # --- Sociodemographic variables ---
  "RIDAGEYR",      # Age in years (continuous)
  "RIDRETH3",      # Race/ethnicity (6 categories including non-Hispanic Asian)
  "DMDEDUC2",      # Education level (adults 20+)
  "INDFMPIR",      # Income-to-poverty ratio (continuous, 0–5)
  
  # --- Anthropometric / clinical variables ---
  "BMXBMI",        # Body mass index (kg/m²)
  "BMXWAIST",      # Waist circumference (cm)
  "BPXSY1",        # Systolic blood pressure — reading 1
  "BPXDI1",        # Diastolic blood pressure — reading 1
  "BPXSY2",        # Systolic blood pressure — reading 2
  "BPXDI2",        # Diastolic blood pressure — reading 2
  "BPXSY3",        # Systolic blood pressure — reading 3
  "BPXDI3",        # Diastolic blood pressure — reading 3
  
  # --- Lipid variables ---
  "LBDHDD",        # HDL cholesterol (mg/dL)
  "LBXTR",         # Triglycerides (mg/dL)
  "LBDLDL",        # LDL cholesterol (mg/dL)
  
  # --- Physical activity ---
  "PAD680",        # Minutes of sedentary activity per day
  
  # --- Smoking ---
  "SMQ020",        # Smoked at least 100 cigarettes in life
  "SMQ040",        # Current smoking status (among ever-smokers)
  
  # --- Alcohol ---
  "ALQ121",        # How often drink alcohol — past 12 months
  "ALQ151",        # Ever had 4 or more drinks every day
  
  # --- Health insurance ---
  "HIQ011",        # Covered by health insurance
  
  # --- Reproductive health ---
  "RHQ131",        # Ever told you had gestational diabetes
  "RHQ160",        # How many times have been pregnant
  "RHQ162"         # Age at first pregnancy
)

# --- 3. Check which variables exist before selecting -------------------------
# This step catches any variable name typos before they cause silent errors
missing_vars <- vars_to_keep[!vars_to_keep %in% names(nhanes_women)]

if (length(missing_vars) == 0) {
  cat("All variables found in dataset. Proceeding with selection.\n\n")
} else {
  cat("WARNING — These variables were NOT found in the dataset:\n")
  print(missing_vars)
  cat("\nCheck spelling against NHANES codebook before proceeding.\n")
}

# --- 4. Select only the variables to keep ------------------------------------
nhanes_selected <- nhanes_women |>
  select(all_of(vars_to_keep))

cat("Selected dataset dimensions:", nrow(nhanes_selected), "rows,", ncol(nhanes_selected), "columns\n\n")

# --- 5. Review missingness across selected variables -------------------------
missing_summary <- nhanes_selected |>
  summarise(across(everything(), ~ sum(is.na(.)))) |>
  tidyr::pivot_longer(everything(),
                      names_to  = "variable",
                      values_to = "n_missing") |>
  mutate(pct_missing = round(n_missing / nrow(nhanes_selected) * 100, 1)) |>
  arrange(desc(n_missing))

cat("Missingness summary across selected variables:\n")
print(missing_summary, n = Inf)

# --- 6. Save the selected dataset --------------------------------------------
saveRDS(nhanes_selected, file = "nhanes_women_selected.rds")

cat("\nSelected dataset saved as nhanes_women_selected.rds\n")

# =============================================================================
# Phase 5: Missingness Assessment and Multiple Imputation
# =============================================================================

# --- 1. Load packages --------------------------------------------------------
library(dplyr)
library(mice)
library(naniar)   # for missingness visualisation

# --- 2. Load the selected dataset --------------------------------------------
nhanes_selected <- readRDS("nhanes_women_selected.rds")

# --- 3. Recode SMQ040 before imputation --------------------------------------
# SMQ040 asks "Do you now smoke cigarettes?" but was ONLY asked of
# people who said yes to SMQ020 (ever smoked 100+ cigarettes).
# Never-smokers (SMQ020 == 2) have NA for SMQ040 — but this is NOT
# true missingness. It means they were never asked.
# We recode these as a new category: 0 = never smoker.
# This makes SMQ040 a 3-category variable:
#   0 = Never smoked (was not asked SMQ040)
#   1 = Smokes every day
#   2 = Smokes some days
#   3 = Does not smoke now (former smoker)

cat("SMQ020 distribution (ever smoked 100+ cigarettes):\n")
table(nhanes_selected$SMQ020, useNA = "always")

cat("\nSMQ040 distribution before recoding:\n")
table(nhanes_selected$SMQ040, useNA = "always")

nhanes_clean <- nhanes_selected |>
  mutate(
    SMQ040_rec = case_when(
      SMQ020 == 2              ~ 0,   # Never smoker — was never asked SMQ040
      SMQ020 == 1 & SMQ040 == 1 ~ 1, # Current every-day smoker
      SMQ020 == 1 & SMQ040 == 2 ~ 2, # Current some-day smoker
      SMQ020 == 1 & SMQ040 == 3 ~ 3, # Former smoker
      SMQ020 %in% c(7, 9)      ~ NA_real_,  # Refused/don't know SMQ020
      TRUE                     ~ NA_real_   # Any remaining unclear cases
    )
  )

cat("\nSMQ040_rec distribution after recoding:\n")
table(nhanes_clean$SMQ040_rec, useNA = "always")

# --- 4. Drop original SMQ040 and SMQ020 now that recoding is done ------------
nhanes_clean <- nhanes_clean |>
  select(-SMQ040,   # Replaced by SMQ040_rec
         -SMQ020)   # Its information is now captured in SMQ040_rec

cat("Dimensions after smoking recode cleanup:",
    nrow(nhanes_clean), "rows,", ncol(nhanes_clean), "columns\n\n")

# --- 5. Create mean blood pressure variables and drop individual readings ----
# Taking the mean of available readings is standard practice.
# rowMeans() with na.rm = TRUE means: average whatever readings exist.
# If someone has readings 1 and 2 but not 3, it averages 1 and 2.

nhanes_clean <- nhanes_clean |>
  mutate(
    mean_sbp = rowMeans(select(nhanes_clean, BPXSY1, BPXSY2, BPXSY3),
                        na.rm = TRUE),
    mean_dbp = rowMeans(select(nhanes_clean, BPXDI1, BPXDI2, BPXDI3),
                        na.rm = TRUE)
  ) |>
  select(-BPXSY1, -BPXSY2, -BPXSY3,   # Drop individual systolic readings
         -BPXDI1, -BPXDI2, -BPXDI3)   # Drop individual diastolic readings

cat("Mean SBP summary:\n")
summary(nhanes_clean$mean_sbp)

cat("\nMean DBP summary:\n")
summary(nhanes_clean$mean_dbp)

# --- 6. Recode remaining NHANES missing value codes to NA --------------------
# NHANES uses 7, 9, 77, 99, 777, 999 as "refused" or "don't know"
# These must be NA before imputation — mice treats numeric values as real data

nhanes_clean <- nhanes_clean |>
  mutate(
    # Education (DMDEDUC2): 7 = Refused, 9 = Don't know
    DMDEDUC2  = na_if(DMDEDUC2, 7),
    DMDEDUC2  = na_if(DMDEDUC2, 9),
    
    # Alcohol frequency (ALQ121): 777 = Refused, 999 = Don't know
    ALQ121    = na_if(ALQ121, 777),
    ALQ121    = na_if(ALQ121, 999),
    
    # Alcohol heavy (ALQ151): 7 = Refused, 9 = Don't know
    ALQ151    = na_if(ALQ151, 7),
    ALQ151    = na_if(ALQ151, 9),
    
    # Gestational diabetes (RHQ131): 2 = No, but 7/9 = refused/don't know
    RHQ131    = na_if(RHQ131, 7),
    RHQ131    = na_if(RHQ131, 9),
    
    # Number of pregnancies (RHQ160): 77 = Refused, 99 = Don't know
    RHQ160    = na_if(RHQ160, 77),
    RHQ160    = na_if(RHQ160, 99),
    
    # Age at first pregnancy (RHQ162): 777 = Refused
    RHQ162    = na_if(RHQ162, 777),
    
    # Sedentary minutes (PAD680): 7777 = Refused, 9999 = Don't know
    PAD680    = na_if(PAD680, 7777),
    PAD680    = na_if(PAD680, 9999),
    
    # Health insurance (HIQ011): 7 = Refused, 9 = Don't know
    HIQ011    = na_if(HIQ011, 7),
    HIQ011    = na_if(HIQ011, 9)
  )

cat("Missingness after NHANES code recoding:\n")
colSums(is.na(nhanes_clean)) |> sort(decreasing = TRUE)

# --- 7. Define the imputation dataset ----------------------------------------
# Variables excluded from imputation model:
# - SEQN: just an ID number, not a real variable
# - WTMEC2YR, SDMVSTRA, SDMVPSU: survey design variables, not substantive
# - LBXGH, LBXGLU, DIQ010_clean: outcome source variables — we keep
#   'diabetes' in the imputation model as a predictor (this is correct
#   practice — the outcome should inform imputation of predictors)
#   but we do not want to impute the raw lab values themselves

vars_exclude_from_imputation <- c("SEQN", "WTMEC2YR", "SDMVSTRA",
                                  "SDMVPSU", "LBXGH", "LBXGLU",
                                  "DIQ010_clean")

nhanes_for_imputation <- nhanes_clean |>
  select(-all_of(vars_exclude_from_imputation))

cat("Variables going into mice imputation model:\n")
print(names(nhanes_for_imputation))
cat("\nDimensions:", nrow(nhanes_for_imputation), "rows,",
    ncol(nhanes_for_imputation), "columns\n\n")

# --- 8. Run multiple imputation with mice ------------------------------------
set.seed(123)   # For reproducibility — same seed = same imputed values every run

cat("Running mice imputation — this may take a few minutes...\n")

imputed <- mice(
  nhanes_for_imputation,
  m      = 5,      # Number of imputed datasets — 5 is standard
  maxit  = 20,     # Number of iterations per imputed dataset
  method = "pmm",  # Predictive mean matching — good for continuous and skewed data
  seed   = 123,    # Seed inside mice as well as set.seed above
  printFlag = TRUE # Print iteration progress so you can see it working
)

cat("\nImputation complete.\n")
summary(imputed)

# --- 9. Check convergence of imputation -------------------------------------
plot(imputed)

# --- 10. Check imputed values look reasonable --------------------------------
# Compare observed vs imputed distributions for key variables
# densityplot shows the density of observed (blue) vs imputed (red) values
# They should be similar in shape — not identical, but not wildly different

densityplot(imputed, ~ BMXBMI + INDFMPIR + LBDHDD + PAD680)

# --- 11. Save the mids object and one complete dataset for inspection --------
# Save the full mice object (mids) — needed for pooled analysis in Phase 8
saveRDS(imputed, file = "nhanes_imputed_mids.rds")

# Extract and save the first completed dataset for Phase 7 descriptive analysis
nhanes_complete1 <- complete(imputed, action = 1)

# Add back the survey design variables and outcome source variables
# that we excluded from mice — they need to travel with the data
nhanes_complete1 <- nhanes_complete1 |>
  bind_cols(
    nhanes_clean |>
      select(SEQN, WTMEC2YR, SDMVSTRA, SDMVPSU,
             LBXGH, LBXGLU, DIQ010_clean)
  )

saveRDS(nhanes_complete1, file = "nhanes_complete1.rds")

cat("Mice mids object saved as nhanes_imputed_mids.rds\n")
cat("First completed dataset saved as nhanes_complete1.rds\n")
cat("Dimensions of complete dataset:", nrow(nhanes_complete1), "rows,",
    ncol(nhanes_complete1), "columns\n")

# =============================================================================
# Phase 6: Survey Design Object Setup
# =============================================================================

# --- 1. Load packages ------------------------------------------------------
library(survey)

# --- 2. Load the completed dataset -------------------------------------------
nhanes_complete1 <- readRDS("nhanes_complete1.rds")

# --- 3. Set the lonely PSU option BEFORE creating the design object ----------
options(survey.lonely.psu = "adjust")

# --- 4. Create the survey design object --------------------------------------
nhanes_design <- svydesign(
  id      = ~SDMVPSU,     # PSU variable — the primary sampling unit
  strata  = ~SDMVSTRA,    # Stratum variable — the sampling stratum
  weights = ~WTMEC2YR,    # Survey weight — MEC exam weight
  data    = nhanes_complete1,  # The completed imputed dataset
  nest    = TRUE          # PSUs are nested within strata (required for NHANES)
)

# --- 5. Verify the design object ---------------------------------------------
cat("Survey design summary:\n")
summary(nhanes_design)

# --- 6. Run basic weighted estimates to confirm the design works -------------
# Weighted sample size (sum of weights = estimated US population represented)
cat("\nEstimated US population represented (sum of weights):\n")
cat(round(sum(weights(nhanes_design)), 0), "\n\n")

# Weighted prevalence of diabetes
cat("Weighted diabetes prevalence:\n")
svymean(~diabetes, nhanes_design, na.rm = TRUE)

# --- 7. Weighted prevalence by race/ethnicity --------------------------------
cat("\nWeighted diabetes prevalence by race/ethnicity:\n")
svyby(~diabetes, ~RIDRETH3, nhanes_design, svymean, na.rm = TRUE)

# --- 8. Save the design object -----------------------------------------------
saveRDS(nhanes_design, file = "nhanes_survey_design.rds")

cat("\nSurvey design object saved as nhanes_survey_design.rds\n")

# =============================================================================
# Phase 7: Descriptive and Exploratory Analysis
# =============================================================================

# --- 1. Load packages --------------------------------------------------------
library(gtsummary)
library(ggplot2)
library(forcats)
library(patchwork)  # For combining plots into one figure

# --- 2. Load data and design object ------------------------------------------
nhanes_complete1 <- readRDS("nhanes_complete1.rds")
options(survey.lonely.psu = "adjust")

nhanes_design <- svydesign(
  id      = ~SDMVPSU,
  strata  = ~SDMVSTRA,
  weights = ~WTMEC2YR,
  data    = nhanes_complete1,
  nest    = TRUE
)

# --- 3. Create labelled factor variables for Table 1 -------------------------
# We need human-readable labels on all categorical variables.
# NHANES stores everything as numbers — we convert to factors with labels
# so Table 1 shows "Mexican American" instead of "1"

nhanes_complete1 <- nhanes_complete1 |>
  mutate(
    
    # Outcome
    diabetes_f = factor(diabetes,
                        levels = c(0, 1),
                        labels = c("No diabetes", "Diabetes")),
    
    # Race/ethnicity
    race_f = factor(RIDRETH3,
                    levels = c(1, 2, 3, 4, 6, 7),
                    labels = c("Mexican American",
                               "Other Hispanic",
                               "Non-Hispanic White",
                               "Non-Hispanic Black",
                               "Non-Hispanic Asian",
                               "Other/Multiracial")),
    
    # Education
    educ_f = factor(DMDEDUC2,
                    levels = c(1, 2, 3, 4, 5),
                    labels = c("Less than 9th grade",
                               "9–11th grade",
                               "High school/GED",
                               "Some college",
                               "College graduate or above")),
    
    # Health insurance
    insurance_f = factor(HIQ011,
                         levels = c(1, 2),
                         labels = c("Insured", "Uninsured")),
    
    # Gestational diabetes
    gdm_f = factor(RHQ131,
                   levels = c(1, 2),
                   labels = c("Yes", "No")),
    
    # Smoking status
    smoking_f = factor(SMQ040_rec,
                       levels = c(0, 1, 2, 3),
                       labels = c("Never smoker",
                                  "Current: every day",
                                  "Current: some days",
                                  "Former smoker")),
    
    # BMI category (derived from BMXBMI)
    bmi_cat = case_when(
      BMXBMI < 18.5              ~ "Underweight",
      BMXBMI >= 18.5 & BMXBMI < 25 ~ "Normal weight",
      BMXBMI >= 25   & BMXBMI < 30 ~ "Overweight",
      BMXBMI >= 30               ~ "Obese"
    ),
    bmi_cat = factor(bmi_cat,
                     levels = c("Underweight", "Normal weight",
                                "Overweight", "Obese"))
  )

# --- 4. Recreate design with labelled data -----------------------------------
nhanes_design <- svydesign(
  id      = ~SDMVPSU,
  strata  = ~SDMVSTRA,
  weights = ~WTMEC2YR,
  data    = nhanes_complete1,   # Now using the labelled version
  nest    = TRUE
)

# --- 5. Build Table 1 using tbl_svysummary -----------------------------------
table1 <- tbl_svysummary(
  data     = nhanes_design,
  by       = diabetes_f,          # Split columns by diabetes status
  include  = c(                   # Variables to include in the table
    RIDAGEYR, race_f, educ_f, INDFMPIR,
    bmi_cat, BMXBMI, BMXWAIST,
    mean_sbp, mean_dbp,
    LBDHDD, LBXTR, LBDLDL,
    LBXGH, LBXGLU,
    insurance_f, smoking_f,
    ALQ121, PAD680,
    gdm_f, RHQ160
  ),
  statistic = list(
    all_continuous()  ~ "{mean} ({sd})",      # Mean (SD) for continuous vars
    all_categorical() ~ "{n_unweighted} ({p}%)"  # N (weighted %) for categorical
  ),
  digits = list(
    all_continuous()  ~ 1,
    all_categorical() ~ c(0, 1)
  ),
  missing = "no"    # Hide missing counts — imputation handled this already
) |>
  add_overall() |>                            # Add an overall column
  add_p(                                      # Add p-values
    test = list(
      all_continuous()  ~ "svy.t.test",       # Survey-weighted t-test
      all_categorical() ~ "svy.chisq.test"    # Survey-weighted chi-square
    )
  ) |>
  modify_header(label ~ "**Characteristic**") |>
  modify_caption("**Table 1. Weighted characteristics of women aged 18–49, NHANES 2017–2018**") |>
  bold_labels()

# Print the table
table1

# --- 6. Visualisation 1 — Weighted diabetes prevalence by race/ethnicity -----

# Get weighted prevalence by race
race_prev <- svyby(~diabetes, ~race_f, nhanes_design, svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    prevalence = diabetes * 100,
    se         = se * 100,
    ci_low     = prevalence - 1.96 * se,
    ci_high    = prevalence + 1.96 * se,
    race_f     = fct_reorder(race_f, prevalence)  # Order bars by prevalence
  )

ggplot(race_prev, aes(x = race_f, y = prevalence, fill = race_f)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                width = 0.2, colour = "black") +
  coord_flip() +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title    = "Weighted Diabetes Prevalence by Race/Ethnicity",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    x        = NULL,
    y        = "Weighted Prevalence (%)",
    caption  = "Error bars represent 95% confidence intervals"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

# --- 7. Visualisation 2 — BMI distribution by diabetes status ----------------
ggplot(nhanes_complete1, aes(x = BMXBMI, fill = diabetes_f)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("steelblue", "tomato")) +
  labs(
    title    = "BMI Distribution by Diabetes Status",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    x        = "BMI (kg/m²)",
    y        = "Density",
    fill     = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "top")

# --- 8. Visualisation 3 — HbA1c distribution by diabetes status --------------
nhanes_complete1 |>
  filter(!is.na(LBXGH)) |>
  ggplot(aes(x = LBXGH, fill = diabetes_f)) +
  geom_density(alpha = 0.5) +
  geom_vline(xintercept = 6.5, linetype = "dashed",
             colour = "darkred", linewidth = 0.8) +
  scale_fill_manual(values = c("steelblue", "tomato")) +
  annotate("text", x = 6.7, y = 1.2,
           label = "ADA threshold\n(6.5%)",
           colour = "darkred", size = 3.5, hjust = 0) +
  labs(
    title    = "HbA1c Distribution by Diabetes Status",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    x        = "HbA1c (%)",
    y        = "Density",
    fill     = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "top")

# --- 9. Visualisation 4 — Weighted prevalence by BMI category ----------------
bmi_prev <- svyby(~diabetes, ~bmi_cat, nhanes_design, svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    prevalence = diabetes * 100,
    se         = se * 100,
    ci_low     = prevalence - 1.96 * se,
    ci_high    = prevalence + 1.96 * se
  )

ggplot(bmi_prev, aes(x = bmi_cat, y = prevalence, fill = bmi_cat)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                width = 0.2, colour = "black") +
  scale_fill_brewer(palette = "OrRd") +
  labs(
    title    = "Weighted Diabetes Prevalence by BMI Category",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    x        = "BMI Category",
    y        = "Weighted Prevalence (%)",
    caption  = "Error bars represent 95% confidence intervals"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

# --- Visualisation 5 — Prevalence by Education -------------------------------
educ_prev <- svyby(~diabetes, ~educ_f, nhanes_design,
                   svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    prevalence = diabetes * 100,
    se         = se * 100,
    ci_low     = pmax(0, prevalence - 1.96 * se),  # pmax prevents negative CIs
    ci_high    = prevalence + 1.96 * se
  )

plot_educ <- ggplot(educ_prev,
                    aes(x = educ_f, y = prevalence, fill = educ_f)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                width = 0.2, colour = "black") +
  coord_flip() +
  scale_fill_brewer(palette = "Blues", direction = -1) +
  scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 20)) +
  labs(
    title = "Diabetes Prevalence by Education Level",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    x = NULL,
    y = "Weighted Prevalence (%)",
    caption = "Error bars represent 95% confidence intervals"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

plot_educ

# --- Visualisation 6 — Prevalence by Insurance Status ------------------------
ins_prev <- svyby(~diabetes, ~insurance_f, nhanes_design,
                  svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    prevalence = diabetes * 100,
    se         = se * 100,
    ci_low     = pmax(0, prevalence - 1.96 * se),
    ci_high    = prevalence + 1.96 * se
  )

plot_ins <- ggplot(ins_prev,
                   aes(x = insurance_f, y = prevalence, fill = insurance_f)) +
  geom_col(width = 0.5, show.legend = FALSE) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                width = 0.15, colour = "black") +
  scale_fill_manual(values = c("steelblue", "tomato")) +
  labs(
    title    = "Diabetes Prevalence by Insurance Status",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    x        = NULL,
    y        = "Weighted Prevalence (%)",
    caption  = "Error bars represent 95% confidence intervals"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

plot_ins

# --- Visualisation 7 — Prevalence by Gestational Diabetes History ------------
gdm_prev <- svyby(~diabetes, ~gdm_f, nhanes_design,
                  svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    prevalence = diabetes * 100,
    se         = se * 100,
    ci_low     = pmax(0, prevalence - 1.96 * se),
    ci_high    = prevalence + 1.96 * se
  )

plot_gdm <- ggplot(gdm_prev,
                   aes(x = gdm_f, y = prevalence, fill = gdm_f)) +
  geom_col(width = 0.5, show.legend = FALSE) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                width = 0.15, colour = "black") +
  scale_fill_manual(values = c("tomato", "steelblue")) +
  labs(
    title    = "Diabetes Prevalence by Gestational Diabetes History",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    x        = "History of Gestational Diabetes",
    y        = "Weighted Prevalence (%)",
    caption  = "Error bars represent 95% confidence intervals"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

plot_gdm

# --- Visualisation 8 — Prevalence by Smoking Status --------------------------
smoke_prev <- svyby(~diabetes, ~smoking_f, nhanes_design,
                    svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    prevalence = diabetes * 100,
    se         = se * 100,
    ci_low     = pmax(0, prevalence - 1.96 * se),
    ci_high    = prevalence + 1.96 * se,
    smoking_f  = fct_reorder(smoking_f, prevalence)
  )

plot_smoke <- ggplot(smoke_prev,
                     aes(x = smoking_f, y = prevalence, fill = smoking_f)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high),
                width = 0.2, colour = "black") +
  coord_flip() +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title    = "Diabetes Prevalence by Smoking Status",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    x        = NULL,
    y        = "Weighted Prevalence (%)",
    caption  = "Error bars represent 95% confidence intervals"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

plot_smoke

# --- Visualisation 9 — Continuous variables boxplot by diabetes status -------
# For continuous variables, side-by-side boxplots work better than bar charts
# We show age, BMI, waist, SBP, HDL, triglycerides in one combined figure

# Helper function to make one boxplot
make_box <- function(var, label, data) {
  ggplot(data |> filter(!is.na(diabetes_f)),
         aes(x = diabetes_f, y = .data[[var]], fill = diabetes_f)) +
    geom_boxplot(alpha = 0.7, outlier.size = 0.8) +
    scale_fill_manual(values = c("steelblue", "tomato")) +
    labs(x = NULL, y = label, fill = NULL) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "none")
}

p_age  <- make_box("RIDAGEYR", "Age (years)", nhanes_complete1)
p_bmi  <- make_box("BMXBMI",   "BMI (kg/m²)", nhanes_complete1)
p_wst  <- make_box("BMXWAIST", "Waist circumference (cm)", nhanes_complete1)
p_sbp  <- make_box("mean_sbp", "Mean SBP (mmHg)", nhanes_complete1)
p_hdl  <- make_box("LBDHDD",   "HDL cholesterol (mg/dL)", nhanes_complete1)
p_trig <- make_box("LBXTR",    "Triglycerides (mg/dL)", nhanes_complete1)

# Combine into one figure using patchwork
combined_boxplots <- (p_age + p_bmi + p_wst) / (p_sbp + p_hdl + p_trig) +
  plot_annotation(
    title    = "Clinical Variables by Diabetes Status",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    theme    = theme(plot.title = element_text(face = "bold", size = 14))
  )

combined_boxplots

# --- Visualisation 10 — Alcohol use distribution by diabetes status ----------
# ALQ121 is a frequency scale (0-never to 10-every day)
# We treat it as approximately continuous and use density plots

ggplot(nhanes_complete1 |> filter(!is.na(diabetes_f)),
       aes(x = ALQ121, fill = diabetes_f)) +
  geom_histogram(aes(y = after_stat(density)),
                 binwidth = 1, position = "dodge",
                 alpha = 0.7, colour = "white") +
  scale_fill_manual(values = c("steelblue", "tomato")) +
  labs(
    title    = "Alcohol Use Frequency by Diabetes Status",
    subtitle = "Women aged 18–49, NHANES 2017–2018",
    x        = "Alcohol drinking frequency (past 12 months)",
    y        = "Density",
    fill     = NULL,
    caption  = "Scale: 0 = never, 10 = every day"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "top")

# --- 10. Save all outputs ----------------------------------------------------
# Save the labelled complete dataset (with factor variables added)
saveRDS(nhanes_complete1, file = "nhanes_complete1_labelled.rds")

# Save Table 1 as a Word document for your portfolio/write-up
table1 |>
  as_gt() |>
  gt::gtsave("table1_weighted.docx")

cat("Table 1 saved as table1_weighted.docx\n")
cat("Labelled dataset saved as nhanes_complete1_labelled.rds\n")


# ============================================================
# Complete Power BI data exports — R
# Run this after loading nhanes_complete1_labelled.rds
# ============================================================

library(dplyr)
library(survey)
library(tidyr)

nhanes_complete1 <- readRDS("nhanes_complete1_labelled.rds")
options(survey.lonely.psu = "adjust")

nhanes_design <- svydesign(
  id      = ~SDMVPSU,
  strata  = ~SDMVSTRA,
  weights = ~WTMEC2YR,
  data    = nhanes_complete1,
  nest    = TRUE
)

# --- 1. Prevalence by smoking status ----------------------------------------
smoke_prev <- svyby(~diabetes, ~smoking_f, nhanes_design,
                    svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    Group          = as.character(smoking_f),
    Prevalence_pct = round(diabetes * 100, 2),
    SE_pct         = round(se * 100, 2),
    CI_low         = round(pmax(0, (diabetes - 1.96*se)) * 100, 2),
    CI_high        = round((diabetes + 1.96*se) * 100, 2)
  ) |>
  select(Group, Prevalence_pct, SE_pct, CI_low, CI_high)

write.csv(smoke_prev, "prevalence_by_smoking.csv", row.names = FALSE)
cat("Saved: prevalence_by_smoking.csv\n")

# --- 2. Prevalence by gestational diabetes ----------------------------------
gdm_prev <- svyby(~diabetes, ~gdm_f, nhanes_design,
                  svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    Group          = as.character(gdm_f),
    Prevalence_pct = round(diabetes * 100, 2),
    SE_pct         = round(se * 100, 2),
    CI_low         = round(pmax(0, (diabetes - 1.96*se)) * 100, 2),
    CI_high        = round((diabetes + 1.96*se) * 100, 2)
  ) |>
  select(Group, Prevalence_pct, SE_pct, CI_low, CI_high)

write.csv(gdm_prev, "prevalence_by_gdm.csv", row.names = FALSE)
cat("Saved: prevalence_by_gdm.csv\n")

# --- 3. Individual-level data for boxplots ----------------------------------
# Power BI can build boxplots from individual observations
# We export the key continuous variables with diabetes status label

boxplot_data <- nhanes_complete1 |>
  filter(!is.na(diabetes_f)) |>
  select(
    diabetes_f,
    Age           = RIDAGEYR,
    BMI           = BMXBMI,
    Waist_cm      = BMXWAIST,
    Triglycerides = LBXTR,
    HDL           = LBDHDD,
    Mean_SBP      = mean_sbp,
    Mean_DBP      = mean_dbp,
    Survey_weight = WTMEC2YR
  ) |>
  rename(Diabetes_status = diabetes_f)

write.csv(boxplot_data, "boxplot_data.csv", row.names = FALSE)
cat("Saved: boxplot_data.csv\n")

# --- 4. Weighted Table 1 summary for Power BI matrix -----------------------
# Weighted means and SDs for continuous variables by diabetes status

table1_continuous <- nhanes_complete1 |>
  filter(!is.na(diabetes_f)) |>
  group_by(Diabetes_status = diabetes_f) |>
  summarise(
    Age_mean       = round(weighted.mean(RIDAGEYR, WTMEC2YR, na.rm=TRUE), 1),
    BMI_mean       = round(weighted.mean(BMXBMI,   WTMEC2YR, na.rm=TRUE), 1),
    Waist_mean     = round(weighted.mean(BMXWAIST, WTMEC2YR, na.rm=TRUE), 1),
    Trig_mean      = round(weighted.mean(LBXTR,    WTMEC2YR, na.rm=TRUE), 1),
    HDL_mean       = round(weighted.mean(LBDHDD,   WTMEC2YR, na.rm=TRUE), 1),
    SBP_mean       = round(weighted.mean(mean_sbp, WTMEC2YR, na.rm=TRUE), 1),
    DBP_mean       = round(weighted.mean(mean_dbp, WTMEC2YR, na.rm=TRUE), 1),
    .groups = "drop"
  )

write.csv(table1_continuous, "table1_continuous.csv", row.names = FALSE)
cat("Saved: table1_continuous.csv\n")

# --- 5. Unadjusted OR results — clean format --------------------------------
# Already saved from Phase 8 as unadjusted_OR_results.csv
# Read it back and confirm it has the right columns

or_check <- read.csv("unadjusted_OR_results.csv")
cat("\nUnadjusted OR file columns:", names(or_check), "\n")
cat("Rows:", nrow(or_check), "\n")

cat("\nAll R exports complete.\n")

# =============================================================================
# Phase 8: Survey-Weighted Logistic Regression
# =============================================================================

# --- 1. Load data and recreate design ----------------------------------------

nhanes_complete1 <- readRDS("nhanes_complete1_labelled.rds")
options(survey.lonely.psu = "adjust")

nhanes_design <- svydesign(
  id      = ~SDMVPSU,
  strata  = ~SDMVSTRA,
  weights = ~WTMEC2YR,
  data    = nhanes_complete1,
  nest    = TRUE
)

cat("Design created. Residual df available:", degf(nhanes_design), "\n")

# --- 2. PART A — Unadjusted models, one predictor at a time ------------------
# We run a separate svyglm for each predictor individually.
# Each model has only 1 predictor so df is never a problem.
# This gives us clean, stable unadjusted ORs for all 13 predictors.

# Continuous predictors — entered as-is
continuous_predictors <- c(
  "RIDAGEYR",   # Age
  "INDFMPIR",   # Income-to-poverty ratio
  "BMXBMI",     # BMI
  "mean_sbp",   # Mean SBP
  "mean_dbp",   # Mean DBP
  "LBDHDD",     # HDL cholesterol
  "LBXTR",      # Triglycerides
  "PAD680",     # Sedentary minutes
  "RHQ160"      # Number of pregnancies
)

# Categorical predictors — must be factored with reference levels set
# We set reference levels that make clinical sense:
#   Race: Non-Hispanic White (3) — largest group, standard reference
#   Education: College graduate (5) — highest education as reference
#   Smoking: Never smoker (0) — unexposed group as reference
#   GDM history: No (2) — unexposed group as reference

nhanes_complete1 <- nhanes_complete1 |>
  mutate(
    RIDRETH3_f   = relevel(factor(RIDRETH3),   ref = "3"),
    DMDEDUC2_f   = relevel(factor(DMDEDUC2),   ref = "5"),
    SMQ040_rec_f = relevel(factor(SMQ040_rec), ref = "0"),
    RHQ131_f     = relevel(factor(RHQ131),     ref = "2")
  )

# Recreate design with factored variables
nhanes_design <- svydesign(
  id      = ~SDMVPSU,
  strata  = ~SDMVSTRA,
  weights = ~WTMEC2YR,
  data    = nhanes_complete1,
  nest    = TRUE
)

categorical_predictors <- c(
  "RIDRETH3_f",    # Race/ethnicity
  "DMDEDUC2_f",    # Education
  "SMQ040_rec_f",  # Smoking
  "RHQ131_f"       # Gestational diabetes history
)

# --- 3. Run unadjusted models for continuous predictors ----------------------
# Storage for results
unadj_results <- list()

for (pred in continuous_predictors) {
  
  formula_i <- as.formula(paste("diabetes ~", pred))
  
  fit <- svyglm(
    formula = formula_i,
    design  = nhanes_design,
    family  = quasibinomial(link = "logit")
  )
  
  coefs <- summary(fit)$coefficients
  b     <- coefs[2, "Estimate"]          # Coefficient (log OR)
  se    <- coefs[2, "Std. Error"]        # Standard error
  pval  <- coefs[2, "Pr(>|t|)"]         # p-value
  
  unadj_results[[pred]] <- data.frame(
    Variable  = pred,
    OR        = round(exp(b), 3),
    CI_low    = round(exp(b - 1.96 * se), 3),
    CI_high   = round(exp(b + 1.96 * se), 3),
    p_value   = round(pval, 3),
    type      = "continuous"
  )
  
  cat("  Fitted:", pred, "| OR =", round(exp(b), 3),
      "| p =", round(pval, 3), "\n")
}

cat("\nAll continuous unadjusted models fitted.\n\n")

# --- 4. Run unadjusted models for categorical predictors ---------------------
# For categorical predictors, each level gets its own row in the output
# We extract all levels except the reference

for (pred in categorical_predictors) {
  
  formula_i <- as.formula(paste("diabetes ~", pred))
  
  fit <- svyglm(
    formula = formula_i,
    design  = nhanes_design,
    family  = quasibinomial(link = "logit")
  )
  
  coefs <- summary(fit)$coefficients
  
  # All rows except intercept (row 1)
  for (j in 2:nrow(coefs)) {
    
    b    <- coefs[j, "Estimate"]
    se   <- coefs[j, "Std. Error"]
    pval <- coefs[j, "Pr(>|t|)"]
    
    label <- rownames(coefs)[j]  # e.g. "RIDRETH3_f1" or "DMDEDUC2_f4"
    
    unadj_results[[label]] <- data.frame(
      Variable  = label,
      OR        = round(exp(b), 3),
      CI_low    = round(exp(b - 1.96 * se), 3),
      CI_high   = round(exp(b + 1.96 * se), 3),
      p_value   = round(pval, 3),
      type      = "categorical"
    )
  }
  
  cat("  Fitted:", pred, "\n")
}

cat("\nAll categorical unadjusted models fitted.\n\n")

# --- 5. Combine and display unadjusted results table -------------------------
unadj_table <- bind_rows(unadj_results) |>
  mutate(
    OR_CI = paste0(OR, " (", CI_low, "–", CI_high, ")"),
    # Clean variable labels for display
    Variable = recode(Variable,
                      "RIDAGEYR"       = "Age (per year)",
                      "INDFMPIR"       = "Income-to-poverty ratio",
                      "BMXBMI"         = "BMI (per kg/m²)",
                      "mean_sbp"       = "Mean SBP (per mmHg)",
                      "mean_dbp"       = "Mean DBP (per mmHg)",
                      "LBDHDD"         = "HDL cholesterol (per mg/dL)",
                      "LBXTR"          = "Triglycerides (per mg/dL)",
                      "PAD680"         = "Sedentary minutes (per min)",
                      "RHQ160"         = "Number of pregnancies",
                      "RIDRETH3_f1"    = "Race: Mexican American vs NHW",
                      "RIDRETH3_f2"    = "Race: Other Hispanic vs NHW",
                      "RIDRETH3_f4"    = "Race: Non-Hispanic Black vs NHW",
                      "RIDRETH3_f6"    = "Race: Non-Hispanic Asian vs NHW",
                      "RIDRETH3_f7"    = "Race: Other/Multiracial vs NHW",
                      "DMDEDUC2_f1"    = "Education: <9th grade vs College",
                      "DMDEDUC2_f2"    = "Education: 9-11th grade vs College",
                      "DMDEDUC2_f3"    = "Education: High school vs College",
                      "DMDEDUC2_f4"    = "Education: Some college vs College",
                      "SMQ040_rec_f1"  = "Smoking: Every day vs Never",
                      "SMQ040_rec_f2"  = "Smoking: Some days vs Never",
                      "SMQ040_rec_f3"  = "Smoking: Former vs Never",
                      "RHQ131_f1"      = "Gestational diabetes: Yes vs No"
    ),
    significance = case_when(
      p_value < 0.001 ~ "***",
      p_value < 0.01  ~ "**",
      p_value < 0.05  ~ "*",
      TRUE            ~ ""
    )
  )

cat("Unadjusted odds ratios — all predictors:\n\n")
print(unadj_table[, c("Variable", "OR_CI", "p_value", "significance")],
      row.names = FALSE)

# --- 6. Forest plot — unadjusted ORs -----------------------------------------
plot_unadj <- unadj_table |>
  mutate(
    Variable = fct_reorder(Variable, OR),
    sig_col  = ifelse(p_value < 0.05, "Significant", "Not significant")
  )

ggplot(plot_unadj, aes(x = OR, y = Variable, colour = sig_col)) +
  geom_point(size = 2.5) +
  geom_errorbar(aes(xmin = CI_low, xmax = CI_high),
                width = 0.3, orientation = "y") +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey40") +
  scale_colour_manual(
    values = c("Not significant" = "grey60", "Significant" = "tomato")
  ) +
  scale_x_log10() +
  labs(
    title    = "Unadjusted Odds Ratios for Diabetes Risk",
    subtitle = "Survey-weighted logistic regression, NHANES 2017–2018\nWomen aged 18–49",
    x        = "Odds Ratio (log scale)",
    y        = NULL,
    colour   = NULL,
    caption  = "Each OR from a separate single-predictor model.\n* p<0.05  ** p<0.01  *** p<0.001"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title      = element_text(face = "bold"),
    legend.position = "bottom"
  )

# --- 7. PART B — Reduced adjusted model (3 continuous predictors only) -------

# With 15 df available, a model with 3 continuous predictors is stable.
# We use the three strongest continuous predictors from Part A:
# age, BMI, and triglycerides.
# Race and education are excluded from the adjusted model due to df constraints
# and are fully described in Table 1 and Part A unadjusted results.
# This limitation is documented in the write-up.

adj_formula <- diabetes ~ RIDAGEYR + BMXBMI + LBXTR + LBDHDD + PAD680

cat("\nAdjusted model formula:\n")
print(adj_formula)

adj_fit <- svyglm(
  formula = adj_formula,
  design  = nhanes_design,
  family  = quasibinomial(link = "logit")
)

cat("\nAdjusted model residual df:", adj_fit$df.residual, "\n")
cat("\nAdjusted model results:\n")
summary(adj_fit)

# --- 8. Extract and display adjusted ORs -------------------------------------

adj_coefs <- summary(adj_fit)$coefficients

adj_results <- adj_coefs |>
  as.data.frame() |>
  tibble::rownames_to_column("Variable") |>
  filter(Variable != "(Intercept)") |>
  mutate(
    OR      = round(exp(Estimate), 3),
    CI_low  = round(exp(Estimate - 1.96 * `Std. Error`), 3),
    CI_high = round(exp(Estimate + 1.96 * `Std. Error`), 3),
    p_value = round(`Pr(>|t|)`, 3),
    OR_CI   = paste0(OR, " (", CI_low, "–", CI_high, ")"),
    Variable = recode(Variable,
                      "RIDAGEYR" = "Age (per year)",
                      "BMXBMI"   = "BMI (per kg/m²)",
                      "LBXTR"    = "Triglycerides (per mg/dL)",
                      "LBDHDD"   = "HDL cholesterol (per mg/dL)",
                      "PAD680"   = "Sedentary minutes (per min)"
    ),
    significance = case_when(
      p_value < 0.001 ~ "***",
      p_value < 0.01  ~ "**",
      p_value < 0.05  ~ "*",
      TRUE            ~ ""
    )
  )

cat("\nAdjusted odds ratios:\n")
print(adj_results[, c("Variable", "OR_CI", "p_value", "significance")],
      row.names = FALSE)

# --- 9. Forest plot — adjusted ORs -------------------------------------------

plot_adj <- adj_results |>
  mutate(
    Variable = fct_reorder(Variable, OR),
    sig_col  = ifelse(p_value < 0.05, "Significant", "Not significant")
  )

ggplot(plot_adj, aes(x = OR, y = Variable, colour = sig_col)) +
  geom_point(size = 3) +
  geom_errorbar(aes(xmin = CI_low, xmax = CI_high),
                width = 0.25, orientation = "y") +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey40") +
  scale_colour_manual(
    values = c("Not significant" = "grey60", "Significant" = "tomato")
  ) +
  scale_x_log10() +
  labs(
    title    = "Adjusted Odds Ratios for Diabetes Risk",
    subtitle = "Survey-weighted logistic regression, NHANES 2017–2018\nWomen aged 18–49 | Mutually adjusted",
    x        = "Odds Ratio (log scale)",
    y        = NULL,
    colour   = NULL,
    caption  = "Adjusted for age, BMI, triglycerides, HDL, sedentary minutes.\n* p<0.05  ** p<0.01  *** p<0.001"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title      = element_text(face = "bold"),
    legend.position = "bottom"
  )

# --- 10. Save all outputs ----------------------------------------------------

write.csv(unadj_table,  "unadjusted_OR_results.csv",  row.names = FALSE)
write.csv(adj_results,  "adjusted_OR_results.csv",    row.names = FALSE)
saveRDS(adj_fit,        "adjusted_svyglm_fit.rds")

cat("\nAll Phase 8 outputs saved.\n")
cat("Phase 8 complete — ready for Phase 9 ML modelling.\n")

# Export the completed dataset for Python
library(haven)

nhanes_complete1 <- readRDS("nhanes_complete1_labelled.rds")

# Save as CSV for Python
write.csv(nhanes_complete1,
          "nhanes_complete1_for_python.csv",
          row.names = FALSE)

cat("Exported successfully.\n")








# ============================================================
# Quick exports for Power BI — run before Phase 11
# ============================================================

library(dplyr)
library(survey)

nhanes_complete1 <- readRDS("nhanes_complete1_labelled.rds")
options(survey.lonely.psu = "adjust")

nhanes_design <- svydesign(
  id      = ~SDMVPSU,
  strata  = ~SDMVSTRA,
  weights = ~WTMEC2YR,
  data    = nhanes_complete1,
  nest    = TRUE
)

# --- Overall prevalence headline ---------------------------------------------
overall <- svymean(~diabetes, nhanes_design, na.rm = TRUE)

overall_df <- data.frame(
  Metric = c("Weighted prevalence (%)",
             "SE (%)",
             "CI lower (%)",
             "CI upper (%)",
             "Estimated population (millions)"),
  Value  = c(round(coef(overall) * 100, 2),
             round(SE(overall) * 100, 2),
             round((coef(overall) - 1.96 * SE(overall)) * 100, 2),
             round((coef(overall) + 1.96 * SE(overall)) * 100, 2),
             round(sum(weights(nhanes_design)) / 1e6, 1))
)

write.csv(overall_df, "prevalence_overall.csv", row.names = FALSE)
cat("Saved: prevalence_overall.csv\n")
print(overall_df)

# --- Prevalence by race/ethnicity --------------------------------------------
race_prev <- svyby(~diabetes, ~race_f, nhanes_design,
                   svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    Group         = as.character(race_f),
    Prevalence_pct = round(diabetes * 100, 2),
    SE_pct         = round(se * 100, 2),
    CI_low         = round((diabetes - 1.96 * se) * 100, 2),
    CI_high        = round((diabetes + 1.96 * se) * 100, 2)
  ) |>
  select(Group, Prevalence_pct, SE_pct, CI_low, CI_high) |>
  arrange(desc(Prevalence_pct))

write.csv(race_prev, "prevalence_by_race.csv", row.names = FALSE)
cat("Saved: prevalence_by_race.csv\n")
print(race_prev)

# --- Prevalence by BMI category ----------------------------------------------
bmi_prev <- svyby(~diabetes, ~bmi_cat, nhanes_design,
                  svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    Group          = as.character(bmi_cat),
    Prevalence_pct = round(diabetes * 100, 2),
    SE_pct         = round(se * 100, 2),
    CI_low         = round((diabetes - 1.96 * se) * 100, 2),
    CI_high        = round((diabetes + 1.96 * se) * 100, 2)
  ) |>
  select(Group, Prevalence_pct, SE_pct, CI_low, CI_high)

write.csv(bmi_prev, "prevalence_by_bmi.csv", row.names = FALSE)
cat("Saved: prevalence_by_bmi.csv\n")
print(bmi_prev)

# --- Prevalence by education -------------------------------------------------
educ_prev <- svyby(~diabetes, ~educ_f, nhanes_design,
                   svymean, na.rm = TRUE) |>
  as.data.frame() |>
  mutate(
    Group          = as.character(educ_f),
    Prevalence_pct = round(diabetes * 100, 2),
    SE_pct         = round(se * 100, 2),
    CI_low         = round((diabetes - 1.96 * se) * 100, 2),
    CI_high        = round((diabetes + 1.96 * se) * 100, 2)
  ) |>
  select(Group, Prevalence_pct, SE_pct, CI_low, CI_high)

write.csv(educ_prev, "prevalence_by_education.csv", row.names = FALSE)
cat("Saved: prevalence_by_education.csv\n")
print(educ_prev)

cat("\nAll Power BI source files exported from R.\n")