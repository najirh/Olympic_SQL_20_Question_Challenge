-- ------------------------------------------------------------------------------------------------
-- SQL Project on 120 year Olympic Data
-- Solved 20 most commonly asked question
-- -- ------------------------------------------------------------------------------------------------

SELECT * FROM olympycs_history;
SELECT * FROM olympycs_history_noc_regions;


--  Q. 1 How many olympics games have been held ?

SELECT COUNT(DISTINCT games) as total_games 
FROM olympycs_history;


-- Q.2 2. List down all Olympics games held so far.

SELECT 
    DISTINCT year, city, games as list_games
FROM olympycs_history;

-- Q.3 3. Mention the total no of nations who participated in each olympics game?

SELECT 
    o.games, COUNT(DISTINCT oh.region) 
FROM olympycs_history as o 
JOIN olympycs_history_noc_regions as oh
ON o.noc = oh.noc 
GROUP BY o.games;



WITH total_countries
AS (SELECT 
		o.games,
		oh.region
	FROM olympycs_history as o 
	JOIN olympycs_history_noc_regions as oh
	ON o.noc = oh.noc
	GROUP BY 1, 2
	ORDER BY 1
   )
   
SELECT games, COUNT(2)
FROM total_countries
GROUP BY games
ORDER BY games;


-- Q.4 4. Which year saw the highest and lowest no of countries participating in olympics

WITH total_year
AS (
     SELECT 
        o.year,
        oh.region
    FROM olympycs_history as o 
    JOIN olympycs_history_noc_regions as oh 
    ON o.noc = oh.noc
    GROUP BY 1, 2
    ORDER BY 1
),
count_counties
AS 
(
    SELECT 
        year, 
        COUNT(region) as total_countries
    FROM total_year
    GROUP BY year
)

SELECT 
    DISTINCT 
    CONCAT(first_value(year) OVER(ORDER BY total_countries), 
    '-',  
    first_value(total_countries) OVER(ORDER BY total_countries))AS lowest_countries,
    
    CONCAT(first_value(year) OVER(ORDER BY total_countries DESC), 
    '-',
    first_value(total_countries) OVER(ORDER BY total_countries DESC)) AS lowest_countries

    FROM count_counties
order by 1;
    
-- Q.5 Which nation has participated in all of the olympic games

WITH total_games
AS 
    (SELECT 
        COUNT(DISTINCT games) as cnt_games 
    FROM olympycs_history
),

country_participated_games
AS
(  
    SELECT 
        oh.region, 
        COUNT(DISTINCT o.games) as game_participated
    FROM olympycs_history as o 
    JOIN olympycs_history_noc_regions as oh 
    ON o.noc=oh.noc 
    GROUP BY 1
)

SELECT 
    c.region, 
    c.game_participated
FROM country_participated_games as c 
JOIN total_games as t 
ON t.cnt_games = c.game_participated
;

-- Q.6 Identify the sport which was played in all summer olympics.

WITH total_summer_games
AS (
    SELECT 
        COUNT(DISTINCT games) as total_games
    FROM olympycs_history
    WHERE seasons = 'Summer'),

sport_counts
AS (
    SELECT 
        sport,
        COUNT(DISTINCT games) no_game_played
    FROM olympycs_history
    WHERE seasons = 'Summer'
    GROUP BY sport
    ORDER BY 2 DESC)

SELECT *
FROM sport_counts as s 
JOIN total_summer_games t
ON s.no_game_played = t.total_games;


-- 7. Which Sports were just played only once in the olympics.
-- find each sports and their total played count 
-- filter sports with sigle played


WITH t1
AS (
    SELECT 
        DISTINCT 
            games,
            sport
    FROM olympycs_history),


t2
AS (
    SELECT 
        sport, count(games) total_played
    FROM t1
    GROUP BY sport 
)

SELECT t2.*, t1.games
FROM t2
JOIN t1 
ON t1.sport = t2.sport
WHERE t2.total_played = 1;



WITH cnt_table 
AS (
    SELECT
        DISTINCT sport, 

        COUNT(DISTINCT games) as cnt
    FROM olympycs_history
    GROUP BY 1)

SELECT 
    sport, 
    cnt
FROM cnt_table
WHERE cnt = 1;

-- 8. Fetch the total no of sports played in each olympic games.


WITH t1 
AS (SELECT 
    DISTINCT games, 
    sport
    FROM olympycs_history),

t2 
AS (SELECT 
    games, 
    COUNT(2)
    FROM t1
    GROUP BY 1)

SELECT *
FROM t2
ORDER BY 1

-- Q. 9. Fetch oldest athletes to win a gold medal


WITH temp1
AS (SELECT 
    name, 
    sex,
    CAST(CASE WHEN age = 'NA' THEN '0' ELSE age END AS int) as age,
    height,
    weight,
    team,
    noc,
    sport,
    event,
    medal
    FROM olympycs_history
    WHERE medal = 'Gold'
    ),
temp2 
AS (
    SELECT *,
    RANK() OVER(ORDER BY age DESC) rnk
FROM temp1
)

SELECT 
    name, 
    sex,
    age,
    height,
    weight,
    team,
    noc,
    sport,
    event,
    medal
FROM temp2 
WHERE rnk = 1

-- Q.10 count number of games where India participated and won medal

SELECT COUNT(*) total_games
FROM olympycs_history
WHERE medal <> 'NA' AND team = 'India' 


-- 11. Fetch the top 5 athletes who have won the most gold medals.

WITH gold_medelist
AS (SELECT 
        name,
        COUNT(1) as total_medal
    FROM olympycs_history
    WHERE medal = 'Gold'
    GROUP BY 1
    ORDER BY total_medal DESC
),
ranked_medelist 
AS ( SELECT *,
    dense_rank() OVER(ORDER BY total_medal DESC) as rnk 
FROM gold_medelist)

SELECT * 
FROM ranked_medelist
WHERE rnk <= 5




-- 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).



WITH gold_medelist
AS (SELECT 
        name,
        COUNT(1) as total_medal
    FROM olympycs_history
    WHERE medal IN ('Gold', 'Silver', 'Bronze')
    GROUP BY 1
    ORDER BY total_medal DESC
),
ranked_medelist 
AS ( SELECT *,
    dense_rank() OVER(ORDER BY total_medal DESC) as rnk 
FROM gold_medelist)

SELECT * 
FROM ranked_medelist
WHERE rnk <= 5



-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
-- number of countries
-- find number of medal won by each country
--  compare 1 & 2

WITH countries 
AS (SELECT 
        oh.region, COUNT(o.medal) AS cnt_medal
    FROM olympycs_history as o 
    JOIN olympycs_history_noc_regions as oh 
    ON o.noc = oh.noc
    WHERE o.medal <> 'NA'
    GROUP BY oh.region
    ),

ranked_countries
AS (
    SELECT *, 
    dense_rank() OVER(ORDER BY cnt_medal DESC) as rnk
FROM countries
)

SELECT * 
FROM ranked_countries
WHERE rnk <= 5;

-- 14. List down total gold, silver and bronze medals won by each country.
-- find out total gold gold by each, silver , bronze

SELECT 
    oh.region as country,
    COALESCE(SUM(CASE WHEN medal = 'Gold' THEN 1 END), 0) AS gold,
    COALESCE(SUM(CASE WHEN medal = 'Silver' THEN 1 END), 0) AS silver,
    COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN 1 END), 0) AS bronze
FROM olympycs_history as o 
JOIN olympycs_history_noc_regions as oh 
ON o.noc = oh.noc 
WHERE medal <> 'NA'
GROUP BY 1
ORDER BY gold DESC, silver DESC, bronze DESC


-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.


SELECT 
    o.games,
    oh.region as country,
    COALESCE(SUM(CASE WHEN medal = 'Gold' THEN 1 END), 0) as gold,
    COALESCE(SUM(CASE WHEN medal = 'Silver' THEN 1 END), 0) as silver,
    COALESCE(SUM(CASE WHEN medal = 'Bronze' THEN 1 END), 0) as bronze
FROM olympycs_history as o 
JOIN olympycs_history_noc_regions as oh 
ON oh.noc = o.noc 
WHERE medal <> 'NA'
GROUP BY 1, 2
ORDER BY 1




-- Q.16 Identify which country won most gold, most silver, most brone medals in each olympics games


CREATE EXTENSION TABLEFUNC; -- To enable Pivot Table Function/ CROSSTAB

    WITH temp as
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    	 	, substring(games, position(' - ' in games) + 3) as country
            , coalesce(gold, 0) as gold
            , coalesce(silver, 0) as silver
            , coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    				  	, count(1) as total_medals
    				  FROM olympycs_history oh
    				  JOIN olympycs_history_noc_regions nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint))
    select distinct games
    	, concat(first_value(country) over(partition by games order by gold desc)
    			, ' - '
    			, first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc)
    			, ' - '
    			, first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc)
    			, ' - '
    			, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
    from temp
    order by games;


-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

/*
Problem Statement: Similar to the previous query, identify during each Olympic Games, 
which country won the highest gold, silver and bronze medals. Along with this, 
identify also the country with the most medals in each olympic games.



-- PIVOT
In Postgresql, we can use crosstab function to create pivot table.
crosstab function is part of a PostgreSQL extension called tablefunc.
To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION TABLEFUNC;

*/
    with temp as
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    		, substring(games, position(' - ' in games) + 3) as country
    		, coalesce(gold, 0) as gold
    		, coalesce(silver, 0) as silver
    		, coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    					, count(1) as total_medals
    				  FROM olympycs_history oh
    				  JOIN olympycs_history_noc_regions nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint)),
    	tot_medals as
    		(SELECT games, nr.region as country, count(1) as total_medals
    		FROM olympycs_history oh
    		JOIN olympycs_history_noc_regions nr ON nr.noc = oh.noc
    		where medal <> 'NA'
    		GROUP BY games,nr.region order BY 1, 2)
    select distinct t.games
    	, concat(first_value(t.country) over(partition by t.games order by gold desc)
    			, ' - '
    			, first_value(t.gold) over(partition by t.games order by gold desc)) as Max_Gold
    	, concat(first_value(t.country) over(partition by t.games order by silver desc)
    			, ' - '
    			, first_value(t.silver) over(partition by t.games order by silver desc)) as Max_Silver
    	, concat(first_value(t.country) over(partition by t.games order by bronze desc)
    			, ' - '
    			, first_value(t.bronze) over(partition by t.games order by bronze desc)) as Max_Bronze
    	, concat(first_value(tm.country) over (partition by tm.games order by total_medals desc nulls last)
    			, ' - '
    			, first_value(tm.total_medals) over(partition by tm.games order by total_medals desc nulls last)) as Max_Medals
    from temp t
    join tot_medals tm on tm.games = t.games and tm.country = t.country
    order by games;


/*
-- PIVOT
In Postgresql, we can use crosstab function to create pivot table.
crosstab function is part of a PostgreSQL extension called tablefunc.
To call the crosstab function, you must first enable the tablefunc extension by executing the following SQL command:

CREATE EXTENSION TABLEFUNC;

18. Which countries have never won gold medal but have won silver/bronze medals?
*/

select * from (
	SELECT country, coalesce(gold,0) as gold, coalesce(silver,0) as silver, coalesce(bronze,0) as bronze
		FROM CROSSTAB('SELECT nr.region as country
					, medal, count(1) as total_medals
					FROM olympycs_history oh
					JOIN olympycs_history_noc_regions nr ON nr.noc=oh.noc
					where medal <> ''NA''
					GROUP BY nr.region,medal order BY nr.region,medal',
				'values (''Bronze''), (''Gold''), (''Silver'')')
		AS FINAL_RESULT(country varchar,
		bronze bigint, gold bigint, silver bigint)) x
where gold = 0 and (silver > 0 or bronze > 0)
order by gold desc nulls last, silver desc nulls last, bronze desc nulls last;



-- 19. In which Sport/event, India has won highest medals.
    
	
	
WITH india_medals
AS (
    SELECT 
		sport, COUNT(1) as total_medal
	FROM olympycs_history
	WHERE medal <> 'NA' AND team = 'India'
	GROUP BY sport
	ORDER BY total_medal DESC),

ranked_india
AS (SELECT *,
    rank() OVER(ORDER BY total_medal DESC) AS rnk 
FROM india_medals
    )
SELECT sport, total_medal
FROM ranked_india
WHERE rnk = 1
	
	
-- 20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games
    
SELECT team, sport, games, count(1) as total_games
FROM olympycs_history
WHERE medal <> 'NA' AND sport = 'Hockey'
AND team = 'India'
GROUP BY team, sport, games

   
   
   