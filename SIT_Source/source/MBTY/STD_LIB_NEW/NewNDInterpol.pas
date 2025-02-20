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
   BorderExtrapolationType:       NativeInt; // ������������ ��� ������������� ��� ��������� �� ��������� ������
   InterpType:        NativeInt; // ������������ ����� ������������

   property_Xarg:            TExtArray2; // ������� ���������� �� ������������
   property_Fval:          TExtArray;  // ������ �������� �������


   Xarg:            TExtArray2; // ������� ���������� �� ������������
   Fval:          TExtArray;  // ������ �������� �������

   // ��� ���������� ����������
   tmpxp:         TExtArray2;
   u_,v_:         TExtArray;
   ad_,k_:        TIntArray;

   function LoadData(): Boolean;

   function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
   function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
   function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
   constructor    Create(Owner: TObject);override;
   destructor     Destroy;override;
 end;

implementation

//uses RealArrays;
{*******************************************************************************
                       ����������� �������� ������������
*******************************************************************************}
constructor  TNewNDInterpol.Create;
begin
  inherited;
  InterpType:=0;
  BorderExtrapolationType:=0;

  tmpxp:=TExtArray2.Create(0,0);

  // ��������� � �������� ������� ��� ����������.
  // ����� ���� �������� - 1. �� ������� ������� 2. ��������� �� �����
  Xarg:=TExtArray2.Create(0,0);
  Fval:=TExtArray.Create(0);

  // �������� ������� - ��������� � �������� �������
  property_Xarg:=TExtArray2.Create(0,0);
  property_Fval:=TExtArray.Create(0);

  u_:=TExtArray.Create(0);
  v_:=TExtArray.Create(0);
  ad_:=TIntArray.Create(0);
  k_:=TIntArray.Create(0);
end;

destructor   TNewNDInterpol.Destroy;
begin
  FreeAndNil(tmpxp);
  FreeAndNil(Xarg);
  FreeAndNil(Fval);
  FreeAndNil(property_Xarg);
  FreeAndNil(property_Fval);
  FreeAndNil(u_);
  FreeAndNil(v_);
  FreeAndNil(ad_);
  FreeAndNil(k_);
  inherited;
end;

function     TNewNDInterpol.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
 var p,i,nn: NativeInt;
begin
  Result:=r_Success;

  case Action of
    i_GetPropErr: begin // ��� ����������� ����� ��� �������� ������������?
                  if (Xarg.CountX > 0) then begin

                    //��������� ��������� �����������
                    p:=Xarg[0].Count;
                    for I := 1 to Xarg.CountX - 1 do p:=p*Xarg[i].Count;

                    //��������� �� �� ������ � ������� val_
                    if Fval.Count > 0 then begin
                      if Fval.Count < p then begin
                         ErrorEvent(txtOrdinatesDefineIncomplete+IntToStr(p),msWarning,VisualObject);
                      end;
                    end
                    else begin
                      ErrorEvent(txtOrdinatesNotDefinedError,msError,VisualObject);
                      Result:=r_Fail;  //���� ���������� > 0 - �� ������ ��������� ������
                    end;

                  end
                  else begin
                    ErrorEvent(txtDimensionsNotDefined,msError,VisualObject);
                    Result:=r_Fail;  //���� ���������� > 0 - �� ������ ��������� ������
                  end;
                  end;

    i_GetCount:   begin
                    //����������� ������ = ����������� ����� ������� �� ����������� ������� �������
                    cY[0].Dim:= SetDim([ GetFullDim(cU[0].Dim) div Xarg.CountX ]);
                    //������� ��������� ����������
                    nn := cY[0].Dim[0]*Xarg.CountX;
                    if GetFullDim(cU[0].Dim) <> nn then cU[0].Dim:=SetDim([nn]);
                  end
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function    TNewNDInterpol.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result<>0 then exit;

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
      Result:=NativeInt(Xarg);
      DataType:=dtMatrix;
      exit;
      end;

    if StrEqu(ParamName,'values') then begin
      Result:=NativeInt(Fval);
      DataType:=dtDoubleArray;
      end;

    ErrorEvent('�������� '+ParamName+' � ����� ����������� ������������ �� ������', msWarning, VisualObject);
end;

function    TNewNDInterpol.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
 var
    i,j: integer;
begin
  Result:=0;
  case Action of
    f_InitObjects:    begin
                          //����������� �-�� ����� �� ����������� �����
                        tmpxp.ChangeCount(GetFullDim(cU[0].Dim) div Xarg.CountX,Xarg.CountX);

                        //�������������� ��������� �������
                        u_.Count  := Xarg.CountX;
                        v_.Count  := 1 shl (Xarg.CountX);
                        ad_.Count := 1 shl (Xarg.CountX);
                        k_.Count  := Xarg.CountX;
                      end;
    f_RestoreOuts,
    f_InitState,
    f_UpdateOuts,
    f_UpdateJacoby,
    f_GoodStep      : begin
                        LoadData();

                        j:=0;
                        for i := 0 to tmpxp.CountX - 1 do begin
                          Move(U[0].Arr^[j],tmpxp[i].Arr^[0],tmpxp[i].Count*SizeOfDouble);
                          inc(j,tmpxp[i].Count);
                        end;

                        case InterpType of
                          1: nstep_interp(Xarg,Fval,tmpxp,Y[0],BorderExtrapolationType,k_);
                        else
                          nlinear_interp(Xarg,Fval,tmpxp,Y[0],BorderExtrapolationType,u_,v_,ad_,k_);
                        end;

                      end;
  end
end;

function TNewNDInterpol.LoadData(): Boolean;
// ��������� ������ �� ������� ��� ������ � ��������� Xarg Fval
var
  Xarg_clone: TExtArray2;
  Fval_clone: TExtArray;
  i,j,k: Integer;
begin
  Result := True;
//TODO - �������� ���������� ����� ����������� ��������
  Xarg_clone := property_Xarg;
  Fval_clone := property_Fval;

  // ����������� ����������� �������
  Fval_clone.Count := Fval.Count;
  for i:=0 to Fval.Count-1 do begin
    Fval_clone[i]:= Fval[i];
    end;

  // ����������� ������������ �������
  Xarg_clone.ChangeCount(Xarg.CountX,Xarg.GetMaxCountY);
  for i:=0 to Xarg.CountX-1 do begin
    for j:=0 to Xarg[i].Count-1 do begin
      Xarg_clone[i][j]:= Xarg[i][j];
      end;
    end;

end;

end.
