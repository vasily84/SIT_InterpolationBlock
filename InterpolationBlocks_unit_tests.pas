//**************************************************************************//
 // Данный исходный код является составной частью системы МВТУ-4             //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit InterpolationBlocks_unit_tests;

 //***************************************************************************//
 //                Блоки N-мерной функции от 1 аргумента, заданная точками
 //***************************************************************************//

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath, InterpolationBlocks_unit;

{$POINTERMATH ON}  // адресная арифметика в стиле Си -> массив равнозначен адресу его первой переменной и наоборот
{$ASSERTIONS ON}


procedure TFndimFunctionByPoints1d_testAll(FileName: string);

implementation

//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
// тестируй меня полностью
procedure TFndimFunctionByPoints1d_testAll(FileName: string);
var
  testLog: TextFile;
  strTime: string;
  funcA, funcB, funcC: TFndimFunctionByPoints1d;
  a_true,b_true,c_true,d_true,e_true,f_true,g_true,
      a_false,b_false,c_false,d_false,e_false,f_false,g_false: Boolean;
  a_real,b_real,c_real,d_real,e_real,f_real,g_real: Double;
  //-----------------------------------------------------------------------
function test_1():Boolean;
  // cоздание объекта-функции,
  // добавление точек вручную,
  // корректность записи и чтения,
  // подсчет количества точек
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray,Farray: array of Double;
    Yptr,Fptr: PDouble;
  begin
  Result := True;
  Ylength := 1; // пока одномерная функция
  funcA.ClearPoints;
  funcA.setFdim(Ylength);
  SetLength(Yarray, Ylength);
  SetLength(Farray, Ylength);

  funcA.beginPoints();
  for i:=0 to 9 do begin // добавляем врукопашную 10 точек
    x := i;
    y := i;
    Yarray[0]:=y;
    funcA.addPoint(x,PDouble(@Yarray[0]));
    end;
  funcA.endPoints();

  Assert(funcA.pointsCount = 10); // контроль количества точек
  if not (funcA.pointsCount = 10) then Result:=False;

  x := funcA.getPoint_Xi(3); // контроль корректности записи-чтения

  funcA.getPoint_Fi(3, PDouble(funcA.Fval1));

  Assert((x=3)and(funcA.Fval1[0]=3));
  if not((x=3)and(funcA.Fval1[0]=3)) then Result:=False;

  SetLength(Yarray, 0);
  SetLength(Farray, 0);
  end;
  //--------------------------------------------------------------------------
function test_2():Boolean;
  // cоздание объекта-функции с векторным выходом,
  // добавление точек вручную,
  // корректность записи и чтения,
  // подсчет количества точек
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray, Farray, Y2array: array of Double;
    cond1: Boolean;

  begin
  Result := True;
  Ylength := 3; // векторная функция, размерность 3
  funcA.ClearPoints;
  funcA.setFdim(Ylength);
  SetLength(Yarray,Ylength);
  SetLength(Y2array,Ylength);
  SetLength(Farray,Ylength);

  funcA.beginPoints();
  for i:=0 to 19 do begin // добавляем врукопашную 20 точек
    x := i;
    y := i;
    Yarray[0] := y;
    Yarray[1] := y*y;
    Yarray[2] := y*y+5;
    funcA.addPoint(x, PDouble(Yarray));
    end;
  funcA.endPoints();

  Assert(funcA.pointsCount = 20); // контроль количества точек
  if not (funcA.pointsCount = 20) then Result:=False;

  x := funcA.getPoint_Xi(0); // контроль корректности записи-чтения
  funcA.getPoint_Fi(0, PDouble(Y2array));
  cond1 := (x=0)and(Y2array[0]=0)and(Y2array[1]=0)and(Y2array[2]=5);
  Assert(cond1);
  if not(cond1) then Result:=False;

  x := funcA.getPoint_Xi(3); // контроль корректности записи-чтения
  funcA.getPoint_Fi(3, PDouble(Y2array));
  cond1 := (x=3)and(Y2array[0]=3)and(Y2array[1]=9)and(Y2array[2]=14);
  Assert(cond1);
  if not(cond1) then Result:=False;

  x := funcA.getPoint_Xi(10); // контроль корректности записи-чтения
  funcA.getPoint_Fi(10, PDouble(Y2array));
  cond1 := (x=10)and(Y2array[0]=10)and(Y2array[1]=100)and(Y2array[2]=105);
  Assert(cond1);
  if not(cond1) then Result:=False;

  SetLength(Yarray, 0);
  SetLength(Y2array, 0);
  SetLength(Farray, 0);
  end;
  //-------------------------------------------------------------------------
function test_3(): Boolean;
  // тестирование функции swap
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray,Y2array: array of Double;

    a_true: Boolean;
  begin
  Result := True;
  Ylength := 3; // векторная функция, размерность 3
  funcA.ClearPoints;
  funcA.setFdim(Ylength);
  SetLength(Yarray,Ylength);
  SetLength(Y2array,Ylength);

  funcA.beginPoints();
  for i:=0 to 19 do begin // добавляем врукопашную 20 точек
    x := i;
    y := i;
    Yarray[0] := y;
    Yarray[1] := y*y;
    Yarray[2] := y*y+5;
    funcA.addPoint(x,PDouble(Yarray));
    end;
  funcA.endPoints();

  // меняем местами точки 5 и 10
  funcA.swapPoints(5,10);

  // на месте точки 5 должны быть значения точки 10
  x := funcA.getPoint_Xi(5);
  funcA.getPoint_Fi(5, PDouble(Y2array));
  a_true := (x=10)and(Y2array[0]=10)and(Y2array[1]=100)and(Y2array[2]=105);
  Assert(a_true);
  if not(a_true) then Result:=False;

  // на месте точки 10 должны быть значения точки 5
  x := funcA.getPoint_Xi(10);
  funcA.getPoint_Fi(10, PDouble(Y2array));
  a_true := (x=5)and(Y2array[0]=5)and(Y2array[1]=25)and(Y2array[2]=30);
  Assert(a_true);
  if not(a_true) then Result:=False;

  // проверяем, что не затерли значения точки 6
  x := funcA.getPoint_Xi(6);
  funcA.getPoint_Fi(6, PDouble(Y2array));
  a_true := (x=6)and(Y2array[0]=6)and(Y2array[1]=36)and(Y2array[2]=41);
  Assert(a_true);
  if not(a_true) then Result:=False;

  SetLength(Yarray, 0 );
  SetLength(Y2array, 0 );

  end;

function test_4(): Boolean;
  // тестирование вспомогательных функции сортировки и прочего
  var
    Func_zero,Func_ones,Func_i,Func_downcount: TFndimFunctionByPoints1d;
    i: Integer;
    x: Double;
    F: array of Double;
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
      Func_zero.addPoint(x,PDouble(F));
      F[0] := 1;
      Func_ones.addPoint(x,PDouble(F));
      F[0] := i;
      Func_i.addPoint(x,PDouble(F));
      F[0] := 9-i;
      Func_downcount.addPoint(x,PDouble(F));
    end;

    Func_zero.endPoints();
    Func_ones.endPoints();
    Func_i.endPoints();
    Func_downcount.endPoints();

  // тесты проверки упорядочения
   a_true := Func_zero.IsXsorted();
   b_true := Func_i.IsXsorted();
   c_true := Func_downcount.IsXsorted();

   Func_i.swapPoints(3,7);  // переставляем точки местами, теперь они неупорядочены
   a_false := Func_i.IsXsorted();
   Func_downcount.swapPoints(0,1);  // переставляем точки местами, теперь они неупорядочены
   b_false := Func_downcount.IsXsorted();

   Assert(a_true and b_true);
   Assert((not a_false)and(not b_false));
   if not (a_true and b_true and c_true) then Result:=False;
   if not ((not a_false)and(not b_false)) then Result:=False;

   // тесты проверки сортировки
   Func_i.swapPoints(7,0);
   Func_i.sortPoints();
   a_true := Func_i.IsXsorted();
   Func_downcount.sortPoints();
   b_true := Func_downcount.IsXsorted();
   Assert(a_true and b_true);
   if not (a_true and b_true and c_true) then Result:=False;

   // тесты сравнения функций
   a_real := Func_zero.CmpWithFunction(Func_zero); //
   b_real := Func_zero.CmpWithFunction(Func_ones);
   a_true := abs(a_real) < REALZERO;
   b_true := abs(b_real-10) < REALZERO;

   Assert(a_true and b_true);
   if not (a_true and b_true) then Result:=False;

   // тесты поиска дубликатов в координатах
   a_false := Func_i.IsXduplicated();
   b_false := Func_ones.IsXduplicated();
   Func_i.beginPoints();
   Func_ones.beginPoints();
   F[0]:=1;
   x:=9;
   Func_i.addPoint(x, PDouble(F));
   Func_ones.addPoint(x, PDouble(F));
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
  // тестирование вспомогательных функции сортировки и прочего - векторный выход размерность 3
  var
    Func_zero,Func_ones,Func_i,Func_downcount: TFndimFunctionByPoints1d;
    i: Integer;
    x: Double;
    F: array of Double;
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
      Func_zero.addPoint(x,PDouble(F));

      F[0] := 1;
      F[1] := 1;
      F[2] := 1;
      Func_ones.addPoint(x,PDouble(F));

      F[0] := i;
      F[1] := i;
      F[2] := i;
      Func_i.addPoint(x,PDouble(F));

      F[0] := 9-i;
      F[1] := 9-i;
      F[2] := 9-i;
      Func_downcount.addPoint(x,PDouble(F));

    end;

    Func_zero.endPoints();
    Func_ones.endPoints();
    Func_i.endPoints();
    Func_downcount.endPoints();

  // тесты проверки упорядочения
   a_true := Func_zero.IsXsorted();
   b_true := Func_i.IsXsorted();
   c_true := Func_downcount.IsXsorted();

   Func_i.swapPoints(3,7);  // переставляем точки местами, теперь они неупорядочены
   a_false := Func_i.IsXsorted();
   Func_downcount.swapPoints(0,1);  // переставляем точки местами, теперь они неупорядочены
   b_false := Func_downcount.IsXsorted();

   Assert(a_true and b_true);
   Assert((not a_false)and(not b_false));
   if not (a_true and b_true and c_true) then Result:=False;
   if not ((not a_false)and(not b_false)) then Result:=False;

   // тесты проверки сортировки
   Func_i.swapPoints(7,0);
   Func_i.sortPoints();
   a_true := Func_i.IsXsorted();
   Func_downcount.sortPoints();
   b_true := Func_downcount.IsXsorted();
   Assert(a_true and b_true);
   if not (a_true and b_true and c_true) then Result:=False;

   // тесты сравнения функций
   a_real := Func_zero.CmpWithFunction(Func_zero); //
   b_real := Func_zero.CmpWithFunction(Func_ones);
   a_true := abs(a_real) < REALZERO;
   b_true := abs(b_real-30) < REALZERO;

   Assert(a_true and b_true);
   if not (a_true and b_true) then Result:=False;

   // тесты поиска дубликатов в координатах
   a_false := Func_i.IsXduplicated();
   b_false := Func_ones.IsXduplicated();
   Func_i.beginPoints();
   Func_ones.beginPoints();
   F[0]:=1;
   x:=9;
   Func_i.addPoint(x, PDouble(F));
   Func_ones.addPoint(x, PDouble(F));
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
  // тестирование тестирование функции интерполяции, кусочно-постоянной и линейной
  var
    i: NativeInt;
    x: Double;
    F: array of Double;
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
    F[0] := x;            // линейная
    funcA.addPoint(x, PDouble(F));

    F[0] := x*x+x;
    funcB.addPoint(x, PDouble(F));

    F[0] := sin(PI*x/20); // синус
    funcC.addPoint(x, PDouble(F));
    end;

  funcA.endPoints;
  funcB.endPoints;
  funcC.endPoints;

  // кусочно-постоянная
  x := 0.1;
  funcA.IntervalInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];

  funcB.IntervalInterpolation(x,PDouble(funcB.Fval1));
  b_real := funcB.Fval1[0];

  funcC.IntervalInterpolation(x,PDouble(funcC.Fval1));
  c_real := funcC.Fval1[0];

  a_true := abs(a_real-0)<REALZERO;
  b_true := abs(b_real-0)<REALZERO;
  c_true := abs(c_real-0)<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  x := 10;

  funcA.IntervalInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];

  funcB.IntervalInterpolation(x,PDouble(funcB.Fval1));
  b_real := funcB.Fval1[0];

  funcC.IntervalInterpolation(x,PDouble(funcC.Fval1));
  c_real := funcC.Fval1[0];

  a_true := abs(a_real-10)<REALZERO;
  b_true := abs(b_real-110)<REALZERO;
  c_true := abs(c_real-sin(PI*10/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // кусочно-постоянная за пределами интервала аргументов - экстраполяция
  x := 110;

  funcA.IntervalInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];

  funcB.IntervalInterpolation(x,PDouble(funcB.Fval1));
  b_real := funcB.Fval1[0];

  funcC.IntervalInterpolation(x,PDouble(funcC.Fval1));
  c_real := funcC.Fval1[0];

  a_true := abs(a_real-100)<REALZERO;
  b_true := abs(100*100+100-b_real)<REALZERO;
  c_true := abs(c_real-sin(PI*100/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // кусочно-постоянная за пределами интервала аргументов - экстраполяция
  x := -110;

  funcA.IntervalInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];

  funcB.IntervalInterpolation(x,PDouble(funcB.Fval1));
  b_real := funcB.Fval1[0];

  funcC.IntervalInterpolation(x,PDouble(funcC.Fval1));
  c_real := funcC.Fval1[0];

  a_true := abs(a_real+100)<REALZERO;
  b_true := abs(100*100-100-b_real)<REALZERO;
  c_true := abs(c_real-sin(PI*-100/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // линейная
  x := 0.1;

  funcA.LinearInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];

  funcB.LinearInterpolation(x,PDouble(funcB.Fval1));
  b_real := funcB.Fval1[0];

  funcC.LinearInterpolation(x,PDouble(funcC.Fval1));
  c_real := funcC.Fval1[0];

  a_true := abs(a_real-0.1)<REALZERO;
  b_true := abs(b_real-0.2)<REALZERO;
  c_true := abs(c_real-0.0156434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  x := 10;

  funcA.LinearInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];

  funcB.LinearInterpolation(x,PDouble(funcB.Fval1));
  b_real := funcB.Fval1[0];

  funcC.LinearInterpolation(x,PDouble(funcC.Fval1));
  c_real := funcC.Fval1[0];

  a_true := abs(a_real-10)<REALZERO;
  b_true := abs(b_real-110)<REALZERO;
  c_true := abs(c_real-1)<1e-4;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // линейная за пределами интервала аргументов - экстраполяция
  x := 110;

  funcA.LinearInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];

  funcB.LinearInterpolation(x,PDouble(funcB.Fval1));
  b_real := funcB.Fval1[0];

  funcC.LinearInterpolation(x,PDouble(funcC.Fval1));
  c_real := funcC.Fval1[0];

  a_true := abs(a_real-110)<REALZERO;
  b_true := abs(12100-b_real)<REALZERO;
  c_true := abs(c_real+1.56434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // линейная за пределами интервала аргументов - экстраполяция
  x := -110;

  funcA.LinearInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];

  funcB.LinearInterpolation(x,PDouble(funcB.Fval1));
  b_real := funcB.Fval1[0];

  funcC.LinearInterpolation(x,PDouble(funcC.Fval1));
  c_real := funcC.Fval1[0];

  a_true := abs(a_real+110)<REALZERO;
  b_true := abs(11880-b_real)<REALZERO;
  c_true := abs(c_real-1.56434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;


  SetLength(F, 0);
  end;

//---------------------------------------------------------------------------
function test_7(): Boolean;
  // тестирование тестирование функции интерполяции, кусочно-постоянной и линейной
  var
    i: NativeInt;
    x: Double;
    F: array of Double;
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
    F[0] := x;            // линейная
    F[1] := x*x+x;
    F[2] := sin(PI*x/20); // синус
    funcA.addPoint(x, PDouble(F));
    end;
  funcA.endPoints;

  // кусочно-постоянная
  x := 0.1;

  //a_real := funcA.IntervalInterpolation(x)[0];
  //b_real := funcA.IntervalInterpolation(x)[1];
  //c_real := funcA.IntervalInterpolation(x)[2];

  funcA.IntervalInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];
  b_real := funcA.Fval1[1];
  c_real := funcA.Fval1[2];

  funcB.IntervalInterpolation(x,PDouble(funcB.Fval1));
  b_real := funcB.Fval1[0];

  funcC.IntervalInterpolation(x,PDouble(funcC.Fval1));
  c_real := funcC.Fval1[0];

  a_true := abs(a_real-0)<REALZERO;
  b_true := abs(b_real-0)<REALZERO;
  c_true := abs(c_real-0)<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  x := 10;

  funcA.IntervalInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];
  b_real := funcA.Fval1[1];
  c_real := funcA.Fval1[2];

  a_true := abs(a_real-10)<REALZERO;
  b_true := abs(b_real-110)<REALZERO;
  c_true := abs(c_real-sin(PI*10/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // кусочно-постоянная за пределами интервала аргументов - экстраполяция
  x := 110;
  funcA.IntervalInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];
  b_real := funcA.Fval1[1];
  c_real := funcA.Fval1[2];

  a_true := abs(a_real-100)<REALZERO;
  b_true := abs(100*100+100-b_real)<REALZERO;
  c_true := abs(c_real-sin(PI*100/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // кусочно-постоянная за пределами интервала аргументов - экстраполяция
  x := -110;
  funcA.IntervalInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];
  b_real := funcA.Fval1[1];
  c_real := funcA.Fval1[2];

  a_true := abs(a_real+100)<REALZERO;
  b_true := abs(100*100-100-b_real)<REALZERO;
  c_true := abs(c_real-sin(PI*-100/20))<REALZERO;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // линейная
  x := 0.1;
  funcA.LinearInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];
  b_real := funcA.Fval1[1];
  c_real := funcA.Fval1[2];

  a_true := abs(a_real-0.1)<REALZERO;
  b_true := abs(b_real-0.2)<REALZERO;
  c_true := abs(c_real-0.0156434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  x := 10;
  funcA.LinearInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];
  b_real := funcA.Fval1[1];
  c_real := funcA.Fval1[2];

  a_true := abs(a_real-10)<REALZERO;
  b_true := abs(b_real-110)<REALZERO;
  c_true := abs(c_real-1)<1e-4;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // линейная за пределами интервала аргументов - экстраполяция
  x := 110;
  funcA.LinearInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];
  b_real := funcA.Fval1[1];
  c_real := funcA.Fval1[2];

  a_true := abs(a_real-110)<REALZERO;
  b_true := abs(12100-b_real)<REALZERO;
  c_true := abs(c_real+1.56434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;

  // линейная за пределами интервала аргументов - экстраполяция
  x := -110;
  funcA.LinearInterpolation(x, PDouble(funcA.Fval1));
  a_real := funcA.Fval1[0];
  b_real := funcA.Fval1[1];
  c_real := funcA.Fval1[2];

  a_true := abs(a_real+110)<REALZERO;
  b_true := abs(11880-b_real)<REALZERO;
  c_true := abs(c_real-1.56434465)<1e-6;

  Assert(a_true and b_true and c_true);
  if not (a_true and b_true and c_true) then Result:=False;


  SetLength(F, 0);
  end;

//----------------------------------------------------------------------------

begin
  //Assert(False, 'если вы видите это сообщение, Asserts подключены и работают' );
  funcA := TFndimFunctionByPoints1d.Create;
  funcB := TFndimFunctionByPoints1d.Create;
  funcC := TFndimFunctionByPoints1d.Create;

  funcA.ExtrapolationType := 2;
  funcB.ExtrapolationType := 2;
  funcC.ExtrapolationType := 2;

  try
    AssignFile(testLog, FileName);
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
