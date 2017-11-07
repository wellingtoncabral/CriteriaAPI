unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, uCriteria, uEmployee;

type
  TfrmMain = class(TForm)
    btnSelectAll: TButton;
    mmSql: TMemo;
    btnRestrictions: TButton;
    btnProjectionList: TButton;
    btnProjectionDistinct: TButton;
    btnProjectionAggregates: TButton;
    btnConjuctions: TButton;
    btnOrderBy: TButton;
    btnLimitedResult: TButton;
    btnComplexQuery: TButton;
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnRestrictionsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnProjectionListClick(Sender: TObject);
    procedure btnProjectionDistinctClick(Sender: TObject);
    procedure btnProjectionAggregatesClick(Sender: TObject);
    procedure btnConjuctionsClick(Sender: TObject);
    procedure btnOrderByClick(Sender: TObject);
    procedure btnLimitedResultClick(Sender: TObject);
    procedure btnComplexQueryClick(Sender: TObject);
  private
    procedure AddCriteriaToMemo(Criteria: TCriteria);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.AddCriteriaToMemo(Criteria: TCriteria);
begin
  mmSql.Clear;
  mmSql.Text := Criteria.ToString;
end;

procedure TfrmMain.btnSelectAllClick(Sender: TObject);
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try
    AddCriteriaToMemo(Criteria);
  finally
    FreeAndNil(Criteria);
  end;
end;

procedure TfrmMain.btnComplexQueryClick(Sender: TObject);
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try
    Criteria.SetProjection(
      TProjections.List([
        TProjections.PropertyName('Id'),
        TProjections.PropertyName('FirstName'),
        TProjections.PropertyName('Salary'),
        TProjections.PropertyName('Birthday'),
        TProjections.Count('Id', 'MyCount')
      ])
    );

    Criteria.Add(
      TRestrictions.Conjunction([
        TRestrictions.Between('Salary', 1000, 2000),
        TRestrictions.Disjunction([
          TRestrictions.Equal('FirstName', 'cabral'),
          TRestrictions.IsNull('GroupId')
        ])
      ])
    );

    Criteria.AddOrder(TOrder.Asc('FirstName'));

    AddCriteriaToMemo(Criteria);
  finally
    FreeAndNil(Criteria);
  end;
end;

procedure TfrmMain.btnConjuctionsClick(Sender: TObject);
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try
    Criteria.Add(
      TRestrictions.Conjunction([

        TRestrictions.Disjunction([
          TRestrictions.IsNull('Birthday'),
          TRestrictions.Equal('Birthday', Now)
        ]),

        TRestrictions.Disjunction([
          TRestrictions.Equal('Salary', 2000),
          TRestrictions.GreaterOrEqual('Salary', 5000)
        ])

      ])
    );

    AddCriteriaToMemo(Criteria);
  finally
    FreeAndNil(Criteria);
  end;
end;

procedure TfrmMain.btnLimitedResultClick(Sender: TObject);
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try
    Criteria.Add(
      TRestrictions.NotEqual('FirstName', 'wellington')
    );
    Criteria.SetFirstResult(50).SetMaxResult(200).AddOrder(TOrder.Desc('Id'));

    AddCriteriaToMemo(Criteria);
  finally
    FreeAndNil(Criteria);
  end;
end;

procedure TfrmMain.btnOrderByClick(Sender: TObject);
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try
    Criteria.Add(
      TRestrictions.NotEqual('FirstName', 'wellington')
    ).AddOrder(TOrder.Desc('Id'));

    AddCriteriaToMemo(Criteria);
  finally
    FreeAndNil(Criteria);
  end;
end;

procedure TfrmMain.btnProjectionAggregatesClick(Sender: TObject);
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try

    Criteria.SetProjection(
      TProjections.List([
        TProjections.Count('Id'),
        TProjections.Sum('Salary'),
        TProjections.Avg('Salary'),
        TProjections.Max('Salary'),
        TProjections.Min('Salary'),
        TProjections.Sum('Salary')
      ])
    );

    AddCriteriaToMemo(Criteria);
  finally
    FreeAndNil(Criteria);
  end;
end;

procedure TfrmMain.btnProjectionDistinctClick(Sender: TObject);
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try

    Criteria.SetProjection(
      TProjections.Distinct(['FirstName', 'Salary'])
    ).Add(TRestrictions.LowerOrEqual('Salary', 3000));

    AddCriteriaToMemo(Criteria);
  finally
    FreeAndNil(Criteria);
  end;
end;

procedure TfrmMain.btnProjectionListClick(Sender: TObject);
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try

    Criteria.SetProjection(
      TProjections.List([
        TProjections.PropertyName('FirstName'),
        TProjections.PropertyName('Salary')
      ])
    ).Add(TRestrictions.GreaterThan('Salary', 3000));

    AddCriteriaToMemo(Criteria);
  finally
    FreeAndNil(Criteria);
  end;
end;

procedure TfrmMain.btnRestrictionsClick(Sender: TObject);
var
  Criteria: TCriteria;
begin
  Criteria := TCriteria.Create(TEmployee.ClassInfo);
  try
    (* Simple Restrictions *)
    Criteria.Add(TRestrictions.IsNull('GroupId'));
    Criteria.Add(TRestrictions.Between('Birthday', Now-30, Now));
    Criteria.Add(TRestrictions.ILike('FirstName', 'wellington%'));

    AddCriteriaToMemo(Criteria);
  finally
    FreeAndNil(Criteria);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := True;
end;

end.
