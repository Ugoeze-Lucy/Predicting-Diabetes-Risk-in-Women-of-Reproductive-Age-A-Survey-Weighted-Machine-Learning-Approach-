# Diabetes Risk Prediction Among US Women of Reproductive Age

![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![scikit-learn](https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white)
![XGBoost](https://img.shields.io/badge/XGBoost-006400?style=for-the-badge)
![SHAP](https://img.shields.io/badge/SHAP-8B1A1A?style=for-the-badge)

A survey-weighted epidemiological and machine learning analysis of diabetes risk in women aged 18-49, using NHANES 2017-2018 data. This project combines biostatistics (complex survey design, multiple imputation, logistic regression) with machine learning (XGBoost, LightGBM, SHAP) and ends in an interactive Power BI dashboard.

## Table of Contents

- [Overview](#overview)
- [Why This Project](#why-this-project)
- [Data Source](#data-source)
- [Project Structure](#project-structure)
- [Methodology](#methodology)
  - [Phase 1-6: Data Preparation](#phase-1-6-data-preparation)
  - [Phase 7: Descriptive Analysis](#phase-7-descriptive-analysis)
  - [Phase 8: Survey-Weighted Logistic Regression](#phase-8-survey-weighted-logistic-regression)
  - [Phase 9-10: Machine Learning and SHAP](#phase-9-10-machine-learning-and-shap)
  - [Phase 11: Power BI Dashboard](#phase-11-power-bi-dashboard)
- [Key Findings](#key-findings)
- [Dashboard Preview](#dashboard-preview)
- [Limitations](#limitations)
- [Tools and Libraries](#tools-and-libraries)
- [How to Reproduce](#how-to-reproduce)
- [Author](#author)

## Overview

Roughly 67 million women aged 18-49 live in the US, and this project asks a simple question: what drives diabetes risk in this group, and can it be predicted from routinely collected demographic and clinical variables?

The answer comes in three parts. First, a properly survey-weighted descriptive picture of who is affected and by how much. Second, a logistic regression identifying which factors are independently associated with diabetes after adjustment. Third, four machine learning models trained to predict diabetes risk, interpreted with SHAP to understand exactly how each model makes its decisions.

The project deliberately uses the **same dataset across two languages** (R for survey statistics, Python for ML) and the final dashboard.

## Why This Project

NHANES is one of the largest publicly available health surveys in the world, and working with it end-to-end from raw `.XPT` files to a published dashboard, mirrors the kind of analytical work I want to do in health system roles. I also wanted a project that didn't pick one methodology and stop there.

## Data Source

**NHANES 2017-2018** (National Health and Nutrition Examination Survey), conducted by the CDC.

Thirteen files were merged on the respondent ID (`SEQN`):

| File | Content |
|---|---|
| DEMO_J | Demographics, survey weights, strata, PSU |
| BMX_J | BMI, waist circumference |
| BPX_J | Blood pressure (3 readings) |
| GHB_J | HbA1c |
| GLU_J | Fasting plasma glucose |
| HDL_J | HDL cholesterol |
| TRIGLY_J | Triglycerides, LDL |
| DIQ_J | Diabetes diagnosis, treatment |
| PAQ_J | Physical activity |
| SMQ_J | Smoking |
| ALQ_J | Alcohol use |
| HIQ_J | Health insurance |
| RHQ_J | Reproductive history |



**Analytic population:** women aged 18-49 with a valid MEC exam weight, n = 1,394, representing approximately 67 million US women.


## Project Structure

```
nhanes-diabetes-risk/
├── R/
│   ├── 01_load_merge.R
│   ├── 02_population_definition.R
│   ├── 03_outcome_definition.R
│   ├── 04_variable_selection.R
│   ├── 05_imputation.R
│   ├── 06_survey_design.R
│   ├── 07_descriptive_analysis.R
│   └── 08_logistic_regression.R
├── python/
│   ├── 09_ml_modelling.ipynb
│   └── 10_evaluation_shap.ipynb
├── powerbi/
│   └── diabetes_dashboard.pbix
├── outputs/
│   ├── figures/
│   ├── tables/
│   └── csv_exports/
└── README.md
```


## Methodology

### Phase 1-6: Data Preparation

All 13 `.XPT` files were loaded with `haven::read_xpt()` and merged with `left_join()` on `SEQN`, keeping the full DEMO file as the base so no participant or survey weight was lost.

The analytic population was restricted to females aged 18-49 with a non-missing, non-zero MEC exam weight (`WTMEC2YR`).

**Outcome definition.** A woman was classified as diabetic if she met any one of three criteria:
- HbA1c ≥ 6.5%
- Fasting glucose ≥ 126 mg/dL
- Self-reported doctor diagnosis

This is the standard ADA-aligned approach and captures both diagnosed and undiagnosed diabetes. Prediabetes (HbA1c 5.7-6.4% with no other criterion met) was coded as non-diabetic, with that decision documented as a limitation.

**Missing data.** NHANES-specific missing codes (7, 9, 77, 99, 777, 999) were recoded to `NA`. Variables with structural missingness (like smoking frequency, only asked of ever-smokers) were recoded before imputation rather than left as missing. Multiple imputation was run using `mice` (predictive mean matching, m = 5, maxit = 20).

**Survey design.** A `svydesign()` object was built with `SDMVPSU` as the PSU, `SDMVSTRA` as strata, `WTMEC2YR` as weights, `nest = TRUE`, and `options(survey.lonely.psu = "adjust")` set in advance. The final design had 15 strata, each with exactly 2 PSUs - no lonely PSU issues.

### Phase 7: Descriptive Analysis

A full survey-weighted Table 1 was produced with `gtsummary::tbl_svysummary()`, comparing diabetic and non-diabetic women across demographic, anthropometric, lipid, and behavioural variables, with survey-appropriate t-tests and chi-square tests.

**Headline numbers:**
- Weighted diabetes prevalence: **5.96%** (95% CI 3.77-8.15%)
- That represents roughly **4 million** of the 67 million women in this age group
- 74.1% of diabetic women were obese, vs 38.5% of non-diabetic women
- Mexican American women had the highest prevalence at 9.4%

A series of weighted bar charts, density plots, were produced to visualise prevalence by race, education, BMI category, smoking, gestational diabetes history, and to compare clinical variables (triglycerides, HDL, blood pressure, waist circumference) between groups.

### Phase 8: Survey-Weighted Logistic Regression

This phase ran into a real constraint worth documenting honestly. With only 15 strata x 2 PSUs, the survey design has roughly 15 degrees of freedom available for variance estimation. A model with 13 predictors (several of them categorical, expanding into multiple dummy variables) simply could not be fit stably - residual degrees of freedom dropped to 1, and confidence intervals became absurd (one OR had a 95% CI spanning 0 to 60 million).

The fix was to split the analysis:

1. **Unadjusted odds ratios** for all 13 predictors, each fit in its own single-predictor `svyglm()` model, where df is never a constraint
2. **A reduced adjusted model** with the 5 strongest predictors (age, BMI, triglycerides, HDL, sedentary minutes), which fit comfortably within the available df

**Adjusted findings:** age, BMI, triglycerides, and sedentary minutes were independently associated with diabetes (all p < 0.05). HDL showed the expected protective direction but lost significance after adjustment.

### Phase 9-10: Machine Learning and SHAP

Four models were trained in Python on the same 19 features (the full predictor set, unlike the constrained logistic regression): **Logistic Regression, Random Forest, XGBoost, and LightGBM**, each inside a pipeline with median imputation, standard scaling, and SMOTE (applied only to training folds).

**Model performance — discrimination and calibration:**

| Model | CV AUC | Test AUC | Brier Score |
|---|---|---|---|
| Logistic Regression | 0.885 ± 0.061 | 0.861 | 0.141 |
| Random Forest | 0.872 ± 0.073 | 0.889 | 0.072 |
| XGBoost | 0.853 ± 0.078 | 0.846 | 0.070 |
| LightGBM | 0.834 ± 0.078 | 0.811 | 0.076 |

No single model dominates across both metrics. Random Forest achieved the highest test AUC (0.889) and strong calibration (Brier 0.072), making it the strongest performer for ranking individual risk. XGBoost produced the best calibration (Brier 0.070) with acceptable discrimination (AUC 0.846), if predicted probabilities need to be read as actual risk estimates rather than just rankings, XGBoost is the more honest model. Logistic Regression won cross-validation but had the worst calibration of all four (Brier 0.141), more than double the naive baseline of ~0.064. The three ensemble models were all reasonably calibrated by comparison, with Brier scores clustered tightly between 0.070 and 0.076.

**SHAP analysis** on the logistic regression model produced the most interesting findings of the project:

| Rank | Feature | Mean \|SHAP\| |
|---|---|---|
| 1 | Age | 1.22 |
| 2 | Triglycerides | 0.75 |
| 3 | Education level | 0.63 |
| 4 | Smoking status | 0.63 |
| 5 | LDL cholesterol | 0.60 |
| 6 | Health insurance | 0.56 |

Age and triglycerides showing up at the top is unsurprising and confirms Phase 8. What's more interesting is **LDL cholesterol and health insurance status** - neither showed any signal in the descriptive Table 1 (p = 0.8 and p > 0.9 respectively) - yet both placed in the top 7 SHAP features. This points to non-linear or interaction effects that a simple group comparison can't pick up, but a model trained on the full feature set can.

Calibration was assessed across all four models. Logistic Regression was substantially overconfident (Brier 0.141), when it predicted a 70% probability of diabetes, observed rates were far lower. The three ensemble models were all considerably better calibrated (Brier 0.070-0.076), though still marginally above the naive baseline. SHAP analysis was run on Logistic Regression specifically because `shap.LinearExplainer` provides mathematically exact attribution for linear models, this was an interpretability choice, not a claim that it is the best predictor.

### Phase 11: Power BI Dashboard

A 4-page interactive dashboard was built in Power BI 

**Page 1 - Prevalence Overview:** headline KPIs (5.96% prevalence, 67M women represented, 95% CI) and prevalence breakdowns by race, BMI category, education, smoking, and gestational diabetes history, each with 95% confidence interval error bars.

**Page 2 - Participant Characteristics:** side-by-side comparison of age, BMI, waist circumference, triglycerides, HDL, and systolic blood pressure between diabetic and non-diabetic women.

**Page 3 - Model Performance:** AUC comparison across all 4 models (CV vs test), calibration curves for all four models with Brier scores, ROC curves, a full performance metrics table (sensitivity, specificity, PPV, NPV, Brier score), and a confusion matrix with conditional formatting.

**Page 4 - SHAP and Risk Factors:** the full 19-feature SHAP importance ranking plus individual dependence plots for age, triglycerides, education, and smoking status, showing exactly how each feature's value relates to its impact on the prediction.

## Key Findings

- An estimated **4 million** US women aged 18-49 had diabetes in 2017-2018, a weighted prevalence of **5.96%** (95% CI 3.77-8.15%), representing roughly 1 in 17 women in this age group
  
- Diabetes prevalence ranged from **3.76%** among college graduates to **15.17%** among women with 9th-11th grade education.

- **Mexican American women had the highest weighted prevalence at 9.4%**, nearly double the overall rate, consistent with known population-level disparities.
  
- In the adjusted regression model, **age, BMI, triglycerides, and sedentary minutes** were all independently associated with diabetes risk after mutual adjustment
  
- All four ML models substantially outperformed chance (test AUC 0.811-0.889). **No single model dominates across metrics**, Random Forest had the best discrimination (AUC 0.889), XGBoost had the best calibration (Brier 0.070), and Logistic Regression had the worst calibration despite winning cross-validation (Brier 0.141)
- SHAP analysis surfaced **LDL cholesterol and health insurance**, two variables with no descriptive signal in Table 1 (both p > 0.8) as top-7 model features
- The SHAP dependence plot for age showed a **perfectly linear relationship** crossing zero at approximately age 32-33, meaning a woman's age contribution to predicted risk switches from protective to risk-increasing somewhere in her early thirties
- Triglycerides showed a **dose-dependent relationship** with predicted risk,even values in the borderline-high clinical range (150-200 mg/dL) meaningfully increased predicted diabetes risk
  
## Dashboard Preview

<img width="1296" height="728" alt="Screenshot 2026-06-13 201121" src="https://github.com/user-attachments/assets/284c5505-755e-4021-9773-8fa8274e3783" />
<img width="1315" height="731" alt="Screenshot 2026-06-13 201102" src="https://github.com/user-attachments/assets/424890c6-e17f-4180-91f2-6bc39b2f898f" />

## Limitations

- **High missingness in key variables:** triglycerides and fasting glucose both had 55%+ missingness, meaning a large share of those imputed values carry more uncertainty than observed measurements. The SHAP missInfo column confirmed 54% of statistical information for triglycerides came from imputation rather than observed data
- **Degrees-of-freedom constraint in logistic regression:** with only 15 strata x 2 PSUs, the survey design allowed a maximum of 15 degrees of freedom for variance estimation. A fully adjusted model with all 13 predictors was not possible, residual df dropped to 1 and confidence intervals became unusable. The adjusted model was limited to 5 continuous predictors
- **Small positive class in test set:** only 19 of 279 test observations had diabetes. Sensitivity (63.2%) and PPV (21.1%) estimates are based on these 19 cases and carry wide uncertainty, a 95% CI around sensitivity spans roughly 38% to 84%
- **Calibration varies substantially by model:** Logistic Regression's predicted probabilities are poorly calibrated (Brier 0.141), worse than a naive model predicting population prevalence for everyone. The ensemble models are considerably better (Brier 0.070-0.076) but still not suitable as individual clinical risk scores without formal recalibration (Platt scaling or isotonic regression)
- **Smoking variable coding artefact:** the SHAP dependence plot for smoking showed an unexpected direction, likely because the ordinal coding of SMQ040_rec (0=never, 1=every day, 2=some days, 3=former) does not represent a true linear scale. The logistic regression model treated it as continuous, which produced a coefficient in the wrong direction. This is a recoding limitation, not evidence that smoking protects against diabetes
- **Cross-sectional design:** causal inference is not possible. All associations are observational and subject to unmeasured confounding

## Tools and Libraries

**R:** `haven`, `dplyr`, `mice`, `survey`, `gtsummary`, `ggplot2`, `forcats`, `patchwork`

**Python:** `pandas`, `scikit-learn`, `xgboost`, `lightgbm`, `imbalanced-learn`, `shap`, `matplotlib`, `seaborn`

**Dashboard:** Power BI Desktop

## How to Reproduce

1. Download the NHANES 2017-2018 `_J` cycle files listed in [Data Source](#data-source) from the [CDC NHANES website](https://wwwn.cdc.gov/nchs/nhanes/)
2. Run the R scripts in `R/` in numerical order (01 through 08)
3. Export the completed dataset to CSV (final line of `06_survey_design.R`)
4. Run the Python notebooks in `python/` in order (09, then 10)
5. Open `powerbi/diabetes_dashboard.pbix` and point it at the CSV exports in `outputs/csv_exports/`


## Author

**Ugoeze Lucy Unegbu**

Public Health Data Analyst | MSc Medical Statistics and Epidemiology, University of Nigeria Nsukka

[LinkedIn](https://linkedin.com/in/ugoeze-lucy) · [Portfolio](https://ugoezelucy.netlify.app) · [Medium](https://medium.com/@zinalucy) · [ORCID](https://orcid.org/0009-0007-4682-6333) · [GitHub](https://github.com/Ugoeze-Lucy)
