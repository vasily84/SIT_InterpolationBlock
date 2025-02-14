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

type
  TFndimFunctionByPoints1d = class(TObject)
  // N-мерная функция от 1 аргумента, заданная точками
  protected
    ApointsCount: NativeInt; // число заданных точек функции
    AFdim: NativeInt; // размер выходного вектора функции
    isBeginPointsEnter: Boolean; // состояние внутри вызовов beginPoints() и endPoints();
    msFvalues, msXvalues: TMemoryStream;
    Fval3,Fval4: array of double;
  public
    // переменные размерности выходного вектора для локального использования
    Fval1,Fval2: array of double;
    ExtrapolationType: NativeInt; // тип экстраполяции - перечисление
    LagrangeOrder: NativeInt; // порядок интерполяции для метода Лагранжа

    constructor Create();
    destructor Destroy;override;

    // переустановить размерность выходного вектора
    procedure setFdim(NewDim: NativeInt);

    // обертки для чтения свойств
    function pointsCount: NativeInt;inline;
    function Fdim: NativeInt;inline; // размер выходного вектора функции,

    // конструирование функции добавлением точек врукопашную
    procedure beginPoints(); // вызвать перед началом работы
    procedure endPoints();
    // удалить все старые точки точки
    procedure ClearPoints;
    // добавить точку в набор точек функции
    function addPoint(x: Double; F: PDouble):Boolean;
    function getPoint_Xi(Pindex: NativeInt): Double;inline;
    //function getPoint_Fi(Pindex: NativeInt): PDouble;inline;
    procedure getPoint_Fi(Pindex: NativeInt; Fresult: PDouble);

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
    function FindIntervalIndex_ofX(x: Double; var outOfXflag:Boolean): NativeInt;

    // найти значение функции по кусочно-постоянной интерполяции
    procedure IntervalInterpolation(x: Double; Fresult: PDouble);
    // найти значение функции по линейной интерполяции
    procedure LinearInterpolation(x: Double; Fresult: PDouble);
    // найти значение функции по интерполяции методом Лагранжа
    procedure LagrangeInterpolation(x: Double; Fresult: PDouble);
    // найти значение функции интерполяцией кубическими сплайнами
    procedure SplineInterpolation(x: Double; Fresult: PDouble);

  end;

implementation

constructor TFndimFunctionByPoints1d.Create();
begin
  msFvalues := TMemoryStream.Create;
  msXvalues := TMemoryStream.Create;

  ApointsCount := 0; // точек пока нет
  setFdim(1); // размер выходного вектора функции - по умолчанию 1
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

// новая функция - удалить все старые точки точки
procedure TFndimFunctionByPoints1d.ClearPoints;
begin
  ApointsCount := 0;
  msFvalues.Clear;
  msXvalues.Clear;
end;

procedure TFndimFunctionByPoints1d.setFdim(NewDim: NativeInt);
begin
  Assert(not((pointsCount>0)and(NewDim<>Fdim)),'Изменение размерности уже заданной точками функции');
  AFdim := NewDim;
  // перераспределяем память локальных переменных.
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

// конструирование функции добавлением точек врукопашную
procedure TFndimFunctionByPoints1d.beginPoints();
// вызвать перед началом работы по добавлению точек
begin
  isBeginPointsEnter := True;
end;

procedure TFndimFunctionByPoints1d.endPoints();
begin
  isBeginPointsEnter := False;
end;

// добавить точку в набор точек функции
function TFndimFunctionByPoints1d.addPoint(x: Double; F: PDouble):Boolean;
var
  i: Integer;
  v: Double;
begin
  Assert(isBeginPointsEnter, 'добавление точек в функцию за пределами beginPoints() endPoints()');

  msXvalues.Write(x,sizeof(Double)); // добавляем аргумент
  //msFvalues.Write(F^,sizeof(Double)*Fdim); // добавляем вектор-значение
  for i:=0 to Fdim-1 do begin
    v:= F[i];
    msFvalues.Write(F[i],sizeof(Double));
    end;
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

procedure TFndimFunctionByPoints1d.getPoint_Fi(Pindex: NativeInt; Fresult: PDouble);
// вернуть указатель на массив значений Y по индексу Pindex, т.е. векторное значение функции в точке
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

  // y brute stupid swap
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
  maxXindex: NativeInt;
  maxXvalue,xj: Double;
  sortedFlag: Boolean;
begin
// сортируем массив с конца, ибо новые точки добавляются в конец. В цикле также проверяем
// упорядоченность рассматриваемой части массива, если все упорядочено - завершаем работу досрочно.

for i:=pointsCount-1 downto 1 do begin
  maxXvalue := getPoint_Xi(i);
  maxXindex := i;
  sortedFlag := True;
  for j:=i-1 downto 0 do begin
    xj := getPoint_Xi(j);
    if(xj>maxXvalue) then begin // найдено большее число
      maxXvalue := xj;
      maxXindex := j;
      sortedFlag := False;
      end;

    // есть неотсортированный точки, нужно сортировать еще
    if xj>getPoint_Xi(j+1) then sortedFlag := False;

    end;
  if(i<>maxXindex) then swapPoints(i, maxXindex);
  // остальная часть массива упорядочена, работа по сортировке выполнена
  if sortedFlag then exit;
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
// возвращает сумму модулей разности элементов
var
  i: NativeInt;
  ASumm,v1,v2: Double;
  F1ptr,F2ptr: PDouble;
begin
  ASumm := 0;
  F1ptr := msFvalues.Memory;
  F2ptr := Func2.msFvalues.Memory;

  Assert(pointsCount=Func2.pointsCount,'пробуем сравнить две функции с разным числом точек');

  for i:=0 to Fdim*pointsCount-1 do begin
    v1 := F1ptr[i];
    v2 := F2ptr[i];
    ASumm := ASumm + abs(v1-v2);
  end;

  Result := ASumm;
end;

// найти индекс точки - начала интервала, внутри которого лежит аргумент x
function TFndimFunctionByPoints1d.FindIntervalIndex_ofX(x: Double; var outOfXflag:Boolean): NativeInt;
var
  i: NativeInt;
  x0: Double;
begin
  Result := 0;
  outOfXflag := False;

  // сперва ищем внутри интервала аргументов
  for i:=0 to pointsCount-2 do begin
    if((x>=getPoint_Xi(i))and(x<getPoint_Xi(i+1))) then begin
      Result := i;
      exit;
      end;
    end;

  Result := 0;
  outOfXflag := True;

  // случай аргумент за пределами
  if x< getPoint_Xi(0) then begin
    Result := 0;
    exit;
    end;

  if x>=getPoint_Xi(pointsCount-1) then begin
    Result := pointsCount-1;
    exit;
    end;

end;

// найти значение функции по кусочно-постоянной интерполяции
procedure TFndimFunctionByPoints1d.IntervalInterpolation(x: Double; Fresult: PDouble);
var
  i,j: NativeInt;
  outOfXflag: Boolean;
begin
  i := FindIntervalIndex_ofX(x, outOfXflag);

  if (not outOfXflag)or(ExtrapolationType=2) then begin // экстраполяция не требуется
    getPoint_Fi(i, Fresult);
    exit;
    end;

  if outOfXflag then begin
    case ExtrapolationType of
      0,2:  // константа вне диапазона, либо экстраполировать границы
        begin
        getPoint_Fi(i, Fresult);
        exit;
        end;

      1: // ноль вне диапазона
        begin
          for j:=0 to Fdim-1 do begin
            Fresult[j] := 0;
            end;
        end;
      else
        Assert(False,'метод экстраполяции '+IntToStr(ExtrapolationType)+' не реализован');
      end;
    end;
end;

// найти значение функции по интерполяции Лагранжем
procedure TFndimFunctionByPoints1d.LagrangeInterpolation(x: Double;Fresult: PDouble);
var
  i,j,k: NativeInt;
  y,dy,dx,x0, RR: Double;
  X1, Y1: PDouble;
  M: NativeInt; // M-сдвиг начала построения полинома интерполяции - индекс массива, от которого строим полином
  P1,P2 : Double;
  outOfXflag: Boolean;
begin
  i := FindIntervalIndex_ofX(x, outOfXflag);

  X1 := msXvalues.Memory;
  Y1 := msFvalues.Memory;

  if (not outOfXflag)or(ExtrapolationType=2) then begin
      // делаем интерполяцию по Лагранжу
      // TODO уточнить, как выбирать M - ВАЖНО !!!
      //M:= i - (LagrangeOrder div 2); // выбираем M сдвиг
      M := i;

      if ((M+LagrangeOrder) > (pointsCount-1)) then begin
        M:= pointsCount-LagrangeOrder-1;
        end;

      if M<0 then begin
        M:=0;
        end;

      // работа интерполяции, код портирован из InterpolFunc.pas
      // TODO - проверить, похоже он для регулярной сетки !!!
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

      EXIT;  // работа по интерполяции выполнена
    end;

  if outOfXflag then begin
    case ExtrapolationType of
      0:  // константа вне диапазона
        begin
        getPoint_Fi(i, Fresult);
        exit;
        end;

      1: // ноль вне диапазона
        begin
          for j:=0 to Fdim-1 do begin
            Fresult[j] := 0;
            end;
        end;
      else
        Assert(False,'метод экстраполяции '+IntToStr(ExtrapolationType)+' не реализован');
      end;
    end;
end;

//===========================================================================
// найти значение функции по Линейному методу интерполяции
procedure TFndimFunctionByPoints1d.LinearInterpolation(x: Double;Fresult: PDouble);
var
  i,j,k: NativeInt;
  y,y1,y2,x1,x2,dy,dx,x0: Double;
  outOfXflag: Boolean;
begin
  i := FindIntervalIndex_ofX(x, outOfXflag);

  if (not outOfXflag)or(ExtrapolationType=2) then begin
    if i=pointsCount-1 then begin // последняя точка интервала значит экстраполяция - берем ее и предпоследнюю.
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
      0:  // константа вне диапазона
        begin
        getPoint_Fi(i, Fresult);
        exit;
        end;

      1: // ноль вне диапазона
        begin
          for j:=0 to Fdim-1 do begin
            Fresult[j] := 0;
            end;
        end;
      else
        Assert(False,'метод экстраполяции '+IntToStr(ExtrapolationType)+' не реализован');
      end;
    end;
end;


//===========================================================================
// найти значение функции по интерполяции кубическими сплайнами
procedure TFndimFunctionByPoints1d.SplineInterpolation(x: Double; Fresult: PDouble);
var
  i,j: NativeInt;
  outOfXflag: Boolean;
begin
  i := FindIntervalIndex_ofX(x, outOfXflag);

  if (not outOfXflag)or(ExtrapolationType=2) then begin // экстраполяция не требуется
    getPoint_Fi(i, Fresult);
    exit;
    end;

  if outOfXflag then begin
    case ExtrapolationType of
      0,2:  // константа вне диапазона, либо экстраполировать границы
        begin
        getPoint_Fi(i, Fresult);
        exit;
        end;

      1: // ноль вне диапазона
        begin
          for j:=0 to Fdim-1 do begin
            Fresult[j] := 0;
            end;
        end;
      else
        Assert(False,'метод экстраполяции '+IntToStr(ExtrapolationType)+' не реализован');
      end;
    end;
end;

//===========================================================================
//===========================================================================
//===========================================================================

{$POINTERMATH OFF}
{$ASSERTIONS OFF}
end.
