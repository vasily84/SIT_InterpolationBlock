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
  public
    Ylength: NativeInt; // размер выходного вектора функции,
    pointsCount: NativeInt; // число заданных точек функции
    isBeginPointsEnter: Boolean; // состояние внутри вызовов beginPoints() и endPoints();
    msYvalues,msXvalues :TMemoryStream;

    constructor Create();
    destructor Destroy;override;
    // тестируй меня полностью
    function TestMeAll():Boolean;

    // переустановить размерность выходного вектора
    procedure resetYlength(AYlength: NativeInt);

    // загрузка функции по точкам из файла на диске
    function LoadFromTlb(fileName: string):Boolean;
    function LoadFromCsv(fileName: string):Boolean;
    function LoadFromJson(fileName: string):Boolean;
    function LoadFromFile(fileName: string):Boolean;

    // запись в файл
    function SaveToCsv(fileName: string):Boolean;

    // создать функцию - наборы точек и прочее пользовательской процедурой -
    // для отладки и тестирования.
    function CreateFunction_ByUser(kind:NativeInt):Boolean;

    // конструирование функции добавлением точек врукопашную
    function beginPoints():Boolean; // вызвать перед началом работы
    procedure endPoints();
    // добавить точку в набор точек функции
    function addPoint(x: Double; y: DoubleArray):Boolean;
    function getPoint_Xvalue(Pindex: NativeInt): Double;
    function getPoint_Yvalue(Pindex: NativeInt): PDouble;

  end;

function TFndimFunctionByPoints1d_testAll():Boolean;

implementation

constructor TFndimFunctionByPoints1d.Create();
begin
  msYvalues := TMemoryStream.Create;
  msXvalues := TMemoryStream.Create;

  Ylength := 1; // размер выходного вектора функции - по умолчанию 1
  pointsCount := 0; // точек пока нет
  isBeginPointsEnter := False;

end;

destructor TFndimFunctionByPoints1d.Destroy;
begin
  inherited;
  FreeAndNil(msYvalues);
  FreeAndNil(msXvalues);

end;

procedure TFndimFunctionByPoints1d.resetYlength(AYlength: NativeInt);
begin
  Ylength := AYlength;
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
function TFndimFunctionByPoints1d.addPoint(x: Double; y: DoubleArray):Boolean;
begin
  Assert(isBeginPointsEnter, 'добавление точек в функцию за пределами beginPoints() endPoints()');

  msXvalues.Write(x,sizeof(Double)); // добавляем аргумент
  msYvalues.Write(y[0],sizeof(Double)*Ylength); // добавляем вектор-значение
  Inc(pointsCount);
  Result := True;
end;

function TFndimFunctionByPoints1d.getPoint_Xvalue(Pindex: NativeInt): Double;
// вернуть аргумент X по индексу Pindex, т.е. аргумент функции в точке
var
  Xptr: PDouble;
begin
  Xptr := msXvalues.Memory;
  Result := Xptr[Pindex];
end;

function TFndimFunctionByPoints1d.getPoint_Yvalue(Pindex: NativeInt): PDouble;
// вернуть указатель на массив значений Y по индексу Pindex, т.е. векторное значение функции в точке
var
  Yptr: PDouble;
begin
  Yptr := msYvalues.Memory;
  Result := @Yptr[Pindex*Ylength];
end;

//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
//===========================================================================
// тестируй меня полностью
function TFndimFunctionByPoints1d.TestMeAll():Boolean;
begin
  Result := False;
end;

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
  funcA.resetYlength(Ylength);
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


  x := funcA.getPoint_Xvalue(3); // контроль корректности записи-чтения
  y := funcA.getPoint_Yvalue(3)[0];

  Assert((x=3)and(y=3));
  if not((x=3)and(y=3)) then Result:=False;

  SetLength(Yarray, 0 );
  FreeAndNil(funcA);
  end;

function test_2():Boolean;
  // cоздание объекта-функции с векторным выходом,
  // добавление точек вручную,
  // корректность записи и чтения,
  // подсчет количества точек
  var
    i,Ylength: Integer;
    x,y: Double;
    Yarray,Y2array: DoubleArray;
  begin
  Result := True;
  funcA := TFndimFunctionByPoints1d.Create;
  Ylength := 3; // векторная функция, размерность 3
  funcA.resetYlength(Ylength);
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

  {
  x := funcA.getPoint_Xvalue(3); // контроль корректности записи-чтения
  y := funcA.getPoint_Yvalue(3)[0];

  Assert((x=3)and(y=3));
  if not((x=3)and(y=3)) then Result:=False;
  }

  SetLength(Yarray, 0 );
  FreeAndNil(funcA);
  end;

procedure test_3();
  begin

  end;

procedure test_4();
  begin

  end;

procedure test_5();
  begin

  end;

begin
  //Assert(False, 'если вы видите это сообщение, Asserts подключены и работают' );

  AssignFile(testLog, autoTest_FileName);
  Rewrite(testLog);
  writeln(testLog, 'autotest report by InterpolationBlocks_unit.pas');
  DateTimeToString(strTime, 'dd/mm/yy hh:mm:ss', Now());
  writeln(testLog, strTime);
  writeln(testLog, 'BEGIN');

  if test_1() then writeln(testLog,'test1     Ok') else writeln(testLog,'!! test1  FAILED!!');
  if test_2() then writeln(testLog,'test2     Ok') else writeln(testLog,'!! test2  FAILED!!');

    test_2();
    test_3();
    test_4();
    test_5();
  write(testLog, 'END of autotest routine log file');
  CloseFile(testLog);
end;

{$POINTERMATH OFF}
{$ASSERTIONS ON}
end.
