SELECT * FROM layoffs_world2;

SELECT MAX(total_laid_off)
FROM layoffs_world2;

SELECT SUM(total_laid_off)
FROM layoffs_world2;

SELECT MAX(percentage_laid_off),MIN(percentage_laid_off)
FROM layoffs.layoffs_world2
WHERE percentage_laid_off IS NOT NULL;

SELECT * FROM layoffs_world2
WHERE percentage_laid_off = 1;
-- this company are meant to startups or companies which aren't working well in the current market scenarios
SELECT * FROM layoffs_world2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- This will tell us How huge the MNC is truelly or it's a startup
-- The more the funds raised means they are successfully yet they aren't now

-- sort by the 2nd column in the SELECT statement.
SELECT company,total_laid_off
FROM layoffs_world2
ORDER BY 2 DESC
LIMIT 5 ;
-- showing TOP-5 which companies has laid off most no.of employees
SELECT company,SUM(total_laid_off)
from layoffs_world2
GROUP BY company
ORDER BY 2 DESC
LIMIT 5;
-- showing TOP-5 in which location does most no.of employees been laid off
SELECT location,SUM(total_laid_off)
from layoffs_world2
GROUP BY location
ORDER BY 2 DESC
LIMIT 5;
-- showing which companies has laid off most no.of employees
SELECT company,SUM(total_laid_off)
from layoffs_world2
GROUP BY company
ORDER BY 2 DESC
;

SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_world2
GROUP BY YEAR(date)
ORDER BY 1 ASC;

SELECT industry,SUM(total_laid_off)
FROM layoffs_world2
GROUP BY industry
ORDER BY 2 DESC;

SELECT stage,SUM(total_laid_off)
FROM layoffs_world2
GROUP BY stage
ORDER BY 2 DESC;

WITH Company_year AS 
(
	SELECT company,YEAR(date) AS years,SUM(total_laid_off) AS total_laid_off
    FROM layoffs_world2
    GROUP BY company,YEAR(date))
    ,
    Company_Year_Rank AS (
    SELECT company,years,total_laid_off,DENSE_RANK() OVER 
    (PARTITION BY years ORDER BY total_laid_off DESC) AS 
    ranking
    FROM Company_year
    )
    SELECT company,years,total_laid_off,ranking
    FROM Company_Year_Rank
    WHERE ranking <=5
-- if we want to neglect the year which isn't asigned just add
--  AND year IS NOT NULL
    ORDER BY years ASC , total_laid_off DESC;

-- this an rolling total of layoffs per month of all companies from the dataset
SELECT SUBSTRING(date,1,7) as dates,SUM(total_laid_off) as total_laid_off
FROM layoffs_world2
GROUP BY dates
ORDER BY dates ASC;

WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_world2
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;


WITH DATE_CTE AS 
(
SELECT SUBSTRING(date,1,7) as dates, AVG(total_laid_off) AS total_laid_off
FROM layoffs_world2
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, ROUND(AVG(total_laid_off) OVER (ORDER BY dates ASC),3) as AVG_layoffs
FROM DATE_CTE
ORDER BY dates ASC;

