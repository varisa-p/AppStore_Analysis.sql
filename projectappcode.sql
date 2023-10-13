-- Identify missing values
SELECT 
  COUNT(*) AS Missing_value 
FROM 
  AppleStore 
WHERE 
  track_name IS NULL 
  OR user_rating IS NULL 
  OR prime_genre IS NULL;
SELECT 
  COUNT(*) AS Missing_value 
FROM 
  appleStore_description 
WHERE 
  track_name IS NULL 
  OR size_bytes IS NULL 
  OR app_desc IS NULL;
-- Count the number of apps with missing user ratings (where user rating = 0, indicating no reviews).
SELECT 
  COUNT(*) AS Missing_value 
FROM 
  AppleStore 
WHERE 
  user_rating = 0;
-- Count the number of apps with missing or undefined size (where size_bytes = 0)
SELECT 
  COUNT(*) AS Missing_value 
FROM 
  AppleStore 
WHERE 
  size_bytes = 0;
-- Create a new table with valid user ratings for analysis
CREATE TABLE AppleStore_ValidRatings AS 
SELECT 
  * 
FROM 
  AppleStore 
WHERE 
  user_rating > 0;
-- Transform unit of app size and add as new column
ALTER TABLE AppleStore_ValidRatings
ADD size_mb AS ROUND((size_bytes / (1024.0 * 1024.0)),0);
-- Find the number of apps
SELECT 
  COUNT(DISTINCT id) AS Appid_num 
FROM 
  AppleStore_ValidRatings;
SELECT 
  COUNT(DISTINCT id) AS Appid_num 
FROM 
  appleStore_description;
-- Find the number of apps per genre
SELECT 
  prime_genre, 
  COUNT(id) AS Num_app 
FROM 
  AppleStore_ValidRatings 
GROUP BY 
  prime_genre 
ORDER BY 
  Num_app DESC;
-- Overall rating
SELECT 
  MIN(user_rating) AS Min_rate, 
  MAX(user_rating) AS Max_rate, 
  AVG(user_rating) AS Avg_rate 
FROM 
  AppleStore_ValidRatings;
-- Identify rating for each genre
SELECT 
  prime_genre, 
  AVG(user_rating) AS Avg_rate 
FROM 
  AppleStore_ValidRatings 
GROUP BY 
  prime_genre;
-- Overall price
SELECT 
  MIN(price) AS Min_price, 
  MAX(price) AS Max_price, 
  ROUND(AVG(price), 2) AS Avg_price 
FROM 
  AppleStore_ValidRatings 
WHERE 
  price > 0;
-- Overall language support
SELECT 
  MIN(lang_num) AS Min_lang, 
  MAX(lang_num) AS Max_lang, 
  AVG(lang_num) AS Avg_lang 
FROM 
  AppleStore_ValidRatings;
-- Overall size_bytes
SELECT 
  MIN(size_mb) AS Min_size, 
  MAX(size_mb) AS Max_size, 
  AVG(size_mb) AS Avg_size, 
FROM 
  AppleStore_ValidRatings;
-- Overall length of description
SELECT 
  MIN(LEN(app_desc)) AS min_letters, 
  MAX(LEN(app_desc)) AS max_letters, 
  AVG(LEN(app_desc)) AS avg_letters 
FROM 
  AppleStore_ValidRatings AS a 
  LEFT JOIN AppleStore_description AS b ON a.id = b.id;
-- Analyze insights
-- User rate based on app type
WITH CTE AS (
  SELECT 
    CASE WHEN price > 0 THEN 'Paid' 
         ELSE 'FREE' END AS App_type, 
    user_rating
  FROM 
    AppleStore_ValidRatings
) -- create CTE to define categories
SELECT 
  App_type, 
  AVG(user_rating) AS avg_rating 
FROM 
  CTE
GROUP BY 
  App_type;

-- User rate based on price
WITH CTE AS (
  SELECT 
    CASE WHEN price = 0 THEN 'Free' 
         WHEN price BETWEEN 0.01 AND 1.99 THEN 'Low price' 
         WHEN price BETWEEN 2.00 AND 3.99 THEN 'Medium price' 
         ELSE 'High price' END AS price_category, 
    user_rating
  FROM 
    AppleStore_ValidRatings 
)
SELECT 
  price_category, 
  COUNT(*) AS app_count, 
  AVG(user_rating) AS average_rating 
FROM 
  CTE
GROUP BY 
  price_category
ORDER BY 
  average_rating DESC;
-- User rate based on size_bytes
WITH CTE AS (
  SELECT 
    CASE WHEN size_bytes <= 200000000 THEN 'Average' ELSE 'Large' END AS size_category, 
    user_rating
  FROM 
    AppleStore_ValidRatings 
)
SELECT 
  size_category, 
  COUNT(*) AS app_count, 
  AVG(user_rating) AS average_rating 
FROM 
  CTE
GROUP BY 
  size_category 
ORDER BY 
  average_rating DESC;

-- Identify low-rated review genres
SELECT TOP(10)
  prime_genre, 
  COUNT(*) AS app_count, 
  AVG(user_rating) AS avg_rating 
FROM 
  AppleStore_ValidRatings 
GROUP BY 
  prime_genre 
ORDER BY 
  avg_rating ASC;
-- Rating based on language support
WITH CategorizedApps AS (
  SELECT 
    CASE WHEN lang_num = 0 THEN 'Default_lang'
         WHEN lang_num <= 5 THEN '1-5'
         WHEN lang_num <= 10 THEN '6-10'
         WHEN lang_num <= 15 THEN '11-15'
         WHEN lang_num <= 20 THEN '16-20'
         ELSE '20+' END AS Num_lang_support, 
    user_rating 
  FROM 
    AppleStore_ValidRatings
)
SELECT 
  Num_lang_support, 
  COUNT(*) AS app_count, 
  AVG(user_rating) AS average_rating 
FROM 
  CategorizedApps 
GROUP BY 
  Num_lang_support 
ORDER BY 
  average_rating DESC;
-- Rating based on length of description
WITH DescriptionLength AS (
  SELECT 
    a.user_rating,
    CASE WHEN LEN(b.app_desc) < 500 THEN 'Short'
         WHEN LEN(b.app_desc) BETWEEN 500 AND 1500 THEN 'Medium'
         ELSE 'Long' END AS description_length_group
  FROM 
    AppleStore_ValidRatings AS a 
    LEFT JOIN AppleStore_description AS b ON a.id = b.id 
)
SELECT 
  description_length_group, 
  COUNT(*) AS app_count, 
  AVG(user_rating) AS average_rating 
FROM 
  DescriptionLength 
GROUP BY 
  description_length_group;
-- Top-rated app in each genre
SELECT 
  prime_genre, 
  track_name, 
  user_rating, 
  prime_genre, 
  size_bytes, 
  lang_num 
FROM 
  (
    SELECT 
      prime_genre, 
      track_name, 
      user_rating, 
      size_bytes, 
      lang_num, 
      RANK() OVER(
        PARTITION BY prime_genre 
        ORDER BY 
          user_rating DESC, 
          rating_count_tot DESC
      ) AS rank 
    FROM 
      AppleStore_ValidRatings
  ) AS a 
WHERE 
  a.rank = 1;

