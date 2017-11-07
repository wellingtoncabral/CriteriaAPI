unit uEmployee;

interface

uses
  DBClient,
  Classes,
  Generics.Collections,
  SysUtils,
  uCriteria.Annotation,
  uWrapper.NullableTypes,
  Variants;

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

implementation

end.
