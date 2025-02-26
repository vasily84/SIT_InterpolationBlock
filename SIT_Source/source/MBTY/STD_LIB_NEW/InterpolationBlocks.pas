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
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath;


type
/////////////////////////////////////////////////////////////////////////////
// ���� ������������ �� �� �� 3 ������� 2025, �� ����������� ���������
  TInterpolationBlock1 = class(TRunObject)
  protected
    // ������������ ������ ����� ������� ������
    // 0- ������ ������� 1-�������� � �-� � ������ ������
    // 2- �������� � ������� � ����� ����� 3- ����� �����
    InputsMode: NativeInt;
    ExtrapolationType: NativeInt;   // ������������ ��� ������������� �� ��������� ����������� ������� - ���������,����, ������������ �� ������� ������
    FileName: string; // ��� ������� �������� �����
    FileNameArgsX: string; // ��� �������� ����� ��� ���������� ��� ���������� ��������
    FileNameFuncTable: string; // ��� �������� ����� ��� �������� ������� ��� ���������� ��������

    property_Xi_array: TExtArray; // ����� ���������� Xi �������, ���� ��� ������ ����� �������� �������
    property_Fi_array: TExtArray; // ����� �������� Fi �������, ���� ��� ������ ����� �������� �������

    //������������ ��� ������������
    //0:�������-���������� 1:�������� 2:������ ���������� 3: �������
    InterpolationType,
    LagrangeOrder,  // ������� ������������ ��� ������ ��������
    Npoints, // ����� ����� �������
    prop_Npoints,
    M_LagrangeShift,

    Fdim: NativeInt; // ����������� ��������� ������� �������
    prop_Fdim: NativeInt;

    prop_IsNaturalSpline: Boolean;
    SplineArr: TExtArray2;

    // ��������� ��������� �������� ������������ ��� ������ ������� Interpol
    LastInd: array of NativeInt;

    Xi_array: TExtArray; // ����� ���������� Xi �������, ���� ��� ������� �� �����
    Fi_array: TExtArray; // ����� �������� Fi �������, ���� ��� ������� �� �����

    x_stamp: TExtArray2; // ������� �������� ������ - ������� ����������� ������ ���
    y_stamp: TExtArray2; // ������������ ��������� ������� ������

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
uses RealArrays;

//===========================================================================
constructor TInterpolationBlock1.Create;
begin
  inherited;
  IsLinearBlock:=True;
  property_Xi_array := TExtArray.Create(1); // ����� ���������� Xi �������, ���� ��� ������ ����� �������� �������
  property_Fi_array:= TExtArray.Create(1); // ����� �������� Fi �������, ���� ��� ������ ����� �������� �������

  SplineArr := TExtArray2.Create(1,1);
  x_stamp := TExtArray2.Create(1,1);
  y_stamp := TExtArray2.Create(1,1);

  Xi_array := TExtArray.Create(1); // ����� ���������� Xi �������, ���� ��� ������� �� �����
  Fi_array := TExtArray.Create(1);
  prop_IsNaturalSpline := True;
end;

destructor  TInterpolationBlock1.Destroy;
begin
  FreeAndNil(property_Xi_array);
  FreeAndNil(property_Fi_array);
  
  FreeAndNil(SplineArr);
  FreeAndNil(x_stamp);
  FreeAndNil(y_stamp);

  FreeAndNil(Xi_array);
  FreeAndNil(Fi_array);

  if Assigned(LastInd) then SetLength(LastInd,0);

  inherited;
end;

function    TInterpolationBlock1.GetParamID;
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
    Result:=NativeInt(@prop_Fdim);
    DataType:=dtInteger;
    exit;
    end;

  // ����� �������� ����� �������
  if StrEqu(ParamName,'Npoints') then begin
    Result:=NativeInt(@prop_Npoints);
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
    Result:=NativeInt(property_Xi_array);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'Fi_array') then begin
    Result:=NativeInt(property_Fi_array);
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

  if StrEqu(ParamName,'IsNaturalSpline') then begin
    Result:=NativeInt(@prop_IsNaturalSpline);
    DataType:=dtBool;
    exit;
    end;

  ErrorEvent('�������� '+ParamName+'� ����� MyInterpolationBlock1 �� ������', msWarning, VisualObject);
end;

{
function    TInterpolationBlock1.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
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
}
//---------------------------------------------------------------------------

function TInterpolationBlock1.LoadFuncFromProperties(): Boolean;
var
  i,j: Integer;
  Xp: Double;
begin
  Result := True;

  if property_Fi_array.Count<>Fdim*property_Xi_array.Count then begin //�������� ������������ ������� ��������
    ErrorEvent('����� �������� Fi_array � ���������� Xi_array ������� ������� �� ���������',msError,VisualObject);
    Result := False;
    exit;
    end;

end;
//---------------------------------------------------------------------------

function TInterpolationBlock1.LoadFuncFromFilesXiFi(): Boolean;
label
  OnExit;
var
  tableX,tableF: TTable1;
  i,j,yy: Integer;
  Xp: Double;

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

  if Fdim <> (1+tableF.FunsCount) then begin
    ErrorEvent('����������� ������� �� ����� = '+IntToStr((1+tableF.FunsCount))+' � �������� Fdim= '+IntToStr(Fdim)+' �� ���������, ���������� ���������� �� �����',msWarning,VisualObject);
    //Result := False;
    //goto OnExit;
    end;

  Xi_array.ChangeCount(tableX.px.count);
  Fi_array.ChangeCount(tableF.px.count*(tableF.FunsCount+1));

  // ����������� ������������� �� �����
  //Npoints := tableF.px.count*(tableF.FunsCount+1);
  Npoints := tableF.px.count;
  Fdim := tableF.FunsCount+1;

  // ���� �� �������� ������� � ��������� ����� � �������.
  yy := 0;
  for i:=0 to tableX.px.count-1 do begin
    Xi_array[i] := tableX.px[i];

    // TODO ���������� - �������� �����, �� ��������
    Fi_array[yy] := tableF.px[i]; // ������ ����� - �� ������� ������� ����������
    inc(yy);
    for j:=0 to tableF.FunsCount-1 do begin // ��������� ����� - �� ������� ��������
      Fi_array[yy] := tableF.py.Arr[j][i];
      inc(yy);
      end;
    end;

OnExit:
  FreeAndNil(tableX);
  FreeAndNil(tableF);
end;
//----------------------------------------------------------------------

function TInterpolationBlock1.LoadFuncFromFile(): Boolean;
label
  OnExit;
var
  table1: TTable1;
  i,j,yy: Integer;
  Xp: Double;

begin
  Result := True;
  table1 := TTable1.Create(FileName);
  if not table1.OpenFromFile(FileName) then begin
    ErrorEvent('���� '+FileName+' ���������� �������',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  Xi_array.ChangeCount(table1.px.count);
  Fi_array.ChangeCount(table1.px.count*table1.FunsCount);

  // ����������� ������������� �� �����
  //Npoints := table1.px.count*table1.FunsCount;
  Npoints := table1.px.count;
  Fdim := table1.FunsCount;

  yy:=0;
  for i:=0 to table1.px.count-1 do begin // ���� �� �������� ������� � ��������� ����� � �������.
    Xi_array[i] := table1.px[i];

    for j:=0 to table1.FunsCount-1 do begin
      Fi_array[yy] := table1.py.Arr[j][i];
      inc(yy);
      end;
    end;

OnExit:
  FreeAndNil(table1);
end;

//============================================================================
function TInterpolationBlock1.LoadFuncFromPorts(): Boolean;
var
  i,j: Integer;
  Xp: Double;
begin
  Result := True;
  // 0. ��������� ����������� ������� ������ -
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

end;

//---------------------------------------------------------------------------
function TInterpolationBlock1.LoadFunc(): Boolean;
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
  {
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
  }

end;

//===========================================================================
function    TInterpolationBlock1.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result := r_Success;
  Fdim := prop_Fdim;
  NPoints := prop_Npoints;

  // TODO ��� ����������, ����� ����� ���������� ����������� ������� �� ������?
  case Action of
    {
    i_GetPropErr:
      begin
      ;
      end;

    i_GetInit:
      begin
      ;
      end;
    }
    i_GetCount:
      begin
      cU[1].Dim:=SetDim([Npoints]);
      cU[2].Dim:=SetDim([Npoints*Fdim]);
      cY[0].Dim:=SetDim([GetFullDim(cU[0].Dim)*Fdim]);
      end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

// ������������ ������, ����������� ��������. ����� ������������.
function   TInterpolationBlock1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var
  i,j,c   : Integer;
  py: PExtArr; // ��������� �� �������� � ��������� ��������������� �������.
  px: PExtArr; // ���������� � SetPxPy
  Yvalue: RealType;

function checkX_range(x: RealType; var AYvalue: RealType):Boolean;
// ���������, ��� �������� � ��������� ������ ��������� ����������� �������.
// ���������� - True - �������� � ��������� ������ ��������� � ������������� �� ���������.
// ����� - False, � �������� AYValue �� �������� �������������
begin

  if ExtrapolationType=2 then begin // ���������������� ������� ��� ��������� ������
    Result := True;
    exit;
    end;

  if x<px[0] then begin
    case ExtrapolationType of
      0: // ��������� ��� ���������
        begin
          Result := False;
          AYvalue := py[0]; // ����� ������ �������� �� ������� ��������
          exit;
        end;

      1: // ���� ��� ���������
        begin
          Result := False;
          AYvalue := 0;
          exit;
        end;
      end;
    end;

  if x>px[Npoints-1] then begin
    case ExtrapolationType of
      0: // ��������� ��� ���������
        begin
          Result := False;
          AYvalue := py[Npoints-1]; // ����� ��������� �������� �� ������� ��������
          exit;
        end;

      1: // ���� ��� ���������
        begin
          Result := False;
          AYvalue := 0;
          exit;
        end;
      end;
    end;
  Result := True;
end;
//---------------------------------------------------------------------------
procedure SetPxPy;
// ������������� ��������� px py �� ������ ���������� ������
begin
  case InputsMode of
    0: // �� �������
      begin
        // ������������� ��������� �� ��������
        px := property_Xi_array.Arr;
        py := property_Fi_array.Arr;
      end;

    1,2: // �� ������ � ������ ���������
      begin
          // ������������� ��������� �� ��������� ������
          px := Xi_array.Arr;
          py := Fi_array.Arr;
      end;

    3: // �� ������
      begin
        // U[1] - ���������, U[2] - ������� ��������
        px := U[1].Arr;
        py := U[2].Arr;
      end;
  end;

end;
//------------------------------------------------------------------------
function  IsNewData:boolean;
// ������� ������ ��� �������?
// ��� ������� ��� ��������� ���������� ������ ������� ������������
var
  j: integer;
begin
  Result := False;
  for j:=0 to Npoints - 1 do // ���� �� ������, ���� ����� ����������� - ������ �����.
    if (x_stamp[i].Arr^[j] <> px[j]) or (y_stamp[i].Arr^[j] <> py[j]) then begin
      x_stamp[i].Arr^[j] := px[j];
      y_stamp[i].Arr^[j] := py[j];
      Result:=True;
      end;
end;
// ������ RunFunc ----------------------------------------------------------
var
  nXindex: NativeInt;
begin
  Result := r_Success;

  case Action of
    f_InitObjects:
      begin
        //����� ������������� ������ ����������� ��������������� ������ � ����������
        SetLength(LastInd,GetFullDim(cU[2].Dim));
        ZeroMemory(Pointer(LastInd), GetFullDim(cU[2].Dim)*SizeOf(NativeInt));
        SplineArr.ChangeCount(5, Npoints);
        x_stamp.ChangeCount(Fdim, Npoints);
        y_stamp.ChangeCount(Fdim, Npoints);

        // ��������� ������� ������� �� ��������� ���������
        if not LoadFunc() then begin
          Result := r_Fail;
          exit;
          end;

      end;

    f_InitState,
    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep:
      begin
        // U[0] - args - �������� ��������� X
        c := 0;
        SetPxPy(); // ������������� ��������� �� ������ ������

        for i:=0 to Fdim - 1 do begin
         case InterpolationType of
           3:   // �������
              begin
                // TODO �������� �������!!
                for j:=0 to U[0].Count - 1 do begin
                  // function Lagrange(var X1,Y1 :array of RealType;X:RealType;N,M:Integer):RealType;
                  // X1 - ������ �������� ���������, Y1 - ������ �������� �������,
                  // X - ��������, N - ������� ��������, M - HOMEP ��������, C KOTOPO�O ���������� ������ ������������
                  if checkX_range(U[0].Arr^[j],Yvalue) then begin

                      nXindex := NPoints-1;
                      // �������� ��� ���������� �������� � ������� �� ��������� ���������� ��������� �
                      Find1(U[0].Arr^[j],px,NPoints,nXindex);
                      M_LagrangeShift := nXindex;

                      // ������� �� ������ �������, �� ������ �� �� �������
                      // ����������� ��. ���������� Lagrange
                      if(M_LagrangeShift+LagrangeOrder)>=(Npoints-1) then begin
                        M_LagrangeShift:= Npoints-1- LagrangeOrder;
                        end;

                      if (M_LagrangeShift<1) then M_LagrangeShift:=1;

                      Y[0].arr^[i*U[0].Count+j] := Lagrange(px^,py^,U[0].arr^[j],LagrangeOrder,M_LagrangeShift);
                    end else begin
                      Y[0].arr^[i*U[0].Count+j] := Yvalue;
                    end;

                  inc(c);
                  end;
              end;

           2:   //���������� ������������ ����������� �������
              begin
                if IsNewData or (Action = f_InitState) then begin
                  NaturalSplineCalc(px, py, SplineArr.Arr, Npoints, prop_IsNaturalSpline );
                  end;

                for j:=0 to U[0].Count-1 do begin

                  if checkX_range(U[0].Arr^[j],Yvalue) then begin
                      Y[0].arr^[c] := Interpol(U[0].Arr^[j], SplineArr.Arr, 5, LastInd[j] );
                    end else begin
                      Y[0].arr^[c] := Yvalue;
                    end;

                  inc(c);
                  end;
              end;

           1:   // �������� ������������
              begin
                if IsNewData or (Action = f_InitState) then begin
                  LInterpCalc(px, py, SplineArr.Arr, Npoints );
                  end;

                for j:=0 to U[0].Count-1 do begin
                  if checkX_range(U[0].Arr^[j],Yvalue) then begin
                      Y[0].arr^[c] := Interpol(U[0].Arr^[j], SplineArr.Arr, 3, LastInd[j]);
                    end else begin
                      Y[0].arr^[c] := Yvalue;
                    end;

                  inc(c);
                  end;
              end;

           0:     // �������� ������������.
              begin
                  for j:=0 to U[0].Count-1 do begin
                    if checkX_range(U[0].Arr^[j],Yvalue) then begin
                        // ������� �������� �������� ��� ������������
                        nXindex := NPoints-1;
                        Find1(U[0].Arr^[j],px,NPoints,nXindex);
                        Y[0].arr^[c] := py[nXindex];
                      end else begin
                        Y[0].arr^[c] := Yvalue;
                      end;

                    inc(c);
                    end;
                end;
           else
              begin
                ErrorEvent('����� ������������ "'+IntToStr(InterpolationType)+'" �� ����������', msError, VisualObject );
                Result := r_Fail;
                exit;
              end;
           end;

         // ������� ��������� �� ������ ��������� ������� � ������
         py := @py^[Npoints];
        end
      end;
  end
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
end.
