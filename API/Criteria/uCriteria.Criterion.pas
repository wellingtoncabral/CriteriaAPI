unit uCriteria.Criterion;

interface

uses
  Rtti,
  SysUtils,
  Generics.Collections,
  uCriteria.Utils;

type

  TCompareOperator = (coEqual, coGreaterThan, coLowerThan, coGreaterOrEqual,
    coLowerOrEqual, coNotEqual, coLike, coILike, coIsNull, coIsNotNull);

  ICriterion = interface
    function Translate(AClassInfo: Pointer): string;
  end;

  TCriterionBase = class(TInterfacedObject)
  strict private
    FPropertyName: string;
  public
    property PropertyName: string read FPropertyName write FPropertyName;
  end;

  TCriterion = class(TCriterionBase, ICriterion)
  strict private
    FCompareOperator: TCompareOperator;
    FValue          : TValue;
  public
    constructor Create(PropertyName: string; CompareOperator: TCompareOperator;
      Value: TValue);

    function Translate(AClassInfo: Pointer): string;

    property CompareOperator: TCompareOperator read FCompareOperator write FCompareOperator;
    property Value: TValue read FValue write FValue;
  end;

  TCriterionBetween = class(TCriterionBase, ICriterion)
  strict private
    FMinValue: TValue;
    FMaxValue: TValue;
  public
    property MinValue: TValue read FMinValue write FMinValue;
    property MaxValue: TValue read FMaxValue write FMaxValue;

    function Translate(AClassInfo: Pointer): string;
  end;

  TCriterionIn = class(TCriterionBase, ICriterion)
  strict private
    FValues: TList<TValue>;
  public
    constructor Create;
    destructor Destroy; override;

    function Translate(AClassInfo: Pointer): string;

    property Values: TList<TValue> read FValues write FValues;
  end;

  TCriterionNotIn = class(TCriterionIn);

  TCriterionLogicalExpression = class(TInterfacedObject)
  private
    FLeftExpression : ICriterion;
    FRightExpression: ICriterion;
  public
    constructor Create(ALeftExpression, ARightExpression: ICriterion);

    property LeftExpression: ICriterion read FLeftExpression write FLeftExpression;
    property RightExpression: ICriterion read FRightExpression write FRightExpression;
  end;

  TCriterionOr = class(TCriterionLogicalExpression, ICriterion)
  public
    function Translate(AClassInfo: Pointer): string;
  end;

  TCriterionAnd = class(TCriterionLogicalExpression, ICriterion)
  public
    function Translate(AClassInfo: Pointer): string;
  end;

  TCriterionList = class(TInterfacedObject)
  strict private
    FRestrictions: TList<ICriterion>;
  public
    constructor Create;
    destructor Destroy; override;

    property Restrictions: TList<ICriterion> read FRestrictions write FRestrictions;
  end;

  TDisjunction = class(TCriterionList, ICriterion)
  public
    function Translate(AClassInfo: Pointer): string;
  end;

  TConjunction = class(TCriterionList, ICriterion)
  public
    function Translate(AClassInfo: Pointer): string;
  end;

implementation

{ TCriterionList }

constructor TCriterionList.Create;
begin
  FRestrictions := TList<ICriterion>.Create;
end;

destructor TCriterionList.Destroy;
begin
  if Assigned(FRestrictions) then
  begin
    FreeAndNil(FRestrictions);
  end;

  inherited;
end;

{ TCriterionOr }

function TCriterionOr.Translate(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
begin
  SQL := TStringBuilder.Create;
  try
    SQL.AppendFormat(
      '%s OR %s',
      [LeftExpression.Translate(AClassInfo), RightExpression.Translate(AClassInfo)]);

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TCriteriaIn }

constructor TCriterionIn.Create;
begin
  FValues := TList<TValue>.Create;
end;

destructor TCriterionIn.Destroy;
begin
  if Assigned(FValues) then
  begin
    FreeAndNil(FValues);
  end;

  inherited;
end;

function TCriterionIn.Translate(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
  Value: TValue;
begin
  SQL := TStringBuilder.Create;
  try

    SQL.Append(TORMUtils.GetColumnName(AClassInfo, PropertyName));

    if (Self is TCriterionNotIn) then
    begin
      SQL.Append(' NOT IN (');
    end
    else
    begin
      SQL.Append(' IN (');
    end;

    for Value in (Self as TCriterionIn).Values do
    begin
      SQL.Append(TORMUtils.GetColumnValueByType(AClassInfo, PropertyName, Value)).Append(',');
    end;

    SQL.Remove(SQL.Length-1, 1).Append(')').AppendLine;

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TCriterion }

constructor TCriterion.Create(PropertyName: string;
  CompareOperator: TCompareOperator; Value: TValue);
begin
  Self.PropertyName    := PropertyName;
  Self.CompareOperator := CompareOperator;
  Self.Value           := Value;
end;

function TCriterion.Translate(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
  FieldName, FieldValue: string;
begin
  SQL := TStringBuilder.Create;
  try
    FieldName := TORMUtils.GetColumnName(AClassInfo, PropertyName);

    // A case-insensitive "like"
    if (CompareOperator = coILike) then
    begin
      FieldName := 'LOWER(' + FieldName + ')';
    end;

    SQL.Append(FieldName);

    case CompareOperator of
      coEqual         : SQL.Append(' = ');
      coGreaterThan   : SQL.Append(' > ');
      coLowerThan     : SQL.Append(' < ');
      coGreaterOrEqual: SQL.Append(' >= ');
      coLowerOrEqual  : SQL.Append(' <= ');
      coNotEqual      : SQL.Append(' <> ');
      coLike, coILike : SQL.Append(' LIKE ');
      coIsNull        : SQL.Append(' IS NULL ');
      coIsNotNull     : SQL.Append(' IS NOT NULL ');
    end;

    if not (CompareOperator in [coIsNull, coIsNotNull]) then
    begin
      FieldValue := TORMUtils.GetColumnValueByType(AClassInfo, PropertyName, Value);

      // A case-insensitive "like"
      if (CompareOperator = coILike) then
      begin
        FieldValue := AnsiLowerCase(FieldValue);
      end;

      SQL.Append(FieldValue).AppendLine;
    end;

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TCriterionBetween }

function TCriterionBetween.Translate(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
begin
  SQL := TStringBuilder.Create;
  try
    SQL.Append(TORMUtils.GetColumnName(AClassInfo, PropertyName));

    SQL.Append(' BETWEEN ').
        Append(TORMUtils.GetColumnValueByType(AClassInfo, PropertyName, MinValue)).
        Append(' AND ').
        Append(TORMUtils.GetColumnValueByType(AClassInfo, PropertyName, MaxValue)).
        AppendLine;

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TDisjunction }

function TDisjunction.Translate(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
  i: Integer;
begin
  SQL := TStringBuilder.Create;
  try
    SQL.Append('(');

    for i := 0 to Self.Restrictions.Count - 1 do
    begin
      SQL.Append(Restrictions[i].Translate(AClassInfo));

      // Is it the last item?
      if (i < Self.Restrictions.Count -1) then
      begin
        SQL.Append(' OR ');
      end;
    end;

    SQL.Append(')');

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TCriterionAnd }

function TCriterionAnd.Translate(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
begin
  SQL := TStringBuilder.Create;
  try
    SQL.AppendFormat(
      '%s AND %s',
      [LeftExpression.Translate(AClassInfo), RightExpression.Translate(AClassInfo)]);

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TConjunction }

function TConjunction.Translate(AClassInfo: Pointer): string;
var
  SQL: TStringBuilder;
  i: Integer;
begin
  SQL := TStringBuilder.Create;
  try
    SQL.Append('(');

    for i := 0 to Self.Restrictions.Count - 1 do
    begin
      SQL.Append(Restrictions[i].Translate(AClassInfo));

      // Is it the last item?
      if (i < Self.Restrictions.Count -1) then
      begin
        SQL.Append(' AND ');
      end;
    end;

    SQL.Append(')');

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;

{ TLogicalExpression }

constructor TCriterionLogicalExpression.Create(ALeftExpression,
  ARightExpression: ICriterion);
begin
  FLeftExpression  := ALeftExpression;
  FRightExpression := ARightExpression;
end;

end.
