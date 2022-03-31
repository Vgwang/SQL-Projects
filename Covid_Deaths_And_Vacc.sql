-- Selecting and taking a look at the data that we are going to be starting with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1,2

-- Total Deaths vs Total Cases
-- Shows likelihood of dying if you contract covid in the US
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT)) * 100 AS Death_Percentage
FROM covid_deaths
WHERE location LIKE '%States%'
ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT location, date, population, total_cases, (CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 AS Percent_Population_Infected
FROM covid_deaths
ORDER BY 1,2

-- Percentage of population infect with Covid in the US
SELECT location, date, population, total_cases, (CAST(total_cases AS FLOAT)/CAST(population AS FLOAT))*100 AS Percent_Population_Infected
FROM covid_deaths
WHERE location LIKE '%States%'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) as Highest_Infection_count, MAX(CAST(total_cases AS FLOAT)/ CAST(population AS FLOAT)) * 100 AS Percent_Population_Infected
FROM covid_deaths
GROUP BY location, population
ORDER BY Percent_Population_Infected DESC

-- Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS BIGINT)) AS Total_Death_Count
FROM covid_deaths
WHERE continent IS NOT null
GROUP BY location
ORDER BY Total_Death_Count DESC

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS BIGINT)) AS Total_Death_Count
FROM covid_deaths
WHERE continent IS NOT null
GROUP BY continent
ORDER BY Total_Death_Count DESC

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS FLOAT))/SUM(CAST(new_cases AS FLOAT)) * 100 AS Death_Percentage
FROM covid_deaths
WHERE continent IS NOT null
GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vacc.new_vaccinations, SUM(CAST(covid_vacc.new_vaccinations AS INT)) OVER (PARTITION BY covid_deaths.location ORDER BY covid_deaths.location, covid_deaths.Date) AS Rolling_People_Vaccinated
FROM covid_deaths
JOIN covid_vacc
	ON covid_deaths.location = covid_vacc.location
	AND covid_deaths.date = covid_vacc.date
WHERE covid_deaths.continent IS NOT null
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vacc.new_vaccinations
, SUM(CAST(covid_vacc.new_vaccinations AS INT)) OVER (PARTITION BY covid_deaths.Location ORDER BY covid_deaths.location, covid_deaths.Date) AS Rolling_People_Vaccinated
FROM covid_deaths
JOIN covid_vacc
	ON covid_deaths.location = covid_vacc.location
	AND covid_deaths.date = covid_vacc.date
WHERE covid_deaths.continent IS NOT null 
)
SELECT *, (CAST(Rolling_People_Vaccinated AS FLOAT)/CAST(Population AS FLOAT))*100 AS Rolling_Percentage_Vaccinated
FROM PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS Percent_Population_Vaccinated;
CREATE TABLE Percent_Population_Vaccinated
(
Continent TEXT,
Location TEXT,
Date DATE,
Population NUMERIC,
New_vaccinations NUMERIC,
Rolling_People_Vaccinated NUMERIC
);

INSERT INTO Percent_Population_Vaccinated
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vacc.new_vaccinations
, SUM(CAST(covid_vacc.new_vaccinations AS INT)) OVER (PARTITION BY covid_deaths.Location ORDER BY covid_deaths.location, covid_deaths.Date) AS Rolling_People_Vaccinated
FROM covid_deaths
JOIN covid_vacc
	ON covid_deaths.location = covid_vacc.location
	AND covid_deaths.date = covid_vacc.date

-- View Temp Table
SELECT *, (CAST(Percent_Population_Vaccinated.Rolling_People_Vaccinated AS FLOAT)/CAST(Population AS FLOAT))*100 AS Rolling_Percentage_Vaccinated
FROM Percent_Population_Vaccinated




-- Creating View to store data for later visualizations

CREATE VIEW Percent_Population_Vaccinated AS
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vacc.new_vaccinations
, SUM(CAST(covid_vacc.new_vaccinations AS INT)) OVER (PARTITION BY covid_deaths.Location ORDER BY covid_deaths.location, covid_deaths.Date) AS Rolling_People_Vaccinated
FROM covid_deaths
JOIN covid_vacc
	ON covid_deaths.location = covid_vacc.location
	AND covid_deaths.date = covid_vacc.date
WHERE covid_deaths.continent IS NOT null 
