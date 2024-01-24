1. Fetch all the paintings which are not displayed on any museums?
SELECT * FROM work
where museum_id is null;

2. Are there museums without any paintings?
SELECT m.*
FROM museum m
WHERE NOT EXISTS (
    SELECT 1
    FROM work w
    WHERE w.museum_id = m.museum_id
);

3. How many paintings have an asking price of more than their regular price?
 SELECT count(work_id) FROM
 paintings.product_size
 where regular_price<sale_price;
 
 
 4. Identify the paintings whose asking price is less than 50% of its regular price
 
SELECT count(work_id) FROM
 paintings.product_size
 where regular_price* 0.5>sale_price;
 
 5. Which canva size costs the most?
 SELECT label
FROM canvas_size
WHERE size_id = (
    SELECT size_id
    FROM product_size
    ORDER BY sale_price DESC #cant use the max here because it needs groupby
    LIMIT 1
);
 
 
 6. Delete duplicate records from work, product_size, subject and image_link tables
 
 
 
7. Identify the museums with invalid city information in the given dataset
 SELECT *
FROM museum
WHERE city REGEXP '^[0-9]';

8) Museum_Hours table has 1 invalid entry. Identify it and remove it.
 SELECT *
FROM Museum_Hours
WHERE NOT (
    TIME_FORMAT(open, '%h:%i:%p') IS NOT NULL
    AND TIME_FORMAT(close, '%h:%i:%p') IS NOT NULL
);
 

9) Fetch the top 10 most famous painting subject
 # My logic was wrong about sale price it was about total count not price
select distinct subject,count(*) as total
from subject s
join work w on s.work_id=w.work_id
 group by subject 
 order by total desc
 limit 10
 
10. Identify the museums which are open on both Sunday and Monday. 
Display museum name, city.

SELECT m.name, m.city
FROM museum m
WHERE m.museum_id IN (
    SELECT h1.museum_id
    FROM museum_hours h1
    WHERE h1.day = 'Sunday'
    INTERSECT
    SELECT h2.museum_id
    FROM museum_hours h2
    WHERE h2.day = 'Monday'
);

11) How many museums are open every single day? 
select count(*) from
(SELECT museum_id,COUNT(museum_id)
FROM museum_hours
GROUP BY museum_id
HAVING COUNT(day) =7) a

12)Which are the top 5 most popular museum? (Popularity is defined based on most
no of paintings in a museum)

SELECT w.museum_id,m.name,count(work_id) as total_work
FROM work w
join museum m on w.museum_id=m.museum_id
group by w.museum_id,m.name
order by total_work desc
limit 5


13. Who are the top 5 most popular artist? (Popularity is defined based on most no of
paintings done by an artist)

SELECT w.artist_id,
		a.full_name,count(work_id) as total_work
FROM paintings.work w
join artist a on w.artist_id=a.artist_id
group by w.artist_id,a.full_name 
order by total_work desc
limit 5

14. Display the 3 least popular canva sizes
SELECT p.size_id,
		c.label,
		count(work_id) as total_work
FROM product_size p
join canvas_size c on p.size_id=c.size_id
group by p.size_id,c.label
order by total_work asc


15) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
SELECT m.name,m.state,
		h.museum_id,
        day,  
        TIMEDIFF(
           STR_TO_DATE(close, '%h:%i:%p'),
           STR_TO_DATE(open, '%h:%i:%p')
       ) AS duration
FROM museum_hours h 
join museum m on h.museum_id=m.museum_id
order by duration desc


16. Which museum has the most no of most popular painting style?
SELECT m.name,
		style,
		count(*) as total
FROM work w
join museum m on m.museum_id=w.museum_id
group by m.name,style
order by total desc


17.  Identify the artists whose paintings are displayed in multiple countries
SELECT a.full_name,count(distinct m.country) as total
 FROM museum m
 join work w on m.museum_id=w.museum_id
 join artist a on w.artist_id=a.artist_id
 group by a.full_name
 order by total desc
 
 
 18. Display the country and the city with most no of museums. Output 2 seperate
columns to mention the city and country. If there are multiple value, seperate them
with comma
WITH cte_country AS (
    SELECT country, COUNT(*) AS country_count,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM museum
    GROUP BY country
),
cte_city AS (
    SELECT city, COUNT(*) AS city_count,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM museum
    GROUP BY city
)
SELECT
    GROUP_CONCAT(DISTINCT country.country SEPARATOR ', ') AS top_countries,
    GROUP_CONCAT(DISTINCT city.city SEPARATOR ', ') AS top_cities
FROM cte_country country
CROSS JOIN cte_city city
WHERE country.rnk = 1
  AND city.rnk = 1;
  
  
  
19. Identify the artist and the museum where the most expensive and least expensive
painting is placed. Display the artist name, sale_price, painting name, museum
name, museum city and canvas label

WITH cte AS (
    SELECT *,
           RANK() OVER (ORDER BY sale_price DESC) AS rnk,
           RANK() OVER (ORDER BY sale_price) AS rnk_asc
    FROM product_size
)
SELECT
    w.name AS painting,
    cte.sale_price,
    a.full_name AS artist,
    m.name AS museum,
    m.city,
    cz.label AS canvas
FROM
    cte
JOIN
    work w ON w.work_id = cte.work_id
JOIN
    museum m ON m.museum_id = w.museum_id
JOIN
    artist a ON a.artist_id = w.artist_id
JOIN
    canvas_size cz ON cz.size_id = CAST(cte.size_id AS SIGNED)
WHERE
    rnk = 1 OR rnk_asc = 1;


20. Which country has the 5th highest no of paintings?
SELECT country, COUNT(work_id) AS total_work
FROM work w
JOIN museum m ON m.museum_id = w.museum_id
GROUP BY country
ORDER BY total_work DESC
LIMIT 1 OFFSET 4;

21. Which are the 3 most popular and 3 least popular painting styles?
WITH StyleCounts AS (
    SELECT style, COUNT(work_id) AS work_count
    FROM work
    GROUP BY style
)
SELECT style, work_count
FROM (
    (SELECT style, work_count
    FROM StyleCounts
    ORDER BY work_count DESC
    LIMIT 3)

    UNION ALL

    (SELECT style, work_count
    FROM StyleCounts
    ORDER BY work_count ASC
    LIMIT 3)
) AS Subquery;


22. Which artist has the most no of Portraits paintings outside USA?. Display artist
name, no of paintings and the artist nationality.
select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	

