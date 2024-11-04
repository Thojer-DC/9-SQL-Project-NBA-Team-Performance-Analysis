# NBA Performance Insights Dashboard


![](https://github.com/Thojer-DC/9-SQL-Project-NBA-Team-Performance-Analysis/blob/main/nba.png)


## Overview


This project delivers insight analysis of NBA team and player performance from 2004 - 2021 season. Using data on seasonal team ranking, game metrics, and performance of player, The dashboard provides insighful league trends, player impact, and team success over the years.


## Objective
1. Explore team rankings by win/loss records, both overall and by conference.
2. Identify the top-performing players based on metrics such as points, assists, and rebounds.
3. Examine key game statistics for matchups between top rank teams.
4. Assess the relationship between team success and the contributions of top players.
5. Visualize changes in team rankings and player stats across seasons to reveal trends.

## SQL Schema
**Creating database** 
```SQL
   CREATE DATABASE nba_db;

```

**Creating table** 
   ```SQL
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
```


## SQL Query

**1. Team Performance and Team ranking over time**
```SQL
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
ORDER BY 3,4;
```

**2. Top-performing players in the league**
```SQL
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
   ORDER BY SUM(points) DESC, SUM(assists) DESC, SUM(rebounds) DESC;
```

**3.Detailed game metrics for between top teams matchups**
```SQL
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
```

**4. Top player and team Correlation**
```SQL
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
   GROUP BY 1,2,3,4,5,6;
```

## Dashboard
![Dashboard](https://github.com/Thojer-DC/9-SQL-Project-NBA-Team-Performance-Analysis/blob/main/Dashboard.png)

## Findings and Recommendations

**Findings:**  
1. Certain teams hold top rankings constantly, while others rise and fall, proving strength in their conference.
2. High-ranking teams often have high-scoring players, demonstrating the connection between team success and superstars performance.
3. Top teams tend to have more turnovers and fouls in major matches because it can be difficult to match up with other top teams.


**Recommendations:**
1. To stay competitive, teams could focus on developing top-performing players.
2. Specific patterns in conference play may help in developing plans for securing playoff positions.
3. Regularly observing player impact on team success can help with strategic acquisitions and lineup changes.



