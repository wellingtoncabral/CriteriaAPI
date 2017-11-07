unit uSQLParse;

interface

uses
  Rtti,
  SysUtils,
  uCriteria.Annotation,
  uCriteria.Utils,
  Classes;
type
  // Referência para método anônimo
  TRttiPropertySequence = reference to procedure(RttiProperty: TRttiProperty; ASequenceName: string);

  TORMSqlParse = class
  private
    class procedure Split(Delimiter: Char; Str: string; ListOfStrings: TStrings);
  public
    class function ForEachPropertyForSqlInsert<T: class>(Obj: T;
      RttiAttributeSequence: TRttiPropertySequence): string;

    class function GetSelectSql(AClassInfo: Pointer): string;
    class function GetPrimaryKeyProperty(AClassInfo: Pointer): string;
    class function GetInsertSql<T: class>(Obj: T): string;
    class function GetUpdateSql<T: class>(Obj: T): string;
    class function GetDeleteSql<T: class>(Obj: T): string;
    class function GetSelectCountSql(AClassInfo: Pointer): string;
    class function GetTableName(AClassInfo: Pointer): string;
    class function GetJoinTable(AClassInfo: Pointer): string;
  end;

const
  C_SQL_SELECT = 'SELECT %s FROM %s';
  C_SQL_COUNT = 'SELECT COUNT(*) AS CONTADOR FROM %s';
  C_SQL_DELETE = 'DELETE FROM %s';
  C_SQL_DELETE_WITH_WHERE = 'DELETE FROM %s WHERE %s';
  C_SQL_UPDATE = 'UPDATE %s SET %s';
  C_SQL_UPDATE_WITH_WHERE = 'UPDATE %s SET %s WHERE %s';
  C_SQL_INSERT = 'INSERT INTO %s (%s) VALUES (%s)';
  C_JOIN_TABLE = '%s.%s = %s.%s';

implementation

{ TORMSqlParse }

class function TORMSqlParse.ForEachPropertyForSqlInsert<T>(Obj: T;
  RttiAttributeSequence: TRttiPropertySequence): string;
var
  LColumnsSql, LValuesSql: TStringBuilder;
  LColumnAux: string;
  CreateColumn: Boolean;
begin
  LColumnsSql := TStringBuilder.Create;
  LValuesSql  := TStringBuilder.Create;
  try
    TORMUtils.ForEachProperty(Obj.ClassInfo,
      procedure(RttiProperty: TRttiProperty)
      var
        LAttr, LColumnAttr: TCustomAttribute;
      begin
        LColumnAttr  := nil;
        CreateColumn := True;
        for LAttr in RttiProperty.GetAttributes do
        begin
          if (LAttr is TColumn) and (CreateColumn) then
          begin
            LColumnAttr := LAttr;
          end
          else
          if (LAttr is TSequence) then
          begin
            if ((LAttr as TSequence).Name <> EmptyStr) then
            begin
              if Assigned(RttiAttributeSequence) then
              begin
                RttiAttributeSequence(RttiProperty, (LAttr as TSequence).Name);
              end;
            end
            else
            begin
              { A coluna é anotada como uma sequence, porém o valor não será
                gerado pelo ORM (possivelmente uma Trigger de BD). }
              CreateColumn := False;
            end;
          end;
        end;

        if Assigned(LColumnAttr) then
        begin
          LColumnsSql.Append((LColumnAttr as TColumn).Name).Append(',');
          LValuesSql.Append(TORMUtils.GetPropertyValue(RttiProperty, Obj)).Append(',');
        end;
      end
    );

    // Remove última virgula
    LColumnsSql.Remove(LColumnsSql.Length - 1, 1);
    LValuesSql.Remove(LValuesSql.Length - 1, 1);

    Result := Format(
      C_SQL_INSERT, [GetTableName(Obj.ClassInfo), LColumnsSql.ToString,
      LValuesSql.ToString]);

  finally
    LColumnsSql.Free;
    LValuesSql.Free;
  end;
end;

class function TORMSqlParse.GetDeleteSql<T>(Obj: T): string;
var
  LColumn, LValue, LTableName: string;
  LWhereSql: TStringBuilder;
begin
  LColumn   := '';
  LValue    := '';

  LTableName := GetTableName(Obj.ClassInfo);
  if (LTableName = '') then Exit;

  LWhereSql := TStringBuilder.Create;
  try
    TORMUtils.ForEachProperty(Obj.ClassInfo,
      procedure(RttiProperty: TRttiProperty)
      var
        LAttr: TCustomAttribute;
        LIsPrimaryKey: Boolean;
      begin
        LColumn := '';
        LIsPrimaryKey := False;
        for LAttr in RttiProperty.GetAttributes do
        begin
          if (LAttr is TColumn) then
          begin
            if (LIsPrimaryKey) then
            begin
              LColumn := (LAttr as TColumn).Name + ' = ';
              LValue  := TORMUtils.GetPropertyValue(RttiProperty, Obj) + ' AND ';
              LWhereSql.Append(LColumn).Append(LValue);
            end;
          end
          else
          if (LAttr is TPrimaryKey) then
          begin
            LIsPrimaryKey := True;
          end;
        end;
      end
    );

    // Remove último AND
    LWhereSql.Remove(LWhereSql.Length - 4, 4);

    if (LWhereSql.ToString = '') then
      Result := Format(C_SQL_DELETE, [LTableName])
    else
      Result := Format(
        C_SQL_DELETE_WITH_WHERE, [LTableName, LWhereSql.ToString]);
  finally
    LWhereSql.Free;
  end;
end;

class function TORMSqlParse.GetInsertSql<T>(Obj: T): string;
begin
  Result := ForEachPropertyForSqlInsert<T>(Obj, nil);
end;

class function TORMSqlParse.GetJoinTable(AClassInfo: Pointer): string;

var
  LRttiContext: TRttiContext;
  LRttiType: TRttiType;
  LRttiAttr: TCustomAttribute;
  LJoinTable: TJoinTable;
  LReferences, LJoinTableStr: TStringBuilder;
  LTableTargetStr: string;
  LFieldsLeft, LFieldsRight: TStringList;
  i: Integer;
begin
  LRttiContext := TRttiContext.Create;
  LFieldsLeft  := TStringList.Create;
  LFieldsRight := TStringList.Create;
  try
    LRttiType := LRttiContext.GetType(AClassInfo);

    LReferences   := TStringBuilder.Create;
    LJoinTableStr := TStringBuilder.Create;
    try
      for LRttiAttr in LRttiType.GetAttributes do
      begin
        if (LRttiAttr is TJoinTable) then
        begin
          LJoinTableStr.Clear;

          LJoinTable := (LRttiAttr as TJoinTable);
          LTableTargetStr := LJoinTable.TableTarget;

          // Prepara SQL para relacionamentos
          case LJoinTable.ReferenceType of
            rtInner: LJoinTableStr.Append('INNER JOIN ');
            rtLeft : LJoinTableStr.Append('LEFT JOIN ');
          end;

          // Prepara String com o relacionamento entras as tabelas
          LJoinTableStr.Append(LJoinTable.TableTarget).Append(' ON (');

          Split(';', LJoinTable.ColumnsSource, LFieldsLeft);
          Split(';', LJoinTable.ColumnsTarget, LFieldsRight);

          if (LFieldsLeft.Count <> LFieldsRight.Count) then
          begin
            raise Exception.Create('Parâmetros de anotação de columas TJoinTable incorreto.');
          end;

          for i := 0 to LFieldsLeft.Count - 1 do
          begin
            if (i > 0) then
            begin
              LJoinTableStr.Append(' AND ');
            end;

            LJoinTableStr.AppendFormat(
              C_JOIN_TABLE,
              [LJoinTable.TableSource, Trim(LFieldsLeft[i]),
              LJoinTable.TableTarget, Trim(LFieldsRight[i])]
            );

          end;

          LJoinTableStr.Append(')');

          // Verifica se a referencia já foi adicionada
          if Pos(LJoinTableStr.ToString, LReferences.ToString) = 0 then
          begin
            LReferences.AppendLine.Append(LJoinTableStr.ToString);
          end;

        end;
      end;

      Result := LReferences.ToString;
    finally
      FreeAndNil(LReferences);
      FreeAndNil(LJoinTableStr);
    end;
  finally
    LRttiContext.Free;
    FreeAndNil(LFieldsLeft);
    FreeAndNil(LFieldsRight);
  end;
end;

class function TORMSqlParse.GetPrimaryKeyProperty(AClassInfo: Pointer): string;
var
  Column: string;
begin
  Column := '';
  TORMUtils.ForEachProperty(AClassInfo,
    procedure(RttiProperty: TRttiProperty)
    var
      LAttr: TCustomAttribute;
    begin
      for LAttr in RttiProperty.GetAttributes do
      begin
        if (LAttr is TPrimaryKey) then
        begin
          Column := RttiProperty.Name;
        end;
      end;
    end
  );

  Result := Column;
end;

class function TORMSqlParse.GetSelectCountSql(AClassInfo: Pointer): string;
begin
  Result := Format(C_SQL_COUNT, [GetTableName(AClassInfo)]);
end;

class function TORMSqlParse.GetSelectSql(AClassInfo: Pointer): string;
var
  LTableSourceStr, LTableTargetStr: string;
  LSQL, LReferences: TStringBuilder;
begin
  LTableSourceStr := GetTableName(AClassInfo);

  // Não tem tabela?
  if (LTableSourceStr = '') then Exit;

  LSQL        := TStringBuilder.Create;
  LReferences := TStringBuilder.Create;
  try
    TORMUtils.ForEachProperty(AClassInfo,
      procedure(RttiProperty: TRttiProperty)
      var
        LAttr: TCustomAttribute;
        LColumn: string;
      begin
        LColumn         := EmptyStr;

        for LAttr in RttiProperty.GetAttributes do
        begin
          LTableTargetStr := LTableSourceStr;

          // É coluna?
          if (LAttr is TColumnBase) then
          begin
            if (LAttr is TJoinColumn) then
            begin
              LTableTargetStr := (LAttr as TJoinColumn).TableName;
            end;

            LColumn := LTableTargetStr + '.' + (LAttr as TColumnBase).Name + ' as ' + RttiProperty.Name;
          end;
        end;

        if (LColumn <> EmptyStr) then
        begin
          LSQL.Append(LColumn).Append(',');
        end;
      end
    );

    // Remove última virgula
    LSQL.Remove(LSQL.Length - 1, 1);

    Result := Format(C_SQL_SELECT, [LSQL.ToString,
      LTableSourceStr + GetJoinTable(AClassInfo)]);
  finally
    LSQL.Free;
    LReferences.Free;
  end;
end;

class function TORMSqlParse.GetTableName(AClassInfo: Pointer): string;
var
  LRttiType: TRttiType;
  LRttiAttr: TCustomAttribute;
  Ctx: TRttiContext;
begin
  Ctx := TRttiContext.Create;
  try
    LRttiType := Ctx.GetType(AClassInfo);

    for LRttiAttr in LRttiType.GetAttributes do
    begin
      if (LRttiAttr is TTable) then
        Exit((LRttiAttr as TTable).Name);
    end;
  finally
    Ctx.Free;
  end;
end;

class function TORMSqlParse.GetUpdateSql<T>(Obj: T): string;
var
  LWhereSql, LValueColumnSql: TStringBuilder;
  LColumn, LValue, LTableName: string;
  i: Integer;
begin
  LColumn := '';
  LValue  := '';

  LTableName := GetTableName(Obj.ClassInfo);
  if (LTableName = '') then Exit;

  LWhereSql       := TStringBuilder.Create;
  LValueColumnSql := TStringBuilder.Create;
  try
    TORMUtils.ForEachProperty(Obj.ClassInfo,
      procedure(RttiProperty: TRttiProperty)
      var
        LAttr: TCustomAttribute;
        LReference, LAddColumn, LIsPrimaryKey: Boolean;
      begin
        LReference    := False;
        LAddColumn    := False;
        LIsPrimaryKey := False;

        for LAttr in RttiProperty.GetAttributes do
        begin
          if (LAttr is TColumn) then
          begin
            LColumn := (LAttr as TColumn).Name + ' = ';
            LValue  := TORMUtils.GetPropertyValue(RttiProperty, Obj);

            if (LIsPrimaryKey) then
            begin
              LWhereSql.Append(LColumn).Append(LValue).Append(' AND ');
            end
            else
            begin
              LValue := LValue + ', ';

              // Adicionou a coluna
              LAddColumn := True;
            end;
          end
          else
          if (LAttr is TPrimaryKey) then
          begin
            LIsPrimaryKey := True;
          end
          else
          if (LAttr is TJoinTable) then
          begin
            LReference := True;
          end;
        end;

        // Só adiciona a coluna se não for uma referencia
        if (not LReference and LAddColumn) then
        begin
          LValueColumnSql.Append(LColumn).Append(LValue);
        end;
      end
    );

    // Remove última virgula
    LValueColumnSql.Remove(LValueColumnSql.Length - 2, 2);
    // Remove último AND
    LWhereSql.Remove(LWhereSql.Length - 4, 4);

    if (LWhereSql.ToString = '') then
      Result := Format(
        C_SQL_UPDATE, [LTableName, LValueColumnSql.ToString])
    else
      Result := Format(
        C_SQL_UPDATE_WITH_WHERE, [LTableName,
        LValueColumnSql.ToString, LWhereSql.ToString]);
  finally
    LWhereSql.Free;
    LValueColumnSql.Free;
  end;
end;

class procedure TORMSqlParse.Split(Delimiter: Char; Str: string;
  ListOfStrings: TStrings);
begin
  ListOfStrings.Clear;
  ListOfStrings.Delimiter       := Delimiter;
  ListOfStrings.StrictDelimiter := True;
  ListOfStrings.DelimitedText   := Str;
end;

end.
