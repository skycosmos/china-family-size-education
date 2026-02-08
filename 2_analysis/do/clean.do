
** Author: Tianyu Zheng
** Date: November 9, 2024
** Version: Stata/MP 18.0

global path = "/Users/tianyu/Desktop/Birth Order/data"

global location = "urban"

//merge_data
use "$path/${location}_person.dta", clear
merge m:1 hhcode using "$path/${location}_household.dta"

//province code
gen prov = real(substr(hhcode, 1, 2))
label define province_code ///
    11 "Beijing" 12 "Tianjin" 13 "Hebei" 14 "Shanxi" 15 "Inner Mongolia" ///
    21 "Liaoning" 22 "Jilin" 23 "Heilongjiang" 31 "Shanghai" 32 "Jiangsu" ///
	33 "Zhejiang" 34 "Anhui" 35 "Fujian" 36 "Jiangxi" 37 "Shandong" ///
    41 "Henan" 42 "Hubei" 43 "Hunan" 44 "Guangdong" 45 "Guangxi" ///
    46 "Hainan" 50 "Chongqing" 51 "Sichuan" 52 "Guizhou" 53 "Yunnan" ///
    54 "Tibet" 61 "Shaanxi" 62 "Gansu" 63 "Qinghai" 64 "Ningxia" ///
    65 "Xinjiang"
label values prov province_code

//age
gen age = 2018 - A04_1
keep if age >= 25 & age < 65

//gender
gen female = cond(A03 == 1, 0, 1)

//number of siblings
gen sib = cond(A08_1 > 0, A08_1, .)

//rank in siblings
gen rank = cond(A08_2 > 0, A08_2, .)

//education (school_year)
gen edu = cond(A13_3 >= 0, A13_3, .)

//health indicator
gen health = cond(A16_1 > 0, 3 - A16_1, .)

//marital status
gen marital = cond(A05 > 0, A05, .)

//head of household
gen head = cond(A02 == 1, 1, 0)

//number of dependent children
gen child = 0
forval i = 1/5 {
    replace child = child + (J02_R`i' > 0 & J03_1_R`i' == idcode & J05_R`i' < 25) if female == 0
	replace child = child + (J02_R`i' > 0 & J03_2_R`i' == idcode & J05_R`i' < 25) if female == 1
}

//household financial status
gen fin_asset = cond(F01 >= 0, cond(F02 >= 0, F01 + F02, F01), .)
gen fin_debt = cond(F05 >= 0, F05, .)

if "${location}" == "rural" {
	keep hhcode idcode prov age female sib rank edu health marital head child fin_asset fin_debt
	gen rural = 1
}

if "${location}" == "urban" {
	//job_1(main)
	gen job_type = cond(C03_4 > 0, C03_4, .)
	gen job_exp = cond(C02 > 0, 2018 - C02, .)
	gen job_source = cond(C06 > 0, C06, .)
	gen income_1 = cond(C05_1 > 0, C05_1 + 12 * cond(C07_4 > 0, C07_4, 0) + 12 * cond(C07_5 > 0, C07_5, 0), .)
	gen time_1 = cond(C01_1 > 0 & C01_2 > 0 & C01_3 > 0, C01_1 * C01_2 * C01_3, .)

	//job_2
	gen income_2 = cond(C09_4 > 0, C09_4, .)
	gen time_2 = cond(C09_1 > 0 & C09_2 > 0 & C09_3 > 0, C09_1 * C09_2 * C09_3, .)

	//job_3
	gen income_3 = cond(C09_6 > 0 & C09_8 > 0, C09_6 * C09_8, .)
	gen time_3 = cond(C09_6 > 0 & C09_7 > 0, C09_6 * C09_7, .)

	//job search
	gen ifsearch = cond(A20_1 > 0, A20_1, .)

	//filter related variables
	keep hhcode idcode prov age female sib rank edu health marital head child fin_asset fin_debt job_type job_exp job_source income_1 time_1 income_2 time_2 income_3 time_3 ifsearch

	//drop obs with missing values
	drop if missing(prov, age, sib, rank, edu, child)
	drop if (!missing(income_1) & missing(time_1)) | (!missing(time_1) & missing(income_1))
	drop if (!missing(income_2) & missing(time_2)) | (!missing(time_2) & missing(income_2))
	drop if (!missing(income_3) & missing(time_3)) | (!missing(time_3) & missing(income_3))


	//total wage income per year
	egen income_total = rowtotal(income_1 income_2 income_3)
	replace income_total = . if income_total == 0
	gen log_income = log(income_total)

	//total working time per year
	egen time_total = rowtotal(time_1 time_2 time_3)
	replace time_total = . if time_total == 0
	gen log_time = log(time_total)
	
	gen rural = 0
}


save "${location}_cleaned.dta", replace
