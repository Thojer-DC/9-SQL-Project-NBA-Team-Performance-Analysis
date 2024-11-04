CTAS

CREATE TABLE  team_rankings AS
(
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
)







CREATE TABLE seasonal_standings AS
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
HAVING RIGHT(season_id, 4)::numeric >= 2004
ORDER BY 2,6
)





CREATE TABLE seasonal_player_stats AS
(
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
	*
FROM player_stats ps
ORDER BY player_name, season
)


CREATE TABLE top_10_players AS
(
SELECT 
	player_id,
	player_name,
	SUM(points) AS total_points,
	SUM(assists) AS total_asssits,
	SUM(rebounds) AS total_rebounds
FROM seasonal_player_stats
GROUP BY 1, 2
HAVING SUM(points) IS NOT NULL
ORDER BY SUM(points) DESC, SUM(assists) DESC, SUM(rebounds) DESC
LIMIT 10
)


