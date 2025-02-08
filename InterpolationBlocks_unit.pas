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

    // создать функцию - наборы точек и прочее пользовательской процедурой -
    // для отладки и тестирования.
    function CreateFunction_ByUser(kind: NativeInt):Boolean;

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
  end;

function TFndimFunctionByPoints1d_testAll():Boolean;

implementation

function DoubleArray_AB_Cmp(a,b: DoubleArray; ALength: NativeInt): Double;
// сравнить два массива типа Double и длиной ALength элементов.
// возвращает сумму модулей разности элементов
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
// возвращает True если массив упорядочен по возрастанию. Иначе - False
var
  i: NativeInt;
begin
  Result := True;

  for i:=0 to ALength-2 do begin
    // следующий элемент в массиве меньше предыдущего - массив неупорядочен
    if(a[i+1]<a[i]) then Result := False; exit;
  end;

end;

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
function TFndimFunctionByPoints1d.CreateFunction_ByUser(kind:NativeInt):Boolean;
begin
  Result := False;
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
// тестируй меня полностью
function TFndimFunctionByPoints1d_testAll():Boolean;
var
  testLog: TextFile;
  strTime: string;
  funcA, funcB, funcC: TFndimFunctionByPoints1d;
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
  funcA := TFndimFunctionByPoints1d.Create;
  Ylength := 1; // пока одномерная функция
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
  FreeAndNil(funcA);
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
  funcA := TFndimFunctionByPoints1d.Create;
  Ylength := 3; // векторная функция, размерность 3
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
  FreeAndNil(funcA);
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
  funcA := TFndimFunctionByPoints1d.Create;
  Ylength := 3; // векторная функция, размерность 3
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
  FreeAndNil(funcA);
  end;

function test_4(): Boolean;
  // тестирование вспомогательных функции сортировки и прочего
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

  // тесты проверки упорядочения
   a_true := DoubleArray_isOrdered(arr_zero, 10);
   b_true := DoubleArray_isOrdered(arr_i, 10);
   c_true := DoubleArray_isOrdered(arr_i, 10);

   a_false := DoubleArray_isOrdered(arr_downcount, 10);

   Assert(a_true and b_true and c_true);
   Assert(not a_false);
   if not (a_true and b_true and c_true) then Result:=False; exit;
   if (a_false) then Result:=False; exit;

   // тесты сравнения

   // тесты сортировки

   SetLength(arr_zero, 0);
   SetLength(arr_ones, 0);
   SetLength(arr_i2, 0);
   SetLength(arr2, 0);
   SetLength(arr3, 0);
   SetLength(arr4, 0);
  end;

procedure test_5();
  // тестирование линейной интерполяции
  begin

  end;

begin
  //Assert(False, 'если вы видите это сообщение, Asserts подключены и работают' );
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
