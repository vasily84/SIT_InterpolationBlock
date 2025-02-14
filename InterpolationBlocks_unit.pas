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

type
  TFndimFunctionByPoints1d = class(TObject)
  // N-������ ������� �� 1 ���������, �������� �������
  protected
    ApointsCount: NativeInt; // ����� �������� ����� �������
    AFdim: NativeInt; // ������ ��������� ������� �������
    isBeginPointsEnter: Boolean; // ��������� ������ ������� beginPoints() � endPoints();
    msFvalues, msXvalues: TMemoryStream;
    Fval3,Fval4: array of double;
  public
    // ���������� ����������� ��������� ������� ��� ���������� �������������
    Fval1,Fval2: array of double;
    ExtrapolationType: NativeInt; // ��� ������������� - ������������
    LagrangeOrder: NativeInt; // ������� ������������ ��� ������ ��������

    constructor Create();
    destructor Destroy;override;

    // �������������� ����������� ��������� �������
    procedure setFdim(NewDim: NativeInt);

    // ������� ��� ������ �������
    function pointsCount: NativeInt;inline;
    function Fdim: NativeInt;inline; // ������ ��������� ������� �������,

    // ��������������� ������� ����������� ����� �����������
    procedure beginPoints(); // ������� ����� ������� ������
    procedure endPoints();
    // ������� ��� ������ ����� �����
    procedure ClearPoints;
    // �������� ����� � ����� ����� �������
    function addPoint(x: Double; F: PDouble):Boolean;
    function getPoint_Xi(Pindex: NativeInt): Double;inline;
    //function getPoint_Fi(Pindex: NativeInt): PDouble;inline;
    procedure getPoint_Fi(Pindex: NativeInt; Fresult: PDouble);

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
    function FindIntervalIndex_ofX(x: Double; var outOfXflag:Boolean): NativeInt;

    // ����� �������� ������� �� �������-���������� ������������
    procedure IntervalInterpolation(x: Double; Fresult: PDouble);
    // ����� �������� ������� �� �������� ������������
    procedure LinearInterpolation(x: Double; Fresult: PDouble);
    // ����� �������� ������� �� ������������ ������� ��������
    procedure LagrangeInterpolation(x: Double; Fresult: PDouble);
    // ����� �������� ������� ������������� ����������� ���������
    procedure SplineInterpolation(x: Double; Fresult: PDouble);

  end;

implementation

constructor TFndimFunctionByPoints1d.Create();
begin
  msFvalues := TMemoryStream.Create;
  msXvalues := TMemoryStream.Create;

  ApointsCount := 0; // ����� ���� ���
  setFdim(1); // ������ ��������� ������� ������� - �� ��������� 1
  isBeginPointsEnter := False;

  ExtrapolationType := 0;
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
function TFndimFunctionByPoints1d.addPoint(x: Double; F: PDouble):Boolean;
var
  i: Integer;
  v: Double;
begin
  Assert(isBeginPointsEnter, '���������� ����� � ������� �� ��������� beginPoints() endPoints()');

  msXvalues.Write(x,sizeof(Double)); // ��������� ��������
  //msFvalues.Write(F^,sizeof(Double)*Fdim); // ��������� ������-��������
  for i:=0 to Fdim-1 do begin
    v:= F[i];
    msFvalues.Write(F[i],sizeof(Double));
    end;
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

procedure TFndimFunctionByPoints1d.getPoint_Fi(Pindex: NativeInt; Fresult: PDouble);
// ������� ��������� �� ������ �������� Y �� ������� Pindex, �.�. ��������� �������� ������� � �����
var
  Fptr: PDouble;
  i,j,count: Integer;
  v: Double;
begin
  count := msFvalues.Size div sizeof(Double);
  Fptr := msFvalues.Memory;

  //for i:=0 to count-1 do begin
  //  v := Fptr[i];
  //  end;

  for i:=0 to Fdim-1 do begin
    v := Fptr[Pindex*Fdim+i];
    Fresult[i] := Fptr[Pindex*Fdim+i];
    end;

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
function TFndimFunctionByPoints1d.FindIntervalIndex_ofX(x: Double; var outOfXflag:Boolean): NativeInt;
var
  i: NativeInt;
  x0: Double;
begin
  Result := 0;
  outOfXflag := False;

  // ������ ���� ������ ��������� ����������
  for i:=0 to pointsCount-2 do begin
    if((x>=getPoint_Xi(i))and(x<getPoint_Xi(i+1))) then begin
      Result := i;
      exit;
      end;
    end;

  Result := 0;
  outOfXflag := True;

  // ������ �������� �� ���������
  if x< getPoint_Xi(0) then begin
    Result := 0;
    exit;
    end;

  if x>=getPoint_Xi(pointsCount-1) then begin
    Result := pointsCount-1;
    exit;
    end;

end;

// ����� �������� ������� �� �������-���������� ������������
procedure TFndimFunctionByPoints1d.IntervalInterpolation(x: Double; Fresult: PDouble);
var
  i,j: NativeInt;
  outOfXflag: Boolean;
begin
  i := FindIntervalIndex_ofX(x, outOfXflag);

  if (not outOfXflag)or(ExtrapolationType=2) then begin // ������������� �� ���������
    getPoint_Fi(i, Fresult);
    exit;
    end;

  if outOfXflag then begin
    case ExtrapolationType of
      0,2:  // ��������� ��� ���������, ���� ���������������� �������
        begin
        getPoint_Fi(i, Fresult);
        exit;
        end;

      1: // ���� ��� ���������
        begin
          for j:=0 to Fdim-1 do begin
            Fresult[j] := 0;
            end;
        end;
      else
        Assert(False,'����� ������������� '+IntToStr(ExtrapolationType)+' �� ����������');
      end;
    end;
end;

// ����� �������� ������� �� ������������ ���������
procedure TFndimFunctionByPoints1d.LagrangeInterpolation(x: Double;Fresult: PDouble);
var
  i,j,k: NativeInt;
  y,dy,dx,x0, RR: Double;
  X1, Y1: PDouble;
  M: NativeInt; // M-����� ������ ���������� �������� ������������ - ������ �������, �� �������� ������ �������
  P1,P2 : Double;
  outOfXflag: Boolean;
begin
  i := FindIntervalIndex_ofX(x, outOfXflag);

  X1 := msXvalues.Memory;
  Y1 := msFvalues.Memory;

  if (not outOfXflag)or(ExtrapolationType=2) then begin
      // ������ ������������ �� ��������
      // TODO ��������, ��� �������� M - ����� !!!
      //M:= i - (LagrangeOrder div 2); // �������� M �����
      M := i;

      if ((M+LagrangeOrder) > (pointsCount-1)) then begin
        M:= pointsCount-LagrangeOrder-1;
        end;

      if M<0 then begin
        M:=0;
        end;

      // ������ ������������, ��� ���������� �� InterpolFunc.pas
      // TODO - ���������, ������ �� ��� ���������� ����� !!!
      for k:=0 to Fdim-1 do begin
        RR := 0.0; //
        for j:=M to M+LagrangeOrder-1 do begin
          P1 := 1.0;
          P2 := 1.0;

          for i:=M to M+LagrangeOrder-1 do begin
            if (i=j) then continue;
            P1 := P1*(X-X1[i]);
            P2 := P2*(X1[j]-X1[i]);
            end;

          RR:=RR + (P1/P2)*Y1[Fdim*j+k];
          end;

        Fresult[k] := RR;
      end;

      EXIT;  // ������ �� ������������ ���������
    end;

  if outOfXflag then begin
    case ExtrapolationType of
      0:  // ��������� ��� ���������
        begin
        getPoint_Fi(i, Fresult);
        exit;
        end;

      1: // ���� ��� ���������
        begin
          for j:=0 to Fdim-1 do begin
            Fresult[j] := 0;
            end;
        end;
      else
        Assert(False,'����� ������������� '+IntToStr(ExtrapolationType)+' �� ����������');
      end;
    end;
end;

//===========================================================================
// ����� �������� ������� �� ��������� ������ ������������
procedure TFndimFunctionByPoints1d.LinearInterpolation(x: Double;Fresult: PDouble);
var
  i,j,k: NativeInt;
  y,y1,y2,x1,x2,dy,dx,x0: Double;
  outOfXflag: Boolean;
begin
  i := FindIntervalIndex_ofX(x, outOfXflag);

  if (not outOfXflag)or(ExtrapolationType=2) then begin
    if i=pointsCount-1 then begin // ��������� ����� ��������� ������ ������������� - ����� �� � �������������.
      Dec(i);
      end;

    x1 := getPoint_Xi(i);
    x2 := getPoint_Xi(i+1);

    getPoint_Fi(i, PDouble(Fval3));
    getPoint_Fi(i+1, PDouble(Fval4));

    for k:=0 to Fdim-1 do begin
      y1 := Fval3[k];
      y2 := Fval4[k];
      y := y1+(x-x1)*(y2-y1)/(x2-x1);
      Fresult[k] :=y;
      end;

    exit;
    end;

  if outOfXflag then begin
    case ExtrapolationType of
      0:  // ��������� ��� ���������
        begin
        getPoint_Fi(i, Fresult);
        exit;
        end;

      1: // ���� ��� ���������
        begin
          for j:=0 to Fdim-1 do begin
            Fresult[j] := 0;
            end;
        end;
      else
        Assert(False,'����� ������������� '+IntToStr(ExtrapolationType)+' �� ����������');
      end;
    end;
end;


//===========================================================================
// ����� �������� ������� �� ������������ ����������� ���������
procedure TFndimFunctionByPoints1d.SplineInterpolation(x: Double; Fresult: PDouble);
var
  i,j: NativeInt;
  outOfXflag: Boolean;
begin
  i := FindIntervalIndex_ofX(x, outOfXflag);

  if (not outOfXflag)or(ExtrapolationType=2) then begin // ������������� �� ���������
    getPoint_Fi(i, Fresult);
    exit;
    end;

  if outOfXflag then begin
    case ExtrapolationType of
      0,2:  // ��������� ��� ���������, ���� ���������������� �������
        begin
        getPoint_Fi(i, Fresult);
        exit;
        end;

      1: // ���� ��� ���������
        begin
          for j:=0 to Fdim-1 do begin
            Fresult[j] := 0;
            end;
        end;
      else
        Assert(False,'����� ������������� '+IntToStr(ExtrapolationType)+' �� ����������');
      end;
    end;
end;

//===========================================================================
//===========================================================================
//===========================================================================

{$POINTERMATH OFF}
{$ASSERTIONS OFF}
end.
