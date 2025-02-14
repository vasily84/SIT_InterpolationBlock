//**************************************************************************//
 // ������ �������� ��� �������� ��������� ������ ������� ����-4             //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit InterpolationBlocks;

 //***************************************************************************//
 //                ����� ������������
 //***************************************************************************//

 {
 ������ �� ������ ������������ ���������� mbty_std
 ���������� ���������� � ���������� ������������, ��� �������� ������ ����� ����
 ������ � ���� �������� - �������� � ������, � � ���� ������� ������.
 }

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath, InterpolationBlocks_unit,InterpolationBlocks_unit_tests;


type
/////////////////////////////////////////////////////////////////////////////
// ���� ������������ �� �� �� 3 ������� 2025, �� ����������� ��������
  TMyInterpolationBlock1 = class(TRunObject)
  protected
    Func: TFndimFunctionByPoints1d; // ��������� ����� ����� �������

    InputsMode: NativeInt; // ������������ ������ ����� ������� ������
    Fdim: NativeInt;                // ����������� ��������� ������� �������
    InterpolationType: NativeInt;   // ������������ ��� ������������ - �������-����������, ��������, �������� � �.�.
    ExtrapolationType: NativeInt;   // ������������ ��� ������������� �� ��������� ����������� ������� - ���������,����, ������������ �� ������� ������
    LagrangeOrder: NativeInt; // ������� ������������ ��� ������ ��������
    FileName: string; // ��� ������� �������� �����
    FileNameArgsX: string; // ��� �������� ����� ��� ���������� ��� ���������� ��������
    FileNameFuncTable: string; // ��� �������� ����� ��� �������� ������� ��� ���������� ��������
    Xi_array: TExtArray; // ����� ���������� Xi �������, ���� ��� ������ ����� �������� �������
    Fi_array: TExtArray; // ����� �������� Fi �������, ���� ��� ������ ����� �������� �������

    function LoadFuncFromProperties(): Boolean;
    function LoadFuncFromFilesXiFi(): Boolean;
    function LoadFuncFromFile(): Boolean;
    function LoadFuncFromPorts(): Boolean;
    function LoadFunc(): Boolean;

  public
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
  end;

///////////////////////////////////////////////////////////////////////////////

implementation

//===========================================================================
constructor TMyInterpolationBlock1.Create;
begin
  inherited;
  IsLinearBlock:=True;
  Xi_array := TExtArray.Create(1); // ����� ���������� Xi �������, ���� ��� ������ ����� �������� �������
  Fi_array:= TExtArray.Create(1); // ����� �������� Fi �������, ���� ��� ������ ����� �������� �������
  Func := TFndimFunctionByPoints1d.Create;

  //TFndimFunctionByPoints1d_testAll('e:\USERDISK\SIM_WORK\�����_������������\InterpolationBlocks_autoTestLog.txt');
end;

destructor  TMyInterpolationBlock1.Destroy;
begin
  FreeAndNil(Xi_array);
  FreeAndNil(Fi_array);
  FreeAndNil(Func);
  inherited;
end;

function    TMyInterpolationBlock1.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

  // ������������ ������ ����� ������� ������
  if StrEqu(ParamName,'InputsMode') then begin
    Result:=NativeInt(@InputsMode);
    DataType:=dtInteger;
    exit;
  end;

  // ����������� ��������� ������� �������
  if StrEqu(ParamName,'Fdim') then begin
    Result:=NativeInt(@Fdim);
    DataType:=dtInteger;
    exit;
  end;

  // ��� ������������ - �������-����������, ��������, �������� � �.�.
  if StrEqu(ParamName,'InterpolationType') then begin
    Result:=NativeInt(@InterpolationType);
    DataType:=dtInteger;
    exit;
  end;

  // ��� ������������� �� ��������� ����������� ������� - ���������, �������-���������� � �.�.
  if StrEqu(ParamName,'ExtrapolationType') then begin
    Result:=NativeInt(@ExtrapolationType);
    DataType:=dtInteger;
    exit;
  end;

  // ������� ������������ ��� ������ ��������
  if StrEqu(ParamName,'LagrangeOrder') then begin
    Result:=NativeInt(@LagrangeOrder);
    DataType:=dtInteger;
    exit;
  end;

  if StrEqu(ParamName,'FileName') then begin
    Result:=NativeInt(@FileName);
    DataType:=dtString;
    exit;
  end;

  if StrEqu(ParamName,'Xi_array') then begin
    Result:=NativeInt(Xi_array);
    DataType:=dtDoubleArray;
    exit;
  end;

  if StrEqu(ParamName,'Fi_array') then begin
    Result:=NativeInt(Fi_array);
    DataType:=dtDoubleArray;
    exit;
  end;

  if StrEqu(ParamName,'FileNameArgsX') then begin
    Result:=NativeInt(@FileNameArgsX);
    DataType:=dtString;
    exit;
  end;

  if StrEqu(ParamName,'FileNameFuncTable') then begin
    Result:=NativeInt(@FileNameFuncTable);
    DataType:=dtString;
    exit;
  end;

  ErrorEvent('�������� '+ParamName+' �� ������', msWarning, VisualObject);
end;

function    TMyInterpolationBlock1.InfoFunc;
  var i,j,maxn,maxd,dimi:  integer;
  val:Double;
begin
  Result := r_Success;

  case Action of
    i_GetInit:  begin
                // ����������������� ����������� ��������� ������� �������
                Func.ClearPoints;
                Func.setFdim(Fdim);
                Result := r_Success;
                end;

    i_GetCount:  begin
                   if Length( cU ) = 0 then begin  // ������� ������ ������� ����� - ����������� ��������
                     ErrorEvent(txtSumErr,msError,VisualObject);
                     Result:=r_Fail;
                     exit;
                    end;

                   //TODO ����� ������������� ����������� ����������� ��������� ������� - ������
                   CY[0].Dim:=SetDim([Fdim]);
                 end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;
//---------------------------------------------------------------------------

function TMyInterpolationBlock1.LoadFuncFromProperties(): Boolean;
var
  i,j: Integer;
  Xp: Double;
begin
  Result := True;

  if Fi_array.Count<>Fdim*Xi_array.Count then begin //�������� ������������ ������� ��������
    ErrorEvent('����� �������� Fi_array � ���������� Xi_array ������� ������� �� ���������',msError,VisualObject);
    Result := False;
    exit;
    end;

  Func.ClearPoints();
  Func.beginPoints;
    for i:=0 to Xi_array.Count-1 do begin // ���� �� �������� ������� � ��������� ����� � �������.
      Xp := Xi_array.Arr[i];

      for j:=0 to Fdim-1 do begin
        Func.Fval1[j] := Fi_array.Arr[i*Fdim+j];
        end;
      Func.addPoint(Xp,PDouble(Func.Fval1));
      end;
  Func.endPoints;

end;

function TMyInterpolationBlock1.LoadFuncFromFilesXiFi(): Boolean;
label
  OnExit;
var
  tableX,tableF: TTable1;
  i,j,k, m,n: Integer;
  Xp,v: Double;

begin
  Result := True;
  tableX := TTable1.Create(FileNameArgsX);
  tableF := TTable1.Create(FileNameFuncTable);

  if not tableX.OpenFromFile(FileNameArgsX) then begin
    ErrorEvent('���� '+FileNameArgsX+' ���������� �������',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if not tableF.OpenFromFile(FileNameFuncTable) then begin
    ErrorEvent('���� '+FileNameFuncTable+' ���������� �������',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if tableX.px.count<>tableF.px.count then begin
    ErrorEvent('����� '+FileNameArgsX+' � '+FileNameFuncTable+' �������� ������ ����� �����',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;


  Func.ClearPoints();
  // TODO ���� ������ ��� �������� - ������� ��� �������� ��, ��� � ���������
  Fdim := 1+tableF.FunsCount;
  Func.setFdim(Fdim);
  Func.beginPoints;

  // ���� �� �������� ������� � ��������� ����� � �������.
    for i:=0 to tableX.px.count-1 do begin
      Xp := tableX.px[i];
      // TODO ���������� - �������� �����, �� ��������
      Func.Fval1[0] := tableF.px[i]; // ������ ����� - �� ������� ������� ����������
      for j:=0 to tableF.FunsCount-1 do begin // �������� ����� - �� ������ ��������
        Func.Fval1[j+1] := tableF.py.Arr[j][i]
        end;

      Func.addPoint(Xp,PDouble(Func.Fval1));
      end;
  Func.endPoints;

OnExit:
  FreeAndNil(tableX);
  FreeAndNil(tableF);
end;
//----------------------------------------------------------------------

function TMyInterpolationBlock1.LoadFuncFromFile(): Boolean;
label
  OnExit;
var
  table1: TTable1;
  i,j,k, m,n: Integer;
  Xp,v: Double;

begin
  Result := True;
  table1 := TTable1.Create(FileName);
  if not table1.OpenFromFile(FileName) then begin
    ErrorEvent('���� '+FileName+' ���������� �������',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  Func.ClearPoints();
  // TODO - ���� ������ ��� �������� - ��� �������� ��, ��� � ���������???
  Fdim := table1.FunsCount;
  Func.setFdim(Fdim);

  Func.beginPoints;
    for i:=0 to table1.px.count-1 do begin // ���� �� �������� ������� � ��������� ����� � �������.
      Xp := table1.px[i];

      for j:=0 to table1.FunsCount-1 do begin
        Func.Fval1[j] := table1.py.Arr[j][i]
        end;

      Func.addPoint(Xp,PDouble(Func.Fval1));
      end;
  Func.endPoints;

OnExit:
  FreeAndNil(table1);
end;

function TMyInterpolationBlock1.LoadFuncFromPorts(): Boolean;
var
  i,j: Integer;
  Xp: Double;
begin
  Result := True;
  // 0. ��������� ����������� ������� ������
  // U[0] - args - �������� ��������� X
  // U[1] - args_arr - ������ �������� �������� ���������
  // U[2] - func_table - ������� �������� �������
  //--------------------------------------------------------
  if Length(U)<>3 then begin
    ErrorEvent('����� ������� ������ �� ����� 3',msError,VisualObject);
    Result := False;
    exit;
    end;

  if U[2].Count<>Fdim*U[1].Count then begin //�������� ������������ ������� ��������
    ErrorEvent('����� �������� Fi � ���������� Xi ������� ������� �� ���������',msError,VisualObject);
    Result := False;
    exit;
    end;

  Func.ClearPoints();
  Func.beginPoints;
    for i:=0 to U[1].Count-1 do begin // ���� �� �������� ������� � ��������� ����� � �������.
      Xp := U[1][i];
      for j:=0 to Fdim-1 do begin
        Func.Fval1[j] := U[2][i*Fdim+j];
        end;
      Func.addPoint(Xp,PDouble(Func.Fval1));
      end;
  Func.endPoints;

end;

function TMyInterpolationBlock1.LoadFunc(): Boolean;
begin
  case InputsMode of
    0:
      Result := LoadFuncFromProperties();
    1:
      Result := LoadFuncFromFilesXiFi();
    2:
      Result := LoadFuncFromFile();
    3:
      Result := LoadFuncFromPorts();
    else begin
      Result := False;
      ErrorEvent('����� ������� ������� '+IntToStr(InputsMode)+' �� ����������',msError,VisualObject);
    end;
  end;

  // ���������, ����������� �� �����. ��� ������������� - �������������
  if not Func.IsXsorted then begin
    Func.sortPoints;
    ErrorEvent('�������� Xi ���� ����������� �� �����������', msWarning, VisualObject );
    end;

  // ���������, ���� �� � ���������� � ���������
  if Func.IsXduplicated then begin
    ErrorEvent('�������� Xi ����� ���������', msWarning, VisualObject );
    end;

  //
  if (InterpolationType = 3) and (LagrangeOrder > Func.pointsCount) then begin
    ErrorEvent('������� ������ �������� ������ ��������� ����� �����, �������� ������� = '+IntToStr(Func.pointsCount), msWarning, VisualObject );
    end;

end;

function   TMyInterpolationBlock1.RunFunc(var at,h : RealType; Action:Integer):NativeInt;
var
    i,j,k : Integer;
    v,vmax   : RealType;
    Xarg: Double;
begin
  Result := r_Success;

  case Action of
    f_InitState:
              begin
                //------------------------------------------------------------
                // 1. �������������� ��� ����� ����� ������
                if not LoadFunc() then begin
                  Result := r_Fail;
                  exit;
                  end;

                Func.ExtrapolationType := ExtrapolationType;
                Func.LagrangeOrder := LagrangeOrder;

                if Func.LagrangeOrder>Func.pointsCount then begin
                  Func.LagrangeOrder := Func.pointsCount;
                  end;

              end;

    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep:
              begin
                ///////////////////////////////////////////////////////////////
                // ������� �������� -
                // 1.�������, ��� ��� ������� ����������������� � f_InitState
                // 2. ���������� �� ����� �������� X
                // 3. ������ ����������� ����� ������������
                // 4. ��������� � ���������� ������-�����

                //------------------------------------------------------------
                // 1. - TODO - �������, ��� ��� ������� ����������������� � f_InitState
                // 2. ���������� �� ����� �������� X
                for k:=0 to U[0].Count-1 do begin
                  Xarg := U[0][k];

                  // 3. ������ ����������� ����� ������������
                  case InterpolationType of
                    0:
                      begin
                        Func.IntervalInterpolation(Xarg, PDouble(Func.Fval1));
                      end;
                    1:
                      begin
                        Func.LinearInterpolation(Xarg, PDouble(Func.Fval1));
                      end;
                    2:
                      begin
                        Func.SplineInterpolation(Xarg, PDouble(Func.Fval1));
                      end;
                    3:
                      begin
                        Func.LagrangeInterpolation(Xarg, PDouble(Func.Fval1));
                      end;

                    else
                      begin
                        ErrorEvent('����� ������������ ������� '+IntToStr(InterpolationType)+' �� ����������',msError,VisualObject);
                        Result := r_Fail;
                        exit;
                      end;
                  end;

                  // 4. ��������� � ���������� ������-�����
                  for j:=0 to Fdim-1 do begin
                    Y[0][k*Fdim+j] :=  Func.Fval1[j];
                    end;

                end;

                EXIT;   // ������ ���������!!!

                ///////////////////////////////////////////////////////////
              end;
  end;
end;

//===========================================================================

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
end.
