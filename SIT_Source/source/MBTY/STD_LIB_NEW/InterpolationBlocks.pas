//**************************************************************************//
 // Данный исходный код является составной частью системы МВТУ-4             //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit InterpolationBlocks;

 //***************************************************************************//
 //                Блоки интерполяции
 //***************************************************************************//

 {
 создан на основе оригинальной библиотеки mbty_std
 реализация одномерной и двухмерной интерполяции, где исходные данные могут быть
 заданы в виде констант - векторов и матриц, и в виде внешних файлов.
 }

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath;


type
/////////////////////////////////////////////////////////////////////////////
// блок интерполяции по ТЗ от 3 февраля 2025, от одномерного аргумента
  TInterpolationBlock1 = class(TRunObject)
  protected
    // ПЕРЕЧИСЛЕНИЕ откуда берем входные данные
    // 0- ввести вручную 1-аргумент и ф-я в разных файлах
    // 2- аргумент и функция в одном файле 3- через порты
    InputsMode: NativeInt;
    ExtrapolationType: NativeInt;   // ПЕРЕЧИСЛЕНИЕ тип экстраполяции за пределами определения функции - константа,ноль, интерполяция по крайним точкам
    FileName: string; // имя единого входного файла
    FileNameArgsX: string; // имя входного файла для аргументов при раздельной загрузке
    FileNameFuncTable: string; // имя входного файла для значений функции при раздельной загрузке

    property_Xi_array: TExtArray; // точки аргументов Xi функции, если она задана через свойства объекта
    property_Fi_array: TExtArray; // точки значений Fi функции, если она задана через свойства объекта

    //ПЕРЕЧИСЛЕНИЕ тип интерполяции
    //0:Кусочно-постоянная 1:Линейная 2:Сплайн Кубический 3: Лагранж
    InterpolationType,
    LagrangeOrder,  // порядок интерполяции для метода Лагранжа
    Npoints, // число точек функции
    prop_Npoints,
    M_LagrangeShift,

    Fdim: NativeInt; // размерность выходного вектора функции
    prop_Fdim: NativeInt;

    prop_IsNaturalSpline: Boolean;
    SplineArr: TExtArray2;

    // последний найденный интервал интерполяции при вызове функции Interpol
    LastInd: array of NativeInt;

    Xi_array: TExtArray; // точки аргументов Xi функции, если она считана из файла
    Fi_array: TExtArray; // точки значений Fi функции, если она считана из файла

    x_stamp: TExtArray2; // Массивы изходных данных - реально применяются только для
    y_stamp: TExtArray2; // отслеживания изменения входных данных

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
  property_Xi_array := TExtArray.Create(1); // точки аргументов Xi функции, если она задана через свойства объекта
  property_Fi_array:= TExtArray.Create(1); // точки значений Fi функции, если она задана через свойства объекта

  SplineArr := TExtArray2.Create(1,1);
  x_stamp := TExtArray2.Create(1,1);
  y_stamp := TExtArray2.Create(1,1);

  Xi_array := TExtArray.Create(1); // точки аргументов Xi функции, если она считана из файла
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

  // ПЕРЕЧИСЛЕНИЕ откуда берем входные данные
  if StrEqu(ParamName,'InputsMode') then begin
    Result:=NativeInt(@InputsMode);
    DataType:=dtInteger;
    exit;
    end;

  // размерность выходного вектора функции
  if StrEqu(ParamName,'Fdim') then begin
    Result:=NativeInt(@prop_Fdim);
    DataType:=dtInteger;
    exit;
    end;

  // число заданных точек функции
  if StrEqu(ParamName,'Npoints') then begin
    Result:=NativeInt(@prop_Npoints);
    DataType:=dtInteger;
    exit;
    end;

  // тип интерполяции - кусочно-постоянная, линейная, Лагранжа и т.п.
  if StrEqu(ParamName,'InterpolationType') then begin
    Result:=NativeInt(@InterpolationType);
    DataType:=dtInteger;
    exit;
    end;

  // тип экстраполяции за пределами определения функции - константа, кусочно-постоянная и т.д.
  if StrEqu(ParamName,'ExtrapolationType') then begin
    Result:=NativeInt(@ExtrapolationType);
    DataType:=dtInteger;
    exit;
    end;

  // порядок интерполяции для метода Лагранжа
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

  ErrorEvent('параметр '+ParamName+'В блоке MyInterpolationBlock1 не найден', msWarning, VisualObject);
end;

{
function    TInterpolationBlock1.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result := r_Success;

  case Action of
    i_GetInit:  begin
                // переустанавливаем размерность выходного вектора функции
                Func.ClearPoints;
                Func.setFdim(Fdim);
                Result := r_Success;
                end;

    i_GetCount:  begin
                   if Length( cU ) = 0 then begin  // входной вектор нулевой длины - невозможная ситуация
                     ErrorEvent(txtSumErr,msError,VisualObject);
                     Result:=r_Fail;
                     exit;
                    end;

                   //TODO зачем устанавливать размерность производных выходного вектора - УЗНАТЬ
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

  if property_Fi_array.Count<>Fdim*property_Xi_array.Count then begin //проверка корректности входных размеров
    ErrorEvent('Число значений Fi_array и аргументов Xi_array входной функции не совпадает',msError,VisualObject);
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
    ErrorEvent('Файл '+FileNameArgsX+' невозможно считать',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if not tableF.OpenFromFile(FileNameFuncTable) then begin
    ErrorEvent('Файл '+FileNameFuncTable+' невозможно считать',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if tableX.px.count<>tableF.px.count then begin
    ErrorEvent('Файлы '+FileNameArgsX+' и '+FileNameFuncTable+' содержат разное число строк',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if Fdim <> (1+tableF.FunsCount) then begin
    ErrorEvent('Размерность функции из файла = '+IntToStr((1+tableF.FunsCount))+' и свойства Fdim= '+IntToStr(Fdim)+' не совпадает, используем размености из файла',msWarning,VisualObject);
    //Result := False;
    //goto OnExit;
    end;

  Xi_array.ChangeCount(tableX.px.count);
  Fi_array.ChangeCount(tableF.px.count*(tableF.FunsCount+1));

  // размерности устанавливаем из файла
  //Npoints := tableF.px.count*(tableF.FunsCount+1);
  Npoints := tableF.px.count;
  Fdim := tableF.FunsCount+1;

  // идем по входному вектору и добавляем точки в функцию.
  yy := 0;
  for i:=0 to tableX.px.count-1 do begin
    Xi_array[i] := tableX.px[i];

    // TODO переделать - дурацкий метод, но работает
    Fi_array[yy] := tableF.px[i]; // первая точка - из первого столбца аргументов
    inc(yy);
    for j:=0 to tableF.FunsCount-1 do begin // остальные точки - из вектора значений
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
    ErrorEvent('Файл '+FileName+' невозможно считать',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  Xi_array.ChangeCount(table1.px.count);
  Fi_array.ChangeCount(table1.px.count*table1.FunsCount);

  // размерности устанавливаем из файла
  //Npoints := table1.px.count*table1.FunsCount;
  Npoints := table1.px.count;
  Fdim := table1.FunsCount;

  yy:=0;
  for i:=0 to table1.px.count-1 do begin // идем по входному вектору и добавляем точки в функцию.
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
  // 0. проверяем размерности входных портов -
  // U[0] - args - значение аргумента X
  // U[1] - args_arr - массив заданных значений аргумента
  // U[2] - func_table - матрица значений функции
  //--------------------------------------------------------
  if Length(U)<>3 then begin
    ErrorEvent('Число входных портов не равно 3',msError,VisualObject);
    Result := False;
    exit;
    end;

  if U[2].Count<>Fdim*U[1].Count then begin //проверка корректности входных размеров
    ErrorEvent('Число значений Fi и аргументов Xi входной функции не совпадает',msError,VisualObject);
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
      ErrorEvent('Метод задания функции '+IntToStr(InputsMode)+' не реализован',msError,VisualObject);
    end;
  end;
  {
  // проверяем, упорядочены ли точки. При необходимости - упорядочиваем
  if not Func.IsXsorted then begin
    Func.sortPoints;
    ErrorEvent('значения Xi были упорядочены по возрастанию', msWarning, VisualObject );
    end;

  // проверяем, есть ли в аргументах Х дубликаты
  if Func.IsXduplicated then begin
    ErrorEvent('значения Xi имеют дубликаты', msWarning, VisualObject );
    end;

  //
  if (InterpolationType = 3) and (LagrangeOrder > Func.pointsCount) then begin
    ErrorEvent('порядок метода Лагранжа больше заданного числа точек, применим порядок = '+IntToStr(Func.pointsCount), msWarning, VisualObject );
    end;
  }

end;

//===========================================================================
function    TInterpolationBlock1.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result := r_Success;
  Fdim := prop_Fdim;
  NPoints := prop_Npoints;

  // TODO как переделать, чтобы знать актуальные размерности функции из файлов?
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

// оригинальная версия, проверенная временем. После Рефакторинга.
function   TInterpolationBlock1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var
  i,j,c   : Integer;
  py: PExtArr; // указатели на значения и аргументы интерполируемых функции.
  px: PExtArr; // изменяются в SetPxPy
  Yvalue: RealType;

function checkX_range(x: RealType; var AYvalue: RealType):Boolean;
// проверить, что аргумент х находится внутри диапазона определения функции.
// возвращает - True - аргумент х находится внутри диапазона и экстраполяция не требуется.
// иначе - False, и изменяет AYValue на значение экстраполяции
begin

  if ExtrapolationType=2 then begin // экстраполировать границы для заданного метода
    Result := True;
    exit;
    end;

  if x<px[0] then begin
    case ExtrapolationType of
      0: // константа вне диапазона
        begin
          Result := False;
          AYvalue := py[0]; // берем первое значение из таблицы значений
          exit;
        end;

      1: // ноль вне диапазона
        begin
          Result := False;
          AYvalue := 0;
          exit;
        end;
      end;
    end;

  if x>px[Npoints-1] then begin
    case ExtrapolationType of
      0: // константа вне диапазона
        begin
          Result := False;
          AYvalue := py[Npoints-1]; // берем последнее значение из таблицы значений
          exit;
        end;

      1: // ноль вне диапазона
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
// устанавливаем указатели px py на начало актуальных данных
begin
  case InputsMode of
    0: // из свойств
      begin
        // устанавливаем указатели на свойства
        px := property_Xi_array.Arr;
        py := property_Fi_array.Arr;
      end;

    1,2: // из файлов в разных вариантах
      begin
          // устанавливаем указатели на считанные данные
          px := Xi_array.Arr;
          py := Fi_array.Arr;
      end;

    3: // из портов
      begin
        // U[1] - агрументы, U[2] - таблица значений
        px := U[1].Arr;
        py := U[2].Arr;
      end;
  end;

end;
//------------------------------------------------------------------------
function  IsNewData:boolean;
// входной вектор был изменен?
// Это Признак для пересчета внутренних матриц функций интерполяции
var
  j: integer;
begin
  Result := False;
  for j:=0 to Npoints - 1 do // идем по данным, если видим неравенство - данные новые.
    if (x_stamp[i].Arr^[j] <> px[j]) or (y_stamp[i].Arr^[j] <> py[j]) then begin
      x_stamp[i].Arr^[j] := px[j];
      y_stamp[i].Arr^[j] := py[j];
      Result:=True;
      end;
end;
// начало RunFunc ----------------------------------------------------------
var
  nXindex: NativeInt;
begin
  Result := r_Success;

  case Action of
    f_InitObjects:
      begin
        //Здесь устанавливаем нужные размерности вспомогательных таблиц и переменных
        SetLength(LastInd,GetFullDim(cU[2].Dim));
        ZeroMemory(Pointer(LastInd), GetFullDim(cU[2].Dim)*SizeOf(NativeInt));
        SplineArr.ChangeCount(5, Npoints);
        x_stamp.ChangeCount(Fdim, Npoints);
        y_stamp.ChangeCount(Fdim, Npoints);

        // загружаем таблицу функции из заданного источника
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
        // U[0] - args - значение аргумента X
        c := 0;
        SetPxPy(); // устанавливаем указатели на начало данных

        for i:=0 to Fdim - 1 do begin
         case InterpolationType of
           3:   // Лагранж
              begin
                // TODO обсудить Лагранж!!
                for j:=0 to U[0].Count - 1 do begin
                  // function Lagrange(var X1,Y1 :array of RealType;X:RealType;N,M:Integer):RealType;
                  // X1 - МАССИВ ЗНАЧЕНИЙ АРГУМЕНТА, Y1 - МАССИВ ЗНАЧЕНИЙ ФУНКЦИИ,
                  // X - АРГУМЕНТ, N - ПОРЯДОК ПОЛИНОМА, M - HOMEP ЭЛЕМЕНТА, C KOTOPOГO НЕОБХОДИМО НАЧАТЬ ИНТЕРПОЛЯЦИЮ
                  if checkX_range(U[0].Arr^[j],Yvalue) then begin

                      nXindex := NPoints-1;
                      // смещение для вычисления полинома Л считаем по интервалу нахождения аргумента Х
                      Find1(U[0].Arr^[j],px,NPoints,nXindex);
                      M_LagrangeShift := nXindex;

                      // полином по точкам функции, не выходя за ее пределы
                      // подробности см. реализации Lagrange
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

           2:   //Вычисление натурального кубического сплайна
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

           1:   // Линейная интерполяция
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

           0:     // кусочная интерполяция.
              begin
                  for j:=0 to U[0].Count-1 do begin
                    if checkX_range(U[0].Arr^[j],Yvalue) then begin
                        // находим интервал значений для интерполяции
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
                ErrorEvent('метод интерполяции "'+IntToStr(InterpolationType)+'" не реализован', msError, VisualObject );
                Result := r_Fail;
                exit;
              end;
           end;

         // двигаем указатель на данные следующей функции в наборе
         py := @py^[Npoints];
        end
      end;
  end
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
end.
