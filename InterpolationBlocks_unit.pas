//**************************************************************************//
 // Данный исходный код является составной частью системы МВТУ-4             //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit InterpolationBlocks_unit;

 //***************************************************************************//
 //                Блоки N-мерной функции от 1 аргумента, заданная точками
 //***************************************************************************//

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath;

{$POINTERMATH ON}  // адресная арифметика в стиле Си -> массив равнозначен адресу его первой переменной и наоборот
{$ASSERTIONS ON}

// путь к отчету по автотесту. Папки должны существовать
const autoTest_FileName = 'e:\USERDISK\SIM_WORK\БЛОКИ_ИНТЕРПОЛЯЦИИ\InterpolationBlocks_autoTestLog.txt';


type
 DoubleArray = Array of Double;

type
  TFndimFunctionByPoints1d = class(TObject)
  // N-мерная функция от 1 аргумента, заданная точками
  protected
    ApointsCount: NativeInt; // число заданных точек функции
    AFdim: NativeInt; // размер выходного вектора функции
    isBeginPointsEnter: Boolean; // состояние внутри вызовов beginPoints() и endPoints();
    msFvalues, msXvalues :TMemoryStream;
  public

    constructor Create();
    destructor Destroy;override;

    // переустановить размерность выходного вектора
    procedure setFdim(NewDim: NativeInt);

    // новая функция - удалить все старые точки точки
    procedure ClearFunction;

    // обертки для чтения свойств
    function pointsCount: NativeInt;inline;
    function Fdim: NativeInt;inline; // размер выходного вектора функции,

    // загрузка функции по точкам из файла на диске
    function LoadFromTlb(fileName: string):Boolean;
    function LoadFromCsv(fileName: string):Boolean;
    function LoadFromJson(fileName: string):Boolean;
    function LoadFromFile(fileName: string):Boolean;

    // запись в файл
    function SaveToCsv(fileName: string):Boolean;

    procedure addUserFunction(Xbegin,Xend: Double; NPoints:NativeInt; kind: string;
      noise,param1,param2: Double);

    // конструирование функции добавлением точек врукопашную
    function beginPoints():Boolean; // вызвать перед началом работы
    procedure endPoints();
    // добавить точку в набор точек функции
    function addPoint(x: Double; F: DoubleArray):Boolean;
    function getPoint_Xi(Pindex: NativeInt): Double;
    function getPoint_Fi(Pindex: NativeInt): PDouble;

    // поменять точки местами
    procedure swapPoints(i,j :NativeInt);
    // отсортировать по возрастанию значений X
    procedure sortPoints();
    // определить, отсортированы ли точки функции по возрастанию аргумента X
    function IsXsorted(): Boolean;
    // определить, есть ли дубликаты значений Х в точках
    function IsXduplicated(): Boolean;
    // сравнить значения функций по точкам. Сравнивают только вектора-значения, аргументы игнорируются
    function CmpWithFunction(Func2: TFndimFunctionByPoints1d): Double;

    // найти индекс точки - начала интервала, внутри которого лежит аргумент x
    //function FindIntervalIndex_ofX(x: Double): NativeInt;
    // найти значение функции по кусочно-постоянной интерполяции
    //function IntervalInterpolation(x: Double): PDouble;
    // найти значение функции по линейной интерполяции
    //function LinearInterpolation(x: Double): PDouble;
  end;

procedure TFndimFunctionByPoints1d_testAll();

implementation

constructor TFndimFunctionByPoints1d.Create();
begin
  msFvalues := TMemoryStream.Create;
  msXvalues := TMemoryStream.Create;

  ApointsCount := 0; // точек пока нет
  setFdim(1); // размер выходного вектора функции - по умолчанию 1
  isBeginPointsEnter := False;

end;

destructor TFndimFunctionByPoints1d.Destroy;
begin
  inherited;
  FreeAndNil(msFvalues);
  FreeAndNil(msXvalues);

end;

// новая функция - удалить все старые точки точки
procedure TFndimFunctionByPoints1d.ClearFunction;
begin
  ApointsCount := 0;
  msFvalues.Clear;
  msXvalues.Clear;
end;

procedure TFndimFunctionByPoints1d.setFdim(NewDim: NativeInt);
begin
  Assert(not((pointsCount>0)and(NewDim<>Fdim)),'Изменение размерности уже заданной точками функции');
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

// запись в файл
function TFndimFunctionByPoints1d.SaveToCsv(fileName: string):Boolean;
begin
  Result := False;
end;

// создать функцию - наборы точек и прочее пользовательской процедурой -
// для отладки и тестирования.
procedure TFndimFunctionByPoints1d.addUserFunction(Xbegin,Xend: Double; NPoints:NativeInt;
  kind: string; noise,param1,param2: Double );
var
  i: NativeInt;
  x,dx: Double;
  F:DoubleArray;
begin
  SetLength(F, 1);

  if StrEqu(kind,'sine') then begin
    dx := (Xend-Xbegin)/NPoints;
    beginPoints();
    for i:=0 to NPoints-1 do begin
      x := Xbegin+i*dx;
      F[0] := sin(x)+(noise-0.5)*random();
      addPoint(x,F);
      end;
    endPoints();
  end;

  if StrEqu(kind,'line') then begin
    dx := (Xend-Xbegin)/NPoints;
    beginPoints();
    for i:=0 to NPoints-1 do begin
      x := Xbegin+i*dx;
      F[0] := param1*x+param2+(noise-0.5)*random();
      addPoint(x,F);
      end;
    endPoints();
  end;

  SetLength(F, 0);
end;

// конструирование функции добавлением точек врукопашную
function TFndimFunctionByPoints1d.beginPoints():Boolean;
// вызвать перед началом работы по добавлению точек
begin
  isBeginPointsEnter := True;
  Result := True;
end;

procedure TFndimFunctionByPoints1d.endPoints();
begin
  isBeginPointsEnter := False;
end;

// добавить точку в набор точек функции
function TFndimFunctionByPoints1d.addPoint(x: Double; F: DoubleArray):Boolean;
begin
  Assert(isBeginPointsEnter, 'добавление точек в функцию за пределами beginPoints() endPoints()');

  msXvalues.Write(x,sizeof(Double)); // добавляем аргумент
  msFvalues.Write(F[0],sizeof(Double)*Fdim); // добавляем вектор-значение
  Inc(ApointsCount);
  Result := True;
end;

function TFndimFunctionByPoints1d.getPoint_Xi(Pindex: NativeInt): Double;
// вернуть аргумент X по индексу Pindex, т.е. аргумент функции в точке
var
  Xptr: PDouble;
begin
  Xptr := msXvalues.Memory;
  Result := Xptr[Pindex];
end;

function TFndimFunctionByPoints1d.getPoint_Fi(Pindex: NativeInt): PDouble;
// вернуть указатель на массив значений Y по индексу Pindex, т.е. векторное значение функции в точке
var
  Fptr: PDouble;
begin
  Fptr := msFvalues.Memory;
  Result := @Fptr[Pindex*Fdim];
end;

// поменять i,j точки функции местами
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

  // y swap TODO - почему не работает?
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

// отсортировать по возрастанию значений X
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
    if(xj<minXvalue) then begin
      minXvalue:=xj; minXindex:=j;
      end;
    end;
  if(i<>minXindex) then swapPoints(i,minXindex);
  end;

end;

function TFndimFunctionByPoints1d.IsXsorted(): Boolean;
// возвращает True если массив упорядочен по возрастанию. Иначе - False
var
  i: NativeInt;
  Xptr: PDouble;
begin
  Result := True;
  Xptr := msXvalues.Memory;

  for i:=0 to pointsCount-2 do begin
    // следующий элемент в массиве меньше предыдущего - массив неупорядочен
    if(Xptr[i+1]<Xptr[i]) then begin
      Result := False;
      exit;
    end;
  end;

end;

// определить, есть ли дубликаты значений Х в точках
function TFndimFunctionByPoints1d.IsXduplicated(): Boolean;
var
  i,j: NativeInt;
  Xptr: PDouble;
begin
  Xptr := msXvalues.Memory;

  Result := False;
  if isXsorted() then begin
  // массив упорядочен, сравниваем соседние точки - сложность O(N) - хороший случай
    for i:=0 to pointsCount-2 do begin
      if(Xptr[i+1]=Xptr[i]) then begin // найден дубликат
        Result := True;
        exit;
        end;
    end;
  end
  else begin
  // массив неупорядочен, сравниваем всех со всеми - сложность O(N^2)
    for i:=0 to pointsCount-2 do begin
      for j:=i+1 to pointsCount-1 do begin
        if(Xptr[j]=Xptr[i]) then begin // найден дубликат
          Result := True;
          exit;
          end;
      end;
  end;
  end;

end;

function TFndimFunctionByPoints1d.CmpWithFunction(Func2: TFndimFunctionByPoints1d): Double;
// сравнить два массива типа Double и длиной ALength элементов.
// возвращает сумму модулей разности элементов
var
  i: NativeInt;
  ASumm,v1,v2: Double;
  X1ptr,X2ptr: PDouble;
begin
  ASumm := 0;
  X1ptr := msFvalues.Memory;
  X2ptr := Func2.msFvalues.Memory;

  Assert(pointsCount=Func2.pointsCount,'пробуем сравнить две функции с разным числом точек');

  for i:=0 to pointsCount-1 do begin
    v1 := X1ptr[i];
    v2 := X2ptr[i];
    ASumm := ASumm + abs(v1-v2);
    end;

  Result := ASumm;
end;

//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
// тестируй меня полностью
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
  // cоздание объекта-функции,
  // добавление точек вручную,
  // корректность записи и чтения,
  // подсчет количества точек
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray: DoubleArray;
  begin
  Result := True;
  Ylength := 1; // пока одномерная функция
  funcA.ClearFunction;
  funcA.setFdim(Ylength);
  SetLength(Yarray,Ylength);

  funcA.beginPoints();
  for i:=0 to 9 do begin // добавляем врукопашную 10 точек
    x := i;
    y := i;
    Yarray[0]:=y;
    funcA.addPoint(x,Yarray);
    end;
  funcA.endPoints();

  Assert(funcA.pointsCount = 10); // контроль количества точек
  if not (funcA.pointsCount = 10) then Result:=False;

  x := funcA.getPoint_Xi(3); // контроль корректности записи-чтения
  y := funcA.getPoint_Fi(3)[0];

  Assert((x=3)and(y=3));
  if not((x=3)and(y=3)) then Result:=False;

  SetLength(Yarray, 0 );
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
    Yarray: DoubleArray;
    Y2ptr: PDouble;
    cond1: Boolean;

  begin
  Result := True;
  Ylength := 3; // векторная функция, размерность 3
  funcA.ClearFunction;
  funcA.setFdim(Ylength);
  SetLength(Yarray,Ylength);

  funcA.beginPoints();
  for i:=0 to 19 do begin // добавляем врукопашную 20 точек
    x := i;
    y := i;
    Yarray[0] := y;
    Yarray[1] := y*y;
    Yarray[2] := y*y+5;
    funcA.addPoint(x,Yarray);
    end;
  funcA.endPoints();

  Assert(funcA.pointsCount = 20); // контроль количества точек
  if not (funcA.pointsCount = 20) then Result:=False;

  x := funcA.getPoint_Xi(0); // контроль корректности записи-чтения
  Y2ptr := funcA.getPoint_Fi(0);
  cond1 := (x=0)and(Y2ptr[0]=0)and(Y2ptr[1]=0)and(Y2ptr[2]=5);
  Assert(cond1);
  if not(cond1) then Result:=False;

  x := funcA.getPoint_Xi(3); // контроль корректности записи-чтения
  Y2ptr := funcA.getPoint_Fi(3);
  cond1 := (x=3)and(Y2ptr[0]=3)and(Y2ptr[1]=9)and(Y2ptr[2]=14);
  Assert(cond1);
  if not(cond1) then Result:=False;

  x := funcA.getPoint_Xi(10); // контроль корректности записи-чтения
  Y2ptr := funcA.getPoint_Fi(10);
  cond1 := (x=10)and(Y2ptr[0]=10)and(Y2ptr[1]=100)and(Y2ptr[2]=105);
  Assert(cond1);
  if not(cond1) then Result:=False;

  SetLength(Yarray, 0 );
  end;
  //-------------------------------------------------------------------------
function test_3(): Boolean;
  // тестирование функции swap
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray: DoubleArray;
    Y2ptr: PDouble;
    cond1: Boolean;
  begin
  Result := True;
  Ylength := 3; // векторная функция, размерность 3
  funcA.ClearFunction;
  funcA.setFdim(Ylength);
  SetLength(Yarray,Ylength);

  funcA.beginPoints();
  for i:=0 to 19 do begin // добавляем врукопашную 20 точек
    x := i;
    y := i;
    Yarray[0] := y;
    Yarray[1] := y*y;
    Yarray[2] := y*y+5;
    funcA.addPoint(x,Yarray);
    end;
  funcA.endPoints();

  // меняем местами точки 5 и 10
  funcA.swapPoints(5,10);

  // на месте точки 5 должны быть значения точки 10
  x := funcA.getPoint_Xi(5);
  Y2ptr := funcA.getPoint_Fi(5);
  cond1 := (x=10)and(Y2ptr[0]=10)and(Y2ptr[1]=100)and(Y2ptr[2]=105);
  Assert(cond1);
  if not(cond1) then Result:=False;

  // на месте точки 10 должны быть значения точки 5
  x := funcA.getPoint_Xi(10);
  Y2ptr := funcA.getPoint_Fi(10);
  cond1 := (x=5)and(Y2ptr[0]=5)and(Y2ptr[1]=25)and(Y2ptr[2]=30);
  Assert(cond1);
  if not(cond1) then Result:=False;

  // проверяем, что не затерли значения точки 6
  x := funcA.getPoint_Xi(6);
  Y2ptr := funcA.getPoint_Fi(6);
  cond1 := (x=6)and(Y2ptr[0]=6)and(Y2ptr[1]=36)and(Y2ptr[2]=41);
  Assert(cond1);
  if not(cond1) then Result:=False;

  SetLength(Yarray, 0 );
  end;

function test_4(): Boolean;
  // тестирование вспомогательных функции сортировки и прочего
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
  begin
  Result := False;
  funcA.ClearFunction;
  funcA.addUserFunction(0,10,1000,'sine',1,0,0);
  end;

begin
  //Assert(False, 'если вы видите это сообщение, Asserts подключены и работают' );
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
