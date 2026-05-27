SELECT * 
FROM layoffs.layoffs_world;



-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens
CREATE TABLE layoffs.layoffs_world1 
LIKE layoffs.layoffs_world;

INSERT layoffs.layoffs_world1 
SELECT * FROM layoffs.layoffs_world;


-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways



-- 1. Remove Duplicates

# First let's check for duplicates



SELECT *
FROM layoffs.layoffs_world1
;

SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`) AS row_num
	FROM 
		layoffs.layoffs_world1;



SELECT *
FROM (
	SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`
			) AS row_num
	FROM 
		layoffs.layoffs_world1
) duplicates
WHERE 
	row_num > 1;
    
-- let's just look at oda to confirm
SELECT *
FROM layoffs.layoffs_world1
WHERE company = 'Oda'
;
-- it looks like these are all legitimate entries and shouldn't be deleted. We need to really look at every single row to be accurate

-- these are our real duplicates 
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs.layoffs_world1
) duplicates
WHERE 
	row_num > 1;

-- these are the ones we want to delete where the row number is > 1 or 2or greater essentially

-- now you may want to write it like this:
WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;
SELECT distinct country

 FROM layoffs_world2;

WITH DELETE_CTE AS (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, 
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num) IN (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions, row_num
	FROM DELETE_CTE
) AND row_num > 1;

-- one solution, which I think is a good one. Is to create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column
-- so let's do it!!

ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;


SELECT *
FROM world_layoffs.layoffs_staging
;

CREATE TABLE `layoffs`.`layoffs_world2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

INSERT INTO `layoffs`.`layoffs_world2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		layoffs.layoffs_world1;

-- now that we have this we can delete rows were row_num is greater than 2

DELETE FROM layoffs.layoffs_world2
WHERE row_num >= 2;

-- 2. Standardize Data

SELECT * 
FROM layoffs.layoffs_world2;

-- if we look at industry it looks like we have some null and empty rows, let's take a look at these
SELECT DISTINCT industry
FROM layoffs.layoffs_world2
ORDER BY industry;

SELECT *
FROM layoffs.layoffs_world2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;


UPDATE layoffs_world2
SET industry = 'Crypto'
WHERE industry LIKE '%crypto%';

SELECT *
FROM layoffs.layoffs_world2;

-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. Let's standardize this.
SELECT DISTINCT country
FROM layoffs.layoffs_world2
ORDER BY country;

UPDATE layoffs.layoffs_world2
SET country = TRIM(TRAILING '.' FROM country);

-- now if we run this again it is fixed
SELECT DISTINCT country
FROM layoffs.layoffs_world2
ORDER BY country;


-- Let's also fix the date columns:
SELECT *
FROM layoffs.layoffs_world2;

-- we can use str to date to update this field
UPDATE layoffs.layoffs_world2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- now we can convert the data type properly
ALTER TABLE layoffs.layoffs_world2
MODIFY COLUMN `date` DATE;


SELECT *
FROM layoffs.layoffs_world2;

-- 3. Look at Null Values

-- the null values in total_laid_off, percentage_laid_off, and funds_raised_millions all look normal. I don't think I want to change that
-- I like having them null because it makes it easier for calculations during the EDA phase

-- so there isn't anything I want to change with the null values




-- 4. remove any columns and rows we need to

SELECT *
FROM layoffs.layoffs_world2
WHERE total_laid_off IS NULL;



SELECT * 
FROM layoffs.layoffs_world2;


UPDATE layoffs.layoffs_world2
SET industry = NULL
WHERE industry ='';

SELECT * 
FROM layoffs.layoffs_world2;

-- let's take a look at these
SELECT *
FROM layoffs.layoffs_world2
WHERE company LIKE 'Airbnb';
 
SELECT t1.industry,t2.industry
FROM layoffs.layoffs_world2 t1
JOIN layoffs.layoffs_world2 t2
	on t1.company = t2.company 
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;


UPDATE layoffs.layoffs_world2 t1
JOIN layoffs.layoffs_world2 t2
	on t1.company = t2.company 
SET  t1.industry= t2.industry
WHERE (t1.industry is null )
and t2.industry is not null;

SELECT * FROM layoffs.layoffs_world2
WHERE industry ='' OR industry IS NULL;

SELECT * 
FROM layoffs.layoffs_world2;


-- DELETING THE ROW AND COLUMNS WHICH ARE IRRELEVANT
SELECT *
FROM layoffs.layoffs_world2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


-- Delete Useless data we can't really use
DELETE FROM layoffs.layoffs_world2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs.layoffs_world2;

ALTER TABLE layoffs.layoffs_world2
DROP COLUMN row_num;

SELECT * FROM layoffs.layoffs_world2;
