## DB2022 Inlämning(2023)

Detta är en inlämningsrepo för kursen "Utveckling mot databaser"   
på ITHS, JAVA2022.   
  
### ER-Diagram  
  
```mermaid
erDiagram
    Student ||--|{ StudentSchool : attends
    School ||--|{ StudentSchool : enrolls
    Student ||--|{ StudentHobby : has
    Hobbies ||--|{ StudentHobby : involves
    Student ||--|{ Phone : has



    Hobbies {
    	int Id
		string Hobby
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
    }
    School {
        int Id
        string Name
        string City
    }
```