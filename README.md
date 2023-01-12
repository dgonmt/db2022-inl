## DB2022 Inlämning(2023)

Detta är en inlämningsrepo för kursen "Utveckling mot databaser"   
på ITHS, JAVA2022.   
  
### ER-Diagram  
  
```mermaid
erDiagram
    Student ||--o{ StudentSchool : attends
    School ||--o{ StudentSchool : enrolls
    Student ||--o{ StudentHobby : has
    Hobbies ||--o{ StudentHobby : involves
    Student ||--o{ Phone : has
    Student }|--o| Grade : has



    Hobbies {
    	int HobbyId
		string Name
    }
    Phone {
    	int PhoneId
		int StudentId
		string Type
		string Number
    }
    StudentHobby {
	  	int StudentId
	  	int HobbyId 
    }
    StudentSchool {
        int StudentId
        int SchoolId
    }
    Student {
        int Id
        string FirstName
        string LastName
        int GradeId
    }
    School {
        int Id
        string Name
        string City
    }
    Grade {
        int GradeId
        string Name
    }
```
