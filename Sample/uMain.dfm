object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Criteria API Example'
  ClientHeight = 415
  ClientWidth = 881
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 16
  object btnSelectAll: TButton
    Left = 8
    Top = 8
    Width = 168
    Height = 25
    Caption = 'Select All'
    TabOrder = 0
    OnClick = btnSelectAllClick
  end
  object mmSql: TMemo
    Left = 0
    Top = 76
    Width = 881
    Height = 339
    Align = alBottom
    TabOrder = 1
    ExplicitTop = 176
    ExplicitWidth = 914
  end
  object btnRestrictions: TButton
    Left = 181
    Top = 8
    Width = 168
    Height = 25
    Caption = 'Restrictions'
    TabOrder = 2
    OnClick = btnRestrictionsClick
  end
  object btnProjectionList: TButton
    Left = 355
    Top = 8
    Width = 168
    Height = 25
    Caption = 'Projection List'
    TabOrder = 3
    OnClick = btnProjectionListClick
  end
  object btnProjectionDistinct: TButton
    Left = 529
    Top = 8
    Width = 168
    Height = 25
    Caption = 'Projection Distinct'
    TabOrder = 4
    OnClick = btnProjectionDistinctClick
  end
  object btnProjectionAggregates: TButton
    Left = 703
    Top = 8
    Width = 168
    Height = 25
    Caption = 'Projection Aggregates'
    TabOrder = 5
    OnClick = btnProjectionAggregatesClick
  end
  object btnConjuctions: TButton
    Left = 8
    Top = 39
    Width = 168
    Height = 25
    Caption = 'Conjuctions/Disjunctions'
    TabOrder = 6
    OnClick = btnConjuctionsClick
  end
  object btnOrderBy: TButton
    Left = 181
    Top = 39
    Width = 168
    Height = 25
    Caption = 'Order By'
    TabOrder = 7
    OnClick = btnOrderByClick
  end
  object btnLimitedResult: TButton
    Left = 355
    Top = 39
    Width = 168
    Height = 25
    Caption = 'Limited Result'
    TabOrder = 8
    OnClick = btnLimitedResultClick
  end
  object btnComplexQuery: TButton
    Left = 529
    Top = 39
    Width = 168
    Height = 25
    Caption = 'Complex Query'
    TabOrder = 9
    OnClick = btnComplexQueryClick
  end
end
