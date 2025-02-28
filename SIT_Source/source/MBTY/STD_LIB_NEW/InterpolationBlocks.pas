//**************************************************************************//
 // ������ �������� ��� �������� ��������� ������ ������� SimInTech          //
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
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath,TExtArray_Utils;


type
/////////////////////////////////////////////////////////////////////////////
// ���� ������������ �� �� �� 3 ������� 2025, �� ����������� ���������
  TInterpolationBlock1 = class(TRunObject)
  protected
    // ������������ ������ ����� ������� ������
    // 0- ������ ������� 1-�������� � �-� � ������ ������
    // 2- �������� � ������� � ����� ����� 3- ����� �����
    InputMode: NativeInt;
    ExtrapolationType: NativeInt;   // ������������ ��� ������������� �� ��������� ����������� ������� - ���������,����, ������������ �� ������� ������

    prop_Xi_arr: TExtArray; // ����� ���������� Xi �������, ���� ��� ������ ����� �������� �������
    prop_Fi_arr: TExtArray; // ����� �������� Fi �������, ���� ��� ������ ����� �������� �������

    //������������ ��� ������������
    //0:�������-���������� 1:�������� 2:������ ���������� 3: �������
    InterpolationType,
    LagrangeOrder,  // ������� ������������ ��� ������ ��������
    Npoints, // ����� ����� �������
    prop_Npoints, // ��� ������� ����� ����� ����� �����
    nport,
    Fdim: NativeInt; // ����������� ��������� ������� �������

    FileName: string; // ��� ������� �������� �����
    FileNameArgsX: string; // ��� �������� ����� ��� ���������� ��� ���������� ��������
    FileNameValsF: string; // ��� �������� ����� ��� �������� ������� ��� ���������� ��������

    prop_IsNaturalSpline: Boolean;
    SplineArr: TExtArray2;

    // ��������� ��������� �������� ������������ ��� ������ ������� Interpol
    LastInd: array of NativeInt;

    Xi_data: TExtArray; // ����� ���������� Xi �������, ���� ��� ������� �� �����
    Fi_data: TExtArray; // ����� �������� Fi �������, ���� ��� ������� �� �����

    x_stamp: TExtArray2; // ������� �������� ������ - ������� ����������� ������ ���
    y_stamp: TExtArray2; // ������������ ��������� ������� ������

    function LoadFunc(): Boolean; // ��������� ������ ��������������� �������
    function LoadFuncFromProperties(): Boolean;
    function LoadFuncFromFilesXiFi(): Boolean;
    function LoadFuncFromFile(): Boolean;
    function LoadFuncFromPorts(): Boolean;

    function CheckInputsU(): Boolean; // ��������� ������������ ������� ������

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

const
{$IFNDEF ENG}
  txtParamUnknown1 = '�������� "';
  txtParamUnknown2 = '" � ����� �� ������';
  txtFiXiDimError = '����� �������� Fi � ���������� Xi ������� ������� �� ���������';
  txtFileError1 = '���� ';
  txtFileError2 = ' ���������� �������';
  txtPortsNot3 = '����� ������� ������ �� ����� 3'; // ���������� � ���������� ������� ������

  txtInputModeErr1 = '����� ������� ������� ������� ';
  txtInputModeErr2 = ' �� ����������';

  txtInterpolationTypeErr1 = '����� ������������ "';
  txtInterpolationTypeErr2 = '" �� ����������';

  txtFilesRowCountErr1 = '����� ';
  txtFilesRowCountErr2 = ' �������� ������ ����� �����';
  txtFilesWrongFdim1 = '����������� ������� �� ����� � �������� Fdim ';
  txtFilesWrongFdim2 = ' �� ���������';
{$ELSE}
  txtParamUnknown1 = 'parameter "';
  txtParamUnknown2 = '" is undefined';
  txtFiXiDimError = 'The number of values of Fi and arguments Xi of the input function does not match';
  txtFileError1 = 'File ';
  txtFileError2 = ' reading failed';
  txtPortsNot3 = 'The number of input ports is not equal to 3';

  txtInputModeErr1 = 'function table InputMode ';
  txtInputModeErr2 = ' not implemented';

  txtInterpolationTypeErr1 = 'Interpolation type "';
  txtInterpolationTypeErr2 = '" not implemented';

  txtFilesRowCountErr1 = 'files  ';
  txtFilesRowCountErr2 = ' is contain different numbers of rows';
  txtFilesWrongFdim1 = 'the dimension of the function from the file and the property Fdim';
  txtFilesWrongFdim2 = '  does not match';
{$ENDIF}

//===========================================================================

constructor TInterpolationBlock1.Create;
begin
  inherited;
  // TODO
  IsLinearBlock:=True;

  prop_Xi_arr := TExtArray.Create(1); // ����� ���������� Xi �������, ���� ��� ������ ����� �������� �������
  prop_Fi_arr:= TExtArray.Create(1); // ����� �������� Fi �������, ���� ��� ������ ����� �������� �������

  SplineArr := TExtArray2.Create(1,1);
  x_stamp := TExtArray2.Create(1,1);
  y_stamp := TExtArray2.Create(1,1);

  Xi_data := TExtArray.Create(1); // ����� ���������� Xi �������, ���� ��� ������� �� �����
  Fi_data := TExtArray.Create(1);
end;
//----------------------------------------------------------------------------
destructor  TInterpolationBlock1.Destroy;
begin
  FreeAndNil(prop_Xi_arr);
  FreeAndNil(prop_Fi_arr);

  FreeAndNil(SplineArr);
  FreeAndNil(x_stamp);
  FreeAndNil(y_stamp);

  FreeAndNil(Xi_data);
  FreeAndNil(Fi_data);

  if Assigned(LastInd) then SetLength(LastInd,0);

  inherited;
end;
//---------------------------------------------------------------------------
function    TInterpolationBlock1.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

  // ������������ ������ ����� ������� ������
  if StrEqu(ParamName,'InputMode') then begin
    Result:=NativeInt(@InputMode);
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

  // ����� �������������� ������
  if StrEqu(ParamName,'nport') then begin
    Result:=NativeInt(@nport);
    DataType:=dtInteger;
    exit;
    end;

  // ����� ����� ��� ������� ����� �����
  if StrEqu(ParamName,'Npoints') then begin
    Result:=NativeInt(@prop_Npoints);
    DataType:=dtInteger;
    exit;
    end;


  if StrEqu(ParamName,'FileName') then begin
    Result:=NativeInt(@FileName);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'Xi_array') then begin
    Result:=NativeInt(prop_Xi_arr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'Fi_array') then begin
    Result:=NativeInt(prop_Fi_arr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'FileNameArgsX') then begin
    Result:=NativeInt(@FileNameArgsX);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'FileNameValsF') then begin
    Result:=NativeInt(@FileNameValsF);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'IsNaturalSpline') then begin
    Result:=NativeInt(@prop_IsNaturalSpline);
    DataType:=dtBool;
    exit;
    end;

  ErrorEvent(txtParamUnknown1+ParamName+txtParamUnknown1, msWarning, VisualObject);
end;

//---------------------------------------------------------------------------

function TInterpolationBlock1.LoadFuncFromProperties(): Boolean;
begin
  Result := True;

  if prop_Fi_arr.Count<>Fdim*prop_Xi_arr.Count then begin //�������� ������������ ������� ��������
    ErrorEvent(txtFiXiDimError, msError, VisualObject);
    Result := False;
    exit;
    end;

  // ��������
  TExtArray_cpy(Xi_data, prop_Xi_arr);
  TExtArray_cpy(Fi_data, prop_Fi_arr);
end;
//---------------------------------------------------------------------------

function TInterpolationBlock1.LoadFuncFromFilesXiFi(): Boolean;
label
  OnExit;
var
  tableX,tableF: TTable1;
  i,j,yy: Integer;
begin
  Result := True;
  tableX := TTable1.Create(FileNameArgsX);
  tableF := TTable1.Create(FileNameValsF);

  if not tableX.OpenFromFile(FileNameArgsX) then begin
    ErrorEvent(txtFileError1+FileNameArgsX+txtFileError2,msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if not tableF.OpenFromFile(FileNameValsF) then begin
    ErrorEvent(txtFileError1+FileNameValsF+txtFileError2,msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if tableX.px.count<>tableF.px.count then begin
    ErrorEvent(txtFilesRowCountErr1+FileNameArgsX+', '+FileNameValsF+txtFilesRowCountErr2,msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if Fdim <> (1+tableF.FunsCount) then begin
    ErrorEvent(txtFilesWrongFdim1+IntToStr((1+tableF.FunsCount))+' <> '+IntToStr(Fdim)+txtFilesWrongFdim2, msWarning, VisualObject);
    Result := False;
    goto OnExit;
    end;

  Xi_data.ChangeCount(tableX.px.count);
  Fi_data.ChangeCount(tableF.px.count*(tableF.FunsCount+1));

  // ����������� �� �����
  Npoints := Xi_data.Count;

  // ���� �� �������� ������� � ��������� ����� � �������.
  yy := 0;
  for i:=0 to tableX.px.count-1 do begin
    Xi_data[i] := tableX.px[i];

    // TODO ���������� - �������� �����, �� ��������
    Fi_data[yy] := tableF.px[i]; // ������ ����� - �� ������� ������� ����������
    inc(yy);
    for j:=0 to tableF.FunsCount-1 do begin // ��������� ����� - �� ������� ��������
      Fi_data[yy] := tableF.py.Arr[j][i];
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
begin
  Result := True;
  table1 := TTable1.Create(FileName);

  if not table1.OpenFromFile(FileName) then begin
    ErrorEvent(txtFileError1+FileName+txtFileError2,msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if Fdim <> (table1.FunsCount) then begin
    ErrorEvent(txtFilesWrongFdim1+IntToStr((table1.FunsCount))+' <> '+IntToStr(Fdim)+txtFilesWrongFdim2, msWarning, VisualObject);
    Result := False;
    goto OnExit;
    end;

  Xi_data.ChangeCount(table1.px.count);
  Fi_data.ChangeCount(table1.px.count*table1.FunsCount);

  // ����������� ������������� �� �����
  Npoints := table1.px.count;

  yy:=0;
  for i:=0 to table1.px.count-1 do begin // ���� �� �������� ������� � ��������� ����� � �������.
    Xi_data[i] := table1.px[i];

    for j:=0 to table1.FunsCount-1 do begin
      Fi_data[yy] := table1.py.Arr[j][i];
      inc(yy);
      end;
    end;

OnExit:
  FreeAndNil(table1);
end;

//============================================================================
// ��������� ������������ ������� ������
function TInterpolationBlock1.CheckInputsU(): Boolean;
begin
  Result := True;

  case InputMode of
    3: // �� ������
    begin
      // 0. ��������� ����������� ������� ������ -
      // U[0] - args - �������� ��������� X
      // U[1] - args_arr - ������ �������� �������� ���������
      // U[2] - func_table - ������� �������� �������
      //--------------------------------------------------------

      if Length(U)<>3 then begin
        ErrorEvent(txtPortsNot3, msError, VisualObject);
        Result := False;
        exit;
        end;

      if U[2].Count<>Fdim*U[1].Count then begin //�������� ������������ ������� ��������
        ErrorEvent(txtFiXiDimError, msError, VisualObject );
        Result := False;
        exit;
        end;
    end;
    else // ������ ���� ����� ���� ������� ����
      begin
      if Length(U)<>1 then begin
        ErrorEvent('������ ���� ����� 1 ������� ����', msError, VisualObject);
        Result := False;
        exit;
        end;
      end;
  end;
end;

function TInterpolationBlock1.LoadFuncFromPorts(): Boolean;
begin
  Result := True;
end;

//---------------------------------------------------------------------------
function TInterpolationBlock1.LoadFunc(): Boolean;
begin
  case InputMode of
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
      ErrorEvent(txtInputModeErr1+IntToStr(InputMode)+txtInputModeErr2, msError, VisualObject);
    end;
  end;

  if InputMode = 3 then Exit; // ���� �������� ������ ���  0..2
  //TODO !! �����!!
  // ���������, ����������� �� �����. ��� ������������� - �������������
  // ���������, ���� �� � ���������� � ���������
  if not TExtArray_IsOrdered(Xi_data) then begin
    Assert(False,'�� ���������� �');
    TExtArray_Sort_XY_Arr(Xi_data, Fi_data, Npoints, Fdim);
    end;

  if TExtArray_HasDuplicates(Xi_data) then begin
    Assert(False,'���� ��������� �');
    end;

end;

//===========================================================================
function    TInterpolationBlock1.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result := r_Success;

  case Action of  {
    i_GetPropErr: //�������� ������������ ������� ���������� ����� (����� �����������)
      begin
        // TODO - �������� �����������, ����� �������� ������ 1 ���
        if not LoadFunc() then begin
          Result := r_Fail;
          exit;
          end;
      end;

    i_GetInit: //�������� ���� ����������� ������� �� ������
      begin
      if not init_NPoints() then begin
        Result := r_Fail;
        exit;
        end;
      end;
      }

    i_GetCount: //�������� ����������� ������\�������
      begin

        if not LoadFunc() then begin // ��� ����������� ���������� � NPoints
          Result := r_Fail;
          exit;
          end;



        if InputMode=3 then begin // ��� ������ ������� ������� ����� �����
          cU[1].Dim:=SetDim([Npoints]);
          cU[2].Dim:=SetDim([Npoints*Fdim]);
          end;
        // ����������� ��������� ������� ������ ����������
        cY[0].Dim:=SetDim([GetFullDim(cU[0].Dim)*Fdim]);
      end;
    else
      Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

//============================================================================
// TODO!!. ��������!! ����������, ����, ������������� ��������.
// ����� ������ ���������� �������� � �������������� ������������� ����� � ��������� ������������
//============================================================================
function MyLagrange(var px,py :PExtArr;X:RealType;LagrOrder,NPoints:Integer):RealType;
//    px - ������ �������� ���������
//    py - ������ �������� �������
//    X - ��������
//    LagrOrder - ������� ��������
//    NPoints - ����� ����� � ������
var
  Mshift: Integer;
  nXindex: NativeInt;
begin
  nXindex := NPoints-1;
  // �������� ��� ���������� �������� � ������� �� ��������� ���������� ��������� �
  Find1(X,px, NPoints,nXindex);
  Mshift := nXindex;

  // ������� �� ������ �������, �� ������ �� �� �������
  // ����������� ��. ���������� Lagrange
  if(Mshift+LagrOrder)>=(Npoints-1) then begin
    Mshift:= Npoints-1- LagrOrder;
    end;

  if (Mshift<1) then Mshift:=1;

  // �������� ������ ������� � ��� ���������� M
  Result := Lagrange(px^,py^,X,LagrOrder,Mshift);
end;
//=============================================================================

// ������������ ������, ����������� ��������. ����� ������������. ��������� � ������ ��������.
function   TInterpolationBlock1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var
  i,j,c   : Integer;
  py: PExtArr; // ��������� �� �������� � ��������� ��������������� �������,
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
  case InputMode of
    0: // �� �������
      begin
        // ������������� ��������� �� ��������
        px := prop_Xi_arr.Arr;
        py := prop_Fi_arr.Arr;
      end;

    1,2: // �� ������ � ������ ���������
      begin
          // ������������� ��������� �� ��������� ������
          px := Xi_data.Arr;
          py := Fi_data.Arr;
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
function  CheckChanges: boolean;
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
//--------------------------------------------------------------------------
// -- ������ ����� RunFunc -------------------------------------------------
var
  nXindex: NativeInt;
begin
  Result := r_Success;

  case Action of
    f_InitObjects:
      begin
        // ��������� ������� ������� �� ��������� ���������
        if not LoadFunc() then begin
          Result := r_Fail;
          exit;
          end;

        //����� ������������� ������ ����������� ��������������� ������ � ����������
        SetLength(LastInd,GetFullDim(cU[2].Dim));
        ZeroMemory(Pointer(LastInd), GetFullDim(cU[2].Dim)*SizeOf(NativeInt));
        SplineArr.ChangeCount(5, Npoints);
        x_stamp.ChangeCount(Fdim, Npoints);
        y_stamp.ChangeCount(Fdim, Npoints);
      end;

    f_InitState, //������ ��������� ���������
    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep:
      begin
        // U[0] - args - ������ �������� ��������� X
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
                      //Y[0].arr^[i*U[0].Count+j] := Lagrange(px^,py^,U[0].arr^[j],LagrangeOrder,1);
                      Y[0].arr^[i*U[0].Count+j] := MyLagrange(px,py,U[0].arr^[j],LagrangeOrder,NPoints);
                    end else begin
                      Y[0].arr^[i*U[0].Count+j] := Yvalue;
                    end;

                  inc(c);
                  end;
              end;

           2:   //���������� ������������ ����������� �������
              begin
                if CheckChanges or (Action = f_InitState) then begin
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
                if CheckChanges or (Action = f_InitState) then begin
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
                ErrorEvent(txtInterpolationTypeErr1+IntToStr(InterpolationType)+txtInterpolationTypeErr2, msError, VisualObject );
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

/////////////////////////////////////////////////////////////////////////////
// ���� ���� ����� //////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
//---------------------------------------------------------------------------

end.
