--- 1. SKAPA DATABAS OCH TABELLER ___

--Skapa databasen library_db
CREATE DATABASE  library_db;

-- Styr till rätt active db på local_host (terminalen)
use library_db;

--Skapa alla tabeller i library_db
CREATE TABLE authors(
author_id INT PRIMARY KEY AUTO_INCREMENT,
first_name VARCHAR(50),
last_name VARCHAR(50),
birth_year INT
);

CREATE TABLE publishers(
publisher_id INT PRIMARY KEY AUTO_INCREMENT, 
`name` VARCHAR(100),
location VARCHAR(100)
);

-- Skapar denna tabell efter ovanstående - annars fel i references vid exec
CREATE TABLE books(
book_id INT PRIMARY KEY AUTO_INCREMENT,
title VARCHAR(100),
publication_year INT,
author_id INT,
publisher_id INT,
FOREIGN KEY (author_id) REFERENCES authors(author_id),
FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id)
);

CREATE TABLE genres(
genre_id INT PRIMARY KEY AUTO_INCREMENT,
genre_name VARCHAR(50)
);

CREATE TABLE book_genre(
book_id INT,
genre_id INT,
FOREIGN KEY (book_id) REFERENCES books(book_id),
FOREIGN KEY (genre_id) REFERENCES genres(genre_id),
PRIMARY KEY (book_id, genre_id)
);


--- 2. FYLLA MED DATA ___
--Ladda library_db specifika kolumner med värden (Primary key är auto_increment och utelämnas)
INSERT INTO publishers (name, location) VALUES ('Penguin Books', 'New York');
--en till
INSERT INTO publishers  (name, location) VALUES ('Vintage Books', 'San Francisco');
--eller 
INSERT INTO library_db.publishers (name, location) VALUES ('HarperCollins', 'London');

-- Kolla att det funkade
SELECT * FROM publishers;


-- Sedan likadant med authors, genres books och kopplingstabellen book_genre
-- BLOD
-- SVETT
-- LITE MER SVETT
-- TÅRAR
-- KLART !!! ---

-- Se i SLASK nedan !

--- 3. SQL-ANROP -----

-- Hämta alla böcker som publicerats före år 1950.
SELECT * FROM books WHERE publication_year <= '1950'

-- Hämta alla genrer som innehåller ordet "Classic".
SELECT genre_name FROM genres WHERE genre_name LIKE '%Classic%'; 
-- No data
SELECT genre_name FROM genres WHERE genre_name LIKE '%Fiction%'; 
--Ger 2 db-poster

-- Hämta alla böcker av en specifik författare, t.ex. "George Orwell".
SELECT books.title, authors.first_name, authors.last_name
FROM books
INNER JOIN authors ON books.author_id = authors.author_id
WHERE authors.last_name="Orwell";

-- eller mer exakt
SELECT books.title, authors.first_name, authors.last_name
FROM books
INNER JOIN authors ON books.author_id = authors.author_id
WHERE authors.first_name = 'George' AND authors.last_name = 'Orwell';

-- Hämta alla böcker som publicerats av ett specifikt förlag och ordna dem efter publiceringsår.
-- Jag slumpade ut alla böcker till olika förlag...
SELECT books.title, books.publication_year, publishers.`name`
FROM books
INNER JOIN publishers ON books.publisher_id = authors.author
WHERE publishers.`name` = 'HarperCollins'
ORDER BY books.publication_year;

-- Hämta alla böcker tillsammans med deras författare och publiceringsår.
SELECT b.title, b.publication_year, CONCAT(authors.first_name, ' ', authors.last_name)
FROM books b
INNER JOIN authors ON b.author_id = authors.author_id
ORDER BY b.publication_year;

-- Hämta alla böcker som publicerats efter det senaste publiceringsåret av böcker som kom ut före år 2000.
SELECT title, publication_year
FROM books
WHERE publication_year > (SELECT MAX(publication_year) FROM books WHERE publication_year < '2000');

-- för koll
SELECT * FROM books ORDER BY publication_year;
SELECT MAX(publication_year) FROM books WHERE publication_year < '2000';

-- UPPDATERAD FRÅGA
-- Hämta alla böcker som publicerades efter den första boken som kom ut efter år 2000. (Funkar med eller utan fnutt på året INT)
SELECT * FROM books
WHERE publication_year > (SELECT MIN(publication_year) FROM books WHERE publication_year > 2000);


-- Uppdatera författarens namn i tabellen.
-- Kolla först deras namn
SELECT * FROM authors;
-- Så varför inte ändra nummer 11 från George R.R. till George R^2
UPDATE authors SET first_name ='George R^2' WHERE author_id = "11";

-- Ta bort en bok från databasen.
-- Lägger till en först
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('Jag lär mig läsa', '2027', '12', '3');

-- kollar att den är där
SELECT * FROM books;

-- Tar sedan bort den
DELETE FROM books WHERE title = 'Jag lär mig läsa';
-- kollar igen - borta  :)


--- 4. ER-DIAGRAM -----
-- Se pdf-fil

-- VG MODE --

-- Hämta alla böcker som publicerats efter år 2000 tillsammans med författarens namn, förlagets namn och genrerna.
SELECT books.title, books.publication_year, 
       CONCAT(authors.first_name, ' ', authors.last_name) AS author_name, 
       publishers.`name`, 
       genres.genre_name
FROM books
INNER JOIN authors ON books.author_id = authors.author_id
INNER JOIN publishers ON books.publisher_id = publishers.publisher_id
INNER JOIN book_genre ON books.book_id = book_genre.book_id
INNER JOIN genres ON book_genre.genre_id = genres.genre_id
WHERE books.publication_year > 2000
ORDER BY books.publication_year,genre_name;

-- Visa författarnas fullständiga namn (förnamn och efternamn), titlarna på deras böcker och vilken genre böckerna tillhör.
SELECT CONCAT(authors.first_name, ' ', authors.last_name) AS author_name, 
	   books.title, 
       genres.genre_name
FROM books
INNER JOIN authors ON books.author_id = authors.author_id
INNER JOIN book_genre ON books.book_id = book_genre.book_id
INNER JOIN genres ON book_genre.genre_id = genres.genre_id
ORDER BY authors.last_name, books.title;

-- Antalet böcker varje författare har skrivit, sorterat i fallande ordning.
-- Kommentar Group by lägger det per författare så att count blir rätt per författare
SELECT CONCAT(authors.first_name, ' ', authors.last_name) AS author_name, 
       COUNT(books.book_id) AS antal_books
FROM authors
INNER JOIN books ON authors.author_id = books.author_id
GROUP BY authors.author_id
ORDER BY antal_books DESC, authors.last_name;

-- Antalet böcker inom varje genre.
-- Sorterar i fallande ordning, sedan i bokstavsordning
SELECT COUNT(books.book_id) AS antal_books,
	   genres.genre_name AS genre
FROM genres
INNER JOIN book_genre ON genres.genre_id = book_genre.genre_id
INNER JOIN books ON book_genre.book_id = books.book_id
GROUP BY genres.genre_id
ORDER BY antal_books DESC, genre;

-- Genomsnittligt antal böcker per författare som är publicerade efter år 2000.
-- Nu sub-query i select-delen. Tar det i steg "innifrån å ut" - först count på group by, sedan average på det.
SELECT AVG(book_count) AS average_books_per_author
FROM (
    SELECT COUNT(books.book_id) AS book_count
    FROM authors
    INNER JOIN books ON authors.author_id = books.author_id
    WHERE books.publication_year > 2000
    GROUP BY authors.author_id
) AS author_book_counts;

-- Skapa en stored procedure som tar ett årtal som parameter och returnerar alla böcker som publicerats efter detta år. Döp den till get_books_after_year.
DELIMITER //

CREATE PROCEDURE get_books_after_year(
    IN Aar INT
)
BEGIN
    SELECT *
    FROM books
    WHERE publication_year > Aar;
END //

DELIMITER ;

-- Kör
CALL get_books_after_year(2000);

-- Skapa en view som visar varje författares fullständiga namn, bokens titel och publiceringsår. 
-- Döp den till author_books.
CREATE VIEW author_books AS
SELECT CONCAT(authors.first_name, ' ', authors.last_name) AS full_name, 
       books.title, 
       books.publication_year
FROM authors
INNER JOIN books ON authors.author_id = books.author_id
ORDER BY publication_year;

-- Kör sedan 
SELECT * FROM author_books;

-- Testar sedan (överkurs) en "mer avancerad" SQL på denna view...
SELECT title FROM author_books WHERE title LIKE '%The%';

-- SLUT -- SLUT -- SLUT -- SLUT --

--- SLASK ---
--authors (12)
INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('J.K.', 'Rowlings', '1965');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('George', 'Orwell', '1903');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('J.R.R.', 'Tolkien', '1892');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('Mark', 'Twain', '1835');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('Isaac', 'Asimov', '1920');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('Arthur', 'Conan Doyle', '1859');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('Agatha', 'Christie', '1890');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('Philip K.', 'Dick', '1928');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('Stephen', 'King', '1947');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('Suzanne', 'Collins', '1962');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('George R.R.', 'Martin', '1948');

INSERT INTO authors (first_name, last_name, birth_year) 
VALUES ('Harlan', 'Coben', '1962');

--genres (7)
INSERT INTO genres (genre_name) 
VALUES ('Fantasy');

INSERT INTO genres (genre_name) 
VALUES ('Adventure');

INSERT INTO genres (genre_name) 
VALUES ('Detective Fiction');

INSERT INTO genres (genre_name) 
VALUES ('Horror');

INSERT INTO genres (genre_name) 
VALUES ('Dystopian');

INSERT INTO genres (genre_name) 
VALUES ('Science Fiction');

INSERT INTO genres (genre_name) 
VALUES ('Thriller');




--books (13)
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('Harry Potter and the Philosophers Stone', '1997', '1', '1');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('1984', '1949', '2', '2');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('The Hobbit', '1937', '3', '3');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('The Adventures of Tom Sawyer', '1876', '4', '1');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('Foundation', '1951', '5', '2');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('The Hound of the Baskervilles', '1902', '6', '3');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('Murder on the Orient Express', '1934', '7', '1');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('Do Androids Dream of Electric Sheep?', '1968', '8', '2');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('The Shining', '1977', '9', '3');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('The Hunger Games', '2008', '10', '1');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('A Game of Thrones', '1996', '11', '2');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('The Stranger', '2015', '12', '3');
INSERT INTO books (title, publication_year, author_id, publisher_id) 
VALUES ('The Woods', '2007', '12', '3');

--Fixat till genom att slumpa publisher/dess_id i sista kolumnen i stället för genre
"Harry Potter and the Philosophers Stone" (1997) - J.K. Rowling - Penguin Books
"1984" (1949) - George Orwell - HarperCollins
"The Hobbit" (1937) - J.R.R. Tolkien - Vintage Books
"The Adventures of Tom Sawyer" (1876) - Mark Twain - Penguin Books
"Foundation" (1951) - Isaac Asimov - HarperCollins
"The Hound of the Baskervilles" (1902) - Arthur Conan Doyle - Vintage Books
"Murder on the Orient Express" (1934) - Agatha Christie - Penguin Books
"Do Androids Dream of Electric Sheep?" (1968) - Philip K. Dick - HarperCollins
"The Shining" (1977) - Stephen King - Vintage Books
"The Hunger Games" (2008) - Suzanne Collins - Penguin Books
"A Game of Thrones" (1996) - George R.R. Martin - HarperCollins
"The Stranger" (2015) - Harlan Coben - Vintage Books
"The Woods" (2007) - Harlan Coben - Vintage Books

-- publishers
-- 1 Penguin Books (New York)
-- 2 HarperCollins (London)
-- 3 Vintage Books (San Francisco)

Original instruktionsfil... genre sista kolumnen, ej publisher
"Harry Potter and the Philosophers Stone" (1997) - J.K. Rowling - Fantasy
"1984" (1949) - George Orwell - Detective Fiction
"The Hobbit" (1937) - J.R.R. Tolkien - Fantasy
"The Adventures of Tom Sawyer" (1876) - Mark Twain - Adventure
"Foundation" (1951) - Isaac Asimov - Science Fiction
"The Hound of the Baskervilles" (1902) - Arthur Conan Doyle - Detective Fiction
"Murder on the Orient Express" (1934) - Agatha Christie - Detective Fiction
"Do Androids Dream of Electric Sheep?" (1968) - Philip K. Dick - Science Fiction
"The Shining" (1977) - Stephen King - Horror/Fantasy
"The Hunger Games" (2008) - Suzanne Collins - Adventure/Dystopian
"A Game of Thrones" (1996) - George R.R. Martin - Fantasy
"The Stranger" (2015) - Harlan Coben - Detective Fiction/Thriller
"The Woods" (2007) - Harlan Coben - Mystery/Thriller

-- publishers
Penguin Books (New York)
HarperCollins (London)
Vintage Books (San Francisco)

Fantasy
Adventure
Detective Fiction
Horror
Dystopian
Science Fiction
Thriller
-- 8 Mystery (extra)

-- kopplingstabellen book_genre (13)
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('1', '1');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('2', '3');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('3', '1');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('4', '2');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('5', '6');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('6', '3');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('7', '3');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('8', '6');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('11', '1');
-- nedan har flera genres 
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('9', '4');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('9', '1');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('10', '2');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('10', '5');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('12', '3');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('12', '7');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('13', '8');
INSERT INTO book_genre (book_id, genre_id) 
VALUES ('13', '7');

"Harry Potter and the Philosopher's Stone" → Fantasy
"1984" → Detective Fiction
"The Hobbit" → Fantasy
"The Adventures of Tom Sawyer" → Adventure
"Foundation" → Science Fiction
"The Hound of the Baskervilles" → Detective Fiction
"Murder on the Orient Express" → Detective Fiction
"Do Androids Dream of Electric Sheep?" → Science Fiction
"The Shining" → Horror/Fantasy
"The Hunger Games" → Adventure/Dystopian
"A Game of Thrones" → Fantasy
"The Stranger" → Detective Fiction/Thriller
"The Woods" → Mystery/Thriller


