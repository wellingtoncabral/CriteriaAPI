unit uCriteria;

interface

uses
  Rtti,
  SysUtils,
  Generics.Collections,
  uHelper.StringBuilder,
  uCriteria.Criterion,
  uCriteria.Order,
  uCriteria.Projection,
  uCriteria.Utils,
  uSQLParse;

type

  TRestrictions = class
  public
    class function Equal(const APropertyName: string; AValue: TValue): TCriterion;
    class function NotEqual(const APropertyName: string; AValue: TValue): TCriterion;
    class function GreaterThan(const APropertyName: string; AValue: TValue): TCriterion;
    class function GreaterOrEqual(const APropertyName: string; AValue: TValue): TCriterion;
    class function LowerThan(const APropertyName: string; AValue: TValue): TCriterion;
    class function LowerOrEqual(const APropertyName: string; AValue: TValue): TCriterion;
    class function IsNull(const APropertyName: string): TCriterion;
    class function IsNotNull(const APropertyName: string): TCriterion;
    class function Like(const APropertyName: string; AValue: TValue): TCriterion;
    class function ILike(const APropertyName: string; AValue: TValue): TCriterion;
    class function Between(const APropertyName: string; AMinValue, AMaxWeight: TValue): TCriterionBetween;
    class function _In(const APropertyName: string; const Args: array of TValue): TCriterionIn;
    class function NotIn(const APropertyName: string; const Args: array of TValue): TCriterionNotIn;
    class function _Or(const LeftExpression, RightExpression: ICriterion): TCriterionOr;
    class function _And(const LeftExpression, RightExpression: ICriterion): TCriterionAnd;
    class function Disjunction(const Args: array of ICriterion): TDisjunction; overload;
    class function Disjunction(const Args: TList<ICriterion>): TDisjunction; overload;
    class function Conjunction(const Args: array of ICriterion): TConjunction; overload;
    class function Conjunction(const Args: TList<ICriterion>): TConjunction; overload;
  end;

  TProjections = class
  public
    class function PropertyName(PropertyName: string): TPropertyProjection; overload;
    class function PropertyName(PropertyName, Alias: string): TPropertyProjection; overload;
    class function List(const Args: array of IProjection): TProjectionList; overload;
    class function List(const Args: TList<IProjection>): TProjectionList; overload;
    class function Distinct(const Args: array of string): TProjectionDistinct;
    class function RowCount: TProjectionRowCount;
    class function Avg(PropertyName: string): TProjectionAvg; overload;
    class function Avg(PropertyName, Alias: string): TProjectionAvg; overload;
    class function Count(PropertyName: string): TProjectionCount; overload;
    class function Count(PropertyName, Alias: string): TProjectionCount; overload;
    class function Min(PropertyName: string): TProjectionMin; overload;
    class function Min(PropertyName, Alias: string): TProjectionMin; overload;
    class function Max(PropertyName: string): TProjectionMax; overload;
    class function Max(PropertyName, Alias: string): TProjectionMax; overload;
    class function Sum(PropertyName: string): TProjectionSum; overload;
    class function Sum(PropertyName, Alias: string): TProjectionSum; overload;
  end;

  TOrder = class
    class function Asc(APropertyName: string): TOrderBase;
    class function Desc(APropertyName: string): TOrderBase;
  end;

  TCriteria = class
  strict private
    FCriterions : TList<ICriterion>;
    FOrders     : TOrderList;
    FProjection : IProjection;
    FClassInfo  : Pointer;
    FFirstResult: Integer;
    FMaxResult  : Integer;

    {$REGION 'Translate methods'}
    function Translate: string;
    procedure TranslateProjections(SQL: TStringBuilder);
    procedure TranslateRestrictions(SQL: TStringBuilder);
    procedure TranslateOrderBy(SQL: TStringBuilder);
    procedure TranslateAdjustments(SQL: TStringBuilder);
    procedure TranslatePaginations(SQL: TStringBuilder);
    procedure TranslateGroupBy(SQL: TStringBuilder);
    {$ENDREGION}
  public
    constructor Create(AClassInfo: Pointer);
    destructor Destroy; override;

    function Add(Criteria: ICriterion): TCriteria;
    function AddOrder(Order: TOrderBase): TCriteria;

    function SetProjection(Projection: IProjection): TCriteria;

    function SetFirstResult(Value: Integer): TCriteria;
    function SetMaxResult(Value: Integer): TCriteria;
    function ToString: string; override;
  end;

implementation

{ TCriteria }

function TCriteria.Add(Criteria: ICriterion): TCriteria;
begin
  FCriterions.Add(Criteria);
  Result := Self;
end;

function TCriteria.AddOrder(Order: TOrderBase): TCriteria;
begin
  FOrders.Add(Order);
  Result := Self;
end;

constructor TCriteria.Create(AClassInfo: Pointer);
begin
  FCriterions  := TList<ICriterion>.Create;
  FOrders      := TOrderList.Create;
  FClassInfo   := AClassInfo;
  FFirstResult := 1;
  FMaxResult   := -1;
end;

destructor TCriteria.Destroy;
begin
  if Assigned(FCriterions) then
  begin
    FreeAndNil(FCriterions);
  end;

  if Assigned(FOrders) then
  begin
    FreeAndNil(FOrders);
  end;

  inherited;
end;

function TCriteria.SetFirstResult(Value: Integer): TCriteria;
begin
  if (Value <= 0) then
  begin
    raise Exception.Create('First Result Param should be greater than 0');
  end;

  FFirstResult := Value;
  Result       := Self;
end;

function TCriteria.SetMaxResult(Value: Integer): TCriteria;
begin
  if (Value <= 0) then
  begin
    raise Exception.Create('Max Result Param should be greater than 0');
  end;

  FMaxResult := Value;
  Result     := Self;
end;

function TCriteria.SetProjection(Projection: IProjection): TCriteria;
begin
  FProjection := Projection;
  Result      := Self;
end;

function TCriteria.ToString: string;
begin
  inherited;
  Result := Translate;
end;

function TCriteria.Translate: string;
var
  SQL : TStringBuilder;
begin
  inherited;

  SQL := TStringBuilder.Create;
  try
    { PROJECTIONS }
    TranslateProjections(SQL);

    { RESTRICTIONS }
    TranslateRestrictions(SQL);

    { GROUP BY }
    TranslateGroupBy(SQL);

    { ORDER BY }
    TranslateOrderBy(SQL);

    { ADJUNTMENTS }
    TranslateAdjustments(SQL);

    { PAGINATION }
    TranslatePaginations(SQL);

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

procedure TCriteria.TranslateAdjustments(SQL: TStringBuilder);
begin
  SQL._Replace('WHERE 1 = 1 AND', 'WHERE');
end;

procedure TCriteria.TranslateGroupBy(SQL: TStringBuilder);
var
  GroupBySQL: string;
  ProjectionLists: IProjectionList;
begin
  if Assigned(FProjection) then
  begin
    if FProjection.QueryInterface(IProjectionList, ProjectionLists) = 0 then
    begin
      GroupBySQL := ProjectionLists.TranslateGroupBy(FClassInfo);

      if GroupBySQL <> EmptyStr then
      begin
        SQL.AppendLine.Append('GROUP BY ').Append(GroupBySQL);
      end;
    end;
  end;
end;

procedure TCriteria.TranslateOrderBy(SQL: TStringBuilder);
begin
  SQL.Append(FOrders.Translate(FClassInfo));
end;

procedure TCriteria.TranslatePaginations(SQL: TStringBuilder);

const
  C_SQL_SELECT_ROWNUM =
    'SELECT * FROM ( ' +
    '  SELECT a.*, ROWNUM rnum FROM ( ' +
    '    %s ' +
    '  ) a WHERE ROWNUM <= %d ' +
    ') WHERE rnum >= %d';

var
  SQLAux: string;
begin
  if (FMaxResult > 0) then
  begin
    SQLAux := SQL.ToString;
    SQL.Clear;

    // Build SQL with Select Row Num
    SQL.AppendFormat(C_SQL_SELECT_ROWNUM, [SQLAux, FMaxResult, FFirstResult]);
  end;
end;

procedure TCriteria.TranslateProjections;
begin
  inherited;
  if Assigned(FProjection) then
  begin
    SQL.Append('SELECT ')
       .Append(FProjection.Translate(FClassInfo)).AppendLine
       .Append('FROM ').Append(TORMSqlParse.GetTableName(FClassInfo));
  end
  else
  begin
    SQL.Append(TORMSqlParse.GetSelectSql(FClassInfo));
  end;

  SQL.AppendLine.Append('WHERE 1 = 1');
end;

procedure TCriteria.TranslateRestrictions(SQL: TStringBuilder);
var
  Item: ICriterion;
begin
  for Item in FCriterions do
  begin
    SQL.Append(' AND ');
    SQL.Append(Item.Translate(FClassInfo));
  end;
end;

{ TRestrictions }

class function TRestrictions.Between(const APropertyName: string; AMinValue,
  AMaxWeight: TValue): TCriterionBetween;
var
  CriterionBetween: TCriterionBetween;
begin
  CriterionBetween              := TCriterionBetween.Create;
  CriterionBetween.PropertyName := APropertyName;
  CriterionBetween.MinValue     := AMinValue;
  CriterionBetween.MaxValue     := AMaxWeight;

  Result := CriterionBetween;
end;

class function TRestrictions.Conjunction(
  const Args: array of ICriterion): TConjunction;
var
  i: Integer;
  Conjunction: TConjunction;
begin
  Conjunction := TConjunction.Create;

  for i := 0 to High(Args) do
  begin
    if Assigned(Args[i]) then
    begin
      Conjunction.Restrictions.Add(Args[i]);
    end;
  end;

  Result := Conjunction;
end;


class function TRestrictions.Conjunction(
  const Args: TList<ICriterion>): TConjunction;
var
  Conjunction: TConjunction;
begin
  Conjunction := TConjunction.Create;
  Conjunction.Restrictions.AddRange(Args);
  Result := Conjunction;
end;

class function TRestrictions.Disjunction(
  const Args: TList<ICriterion>): TDisjunction;
var
  Disjunction: TDisjunction;
begin
  Disjunction := TDisjunction.Create;
  Disjunction.Restrictions.AddRange(Args);
  Result := Disjunction;
end;


class function TRestrictions.Disjunction(
  const Args: array of ICriterion): TDisjunction;
var
  i: Integer;
  Disjunction: TDisjunction;
begin
  Disjunction := TDisjunction.Create;

  for i := 0 to High(Args) do
  begin
    if Assigned(Args[i]) then
    begin
      Disjunction.Restrictions.Add(Args[i]);
    end;
  end;

  Result := Disjunction;
end;

class function TRestrictions.Equal(const APropertyName: string;
  AValue: TValue): TCriterion;
begin
  Result := TCriterion.Create(APropertyName, coEqual, AValue);
end;

class function TRestrictions.GreaterOrEqual(const APropertyName: string;
  AValue: TValue): TCriterion;
begin
  Result := TCriterion.Create(APropertyName, coGreaterOrEqual, AValue);
end;

class function TRestrictions.GreaterThan(const APropertyName: string;
  AValue: TValue): TCriterion;
begin
  Result := TCriterion.Create(APropertyName, coGreaterThan, AValue);
end;

class function TRestrictions.ILike(const APropertyName: string;
  AValue: TValue): TCriterion;
begin
  // Case-insensitive "like"
  Result := TCriterion.Create(APropertyName, coILike, AValue);
end;

class function TRestrictions.IsNotNull(const APropertyName: string): TCriterion;
begin
  Result := TCriterion.Create(APropertyName, coIsNotNull, '');
end;

class function TRestrictions.IsNull(const APropertyName: string): TCriterion;
begin
  Result := TCriterion.Create(APropertyName, coIsNull, '');
end;

class function TRestrictions.Like(const APropertyName: string;
  AValue: TValue): TCriterion;
begin
  Result := TCriterion.Create(APropertyName, coLike, AValue);
end;

class function TRestrictions.LowerOrEqual(const APropertyName: string;
  AValue: TValue): TCriterion;
begin
  Result := TCriterion.Create(APropertyName, coLowerOrEqual, AValue);
end;

class function TRestrictions.LowerThan(const APropertyName: string;
  AValue: TValue): TCriterion;
begin
  Result := TCriterion.Create(APropertyName, coLowerThan, AValue);
end;

class function TRestrictions.NotEqual(const APropertyName: string;
  AValue: TValue): TCriterion;
begin
  Result := TCriterion.Create(APropertyName, coNotEqual, AValue);
end;

class function TRestrictions.NotIn(const APropertyName: string;
  const Args: array of TValue): TCriterionNotIn;
var
  i: Integer;
  CriterionNotIn: TCriterionNotIn;
begin
  CriterionNotIn              := TCriterionNotIn.Create;
  CriterionNotIn.PropertyName := APropertyName;

  for i := 0 to High(Args) do
  begin
    CriterionNotIn.Values.Add(Args[i]);
  end;

  Result := CriterionNotIn;
end;

class function TRestrictions._And(const LeftExpression, RightExpression: ICriterion): TCriterionAnd;
begin
  Result := TCriterionAnd.Create(LeftExpression, RightExpression);
end;

class function TRestrictions._In(const APropertyName: string;
  const Args: array of TValue): TCriterionIn;
var
  i: Integer;
  CriterionIn: TCriterionIn;
begin
  CriterionIn              := TCriterionIn.Create;
  CriterionIn.PropertyName := APropertyName;

  for i := 0 to High(Args) do
  begin
    CriterionIn.Values.Add(Args[i]);
  end;

  Result := CriterionIn;
end;

class function TRestrictions._Or(const LeftExpression,
  RightExpression: ICriterion): TCriterionOr;
begin
  Result := TCriterionOr.Create(LeftExpression, RightExpression);
end;

{ TProjections }

class function TProjections.Avg(PropertyName: string): TProjectionAvg;
begin
  Result := TProjectionAvg.Create(PropertyName);
end;

class function TProjections.Count(PropertyName: string): TProjectionCount;
begin
  Result := TProjectionCount.Create(PropertyName);
end;

class function TProjections.Avg(PropertyName, Alias: string): TProjectionAvg;
begin
  Result := TProjectionAvg.Create(PropertyName, Alias);
end;

class function TProjections.Count(PropertyName, Alias: string): TProjectionCount;
begin
  Result := TProjectionCount.Create(PropertyName, Alias);
end;

class function TProjections.Distinct(
  const Args: array of string): TProjectionDistinct;
var
  ProjectionDistinct: TProjectionDistinct;
  Projection: TPropertyProjection;
  i: Integer;
begin
  ProjectionDistinct := TProjectionDistinct.Create;

  for i := 0 to High(Args) do
  begin
    Projection := TPropertyProjection.Create(Args[i]);
    ProjectionDistinct.Projections.Add(Projection);
  end;

  Result := ProjectionDistinct;
end;

class function TProjections.List(
  const Args: TList<IProjection>): TProjectionList;
var
  ProjectionList: TProjectionList;
begin
  ProjectionList := TProjectionList.Create;
  ProjectionList.Projections.AddRange(Args);
  Result := ProjectionList;
end;

class function TProjections.List(const Args: array of IProjection): TProjectionList;
var
  ProjectionList: TProjectionList;
  i: Integer;
begin
  ProjectionList := TProjectionList.Create;

  for i := 0 to High(Args) do
  begin
    if Assigned(Args[i]) then
    begin
      ProjectionList.Projections.Add(Args[i]);
    end;
  end;

  Result := ProjectionList;
end;

class function TProjections.Max(PropertyName: string): TProjectionMax;
begin
  Result := TProjectionMax.Create(PropertyName);
end;

class function TProjections.Max(PropertyName, Alias: string): TProjectionMax;
begin
  Result := TProjectionMax.Create(PropertyName, Alias);
end;

class function TProjections.Min(PropertyName, Alias: string): TProjectionMin;
begin
  Result := TProjectionMin.Create(PropertyName, Alias);
end;

class function TProjections.Min(PropertyName: string): TProjectionMin;
begin
  Result := TProjectionMin.Create(PropertyName);
end;

class function TProjections.PropertyName(PropertyName,
  Alias: string): TPropertyProjection;
begin
  Result := TPropertyProjection.Create(PropertyName, Alias);
end;


class function TProjections.PropertyName(PropertyName: string): TPropertyProjection;
begin
  Result := TPropertyProjection.Create(PropertyName);
end;

class function TProjections.RowCount: TProjectionRowCount;
begin
  Result := TProjectionRowCount.Create;
end;

class function TProjections.Sum(PropertyName: string): TProjectionSum;
begin
  Result := TProjectionSum.Create(PropertyName);
end;

class function TProjections.Sum(PropertyName, Alias: string): TProjectionSum;
begin
  Result := TProjectionSum.Create(PropertyName, Alias);
end;

{ TOrder }

class function TOrder.Asc(APropertyName: string): TOrderBase;
begin
  Result              := TOrderBase.Create;
  Result.PropertyName := APropertyName;
  Result.OrderType    := otAsc;
end;

class function TOrder.Desc(APropertyName: string): TOrderBase;
begin
  Result              := TOrderBase.Create;
  Result.PropertyName := APropertyName;
  Result.OrderType    := otDesc;
end;

end.
