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
	StudentId INT NOT NULL AUTO_INCREMENT,
	FirstName VARCHAR(26) NOT NULL,
	LastName VARCHAR(26) NOT NULL,
	PRIMARY KEY (StudentId)
) ENGINE=INNODB;


INSERT INTO Student (StudentId, FirstName, LastName) 
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
) ENGINE=INNODB;

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
	SchoolId INT NOT NULL AUTO_INCREMENT,
	Name VARCHAR(32) NOT NULL,
	City VARCHAR(32) NOT NULL,
	PRIMARY KEY (SchoolId)
) ENGINE=INNODB;

INSERT INTO School(Name, City)
SELECT DISTINCT School AS Name, City AS City FROM UNF;

-- -------------------------------------------StudentSchool-kopplingstabell----------------------------------------

DROP TABLE IF EXISTS StudentSchool;

CREATE TABLE StudentSchool (
	StudentId INT NOT NULL,
	SchoolId INT NOT NULL,
	PRIMARY KEY(StudentId, SchoolId)
) ENGINE=INNODB;

INSERT INTO StudentSchool(StudentId, SchoolId)
SELECT DISTINCT UNF.Id AS StudentId, School.SchoolId AS SchoolId
FROM UNF INNER JOIN School ON UNF.School =School.Name;

-- --------------------------------------------------UniqueHobbies-------------------------------------------------

DROP TABLE IF EXISTS Hobbies;

CREATE TABLE Hobbies (
	HobbyId INT NOT NULL AUTO_INCREMENT,
	Name VARCHAR(100),
	PRIMARY KEY(HobbyId)
) ENGINE=INNODB;

DROP PROCEDURE IF EXISTS extract_unique_hobbies;
DROP TABLE IF EXISTS temp_Hobbies;

DELIMITER //

CREATE procedure extract_unique_hobbies()

BEGIN
  SET @max_hobbies := ((SELECT max(length(Hobbies) - length(replace(Hobbies, ',', ''))) AS Max FROM UNF) + 1);
  SET @x := 1;

  CREATE TABLE temp_Hobbies (
  	HobbyId INT NOT NULL AUTO_INCREMENT,
  	Name VARCHAR(100),
  	PRIMARY KEY(HobbyId)
  	) ENGINE=INNODB;

  WHILE @x <= @max_hobbies DO
    
	INSERT INTO temp_Hobbies(Name) SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(Hobbies, ',', @x), ',', -1) AS temp_Hobby FROM UNF ;

    SET @x = @x + 1;
  END WHILE;

INSERT INTO Hobbies(Name)
SELECT DISTINCT trim(Name) FROM temp_Hobbies WHERE length(Name) > 0;
DROP TABLE temp_Hobbies;
END//

DELIMITER ;

CALL extract_unique_hobbies();

-- --------------------------------------------------HobbiesStudents-------------------------------------------------

DROP TABLE IF EXISTS HobbiesStudents;

CREATE TABLE HobbiesStudents (
	Hobby VARCHAR(100),
	StudentId INT NOT NULL
) ENGINE=INNODB;


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
  	) ENGINE=INNODB;

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

CREATE TABLE StudentHobby (
	StudentId INT NOT NULL,
	HobbyId INT NOT NULL,
	PRIMARY KEY(StudentId, HobbyId)
) ENGINE=INNODB;

INSERT INTO StudentHobby(StudentId, HobbyId)
SELECT HobbiesStudents.StudentId AS StudentId, Hobbies.HobbyId AS HobbyId
FROM HobbiesStudents JOIN Hobbies ON HobbiesStudents.Hobby = Hobbies.Name;

DROP TABLE IF EXISTS HobbiesStudents;


-- ----------------------------------------------------Grades-------------------------------------------------------

DROP TABLE IF EXISTS Grade;

CREATE TABLE Grade (
	GradeId INT NOT NULL AUTO_INCREMENT,
	Name VARCHAR(30) NOT NULL,
	PRIMARY KEY(GradeId)
) ENGINE=INNODB;

INSERT INTO Grade (Name)
SELECT DISTINCT Grade FROM UNF;

ALTER TABLE Student ADD COLUMN GradeId INT NOT NULL;

UPDATE Student JOIN UNF ON Student.StudentId = UNF.Id
JOIN Grade ON Grade.Name = UNF.Grade
SET Student.GradeId = Grade.GradeId;


-- ----------------------------------------------------Views--------------------------------------------------------

-- PhoneList
DROP VIEW IF EXISTS PhoneList;
CREATE VIEW PhoneList AS 
SELECT Student.StudentId, FirstName, LastName, group_concat(Number) AS Numbers FROM Student 
JOIN Phone ON Student.StudentId=Phone.StudentId
GROUP BY StudentId;

-- HobbyList
DROP VIEW IF EXISTS HobbyList;
CREATE VIEW HobbyList AS 
SELECT Student.StudentId, FirstName, LastName, group_concat(Name) AS Hobbies FROM Student
JOIN StudentHobby USING (StudentId)
JOIN Hobbies USING (HobbyId)
GROUP BY StudentId;

-- StudentList
DROP VIEW IF EXISTS StudentList;
CREATE VIEW StudentList AS
SELECT Student.StudentId, Student.FirstName, Student.LastName, Grade.Name AS Grade, Hobbies, School.Name AS School, City, Numbers
FROM StudentSchool
LEFT JOIN Student USING (StudentId)
LEFT JOIN Grade USING (GradeId)
LEFT JOIN HobbyList USING (StudentId)
LEFT JOIN School USING (SchoolId)
LEFT JOIN PhoneList USING (StudentId);