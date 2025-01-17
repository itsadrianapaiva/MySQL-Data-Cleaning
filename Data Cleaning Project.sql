-- Data Cleaning Project

-- 1. Remove duplicates 
-- 2. Standardize the Data
-- 3. Null values or blank values
-- 4. Remove Any Columns


SELECT *
FROM world_layoffs.layoffs;


-- 1. Remove duplicates 

-- I'm creating a staging table to work on so I can always go back to
-- the raw data if something goes wrong.

CREATE TABLE world_layoffs.layoffs_staging
LIKE world_layoffs.layoffs;

SELECT *
FROM world_layoffs.layoffs_staging;

INSERT world_layoffs.layoffs_staging
SELECT *
FROM world_layoffs.layoffs;


-- I'm creating row numbers for the data to check for duplicates.

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off,  `date`) AS  row_num
FROM world_layoffs.layoffs_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised) AS  row_num
FROM world_layoffs.layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Checking the duplicate to make sure it really is a duplicate
-- and it looks like they aren't all real duplicates. I'm glad I checked.
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Cazoo';

-- I'll be taking a different approach to delete the duplicates only
-- Creating a new staging table with the actual row_num and delete it where the row is = 2
CREATE TABLE `world_layoffs`.`layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` text,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised` double DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM world_layoffs.layoffs_staging2;

INSERT INTO world_layoffs.layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised) AS  row_num
FROM world_layoffs.layoffs_staging;

-- Before deleting, I checked with a select statement to be sure about what was being deleted
DELETE 
FROM world_layoffs.layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM world_layoffs.layoffs_staging2;


-- 2. Standardize the Data

-- I'll start by removing  the white space with TRIM()
SELECT DISTINCT (company), TRIM(company)
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET company = TRIM(company);

-- Checking other columns.
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT DISTINCT *
FROM world_layoffs.layoffs_staging2
WHERE industry LIKE 'https%';

-- Removing the link from the row.
UPDATE world_layoffs.layoffs_staging2
SET industry = ' '
WHERE industry LIKE 'http%';

SELECT DISTINCT *
FROM world_layoffs.layoffs_staging2;

-- Checking other columns and fixing the unknown characters.
SELECT DISTINCT country, location
FROM world_layoffs.layoffs_staging2
ORDER BY 1;

SELECT DISTINCT location
FROM world_layoffs.layoffs_staging2
WHERE location LIKE 'D%';

UPDATE world_layoffs.layoffs_staging2
SET location = 'Dusseldorf'
WHERE location LIKE '%sseldorf';

SELECT DISTINCT country, location
FROM world_layoffs.layoffs_staging2
WHERE location LIKE 'Non%';

UPDATE world_layoffs.layoffs_staging2
SET location = 'Forde'
WHERE location LIKE '%rde';

UPDATE world_layoffs.layoffs_staging2
SET location = 'Florianopolis'
WHERE location LIKE 'Flo%polis';

UPDATE world_layoffs.layoffs_staging2
SET location = 'Malmo'
WHERE location LIKE 'Malm%';

SELECT DISTINCT country, location
FROM world_layoffs.layoffs_staging2
WHERE location LIKE 'Non-%';

-- Removing dots from the data.
SELECT DISTINCT country, location, TRIM(TRAILING '.' FROM location)
FROM world_layoffs.layoffs_staging2
WHERE location LIKE 'Non-%';

UPDATE world_layoffs.layoffs_staging2
SET location = TRIM(TRAILING '.' FROM location)
WHERE location LIKE 'Non-%';

-- I'm changing the date format which was initially as text
SELECT `date`,
date_format(`date`, '%m/%d/%Y')
FROM world_layoffs.layoffs_staging2;

UPDATE world_layoffs.layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

ALTER TABLE world_layoffs.layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. Null Values or blank values

-- I'm checking for nulls and missing values
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE (total_laid_off IS NULL
OR total_laid_off  = '')
AND percentage_laid_off IS NULL
OR percentage_laid_off = '';

SELECT DISTINCT *
FROM world_layoffs.layoffs_staging2
WHERE industry is NULL 
OR industry = '';

-- There are black spaces that aren't coming up but I can pull up in a more specif selection
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE country = 'Israel';

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'eBay';

SELECT *
FROM world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
		ON t1.company = t2.company
		AND t1.location = t2.location
WHERE t1.company = 'eBay';

-- Populating the eBay blanks with similar values  
SELECT *
FROM world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
		ON t1.company = t2.company
		AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
-- for some reason eBay doesn't show with this selection 

-- In this case, I could set eBay blanks into nulls and then procede with the update.
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL 
WHERE industry = '';

UPDATE world_layoffs.layoffs_staging2 t1
JOIN world_layoffs.layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
-- now I was able to populate with the update as expected.

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2;

-- There's still one company with blank industry and I'll insert data manually
-- based on real-world research 
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company = 'Appsmith';

UPDATE world_layoffs.layoffs_staging2
SET industry = 'Software'
WHERE company = 'Appsmith';

SELECT DISTINCT *
FROM world_layoffs.layoffs_staging2;

-- Turning all the blanks into nulls on the remaining columns.
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE (total_laid_off IS NULL
OR total_laid_off  = '')
AND percentage_laid_off IS NULL
OR percentage_laid_off = '';

UPDATE world_layoffs.layoffs_staging2
SET total_laid_off  = NULL 
WHERE total_laid_off = '';

UPDATE world_layoffs.layoffs_staging2
SET percentage_laid_off = NULL 
WHERE percentage_laid_off = '';
-- I could've used CASE Expression to update both columns altogether. 

SELECT total_laid_off, percentage_laid_off
FROM world_layoffs.layoffs_staging2;


-- 4. Remove Any Columns

-- Based on the fact that I'll be doing calculations through EDA phase,
-- all the  null values in both total_laid_off and percentage_laid_off won't have much value 
-- and I can't really trust that data.
-- For that reason I'm going to delete them all.

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM world_layoffs.layoffs_staging2;

-- Now, to wrap it up I'll remove the row_num column that I initially created.
ALTER TABLE world_layoffs.layoffs_staging2
DROP COLUMN row_num;


-- Data is ready for EDA phase. 




