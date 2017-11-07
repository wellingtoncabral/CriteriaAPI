unit uCriteria.Order;

interface

uses
  SysUtils,
  Generics.Collections,
  uCriteria.Utils;

type
  TOrderType = (otAsc, otDesc);

  ITranslateSQL = interface
    function Translate(AClassInfo: Pointer): string;
  end;

  TOrderBase = class
  strict private
    FPropertyName: string;
    FOrderType   : TOrderType;
  public
    property PropertyName: string read FPropertyName write FPropertyName;
    property OrderType: TOrderType read FOrderType write FOrderType;
  end;

  TOrderList = class(TInterfacedObject, ITranslateSQL)
  private
    FItems: TObjectList<TOrderBase>;
  public
    constructor Create;
    destructor Destroy; override;

    function Translate(AClassInfo: Pointer): string;

    procedure Add(Order: TOrderBase);
    function Count: Integer;
  end;


implementation

{ TOrderList }

procedure TOrderList.Add(Order: TOrderBase);
begin
  FItems.Add(Order);
end;

function TOrderList.Count: Integer;
begin
  Result := FItems.Count;
end;

constructor TOrderList.Create;
begin
  FItems := TObjectList<TOrderBase>.Create;
end;

destructor TOrderList.Destroy;
begin
  if Assigned(FItems) then
  begin
    FreeAndNil(FItems);
  end;

  inherited;
end;

function TOrderList.Translate(AClassInfo: Pointer): string;
var
  Item: TOrderBase;
  SQL: TStringBuilder;
begin
  SQL := TStringBuilder.Create;
  try
    if FItems.Count > 0 then
    begin
      SQL.Append(' ORDER BY ');
      for Item in FItems do
      begin
        SQL.Append(TORMUtils.GetColumnName(AClassInfo, Item.PropertyName)).Append(' ');
        case Item.OrderType of
          otAsc : SQL.Append('ASC');
          otDesc: SQL.Append('DESC');
        end;
        SQL.Append(', ');
      end;

      SQL.Remove(SQL.Length-2, 2);
    end;

    Result := SQL.ToString;
  finally
    FreeAndNil(SQL);
  end;
end;



end.
