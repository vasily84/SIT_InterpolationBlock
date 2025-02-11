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
    msFvalues, msXvalues: TMemoryStream;
    // ���������� ����������� ��������� ������� ��� ���������� �������������
    Fval1,Fval2,Fval3,Fval4: DoubleArray;
    // ��������� ������, ��������� ��� ������ ������� ������ ������� ���������
    // - ������ ����� �� ��������� ��� ���������� ������
    LastIntervalIndex: NativeInt;
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

    // ��������������� ������� ����������� ����� �����������
    procedure beginPoints(); // ������� ����� ������� ������
    procedure endPoints();
    // ������� ��� ������ ����� �����
    procedure ClearPoints;
    // �������� ����� � ����� ����� �������
    function addPoint(x: Double; F: DoubleArray):Boolean;
    function getPoint_Xi(Pindex: NativeInt): Double;inline;
    function getPoint_Fi(Pindex: NativeInt): PDouble;inline;

    // �������� ����� �������
    procedure swapPoints(i,j :NativeInt);
    // ������������� �� ����������� �������� X
    procedure sortPoints();
    // ����������, ������������� �� ����� ������� �� ����������� ��������� X
    function IsXsorted(): Boolean;
    // ����������, ���� �� ��������� �������� � � ������
    function IsXduplicated(): Boolean;
    // �������� �������� ������� �� ������. ���������� ������ �������-��������, ��������� ������������
    function CmpWithFunction(Func2: TFndimFunctionByPoints1d): Double;

    // ����� ������ ����� - ������ ���������, ������ �������� ����� �������� x
    function FindIntervalIndex_ofX(x: Double): NativeInt;
    // ����� �������� ������� �� �������-���������� ������������
    function IntervalInterpolation(x: Double): PDouble;
    // ����� �������� ������� �� �������� ������������
    function LinearInterpolation(x: Double): PDouble;
  end;

procedure TFndimFunctionByPoints1d_testAll();

implementation

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
  SetLength(Fval1, 0);
  SetLength(Fval2, 0);
  SetLength(Fval3, 0);
  SetLength(Fval4, 0);
end;

// ����� ������� - ������� ��� ������ ����� �����
procedure TFndimFunctionByPoints1d.ClearPoints;
begin
  ApointsCount := 0;
  msFvalues.Clear;
  msXvalues.Clear;
end;

procedure TFndimFunctionByPoints1d.setFdim(NewDim: NativeInt);
begin
  Assert(not((pointsCount>0)and(NewDim<>Fdim)),'��������� ����������� ��� �������� ������� �������');
  AFdim := NewDim;
  // ���������������� ������ ��������� ����������.
  SetLength(Fval1, NewDim);
  SetLength(Fval2, NewDim);
  SetLength(Fval3, NewDim);
  SetLength(Fval4, NewDim);
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

// ��������������� ������� ����������� ����� �����������
procedure TFndimFunctionByPoints1d.beginPoints();
// ������� ����� ������� ������ �� ���������� �����
begin
  isBeginPointsEnter := True;
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

  // y brute stupid swap
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
  maxXindex: NativeInt;
  maxXvalue,xj: Double;
  sortedFlag: Boolean;
begin
// ��������� ������ � �����, ��� ����� ����� ����������� � �����. � ����� ����� ���������
// ��������������� ��������������� ����� �������, ���� ��� ����������� - ��������� ������ ��������.

for i:=pointsCount-1 downto 1 do begin
  maxXvalue := getPoint_Xi(i);
  maxXindex := i;
  sortedFlag := True;
  for j:=i-1 downto 0 do begin
    xj := getPoint_Xi(j);
    if(xj>maxXvalue) then begin // ������� ������� �����
      maxXvalue := xj;
      maxXindex := j;
      sortedFlag := False;
      end;

    // ���� ����������������� �����, ����� ����������� ���
    if xj>getPoint_Xi(j+1) then sortedFlag := False;

    end;
  if(i<>maxXindex) then swapPoints(i, maxXindex);
  // ��������� ����� ������� �����������, ������ �� ���������� ���������
  if sortedFlag then exit;
  end;

end;

function TFndimFunctionByPoints1d.IsXsorted(): Boolean;
// ���������� True ���� ������ ���������� �� �����������. ����� - False
var
  i: NativeInt;
  Xptr: PDouble;
begin
  Result := True;
  Xptr := msXvalues.Memory;

  for i:=0 to pointsCount-2 do begin
    // ��������� ������� � ������� ������ ����������� - ������ ������������
    if(Xptr[i+1]<Xptr[i]) then begin
      Result := False;
      exit;
    end;
  end;

end;

// ����������, ���� �� ��������� �������� � � ������
function TFndimFunctionByPoints1d.IsXduplicated(): Boolean;
var
  i,j: NativeInt;
  Xptr: PDouble;
begin
  Xptr := msXvalues.Memory;

  Result := False;
  if isXsorted() then begin
  // ������ ����������, ���������� �������� ����� - ��������� O(N) - ������� ������
    for i:=0 to pointsCount-2 do begin
      if(Xptr[i+1]=Xptr[i]) then begin // ������ ��������
        Result := True;
        exit;
        end;
    end;
  end
  else begin
  // ������ ������������, ���������� ���� �� ����� - ��������� O(N^2)
    for i:=0 to pointsCount-2 do begin
      for j:=i+1 to pointsCount-1 do begin
        if(Xptr[j]=Xptr[i]) then begin // ������ ��������
          Result := True;
          exit;
          end;
      end;
  end;
  end;

end;

function TFndimFunctionByPoints1d.CmpWithFunction(Func2: TFndimFunctionByPoints1d): Double;
// ���������� ����� ������� �������� ���������
var
  i: NativeInt;
  ASumm,v1,v2: Double;
  F1ptr,F2ptr: PDouble;
begin
  ASumm := 0;
  F1ptr := msFvalues.Memory;
  F2ptr := Func2.msFvalues.Memory;

  Assert(pointsCount=Func2.pointsCount,'������� �������� ��� ������� � ������ ������ �����');

  for i:=0 to Fdim*pointsCount-1 do begin
    v1 := F1ptr[i];
    v2 := F2ptr[i];
    ASumm := ASumm + abs(v1-v2);
  end;

  Result := ASumm;
end;

// ����� ������ ����� - ������ ���������, ������ �������� ����� �������� x
function TFndimFunctionByPoints1d.FindIntervalIndex_ofX(x: Double): NativeInt;
var
  i: NativeInt;
  x0: Double;
begin
  Result := 0;

  // ������ ���� ������ ��������� ����������
  for i:=0 to pointsCount-2 do begin
    if((x>=getPoint_Xi(i))and(x<getPoint_Xi(i+1))) then begin
      Result := i;
      exit;
    end;
    end;

  // ������ �������� �� ���������
  if x< getPoint_Xi(0) then begin
    Result := 0;
    exit;
  end
  else if x>=getPoint_Xi(pointsCount-1) then begin
    Result := pointsCount-1;
    exit;
  end;

end;

// ����� �������� ������� �� �������-���������� ������������
function TFndimFunctionByPoints1d.IntervalInterpolation(x: Double): PDouble;
var
  i: NativeInt;
begin
  i := FindIntervalIndex_ofX(x);
  Result:= getPoint_Fi(i);
end;

// ����� �������� ������� �� �������� ������������
function TFndimFunctionByPoints1d.LinearInterpolation(x: Double): PDouble;
var
  i,k: NativeInt;
  F2,F1: PDouble;
  y,y1,y2,x1,x2,dy,dx,x0: Double;
begin
  i := FindIntervalIndex_ofX(x);

  if i=pointsCount-1 then begin // ��������� ����� ��������� ������ ������������� - ����� �� � �������������.
    Dec(i);
  end;

  x1 := getPoint_Xi(i);
  x2 := getPoint_Xi(i+1);

  F1 := getPoint_Fi(i);
  F2 := getPoint_Fi(i+1);

  for k:=0 to Fdim-1 do begin
    y1 := F1[k];
    y2 := F2[k];
    y := y1+(x-x1)*(y2-y1)/(x2-x1);
    Fval1[k] :=y;
  end;

  // TODO ���������, ����� ������ �� ��������������
  Result:= @Fval1[0];
end;

//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
// �������� ���� ���������
procedure TFndimFunctionByPoints1d_testAll();
var
  testLog: TextFile;
  strTime: string;
  funcA, funcB, funcC: TFndimFunctionByPoints1d;
  a_true,b_true,c_true,d_true,e_true,f_true,g_true,
      a_false,b_false,c_false,d_false,e_false,f_false,g_false: Boolean;
  a_real,b_real,c_real,d_real,e_real,f_real,g_real: Double;
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
  Ylength := 1; // ���� ���������� �������
  funcA.ClearPoints;
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
  Ylength := 3; // ��������� �������, ����������� 3
  funcA.ClearPoints;
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
  end;
  //-------------------------------------------------------------------------
function test_3(): Boolean;
  // ������������ ������� swap
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray: DoubleArray;
    Y2ptr: PDouble;
    a_true: Boolean;
  begin
  Result := True;
  Ylength := 3; // ��������� �������, ����������� 3
  funcA.ClearPoints;
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
  a_true := (x=10)and(Y2ptr[0]=10)and(Y2ptr[1]=100)and(Y2ptr[2]=105);
  Assert(a_true);
  if not(a_true) then Result:=False;

  // �� ����� ����� 10 ������ ���� �������� ����� 5
  x := funcA.getPoint_Xi(10);
  Y2ptr := funcA.getPoint_Fi(10);
  a_true := (x=5)and(Y2ptr[0]=5)and(Y2ptr[1]=25)and(Y2ptr[2]=30);
  Assert(a_true);
  if not(a_true) then Result:=False;

  // ���������, ��� �� ������� �������� ����� 6
  x := funcA.getPoint_Xi(6);
  Y2ptr := funcA.getPoint_Fi(6);
  a_true := (x=6)and(Y2ptr[0]=6)and(Y2ptr[1]=36)and(Y2ptr[2]=41);
  Assert(a_true);
  if not(a_true) then Result:=False;

  SetLength(Yarray, 0 );
  end;

function test_4(): Boolean;
  // ������������ ��������������� ������� ���������� � �������
  var
    Func_zero,Func_ones,Func_i,Func_downcount: TFndimFunctionByPoints1d;
    i: Integer;
    x: Double;
    F: DoubleArray;
  const
    REALZERO = 1e-8;
  begin
    Result := True;

    SetLength(F, 1);
    Func_zero := TFndimFunctionByPoints1d.Create;
    Func_ones := TFndimFunctionByPoints1d.Create;
    Func_i := TFndimFunctionByPoints1d.Create;
    Func_downcount := TFndimFunctionByPoints1d.Create;

    Func_zero.beginPoints();
    Func_ones.beginPoints();
    Func_i.beginPoints();
    Func_downcount.beginPoints();

    for i:=0 to 9 do begin
      x := i;
      F[0] := 0;
      Func_zero.addPoint(x,F);
      F[0] := 1;
      Func_ones.addPoint(x,F);
      F[0] := i;
      Func_i.addPoint(x,F);
      F[0] := 9-i;
      Func_downcount.addPoint(x,F);
    end;

    Func_zero.endPoints();
    Func_ones.endPoints();
    Func_i.endPoints();
    Func_downcount.endPoints();

  // ����� �������� ������������
   a_true := Func_zero.IsXsorted();
   b_true := Func_i.IsXsorted();
   c_true := Func_downcount.IsXsorted();

   Func_i.swapPoints(3,7);  // ������������ ����� �������, ������ ��� �������������
   a_false := Func_i.IsXsorted();
   Func_downcount.swapPoints(0,1);  // ������������ ����� �������, ������ ��� �������������
   b_false := Func_downcount.IsXsorted();

   Assert(a_true and b_true);
   Assert((not a_false)and(not b_false));
   if not (a_true and b_true and c_true) then Result:=False;
   if not ((not a_false)and(not b_false)) then Result:=False;

   // ����� �������� ����������
   Func_i.swapPoints(7,0);
   Func_i.sortPoints();
   a_true := Func_i.IsXsorted();
   Func_downcount.sortPoints();
   b_true := Func_downcount.IsXsorted();
   Assert(a_true and b_true);
   if not (a_true and b_true and c_true) then Result:=False;

   // ����� ��������� �������
   a_real := Func_zero.CmpWithFunction(Func_zero); //
   b_real := Func_zero.CmpWithFunction(Func_ones);
   a_true := abs(a_real) < REALZERO;
   b_true := abs(b_real-10) < REALZERO;

   Assert(a_true and b_true);
   if not (a_true and b_true) then Result:=False;

   // ����� ������ ���������� � �����������
   a_false := Func_i.IsXduplicated();
   b_false := Func_ones.IsXduplicated();
   Func_i.beginPoints();
   Func_ones.beginPoints();
   F[0]:=1;
   x:=9;
   Func_i.addPoint(x, F);
   Func_ones.addPoint(x, F);
   Func_i.endPoints();
   Func_ones.endPoints();
   a_true := Func_i.IsXduplicated();
   b_true := Func_ones.IsXduplicated();

   Assert(a_true and b_true and(not a_false)and(not b_false));
   if not(a_true and b_true and(not a_false)and(not b_false)) then Result:=False;

   SetLength(F, 0);
   FreeAndNil(Func_zero);
   FreeAndNil(Func_ones);
   FreeAndNil(Func_i);
   FreeAndNil(Func_downcount);
  end;

function test_5(): Boolean;
  // ������������ ��������������� ������� ���������� � ������� - ��������� ����� ����������� 3
  var
    Func_zero,Func_ones,Func_i,Func_downcount: TFndimFunctionByPoints1d;
    i: Integer;
    x: Double;
    F: DoubleArray;
  const
    REALZERO = 1e-8;
    VSIZE = 3;
  begin
    Result := True;

    SetLength(F, VSIZE);
    Func_zero := TFndimFunctionByPoints1d.Create;
    Func_zero.setFdim(3);

    Func_ones := TFndimFunctionByPoints1d.Create;
    Func_ones.setFdim(3);

    Func_i := TFndimFunctionByPoints1d.Create;
    Func_i.setFdim(3);

    Func_downcount := TFndimFunctionByPoints1d.Create;
    Func_downcount.setFdim(3);

    Func_zero.beginPoints();
    Func_ones.beginPoints();
    Func_i.beginPoints();
    Func_downcount.beginPoints();

    for i:=0 to 9 do begin
      x := i;
      F[0] := 0;
      F[1] := 0;
      F[2] := 0;
      Func_zero.addPoint(x,F);

      F[0] := 1;
      F[1] := 1;
      F[2] := 1;
      Func_ones.addPoint(x,F);

      F[0] := i;
      F[1] := i;
      F[2] := i;
      Func_i.addPoint(x,F);

      F[0] := 9-i;
      F[1] := 9-i;
      F[2] := 9-i;
      Func_downcount.addPoint(x,F);

    end;

    Func_zero.endPoints();
    Func_ones.endPoints();
    Func_i.endPoints();
    Func_downcount.endPoints();

  // ����� �������� ������������
   a_true := Func_zero.IsXsorted();
   b_true := Func_i.IsXsorted();
   c_true := Func_downcount.IsXsorted();

   Func_i.swapPoints(3,7);  // ������������ ����� �������, ������ ��� �������������
   a_false := Func_i.IsXsorted();
   Func_downcount.swapPoints(0,1);  // ������������ ����� �������, ������ ��� �������������
   b_false := Func_downcount.IsXsorted();

   Assert(a_true and b_true);
   Assert((not a_false)and(not b_false));
   if not (a_true and b_true and c_true) then Result:=False;
   if not ((not a_false)and(not b_false)) then Result:=False;

   // ����� �������� ����������
   Func_i.swapPoints(7,0);
   Func_i.sortPoints();
   a_true := Func_i.IsXsorted();
   Func_downcount.sortPoints();
   b_true := Func_downcount.IsXsorted();
   Assert(a_true and b_true);
   if not (a_true and b_true and c_true) then Result:=False;

   // ����� ��������� �������
   a_real := Func_zero.CmpWithFunction(Func_zero); //
   b_real := Func_zero.CmpWithFunction(Func_ones);
   a_true := abs(a_real) < REALZERO;
   b_true := abs(b_real-30) < REALZERO;

   Assert(a_true and b_true);
   if not (a_true and b_true) then Result:=False;

   // ����� ������ ���������� � �����������
   a_false := Func_i.IsXduplicated();
   b_false := Func_ones.IsXduplicated();
   Func_i.beginPoints();
   Func_ones.beginPoints();
   F[0]:=1;
   x:=9;
   Func_i.addPoint(x, F);
   Func_ones.addPoint(x, F);
   Func_i.endPoints();
   Func_ones.endPoints();
   a_true := Func_i.IsXduplicated();
   b_true := Func_ones.IsXduplicated();

   Assert(a_true and b_true and(not a_false)and(not b_false));
   if not(a_true and b_true and(not a_false)and(not b_false)) then Result:=False;

   SetLength(F, 0);
   FreeAndNil(Func_zero);
   FreeAndNil(Func_ones);
   FreeAndNil(Func_i);
   FreeAndNil(Func_downcount);
  end;
//----------------------------------------------------------------------------
function test_6(): Boolean;
  // ������������ ������������ ������� ������������, �������-���������� � ��������
  var
    i: NativeInt;
    x: Double;
    F:DoubleArray;
  const
    REALZERO = 1e-8;
  begin
  Result := True;
  funcA.ClearPoints;
  funcA.setFdim(1);

  funcB.ClearPoints;
  funcB.setFdim(1);

  funcC.ClearPoints;
  funcC.setFdim(1);
  SetLength(F, 1);

  funcA.beginPoints;
  funcB.beginPoints;
  funcC.beginPoints;

  for i:=-100 to 100 do begin
    x := i;
    F[0] := x;            // ��������
    funcA.addPoint(x, F);

    F[0] := x*x+x;
    funcB.addPoint(x, F);

    F[0] := sin(PI*x/20); // �����
    funcC.addPoint(x, F);
    end;

  funcA.endPoints;
  funcB.endPoints;
  funcC.endPoints;

  // �������-����������
  x := 0.1;
  a_real := funcA.IntervalInterpolation(x)[0];
  b_real := funcB.IntervalInterpolation(x)[0];
  c_real := funcC.IntervalInterpolation(x)[0];

  a_true := abs(a_real-0)<REALZERO;
  b_true := abs(b_real-0)<REALZERO;
  c_true := abs(c_real-0)<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  x := 10;
  a_real := funcA.IntervalInterpolation(x)[0];
  b_real := funcB.IntervalInterpolation(x)[0];
  c_real := funcC.IntervalInterpolation(x)[0];

  a_true := abs(a_real-10)<REALZERO;
  b_true := abs(b_real-110)<REALZERO;
  c_true := abs(c_real-sin(PI*10/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // �������-���������� �� ��������� ��������� ���������� - �������������
  x := 110;
  a_real := funcA.IntervalInterpolation(x)[0];
  b_real := funcB.IntervalInterpolation(x)[0];
  c_real := funcC.IntervalInterpolation(x)[0];

  a_true := abs(a_real-100)<REALZERO;
  b_true := abs(100*100+100-b_real)<REALZERO;
  c_true := abs(c_real-sin(PI*100/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // �������-���������� �� ��������� ��������� ���������� - �������������
  x := -110;
  a_real := funcA.IntervalInterpolation(x)[0];
  b_real := funcB.IntervalInterpolation(x)[0];
  c_real := funcC.IntervalInterpolation(x)[0];

  a_true := abs(a_real+100)<REALZERO;
  b_true := abs(100*100-100-b_real)<REALZERO;
  c_true := abs(c_real-sin(PI*-100/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // ��������
  x := 0.1;
  a_real := funcA.LinearInterpolation(x)[0];
  b_real := funcB.LinearInterpolation(x)[0];
  c_real := funcC.LinearInterpolation(x)[0];

  a_true := abs(a_real-0.1)<REALZERO;
  b_true := abs(b_real-0.2)<REALZERO;
  c_true := abs(c_real-0.0156434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  x := 10;
  a_real := funcA.LinearInterpolation(x)[0];
  b_real := funcB.LinearInterpolation(x)[0];
  c_real := funcC.LinearInterpolation(x)[0];

  a_true := abs(a_real-10)<REALZERO;
  b_true := abs(b_real-110)<REALZERO;
  c_true := abs(c_real-1)<1e-4;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // �������� �� ��������� ��������� ���������� - �������������
  x := 110;
  a_real := funcA.LinearInterpolation(x)[0];
  b_real := funcB.LinearInterpolation(x)[0];
  c_real := funcC.LinearInterpolation(x)[0];

  a_true := abs(a_real-110)<REALZERO;
  b_true := abs(12100-b_real)<REALZERO;
  c_true := abs(c_real+1.56434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // �������� �� ��������� ��������� ���������� - �������������
  x := -110;
  a_real := funcA.LinearInterpolation(x)[0];
  b_real := funcB.LinearInterpolation(x)[0];
  c_real := funcC.LinearInterpolation(x)[0];

  a_true := abs(a_real+110)<REALZERO;
  b_true := abs(11880-b_real)<REALZERO;
  c_true := abs(c_real-1.56434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;


  SetLength(F, 0);
  end;

//---------------------------------------------------------------------------
function test_7(): Boolean;
  // ������������ ������������ ������� ������������, �������-���������� � ��������
  var
    i: NativeInt;
    x: Double;
    F:DoubleArray;
  const
    REALZERO = 1e-8;
  begin
  Result := True;
  funcA.ClearPoints;
  funcA.setFdim(3);

  SetLength(F, 3);

  funcA.beginPoints;
  for i:=-100 to 100 do begin
    x := i;
    F[0] := x;            // ��������
    F[1] := x*x+x;
    F[2] := sin(PI*x/20); // �����
    funcA.addPoint(x, F);
    end;
  funcA.endPoints;

  // �������-����������
  x := 0.1;
  a_real := funcA.IntervalInterpolation(x)[0];
  b_real := funcA.IntervalInterpolation(x)[1];
  c_real := funcA.IntervalInterpolation(x)[2];

  a_true := abs(a_real-0)<REALZERO;
  b_true := abs(b_real-0)<REALZERO;
  c_true := abs(c_real-0)<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  x := 10;
  a_real := funcA.IntervalInterpolation(x)[0];
  b_real := funcA.IntervalInterpolation(x)[1];
  c_real := funcA.IntervalInterpolation(x)[2];

  a_true := abs(a_real-10)<REALZERO;
  b_true := abs(b_real-110)<REALZERO;
  c_true := abs(c_real-sin(PI*10/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // �������-���������� �� ��������� ��������� ���������� - �������������
  x := 110;
  a_real := funcA.IntervalInterpolation(x)[0];
  b_real := funcA.IntervalInterpolation(x)[1];
  c_real := funcA.IntervalInterpolation(x)[2];

  a_true := abs(a_real-100)<REALZERO;
  b_true := abs(100*100+100-b_real)<REALZERO;
  c_true := abs(c_real-sin(PI*100/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // �������-���������� �� ��������� ��������� ���������� - �������������
  x := -110;
  a_real := funcA.IntervalInterpolation(x)[0];
  b_real := funcA.IntervalInterpolation(x)[1];
  c_real := funcA.IntervalInterpolation(x)[2];

  a_true := abs(a_real+100)<REALZERO;
  b_true := abs(100*100-100-b_real)<REALZERO;
  c_true := abs(c_real-sin(PI*-100/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // ��������
  x := 0.1;
  a_real := funcA.LinearInterpolation(x)[0];
  b_real := funcA.LinearInterpolation(x)[1];
  c_real := funcA.LinearInterpolation(x)[2];

  a_true := abs(a_real-0.1)<REALZERO;
  b_true := abs(b_real-0.2)<REALZERO;
  c_true := abs(c_real-0.0156434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  x := 10;
  a_real := funcA.LinearInterpolation(x)[0];
  b_real := funcA.LinearInterpolation(x)[1];
  c_real := funcA.LinearInterpolation(x)[2];

  a_true := abs(a_real-10)<REALZERO;
  b_true := abs(b_real-110)<REALZERO;
  c_true := abs(c_real-1)<1e-4;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // �������� �� ��������� ��������� ���������� - �������������
  x := 110;
  a_real := funcA.LinearInterpolation(x)[0];
  b_real := funcA.LinearInterpolation(x)[1];
  c_real := funcA.LinearInterpolation(x)[2];

  a_true := abs(a_real-110)<REALZERO;
  b_true := abs(12100-b_real)<REALZERO;
  c_true := abs(c_real+1.56434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // �������� �� ��������� ��������� ���������� - �������������
  x := -110;
  a_real := funcA.LinearInterpolation(x)[0];
  b_real := funcA.LinearInterpolation(x)[1];
  c_real := funcA.LinearInterpolation(x)[2];

  a_true := abs(a_real+110)<REALZERO;
  b_true := abs(11880-b_real)<REALZERO;
  c_true := abs(c_real-1.56434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;


  SetLength(F, 0);
  end;

//----------------------------------------------------------------------------

begin
  //Assert(False, '���� �� ������ ��� ���������, Asserts ���������� � ��������' );
  funcA := TFndimFunctionByPoints1d.Create;
  funcB := TFndimFunctionByPoints1d.Create;
  funcC := TFndimFunctionByPoints1d.Create;

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
    if test_5() then writeln(testLog,'test5     Ok') else writeln(testLog,'!! test5  FAILED!!');
    if test_6() then writeln(testLog,'test6     Ok') else writeln(testLog,'!! test6  FAILED!!');
    if test_7() then writeln(testLog,'test7     Ok') else writeln(testLog,'!! test7  FAILED!!');

  finally
    write(testLog, 'END of autotest routine log file');
    CloseFile(testLog);
    FreeAndNil(funcA);
    FreeAndNil(funcB);
    FreeAndNil(funcC);
  end;

end;

{$POINTERMATH OFF}
{$ASSERTIONS OFF}
end.
