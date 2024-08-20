
use MyDatabase;


-- Check for duplicates
SELECT COUNT (*) FROM HockeyTeam;

SELECT COUNT(*) FROM
(SELECT DISTINCT * FROM HockeyTeam)
AS DISTINCT_ROWS;


WITH CTE AS (
	SELECT DISTINCT * FROM HockeyTeam)
SELECT COUNT(*) FROM CTE


-- View Data in a form that puts duplicate rows together
SELECT * FROM HockeyTeam
ORDER BY [Team Name], Year;


-- Delete duplicate records
WITH CTE AS (
    SELECT 
        [Team Name],
        [Year],
        [Wins],
        [Losses],
        [OT Losses],
        [Win %],
        [Goals For (GF)],
        [Goals Against (GA)],
        [+ / -],
        ROW_NUMBER() OVER (
            PARTITION BY 
                [Team Name], 
                [Year], 
                [Wins], 
                [Losses], 
                [OT Losses], 
                [Win %], 
                [Goals For (GF)], 
                [Goals Against (GA)], 
                [+ / -]
            ORDER BY 
                (SELECT NULL)
        ) AS rn
    FROM 
        HockeyTeam
)
DELETE FROM CTE
WHERE rn > 1;


-- Check that duplicate records have been removed
SELECT COUNT(*) FROM HockeyTeam;

SELECT * FROM HockeyTeam;

-- Rename '+/-' column header to 'Goal Difference'
EXEC sp_rename 'HockeyTeam.[+ / -]', 'Goal Difference', 'COLUMN'


-- Rename 'OT Losses' column header to 'Overtime Losses'
EXEC sp_rename 'HockeyTeam.[OT Losses]', 'Overtime Losses', 'COLUMN'



-- Create new column that shows difference between Wins and Losses
ALTER TABLE HockeyTeam
ADD Win_Difference INT;

UPDATE HockeyTeam
SET Win_Difference = (Cast(Wins AS INT) - Cast(Losses AS INT));


-- Total number of Games per Team
ALTER TABLE HockeyTeam
ADD Total_Games INT;

UPDATE HockeyTeam
SET Total_Games = (Cast(Wins AS INT) + Cast(Losses AS INT) + Cast([Overtime Losses] AS INT));


-- Group years into eras
-- Group Games before 2000 as Millenial Era, before 2010 as Gen Z, from 2010 and beyond as Gen X

-- First check minimum and maximum years to determine boundaries
SELECT MIN(Year) From HockeyTeam;

SELECT MAX(Year) From HockeyTeam;

-- Create Era column
ALTER TABLE HockeyTeam
ADD Era VARCHAR (255);

UPDATE HockeyTeam
SET Era = CASE 
	WHEN Year >= 2010 THEN 'Gen X'
	WHEN Year >= 2000 THEN 'Gen Z'
	Else 'Millenial'
END;



-- Create new team name column from Initials

-- First Get the Maximum number of spaces in the 'Team Name' Column to determine how many scenarios (for number of spaces) would be created

SELECT MAX((LEN([Team Name]) - LEN(REPLACE([Team Name], ' ', '')))) AS NumberofSpaces
FROM HockeyTeam


ALTER TABLE HockeyTeam
ADD Initials VARCHAR(10);


UPDATE HockeyTeam
Set Initials = 
    -- Extract the initials
    LEFT([Team Name], 1) +
    CASE WHEN CHARINDEX(' ', [Team Name]) > 0 
				THEN SUBSTRING([Team Name], CHARINDEX(' ', [Team Name]) + 1, 1) ELSE '' END +

    CASE WHEN CHARINDEX(' ', 
							SUBSTRING([Team Name], 
										CHARINDEX(' ', [Team Name]) + 1, 
										LEN([Team Name]))) > 0 
				THEN LEFT(SUBSTRING([Team Name], 
									CHARINDEX(' ', [Team Name]) + 
									CHARINDEX(' ', 
												SUBSTRING([Team Name], 
															CHARINDEX(' ', [Team Name]) + 1, 
															LEN([Team Name]))) + 1, 
						LEN([Team Name])), 
					1) ELSE '' END