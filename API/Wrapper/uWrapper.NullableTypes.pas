unit uWrapper.NullableTypes;

// Jim McKeeth - www.Delphi.org - jim@mckeeth.org

interface

uses
  Variants, SysUtils;

type
  ENullReference = class(Exception)
  end;
  EUnsupportedType = class(Exception)
  end;

  Nullable<T> = Record
  private
    FValue: T;
    class function CastBack(const aValue): T; static; inline;

    class function AddInt(const aInt, bInt): T; static; inline;
    class function AddFloat(const aFloat, bFloat): T; static; inline;
    class function AddString(const aString, bString): T; static; inline;
    class function AddInt64(const aInt64, bInt64): T; static; inline;
    class function AddUString(const aUString, bUString): T; static; inline;
    class function AddBoolean(const aBoolean, bBoolean): T; static; inline;

    class function SubtractInt(const aInt, bInt): T; static; inline;
    class function SubtractFloat(const aFloat, bFloat): T; static; inline;
    class function SubtractInt64(const aInt64, bInt64): T; static; inline;

    class function MultiplyInt(const aInt, bInt): T; static; inline;
    class function MultiplyFloat(const aFloat, bFloat): T; static; inline;
    class function MultiplyInt64(const aInt64, bInt64): T; static; inline;

    class function DivideInt(const aInt, bInt): T; static; inline;
    class function DivideFloat(const aFloat, bFloat): T; static; inline;
    class function DivideInt64(const aInt64, bInt64): T; static; inline;

    var FInitValue: string;
    var FDefault: T;
    var FInitDefault: string;
    var FModified: Boolean;
    var FIsNotNull: Boolean;

    procedure SetValue(const AValue: T);
    function GetValue: T;
    function GetIsNull: Boolean;
    function GetIsNotNull: Boolean;
    function GetHasValue: Boolean;
    function GetHasDefault: Boolean;
    procedure SetModified(const Value: Boolean);
  public
    property Value: T read GetValue write SetValue;
    property IsNull: Boolean read GetIsNull;
    property IsNotNull: Boolean read GetIsNotNull;
    property HasValue: Boolean read GetHasValue;
    property HasDefault: Boolean read GetHasDefault;
    property Modified: Boolean read FModified write SetModified;

    procedure ClearValue;
    procedure SetNullValue;
    procedure SetNotNullValue;
    procedure SetDefault(const aDefault: T);

    constructor Create(const aValue: T); overload;
    constructor Create(const aValue: T; const aDefault: T); overload;

    class operator In(aLeft, aRight: Nullable<T>): Boolean;
    class operator NotEqual(aLeft, aRight: Nullable<T>): Boolean;
    class operator Equal(aLeft, aRight: Nullable<T>): Boolean;
    class operator GreaterThan(aLeft, aRight: Nullable<T>): Boolean;
    class operator GreaterThanOrEqual(aLeft, aRight: Nullable<T>): Boolean;
    class operator LessThan(aLeft, aRight: Nullable<T>): Boolean;
    class operator LessThanOrEqual(aLeft, aRight: Nullable<T>): Boolean;
    class operator Implicit(a : T) : Nullable<T>;
    class operator Implicit(a : Nullable<T>): T;
    class operator Explicit(aValue: Nullable<T>): T;


    class operator Add(a,b: Nullable<T>): Nullable<T>;
    class operator Subtract(a, b: Nullable<T>) : Nullable<T>;
    class operator Multiply(a,b: Nullable<T>): Nullable<T>;
    class operator Divide(a,b: Nullable<T>): Nullable<T>; overload;
  end;

const
  UNIT_NAME = 'NullableTypes';

implementation

uses
  TypInfo, Generics.Defaults, uWrapper.Generics.Casts;

{ Nullable<T> }

function Nullable<T>.GetHasDefault: Boolean;
begin
  Result := FInitDefault = 'I';
end;

function Nullable<T>.GetHasValue: Boolean;
begin
  Result := not IsNull;
end;

function Nullable<T>.GetIsNull: boolean;
begin
  Result := FInitValue <> 'I';
end;

function Nullable<T>.GetIsNotNull: Boolean;
begin
  Result := FIsNotNull;
end;

function Nullable<T>.GetValue: T;
begin
//  CheckType;
//  CheckValue;
//  Result := fValue;
//  if HasValue then
    Result := FValue;
//  else
//    Result := Default(T);
end;

procedure Nullable<T>.SetDefault(const aDefault: T);
begin
  FDefault := aDefault;
  FInitDefault := 'I';
  if IsNull then
    FValue := aDefault;
end;

procedure Nullable<T>.SetModified(const Value: Boolean);
begin
  FModified := Value;
end;

procedure Nullable<T>.SetValue(const AValue: T);
var
  Comparer: IEqualityComparer<T>;
begin
  Comparer := TEqualityComparer<T>.Default;
  if (HasValue) or (not Comparer.Equals(FValue, AValue)) then
    FModified := True;

  FInitValue := 'I';
  FValue := AValue;
  FIsNotNull := False;
end;

class operator Nullable<T>.Implicit(a: Nullable<T>): T;
begin
  Result := a.Value;
end;

class operator Nullable<T>.In(aLeft, aRight: Nullable<T>): Boolean;
var
  info: PTypeInfo;
  aIItem, bIItem: Integer;
  aSItem, bSItem: String;
begin
    Info := TypeInfo(T);
    Result := False;
    case info^.Kind of
      tkInteger:
        begin
          aIItem  := GenericAsInteger(aLeft);
          bIItem  := GenericAsInteger(aRight);
          Result := aIItem in [0 .. bIItem];
        end;
      tkUString,tkString:
        begin
          aSItem := GenericAsString(aLeft);
          bSItem := GenericAsString(aRight);
          Result := (Pos(aSItem, bSItem)>0);
        end;
    end;
end;

class operator Nullable<T>.LessThan(aLeft, aRight: Nullable<T>): Boolean;
var
  Comparer: IComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TComparer<T>.Default;
    Result   := (Comparer.Compare(aLeft, aRight) < 0);
  end else
    Result := ALeft.HasValue = aRight.HasValue;

end;

class operator Nullable<T>.LessThanOrEqual(aLeft, aRight: Nullable<T>): Boolean;
var
  Comparer: IComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TComparer<T>.Default;
    Result := (Comparer.Compare(aLeft, aRight) <= 0);
  end else
    Result := ALeft.HasValue = aRight.HasValue;

end;

class operator Nullable<T>.NotEqual(ALeft, ARight: Nullable<T>): Boolean;
var
  Comparer: IEqualityComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TEqualityComparer<T>.Default;
    Result := not Comparer.Equals(ALeft.Value, ARight.Value);
  end else
    Result := ALeft.HasValue <> ARight.HasValue;
end;

class operator Nullable<T>.Implicit(a: T): Nullable<T>;
begin
  Result.Value := a;
end;

class function Nullable<T>.CastBack(const aValue): T;
begin
  Result := T(aValue);
end;

class function Nullable<T>.AddInt(const aInt, bInt): T;
var
  value: Integer;
begin
  value := Integer(aInt) + Integer(bInt);
  Result := CastBack(value);
end;

class function Nullable<T>.AddInt64(const aInt64, bInt64): T;
var
  value: Int64;
begin
  value := Int64(aInt64) + Int64(bInt64);
  Result := CastBack(value);
end;

class function Nullable<T>.AddFloat(const aFloat, bFloat): T;
var
  value: Double;
begin
  value := Double(aFloat) + Double(bFloat);
  Result := CastBack(value);
end;

class function Nullable<T>.AddString(const aString, bString): T;
var
  value: AnsiString;
begin
  value := AnsiString(aString) + AnsiString(bString);
  Result := CastBack(value);
end;

class function Nullable<T>.AddUString(const aUString, bUString): T;
var
  value: String;
begin
  value := String(aUString) + String(bUString);
  Result := CastBack(value);
end;

class function Nullable<T>.AddBoolean(const aBoolean, bBoolean): T;
var
  value: Boolean;
begin
  value := Boolean(aBoolean) and Boolean(bBoolean);
  Result := CastBack(value);
end;

class function Nullable<T>.SubtractInt(const aInt, bInt): T;
var
  value: Integer;
begin
  value := Integer(aInt) - Integer(bInt);
  Result := CastBack(value);
end;

class function Nullable<T>.SubtractFloat(const aFloat, bFloat): T;
var
  value: Double;
begin
  value := Double(aFloat) - Double(bFloat);
  Result := CastBack(value);
end;

class function Nullable<T>.SubtractInt64(const aInt64, bInt64): T;
var
  value: Int64;
begin
  value := Int64(aInt64) - Int64(bInt64);
  Result := CastBack(value);
end;

class function Nullable<T>.MultiplyInt(const aInt, bInt): T;
var
  value: Integer;
begin
  value := Integer(aInt) * Integer(bInt);
  Result := CastBack(value);
end;

class function Nullable<T>.MultiplyFloat(const aFloat, bFloat): T;
var
  value: Double;
begin
  value := Double(aFloat) * Double(bFloat);
  Result := CastBack(value);
end;

class function Nullable<T>.MultiplyInt64(const aInt64, bInt64): T;
var
  value: Int64;
begin
  value := Int64(aInt64) * Int64(bInt64);
  Result := CastBack(value);
end;

class function Nullable<T>.DivideInt(const aInt, bInt): T;
var
  value: Integer;
begin
  value := Integer(aInt) div Integer(bInt);
  Result := CastBack(value);
end;

class function Nullable<T>.DivideFloat(const aFloat, bFloat): T;
var
  value: Double;
begin
  value := Double(aFloat) / Double(bFloat);
  Result := CastBack(value);
end;

class function Nullable<T>.DivideInt64(const aInt64, bInt64): T;
var
  value: Int64;
begin
  value := Int64(aInt64) div Int64(bInt64);
  Result := CastBack(value);
end;

class operator Nullable<T>.Add(a, b: Nullable<T>): Nullable<T>;
var
  info: PTypeInfo;
begin
  if a.IsNull or b.IsNull then
    Result.ClearValue
  else
  begin
    Info := TypeInfo(T);
    case info^.Kind of
      tkInteger: Result.Value := AddInt(a.FValue, b.FValue);
      tkFloat: Result.Value := AddFloat(a.FValue, b.FValue);
      tkString: Result.Value := AddString(a.FValue, b.FValue);
      tkInt64: Result.Value := AddInt64(a.FValue, b.FValue);
      tkUString: Result.Value := AddUString(a.FValue, b.FValue);
      tkEnumeration: Result.Value := AddBoolean(a.FValue, b.FValue);
    end;
  end;
end;

class operator Nullable<T>.Subtract(a, b: Nullable<T>): Nullable<T>;
var
  info: PTypeInfo;
begin
  if a.IsNull or b.IsNull then
    Result.ClearValue
  else
  begin
    Info := TypeInfo(T);
    case info^.Kind of
      tkInteger: Result.Value := SubtractInt(a.FValue, b.FValue);
      tkFloat: Result.Value := SubtractFloat(a.FValue, b.FValue);
      tkString: Result.ClearValue;
      tkInt64: Result.Value := SubtractInt64(a.FValue, b.FValue);
      tkUString: Result.ClearValue;
      tkEnumeration: Result.ClearValue;
    end;
  end;
end;

class operator Nullable<T>.GreaterThan(aLeft, aRight: Nullable<T>): Boolean;
var
  Comparer: IComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TComparer<T>.Default;
    Result   := (Comparer.Compare(aLeft, aRight) > 0);
  end else
    Result := ALeft.HasValue = aRight.HasValue;
end;

class operator Nullable<T>.GreaterThanOrEqual(aLeft,
  aRight: Nullable<T>): Boolean;
var
  Comparer: IComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TComparer<T>.Default;
    Result := (Comparer.Compare(aLeft, aRight) >= 0);
  end else
    Result := ALeft.HasValue = aRight.HasValue;
end;

class operator Nullable<T>.Multiply(a, b: Nullable<T>): Nullable<T>;
var
  info: PTypeInfo;
begin
  if a.IsNull or b.IsNull then
    Result.ClearValue
  else
  begin
    Info := TypeInfo(T);
    case info^.Kind of
      tkInteger: Result.Value := MultiplyInt(a.FValue, b.FValue);
      tkFloat: Result.Value := MultiplyFloat(a.FValue, b.FValue);
      tkString: Result.ClearValue;
      tkInt64: Result.Value := MultiplyInt64(a.FValue, b.FValue);
      tkUString: Result.ClearValue;
      tkEnumeration: Result.ClearValue;
    end;
  end;
end;

class operator Nullable<T>.Divide(a, b: Nullable<T>): Nullable<T>;
var
  info: PTypeInfo;
begin
  if a.IsNull or b.IsNull then
    Result.ClearValue
  else
  begin
    Info := TypeInfo(T);
    case info^.Kind of
      tkInteger: Result.Value := DivideInt(a.FValue, b.FValue);
      tkFloat: Result.Value := DivideFloat(a.FValue, b.FValue);
      tkString: Result.ClearValue;
      tkInt64: Result.Value := DivideInt64(a.FValue, b.FValue);
      tkUString: Result.ClearValue;
      tkEnumeration: Result.ClearValue;
    end;
  end;
end;

procedure Nullable<T>.ClearValue;
begin
  if HasValue then
    FModified := True;

  FInitValue := '';
  FIsNotNull := False;
end;

procedure Nullable<T>.SetNullValue;
begin
  FModified := True;
  FInitValue := '';
end;

procedure Nullable<T>.SetNotNullValue;
begin
  FInitValue := 'I';
  FModified := True;
  FIsNotNull := True;
end;

constructor Nullable<T>.Create(const aValue: T);
begin
  SetValue(aValue);
  FModified := False;
  FIsNotNull := False;
end;

constructor Nullable<T>.Create(const aValue, aDefault: T);
begin
  SetValue(aValue);
  SetDefault(aDefault);
  FIsNotNull := False;
end;

class operator Nullable<T>.Equal(aLeft, aRight: Nullable<T>): Boolean;
var
  Comparer: IEqualityComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TEqualityComparer<T>.Default;
    Result := Comparer.Equals(aLeft.Value, aRight.Value);
  end else
    Result := ALeft.HasValue = aRight.HasValue;
end;

class operator Nullable<T>.Explicit(aValue: Nullable<T>): T;
begin
  Result := aValue.Value;
end;

end.
