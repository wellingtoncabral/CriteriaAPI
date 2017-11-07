program CriteriaAPI;

uses
  Forms,
  uMain in 'uMain.pas' {frmMain},
  uCriteria.Criterion in '..\API\Criteria\uCriteria.Criterion.pas',
  uCriteria.Order in '..\API\Criteria\uCriteria.Order.pas',
  uCriteria in '..\API\Criteria\uCriteria.pas',
  uCriteria.Projection in '..\API\Criteria\uCriteria.Projection.pas',
  uCriteria.Utils in '..\API\Criteria\uCriteria.Utils.pas',
  uWrapper.Generics.Casts in '..\API\Wrapper\uWrapper.Generics.Casts.pas',
  uWrapper.NullableTypes in '..\API\Wrapper\uWrapper.NullableTypes.pas',
  uCriteria.Annotation in '..\API\Criteria\uCriteria.Annotation.pas',
  uHelper.StringBuilder in '..\API\Helper\uHelper.StringBuilder.pas',
  uSQLParse in '..\API\Criteria\uSQLParse.pas',
  uEmployee in 'uEmployee.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
