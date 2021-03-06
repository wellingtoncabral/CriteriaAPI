unit uCriteria.Annotation;

interface

type
  TReferenceType = (rtInner, rtLeft);

  TTable = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(AName: string);
    property Name: string read FName;
  end;

  TPrimaryKey = class(TCustomAttribute);

  TSequence = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create; overload;
    constructor Create(AName: string); overload;

    property Name: string read FName;
  end;

  TColumnBase = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(AName: string);

    property Name: string read FName;
  end;

  TColumn     = class(TColumnBase);
  TTransient  = class(TColumnBase);


  TJoinTable = class(TCustomAttribute)
  private
    FTableSource  : string;
    FColumnsSource: string;
    FTableTarget  : string;
    FColumnsTarget: string;
    FReferenceType: TReferenceType;
  public
    constructor Create(ATableSource, AColumnsSource, ATableTarget,
      AColumnsTarget: string; AReferenceType: TReferenceType);

    property TableSource: string read FTableSource write FTableSource;
    property ColumnsSource: string read FColumnsSource write FColumnsSource;
    property TableTarget: string read FTableTarget write FTableTarget;
    property ColumnsTarget: string read FColumnsTarget write FColumnsTarget;
    property ReferenceType: TReferenceType read FReferenceType write FReferenceType;
  end;

  TJoinColumn = class(TColumnBase)
  private
    FTableName : string;
  public
    constructor Create(ATableName, AColumnName: string);

    property TableName: string read FTableName write FTableName;
  end;



implementation

{ TTabela }

constructor TTable.Create(AName: string);
begin
  FName := AName;
end;

{ TColumnBase }

constructor TColumnBase.Create(AName: string);
begin
  FName := AName;
end;

{ TSequence }

constructor TSequence.Create(AName: string);
begin
  FName := AName;
end;

constructor TSequence.Create;
begin
  Create('');
end;

{ TJoinTable }

constructor TJoinTable.Create(ATableSource, AColumnsSource, ATableTarget,
      AColumnsTarget: string; AReferenceType: TReferenceType);
begin
  FTableSource   := ATableSource;
  FColumnsSource := AColumnsSource;
  FTableTarget   := ATableTarget;
  FColumnsTarget := AColumnsTarget;
  FReferenceType := AReferenceType;
end;

{ TJoinColumn }

constructor TJoinColumn.Create(ATableName, AColumnName: string);
begin
  FTableName := ATableName;
  FName      := AColumnName;
end;

end.
