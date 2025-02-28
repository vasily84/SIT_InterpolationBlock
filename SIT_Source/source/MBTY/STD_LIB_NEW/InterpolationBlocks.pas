//**************************************************************************//
 // Данный исходный код является составной частью системы SimInTech          //
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
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath,TExtArray_Utils;


type
/////////////////////////////////////////////////////////////////////////////
// блок интерполяции по ТЗ от 3 февраля 2025, от одномерного аргумента
  TInterpolationBlock1 = class(TRunObject)
  protected
    // ПЕРЕЧИСЛЕНИЕ откуда берем входные данные
    // 0- ввести вручную 1-аргумент и ф-я в разных файлах
    // 2- аргумент и функция в одном файле 3- через порты
    InputMode: NativeInt;
    ExtrapolationType: NativeInt;   // ПЕРЕЧИСЛЕНИЕ тип экстраполяции за пределами определения функции - константа,ноль, интерполяция по крайним точкам

    prop_Xi_arr: TExtArray; // точки аргументов Xi функции, если она задана через свойства объекта
    prop_Fi_arr: TExtArray; // точки значений Fi функции, если она задана через свойства объекта

    //ПЕРЕЧИСЛЕНИЕ тип интерполяции
    //0:Кусочно-постоянная 1:Линейная 2:Сплайн Кубический 3: Лагранж
    InterpolationType,
    LagrangeOrder,  // порядок интерполяции для метода Лагранжа
    Npoints, // число точек функции
    prop_Npoints, // для задания числа точек через порты
    nport,
    Fdim: NativeInt; // размерность выходного вектора функции

    FileName: string; // имя единого входного файла
    FileNameArgsX: string; // имя входного файла для аргументов при раздельной загрузке
    FileNameValsF: string; // имя входного файла для значений функции при раздельной загрузке

    prop_IsNaturalSpline: Boolean;
    SplineArr: TExtArray2;

    // последний найденный интервал интерполяции при вызове функции Interpol
    LastInd: array of NativeInt;

    Xi_data: TExtArray; // точки аргументов Xi функции, если она считана из файла
    Fi_data: TExtArray; // точки значений Fi функции, если она считана из файла

    x_stamp: TExtArray2; // Массивы изходных данных - реально применяются только для
    y_stamp: TExtArray2; // отслеживания изменения входных данных

    function LoadFunc(): Boolean; // загрузить данные интерполируемой функции
    function LoadFuncFromProperties(): Boolean;
    function LoadFuncFromFilesXiFi(): Boolean;
    function LoadFuncFromFile(): Boolean;
    function LoadFuncFromPorts(): Boolean;

    function CheckInputsU(): Boolean; // проверить корректность входных портов

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
  txtParamUnknown1 = 'параметр "';
  txtParamUnknown2 = '" в блоке не найден';
  txtFiXiDimError = 'Число значений Fi и аргументов Xi входной функции не совпадает';
  txtFileError1 = 'Файл ';
  txtFileError2 = ' невозможно считать';
  txtPortsNot3 = 'Число входных портов не равно 3'; // переделать с названиями входных портов

  txtInputModeErr1 = 'Метод задания таблицы функции ';
  txtInputModeErr2 = ' не реализован';

  txtInterpolationTypeErr1 = 'метод интерполяции "';
  txtInterpolationTypeErr2 = '" не реализован';

  txtFilesRowCountErr1 = 'Файлы ';
  txtFilesRowCountErr2 = ' содержат разное число строк';
  txtFilesWrongFdim1 = 'Размерность функции из файла и свойства Fdim ';
  txtFilesWrongFdim2 = ' не совпадает';
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

  prop_Xi_arr := TExtArray.Create(1); // точки аргументов Xi функции, если она задана через свойства объекта
  prop_Fi_arr:= TExtArray.Create(1); // точки значений Fi функции, если она задана через свойства объекта

  SplineArr := TExtArray2.Create(1,1);
  x_stamp := TExtArray2.Create(1,1);
  y_stamp := TExtArray2.Create(1,1);

  Xi_data := TExtArray.Create(1); // точки аргументов Xi функции, если она считана из файла
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

  // ПЕРЕЧИСЛЕНИЕ откуда берем входные данные
  if StrEqu(ParamName,'InputMode') then begin
    Result:=NativeInt(@InputMode);
    DataType:=dtInteger;
    exit;
    end;

  // размерность выходного вектора функции
  if StrEqu(ParamName,'Fdim') then begin
    Result:=NativeInt(@Fdim);
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

  // число дополнительных портов
  if StrEqu(ParamName,'nport') then begin
    Result:=NativeInt(@nport);
    DataType:=dtInteger;
    exit;
    end;

  // число точек при задании через порты
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

  if prop_Fi_arr.Count<>Fdim*prop_Xi_arr.Count then begin //проверка корректности входных размеров
    ErrorEvent(txtFiXiDimError, msError, VisualObject);
    Result := False;
    exit;
    end;

  // копируем
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

  // размерность из файла
  Npoints := Xi_data.Count;

  // идем по входному вектору и добавляем точки в функцию.
  yy := 0;
  for i:=0 to tableX.px.count-1 do begin
    Xi_data[i] := tableX.px[i];

    // TODO переделать - дурацкий метод, но работает
    Fi_data[yy] := tableF.px[i]; // первая точка - из первого столбца аргументов
    inc(yy);
    for j:=0 to tableF.FunsCount-1 do begin // остальные точки - из вектора значений
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

  // размерности устанавливаем из файла
  Npoints := table1.px.count;

  yy:=0;
  for i:=0 to table1.px.count-1 do begin // идем по входному вектору и добавляем точки в функцию.
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
// проверить корректность входных портов
function TInterpolationBlock1.CheckInputsU(): Boolean;
begin
  Result := True;

  case InputMode of
    3: // из портов
    begin
      // 0. проверяем размерности входных портов -
      // U[0] - args - значение аргумента X
      // U[1] - args_arr - массив заданных значений аргумента
      // U[2] - func_table - матрица значений функции
      //--------------------------------------------------------

      if Length(U)<>3 then begin
        ErrorEvent(txtPortsNot3, msError, VisualObject);
        Result := False;
        exit;
        end;

      if U[2].Count<>Fdim*U[1].Count then begin //проверка корректности входных размеров
        ErrorEvent(txtFiXiDimError, msError, VisualObject );
        Result := False;
        exit;
        end;
    end;
    else // должен быть задан один входной порт
      begin
      if Length(U)<>1 then begin
        ErrorEvent('должен быть задан 1 входной порт', msError, VisualObject);
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

  if InputMode = 3 then Exit; // ниже проверки только для  0..2
  //TODO !! Важно!!
  // проверяем, упорядочены ли точки. При необходимости - упорядочиваем
  // проверяем, есть ли в аргументах Х дубликаты
  if not TExtArray_IsOrdered(Xi_data) then begin
    Assert(False,'не упорядочен Х');
    TExtArray_Sort_XY_Arr(Xi_data, Fi_data, Npoints, Fdim);
    end;

  if TExtArray_HasDuplicates(Xi_data) then begin
    Assert(False,'есть дубликаты Х');
    end;

end;

//===========================================================================
function    TInterpolationBlock1.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result := r_Success;

  case Action of  {
    i_GetPropErr: //Проверка правильности задания параметров блока (перед сортировкой)
      begin
        // TODO - добавить буфуризацию, чтобы читалось только 1 раз
        if not LoadFunc() then begin
          Result := r_Fail;
          exit;
          end;
      end;

    i_GetInit: //Получить флаг зависимости выходов от входов
      begin
      if not init_NPoints() then begin
        Result := r_Fail;
        exit;
        end;
      end;
      }

    i_GetCount: //Получить размерности входов\выходов
      begin

        if not LoadFunc() then begin // там необходимая информация о NPoints
          Result := r_Fail;
          exit;
          end;



        if InputMode=3 then begin // для случая задания функции через порты
          cU[1].Dim:=SetDim([Npoints]);
          cU[2].Dim:=SetDim([Npoints*Fdim]);
          end;
        // размерность выходного вектора всегда определена
        cY[0].Dim:=SetDim([GetFullDim(cU[0].Dim)*Fdim]);
      end;
    else
      Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

//============================================================================
// TODO!!. Обсудить!! Корректное, ИМХО, использование Лагранжа.
// точка начала построения полинома Л утанавливается принудительно рядом с инервалом интерполяции
//============================================================================
function MyLagrange(var px,py :PExtArr;X:RealType;LagrOrder,NPoints:Integer):RealType;
//    px - МАССИВ ЗНАЧЕНИЙ АРГУМЕНТА
//    py - МАССИВ ЗНАЧЕНИЙ ФУНКЦИИ
//    X - АРГУМЕНТ
//    LagrOrder - ПОРЯДОК ПОЛИНОМА
//    NPoints - число точек в наборе
var
  Mshift: Integer;
  nXindex: NativeInt;
begin
  nXindex := NPoints-1;
  // смещение для вычисления полинома Л считаем по интервалу нахождения аргумента Х
  Find1(X,px, NPoints,nXindex);
  Mshift := nXindex;

  // полином по точкам функции, не выходя за ее пределы
  // подробности см. реализации Lagrange
  if(Mshift+LagrOrder)>=(Npoints-1) then begin
    Mshift:= Npoints-1- LagrOrder;
    end;

  if (Mshift<1) then Mshift:=1;

  // вызываем старую функцию с уже правильным M
  Result := Lagrange(px^,py^,X,LagrOrder,Mshift);
end;
//=============================================================================

// оригинальная версия, проверенная временем. После Рефакторинга. Изменения в вызове Лагарнжа.
function   TInterpolationBlock1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var
  i,j,c   : Integer;
  py: PExtArr; // указатели на значения и аргументы интерполируемых функции,
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
  case InputMode of
    0: // из свойств
      begin
        // устанавливаем указатели на свойства
        px := prop_Xi_arr.Arr;
        py := prop_Fi_arr.Arr;
      end;

    1,2: // из файлов в разных вариантах
      begin
          // устанавливаем указатели на считанные данные
          px := Xi_data.Arr;
          py := Fi_data.Arr;
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
function  CheckChanges: boolean;
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
//--------------------------------------------------------------------------
// -- начало самой RunFunc -------------------------------------------------
var
  nXindex: NativeInt;
begin
  Result := r_Success;

  case Action of
    f_InitObjects:
      begin
        // загружаем таблицу функции из заданного источника
        if not LoadFunc() then begin
          Result := r_Fail;
          exit;
          end;

        //Здесь устанавливаем нужные размерности вспомогательных таблиц и переменных
        SetLength(LastInd,GetFullDim(cU[2].Dim));
        ZeroMemory(Pointer(LastInd), GetFullDim(cU[2].Dim)*SizeOf(NativeInt));
        SplineArr.ChangeCount(5, Npoints);
        x_stamp.ChangeCount(Fdim, Npoints);
        y_stamp.ChangeCount(Fdim, Npoints);
      end;

    f_InitState, //Запись начальных состояний
    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep:
      begin
        // U[0] - args - всегда значение аргумента X
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
                      //Y[0].arr^[i*U[0].Count+j] := Lagrange(px^,py^,U[0].arr^[j],LagrangeOrder,1);
                      Y[0].arr^[i*U[0].Count+j] := MyLagrange(px,py,U[0].arr^[j],LagrangeOrder,NPoints);
                    end else begin
                      Y[0].arr^[i*U[0].Count+j] := Yvalue;
                    end;

                  inc(c);
                  end;
              end;

           2:   //Вычисление натурального кубического сплайна
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

           1:   // Линейная интерполяция
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
                ErrorEvent(txtInterpolationTypeErr1+IntToStr(InterpolationType)+txtInterpolationTypeErr2, msError, VisualObject );
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

/////////////////////////////////////////////////////////////////////////////
// НИЖЕ ИДУТ ТЕСТЫ //////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
//---------------------------------------------------------------------------

end.
