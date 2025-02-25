//**************************************************************************//
 // ������ �������� ��� �������� ��������� ������ ������� ����-4             //
 // ������������:                          //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit NewNDInterpol;

interface

uses Classes, MBTYArrays, DataTypes, SysUtils, abstract_im_interface, RunObjts, Math,
     uCircBufferAlgs, mbty_std_consts, InterpolFuncs;


type
 //���� ����������� �������� ������������
 TNewNDInterpol = class(TRunObject)
 public
   // ��� ��������
   BorderExtrapolationType: NativeInt; // ������������ ��� ������������� ��� ��������� �� ��������� ������
   InterpType: NativeInt; // ������������ ����� ������������

   property_X: TExtArray2; // ������� ���������� �� ������������
   property_F: TExtArray;  // ������ �������� �������


   Xtable: TExtArray2; // ������� ���������� �� ������������
   Ftable: TExtArray;  // ������ �������� �������

   // ��� ���������� ����������
   tmpXp:         TExtArray2; // ��� ��������� �������, ���������� �� ����� U
   u_,v_:         TExtArray;
   ad_,k_:        TIntArray;

   function LoadDataFromProperties(): Boolean;
   function LoadDataFromFiles(): Boolean;


   function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
   function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
   function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
   constructor    Create(Owner: TObject);override;
   destructor     Destroy;override;
 end;

implementation

uses System.StrUtils, RealArrays;

constructor  TNewNDInterpol.Create;
begin
  inherited;
  InterpType:=0;
  BorderExtrapolationType:=0;

  tmpXp:=TExtArray2.Create(0,0);
  // ��������� � �������� ������� ��� ����������.
  // ����� ���� �������� - 1. �� ������� ������� 2. ��������� �� �����
  Xtable:=TExtArray2.Create(0,0);
  Ftable:=TExtArray.Create(0);

  // �������� ������� - ��������� � �������� �������
  property_X:=TExtArray2.Create(0,0);
  property_F:=TExtArray.Create(0);

  // ���������� ���������� ��� ������� ������������
  u_:=TExtArray.Create(0);
  v_:=TExtArray.Create(0);
  ad_:=TIntArray.Create(0);
  k_:=TIntArray.Create(0);
end;

destructor   TNewNDInterpol.Destroy;
begin
  FreeAndNil(tmpXp);
  FreeAndNil(Xtable);
  FreeAndNil(Ftable);
  FreeAndNil(property_X);
  FreeAndNil(property_F);
  FreeAndNil(u_);
  FreeAndNil(v_);
  FreeAndNil(ad_);
  FreeAndNil(k_);
  inherited;
end;

//--------------------------------------------------------------------------
function     TNewNDInterpol.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
 var p,i,nn: NativeInt;
begin
  Result:=r_Success;

  case Action of
    i_GetPropErr: // �������� ������������
                  begin
                    LoadDataFromProperties();

                    if Xtable.CountX <= 0 then begin
                      ErrorEvent(txtDimensionsNotDefined,msError,VisualObject);
                      Result:=r_Fail;
                      exit;
                      end;

                    //��������� ��������� �����������
                    p:=Xtable[0].Count;
                    for i := 1 to Xtable.CountX - 1 do p:=p*Xtable[i].Count;

                    //��������� �� �� ������ � ������� val_
                    if Ftable.Count > 0 then begin
                      if Ftable.Count < p then begin
                         ErrorEvent(txtOrdinatesDefineIncomplete+IntToStr(p),msWarning,VisualObject);
                         Result := r_Fail;
                         exit;
                         end;
                      end;
                  end;


    i_GetCount:   begin
                    //����������� ������ = ����������� ����� ������� �� ����������� ������� �������
                    cY[0].Dim:= SetDim([ GetFullDim(cU[0].Dim) div Xtable.CountX ]);
                    //������� ��������� ����������
                    nn := cY[0].Dim[0]*Xtable.CountX;
                    if GetFullDim(cU[0].Dim) <> nn then cU[0].Dim:=SetDim([nn]);
                  end
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function    TNewNDInterpol.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
 var
    i,j: integer;
begin
  Result:=0;
  case Action of
    f_InitObjects:    begin
                        //LoadDataFromProperties();
                        LoadDataFromFiles();
                          //����������� �-�� ����� �� ����������� �����
                        tmpXp.ChangeCount(GetFullDim(cU[0].Dim) div Xtable.CountX,Xtable.CountX);

                        //�������������� ��������� �������
                        u_.Count  := Xtable.CountX;
                        v_.Count  := 1 shl (Xtable.CountX);
                        ad_.Count := 1 shl (Xtable.CountX);
                        k_.Count  := Xtable.CountX;
                      end;
    f_RestoreOuts,
    f_InitState,
    f_UpdateOuts,
    f_UpdateJacoby,
    f_GoodStep      : begin
                        //LoadData();

                        j:=0;
                        // �������� �������� �� �������� ������� U �� ��������� ���������
                        for i := 0 to tmpXp.CountX - 1 do begin
                          Move(U[0].Arr^[j],tmpXp[i].Arr^[0],tmpXp[i].Count*SizeOfDouble);
                          inc(j,tmpXp[i].Count);
                        end;


                        case InterpType of
                          1: nstep_interp(Xtable,Ftable,tmpXp,Y[0],BorderExtrapolationType,k_);
                        else
                          nlinear_interp(Xtable,Ftable,tmpXp,Y[0],BorderExtrapolationType,u_,v_,ad_,k_);
                        end;

                      end;
  end
end;

//---------------------------------------------------------------------------
procedure RemoveCommentsFromStrings(var Strings:TStringList);
// ������ ������, ������ ������������ � $, ����� ����� �� // - �����������
var
  slist2: TStringList;
  i,position: Integer;
  str1: string;
begin
  slist2 := TStringList.Create;
  // ����������� ����������� � ������ ������
  for i:=0 to Strings.Count-1 do begin
    str1 := Strings.Strings[i];
    if StartsText('$', str1) then continue;

    position := Pos('//',str1);
    if position>=1 then begin // ����������� ����������������� �����
      SetLength(str1, position);
      end;

    str1 := Trim(str1);
    if str1='' then continue; // ����������� ������ ������
    slist2.Add(str1);
    end;

  Strings.Assign(slist2);
  FreeAndNil(slist2);
end;
//--------------------------------------------------------------------------

function Load_TExtArray2_FromFile(FileName: string; var arrayVect: TExtArray2): Boolean;
// ��������� ������ �������� �� �����
var
  slist1,slist2,slist3: TStringList;
  str1,str2, str3: string;
  v1: RealType;
  i,j: integer;
begin
  // ������ ����� [[0 , 1 , 2 , 9];[0 , 5 , 8];[0 , 3]]
  // ������ ������, ������ ������������ � $, ����� ����� �� // - �����������
  Result := True;
  try
    slist1 := TStringList.Create;
    slist2 := TStringList.Create;
    slist3 := TStringList.Create;

    slist1.LoadFromFile(FileName);
    // ����������� ����������� � ������ ������
    RemoveCommentsFromStrings(slist1);

    slist1.LineBreak := ';';

    str1 := slist1.Text;
    //TODO - �������� �������� ������� ������� ������.
    // �������� ������� ������ �� ���������
    str1 := StringReplace(str1, '[[', '[', [rfReplaceAll, rfIgnoreCase]);
    str1 := StringReplace(str1, ']]', ']', [rfReplaceAll, rfIgnoreCase]);

    // ������ ������� ������ ���������.
    str1 := StringReplace(str1, '],', '];', [rfReplaceAll, rfIgnoreCase]);
    str1 := StringReplace(str1, '] ,', '];', [rfReplaceAll, rfIgnoreCase]);

    slist1.Text := str1;

    arrayVect.ChangeCount(slist1.Count, 1);

    for i:=0 to slist1.Count-1 do begin
      str1 := slist1.Strings[i];
      str1 := StringReplace(str1, '[', ' ', [rfReplaceAll, rfIgnoreCase]);
      str1 := StringReplace(str1, ']', ' ', [rfReplaceAll, rfIgnoreCase]);
      str1 := StringReplace(str1, ';', ' ', [rfReplaceAll, rfIgnoreCase]);

      slist2.Clear;
      slist2.LineBreak := ',';
      slist2.Text := str1;

      arrayVect[i].Count := slist2.Count;
      for j:=0 to slist2.Count-1 do begin
        str2 := slist2.Strings[j];
        v1 := StrToFloat(str2);
        arrayVect[i][j] := v1;
        end;
      end;
  except
    Result := False;
  end;

  FreeAndNil(slist1);
  FreeAndNil(slist2);
  FreeAndNil(slist3);
end;

//---------------------------------------------------------------------------
function Load_TExtArray_FromFile(FileName: string; var array1: TExtArray): Boolean;
// ��������� ������ �� �����
var
  slist1: TStringList;
  str1: string;
  v1: RealType;
  i: Integer;
begin
  // ������ ����� [0 , 0.1 , 1.1 , 1.2 , 3.5 , 3.3 , 6.1 , 6.2 , 7.1 , 7.2 , 9.1 , 9.2 , 8.1 , 8.3 , 5.6 , 5.9 , 3.7 , 3.9 , 18.1 , 18.3 , 15.6 , 5.9 , 13.7 , 13.9]
  Result := True;

  try
    slist1 := TStringList.Create;
    slist1.LoadFromFile(FileName);
    RemoveCommentsFromStrings(slist1);

    slist1.LineBreak := ',';
    str1 := slist1.Text;
    str1 := StringReplace(str1, '[', ' ', [rfReplaceAll, rfIgnoreCase]);
    str1 := StringReplace(str1, ']', ' ', [rfReplaceAll, rfIgnoreCase]);
    slist1.Text := str1;

    array1.Count := slist1.Count;

    for i:=0 to slist1.Count-1 do begin
      str1 := slist1.Strings[i];
      str1 := StringReplace(str1, '[', ' ', [rfReplaceAll, rfIgnoreCase]);
      str1 := StringReplace(str1, ';', ' ', [rfReplaceAll, rfIgnoreCase]);
      str1 := StringReplace(str1, ']', ' ', [rfReplaceAll, rfIgnoreCase]);

      v1 := StrToFloat(str1);
      array1[i] := v1;
      end;

  except
    Result := False;
  end;

  FreeAndNil(slist1);
end;
//---------------------------------------------------------------------------
function TNewNDInterpol.LoadDataFromFiles(): Boolean;
// ��������� ������ �� ������� � ��������� Xarg Fval
var
  a,b: Boolean;
begin
  a := Load_TExtArray2_FromFile('data.txt',Xtable);
  b := Load_TExtArray_FromFile('dataF.txt',Ftable);

  Result := a and b;
end;

//---------------------------------------------------------------------------
function TNewNDInterpol.LoadDataFromProperties(): Boolean;
// ��������� ������ �� ������ � ��������� Xarg Fval
var
  i,j: Integer;
begin
  // ����������� ����������� �������
  Ftable.Count := property_F.Count;
  for i:=0 to property_F.Count-1 do begin
    Ftable[i]:= property_F[i];
    end;

  // ����������� ������������ �������
  Xtable.ChangeCount(property_X.CountX, property_X.GetMaxCountY);
  for i:=0 to property_X.CountX-1 do begin
    Xtable[i].Count := property_X[i].Count;
    for j:=0 to property_X[i].Count-1 do begin
      Xtable[i][j]:= property_X[i][j];
      end;
    end;

  Result := True;
end;

//---------------------------------------------------------------------------
function    TNewNDInterpol.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result<>-1 then exit;

  if StrEqu(ParamName,'outmode') then begin
    Result:=NativeInt(@BorderExtrapolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'method') then begin
    Result:=NativeInt(@InterpType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'x') then begin
    Result:=NativeInt(property_X);
    DataType:=dtMatrix;
    exit;
    end;

  if StrEqu(ParamName,'values') then begin
    Result:=NativeInt(property_F);
    DataType:=dtDoubleArray;
    exit;
    end;

  ErrorEvent('�������� '+ParamName+' � ����� ����������� ������������ �� ������', msWarning, VisualObject);
end;

end.
