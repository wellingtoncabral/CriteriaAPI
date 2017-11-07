unit uWrapper.Generics.Casts;

interface

uses Windows;

function GenericAsString(const Value): string; inline;
function GenericAsInteger(const Value): Integer; inline;
function GenericAsInt64(const Value): Int64; inline;
function GenericAsChar(const Value): Char; inline;
function GenericAsWChar(const Value): WChar; inline;
function GenericAsDouble(const Value): Double; inline;

implementation

function GenericAsString(const Value): string;
begin
  Result := string(Value);
end;

function GenericAsInteger(const Value): Integer;
begin
  Result := Integer(Value);
end;

function GenericAsDouble(const Value): Double;
begin
  Result := Double(Value);
end;

function GenericAsInt64(const Value): Int64; inline;
begin
  Result := Int64(Value);
end;

function GenericAsChar(const Value): Char; inline;
begin
  Result := Char(Value);
end;

function GenericAsWChar(const Value): WChar; inline;
begin
  Result := WChar(Value);
end;

end.
