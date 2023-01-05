## DB2022 Inlämning(2023)

Detta är en inlämningsrepo för kursen "Utveckling mot databaser"   
på ITHS, JAVA2022.   
  
### ER-Diagram  
  
School ||--|{ StudentSchool : accepts
    School {
        int Id
        string Name
        string City
    }
    StudentSchool {
        int StudentId
        int SchoolId
    }