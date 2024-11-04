


DROP TABLE IF EXISTS teams;
CREATE TABLE teams
(
	TEAM_ID VARCHAR(15),
	ABBREVIATION VARCHAR(5),
	TEAM_NAME VARCHAR(55),
	YEARFOUNDED	VARCHAR(5),
	MAX_YEAR VARCHAR(5),
	ARENA VARCHAR(55),
	ARENACAPACITY BIGINT,
	team_OWNER VARCHAR(55),
	GENERALMANAGER VARCHAR(55),
	HEADCOACH VARCHAR(55),
	DLEAGUEAFFILIATION VARCHAR(55)

);


DROP TABLE IF EXISTS ranking;
CREATE TABLE ranking
(
	TEAM_ID VARCHAR(15),
	SEASON_ID VARCHAR(5),
	STANDINGSDATE DATE,
	CONFERENCE	VARCHAR(5),
	G INT,
	w INT,
	l INT,
	W_PCT FLOAT,
	HOME_RECORD	DATE,
	ROAD_RECORD VARCHAR(55)
);



DROP TABLE IF EXISTS players;
CREATE TABLE players
(
	PLAYER_ID VARCHAR(15),
	PLAYER_NAME VARCHAR(55),
	TEAM_ID VARCHAR(15),
	SEASON VARCHAR(5)

);



DROP TABLE IF EXISTS games;
CREATE TABLE games
(
	GAME_DATE_EST DATE,
	GAME_ID VARCHAR(15),
	GAME_STATUS_TEXT VARCHAR(10),
	SEASON VARCHAR(5),
	TEAM_ID_home VARCHAR(15),
	PTS_home INT,
	AST_home INT,
	REB_home INT,
	FG_PCT_home FLOAT,
	FT_PCT_home FLOAT,
	FG3_PCT_home FLOAT,
	TEAM_ID_away VARCHAR(15),
	PTS_away INT,
	AST_away INT,
	REB_away INT,
	FG_PCT_away FLOAT,
	FT_PCT_away FLOAT,
	FG3_PCT_away FLOAT,
	HOME_TEAM_WINS VARCHAR(5)
);


DROP TABLE IF EXISTS game_details;
CREATE TABLE game_details
(
	GAME_ID VARCHAR(15),
	TEAM_ID VARCHAR(15),
	PLAYER_ID VARCHAR(15),
	START_POSITION VARCHAR(5),
	PLAYER_COMMENT VARCHAR(55),
	PMIN VARCHAR(55),
	FGM INT,
	FGA INT,
	FG_PCT FLOAT,
	FG3M INT,
	FG3A INT,
	FG3_PCT FLOAT,
	FTM INT,
	FTA INT,
	FT_PCT FLOAT,
	OREB INT,
	DREB INT,
	REB INT,
	AST INT,
	STL	INT,
	BLK	INT,
	TURN_OVER INT,
	PF INT,
	PTS	INT,
	PLUS_MINUS INT
);


SELECT * FROM games;
SELECT * FROM game_details;
SELECT * FROM teams;
SELECT * FROM players ;
SELECT * FROM ranking;




-- Team Performance Analysis:
-- Could you provide a ranking of teams by their overall performance, focusing on win/loss records from 2004 onwards?
-- Can you split this analysis by conference (West/East) and show any trends over time?

WITH team_performance AS
(
SELECT 
	r.team_id,
	t.team_name,
	g,
	w,
	l,	
	RIGHT(season_id, 4) AS season,
	conference,	
	RANK() OVER(PARTITION BY RIGHT(season_id, 4), conference ORDER BY w DESC)
FROM ranking r
JOIN
	teams t ON t.team_id = r.team_id
WHERE g = 82
GROUP BY 1,2,3,4,5,6,7
ORDER BY 2,6
)

SELECT
	team_id,
	team_name,
	conference,
	RANK() OVER(PARTITION BY conference ORDER BY SUM(w) DESC) AS ranking,
	SUM(w) AS total_wins,
	SUM(l) AS total_losses
FROM team_performance
GROUP BY 1,2,3
ORDER BY 3,4


-- Top Players:
-- We need insights on top-performing players in the league.
-- Could you provide the top 10 players based on overall performance metrics (points, assists, rebounds, etc.) from the games played?

WITH player_names AS
(
SELECT 
	DISTINCT player_id, player_name
FROM players
),
player_stats AS 
(
SELECT
	gd.player_id,
	pn.player_name,
	gd.team_id,
	t.team_name,
	g.season,
	SUM(pts) AS points,
	ROUND(AVG(pts),1) AS avg_points,
	SUM(ast) AS assists,
	ROUND(AVG(ast),1) AS avg_assists,
	SUM(reb) AS rebounds,
	ROUND(AVG(reb),1) AS avg_rebounds
FROM game_details gd
JOIN 
	games g ON g.game_id = gd.game_id
JOIN 
	teams t On t.team_id = gd.team_id
JOIN 
	player_names pn ON pn.player_id = gd.player_id
--WHERE gd.player_id = '2544'
GROUP BY 1, 2, 3, 4, 5
)
SELECT 
	player_id,
	player_name,
	SUM(points) AS total_points,
	SUM(assists) AS total_assists,
	SUM(rebounds) AS total_rebounds
FROM player_stats ps
GROUP BY 1, 2
HAVING SUM(points) IS NOT NULL
ORDER BY SUM(points) DESC, SUM(assists) DESC, SUM(rebounds) DESC





-- Detailed Game Stats:
-- For a deeper dive, can you show us a breakdown of game statistics for key matchups, like top teams playing against each other?
-- Include any trends regarding team statistics such as total points scored, turnovers, and fouls committed.

SELECT 
	gd.game_id,
	gd.team_id,
	t.team_name,
	SUM(gd.pts) AS points,
	SUM(gd.turn_over) AS turn_overs,
	SUM(gd.pf) AS fouls
FROM game_details gd
JOIN 
	teams t ON t.team_id = gd.team_id
WHERE game_id IN
(
	SELECT game_id FROM game_details 
	WHERE team_id IN	(SELECT team_id FROM team_rankings WHERE ranking <= 1)
	GROUP BY 1
	HAVING COUNT(DISTINCT team_id) = 2
)
GROUP BY 1,2,3
ORDER BY 1



-- Ranking Insights:
-- We would like to understand how team rankings (by wins/losses) have shifted over time.
-- Can you plot this out and show whether certain teams have consistently stayed on top or fluctuated in the rankings?



-- Player & Team Correlation:
-- Lastly, can you look into whether there's any correlation between a team's ranking and the performance of their top players?
-- For example, are teams with top-scoring players also the ones ranked highest?


SELECT 
	tp.player_id,
	tp.player_name,
	gd.team_id,
	t.team_name,
	g.season,
	ss.rank,
	SUM(pts) AS points,
	SUM(ast) AS assists,
	SUM(reb) AS rebounds
FROM game_details gd
JOIN 
	games g ON g.game_id = gd.game_id
JOIN 
	top_10_players tp ON tp.player_id = gd.player_id
JOIN 
	teams t ON t.team_id = gd.team_id
JOIN 
	seasonal_standings ss ON ss.team_id = gd.team_id AND ss.season = g.season
WHERE gd.pts IS NOT NULL
GROUP BY 1,2,3,4,5,6






