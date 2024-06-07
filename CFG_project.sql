CREATE DATABASE IF NOT EXISTS joins_languages;
USE joins_languages;

-- Drop existing tables if they exist to avoid conflicts during creation
DROP TABLE IF EXISTS video, channel, brand, category, language, YouTubeCSV, first_languages, second_languages;

-- Create table for languages
CREATE TABLE language (
    language_id INT AUTO_INCREMENT PRIMARY KEY,
    language_name VARCHAR(255) NOT NULL
);

-- Create table for categories
CREATE TABLE category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL
);

-- Create table for brands
CREATE TABLE brand (
    brand_id INT AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(255) NOT NULL
);

-- Create table for channels
CREATE TABLE channel (
    channel_id INT AUTO_INCREMENT PRIMARY KEY,
    brand_id INT,
    category_id INT,
    totalviews BIGINT,
    FOREIGN KEY (brand_id) REFERENCES brand(brand_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

-- Create table for videos
CREATE TABLE video (
    video_id INT AUTO_INCREMENT PRIMARY KEY,
    channel_id INT,
    title VARCHAR(255),
    views BIGINT,
    FOREIGN KEY (channel_id) REFERENCES channel(channel_id)
);

-- Temporary table to import CSV data
CREATE TABLE YouTubeCSV (
    Name VARCHAR(255),
    Brand_channel VARCHAR(255),
    Subscribers_millions DECIMAL(10, 2),
    Primary_language VARCHAR(100),
    Category VARCHAR(100),
    Country VARCHAR(100),
    PRIMARY KEY (Name)
);

-- Load data from a CSV file into the YouTubeCSV table
LOAD DATA LOCAL INFILE '/Users/marikabertelli/Desktop/Online courses/Code First Girls/Intro to Data & SQL/final project/Most Subscribed YouTube Channels_exported.csv' 
INTO TABLE YouTubeCSV
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Name, Brand_channel, Subscribers_millions, Primary_language, Category, Country);

-- Insert unique languages into the language table
INSERT INTO language (language_name)
SELECT DISTINCT Primary_language FROM YouTubeCSV;

-- Insert unique categories into the category table
INSERT INTO category (category_name)
SELECT DISTINCT Category FROM YouTubeCSV;

-- Insert unique brands into the brand table
INSERT INTO brand (brand_name)
SELECT DISTINCT Brand_channel FROM YouTubeCSV;

-- Populate the channel table with data from YouTubeCSV
INSERT INTO channel (brand_id, category_id, totalviews)
SELECT b.brand_id, c.category_id, SUM(y.Subscribers_millions * 1000000) AS totalviews
FROM YouTubeCSV y
JOIN brand b ON y.Brand_channel = b.brand_name
JOIN category c ON y.Category = c.category_name
GROUP BY b.brand_id, c.category_id;

-- Insert data into the video table
INSERT INTO video (channel_id, title, views)
SELECT c.channel_id, CONCAT('Video for Channel ID ', c.channel_id), c.totalviews
FROM channel c;

-- Using any type of joins create a view that combines multiple tables in a logical way
CREATE OR REPLACE VIEW video_info AS
SELECT v.video_id, v.title, v.views, c.channel_id, b.brand_id, b.brand_name
FROM video v
INNER JOIN channel c ON v.channel_id = c.channel_id
INNER JOIN brand b ON c.brand_id = b.brand_id;

-- Query with a subquery to demonstrate how to extract data from your DB for analysis
SELECT brand_name, total_views
FROM (
    SELECT b.brand_name, SUM(v.views) AS total_views
    FROM video v
    JOIN channel c ON v.channel_id = c.channel_id
    JOIN brand b ON c.brand_id = b.brand_id
    GROUP BY b.brand_name
) AS brand_views
ORDER BY total_views DESC
LIMIT 5;

-- Create a view that uses at least 3-4 base tables; prepare and demonstrate a query that uses the view to produce a logically arranged result set for analysis
CREATE OR REPLACE VIEW channel_details AS
SELECT c.channel_id, b.brand_name, cat.category_name, c.totalviews, l.language_name
FROM channel c
JOIN brand b ON c.brand_id = b.brand_id
JOIN category cat ON c.category_id = cat.category_id
JOIN language l ON l.language_name = (
    SELECT language_name FROM language WHERE language_name = (SELECT Primary_language FROM YouTubeCSV WHERE Brand_channel = b.brand_name AND Category = cat.category_name LIMIT 1)
);

-- Query to get the top 3 channels with the highest views for a specific language
SELECT brand_name, category_name, totalviews
FROM channel_details
WHERE language_name = 'English'
ORDER BY totalviews DESC
LIMIT 3;

-- Prepare an example query with group by and having to demonstrate how to extract data from your DB for analysis
SELECT category_name, COUNT(*) AS channel_count
FROM channel_details
GROUP BY category_name
HAVING channel_count > 2
ORDER BY channel_count DESC;

-- Check if the function exists and drop it before recreating
DROP FUNCTION IF EXISTS calculateTotalViewsForBrand;

-- Function to calculate total views for a brand
DELIMITER //
CREATE FUNCTION calculateTotalViewsForBrand(brandName VARCHAR(255)) RETURNS BIGINT
DETERMINISTIC
BEGIN
    DECLARE totalViews BIGINT DEFAULT 0;
    SELECT SUM(v.views) INTO totalViews
    FROM video v
    JOIN channel c ON v.channel_id = c.channel_id
    JOIN brand b ON c.brand_id = b.brand_id
    WHERE b.brand_name = brandName;
    RETURN totalViews;
END //
DELIMITER ;

-- Prepare an example query with group by and having to demonstrate how to extract data from your DB for analysis
SELECT category_name, COUNT(*) AS channel_count
FROM channel_details
GROUP BY category_name
HAVING channel_count > 2
ORDER BY channel_count DESC;


USE joins_languages;

-- Create table for primary languages
CREATE TABLE IF NOT EXISTS first_languages (
    id INT,
    languages VARCHAR(255),
    PRIMARY KEY (id)
);

-- Insert data into first_languages
INSERT INTO first_languages (id, languages)
VALUES
(1, 'english'),
(2, 'spanish'),
(3, 'hindi'),
(4, 'korean'),
(5, 'portuguese');

-- Create table for secondary languages if not exists
CREATE TABLE IF NOT EXISTS second_languages (
    id INT,
    languages VARCHAR(255),
    PRIMARY KEY (id)
);

-- Insert data into second_languages
INSERT INTO second_languages (id, languages)
VALUES
(1, 'english'),
(2, 'spanish'),
(3, 'hindi'),
(6, 'korean'),
(7, 'portuguese'),
(8, 'russian');

-- Display all records from first_languages
SELECT * FROM first_languages;

-- Display all records from second_languages
SELECT * FROM second_languages;

-- INNER JOIN
SELECT t1.*, t2.*
FROM first_languages AS t1
JOIN second_languages AS t2
ON t1.id = t2.id;

-- LEFT JOIN
SELECT t1.*, t2.*
FROM first_languages AS t1
LEFT JOIN second_languages AS t2
ON t1.id = t2.id;

-- RIGHT JOIN
SELECT t1.*, t2.*
FROM first_languages AS t1
RIGHT JOIN second_languages AS t2
ON t1.id = t2.id;

-- Combine LEFT JOIN and RIGHT JOIN using UNION 
SELECT * FROM first_languages AS t1
LEFT JOIN second_languages AS t2
ON t1.id = t2.id
UNION
SELECT * FROM first_languages AS t1
RIGHT JOIN second_languages AS t2
ON t1.id = t2.id;

-- Example query to demonstrate extraction using GROUP BY and HAVING
SELECT category_name, COUNT(*) AS channel_count
FROM channel_details
GROUP BY category_name
HAVING channel_count > 2
ORDER BY channel_count DESC;
