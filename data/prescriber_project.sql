-- Q1 a.

SELECT npi, total_claim_count
FROM prescription
ORDER BY total_claim_count DESC;

-- Q1 b.

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count)
FROM prescriber
FULL JOIN prescription
USING (npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY SUM(total_claim_count) DESC NULLS LAST;

--Q2 a.

SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING (npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC NULLS LAST;

--Q2 b.

SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
INNER JOIN prescription
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE drug.opioid_drug_flag LIKE 'Y'
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC;

--Q2 c.

SELECT specialty_description, SUM(total_claim_count)
FROM prescriber
FULL JOIN prescription
USING (npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC
LIMIT 15;

--Q2 d.

WITH total_opioid_perscribed AS 
	(SELECT specialty_description, SUM(total_claim_count) AS opioids
	FROM prescriber
	FULL JOIN prescription
	USING (npi)
	FULL JOIN drug
	USING (drug_name)
	WHERE drug.opioid_drug_flag LIKE 'Y'
	GROUP BY specialty_description
	ORDER BY SUM(total_claim_count) DESC)

SELECT prescriber.specialty_description, total_opioid_perscribed.opioids AS opioids_perscribed, SUM(total_claim_count) AS total_perscribed, ROUND((total_opioid_perscribed.opioids / SUM(total_claim_count)) * 100,2) AS percentage_of_claims
FROM prescriber
FULL JOIN prescription
USING (npi)
FULL JOIN total_opioid_perscribed
ON prescriber.specialty_description = total_opioid_perscribed.specialty_description
GROUP BY prescriber.specialty_description, total_opioid_perscribed.opioids
ORDER BY percentage_of_claims DESC nulls LAST;

--Q3 a.

SELECT SUM(total_drug_cost) AS cost, generic_name
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY cost DESC;

--Q3 b.

SELECT ROUND(SUM(total_drug_cost) / SUM(total_day_supply),2) AS cost_per_day, generic_name
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;

--Q4 a.

SELECT DISTINCT drug_name,
CASE WHEN opioid_drug_flag LIKE 'Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag LIKE 'Y' THEN 'antibiotic'
	 ELSE 'neither' END AS drug_type
FROM drug;

--Q4 b.

SELECT DISTINCT SUM(prescription.total_drug_cost::MONEY) AS total_cost,
CASE WHEN opioid_drug_flag LIKE 'Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag LIKE 'Y' THEN 'antibiotic'
	 ELSE 'neither' END AS drug_type
FROM drug
FULL JOIN prescription
USING (drug_name)
WHERE opioid_drug_flag LIKE 'Y' OR antibiotic_drug_flag LIKE 'Y'
GROUP BY opioid_drug_flag, antibiotic_drug_flag
ORDER BY total_cost DESC NULLS LAST;

--Q5 a.

SELECT COUNT(DISTINCT cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--Q5 b.

SELECT cbsaname, population
FROM cbsa
INNER JOIN population
USING (fipscounty)
WHERE population IS NOT null
ORDER BY population DESC;

--Q5 c.

(SELECT county, population
FROM fips_county
INNER JOIN population
USING (fipscounty))
EXCEPT
(SELECT fipscounty, cbsa::numeric
FROM cbsa)
ORDER BY population DESC;

--Q6 a.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--Q6 b.

SELECT drug_name, total_claim_count,
CASE WHEN opioid_drug_flag LIKE 'Y' THEN 'opioid'
ELSE 'not opioid' END AS opioid
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count >= 3000;

--Q6 c.

SELECT drug_name, total_claim_count, nppes_provider_first_name, nppes_provider_last_org_name,
CASE WHEN opioid_drug_flag LIKE 'Y' THEN 'opioid'
ELSE 'not opioid' END AS opioid
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE total_claim_count >= 3000;

--Q7 a.

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--Q7 b.

SELECT prescriber.npi, drug.drug_name, total_claim_count
FROM prescriber
CROSS JOIN drug
FULL JOIN prescription
ON prescriber.npi = prescription.npi AND drug.drug_name = prescription.drug_name
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--Q7 c.

SELECT prescriber.npi, drug.drug_name, COALESCE(total_claim_count,0) AS total_claim_count
FROM prescriber
CROSS JOIN drug
FULL JOIN prescription
ON prescriber.npi = prescription.npi AND drug.drug_name = prescription.drug_name
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y'
ORDER BY total_claim_count DESC;

--BONUS
--Q1

SELECT npi
FROM prescriber
EXCEPT
SELECT npi
FROM prescription;

--Q2 a.

SELECT generic_name, SUM(total_claim_count) AS total_prescribed
FROM prescription
INNER JOIN prescriber
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_prescribed DESC
LIMIT 5;

--Q2 b.

SELECT generic_name, SUM(total_claim_count) AS total_prescribed
FROM prescription
INNER JOIN prescriber
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_prescribed DESC
LIMIT 5;

--Q2 c.

SELECT generic_name, SUM(total_claim_count) AS total_prescribed
FROM prescription
INNER JOIN prescriber
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE specialty_description = 'Cardiology' OR specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_prescribed DESC
LIMIT 5;

--Q3 a.

SELECT npi, SUM(total_claim_count) AS total_prescriptions, nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_prescriptions DESC;

--Q3 b.

SELECT npi, SUM(total_claim_count) AS total_prescriptions, nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_prescriptions DESC;

--Q3 c.

SELECT npi, SUM(total_claim_count) AS total_prescriptions, nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
OR nppes_provider_city = 'MEMPHIS'
OR nppes_provider_city = 'KNOXVILLE'
OR nppes_provider_city = 'CHATTANOOGA'
GROUP BY npi, nppes_provider_city
ORDER BY total_prescriptions DESC;

--Q4 

SELECT county, SUM(overdose_deaths) AS ods
FROM fips_county
INNER JOIN overdose_deaths
ON fips_county.fipscounty::INTEGER = overdose_deaths.fipscounty
WHERE overdose_deaths > (SELECT AVG(overdose_deaths)
						FROM overdose_deaths)
GROUP BY county
ORDER BY ods DESC;

--Q5

WITH tn_pop AS (SELECT state, SUM(population) AS total_pop
FROM population
INNER JOIN fips_county
USING (fipscounty)
WHERE state = 'TN'
GROUP BY state)

SELECT county, population, ROUND(((population / total_pop) * 100),2) AS pop_perct
FROM fips_county
INNER JOIN population
USING (fipscounty)
INNER JOIN tn_pop
USING (state);






