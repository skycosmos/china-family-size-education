global path = "/Users/tianyu/Downloads/毕业论文/Birth Order/data"

use "$path/urban_cleaned.dta", clear
append using "rural_cleaned.dta"

//average hourly wage
gen hwage = income_total / time_total 
gen log_hwage = log(hwage)

//dum var: help in job search from family members and friends
gen search_help = inlist(job_source, 8, 9, 10, 12)
replace search_help = . if missing(job_source)

//dum var: white_collar jobs
gen white_collar = inlist(job_type, 1, 2, 3, 7)
replace white_collar = . if missing(job_type)

gen year = 2018 - age

//age_squared
gen age_sqrt = age ^ 2

drop if rank == . | sib == .

//dum var: number of siblings
gen sib_group = cond(sib >= 7, 7, sib)
label define sib_lbl 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7+"
label values sib_group sib_lbl
tabulate sib_group , generate(sib_dum)

//dum var: rank between siblings
gen rank_group = cond(rank >= 7, 7, rank)
label define rank_lbl 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7+"
label values rank_group rank_lbl
tabulate rank_group , generate(rank_dum)

//label
label variable age "Age in 2018"
label variable age_sqrt "Age^2"
label variable year "Year of Birth"
label variable female "Female = 1"
label variable sib "Num of Siblings including Self"
label variable rank "Birth Order among Siblings"
label variable edu "Years of Education"
label variable log_income "Log of Annual Income (CNY)"
label variable log_hwage "Log of Hourly Wage (CNY)"
label variable child "Num of Dependent Children"
label variable head "Head of Household = 1"

global cohorts "cohort_1954 cohort_1959 cohort_1964 cohort_1969 cohort_1974 cohort_1979 cohort_1984 cohort_1989"
global sib_dum "sib_dum2 sib_dum3 sib_dum4 sib_dum5 sib_dum6 sib_dum7"
global rank_dum "rank_dum2 rank_dum3 rank_dum4 rank_dum5 rank_dum6 rank_dum7"

save "combined.dta", replace





** Figure : Average Number of Siblings by Year

preserve

collapse (mean) avg_siblings = sib, by(year)

twoway line avg_siblings year, ///
    title("Average Number of Siblings by Year") ///
    ytitle("Average Number of Siblings") ///
    xtitle("Year of Birth") ///
    xlabel(, angle(45)) ///
    scheme(s1mono)
	
restore

** Drop-Out Rate

gen highest_grade = edu
replace highest_grade = 0 if edu <= 0

forvalues grade = 1/12 {
    gen completed_grade`grade' = (highest_grade >= `grade')
}

* Reshape to long format for analysis
gen id = _n  // create unique identifier
reshape long completed_grade, i(id) j(grade)

* Calculate completion year for each grade
gen grade_completion_year = year + 6 + grade


* Calculate dropout rates by birth cohort and grade
preserve
    
    * Collapse to get completion rates by birth year and grade
    collapse (mean) completed_grade (count) n=completed_grade, by(year grade)
    
    * Calculate dropout rate
    gen dropout_rate = 1 - completed_grade
    
    * Label variables
    label var year "Birth Year"
    label var grade "Grade Level"
    label var completed_grade "Completion Rate"
    label var dropout_rate "Dropout Rate"
    label var n "Number of Individuals"
    
    * Format as percentages
    format completed_grade dropout_rate %9.2f
    
    * Sort for better viewing
    sort year grade
    
    * View results
    list year grade dropout_rate n if grade <= 12, sepby(year) noobs
    
    * Create visualization (example for selected birth years)
    * First find the range of birth years in your data
    sum year
    local min_year = r(min)
    local max_year = r(max)
    
    * Select 3 representative years (adjust as needed)
    local year1 = `min_year' + 5
    local year2 = `min_year' + floor((`max_year'-`min_year')/2)
    local year3 = `max_year' - 5
    
    twoway (line dropout_rate grade if year == `year1', lcolor(blue)) ///
           (line dropout_rate grade if year == `year2', lcolor(red)) ///
           (line dropout_rate grade if year == `year3', lcolor(green)), ///
           legend(order(1 "`year1'" 2 "`year2'" 3 "`year3'")) ///
           title("Dropout Rates by Grade Level") ///
           ytitle("Dropout Rate") xtitle("Grade Level") ///
           ylabel(0(0.1)1, format(%2.1f)) xlabel(1(1)12)
		  
restore



** Table 1 : Summary Statistics
** total / urban / rural

eststo clear

estpost summarize age female sib rank head child edu log_income log_hwage
eststo total

preserve
keep if rural == 1
estpost summarize age female sib rank head child edu log_income log_hwage
eststo rural
restore

preserve
keep if rural == 0
estpost summarize age female sib rank head child edu log_income log_hwage
eststo urban
restore

esttab total rural urban using summary.tex, replace ///
    cells("mean(fmt(3)) sd(fmt(3))") ///
    title("Summary Statistics") ///
	label ///
    tex

** Table 2 : Distribution of Birth Order Across Family Size


** Table 3 : Income and Educational Attainment

eststo clear

reg log_income age age_sqrt female child `sib_dum' rank_dum2-rank_dum7
estadd scalar FE 0
eststo Model1

areg log_income age age_sqrt female child `sib_dum' rank_dum2-rank_dum7, absorb(prov)
estadd scalar FE 1
eststo Model2
estimates store no_edu_control

reg log_income age age_sqrt edu female child `sib_dum' rank_dum2-rank_dum7
estadd scalar FE 0
eststo Model3

areg log_income age age_sqrt edu female child `sib_dum' rank_dum2-rank_dum7, absorb(prov)
estadd scalar FE 1
eststo Model4
estimates store edu_control

reg log_income age age_sqrt edu female child `sib_dum'
estadd scalar FE 0
eststo Model5

areg log_income age age_sqrt edu female child `sib_dum', absorb(prov)
estadd scalar FE 1
eststo Model6


esttab Model1 Model2 Model3 Model4 Model5 Model6 using "income.tex", replace ///
    keep(age age_sqrt female child edu `sib_dum' rank_dum2 rank_dum3 rank_dum4 rank_dum5 rank_dum6 rank_dum7) ///
    stats(r2 N FE, fmt(3 0)) ///
    se star(* 0.1 ** 0.05 *** 0.01) ///
    title("Family Size and Birth Order Effects on Income") ///
    collabels("OLS1" "FE 1" "OLS 2" "FE 2" "OLS 3" "FE 3") ///
    alignment(c) ///
    compress
	
** filefilter "income.tex", from("0") to("No")
** filefilter "income.tex", from("1") to("Yes")

* generate a figure coef of sib_dum2 - sib_dum7 under two conditions (whether controlling for edu)

** Figure : The Effect of Family Size 

coefplot no_edu_control edu_control, keep(sib_dum2 sib_dum3 sib_dum4 sib_dum5 sib_dum6 sib_dum7) vertical ///
	connect(l) ///
	ciopts(lpattern(dash)) ///
	yline(0, lcolor(black)) ///
	xtitle(Number of Siblings) ///
	ytitle(Coefficient of Dummy Variables) ///
	xlabel(1 "2" 2 "3" 3 "4" 4 "5" 5 "6" 6 "7+")

graph export "family_size_control_edu.png", replace

** Table 4 : Educational Attaiment by Cohorts

estimates clear

areg edu age age_sqrt female sib_dum2-sib_dum7, absorb(prov)
estimates store full_sample

foreach year in 1954 1959 1964 1969 1974 1979 1984 1989 {
    preserve
    keep if age > 2018 - `year' - 5 & age <= 2018 - `year'
    areg edu age female `sib_dum', absorb(prov)
    estimates store cohort_`year'
    restore
}

esttab full_sample cohort_1954 cohort_1959 cohort_1964 cohort_1969 cohort_1974 cohort_1979 cohort_1984 cohort_1989 using edu_cohorts.tex, tex replace ///
    se starlevels(* 0.10 ** 0.05 *** 0.01)

** Figure: The Sudden Rise of Family Size Effect

coefplot cohort_1954 cohort_1959 cohort_1964 cohort_1969 cohort_1974 cohort_1979 cohort_1984 cohort_1989, keep(`sib_dum') vertical ///
	connect(l) ///
	ciopts(lpattern(dash)) ///
	yline(0, lcolor(black)) ///
	xtitle(Number of Siblings) ///
	ytitle(Coefficient of Dummy Variables) ///
	xlabel(1 "2" 2 "3" 3 "4" 4 "5" 5 "6" 6 "7+")
	
graph export "edu_cohorts.png", replace

	
** Figure: Proportion of Last-Born Children by Year

preserve
gen youngest = (rank == sib)
collapse (mean) youngest, by (year)
twoway (line youngest year, lcolor(blue) lwidth(medium)), ///
    title("Proportion of Last-Borns by Year of Birth") ///
    xlabel(, angle(45)) ///
    ylabel(, grid) ///
    xtitle("Year of Birth") ///
    ytitle("Proportion of Last-Borns")
graph export "last_born.png", replace
restore

** Table 5 : One-Child Policy

preserve
keep if age <= 50 & age >= 41
gen youngest = (rank == sib)
areg edu age age_sqrt female youngest sib_dum2-sib_dum7, absorb(prov)
restore

** Table 5: RDD
** Note: `c.birth_year_centered#c.treatment` adds an interaction between the running variable and treatment for a flexible slope.

preserve
gen year_centered = year - 1975
gen treatment = year >= 1975

foreach var in sib_dum2 sib_dum3 sib_dum4 sib_dum5 sib_dum6 sib_dum7 {
    gen `var'_post = `var' * treatment
}

areg edu age_sqrt female sib_dum2-sib_dum7 sib_dum2_post-sib_dum7_post ///
    year_centered treatment ///
    c.year_centered#c.treatment, absorb(prov)
	
eststo clear

eststo: areg edu age_sqrt female sib_dum2-sib_dum7 sib_dum2_post-sib_dum7_post ///
    year_centered treatment ///
    c.year_centered#c.treatment, absorb(prov)

esttab using "rdd_results.tex", replace ///
    title("Change in Family Size Effects Post-1975") ///
    label b(3) se star(* 0.1 ** 0.05 *** 0.01) ///
    alignment(c) nonumber
	
restore











