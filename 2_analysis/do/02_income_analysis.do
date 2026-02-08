**************************************************
* 02_income_analysis.do
** Author: Tianyu Zheng
** Date: April 10, 2025
** Version: Stata/MP 18.0
**************************************************

/* Income Analysis */

** Table & Figure: Income, Family Size, Rank among Siblings, Educational Attainment

use "$CLEAN/data_processed.dta", clear
estimates clear

gen log_income = log(income)
label var log_income "Log Income"

gen log_asset = log(fin_asset)
label var log_asset "Log Assets"

gen age = 2018 - year
label var age "Age in 2018"

gen age_sqrt = age^2
label var age_sqrt "Age^2"

keep if age >= 30 & age < 55
	
eststo clear

// Model 1-2: log_income without education control
reg log_income age age_sqrt female child i.family_cat i.rank_cat
estadd local FE "No"
estadd local EduControl "No"
eststo Model1

areg log_income age age_sqrt female child i.family_cat i.rank_cat, absorb(prov)
estadd local FE "Yes"
estadd local EduControl "No"
eststo Model2

// Model 3-4: log_income with education control
reg log_income age age_sqrt edu female child i.family_cat i.rank_cat
estadd local FE "No"
estadd local EduControl "Yes"
eststo Model3

areg log_income age age_sqrt edu female child i.family_cat i.rank_cat, absorb(prov)
estadd local FE "Yes"
estadd local EduControl "Yes"
eststo Model4

// Model 5-6: log_asset with education control
reg log_asset age age_sqrt female child i.family_cat i.rank_cat, absorb(prov)
estadd local FE "Yes"
estadd local EduControl "No"
eststo Model5

areg log_asset age age_sqrt edu female child i.family_cat i.rank_cat, absorb(prov)
estadd local FE "Yes"
estadd local EduControl "Yes"
eststo Model6

// Table
esttab Model1 Model2 Model3 Model4 Model5 Model6 using "$RESULT/tables/income.tex", replace ///
    keep(age age_sqrt female child edu 2.family_cat 3.family_cat 4.family_cat 5.family_cat 6.family_cat 2.rank_cat 3.rank_cat 4.rank_cat 5.rank_cat 6.rank_cat) ///
    stats(FE EduControl r2 N, fmt(s s 3 0)) ///
    se star(* 0.1 ** 0.05 *** 0.01) ///
    title("Family Size and Birth Order Effects on Income") ///
    collabels("OLS (1)" "FE (2)" "OLS (3)" "FE (4)" "FE (5)" "FE (6)") ///
    alignment(D{.}{.}{-1}) ///
    compress nogap ///
    label booktabs ///
    refcat(2.family_cat "Family Size" 2.rank_cat "Birth Order", nolabel)

// Figure
coefplot Model2 Model4, ///
    keep(2.family_cat 3.family_cat 4.family_cat 5.family_cat 6.family_cat) ///
    vertical ///
	connect (l) ///
	ciopts(lpattern(dash)) ///
    xlabel(1 "2" 2 "3" 3 "4" 4 "5" 5 "6+") ///
    yline(0, lcolor(red) lpattern(dash)) ///
    title("The Impact of Family Size on Log Income") ///
	xtitle("Family Size", size(medsmall)) ///
	ytitle("Coeffcient Estimates") ///
    legend(label(2 "Without Edu Control") label(4 "With Edu Control")) ///
    scheme(s1color) ///
    plotregion(color(white)) graphregion(color(white))

graph export "$RESULT/figures/income.png", replace