USE iths;

-- ------------------------------------------------------UNF-------------------------------------------------------

DROP TABLE IF EXISTS UNF;

CREATE TABLE UNF (
	Id DECIMAL(38, 0) NOT NULL,
	Name VARCHAR(26) NOT NULL,
	Grade VARCHAR(11) NOT NULL,
	Hobbies VARCHAR(25),
	City VARCHAR(10) NOT NULL,
	School VARCHAR(30) NOT NULL,
	HomePhone VARCHAR(15),
	JobPhone VARCHAR(15),
	MobilePhone1 VARCHAR(15),
	MobilePhone2 VARCHAR(15)
) ENGINE=INNODB;

LOAD DATA INFILE '/var/lib/mysql-files/denormalized-data.csv'
INTO TABLE UNF
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ----------------------------------------------------Student-----------------------------------------------------

DROP TABLE IF EXISTS Student;

CREATE TABLE Student (
	Id INT NOT NULL AUTO_INCREMENT,
	FirstName VARCHAR(26) NOT NULL,
	LastName VARCHAR(26) NOT NULL,
	PRIMARY KEY (Id)
) ENGINE=INNODB;


INSERT INTO Student (Id, FirstName, LastName) 
SELECT DISTINCT Id, SUBSTRING_INDEX(Name, ' ', 1) AS FirstName, SUBSTRING_INDEX(Name, ' ', -1) AS LastName
FROM UNF;

-- -----------------------------------------------------Phone------------------------------------------------------

DROP TABLE IF EXISTS Phone;
CREATE TABLE Phone (
    PhoneId INT NOT NULL AUTO_INCREMENT,
    StudentId INT NOT NULL,
    Type VARCHAR(32),
    Number VARCHAR(32) NOT NULL,
    PRIMARY KEY(PhoneId)
);

INSERT INTO Phone(StudentId, Type, Number) 
SELECT ID As StudentId, "Home" AS Type, HomePhone as Number FROM UNF
WHERE HomePhone IS NOT NULL AND HomePhone != ''
UNION SELECT ID As StudentId, "Job" AS Type, JobPhone as Number FROM UNF
WHERE JobPhone IS NOT NULL AND JobPhone != ''
UNION SELECT ID As StudentId, "Mobile" AS Type, MobilePhone1 as Number FROM UNF
WHERE MobilePhone1 IS NOT NULL AND MobilePhone1 != ''
UNION SELECT ID As StudentId, "Mobile" AS Type, MobilePhone2 as Number FROM UNF
WHERE MobilePhone2 IS NOT NULL AND MobilePhone2 != '';

-- -----------------------------------------------------School-----------------------------------------------------

DROP TABLE IF EXISTS School;

CREATE TABLE School (
	Id INT NOT NULL AUTO_INCREMENT,
	Name VARCHAR(32) NOT NULL,
	City VARCHAR(32) NOT NULL,
	PRIMARY KEY (Id)
);

INSERT INTO School(Name, City)
SELECT DISTINCT School AS Name, City AS City FROM UNF;

-- -------------------------------------------StudentSchool-kopplingstabell----------------------------------------

DROP TABLE IF EXISTS StudentSchool;

CREATE TABLE StudentSchool (
	StudentId INT NOT NULL,
	SchoolId INT NOT NULL,
	PRIMARY KEY(StudentId, SchoolId)
);

INSERT INTO StudentSchool(StudentId, SchoolId)
SELECT DISTINCT UNF.Id AS StudentId, School.Id AS SchoolId
FROM UNF INNER JOIN School ON UNF.School =School.Name;

-- --------------------------------------------------UniqueHobbies-------------------------------------------------

DROP TABLE IF EXISTS Hobbies;

CREATE TABLE Hobbies (
	Id INT NOT NULL AUTO_INCREMENT,
	Hobby VARCHAR(100),
	PRIMARY KEY(Id)
);

DROP PROCEDURE IF EXISTS extract_unique_hobbies;
DROP TABLE IF EXISTS temp_Hobbies;

DELIMITER //

CREATE procedure extract_unique_hobbies()

BEGIN
  SET @max_hobbies := ((SELECT max(length(Hobbies) - length(replace(Hobbies, ',', ''))) AS Max FROM UNF) + 1);
  SET @x := 1;

  CREATE TABLE temp_Hobbies (
  	Id INT NOT NULL AUTO_INCREMENT,
  	Hobby VARCHAR(100),
  	PRIMARY KEY(Id)
  	);

  WHILE @x <= @max_hobbies DO
    
	INSERT INTO temp_Hobbies(Hobby) SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(Hobbies, ',', @x), ',', -1) AS temp_Hobby FROM UNF ;

    SET @x = @x + 1;
  END WHILE;

INSERT INTO Hobbies(Hobby)
SELECT DISTINCT trim(Hobby) FROM temp_Hobbies WHERE length(Hobby) > 0;
DROP TABLE temp_Hobbies;
END//

DELIMITER ;

CALL extract_unique_hobbies();

-- --------------------------------------------------HobbiesStudents-------------------------------------------------

DROP TABLE IF EXISTS HobbiesStudents;

CREATE TABLE HobbiesStudents (
	Hobby VARCHAR(100),
	StudentId INT NOT NULL
);


DROP PROCEDURE IF EXISTS table_hobbiesstudent;
DROP TABLE IF EXISTS temp_Hobbies;

DELIMITER //

CREATE procedure table_hobbiesstudent()


BEGIN
  SET @max_hobbies := ((SELECT max(length(Hobbies) - length(replace(Hobbies, ',', ''))) AS Max FROM UNF) + 1);
  SET @x := 1;

  CREATE TABLE temp_Hobbies (
  	Hobby VARCHAR(100),
  	StudentId INT NOT NULL
  	);

  WHILE @x <= @max_hobbies DO
    

	INSERT INTO temp_Hobbies(Hobby, StudentId) 
	SELECT DISTINCT trim(SUBSTRING_INDEX(SUBSTRING_INDEX(Hobbies, ',', @x), ',', -1)) AS temp_Hobby, Id AS StudentId 
	FROM UNF;


    SET @x = @x + 1;
  END WHILE;


INSERT INTO HobbiesStudents
SELECT DISTINCT * 
FROM temp_Hobbies 
WHERE length(Hobby) > 0;
DROP TABLE temp_Hobbies;
END//

DELIMITER ;

CALL table_hobbiesstudent();

-- ------------------------------------------StudentHobby-kopplingstabell-------------------------------------------


DROP TABLE IF EXISTS StudentHobby;

CREATE TABLE StudentHobby AS SELECT HobbiesStudents.StudentId AS StudentId, Hobbies.Id AS HobbyId  
FROM HobbiesStudents JOIN Hobbies ON HobbiesStudents.Hobby = Hobbies.Hobby;

DROP TABLE IF EXISTS HobbiesStudents;

