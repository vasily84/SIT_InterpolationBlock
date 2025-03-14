//**************************************************************************//
 // Данный исходный код является составной частью системы SimInTech          //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit Interpol_Blocks;

 //***************************************************************************//
 //                Блоки интерполяции
 //***************************************************************************//

 //создан на основе оригинальной библиотеки mbty_std
 //реализация вариантов одномерной, двумерной и многомерной интерполяции,
 //где исходные данные могут быть заданы по разному - через свойства, файлы, или порты.

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath,RealArrays_Utils;

type
/////////////////////////////////////////////////////////////////////////////
// блок интерполяции от одномерного аргумента
  TInterpolBlock1d = class(TRunObject)
  protected
    // ПЕРЕЧИСЛЕНИЕ откуда берем входные данные
    // 0- ввести вручную 1-аргумент и ф-я в разных файлах
    // 2- аргумент и функция в одном файле 3- через порты
    InputMode: NativeInt;
    ExtrapolationType: NativeInt;   // ПЕРЕЧИСЛЕНИЕ тип экстраполяции за пределами определения функции - константа,ноль, интерполяция по крайним точкам

    prop_X_arr: TExtArray; // точки аргументов Xi функции, если она задана через свойства объекта
    prop_F_arr: TExtArray; // точки значений Fi функции, если она задана через свойства объекта

    //ПЕРЕЧИСЛЕНИЕ тип интерполяции
    //0:Кусочно-постоянная 1:Линейная 2:Сплайн Кубический 3: Лагранж
    InterpolationType,
    LagrangeOrder,  // порядок интерполяции для метода Лагранжа
    Npoints, // число точек функции
    prop_Npoints, // для задания числа точек через порты
    nport, // свойство для изменения числа видимых портов
    Fdim: NativeInt; // размерность выходного вектора функции

    FileName: string; // имя единого входного файла
    FileNameArgs: string; // имя входного файла для аргументов при раздельной загрузке
    FileNameVals: string; // имя входного файла для значений функции при раздельной загрузке

    prop_IsNaturalSpline: Boolean;
    SplineArr: TExtArray2;

    // последний найденный интервал интерполяции при вызове функции Interpol
    LastInd: array of NativeInt;

    Xarr_data: TExtArray; // точки аргументов Xi функции, если она считана из файла
    Farr_data: TExtArray; // точки значений Fi функции, если она считана из файла
    // Массивы изходных данных - реально применяются только для отслеживания изменения входных данных
    x_stamp,y_stamp: TExtArray2;

    function LoadData(): Boolean; // загрузить данные интерполируемой функции
    function LoadDataFromProperties(): Boolean;
    function LoadDataFrom2Files(): Boolean;
    function LoadDataFromFile(): Boolean;
    function LoadDataFromPorts(): Boolean;
    function LoadDataFromJSON(): Boolean;

    function CheckInputsU(): Boolean; // проверить корректность входных портов

  public
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
  end;

///////////////////////////////////////////////////////////////////////////////
//Двумерная линейная интерполяция по таблице из файла
type
  TInterpolBlockXY = class(TRunObject)
  protected
    table: TTable2;
  public
    fileName,FileNameArgs,FileNameVals: string;
    InterpolationType: NativeInt;
    ExtrapolationType: NativeInt;
    inputMode: NativeInt;
    nport: NativeInt;
    prop_X1_arr, prop_X2_arr: TExtArray;
    prop_DataTable: TExtArray2;

    function LoadDataFromPorts(): Boolean;
    function LoadDataFromProperties(): Boolean;
    function LoadDataFrom2Files():Boolean;
    function LoadDataFromFile(): Boolean;
    function LoadDataFromJSON(): Boolean;
    function LoadData(): Boolean;


    function checkXY_Range(var aX1,aX2: RealType;var aZvalue: RealType): Boolean;
    function InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor Create(Owner: TObject);override;
    destructor Destroy;override;

    // TODO - выяснить, что это было?
    function GetOutParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    function ReadParam(ID: NativeInt;ParamType:TDataType;DestData: Pointer;DestDataType: TDataType;MoveData:TMoveProc):boolean;override;
  end;

/////////////////////////////////////////////////////////////////////
//Блок многомерной линейной интерполяции
type
  TInterpolBlockMultiDim = class(TRunObject)
  public
   // это свойства
   ExtrapolationType: NativeInt; // ПЕРЕЧИСЛЕНИЕ тип экстраполяции при аргументе за пределами границ
   InterpolationType: NativeInt; // ПЕРЕЧИСЛЕНИЕ метод интерполяции

   inputMode: NativeInt; // ПЕРЕЧИСЛЕНИЕ метод задания функции
   FileName: string;

   prop_X: TExtArray2; // матрица аргументов по размерностям
   prop_F: TExtArray;  // Вектор значений функции

   Xtable: TExtArray2; // матрица аргументов по размерностям
   Ftable: TExtArray;  // Вектор значений функции

   // это внутренние переменные
   tmpXp:         TExtArray2; // для Аргумента функции, считанного из входа U
   u_,v_:         TExtArray;
   ad_,k_:        TIntArray;

   function LoadDataFromProperties(): Boolean;
   function LoadDataFromFile(): Boolean;
   function LoadDataFromJSON(): Boolean;
   function LoadData(): Boolean;

   function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
   function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
   function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
   constructor    Create(Owner: TObject);override;
   destructor     Destroy;override;
 end;

 ///////////////////////////////////////////////////////////////////////
implementation

uses RealArrays,JSON,IOUtils;

const
  // назначения входных портов для интерполяции на плоскости
  ROW_ARG = 0;
  COL_ARG = 1;
  ROW_ARGS_ARR = 2;
  COL_ARGS_ARR = 3;
  FUNCS_TABLE = 4;

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
  txtXiduplicates = 'таблица значений функции содержит дубликаты аргумента';
  txtFuncTableReordered = 'таблица значений функции переупорядочена по возрастанию аргумента';
  txtPortsNot1 = 'должен быть задан 1 входной порт';
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
  txtXiduplicates = 'The table of function values contains duplicate arguments';
  txtFuncTableReordered = 'the table of function values is reordered in ascending order of the argument';
  txtPortsNot1 = 'must be set only 1 input port';
{$ENDIF}

//===========================================================================

constructor TInterpolBlock1d.Create;
begin
  inherited;
  // TODO
  IsLinearBlock:=True;

  prop_X_arr := TExtArray.Create(1); // точки аргументов Xi функции, если она задана через свойства объекта
  prop_F_arr:= TExtArray.Create(1); // точки значений Fi функции, если она задана через свойства объекта

  SplineArr := TExtArray2.Create(1,1);
  x_stamp := TExtArray2.Create(1,1);
  y_stamp := TExtArray2.Create(1,1);

  Xarr_data := TExtArray.Create(1); // точки аргументов Xi функции, если она считана из файла
  Farr_data := TExtArray.Create(1);
end;
//----------------------------------------------------------------------------
destructor  TInterpolBlock1d.Destroy;
begin
  FreeAndNil(prop_X_arr);
  FreeAndNil(prop_F_arr);

  FreeAndNil(SplineArr);
  FreeAndNil(x_stamp);
  FreeAndNil(y_stamp);

  FreeAndNil(Xarr_data);
  FreeAndNil(Farr_data);

  if Assigned(LastInd) then SetLength(LastInd,0);

  inherited;
end;
//---------------------------------------------------------------------------
function    TInterpolBlock1d.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
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

  if StrEqu(ParamName,'X_arr') then begin
    Result:=NativeInt(prop_X_arr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'F_arr') then begin
    Result:=NativeInt(prop_F_arr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'FileNameArgsX') then begin
    Result:=NativeInt(@FileNameArgs);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'FileNameValsF') then begin
    Result:=NativeInt(@FileNameVals);
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

function TInterpolBlock1d.LoadDataFromProperties(): Boolean;
begin
  Result := True;

  if prop_F_arr.Count<>Fdim*prop_X_arr.Count then begin //проверка корректности входных размеров
    ErrorEvent(txtFiXiDimError, msError, VisualObject);
    Result := False;
    exit;
    end;

  // копируем
  TExtArray_cpy(Xarr_data, prop_X_arr);
  TExtArray_cpy(Farr_data, prop_F_arr);
  NPoints := Xarr_data.Count;
end;
//---------------------------------------------------------------------------

function TInterpolBlock1d.LoadDataFrom2Files(): Boolean;
label
  OnExit;
var
  tableX,tableF: TTable1;
  i,j,yy: Integer;
begin
  Result := True;
  tableX := TTable1.Create(FileNameArgs);
  tableF := TTable1.Create(FileNameVals);

  if not tableX.OpenFromFile(FileNameArgs) then begin
    ErrorEvent(txtFileError1+FileNameArgs+txtFileError2,msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if not tableF.OpenFromFile(FileNameVals) then begin
    ErrorEvent(txtFileError1+FileNameVals+txtFileError2,msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if tableX.px.count<>tableF.px.count then begin
    ErrorEvent(txtFilesRowCountErr1+FileNameArgs+', '+FileNameVals+txtFilesRowCountErr2,msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if Fdim <> (1+tableF.FunsCount) then begin
    ErrorEvent(txtFilesWrongFdim1+IntToStr((1+tableF.FunsCount))+' <> '+IntToStr(Fdim)+txtFilesWrongFdim2, msWarning, VisualObject);
    Result := False;
    goto OnExit;
    end;

  Xarr_data.ChangeCount(tableX.px.count);
  Farr_data.ChangeCount(tableF.px.count*(tableF.FunsCount+1));

  // размерность из файла
  Npoints := Xarr_data.Count;

  // идем по входному вектору и добавляем точки в функцию.
  yy := 0;
  for i:=0 to tableX.px.count-1 do begin
    Xarr_data[i] := tableX.px[i];

    // TODO переделать - дурацкий метод, но работает
    Farr_data[yy] := tableF.px[i]; // первая точка - из первого столбца аргументов
    inc(yy);
    for j:=0 to tableF.FunsCount-1 do begin // остальные точки - из вектора значений
      Farr_data[yy] := tableF.py.Arr[j][i];
      inc(yy);
      end;
    end;

OnExit:
  FreeAndNil(tableX);
  FreeAndNil(tableF);
end;
//----------------------------------------------------------------------

function TInterpolBlock1d.LoadDataFromFile(): Boolean;
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

  Xarr_data.ChangeCount(table1.px.count);
  Farr_data.ChangeCount(table1.px.count*Fdim);

  // размерности устанавливаем из файла
  Npoints := table1.px.count;

  yy:=0;
  for i:=0 to table1.px.count-1 do begin // идем по входному вектору и добавляем точки в функцию.
    Xarr_data[i] := table1.px[i];

    for j:=0 to table1.FunsCount-1 do begin
      Farr_data[yy] := table1.py.Arr[j][i];
      //Fi_data[i+j*Npoints] := table1.py.Arr[j][i];
      inc(yy);
      end;
    end;

OnExit:
  FreeAndNil(table1);
end;

//============================================================================
// проверить корректность входных портов
function TInterpolBlock1d.CheckInputsU(): Boolean;
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
      //TODO - надо ли это вообще? SIT IDE сама проверяет размерности?
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
        ErrorEvent(txtPortsNot1, msError, VisualObject);
        Result := False;
        exit;
        end;
      end;
  end;
end;
//---------------------------------------------------------------------------
function TInterpolBlock1d.LoadDataFromPorts(): Boolean;  // stub
begin
  Result := True;
  Npoints := prop_Npoints;
end;
//----------------------------------------------------------------------------
function TInterpolBlock1d.LoadDataFromJSON(): Boolean;
var
  str1,str2: string;
  jso: TJSONObject;
  jsv: TJSONValue;
  jarr: TJSONArray;
  i,j,axisCount,jarrCount: Integer;
  arrValue: TJSONValue;
begin
  Result := True;
  jso := nil;

  try
    str1 := TFILE.ReadAllText(ExpandFileName(FileName));
    jso := TJSONObject.ParseJSONValue(str1) as TJSONObject;

    // подгружаем ось Х
    str2 := 'axis1';
    jarr := jso.GetValue(str2) as TJSONArray;
    jarrCount:=jarr.Count;
    Xarr_data.Count := jarrCount;

    for j := 0 to jarrCount - 1 do begin
      arrValue := jarr.Items[j];
      Xarr_data[j]:=StrToFloat(arrValue.AsType<string>);
      end;

    // подгружаем тело функции
    str2 := 'dataVolume';
    jarr := jso.GetValue(str2) as TJSONArray;
    jarrCount:=jarr.Count;
    Farr_data.Count := jarrCount;

    for j := 0 to jarrCount - 1 do begin
      arrValue := jarr.Items[j];
      Farr_data[j]:=StrToFloat(arrValue.AsType<string>);
      end;

  except
    Result := False;
  end;

  if Assigned(jso) then FreeAndNil(jso);
end;

//---------------------------------------------------------------------------
function TInterpolBlock1d.LoadData(): Boolean;
begin
  case InputMode of
    0:
      Result := LoadDataFromProperties();
    1:
      Result := LoadDataFrom2Files();
    2:
      Result := LoadDataFromFile();
    3:
      Result := LoadDataFromPorts();
    else begin
      Result := False;
      ErrorEvent(txtInputModeErr1+IntToStr(InputMode)+txtInputModeErr2, msError, VisualObject);
    end;
  end;


  // проверяем, есть ли в аргументах Х дубликаты
  if TExtArray_HasDuplicates(Xarr_data) then begin
    ErrorEvent(txtXiduplicates, msWarning, VisualObject);
    end;

  // TODO - сейчас с дубликатами дуркует.
  // Необходимо добавить функцию исключения дубликатов из кода

  // проверяем, упорядочены ли точки. При необходимости - упорядочиваем
  if (InputMode < 3)and(TExtArray_IsOrdered(Xarr_data)=False) then begin
    ErrorEvent(txtFuncTableReordered, msWarning, VisualObject);
    TExtArray_Sort_XY_Arr(Xarr_data, Farr_data, Npoints, Fdim);
    end;

end;

//===========================================================================
function    TInterpolBlock1d.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result := r_Success;

  case Action of
    //i_GetPropErr: //Проверка правильности задания параметров блока (перед сортировкой)

    i_GetCount: //Получить размерности входов\выходов
      begin

        if not LoadData() then begin // Загружаем, там необходимая информация о NPoints
          Result := r_Fail;
          exit;
          end;

        //CheckInputsU();

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
function   TInterpolBlock1d.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
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
          begin AYvalue := py[0]; end; // берем первое значение из таблицы значений

      1: // ноль вне диапазона
          begin AYvalue := 0; end;
      end;
    Result := False;
    exit;
    end;

  if x>px[Npoints-1] then begin
    case ExtrapolationType of
      0: // константа вне диапазона
          begin AYvalue := py[Npoints-1]; end; // берем последнее значение из таблицы значений

      1: // ноль вне диапазона
          begin AYvalue := 0; end;
      end;
    Result := False;
    exit;
    end;
  // х внутри диапазона определения функции, экстраполяция не требуется
  Result := True;
end;
//---------------------------------------------------------------------------
procedure SetPxPy;
// устанавливаем указатели px py на начало актуальных данных
begin
  case InputMode of
    0,1,2: // из файлов в разных вариантах
      begin
          // устанавливаем указатели на считанные данные
          px := Xarr_data.Arr;
          py := Farr_data.Arr;
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
  q: integer;
begin
  Result := False;
  for q:=0 to Npoints - 1 do // идем по данным, если видим неравенство - данные новые.
    if (x_stamp[i].Arr^[q] <> px[q]) or (y_stamp[i].Arr^[q] <> py[q]) then begin
      x_stamp[i].Arr^[q] := px[q];
      y_stamp[i].Arr^[q] := py[q];
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
//****************************************************************************
//            Двумерная линейная интерполяция по таблице
//****************************************************************************
constructor TInterpolBlockXY.Create;
begin
  inherited;
  table:=TTable2.Create('');
  InterpolationType:=0;
  prop_X1_arr:= TExtArray.Create(1);
  prop_X2_arr:= TExtArray.Create(1);
  prop_DataTable:= TExtArray2.Create(1,1);
end;

destructor TInterpolBlockXY.Destroy;
begin
  FreeAndNil(table);
  FreeAndNil(prop_X1_arr);
  FreeAndNil(prop_X2_arr);
  FreeAndNil(prop_DataTable);
  inherited;
end;
//---------------------------------------------------------------------------
function TInterpolBlockXY.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

  if StrEqu(ParamName,'Row_arr') then begin
    Result:=NativeInt(prop_X1_arr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'Col_arr') then begin
    Result:=NativeInt(prop_X2_arr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'DataMatrix') then begin
    Result:=NativeInt(prop_DataTable);
    DataType:=dtMatrix;
    exit;
    end;

  if StrEqu(ParamName,'interp_method') then begin
    Result:=NativeInt(@InterpolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'extrType') then begin
    Result:=NativeInt(@ExtrapolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'inputType') then begin
    Result:=NativeInt(@inputMode);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'filename') then begin
    Result:=NativeInt(@fileName);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'fileNameArgs') then begin
    Result:=NativeInt(@fileNameArgs);
    DataType:=dtString;
    exit;
    end;

if StrEqu(ParamName,'fileNameVals') then begin
    Result:=NativeInt(@fileNameVals);
    DataType:=dtString;
    exit;
    end;

// число дополнительных портов
  if StrEqu(ParamName,'nport') then begin
    Result:=NativeInt(@nport);
    DataType:=dtInteger;
    exit;
    end;

  ErrorEvent(txtParamUnknown1+ParamName+txtParamUnknown2, msWarning, VisualObject);
end;

//----------------------------------------------------------------------------
function TInterpolBlockXY.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result:=r_Success;
  case Action of
    i_GetPropErr:
      begin
           // уже есть свойства, можно проверить размерности свойств
      end;

    i_GetInit:   Result:=r_Success;

    i_GetCount:
      //
                if Length(cU) > 1 then begin
                    if GetFullDim( cU[1].Dim ) > GetFullDim( cU[0].Dim ) then
                       cU[0].Dim:=cU[1].Dim
                    else
                       cU[1].Dim:=cU[0].Dim;
                   cY[0]:=cU[0];
                 end
                 else
                   Result:=r_Fail;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.checkXY_Range(var aX1,aX2: RealType;var aZvalue: RealType): Boolean;
// проверить, что аргументы aX и aY находится внутри диапазона определения функции.
// возвращает - True - аргументы находится внутри диапазона и экстраполяция не требуется.
// иначе - False, и изменяет AYValue на значение экстраполяции
var
  // признаки нахождения аргументов в границах диапазонов
  //x1_belowRange,x1_inRange,x1_aboveRange,x2_belowRange,x2_inRange,x2_aboveRange: Boolean;
  x1_inRange,x2_inRange: Boolean;
begin

  if ExtrapolationType=2 then begin // экстраполировать границы для заданного метода
    Result := True;
    exit;
    end;

  x1_inRange := ((aX1>=table.px1[0])and(aX1<=table.px1[table.Arg1Count-1]));
  x2_inRange := ((aX2>=table.px2[0])and(aX2<=table.px2[table.Arg2Count-1]));

  // TODO -
  //if (x1_inRange and x2_inRange) then begin //- по идее должно быть так - обсудить
  if (x1_inRange or x2_inRange) then begin // в диапазоне, экстраполяция не требуется
    Result := True;
    exit;
    end;

  // за пределами диапазона, тип экстраполяции - ноль за пределами диапазона
  if ExtrapolationType=1 then begin
    Result := False;
    aZvalue := 0;
    exit;
    end;

  //x1_belowRange := aX1<table.px1[0];
  //x1_aboveRange := aX1>table.px1[table.Arg1Count-1];

  //x2_belowRange := aX2<table.px2[0];
  //x2_aboveRange := aX2>table.px2[table.Arg2Count-1];

  // кусочно-постоянная интерполяция
  Result:=False;
  // подставляем результат интервальной интерполяции
  aZvalue := table.GetFunValueWithoutInterpolation(aX1,aX2);
  // либо использовать
  // table.GetFunValueWithoutExtrapolation
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadDataFromPorts(): Boolean;
var
  i,j,k,M,N: Integer;
  f: RealType;
begin
  N := U[ROW_ARGS_ARR].Count;
  M := U[COL_ARGS_ARR].Count;
  // TODO - проверка размерности
  if (M*N<>U[FUNCS_TABLE].Count) then begin
    Result:=False;
    exit;
    end;

  table.Arg1Count := N;
  table.Arg2Count := M;

  TExtArray_cpy(table.px1, U[ROW_ARGS_ARR]);
  TExtArray_cpy(table.px2, U[COL_ARGS_ARR]);

  table.py.ChangeCount(N,M);
  k:=0;
  for i:=0 to N-1 do begin
    for j:=0 to M-1 do begin
      f := U[FUNCS_TABLE].Arr[k];
      Inc(k);
      table.py[i][j]:=f;
      end;
    end;

  Result := True;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadDataFromProperties(): Boolean;
var
  b1,b2: Boolean;
begin
  b1 := (prop_X1_arr.Count <> prop_DataTable.CountX);
  b2:=  (prop_X2_arr.Count <> prop_DataTable.GetMaxCountY);

  if (b1 or b2) then begin // некорректные размерности
    Result:=False;
    exit;
    end;

  table.Arg1Count := prop_X1_arr.Count;
  table.Arg2Count := prop_X2_arr.Count;

  TExtArray_cpy(table.px1, prop_X1_arr);
  TExtArray_cpy(table.px2, prop_X2_arr);
  TExtArray2_cpy(table.py, prop_DataTable);

  Result := True;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadDataFrom2Files(): Boolean;
var
  a,b: Boolean;
begin
  Result:=False;
end;

function TInterpolBlockXY.LoadDataFromJSON(): Boolean;
var
  str1,str2: string;
  jso: TJSONObject;
  jsv: TJSONValue;
  jarr: TJSONArray;
  i,j,k,axisCount,jarrCount,x1count,x2count: Integer;
  arrValue: TJSONValue;
begin
  Result := True;
  jso := nil;

  try
    str1 := TFILE.ReadAllText(ExpandFileName(FileName));
    jso := TJSONObject.ParseJSONValue(str1) as TJSONObject;

    // подгружаем ось Х1
    str2 := 'axis1';
    jarr := jso.GetValue(str2) as TJSONArray;
    x1Count:=jarr.Count;
    table.Arg1Count := x1Count;

    for j := 0 to jarrCount - 1 do begin
      arrValue := jarr.Items[j];
      table.px1[j]:=StrToFloat(arrValue.AsType<string>);
      end;

    // подгружаем ось Х2
    str2 := 'axis2';
    jarr := jso.GetValue(str2) as TJSONArray;
    x2Count:=jarr.Count;
    table.Arg2Count := x2Count;

    for j := 0 to jarrCount - 1 do begin
      arrValue := jarr.Items[j];
      table.px2[j]:=StrToFloat(arrValue.AsType<string>);
      end;

    // подгружаем тело функции
    jsv := jso.GetValue('dataVolume');
    jarr := jsv as TJSONArray;
    jarrCount := jarr.Count;
    table.py.ChangeCount(table.px1.Count,table.px2.Count);
    k := 0;

    for i:=0 to x1count-1 do
    for j := 0 to x2count-1 do begin
      arrValue := jarr.Items[k];
      table.py[i][j]:=StrToFloat(arrValue.AsType<string>);
      inc(k);
      end;

  except
    Result := False;
  end;

  if Assigned(jso) then FreeAndNil(jso);
end;

//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadDataFromFile(): Boolean;
begin
  //Загрузка данных из файла с таблицей
  Result:=True;
  table.OpenFromFile(fileName);
  if (table.px1.Count = 0) or (table.px2.Count = 0) then begin
    Result:=False;
    exit;
    end;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadData(): Boolean;
begin
case inputMode of
  0:// ввести вручную через свойства
    Result:=LoadDataFromProperties();
  1:// в разных файлах
    Result:=LoadDataFrom2Files();
  2:// в одном файле
    Result:=LoadDataFromFile();
  3:// через порты
    Result:=LoadDataFromPorts();
  else
    Assert(False,'unknown input type');
    Result:=False;
    exit;
  end;

end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
 var i: integer;
 Yval: RealType;
begin
  Result:=r_Success;

  case Action of
    f_InitObjects:
      begin
       //Загрузка данных из файла с таблицей
       if not LoadData() then begin
         ErrorEvent(txtErrorReadTable,msError,VisualObject);
         Result:=r_Fail;
       end;
      end;

    f_InitState:  // можно сделать общую загрузку и проверки для режимов файла
      begin
        //TODO - Загрузка данных из порта - почему сразу не выставляет данные на порту, неведомо
        if inputMode=3 then LoadDataFromPorts();
        // общая загрузка
        // общая проверка размерности из загруженного -
        // checkDimensions
      end;
    f_UpdateJacoby,
    f_UpdateOuts,
    f_RestoreOuts,
    f_GoodStep:
      begin

        case InterpolationType of

            0:  // линейная
              begin
              for i:=0 to U[0].Count - 1 do
                if checkXY_Range(U[0].Arr^[i],U[1].Arr^[i],Yval) then begin
                  Y[0].Arr^[i]:=table.GetFunValue(U[0].Arr^[i],U[1].Arr^[i]); end
                  else begin
                  Y[0].Arr^[i]:=Yval; end;
              end;

            1:  // кусочно-постоянная
               begin
                 for i:=0 to U[0].Count - 1 do
                  if checkXY_Range(U[0].Arr^[i],U[1].Arr^[i],Yval) then begin
                    Y[0].Arr^[i]:=table.GetFunValueWithoutInterpolation(U[0].Arr^[i],U[1].Arr^[i]); end
                    else begin
                    Y[0].Arr^[i]:=Yval;
                    end;
               end;

            2: // сплайны
              begin
                  for i:=0 to U[0].Count - 1 do
                    if checkXY_Range(U[0].Arr^[i],U[1].Arr^[i],Yval) then begin
                    Y[0].Arr^[i]:=table.GetFunValueBySplineInterpolation(U[0].Arr^[i],U[1].Arr^[i]); end
                    else begin
                    Y[0].Arr^[i]:=Yval;
                    end;
              end;

            3: // Акима
              begin
                  for i:=0 to U[0].Count - 1 do
                    if checkXY_Range(U[0].Arr^[i],U[1].Arr^[i],Yval) then begin
                      Y[0].Arr^[i]:=table.GetFunValueByAkimaInterpolation(U[0].Arr^[i],U[1].Arr^[i]); end
                      else begin
                      Y[0].Arr^[i]:=Yval;
                      end;
              end;
          else
            Assert(False,'TInterpolBlockXY interpolation method not implemented');
        end;
      end;

  end
end;
//--------------------------------------------------------------------------
// TODO - зачем это так сделано? выяснить.
function TInterpolBlockXY.GetOutParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result:=inherited GetOutParamID(ParamName, DataType, IsConst);
  if Result = -1 then begin
    if StrEqu(ParamName,'py_') then begin
      Result:=11;
      DataType:=dtMatrix;
    end
    else
    if StrEqu(ParamName,'px1_') then begin
      Result:=12;
      DataType:=dtDoubleArray;
    end
    else
    if StrEqu(ParamName,'px2_') then begin
      Result:=13;
      DataType:=dtDoubleArray;
    end
  end;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.ReadParam(ID: NativeInt;ParamType:TDataType;DestData: Pointer;DestDataType: TDataType;MoveData:TMoveProc):boolean;
// var i: integer;
begin
  Result:=inherited ReadParam(ID,ParamType,DestData,DestDataType,MoveData);
  if not Result then
  case ID of
    11: if table <> nil then begin
          MoveData(table.py,dtMatrix,DestData,DestDataType);
          Result:=True;
        end;
    12: if table <> nil then begin
          MoveData(table.px1,dtDoubleArray,DestData,DestDataType);
          Result:=True;
        end;
    13: if table <> nil then begin
          MoveData(table.px2,dtDoubleArray,DestData,DestDataType);
          Result:=True;
        end;
  end;
end;
/////////////////////////////////////////////////////////////////////////////

constructor  TInterpolBlockMultiDim.Create;
begin
  inherited;
  IsLinearBlock:=True;
  InterpolationType:=0;
  ExtrapolationType:=0;

  tmpXp:=TExtArray2.Create(1,1);
  // аргументы и значения функции для вычислений.
  // Могут быть получены - 1. из свойств объекта 2. загружены из файла
  Xtable:=TExtArray2.Create(1,1);
  Ftable:=TExtArray.Create(1);

  // свойства объекта - аргументы и значения функции
  prop_X:=TExtArray2.Create(1,1);
  prop_F:=TExtArray.Create(1);

  // внутренние переменные для функции интерполяции
  u_:=TExtArray.Create(1);
  v_:=TExtArray.Create(1);
  ad_:=TIntArray.Create(1);
  k_:=TIntArray.Create(1);
end;

destructor   TInterpolBlockMultiDim.Destroy;
begin
  FreeAndNil(tmpXp);
  FreeAndNil(Xtable);
  FreeAndNil(Ftable);
  FreeAndNil(prop_X);
  FreeAndNil(prop_F);
  FreeAndNil(u_);
  FreeAndNil(v_);
  FreeAndNil(ad_);
  FreeAndNil(k_);
  inherited;
end;

//--------------------------------------------------------------------------
function     TInterpolBlockMultiDim.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
 var p,i,nn: NativeInt;
begin
  Result:=r_Success;

  case Action of
    i_GetPropErr: // проверка размерностей
      begin
        if not LoadData then begin
              Result:=r_Fail;
              exit;
              end;

        if Xtable.CountX <= 0 then begin
          ErrorEvent(txtDimensionsNotDefined,msError,VisualObject);
          Result:=r_Fail;
          exit;
          end;

        //Вычисляем суммарную размерность
        p:=Xtable[0].Count;
        for i := 1 to Xtable.CountX - 1 do p:=p*Xtable[i].Count;

        //Проверяем всё ли задано в массиве val_
        if Ftable.Count > 0 then begin
          if Ftable.Count < p then begin
             ErrorEvent(txtOrdinatesDefineIncomplete+IntToStr(p),msWarning,VisualObject);
             Result := r_Fail;
             exit;
             end;
          end;
      end;

    i_GetCount:
      begin
        if not LoadData then begin
          Result:=r_Fail;
          exit;
          end;
          //Размерность выхода = размерность входа делённая на размерность матрицы абсцисс
          cY[0].Dim:= SetDim([ GetFullDim(cU[0].Dim) div Xtable.CountX ]);
          //Условие кратности рзмерности
          nn := cY[0].Dim[0]*Xtable.CountX;
          if GetFullDim(cU[0].Dim) <> nn then cU[0].Dim:=SetDim([nn]);
      end
    else
      Result:=inherited InfoFunc(Action,aParameter);
  end;
end;
//--------------------------------------------------------------------------
function    TInterpolBlockMultiDim.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
 var
    i,j: integer;
begin
  Result := r_Success;
  case Action of
    f_InitObjects:
      begin
        if not LoadData then begin
          Result:=r_Fail;
          exit;
          end;

          //Подчитываем к-во точек по размерности входа
        tmpXp.ChangeCount(GetFullDim(cU[0].Dim) div Xtable.CountX,Xtable.CountX);

        //Инициализируем временные массивы
        u_.Count  := Xtable.CountX;
        v_.Count  := 1 shl (Xtable.CountX);
        ad_.Count := 1 shl (Xtable.CountX);
        k_.Count  := Xtable.CountX;
      end;

    f_RestoreOuts,
    f_InitState,
    f_UpdateOuts,
    f_UpdateJacoby,
    f_GoodStep:
      begin
        j:=0;
        // копируем аргумент из входного вектора U во временное хранилище
        for i := 0 to tmpXp.CountX - 1 do begin
          Move(U[0].Arr^[j],tmpXp[i].Arr^[0],tmpXp[i].Count*SizeOfDouble);
          inc(j,tmpXp[i].Count);
        end;


        case InterpolationType of
          1: nstep_interp(Xtable,Ftable,tmpXp,Y[0],ExtrapolationType,k_);
        else
          nlinear_interp(Xtable,Ftable,tmpXp,Y[0],ExtrapolationType,u_,v_,ad_,k_);
        end;

        end;
      end
end;
//--------------------------------------------------------------------------
function TInterpolBlockMultiDim.LoadData(): Boolean;
begin

  if inputMode=0 then
    Result := LoadDataFromProperties()
  else
    Result := LoadDataFromFile();
end;
//---------------------------------------------------------------------------
function TInterpolBlockMultiDim.LoadDataFromJSON(): Boolean;
var
  str1,str2: string;
  jso: TJSONObject;
  jsv: TJSONValue;
  jarr: TJSONArray;
  i,j,axisCount,jarrCount: Integer;
  arrValue: TJSONValue;

begin
  Result := True;
  jso := nil;

  try
    str1 := TFILE.ReadAllText(ExpandFileName(FileName));
    jso := TJSONObject.ParseJSONValue(str1) as TJSONObject;

    // подгружаем оси и размерности
    //axisCount := jso.GetValue<integer>('axisCount');
    axisCount:=0;
    for i:=0 to 10 do begin
      str2 := 'axis'+IntToStr(i+1);
      jarr := jso.GetValue(str2) as TJSONArray;
      if not Assigned(jarr) then break;

      inc(axisCount);
      end;

    Xtable.ChangeCountX(axisCount);
    for i:=0 to axisCount-1 do begin
      str2 := 'axis'+IntToStr(i+1);
      jarr := jso.GetValue(str2) as TJSONArray;
      jarrCount:=jarr.Count;
      Xtable[i].ChangeCount(jarrCount);

      for j := 0 to jarrCount - 1 do begin
        arrValue := jarr.Items[j];
        Xtable[i][j]:=StrToFloat(arrValue.AsType<string>);
        end;

      end;

    // подгружаем тело функции
    jsv := jso.GetValue('dataVolume');
    jarr := jsv as TJSONArray;
    jarrCount := jarr.Count;
    Ftable.ChangeCount(jarrCount);

    for j := 0 to jarrCount - 1 do begin
      arrValue := jarr.Items[j];
      Ftable[j]:=StrToFloat(arrValue.AsType<string>);
      end;

  except
    Result := False;
  end;

  if Assigned(jso) then FreeAndNil(jso);
end;

function TInterpolBlockMultiDim.LoadDataFromFile(): Boolean;
begin
  Result := LoadDataFromJSON();
end;
//---------------------------------------------------------------------------
function TInterpolBlockMultiDim.LoadDataFromProperties(): Boolean;
// загрузить данные из файлов в расчетные Xarg Fval
begin
  TExtArray_cpy(Ftable, prop_F);
  TExtArray2_cpy(Xtable,prop_X);
  Result := True;
end;
//---------------------------------------------------------------------------
function    TInterpolBlockMultiDim.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result<>-1 then exit;

  if StrEqu(ParamName,'outmode') then begin
    Result:=NativeInt(@ExtrapolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'method') then begin
    Result:=NativeInt(@InterpolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'x') then begin
    Result:=NativeInt(prop_X);
    DataType:=dtMatrix;
    exit;
    end;

  if StrEqu(ParamName,'values') then begin
    Result:=NativeInt(prop_F);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'inputMode') then begin
    Result:=NativeInt(@inputMode);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'FileName') then begin
    Result:=NativeInt(@FileName);
    DataType:=dtString;
    exit;
    end;

  ErrorEvent(txtParamUnknown1+ParamName+txtParamUnknown2, msWarning, VisualObject);
end;

end.
