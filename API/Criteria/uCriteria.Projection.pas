unit uCriteria.Projection;

interface

uses
  SysUtils,
  Generics.Collections,
  uSQLParse,
  uCriteria.Utils;

type

  IProjection = interface
  ['{835DA42A-B5CA-4F56-9F89-22485ECF3817}']
    function Translate(AClassInfo: Pointer): string;
  end;

  IGroupByProjection = interface
  ['{EB40DE7A-DB2C-4934-9C12-72C50BAEFC01}']
    function ToGroupSqlString(AClassInfo: Pointer): string;
  end;

  IAggregateProjection = interface
  ['{05F288FB-4F6E-40EB-B674-EEA92200C216}']
  end;

  IProjectionList = interface
  ['{2B8C2362-4C3F-4F1E-B1BB-C9892ACB7C67}']
    function TranslateGroupBy(AClassInfo: Pointer): string;
  end;

  TPropertyProjectionBase = class(TInterfacedObject)
  strict private
    FPropertyName: string;
    FAlias       : string;
  private
    function GetPropertyName: string;
    function GetAlias: string;
  public
    constructor Create(APropertyName: string); overload;
    constructor Create(APropertyName, AAlias: string); overload;

    property PropertyName: string read GetPropertyName;
    property Alias: string read GetAlias;
  end;

  TPropertyProjection = class(TPropertyProjectionBase, IProjection, IGroupByProjection)
  public
    function Translate(AClassInfo: Pointer): string;
    function ToGroupSqlString(AClassInfo: Pointer): string;
  end;

  TProjectionBaseList = class(TInterfacedObject)
  strict private
    FProjections: TList<IProjection>;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    property Projections: TList<IProjection> read FProjections write FProjections;
  end;

  TProjectionList = class(TProjectionBaseList, IProjection, IProjectionList)
  public
    function Translate(AClassInfo: Pointer): string; virtual;
    function TranslateGroupBy(AClassInfo: Pointer): string;
  end;

  TProjectionDistinct = class(TProjectionList, IGroupByProjection)
  public
    function Translate(AClassInfo: Pointer): string; override;
    function ToGroupSqlString(AClassInfo: Pointer): string;
  end;

  TProjectionRowCount = class(TInterfacedObject, IProjection, IAggregateProjection)
  public
    function Translate(AClassInfo: Pointer): string;
  end;

  TProjectionAvg = class(TPropertyProjectionBase, IProjection, IAggregateProjection)
  public
    function Translate(AClassInfo: Pointer): string;
  end;

  TProjectionMin = class(TPropertyProjectionBase, IProjection, IAggregateProjection)
  public
    function Translate(AClassInfo: Pointer): string;
  end;

  TProjectionMax = class(TPropertyProjectionBase, IProjection, IAggregateProjection)
  public
    function Translate(AClassInfo: Pointer): string;
  end;

  TProjectionCount = class(TPropertyProjectionBase, IProjection, IAggregateProjection)
  public
    function Translate(AClassInfo: Pointer): string;
  end;

  TProjectionSum = class(TPropertyProjectionBase, IProjection, IAggregateProjection)
  public
    function Translate(AClassInfo: Pointer): string;
  end;


implementation

{ TProjection }

function TPropertyProjection.Translate(AClassInfo: Pointer): string;
var
  LAlias: string;
begin
  if Alias = EmptyStr then
  begin
    LAlias := PropertyName;
  end
  else
  begin
    LAlias := Alias;
  end;

  Result :=
    TORMSqlParse.GetTableName(AClassInfo) + '.' +
    TORMUtils.GetColumnName(AClassInfo, PropertyName) + ' as ' +
    LAlias;
end;

function TPropertyProjection.ToGroupSqlString(AClassInfo: Pointer): string;
begin
  Result :=
    TORMSqlParse.GetTableName(AClassInfo) + '.' +
    TORMUtils.GetColumnName(AClassInfo, PropertyName);
end;

{ TProjectionBaseList }

constructor TProjectionBaseList.Create;
begin
  FProjections := TList<IProjection>.Create;
end;

destructor TProjectionBaseList.Destroy;
begin
  if Assigned(FProjections) then
  begin
    FreeAndNil(FProjections);
  end;

  inherited;
end;

{ TProjectionList }

function TProjectionList.Translate(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
  i: Integer;
  SQLAux: string;
begin
  SQL := TStringBuilder.Create;
  try
    for i := 0 to Self.Projections.Count - 1 do
    begin
      SQLAux := Self.Projections[i].Translate(AClassInfo);

      // Is it the last item?
      if (i < Self.Projections.Count -1) then
      begin
        SQLAux := SQLAux + ', ';
      end;

      SQL.Append(SQLAux);

    end;
    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

function TProjectionList.TranslateGroupBy(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
  i: Integer;
  SQLAux: string;
  GroupByProjection: IGroupByProjection;
  ProjectionAggregation: IAggregateProjection;
  HasAggregate: Boolean;
begin
  HasAggregate := False;

  SQL := TStringBuilder.Create;
  try
    for i := 0 to Self.Projections.Count - 1 do
    begin

      // Has aggregate functions and one more projections itens
      if (not HasAggregate) and (Self.Projections[i].QueryInterface(IAggregateProjection, ProjectionAggregation) = 0) then
      begin
        HasAggregate := Self.Projections.Count > 1;
      end;

      if Self.Projections[i].QueryInterface(IGroupByProjection, GroupByProjection) = 0 then
      begin
        SQLAux := GroupByProjection.ToGroupSqlString(AClassInfo);

        if (SQLAux <> EmptyStr) then
        begin
          if (SQL.ToString <> EmptyStr) then
          begin
            SQL.Append(', ');
          end;
          SQL.Append(SQLAux);
        end;
      end;
    end;

    // Clear the SQL Group if there aren't aggregate functions in the list
    if not HasAggregate then
    begin
      SQL.Clear;
    end;

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TProjectionDistinct }

function TProjectionDistinct.ToGroupSqlString(AClassInfo: Pointer): string;
begin
  Result := inherited TranslateGroupBy(AClassInfo);
end;

function TProjectionDistinct.Translate(AClassInfo: Pointer): string;
begin
  Result := 'DISTINCT ' + inherited Translate(AClassInfo);
end;

{ TProjectionRowCount }

function TProjectionRowCount.Translate(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
  PKPropertyName: string;
begin

  SQL := TStringBuilder.Create;
  try
    PKPropertyName := TORMSqlParse.GetPrimaryKeyProperty(AClassInfo);

    if (PKPropertyName = EmptyStr) then
    begin
      PKPropertyName := '*';
    end
    else
    begin
      PKPropertyName := TORMSqlParse.GetTableName(AClassInfo) + '.' +
        TORMUtils.GetColumnName(AClassInfo, PKPropertyName)
    end;

    SQL.Append('COUNT(').Append(PKPropertyName).Append(') AS COUNT');

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;

end;

{ TProjectionAvg }

function TProjectionAvg.Translate(AClassInfo: Pointer): string;
var
  SQLAux, LAlias: string;
begin

  if Alias = EmptyStr then
  begin
    LAlias := 'AVG_' + PropertyName;
  end
  else
  begin
    LAlias := Alias;
  end;

  SQLAux := TORMSqlParse.GetTableName(AClassInfo) + '.' +
    TORMUtils.GetColumnName(AClassInfo, PropertyName);

  SQLAux := 'AVG(' + SQLAux + ') AS ' + LAlias;

  Result := SQLAux;
end;

{ TPropertyProjectionBase }

constructor TPropertyProjectionBase.Create(APropertyName: string);
begin
  Create(APropertyName, EmptyStr);
end;

constructor TPropertyProjectionBase.Create(APropertyName, AAlias: string);
begin
  FPropertyName := APropertyName;
  FAlias        := AAlias;
end;

function TPropertyProjectionBase.GetAlias: string;
begin
  Result := FAlias;
end;

function TPropertyProjectionBase.GetPropertyName: string;
begin
  Result := FPropertyName;
end;

{ TProjectionMin }

function TProjectionMin.Translate(AClassInfo: Pointer): string;
var
  SQLAux: string;
  LAlias: string;
begin

  if Alias = EmptyStr then
  begin
    LAlias := 'MIN_' + PropertyName;
  end
  else
  begin
    LAlias := Alias;
  end;

  SQLAux := TORMSqlParse.GetTableName(AClassInfo) + '.' +
    TORMUtils.GetColumnName(AClassInfo, PropertyName);

  SQLAux := 'MIN(' + SQLAux + ') AS ' + LAlias;

  Result := SQLAux;
end;

{ TProjectionMax }

function TProjectionMax.Translate(AClassInfo: Pointer): string;
var
  SQLAux: string;
  LAlias: string;
begin

  if Alias = EmptyStr then
  begin
    LAlias := 'MAX_' + PropertyName;
  end
  else
  begin
    LAlias := Alias;
  end;

  SQLAux := TORMSqlParse.GetTableName(AClassInfo) + '.' +
    TORMUtils.GetColumnName(AClassInfo, PropertyName);

  SQLAux := 'MAX(' + SQLAux + ') AS ' + LAlias;

  Result := SQLAux;
end;

{ TProjectionCount }

function TProjectionCount.Translate(AClassInfo: Pointer): string;
var
  SQLAux: string;
  LAlias: string;
begin

  if (Trim(PropertyName) <> EmptyStr) then
  begin
    if Alias = EmptyStr then
    begin
      LAlias := 'COUNT_' + PropertyName;
    end
    else
    begin
      LAlias := Alias;
    end;

    SQLAux := TORMSqlParse.GetTableName(AClassInfo) + '.' +
      TORMUtils.GetColumnName(AClassInfo, PropertyName);
  end
  else
  begin
    SQLAux := '*';
    LAlias := 'COUNT';
  end;

  SQLAux := 'COUNT(' + SQLAux + ') AS ' + LAlias;

  Result := SQLAux;
end;

{ TProjectionSum }

function TProjectionSum.Translate(AClassInfo: Pointer): string;
var
  SQLAux: string;
  LAlias: string;
begin

  if Alias = EmptyStr then
  begin
    LAlias := 'SUM_' + PropertyName;
  end
  else
  begin
    LAlias := Alias;
  end;

  SQLAux := TORMSqlParse.GetTableName(AClassInfo) + '.' +
    TORMUtils.GetColumnName(AClassInfo, PropertyName);

  SQLAux := 'SUM(' + SQLAux + ') AS ' + LAlias;

  Result := SQLAux;
end;

end.
