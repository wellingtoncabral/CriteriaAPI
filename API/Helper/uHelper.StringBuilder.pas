unit uHelper.StringBuilder;

interface

uses
  SysUtils;

type
  TAGStringBuilder = class Helper for TStringBuilder
  public
    function _replace(const OldValue: string;
      const NewValue: string): TStringBuilder; overload;

    function _replace(const OldValue: string; const NewValue: string;
      PosIni: Integer; Size: Integer): TStringBuilder; overload;

    function _replace(const OldChar : Char;
      const NewChar: Char): TStringBuilder; overload;

    function _replace(const OldChar : Char; const NewChar: Char;
      PosIni: Integer; Size: Integer): TStringBuilder; overload;
  end;

implementation

{ TAGStringBuilder }

function TAGStringBuilder._Replace(const OldValue,
  NewValue: string): TStringBuilder;
var
  Text: string;
begin
  Text := Self.ToString;
  Self.Clear;
  Self.Append(StringReplace(Text, OldValue, NewValue, [rfReplaceAll]));
  Result := Self;
end;

function TAGStringBuilder._Replace(const OldValue: string;
  const NewValue: string; PosIni: Integer; Size: Integer): TStringBuilder;
begin
  Result := Self._Replace(OldValue, NewValue);
end;

function TAGStringBuilder._Replace(const OldChar,
  NewChar: Char): TStringBuilder;
begin
  Result := Self._Replace(OldChar, NewChar);
end;

function TAGStringBuilder._Replace(const OldChar, NewChar: Char; PosIni,
  Size: Integer): TStringBuilder;
begin
  Result := Self._Replace(OldChar, NewChar);
end;


end.
