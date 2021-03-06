unit uCriteria.Utils;

interface

uses
  DB,
  SysUtils,
  TypInfo,
  Classes,
  Rtti,
  Generics.Collections,
  uWrapper.NullableTypes,
  uCriteria.Annotation;

type

  TORMFieldType = (oftUnknown, oftString, oftInteger, oftRecord, oftDate, oftDateTime,
    oftDecimal, oftFloat, oftTime, oftBoolean, oftBlob);

  TRttiPropertyMsg = reference to procedure(RttiProperty: TRttiProperty);

  TORMUtils = class sealed
  private
    class var Ctx: TRttiContext;
  public
    class function DateTimeToStrDBFormat(Value: TDateTime): string;

    class function GetHandleType(Handle: PTypeInfo): TORMFieldType;
    class function GetFieldType(AField: TRttiField): TORMFieldType;
    class function GetPropertyType(AProp: TRttiProperty): TORMFieldType;

    class function GetHandleValue(Handle: PTypeInfo; Value: TValue): string;
    class function GetPropertyValue(AProp: TRttiProperty; Obj: TObject): string;
    class function GetFieldValue(AField: TRttiField; Obj: TObject): string;

    class function GetProperty(AClassInfo: Pointer; Name: string): TRttiProperty;

    class function GetColumnName(AClassInfo: Pointer; PropertyName: string): string; overload;
    class function GetColumnName(RttiProperty: TRttiProperty): string; overload;
    class function GetColumnValueByType(AClassInfo: Pointer; PropertyName: string; Value: TValue): string;

    class function DataSetToObjectList<T: class, constructor>(
      DataSet: TDataSet; AOwnsObjects: Boolean = True): TObjectList<T>;

    class procedure ForEachProperty(AClassInfo: Pointer; RttiAttributeMsg: TRttiPropertyMsg);

    class function PropertyIsNullable(ARecord: TRttiRecordType): Boolean;

    class function CreateObject(ARttiType: TRttiType): TObject;
    class function Clone(Obj: TObject): TObject;
    class procedure CopyObject(SourceObj, TargetObj: TObject);

  end;

const
  C_DB_DATE_TIME_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

implementation

uses
  Variants;

{ TORMUtils }


class function TORMUtils.Clone(Obj: TObject): TObject;
var
  RttiType: TRttiType;
  Field: TRttiField;
  Master, Cloned: TObject;
  Src: TObject;
  SourceStream: TStream;
  SavedPosition: Int64;
  TargetStream: TStream;
  TargetCollection: TObjectList<TObject>;
  SourceCollection: TObjectList<TObject>;
  I: Integer;
  SourceObject: TObject;
  TargetObject: TObject;
  ClonedValue: TValue;
begin
  Result := nil;
  if not Assigned(Obj) then
  begin
    Exit;
  end;

  RttiType := ctx.GetType(Obj.ClassType);
  Cloned := CreateObject(RttiType);
  Master := Obj;

  for Field in RttiType.GetFields do
  begin
    if not Field.FieldType.IsInstance then
    begin
      Field.SetValue(Cloned, Field.GetValue(Master));
    end
    else
    begin
      Src := Field.GetValue(Obj).AsObject;
      if Src is TStream then
      begin
        SourceStream := TStream(Src);
        SavedPosition := SourceStream.Position;
        SourceStream.Position := 0;

        ClonedValue := Field.GetValue(Cloned);
        if ClonedValue.IsEmpty then
        begin
          TargetStream := TMemoryStream.Create;
          Field.SetValue(Cloned, TargetStream);
        end
        else
        begin
          TargetStream := ClonedValue.AsObject as TStream;
        end;
        TargetStream.Position := 0;
        TargetStream.CopyFrom(SourceStream, SourceStream.Size);
        TargetStream.Position := SavedPosition;
        SourceStream.Position := SavedPosition;
      end
      else
      if Src is TObjectList<TObject> then
      begin
        SourceCollection := TObjectList<TObject>(Src);

        ClonedValue := Field.GetValue(Cloned);
        if ClonedValue.IsEmpty then
        begin
          TargetCollection := TObjectList<TObject>.Create;
          Field.SetValue(Cloned, TargetCollection);
        end
        else
        begin
          TargetCollection := ClonedValue.AsObject as TObjectList<TObject>;
        end;
        for I := 0 to SourceCollection.Count - 1 do
        begin
          TargetCollection.Add(Clone(SourceCollection[I]));
        end;
      end
      else
      begin
        SourceObject := Src;

        ClonedValue := Field.GetValue(Cloned);

        if ClonedValue.IsEmpty then
        begin
          TargetObject := Clone(SourceObject);
          Field.SetValue(Cloned, TargetObject);
        end
        else
        begin
          TargetObject := ClonedValue.AsObject;
          TORMUtils.CopyObject(SourceObject, TargetObject);
        end;
        Field.SetValue(Cloned, TargetObject);
      end;
    end;
  end;
  Result := Cloned;
end;

class procedure TORMUtils.CopyObject(SourceObj, TargetObj: TObject);
var
  RttiType: TRttiType;
  Field: TRttiField;
  Master, Cloned: TObject;
  Src: TObject;
  SourceStream: TStream;
  SavedPosition: Int64;
  TargetStream: TStream;
  TargetCollection: TObjectList<TObject>;
  SourceCollection: TObjectList<TObject>;
  I: Integer;
  SourceObject: TObject;
  TargetObject: TObject;
  ClonedValue: TValue;
begin
  if not Assigned(TargetObj) then
    Exit;

  RttiType := ctx.GetType(SourceObj.ClassType);
  Cloned := TargetObj;
  Master := SourceObj;

  for Field in RttiType.GetFields do
  begin
    if not Field.FieldType.IsInstance then
    begin
      Field.SetValue(Cloned, Field.GetValue(Master));
    end
    else
    begin
      Src := Field.GetValue(SourceObj).AsObject;
      if Src is TStream then
      begin

        SourceStream  := TStream(Src);
        SavedPosition := SourceStream.Position;
        SourceStream.Position := 0;

        ClonedValue := Field.GetValue(Cloned);

        if ClonedValue.IsEmpty then
        begin
          TargetStream := TMemoryStream.Create;
          Field.SetValue(Cloned, TargetStream);
        end
        else
        begin
          TargetStream := ClonedValue.AsObject as TStream;
        end;

        TargetStream.Position := 0;
        TargetStream.CopyFrom(SourceStream, SourceStream.Size);
        TargetStream.Position := SavedPosition;
        SourceStream.Position := SavedPosition;
      end
      else
      if Src is TObjectList<TObject> then
      begin
        SourceCollection := TObjectList<TObject>(Src);

        ClonedValue := Field.GetValue(Cloned);

        if ClonedValue.IsEmpty then
        begin
          TargetCollection := TObjectList<TObject>.Create;
          Field.SetValue(Cloned, TargetCollection);
        end
        else
        begin
          TargetCollection := ClonedValue
            .AsObject as TObjectList<TObject>;
        end;

        for I := 0 to SourceCollection.Count - 1 do
        begin
          TargetCollection.Add(TORMUtils.Clone(SourceCollection[I]));
        end;
      end
      else
      begin
        SourceObject := Src;
        ClonedValue  := Field.GetValue(Cloned);

        if ClonedValue.IsEmpty then
        begin
          TargetObject := TORMUtils.Clone(SourceObject);
          Field.SetValue(Cloned, TargetObject);
        end
        else
        begin
          TargetObject := ClonedValue.AsObject;
          TORMUtils.CopyObject(SourceObject, TargetObject);
        end;
      end;
    end;
  end;
end;


class function TORMUtils.CreateObject(ARttiType: TRttiType): TObject;
var
  Method: TRttiMethod;
  MetaClass: TClass;
begin
  { First solution, clear and slow }
  MetaClass := nil;
  Method    := nil;
  for Method in ARttiType.GetMethods do
  begin
    if Method.HasExtendedInfo and Method.IsConstructor then
    begin
      if length(Method.GetParameters) = 0 then
      begin
        MetaClass := ARttiType.AsInstance.MetaclassType;
        Break;
      end;
    end;
  end;
  if Assigned(MetaClass) then
  begin
    Result := Method.Invoke(MetaClass, []).AsObject;
  end
  else
  begin
    raise Exception.Create('Cannot find a propert constructor for ' +
      ARttiType.ToString);
  end;

  { Second solution, dirty and fast }
  // Result := TObject(ARttiType.GetMethod('Create')
  // .Invoke(ARttiType.AsInstance.MetaclassType, []).AsObject);
end;

class function TORMUtils.DataSetToObjectList<T>(DataSet: TDataSet;
  AOwnsObjects: Boolean): TObjectList<T>;
var
  i: Integer;
  Item: T;
  FieldName: string;

  NI : Nullable<Integer>;
  NN : Nullable<Double>;
  NC : Nullable<Currency>;
  NS : Nullable<string>;
  NB : Nullable<Boolean>;
  ND : Nullable<TDate>;
  NDT: Nullable<TDateTime>;
begin
  Result := TObjectList<T>.Create(AOwnsObjects);

  if Assigned(DataSet) and (DataSet.Active) then
  begin
    DataSet.DisableControls;
    try
      DataSet.First;
      while not DataSet.Eof do
      begin
        Item := T.Create;

        for i := 0 to DataSet.Fields.Count - 1 do
        begin
          FieldName := DataSet.Fields[i].FieldName;

          Self.ForEachProperty(Item.ClassInfo,
            procedure(RttiProperty: TRttiProperty)
            var
      	      PropertyType: TORMFieldType;
              RecVal: TValue;
              RttiRecord: TRttiRecordType;
              RttiFieldAux: TRttiField;
              ModifiedValue: TValue;
              InitValue: TValue;
            begin
              if UpperCase(FieldName) = UpperCase(RttiProperty.Name) then
              begin
                if (not VarIsNull(DataSet.Fields[i].Value)) and
                   (not VarIsEmpty(DataSet.Fields[i].Value)) then
                begin
        	        PropertyType := GetPropertyType(RttiProperty);

                  if (PropertyType <> oftRecord) then
                  begin
                    if PropertyType in [oftDate, oftDateTime] then
                    begin
                      RecVal := DataSet.Fields[i].AsDateTime;
                    end
                    else
                    begin
                      RecVal := TValue.FromVariant(DataSet.Fields[i].Value);
                    end;

                    RttiProperty.SetValue(TObject(Item), RecVal);								
                  end
                  else
                  begin
                    RttiRecord   := Ctx.GetType(RttiProperty.GetValue(
                      TObject(Item)).TypeInfo).AsRecord;

                    RttiFieldAux := RttiRecord.GetField('FValue');

                    // Is a Nullable Record?
                    if Assigned(RttiFieldAux) then
                    begin
                      case GetHandleType(RttiFieldAux.FieldType.Handle) of
                        oftString:
                        begin
                          NS     := DataSet.Fields[i].AsString;
                          RecVal := TValue.From<Nullable<string>>(NS);
                        end;

                        oftInteger:
                        begin
                          NI     := DataSet.Fields[i].AsInteger;
                          RecVal := TValue.From<Nullable<Integer>>(NI);
                        end;

                        oftFloat:
                        begin
                          NN     := DataSet.Fields[i].AsFloat;
                          RecVal := TValue.From<Nullable<Double>>(NN);
                        end;

                        oftDecimal:
                        begin
                          NC     := DataSet.Fields[i].AsCurrency;
                          RecVal := TValue.From<Nullable<Currency>>(NC);
                        end;

                        oftDate:
                        begin
                          ND     := DataSet.Fields[i].AsDateTime;
                          RecVal := TValue.From<Nullable<TDate>>(ND);
                        end;

                        oftDateTime:
                        begin
                          NDT    := DataSet.Fields[i].AsDateTime;
                          RecVal := TValue.From<Nullable<TDateTime>>(NDT);
                        end;

                        oftBoolean:
                        begin
                          NB     := DataSet.Fields[i].AsBoolean;
                          RecVal := TValue.From<Nullable<Boolean>>(NB);
                        end;

                        else raise Exception.Create('Nullable type not ' +
                          'supported to make DataSetToObjectList');

                      end;

                      RttiProperty.SetValue(TObject(Item), RecVal);
                    end;
                  end;
                end;
              end;
            end
          );
        end;

        Result.Add(Item);

        DataSet.Next;
      end;
    finally
      DataSet.EnableControls;
    end;
  end;
end;

class function TORMUtils.DateTimeToStrDBFormat(Value: TDateTime): string;
begin
  Result := 'TO_DATE(' +
    QuotedStr(FormatDateTime('dd-mm-yyyy hh:mm:ss', Value))
    + ', ' + QuotedStr(C_DB_DATE_TIME_FORMAT) + ')';
end;

class procedure TORMUtils.ForEachProperty(AClassInfo: Pointer;
  RttiAttributeMsg: TRttiPropertyMsg);
var
  LRttiType: TRttiType;
  LRttiProperty: TRttiProperty;
begin
  LRttiType := Ctx.GetType(AClassInfo);
  for LRttiProperty in LRttiType.GetDeclaredProperties do
  begin
    // Chama a referencia para o m�todo an�nimo
    RttiAttributeMsg(LRttiProperty);
  end;
end;

class function TORMUtils.GetColumnName(AClassInfo: Pointer;
  PropertyName: string): string;

var
  RttiProperty: TRttiProperty;
begin
  Result := '';
  RttiProperty := TORMUtils.GetProperty(AClassInfo, PropertyName);

  if not Assigned(RttiProperty) then
  begin
    raise Exception.Create('Atributo ' + PropertyName + ' informado no Criteria n�o existe na classe');
  end;

  Result := TORMUtils.GetColumnName(RttiProperty);

  if (Result = EmptyStr) then
  begin
    raise Exception.Create('N�o existe anota��o TColumn para o atributo ' + PropertyName);
  end;
end;

class function TORMUtils.GetColumnName(RttiProperty: TRttiProperty): string;
var
  LAttr: TCustomAttribute;
begin
  Result := '';
  for LAttr in RttiProperty.GetAttributes do
  begin
    // � coluna?
    if (LAttr is TColumn) or (LAttr is TTransient) then
    begin
      Result := (LAttr as TColumnBase).Name;
      Break;
    end;
  end;
end;

class function TORMUtils.GetColumnValueByType(AClassInfo: Pointer;
  PropertyName: string; Value: TValue): string;
var
  RttiProperty: TRttiProperty;
begin
  try
    RttiProperty := TORMUtils.GetProperty(AClassInfo, PropertyName);
    Result := TORMUtils.GetHandleValue(RttiProperty.PropertyType.Handle, Value);
  except
    on E: EInvalidCast do
    begin
      Result := '{#InvalidCast#}';
    end;
    on E: Exception do
    begin
      Result := '{#CanNotConvertValue#}';
    end;
  end;
end;

class function TORMUtils.GetFieldType(AField: TRttiField): TORMFieldType;
begin
  Result := GetHandleType(AField.FieldType.Handle);

  if (Result = oftUnknown) then
  begin
    if AField.FieldType.IsInstance and
      AField.FieldType.AsInstance.MetaclassType.InheritsFrom(TStream) then
    begin
      Result := oftBlob;
    end;
  end;
end;

class function TORMUtils.GetFieldValue(AField: TRttiField; Obj: TObject): string;
begin
  Result := GetHandleValue(AField.FieldType.Handle, AField.GetValue(Obj));
end;

class function TORMUtils.GetProperty(AClassInfo: Pointer; Name: string): TRttiProperty;
var
  RttiType: TRttiType;
  RttiProperty: TRttiProperty;
begin
  Result := nil;

  RttiType := Ctx.GetType(AClassInfo);

  for RttiProperty in RttiType.GetDeclaredProperties do
  begin
    if UpperCase(RttiProperty.Name) = UpperCase(Name) then
    begin
      Result := RttiProperty;
      Break;
    end;
  end;
end;

class function TORMUtils.GetPropertyType(AProp: TRttiProperty): TORMFieldType;
begin
  Result := GetHandleType(AProp.PropertyType.Handle);

  if (Result = oftUnknown) then
  begin
    if AProp.PropertyType.IsInstance and
      AProp.PropertyType.AsInstance.MetaclassType.InheritsFrom(TStream) then
    begin
      Result := oftBlob;
    end;
  end;
end;

class function TORMUtils.GetPropertyValue(AProp: TRttiProperty;
  Obj: TObject): string;
var
  FieldType: TORMFieldType;
  Value: TValue;
  RttiRecord: TRttiRecordType;
  RttiFieldAux: TRttiField;
  InitValue: TValue;
  ModifiedValue: TValue;
begin
  Result    := '';
  FieldType := GetPropertyType(AProp);
  Value     := AProp.GetValue(TObject(Obj));

  // Record
  if FieldType = oftRecord then
  begin
    RttiRecord := Ctx.GetType(AProp.GetValue(TObject(Obj)).TypeInfo).AsRecord;

    RttiFieldAux := RttiRecord.GetField('FInitValue');

    // Is a Nullable Record?
    if Assigned(RttiFieldAux) then
    begin
      InitValue     := RttiFieldAux.GetValue(AProp.GetValue(TObject(Obj)).GetReferenceToRawData);

      RttiFieldAux  := RttiRecord.GetField('FModified');
      ModifiedValue := RttiFieldAux.GetValue(AProp.GetValue(TObject(Obj)).GetReferenceToRawData);

      // Is Null?
      if (InitValue.AsString <> 'I') or (not ModifiedValue.AsBoolean) then
      begin
        Result := 'NULL';
      end
      else
      begin
        RttiFieldAux := RttiRecord.GetField('FValue');

        Result := GetHandleValue(RttiFieldAux.FieldType.Handle, RttiFieldAux.GetValue(AProp.GetValue(TObject(Obj)).GetReferenceToRawData));
      end;
    end;
  end
  else
  begin
    Result := GetHandleValue(AProp.PropertyType.Handle, Value);
  end;
end;

class function TORMUtils.PropertyIsNullable(
  ARecord: TRttiRecordType): Boolean;
begin
  Result := Assigned(ARecord.GetField('FInitValue'));
end;

class function TORMUtils.GetHandleType(Handle: PTypeInfo): TORMFieldType;
begin
  Result := oftUnknown;

  if Handle.Kind in [tkString, tkWString, tkChar, tkWChar, tkLString,
    tkUString] then
  begin
    Result := oftString;
  end
  else
  if Handle.Kind in [tkInteger, tkInt64] then
  begin
    Result := oftInteger;
  end
  else
  if Handle.Kind = tkRecord then
  begin
    Result := oftRecord;
  end
  else
  if Handle = TypeInfo(TDate) then
  begin
    Result := oftDate;
  end
  else
  if Handle = TypeInfo(TDateTime) then
  begin
    Result := oftDateTime;
  end
  else
  if Handle = TypeInfo(Currency) then
  begin
    Result := oftDecimal;
  end
  else
  if Handle = TypeInfo(TTime) then
  begin
    Result := oftTime;
  end
  else
  if Handle.Kind = tkFloat then
  begin
    Result := oftFloat;
  end
  else
  if (Handle.Kind = tkEnumeration) and (Handle.Name = 'Boolean') then
  begin
    Result := oftBoolean;
  end;
end;

class function TORMUtils.GetHandleValue(Handle: PTypeInfo; Value: TValue): string;
var
  FieldType: TORMFieldType;
  RttiRecord: TRttiRecordType;
  RttiFieldAux: TRttiField;
begin
  Result    := '';
  FieldType := GetHandleType(Handle);

  // Strings
  if FieldType = oftString then
  begin
    Result := QuotedStr(Value.AsString);
  end
  else
  // Date
  if FieldType = oftDate then
  begin
    Result := QuotedStr(FormatDateTime('dd-mm-yyyy', Value.AsExtended));
  end
  else
  // DateTime
  if FieldType = oftDateTime then
  begin
    Result := DateTimeToStrDBFormat(Value.AsExtended);
  end
  else
  // Time
  if FieldType = oftTime then
  begin
    Result := QuotedStr(FormatDateTime('hh:mm:ss', Value.AsExtended));
  end
  else
  // Boolean
  if FieldType = oftBoolean then
  begin
    if (Value.AsBoolean = True) then
    begin
      Result := 'S';
    end
    else
    begin
      Result := 'N';
    end;
  end
  else
  // Numerics
  if (FieldType = oftDecimal) or (FieldType = oftFloat) then
  begin
    //if Value. then
    begin
      Result := StringReplace(
        FloatToStr(Value.AsExtended), ',', '.', []);
    end;
  end
  else
  // Integer
  if FieldType = oftInteger then
  begin
    Result := IntToStr(Value.AsInteger);
  end
  else
  // Nullable
  if (FieldType = oftRecord) then
  begin
    RttiRecord := Ctx.GetType(Handle).AsRecord;

    RttiFieldAux := RttiRecord.GetField('FInitValue');

    // Is a Nullable Record?
    if Assigned(RttiFieldAux) then
    begin
      RttiFieldAux := RttiRecord.GetField('FValue');
      Result := GetHandleValue(RttiFieldAux.FieldType.Handle, Value);
    end;
  end;
end;

end.
