//**************************************************************************//
 // ������ �������� ��� �������� ��������� ������ ������� ����-4             //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit InterpolationBlocks_unit;

 //***************************************************************************//
 //                ����� N-������ ������� �� 1 ���������, �������� �������
 //***************************************************************************//

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath;

{$POINTERMATH ON}  // �������� ���������� � ����� �� -> ������ ����������� ������ ��� ������ ���������� � ��������
{$ASSERTIONS ON}

// ���� � ������ �� ���������. ����� ������ ������������
const autoTest_FileName = 'e:\USERDISK\SIM_WORK\�����_������������\InterpolationBlocks_autoTestLog.txt';


type
 DoubleArray = Array of Double;

type
  TFndimFunctionByPoints1d = class(TObject)
  // N-������ ������� �� 1 ���������, �������� �������
  protected
    ApointsCount: NativeInt; // ����� �������� ����� �������
    AFdim: NativeInt; // ������ ��������� ������� �������
    isBeginPointsEnter: Boolean; // ��������� ������ ������� beginPoints() � endPoints();
    msFvalues, msXvalues :TMemoryStream;
  public

    constructor Create();
    destructor Destroy;override;

    // �������������� ����������� ��������� �������
    procedure setFdim(NewDim: NativeInt);

    // ������� ��� ������ �������
    function pointsCount: NativeInt;inline;
    function Fdim: NativeInt;inline; // ������ ��������� ������� �������,

    // �������� ������� �� ������ �� ����� �� �����
    function LoadFromTlb(fileName: string):Boolean;
    function LoadFromCsv(fileName: string):Boolean;
    function LoadFromJson(fileName: string):Boolean;
    function LoadFromFile(fileName: string):Boolean;

    // ������ � ����
    function SaveToCsv(fileName: string):Boolean;

    // ������� ������� - ������ ����� � ������ ���������������� ���������� -
    // ��� ������� � ������������.
    function CreateFunction_ByUser(kind: NativeInt):Boolean;

    // ��������������� ������� ����������� ����� �����������
    function beginPoints():Boolean; // ������� ����� ������� ������
    procedure endPoints();
    // �������� ����� � ����� ����� �������
    function addPoint(x: Double; F: DoubleArray):Boolean;
    function getPoint_Xi(Pindex: NativeInt): Double;
    function getPoint_Fi(Pindex: NativeInt): PDouble;

    // �������� ����� �������
    procedure swapPoints(i,j :NativeInt);
    // ������������� �� ����������� �������� X
    procedure sortPoints();
  end;

function TFndimFunctionByPoints1d_testAll():Boolean;

implementation

function DoubleArray_AB_Cmp(a,b: DoubleArray; ALength: NativeInt): Double;
// �������� ��� ������� ���� Double � ������ ALength ���������.
// ���������� ����� ������� �������� ���������
var
  i: NativeInt;
  ASumm,v1,v2: Double;
begin
  ASumm := 0;
  for i:=0 to ALength-1 do begin
    v1 := a[i];
    v2 := b[i];
    ASumm := ASumm + abs(v1-v2);
    end;

  Result := ASumm;
end;

function DoubleArray_IsOrdered(a: DoubleArray; ALength: NativeInt): Boolean;
// ���������� True ���� ������ ���������� �� �����������. ����� - False
var
  i: NativeInt;
begin
  Result := True;

  for i:=0 to ALength-2 do begin
    // ��������� ������� � ������� ������ ����������� - ������ ������������
    if(a[i+1]<a[i]) then Result := False; exit;
  end;

end;

constructor TFndimFunctionByPoints1d.Create();
begin
  msFvalues := TMemoryStream.Create;
  msXvalues := TMemoryStream.Create;

  ApointsCount := 0; // ����� ���� ���
  setFdim(1); // ������ ��������� ������� ������� - �� ��������� 1
  isBeginPointsEnter := False;

end;

destructor TFndimFunctionByPoints1d.Destroy;
begin
  inherited;
  FreeAndNil(msFvalues);
  FreeAndNil(msXvalues);

end;

procedure TFndimFunctionByPoints1d.setFdim(NewDim: NativeInt);
begin
  Assert(not((pointsCount>0)and(NewDim<>Fdim)),'��������� ����������� ��� �������� ������� �������');
  AFdim := NewDim;
end;

function TFndimFunctionByPoints1d.pointsCount: NativeInt;
begin
  Result := APointsCount;
end;

function TFndimFunctionByPoints1d.Fdim: NativeInt;
begin
  Result := AFdim;
end;

function TFndimFunctionByPoints1d.LoadFromTlb(fileName: string):Boolean;
begin
  Result := False;
end;

function TFndimFunctionByPoints1d.LoadFromCsv(fileName: string):Boolean;
begin
  Result := False;
end;

function TFndimFunctionByPoints1d.LoadFromJson(fileName: string):Boolean;
begin
  Result := False;
end;

function TFndimFunctionByPoints1d.LoadFromFile(fileName: string):Boolean;
begin
  Result := False;
end;

// ������ � ����
function TFndimFunctionByPoints1d.SaveToCsv(fileName: string):Boolean;
begin
  Result := False;
end;

// ������� ������� - ������ ����� � ������ ���������������� ���������� -
// ��� ������� � ������������.
function TFndimFunctionByPoints1d.CreateFunction_ByUser(kind:NativeInt):Boolean;
begin
  Result := False;
end;

// ��������������� ������� ����������� ����� �����������
function TFndimFunctionByPoints1d.beginPoints():Boolean;
// ������� ����� ������� ������ �� ���������� �����
begin
  isBeginPointsEnter := True;
  Result := True;
end;

procedure TFndimFunctionByPoints1d.endPoints();
begin
  isBeginPointsEnter := False;
end;

// �������� ����� � ����� ����� �������
function TFndimFunctionByPoints1d.addPoint(x: Double; F: DoubleArray):Boolean;
begin
  Assert(isBeginPointsEnter, '���������� ����� � ������� �� ��������� beginPoints() endPoints()');

  msXvalues.Write(x,sizeof(Double)); // ��������� ��������
  msFvalues.Write(F[0],sizeof(Double)*Fdim); // ��������� ������-��������
  Inc(ApointsCount);
  Result := True;
end;

function TFndimFunctionByPoints1d.getPoint_Xi(Pindex: NativeInt): Double;
// ������� �������� X �� ������� Pindex, �.�. �������� ������� � �����
var
  Xptr: PDouble;
begin
  Xptr := msXvalues.Memory;
  Result := Xptr[Pindex];
end;

function TFndimFunctionByPoints1d.getPoint_Fi(Pindex: NativeInt): PDouble;
// ������� ��������� �� ������ �������� Y �� ������� Pindex, �.�. ��������� �������� ������� � �����
var
  Fptr: PDouble;
begin
  Fptr := msFvalues.Memory;
  Result := @Fptr[Pindex*Fdim];
end;

// �������� i,j ����� ������� �������
procedure TFndimFunctionByPoints1d.swapPoints(i,j :NativeInt);
var
  Xptr,Fptr: PDouble;
  xval, yval: Double;
  //ybuf: DoubleArray;
  k: NativeInt;
begin
  Xptr := msXvalues.Memory;
  Fptr := msFvalues.Memory;
  // x swap
  xval := Xptr[i];
  Xptr[i] := Xptr[j];
  Xptr[j] :=xval;

  // y swap TODO - ������ �� ��������?
  //SetLength(ybuf,Ylength);
  //Move(Yptr[i], Ybuf, sizeof(Double)*Ylength);
  //Move(Yptr[j], Yptr[i], sizeof(Double)*Ylength);
  //Move(Ybuf, Yptr[j], sizeof(Double)*Ylength);
  //SetLength(ybuf, 0);

  // y stupid swap
  for k:=0 to Fdim-1 do begin
    yval := Fptr[i*Fdim+k];
    Fptr[i*Fdim+k] := Fptr[j*Fdim+k];
    Fptr[j*Fdim+k] := yval;
    end;
end;

// ������������� �� ����������� �������� X
procedure TFndimFunctionByPoints1d.sortPoints();
var
  i,j: NativeInt;
  minXindex: NativeInt;
  minXvalue,xj: Double;
begin

for i:=0 to pointsCount-2 do begin
  minXvalue := getPoint_Xi(i);
  minXindex := i;
  for j:=i+1 to pointsCount-1 do begin
    xj := getPoint_Xi(j);
    if(xj<minXvalue) then minXvalue:=xj; minXindex:=j;
    //
    end;
  if(i<>minXindex) then swapPoints(i,minXindex);
  end;

end;

//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
// �������� ���� ���������
function TFndimFunctionByPoints1d_testAll():Boolean;
var
  testLog: TextFile;
  strTime: string;
  funcA, funcB, funcC: TFndimFunctionByPoints1d;
  //-----------------------------------------------------------------------
function test_1():Boolean;
  // c������� �������-�������,
  // ���������� ����� �������,
  // ������������ ������ � ������,
  // ������� ���������� �����
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray: DoubleArray;
  begin
  Result := True;
  funcA := TFndimFunctionByPoints1d.Create;
  Ylength := 1; // ���� ���������� �������
  funcA.setFdim(Ylength);
  SetLength(Yarray,Ylength);

  funcA.beginPoints();
  for i:=0 to 9 do begin // ��������� ����������� 10 �����
    x := i;
    y := i;
    Yarray[0]:=y;
    funcA.addPoint(x,Yarray);
    end;
  funcA.endPoints();

  Assert(funcA.pointsCount = 10); // �������� ���������� �����
  if not (funcA.pointsCount = 10) then Result:=False;

  x := funcA.getPoint_Xi(3); // �������� ������������ ������-������
  y := funcA.getPoint_Fi(3)[0];

  Assert((x=3)and(y=3));
  if not((x=3)and(y=3)) then Result:=False;

  SetLength(Yarray, 0 );
  FreeAndNil(funcA);
  end;
  //--------------------------------------------------------------------------
function test_2():Boolean;
  // c������� �������-������� � ��������� �������,
  // ���������� ����� �������,
  // ������������ ������ � ������,
  // ������� ���������� �����
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray: DoubleArray;
    Y2ptr: PDouble;
    cond1: Boolean;

  begin
  Result := True;
  funcA := TFndimFunctionByPoints1d.Create;
  Ylength := 3; // ��������� �������, ����������� 3
  funcA.setFdim(Ylength);
  SetLength(Yarray,Ylength);

  funcA.beginPoints();
  for i:=0 to 19 do begin // ��������� ����������� 20 �����
    x := i;
    y := i;
    Yarray[0] := y;
    Yarray[1] := y*y;
    Yarray[2] := y*y+5;
    funcA.addPoint(x,Yarray);
    end;
  funcA.endPoints();

  Assert(funcA.pointsCount = 20); // �������� ���������� �����
  if not (funcA.pointsCount = 20) then Result:=False;

  x := funcA.getPoint_Xi(0); // �������� ������������ ������-������
  Y2ptr := funcA.getPoint_Fi(0);
  cond1 := (x=0)and(Y2ptr[0]=0)and(Y2ptr[1]=0)and(Y2ptr[2]=5);
  Assert(cond1);
  if not(cond1) then Result:=False;

  x := funcA.getPoint_Xi(3); // �������� ������������ ������-������
  Y2ptr := funcA.getPoint_Fi(3);
  cond1 := (x=3)and(Y2ptr[0]=3)and(Y2ptr[1]=9)and(Y2ptr[2]=14);
  Assert(cond1);
  if not(cond1) then Result:=False;

  x := funcA.getPoint_Xi(10); // �������� ������������ ������-������
  Y2ptr := funcA.getPoint_Fi(10);
  cond1 := (x=10)and(Y2ptr[0]=10)and(Y2ptr[1]=100)and(Y2ptr[2]=105);
  Assert(cond1);
  if not(cond1) then Result:=False;

  SetLength(Yarray, 0 );
  FreeAndNil(funcA);
  end;
  //-------------------------------------------------------------------------
function test_3(): Boolean;
  // ������������ ������� swap
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray: DoubleArray;
    Y2ptr: PDouble;
    cond1: Boolean;
  begin
  Result := True;
  funcA := TFndimFunctionByPoints1d.Create;
  Ylength := 3; // ��������� �������, ����������� 3
  funcA.setFdim(Ylength);
  SetLength(Yarray,Ylength);

  funcA.beginPoints();
  for i:=0 to 19 do begin // ��������� ����������� 20 �����
    x := i;
    y := i;
    Yarray[0] := y;
    Yarray[1] := y*y;
    Yarray[2] := y*y+5;
    funcA.addPoint(x,Yarray);
    end;
  funcA.endPoints();

  // ������ ������� ����� 5 � 10
  funcA.swapPoints(5,10);

  // �� ����� ����� 5 ������ ���� �������� ����� 10
  x := funcA.getPoint_Xi(5);
  Y2ptr := funcA.getPoint_Fi(5);
  cond1 := (x=10)and(Y2ptr[0]=10)and(Y2ptr[1]=100)and(Y2ptr[2]=105);
  Assert(cond1);
  if not(cond1) then Result:=False;

  // �� ����� ����� 10 ������ ���� �������� ����� 5
  x := funcA.getPoint_Xi(10);
  Y2ptr := funcA.getPoint_Fi(10);
  cond1 := (x=5)and(Y2ptr[0]=5)and(Y2ptr[1]=25)and(Y2ptr[2]=30);
  Assert(cond1);
  if not(cond1) then Result:=False;

  // ���������, ��� �� ������� �������� ����� 6
  x := funcA.getPoint_Xi(6);
  Y2ptr := funcA.getPoint_Fi(6);
  cond1 := (x=6)and(Y2ptr[0]=6)and(Y2ptr[1]=36)and(Y2ptr[2]=41);
  Assert(cond1);
  if not(cond1) then Result:=False;

  SetLength(Yarray, 0 );
  FreeAndNil(funcA);
  end;

function test_4(): Boolean;
  // ������������ ��������������� ������� ���������� � �������
  var
    arr_zero,arr_ones,arr_i,arr_i2,arr_downcount,arr2,arr3,arr4,arr5: DoubleArray;
    i: Integer;
    a_true,b_true,c_true,d_true,e_true,f_true,g_true,
      a_false,b_false,c_false,d_false,e_false,f_false,g_false: Boolean;
    a_real,b_real,c_real,d_real,e_real,f_real: Double;
  const
    REALZERO = 1e-8;
  begin
    Result := True;

    SetLength(arr_zero, 10);
    SetLength(arr_ones, 10);
    SetLength(arr_i, 10);
    SetLength(arr_i2, 10);
    SetLength(arr_downcount, 10);
    SetLength(arr2, 10);
    SetLength(arr3, 10);
    SetLength(arr4, 10);

    for i:=0 to 9 do begin
      arr_zero[i] := 0;
      arr_ones[i] := 1;
      arr_i[i] := i;
      arr_i2[i] := i*i;
      arr_downcount[i] := 9-i;
      arr2[i] := i;
      arr3[i] := i;
      arr4[i] := i;
    end;

  // ����� �������� ������������
   a_true := DoubleArray_isOrdered(arr_zero, 10);
   b_true := DoubleArray_isOrdered(arr_i, 10);
   c_true := DoubleArray_isOrdered(arr_i, 10);

   a_false := DoubleArray_isOrdered(arr_downcount, 10);

   Assert(a_true and b_true and c_true);
   Assert(not a_false);
   if not (a_true and b_true and c_true) then Result:=False; exit;
   if (a_false) then Result:=False; exit;

   // ����� ���������

   // ����� ����������

   SetLength(arr_zero, 0);
   SetLength(arr_ones, 0);
   SetLength(arr_i2, 0);
   SetLength(arr2, 0);
   SetLength(arr3, 0);
   SetLength(arr4, 0);
  end;

procedure test_5();
  // ������������ �������� ������������
  begin

  end;

begin
  //Assert(False, '���� �� ������ ��� ���������, Asserts ���������� � ��������' );
  try
    AssignFile(testLog, autoTest_FileName);
    Rewrite(testLog);
    writeln(testLog, 'autotest report by InterpolationBlocks_unit.pas');
    DateTimeToString(strTime, 'dd/mm/yy hh:mm:ss', Now());
    writeln(testLog, strTime);
    writeln(testLog, 'BEGIN');

    if test_1() then writeln(testLog,'test1     Ok') else writeln(testLog,'!! test1  FAILED!!');
    if test_2() then writeln(testLog,'test2     Ok') else writeln(testLog,'!! test2  FAILED!!');
    if test_3() then writeln(testLog,'test3     Ok') else writeln(testLog,'!! test3  FAILED!!');
    if test_4() then writeln(testLog,'test4     Ok') else writeln(testLog,'!! test4  FAILED!!');

  finally
    write(testLog, 'END of autotest routine log file');
    CloseFile(testLog);
  end;
end;

{$POINTERMATH OFF}
{$ASSERTIONS OFF}
end.
