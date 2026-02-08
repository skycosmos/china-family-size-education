**************************************************
* data_clean.do
** Author: Tianyu Zheng
** Date: April 10, 2025
** Version: Stata/MP 18.0
**************************************************

/* Data Clean */

*-------------------------------------------------------------------------------
/* Rural */

//merge_data
use "$RAW/rural_person.dta", clear
merge m:1 hhcode using "$RAW/rural_household.dta"
gen rural = 1

gen prov = real(substr(hhcode, 1, 2)) //resident province
gen prov_birth = cond(A09_3 > 0, A09_3, .) //province at 14 years old

gen year = A04_1 //birth year
gen female = cond(A03 == 1, 0, 1) //gender
gen sib = cond(A08_1 > 0, A08_1, .) //number of siblings including self
gen rank = cond(A08_2 > 0, A08_2, .) //rank in siblings
gen edu = cond(A13_3 >= 0, A13_3, .) //education (years of education)
gen health = cond(A16_1 > 0, 3 - A16_1, .) //health indicator
gen marital = cond(A05 > 0, A05, .) //marital status
gen househead = cond(A02 == 1, 1, 0) //head of household

//number of dependent children
gen child = 0
forval i = 1/5 {
    replace child = child + (J02_R`i' > 0 & J03_1_R`i' == idcode & J05_R`i' < 25) if female == 0
	replace child = child + (J02_R`i' > 0 & J03_2_R`i' == idcode & J05_R`i' < 25) if female == 1
}

//household financial status
gen fin_asset = cond(F01 >= 0, cond(F02 >= 0, F01 + F02, F01), .)
gen fin_debt = cond(F05 >= 0, F05, .)

keep hhcode idcode rural prov prov_birth year female sib rank edu health marital househead child fin_asset fin_debt

tempfile rural_processed
save `rural_processed'

*-------------------------------------------------------------------------------
/* Urban */

//merge_data
use "$RAW/urban_person.dta", clear
merge m:1 hhcode using "$RAW/urban_household.dta"
gen rural = 0

gen prov = real(substr(hhcode, 1, 2)) //resident province
gen prov_birth = cond(A09_3 > 0, A09_3, .) //province at 14 years old

gen year = A04_1 //birth year
gen female = cond(A03 == 1, 0, 1) //gender
gen sib = cond(A08_1 > 0, A08_1, .) //number of siblings including self
gen rank = cond(A08_2 > 0, A08_2, .) //rank in siblings
gen edu = cond(A13_3 >= 0, A13_3, .) //education (years of education)
gen health = cond(A16_1 > 0, 3 - A16_1, .) //health indicator
gen marital = cond(A05 > 0, A05, .) //marital status
gen househead = cond(A02 == 1, 1, 0) //head of household

//number of dependent children
gen child = 0
forval i = 1/5 {
    replace child = child + (J02_R`i' > 0 & J03_1_R`i' == idcode & J05_R`i' < 25) if female == 0
	replace child = child + (J02_R`i' > 0 & J03_2_R`i' == idcode & J05_R`i' < 25) if female == 1
}

//household financial status
gen fin_asset = cond(F01 >= 0, cond(F02 >= 0, F01 + F02, F01), .)
gen fin_debt = cond(F05 >= 0, F05, .)

//job_1(main)
gen income_1 = cond(C05_1 > 0, C05_1 + 12 * cond(C07_4 > 0, C07_4, 0) + 12 * cond(C07_5 > 0, C07_5, 0), .)
//job_2
gen income_2 = cond(C09_4 > 0, C09_4, .)
//job_3
gen income_3 = cond(C09_6 > 0 & C09_8 > 0, C09_6 * C09_8, .)
//total wage income per year
egen income = rowtotal(income_1 income_2 income_3)
replace income = . if income == 0

keep hhcode idcode rural prov prov_birth year female sib rank edu health marital househead child fin_asset fin_debt income

tempfile urban_processed
save `urban_processed'

*-------------------------------------------------------------------------------

/* Combine */

append using `rural_processed'

label define province_code ///
    11 "Beijing" 12 "Tianjin" 13 "Hebei" 14 "Shanxi" 15 "Inner Mongolia" ///
    21 "Liaoning" 22 "Jilin" 23 "Heilongjiang" 31 "Shanghai" 32 "Jiangsu" ///
	33 "Zhejiang" 34 "Anhui" 35 "Fujian" 36 "Jiangxi" 37 "Shandong" ///
    41 "Henan" 42 "Hubei" 43 "Hunan" 44 "Guangdong" 45 "Guangxi" ///
    46 "Hainan" 50 "Chongqing" 51 "Sichuan" 52 "Guizhou" 53 "Yunnan" ///
    54 "Tibet" 61 "Shaanxi" 62 "Gansu" 63 "Qinghai" 64 "Ningxia" ///
    65 "Xinjiang" 81 "Hong Kong" 82 "Macao" 83 "Taiwan"

label values prov province_code
label values prov_birth province_code

// family size categorize
gen family_cat = cond(sib>=6, 6, sib)
label define famcat 1 "1 child" 2 "2 child" 3 "3 child" 4 "4 child" 5 "5 child" 6 "6+ child"
label values family_cat famcat

// rank categorize
gen rank_cat = cond(rank>=6, 6, rank)
label define rankcat 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6+"
label values rank_cat rankcat

label define marital_lbl ///
    1 "First marriage (legally married)" ///
    2 "Remarried after divorce" ///
    3 "Remarried after widowhood" ///
    4 "Cohabiting (unmarried partnership)" ///
    5 "Separated (legally married but living apart)" ///
    6 "Divorced (single)" ///
    7 "Widowed (single)" ///
    8 "Never married" ///
    9 "Other", ///
    replace
label values marital marital_lbl

label var edu "Years of Edu"
label var income "Annual Income (CNY)"
label var rural "Rural Resident = 1"
label var prov "Province of Residence (Current)"
label var prov_birth "Province of Residence at Age 14"
label var year "Birth Year"
label var female "Female = 1"
label var sib "Num of Sib + Self"
label var rank "Birth Order"
label var family_cat "Family Size Category"
label var rank_cat "Rank Category"
label var health "Health Indicator"
label var marital "Marital Status"
label var househead "Househead = 1"
label var child "Num of Depend Child"
label var fin_asset "Household Financial Asset (CNY)"
label var fin_debt "Household Financial Debt (CNY)"

keep if year >= 1956 & year <= 1990

drop if missing(sib) | missing(rank)

save "$CLEAN/data_processed.dta", replace

*-------------------------------------------------------------------------------
*-------------------------------------------------------------------------------
