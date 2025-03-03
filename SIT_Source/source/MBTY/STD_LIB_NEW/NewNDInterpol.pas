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
     uCircBufferAlgs, mbty_std_consts, InterpolFuncs, TExtArray_Utils;


type
 //���� ����������� �������� ������������
 TInterpolBlockMultiDim = class(TRunObject)
 public
   // ��� ��������
   ExtrapolationType: NativeInt; // ������������ ��� ������������� ��� ��������� �� ��������� ������
   InterpType: NativeInt; // ������������ ����� ������������

   inputMode: NativeInt; // ������������ ����� ������� �������
   FileNameArgs, FileNameVars: string;

   prop_X: TExtArray2; // ������� ���������� �� ������������
   prop_F: TExtArray;  // ������ �������� �������


   Xtable: TExtArray2; // ������� ���������� �� ������������
   Ftable: TExtArray;  // ������ �������� �������

   // ��� ���������� ����������
   tmpXp:         TExtArray2; // ��� ��������� �������, ���������� �� ����� U
   u_,v_:         TExtArray;
   ad_,k_:        TIntArray;

   function LoadDataFromProperties(): Boolean;
   function LoadDataFromFiles(): Boolean;
   function LoadData(): Boolean;

   function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
   function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
   function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
   constructor    Create(Owner: TObject);override;
   destructor     Destroy;override;
 end;

implementation

uses RealArrays;

constructor  TInterpolBlockMultiDim.Create;
begin
  inherited;
  IsLinearBlock:=True;
  InterpType:=0;
  ExtrapolationType:=0;

  tmpXp:=TExtArray2.Create(1,1);
  // ��������� � �������� ������� ��� ����������.
  // ����� ���� �������� - 1. �� ������� ������� 2. ��������� �� �����
  Xtable:=TExtArray2.Create(1,1);
  Ftable:=TExtArray.Create(1);

  // �������� ������� - ��������� � �������� �������
  prop_X:=TExtArray2.Create(1,1);
  prop_F:=TExtArray.Create(1);

  // ���������� ���������� ��� ������� ������������
  u_:=TExtArray.Create(1);
  v_:=TExtArray.Create(1);
  ad_:=TIntArray.Create(1);
  k_:=TIntArray.Create(1);
end;

destructor   TInterpolBlockMultiDim.Destroy;
begin
  FreeAndNil(tmpXp);
  FreeAndNil(Xtable);
  FreeAndNil(Ftable);
  FreeAndNil(prop_X);
  FreeAndNil(prop_F);
  FreeAndNil(u_);
  FreeAndNil(v_);
  FreeAndNil(ad_);
  FreeAndNil(k_);
  inherited;
end;

//--------------------------------------------------------------------------
function     TInterpolBlockMultiDim.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
 var p,i,nn: NativeInt;
begin
  Result:=r_Success;

  case Action of
    i_GetPropErr: // �������� ������������
                  begin
                    if not LoadData then begin
                          Result:=r_Fail;
                          exit;
                          end;

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
                  if not LoadData then begin
                    Result:=r_Fail;
                    exit;
                    end;
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

function    TInterpolBlockMultiDim.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
 var
    i,j: integer;
begin
  Result := r_Success;
  case Action of
    f_InitObjects:    begin
                        if not LoadData then begin
                          Result:=r_Fail;
                          exit;
                          end;

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

                        j:=0;
                        // �������� �������� �� �������� ������� U �� ��������� ���������
                        for i := 0 to tmpXp.CountX - 1 do begin
                          Move(U[0].Arr^[j],tmpXp[i].Arr^[0],tmpXp[i].Count*SizeOfDouble);
                          inc(j,tmpXp[i].Count);
                        end;


                        case InterpType of
                          1: nstep_interp(Xtable,Ftable,tmpXp,Y[0],ExtrapolationType,k_);
                        else
                          nlinear_interp(Xtable,Ftable,tmpXp,Y[0],ExtrapolationType,u_,v_,ad_,k_);
                        end;

                      end;
  end
end;

//--------------------------------------------------------------------------
function TInterpolBlockMultiDim.LoadData(): Boolean;
begin
  if inputMode=0 then
    Result := LoadDataFromProperties()
  else
    Result := LoadDataFromFiles();

end;
//---------------------------------------------------------------------------
function TInterpolBlockMultiDim.LoadDataFromFiles(): Boolean;
// ��������� ������ �� ������� � ��������� Xarg Fval
var
  a,b: Boolean;
begin
  a := Load_TExtArray2_FromBracketFile('data.txt',Xtable);
  b := Load_TExtArray_FromBracketFile('dataF.txt',Ftable);

  Result := a and b;
end;

//---------------------------------------------------------------------------
function TInterpolBlockMultiDim.LoadDataFromProperties(): Boolean;
// ��������� ������ �� ������ � ��������� Xarg Fval
var
  i,j: Integer;
begin
  // ����������� ����������� �������
  TExtArray_cpy(Ftable, prop_F);
  {Ftable.Count := property_F.Count;
  for i:=0 to property_F.Count-1 do begin
    Ftable[i]:= property_F[i];
    end;}


  // ����������� ������������ �������
  TExtArray2_cpy(Xtable,prop_X);
  {
  Xtable.ChangeCount(property_X.CountX, property_X.GetMaxCountY);
  for i:=0 to property_X.CountX-1 do begin
    Xtable[i].Count := property_X[i].Count;
    for j:=0 to property_X[i].Count-1 do begin
      Xtable[i][j]:= property_X[i][j];
      end;
    end;
  }
  Result := True;
end;

//---------------------------------------------------------------------------
function    TInterpolBlockMultiDim.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result<>-1 then exit;

  if StrEqu(ParamName,'outmode') then begin
    Result:=NativeInt(@ExtrapolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'method') then begin
    Result:=NativeInt(@InterpType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'x') then begin
    Result:=NativeInt(prop_X);
    DataType:=dtMatrix;
    exit;
    end;

  if StrEqu(ParamName,'values') then begin
    Result:=NativeInt(prop_F);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'inputMode') then begin
    Result:=NativeInt(@inputMode);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'FileNameArgs') then begin
    Result:=NativeInt(@FileNameArgs);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'FileNameVars') then begin
    Result:=NativeInt(@FileNameVars);
    DataType:=dtString;
    exit;
    end;

  ErrorEvent('�������� '+ParamName+' � ����� ����������� ������������ �� ������', msWarning, VisualObject);
end;

end.
