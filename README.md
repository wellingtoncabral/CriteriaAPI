#Criteria API

The Criteria API allows you to build up a criteria query object programmatically where you can apply filtration rules and logical conditions.

The Criteria interface provides methods which can be used to create a Criteria object that returns instances of the persistence object's class when your application executes a criteria query.

Following is the simplest example of a criteria query is one which will simply return the SQL that corresponds to the TEmployee class.

```delphi
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try
    ShowMessage(Criteria.ToString);
  finally
    FreeAndNil(Criteria);
  end;
end;  
```

Output:

```sql
SELECT
  TB_EMPLOYEE.ID as Id,
  TB_EMPLOYEE.FIRST_NAME as FirstName,
  TB_EMPLOYEE.SALARY as Salary,
  TB_EMPLOYEE.DH_BIRTHDAY as Birthday,
  TB_EMPLOYEE.GROUP_ID as GroupId 
FROM 
  TB_EMPLOYEE
```

##Annotations
To use the Criteria API you need to define annotations in the POJO class.

Consider the following POJO class:

```delphi
type
  [TTable('TB_EMPLOYEE')]
  TEmployee = class
  private
    FId: Integer;
    FFirstName: string;
    FSalary: Nullable<Double>;
    FBirthday: TDate;
    FGroupId: Integer;
    FGroupDescription: string;
  public
    [TPrimaryKey]
    [TColumn('ID')]
    property Id: Integer read FId write FId;

    [TColumn('FIRST_NAME')]
    property FirstName: string read FFirstName write FFirstName;

    [TColumn('SALARY')]
    property Salary: Nullable<Double> read FSalary write FSalary;

    [TColumn('DH_BIRTHDAY')]
    property Birthday: TDate read FBirthday write FBirthday;

    [TColumn('GROUP_ID')]
    property GroupId: Integer read FGroupId write FGroupId;
 end;
 ```
 
###Annotations Supported
* **[TTable('TABLE_NAME')]** - Annotation for tables
* **[TPrimaryKey]** - Annotation for represent the primary key column
* **[TColumn('COLUMN_NAME')]** - Annotation for table's column
* **[TSequence('SEQUENCE_NAME')]** - Annotation for db sequence
* **[TTransient]** - Annotation for non-persistent columns

###Nullable types
You must use the **Nullable<>** type for fields that allow persistence with null value

##Restrictions with Criteria
You can use add() method available for Criteria object to add restriction for a criteria query. Following is the example to add a restriction to return the records with salary is equal to 5000.

```delphi
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try
    Criteria.Add(TRestrictions.Equal('Salary', 5000));
    ShowMessage(Criteria.ToString);    
  finally
    FreeAndNil(Criteria);
  end;
```

Output:

```sql
SELECT 
  TB_EMPLOYEE.ID as Id,
  TB_EMPLOYEE.FIRST_NAME as FirstName,
  TB_EMPLOYEE.SALARY as Salary,
  TB_EMPLOYEE.DH_BIRTHDAY as Birthday,
  TB_EMPLOYEE.GROUP_ID as GroupId 
FROM 
  TB_EMPLOYEE
WHERE 
  SALARY = 5000
```

Following are the few more examples covering different scenarios and can be used as per requirement:

```delphi
Criteria := TCriteria.Create(TEmployee.ClassInfo);
try
  // To get records having salary more than 5000
  Criteria.Add(TRestrictions.GreaterThan('salary', 5000));

  // To get records having salary less than 5000
  Criteria.Add(TRestrictions.LowerThan('salary', 5000));

  // To get records having fistName starting with zara
  Criteria.Add(TRestrictions.Like('firstName', 'wellington%'));

  // Case sensitive form of the above restriction.
  Criteria.Add(TRestrictions.ILike('firstName', 'wellington%'));

  // To get records having salary in between 1000 and 5000
  Criteria.Add(TRestrictions.Between('salary', 1000, 5000));

  // To check if the given property is null
  Criteria.Add(TRestrictions.IsNull('salary'));

  // To check if the given property is not null
  Criteria.Add(TRestrictions.IsNotNull('salary'));
  
  ShowMessage(Criteria.ToString);    
finally
  FreeAndNil(Criteria);
end;
```

Output:

```sql
SELECT 
  TB_EMPLOYEE.ID as Id,
  TB_EMPLOYEE.FIRST_NAME as FirstName,
  TB_EMPLOYEE.SALARY as Salary,
  TB_EMPLOYEE.DH_BIRTHDAY as Birthday,
  TB_EMPLOYEE.GROUP_ID as GroupId 
FROM
  TB_EMPLOYEE
WHERE SALARY > 5000 
  AND SALARY < 5000 
  AND FIRST_NAME LIKE 'wellington%' 
  AND LOWER(FIRST_NAME) LIKE 'wellington%'
  AND SALARY BETWEEN 1000 AND 5000
  AND SALARY IS NULL  
  AND SALARY IS NOT NULL 
```  

You can create AND or OR conditions using LogicalExpression restrictions as follows:

```delphi
var
  Criteria: TCriteria;
  SalaryCriterion, NameCriterion: ICriterion;
  OrExp: TCriterionOr;
  AndExp: TCriterionAnd;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try
    SalaryCriterion := TRestrictions.GreaterThan('salary', 5000);
    NameCriterion   := TRestrictions.ILike('firstName','wellington%');

    // To get records matching with OR condistions
    OrExp := TRestrictions._Or(SalaryCriterion, NameCriterion);
    Criteria.Add(OrExp);

    // To get records matching with AND condistions
    AndExp := TRestrictions._And(SalaryCriterion, NameCriterion);
    Criteria.Add(AndExp);

    ShowMessage(Criteria.ToString);
  finally
    FreeAndNil(Criteria);
  end;
end;
```

Output:

```sql
SELECT
  TB_EMPLOYEE.ID as Id,
  TB_EMPLOYEE.FIRST_NAME as FirstName,
  TB_EMPLOYEE.SALARY as Salary,
  TB_EMPLOYEE.DH_BIRTHDAY as Birthday,
  TB_EMPLOYEE.GROUP_ID as GroupId 
FROM 
  TB_EMPLOYEE
WHERE SALARY > 5000
  OR LOWER(FIRST_NAME) LIKE 'wellington%'
 AND SALARY > 5000
 AND LOWER(FIRST_NAME) LIKE 'wellington%'
```

##Pagination using Criteria
There are two methods of the Criteria interface for pagination.

**The Criteria API uses Oracle structure pagination.**

1. **function TCriteria.SetFirstResult(Value: Integer): TCriteria;**
This method takes an integer that represents the first row in your result set, starting with row 0.

2. **function TCriteria.SetMaxResult(Value: Integer): TCriteria;**
This method tells Criteria API to retrieve a fixed number maxResults of objects.

Using above two methods together, we can construct a paging component in our web or Swing application. Following is the example which you can extend to fetch 10 rows at a time:

```delphi
Criteria := TCriteria.Create(TEmployee.ClassInfo);
try
  Criteria.SetFirstResult(1).SetMaxResult(10);
  ShowMessage(Criteria.ToString);
finally
  FreeAndNil(Criteria);
end;
```

Output:

```sql
SELECT * FROM (
  SELECT 
    a.*, 
    ROWNUM rnum FROM (SELECT 
                        TB_EMPLOYEE.ID as Id,
                        TB_EMPLOYEE.FIRST_NAME as FirstName,
                        TB_EMPLOYEE.SALARY as Salary,
                        TB_EMPLOYEE.DH_BIRTHDAY as Birthday,
                        TB_EMPLOYEE.GROUP_ID as GroupId 
                      FROM 
                        TB_EMPLOYEE 
                      WHERE 1 = 1) 
    a WHERE ROWNUM <= 10 ) 
WHERE rnum >= 1
```

##Sorting the Results
The Criteria API provides the Order class to sort your result set in either ascending or descending order, according to one of your object's properties. This example demonstrates how you would use the Order class to sort the result set:

```delphi
Criteria := TCriteria.Create(TEmployee.ClassInfo);
try
  // To get records having salary more than 1000
  Criteria.Add(TRestrictions.GreaterThan('salary', 1000));

  // To sort records in descening order
  Criteria.AddOrder(TOrder.Desc('salary'));

  // To sort records in ascending order
  Criteria.AddOrder(TOrder.Asc('salary'));
  
  ShowMessage(Criteria.ToString);
finally
  FreeAndNil(Criteria);
end;
```

Output:

```sql
SELECT 
  TB_EMPLOYEE.ID as Id,
  TB_EMPLOYEE.FIRST_NAME as FirstName,
  TB_EMPLOYEE.SALARY as Salary,
  TB_EMPLOYEE.DH_BIRTHDAY as Birthday,
  TB_EMPLOYEE.GROUP_ID as GroupId 
FROM 
  TB_EMPLOYEE
WHERE SALARY > 1000
ORDER BY SALARY DESC, SALARY ASC
```

##Projections & Aggregations:
The Criteria API provides the Projections class which can be used to get average, maximum or minimum of the property values. The Projections class is similar to the Restrictions class in that it provides several static factory methods for obtaining Projection instances.

Following are the few examples covering different scenarios and can be used as per requirement:

```delphi
Criteria := TCriteria.Create(TEmployee.ClassInfo);
try
  // To get total row count.
  Criteria.SetProjection(TProjections.RowCount());

  // To get average of a property.
  Criteria.SetProjection(TProjections.Avg('salary'));

  // To get distinct of a property.
  Criteria.SetProjection(TProjections.Distinct(['firstName']));

  // To get maximum of a property.
  Criteria.SetProjection(TProjections.Max('salary'));

  // To get minimum of a property.
  Criteria.SetProjection(TProjections.Min('salary'));

  // To get sum of a property.
  Criteria.SetProjection(TProjections.Sum('salary'));

  ShowMessage(Criteria.ToString);
finally
  FreeAndNil(Criteria);
end;
```

##Informations
For more information check the sample project.
