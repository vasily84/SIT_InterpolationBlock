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
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, RealArrays_Utils;

type
/////////////////////////////////////////////////////////////////////////////
// блок интерполяции от одномерного аргумента
  TInterpolBlock1d = class(TRunObject)
  protected
    // ПЕРЕЧИСЛЕНИЕ откуда берем входные данные
    fInputMode: NativeInt;
    fExtrapolationType: NativeInt;   // ПЕРЕЧИСЛЕНИЕ тип экстраполяции за пределами определения функции - константа,ноль, интерполяция по крайним точкам
    fInterpolationType, //ПЕРЕЧИСЛЕНИЕ тип интерполяции
    fLagrangeOrder: NativeInt;  // порядок интерполяции для метода Лагранжа

    fProp_Xarr: TExtArray; // точки аргументов Xi функции, если она задана через свойства объекта
    fProp_Farr: TExtArray; // точки значений Fi функции, если она задана через свойства объекта

    fFileName: string; // имя единого входного файла
    fFileNameArgs: string; // имя входного файла для аргументов при раздельной загрузке
    fFileNameVals: string; // имя входного файла для значений функции при раздельной загрузке

    fIsNaturalSpline: Boolean;
    fSplineArr: TExtArray2;

    // последний найденный интервал интерполяции при вызове функции Interpol
    fLastInd: array of NativeInt;

    fXarr_data, fYarr_data: TExtArray; // точки аргументов Xi и значений Fi функции для расчета

    // Массивы иcходных данных - реально применяются только для отслеживания изменения входных данных
    fX_stamp,fY_stamp: TExtArray2;

    fDataLength: Integer;
    fDataOk: Boolean;
    function LoadDataFromProperties(): Boolean;
    function LoadDataFrom2Files(): Boolean;
    function LoadDataFromFile(): Boolean;
    function LoadDataFromPorts(): Boolean;
    function LoadDataFromJSON(): Boolean;

    function LoadData(): Boolean; // загрузить данные интерполируемой функции
    function CheckData(): Boolean; // проверить корректность входных данных

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
    fTable: TTable2;
    fFileName,fFileNameRows,fFileNameCols,fFileNameVals: string;
    fInterpolationType: NativeInt;
    fExtrapolationType: NativeInt;
    fInputMode: NativeInt;
    fProp_X1arr, fProp_X2arr: TExtArray;
    fProp_DataTable: TExtArray2;

    fDataLength: Integer;
    fDataOk: Boolean;
    // функции загрузки значений в table. Возвращает True при успешной загрузке
    function LoadDataFromPorts(): Boolean;
    function LoadDataFromProperties(): Boolean;
    function LoadDataFrom3Files():Boolean;
    function LoadDataFromTbl(): Boolean;
    function LoadDataFromJSON(): Boolean;

    function LoadData(): Boolean;
    // общая проверка размерностей введенных данных
    function CheckData(): Boolean;
    function checkXY_inRange(var aX1,aX2: RealType;var aZvalue: RealType): Boolean;

  public
    function InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor Create(Owner: TObject);override;
    destructor Destroy;override;
end;

/////////////////////////////////////////////////////////////////////
//Блок многомерной линейной интерполяции
type
  TInterpolBlockMultiDim = class(TRunObject)
  protected
   // это свойства
   fExtrapolationType: NativeInt; // ПЕРЕЧИСЛЕНИЕ тип экстраполяции при аргументе за пределами границ
   fInterpolationType: NativeInt; // ПЕРЕЧИСЛЕНИЕ метод интерполяции
   fInputMode: NativeInt; // ПЕРЕЧИСЛЕНИЕ метод задания функции
   fFileName: string;

   fProp_X: TExtArray2; // матрица аргументов по размерностям
   fProp_F: TExtArray;  // Вектор значений функции

   fXtable: TExtArray2; // матрица аргументов по размерностям
   fFtable: TExtArray;  // Вектор значений функции

   // это внутренние переменные
   ftempXp:         TExtArray2; // для Аргумента функции, считанного из входа U
   fU_,fV_:         TExtArray;
   fAd_,fK_:        TIntArray;

   fDataOk: Boolean; // данные корректны, их можно использовать для расчета
   fDataLength: Integer;// длина загруженных данных
   function LoadDataFromProperties(): Boolean;
   function LoadDataFromJSON(): Boolean;
   function LoadData(): Boolean;// загрузить и проверить корректность данных
   function CheckData(): Boolean;// общая проверка размерностей введенных данных

  public
   function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
   function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
   function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
   constructor    Create(Owner: TObject);override;
   destructor     Destroy;override;
 end;

 ///////////////////////////////////////////////////////////////////////
implementation

uses RealArrays{$IFNDEF FPC},JSON,IOUtils,Generics.Collections{$ELSE},fpJson,JsonParser{$ENDIF};

const
  // назначения входных портов для интерполяции на плоскости
  ROW_ARG = 0;
  COL_ARG = 1;
  ROW_ARGS_ARR = 2;
  COL_ARGS_ARR = 3;
  FUNCS_TABLE = 4;

const
{$IFNDEF ENG}
  txtFiXiDimError = 'Число значений F и аргументов X входной функции не совпадает';
  txtFileError1 = 'Файл ';
  txtFileError2 = ' невозможно считать';

  txtDimError = 'Некорректная размерность входных данных';

  txtXiduplicates = 'таблица значений функции содержит дубликаты аргумента';
  txtFuncTableReordered = 'таблица значений функции переупорядочена по возрастанию аргумента';

{$ELSE}
  txtFiXiDimError = 'The number of values of F and arguments X of the input function does not match';
  txtFileError1 = 'File ';
  txtFileError2 = ' reading failed';
  txtDimError = 'Input data dimension error';

  txtXiduplicates = 'The table of function values contains duplicate arguments';
  txtFuncTableReordered = 'the table of function values is reordered in ascending order of the argument';
{$ENDIF}

//===========================================================================

constructor TInterpolBlock1d.Create;
begin
  inherited;
  fProp_Xarr := TExtArray.Create(1); // точки аргументов Xi функции, если она задана через свойства объекта
  fProp_Farr:= TExtArray.Create(1); // точки значений Fi функции, если она задана через свойства объекта

  fSplineArr := TExtArray2.Create(1,1);
  fX_stamp := TExtArray2.Create(1,1);
  fY_stamp := TExtArray2.Create(1,1);

  fXarr_data := TExtArray.Create(1); // точки аргументов Xi функции, если она считана из файла
  fYarr_data := TExtArray.Create(1);
end;
//----------------------------------------------------------------------------
destructor  TInterpolBlock1d.Destroy;
begin
  FreeAndNil(fProp_Xarr);
  FreeAndNil(fProp_Farr);

  FreeAndNil(fSplineArr);
  FreeAndNil(fX_stamp);
  FreeAndNil(fY_stamp);

  FreeAndNil(fXarr_data);
  FreeAndNil(fYarr_data);

  if Assigned(fLastInd) then SetLength(fLastInd, 0);

  inherited;
end;
//---------------------------------------------------------------------------
function    TInterpolBlock1d.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

  // ПЕРЕЧИСЛЕНИЕ откуда берем входные данные
  if StrEqu(ParamName,'InputMode') then begin
    Result:=NativeInt(@fInputMode);
    DataType:=dtInteger;
    exit;
    end;

  // тип интерполяции - кусочно-постоянная, линейная, Лагранжа и т.п.
  if StrEqu(ParamName,'InterpolationType') then begin
    Result:=NativeInt(@fInterpolationType);
    DataType:=dtInteger;
    exit;
    end;

  // тип экстраполяции за пределами определения функции - константа, кусочно-постоянная и т.д.
  if StrEqu(ParamName,'ExtrapolationType') then begin
    Result:=NativeInt(@fExtrapolationType);
    DataType:=dtInteger;
    exit;
    end;

  // порядок интерполяции для метода Лагранжа
  if StrEqu(ParamName,'LagrangeOrder') then begin
    Result:=NativeInt(@fLagrangeOrder);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'FileName') then begin
    Result:=NativeInt(@fFileName);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'X_arr') then begin
    Result:=NativeInt(fProp_Xarr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'F_arr') then begin
    Result:=NativeInt(fProp_Farr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'FileNameArgs') then begin
    Result:=NativeInt(@fFileNameArgs);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'FileNameVals') then begin
    Result:=NativeInt(@fFileNameVals);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'IsNaturalSpline') then begin
    Result:=NativeInt(@fIsNaturalSpline);
    DataType:=dtBool;
    exit;
    end;

end;

//---------------------------------------------------------------------------
function TInterpolBlock1d.LoadDataFromProperties(): Boolean;
begin
  // копируем
  TExtArray_cpy(fXarr_data, fProp_Xarr);
  TExtArray_cpy(fYarr_data, fProp_Farr);
  fDataLength := fYarr_data.Count;
  Result := True;
end;
//---------------------------------------------------------------------------
function TInterpolBlock1d.LoadDataFrom2Files(): Boolean;
begin
  if not Load_TExtArray_FromFile(fFileNameArgs, fXarr_data) then begin
    ErrorEvent(txtFileError1+fFileNameArgs+txtFileError2, msError, VisualObject);
    exit(False);
    end;

  if not Load_TExtArray_FromFile(fFileNameVals, fYarr_data)then begin
    ErrorEvent(txtFileError1+fFileNameVals+txtFileError2, msError, VisualObject);
    exit(False);
    end;

  fDataLength:=fYarr_data.Count;
  Result := True;
end;
//----------------------------------------------------------------------

function TInterpolBlock1d.LoadDataFromFile(): Boolean;
begin
  Result := Load_2TExtArrays_FromFile(fFileName,fXarr_data,fYarr_data);
end;

//============================================================================
// проверить корректность входных данных
function TInterpolBlock1d.CheckData(): Boolean;
begin
  Result := True;
  if fXarr_data.Count<>fYarr_data.Count then begin
    ErrorEvent(txtDimError, msError, VisualObject);
    Result := False;
    end;
end;
//---------------------------------------------------------------------------
function TInterpolBlock1d.LoadDataFromPorts(): Boolean;  // stub
begin
  Result := True;
  TExtArray_cpy(fXarr_data, U[1]);
  TExtArray_cpy(fYarr_data, U[2]);
  fDataLength:=fYarr_data.Count;
end;
//----------------------------------------------------------------------------
{$IFNDEF FPC}
function TInterpolBlock1d.LoadDataFromJSON(): Boolean;
var
  str1: string;
  jso: TJSONObject;
  jarr: TJSONArray;
  j,jarrCount: Integer;
begin
  Result := True;
  jso := nil;
  fDataLength := 0;
  try
    str1 := TFILE.ReadAllText(ExpandFileName(fFileName));
    jso := TJSONObject.ParseJSONValue(str1) as TJSONObject;

    // подгружаем ось Х
    jarr := jso.GetValue<TJSONArray>('axis1');
    jarrCount:=jarr.Count;
    fXarr_data.Count := jarrCount;

    for j := 0 to jarrCount - 1 do begin
      fXarr_data[j]:=jarr.Items[j].AsType<TJSONNumber>.AsDouble;
      end;

    // подгружаем тело функции
    jarr := jso.GetValue<TJSONArray>('dataVolume');
    jarrCount:=jarr.Count;
    fYarr_data.Count := jarrCount;
    fDataLength := jarrCount;
    for j := 0 to jarrCount - 1 do begin
      fYarr_data[j]:=jarr.Items[j].AsType<TJSONNumber>.AsDouble;
      end;

  except
    Result := False;
  end;

  if Assigned(jso) then FreeAndNil(jso);
end;
{$ELSE}
function TInterpolBlock1d.LoadDataFromJSON(): Boolean;
var
  jso: TJSONObject;
  jarr: TJSONArray;
  i,j,x1count,x2count,jarrCount: Integer;
  slist1:TStringList;
  str1:string;
begin
	Result:=True;
  fDataLength:=0;
  slist1:=TStringList.Create;
  slist1.LoadFromFile(ExpandFileName(fFileName));
  str1:=slist1.Text;
  FreeAndNil(slist1);

  jso := TJSONObject(GetJSON(str1));
  try
    // подгружаем ось Х
    jarr := jso.Arrays['axis1'];
    jarrCount:=jarr.Count;
    fXarr_data.Count := jarrCount;

    for j := 0 to jarrCount - 1 do begin
      fXarr_data[j]:=jarr.Floats[j];
      end;

    // читаем dataVolume
    jarr := jso.Arrays['dataVolume'];
    jarrCount:=jarr.Count;
    fFarr_data.Count := jarrCount;
    fDataLength:= jarrCount;

    for j := 0 to jarrCount - 1 do begin
      fFarr_data[j]:=jarr.Floats[j];
      end;

  except
    Result:=False;
  end;

	if Assigned(jso) then FreeAndNil(jso);
end;
{$ENDIF}
//---------------------------------------------------------------------------
function TInterpolBlock1d.LoadData(): Boolean;
begin
  fDataOk:=False;

  case fInputMode of
    0:
      Result := LoadDataFromProperties();
    1:
      Result := LoadDataFrom2Files();
    2:
      begin
        Result := LoadDataFromJSON();
        if not Result then Result := LoadDataFromFile();
        if not Result then begin
          ErrorEvent(txtFileError1+fFileName+txtFileError2, msError, VisualObject);
          exit;
          end;
      end;
    3:
      Result := LoadDataFromPorts();
    else begin
      Result := False;
      Assert(False,'TInterpolBlock1d метод задания функции не реализован');
      exit;
    end;
  end;

  if Result then Result:=CheckData();
  if Result then fDataOk:=True;


  // проверяем, есть ли в аргументах Х дубликаты
  if TExtArray_HasDuplicates(fXarr_data) then begin
    ErrorEvent(txtXiduplicates, msWarning, VisualObject);
    end;

  // TODO - сейчас с дубликатами дуркует.
  // проверяем, упорядочены ли точки. При необходимости - упорядочиваем
  if not TExtArray_IsOrdered(fXarr_data) then begin
    //ErrorEvent(txtFuncTableReordered, msWarning, VisualObject);
    TExtArray_Sort_XY_Arr(fXarr_data, fYarr_data);
    end;

end;
//===========================================================================
function    TInterpolBlock1d.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result := r_Success;

  case Action of
    i_GetCount: //Получить размерности входов\выходов
      begin
        if fInputMode=3 then begin // для случая задания функции через порты
          //cU[2].Dim := cU[1].Dim;
          if GetFullDim(cU[1].Dim)<GetFullDim(cU[2].Dim) then
              cU[2].Dim := cU[1].Dim
            else
              cU[1].Dim := cU[2].Dim
          end;

        // размерность выходного вектора всегда определена
        cY[0].Dim:=cU[0].Dim;
      end;
    else
      Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

//============================================================================
//точка начала построения полинома Л утанавливается принудительно рядом с инервалом интерполяции
//============================================================================
function WLagrange(var aPx,aPy :PExtArr;aX:RealType;aLagrOrder,aNumPoints:Integer):RealType;
//    px - МАССИВ ЗНАЧЕНИЙ АРГУМЕНТА
//    py - МАССИВ ЗНАЧЕНИЙ ФУНКЦИИ
//    X - АРГУМЕНТ
//    LagrOrder - ПОРЯДОК ПОЛИНОМА
//    NPoints - число точек в наборе
var
  Mshift: Integer;
  nXindex: NativeInt;
begin
  nXindex := aNumPoints-1;
  // смещение для вычисления полинома Л считаем по интервалу нахождения аргумента Х
  Find1(aX,aPx, aNumPoints,nXindex);
  Mshift := nXindex;

  // полином по точкам функции, не выходя за ее пределы
  // подробности см. реализации Lagrange
  if(Mshift+aLagrOrder)>=(aNumPoints-1) then begin
    Mshift:= aNumPoints-1- aLagrOrder;
    end;

  if (Mshift<1) then Mshift:=1;

  // вызываем старую функцию с уже правильным M
  Result := Lagrange(aPx^,aPy^,aX,aLagrOrder,Mshift);
end;
//=============================================================================

// оригинальная версия, проверенная временем. После Рефакторинга. Изменения в вызове Лагарнжа.
function   TInterpolBlock1d.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var
  uInd: Integer;
  px,py: PExtArr; // указатели на значения и аргументы интерполируемых функции,
  Yvalue: RealType;

function checkX_inRange(aX: RealType; var AYvalue: RealType):Boolean;
// проверить, что аргумент х находится внутри диапазона определения функции.
// возвращает - True - аргумент х находится внутри диапазона и экстраполяция не требуется.
// иначе - False, и изменяет AYValue на значение экстраполяции
begin
  if fExtrapolationType=2 then begin // экстраполировать границы для заданного метода
    exit(True);
    end;

  if aX<px[0] then begin
    case fExtrapolationType of
      0: // константа вне диапазона
          AYvalue := py[0]; // берем первое значение из таблицы значений

      1: // ноль вне диапазона
          AYvalue := 0;
      end;
    exit(False);
    end;

  if aX>px[fXarr_data.Count-1] then begin
    case fExtrapolationType of
      0: // константа вне диапазона
          AYvalue := py[fXarr_data.Count-1]; // берем последнее значение из таблицы значений

      1: // ноль вне диапазона
          AYvalue := 0;
      end;
    exit(False);
    end;
  // х внутри диапазона определения функции, экстраполяция не требуется
  Result := True;
end;
//------------------------------------------------------------------------
function  CheckChanges: Boolean;
// входной вектор был изменен?
// Это Признак для пересчета внутренних матриц функций интерполяции
var
  q: integer;
begin
  Result := False;
  // TODO!! переделать на 1 мерный массивы
  for q:=0 to fXarr_data.Count - 1 do // идем по данным, если видим неравенство - данные новые.
    if (fX_stamp[0].Arr^[q] <> px[q]) or (fY_stamp[0].Arr^[q] <> py[q]) then begin
      fX_stamp[0].Arr^[q] := px[q];
      fY_stamp[0].Arr^[q] := py[q];
      exit(True);
      end;
end;
//--------------------------------------------------------------------------
// -- начало самой RunFunc -------------------------------------------------
var
  nXindex: NativeInt;
begin
  Result := r_Success;

  case Action of
    f_InitState,
    f_InitObjects:
      begin
        if not LoadData() then begin
          exit(r_Fail);
          end;

        //Здесь устанавливаем нужные размерности вспомогательных таблиц и переменных
        SetLength(fLastInd,GetFullDim(cU[0].Dim));
        ZeroMemory(Pointer(fLastInd), GetFullDim(cU[0].Dim)*SizeOf(NativeInt));
        // TODO!! - выяснить минимально необходимую размерность аргументов.
        fSplineArr.ChangeCount(5, fXarr_data.Count);
        fX_stamp.ChangeCount(1, fXarr_data.Count);
        fY_stamp.ChangeCount(1, fYarr_data.Count);
      end;

    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep:
      begin
        if not fDataOk then begin
          exit(r_Fail);
          end;

        // U[0] - args - всегда значение аргумента X
        // устанавливаем указатели на считанные данные
        px := fXarr_data.Arr;
        py := fYarr_data.Arr;

    // пересчитываем матрицы при необходимости
    if CheckChanges or (Action = f_InitState) then begin
      case fInterpolationType of
         1:   // Линейная интерполяция
                LInterpCalc(px, py, fSplineArr.Arr, fXarr_data.Count );
         2:   //Вычисление натурального кубического сплайна
                NaturalSplineCalc(px, py, fSplineArr.Arr, fXarr_data.Count, fIsNaturalSpline );
        end;
      end;

    //
    for uInd:=0 to U[0].Count - 1 do begin
     if checkX_inRange(U[0].Arr^[uInd],Yvalue) then begin
       Y[0].arr^[uInd] := Yvalue;
       continue;
       end;

     case fInterpolationType of
       3:   // Лагранж
          Y[0].arr^[uInd] := WLagrange(px,py,U[0].arr^[uInd],fLagrangeOrder,fXarr_data.Count);

       2:   //Вычисление натурального кубического сплайна
          Y[0].arr^[uInd] := Interpol(U[0].Arr^[uInd], fSplineArr.Arr, 5, fLastInd[uInd] );

       1:   // Линейная интерполяция
          Y[0].arr^[uInd] := Interpol(U[0].Arr^[uInd], fSplineArr.Arr, 3, fLastInd[uInd]);

       0:     // кусочная интерполяция.
          begin
            // находим интервал значений для интерполяции
            nXindex := fXarr_data.Count-1;
            Find1(U[0].Arr^[uInd],px,fXarr_data.Count,nXindex);
            Y[0].arr^[uInd] := py[nXindex];
          end;
       else
          begin
            Assert(False,'TInterpolBlock1d метод задания интерполяции не реализован');
            exit(r_Fail);
          end;
       end;
      end;
    end;
  end;
end;

/////////////////////////////////////////////////////////////////////////////
//****************************************************************************
//            Двумерная линейная интерполяция по таблице
//****************************************************************************
constructor TInterpolBlockXY.Create;
begin
  inherited;
  fTable:=TTable2.Create('');
  fInterpolationType:=0;
  fProp_X1arr:= TExtArray.Create(1);
  fProp_X2arr:= TExtArray.Create(1);
  fProp_DataTable:= TExtArray2.Create(1,1);
end;

destructor TInterpolBlockXY.Destroy;
begin
  FreeAndNil(fTable);
  FreeAndNil(fProp_X1arr);
  FreeAndNil(fProp_X2arr);
  FreeAndNil(fProp_DataTable);
  inherited;
end;
//---------------------------------------------------------------------------
function TInterpolBlockXY.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

  if StrEqu(ParamName,'Row_arr') then begin
    Result:=NativeInt(fProp_X1arr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'Col_arr') then begin
    Result:=NativeInt(fProp_X2arr);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'DataMatrix') then begin
    Result:=NativeInt(fProp_DataTable);
    DataType:=dtMatrix;
    exit;
    end;

  if StrEqu(ParamName,'interp_method') then begin
    Result:=NativeInt(@fInterpolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'extrType') then begin
    Result:=NativeInt(@fExtrapolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'inputType') then begin
    Result:=NativeInt(@fInputMode);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'filename') then begin
    Result:=NativeInt(@fFileName);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'fileNameRows') then begin
    Result:=NativeInt(@fFileNameRows);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'fileNameCols') then begin
    Result:=NativeInt(@fFileNameCols);
    DataType:=dtString;
    exit;
    end;

  if StrEqu(ParamName,'fileNameVals') then begin
    Result:=NativeInt(@fFileNameVals);
    DataType:=dtString;
    exit;
    end;

end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.checkXY_inRange(var aX1,aX2: RealType;var aZvalue: RealType): Boolean;
// проверить, что аргументы aX и aY находится внутри диапазона определения функции.
// возвращает - True - аргументы находится внутри диапазона и экстраполяция не требуется.
// иначе - False, и изменяет AYValue на значение экстраполяции
var
  // признаки нахождения аргументов в границах диапазонов
  x1_inRange,x2_inRange: Boolean;
begin

  if fExtrapolationType=2 then begin // экстраполировать границы для заданного метода
    exit(True);
    end;

  x1_inRange := ((aX1>=fTable.px1[0])and(aX1<=fTable.px1[fTable.Arg1Count-1]));
  x2_inRange := ((aX2>=fTable.px2[0])and(aX2<=fTable.px2[fTable.Arg2Count-1]));

  if (x1_inRange and x2_inRange) then begin //в диапазоне, экстраполяция не требуется
    exit(True);
    end;

  // за пределами диапазона, тип экстраполяции - ноль за пределами диапазона
  if fExtrapolationType=1 then begin
    aZvalue := 0;
    exit(False);
    end;

  // кусочно-постоянная интерполяция
  Result:=False;
  // подставляем результат интервальной интерполяции
  aZvalue := fTable.GetFunValueWithoutInterpolation(aX1,aX2);
  // либо использовать
  // table.GetFunValueWithoutExtrapolation
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadDataFromPorts(): Boolean;
var
  i,j,M,N: Integer;
  f: RealType;
begin
  fDataLength:=0;

  N := U[ROW_ARGS_ARR].Count;
  M := U[COL_ARGS_ARR].Count;

  fTable.Arg1Count := N;
  fTable.Arg2Count := M;

  TExtArray_cpy(fTable.px1, U[ROW_ARGS_ARR]);
  TExtArray_cpy(fTable.px2, U[COL_ARGS_ARR]);

  fTable.py.ChangeCount(N,M);

  if (M*N<>U[FUNCS_TABLE].Count) then begin
    exit(False);
    end;

  for i:=0 to N-1 do begin
    for j:=0 to M-1 do begin
      f := U[FUNCS_TABLE].Arr[fDataLength];
      Inc(fDataLength);
      fTable.py[i][j]:=f;
      end;
    end;

  Result := True;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadDataFromProperties(): Boolean;
begin
  fTable.Arg1Count := fProp_X1arr.Count;
  fTable.Arg2Count := fProp_X2arr.Count;

  TExtArray_cpy(fTable.px1, fProp_X1arr);
  TExtArray_cpy(fTable.px2, fProp_X2arr);
  TExtArray2_cpy(fTable.py, fProp_DataTable);

  fDataLength := fTable.py.CountX*fTable.py.GetMaxCountY;
  Result := True;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadDataFrom3Files(): Boolean;
begin
  fDataLength:=0;

  //rows
  if not Load_TExtArray_FromFile(fFileNameRows,fTable.px1) then begin
    ErrorEvent(txtFileError1+fFileNameRows+txtFileError2,msError,VisualObject);
    exit(False);
    end;
  fTable.Arg1Count:=fTable.px1.Count;

  // cols
  if not Load_TExtArray_FromFile(fFileNameCols,fTable.px2) then begin
    ErrorEvent(txtFileError1+fFileNameCols+txtFileError2,msError,VisualObject);
    exit(False);
    end;
  fTable.Arg2Count:=fTable.px2.Count;

  // vars
  if not Load_TExtArray2_FromCsvFile(fFileNameVals,fTable.py) then begin
    ErrorEvent(txtFileError1+fFileNameVals+txtFileError2,msError,VisualObject);
    exit(False);
    end;

  // TODO!! добавить варианты чтения бинарника
  fDataLength:=fTable.py.CountX*fTable.py.GetMaxCountY;
  Result := True;
end;
//----------------------------------------------------------------------------
{$IFNDEF FPC}
function TInterpolBlockXY.LoadDataFromJson():Boolean;
var
  str1: string;
  jso: TJSONObject;
  jarr: TJSONArray;
  i,j,x1count,x2count,jarrCount: Integer;
begin
  Result := True;
  fDataLength:=0;
  jso := nil;

  try
    str1 := TFILE.ReadAllText(ExpandFileName(fFileName));
    jso := TJSONObject.ParseJSONValue(str1) as TJSONObject;

    // подгружаем ось Х1
    jarr := jso.GetValue<TJSONArray>('axis1');
    x1Count:=jarr.Count;
    fTable.Arg1Count := x1Count;

    for j := 0 to x1Count - 1 do begin
      fTable.px1[j]:=jarr.Items[j].AsType<TJSONNumber>.AsDouble;
      end;

    // подгружаем ось Х2
    jarr := jso.GetValue<TJSONArray>('axis2');
    x2Count:=jarr.Count;
    fTable.Arg2Count := x2Count;

    for j := 0 to x2Count - 1 do begin
      fTable.px2[j]:=jarr.Items[j].AsType<TJSONNumber>.AsDouble;
      end;

    // подгружаем тело функции
    jarr := jso.GetValue<TJSONArray>('dataVolume');
    jarrCount := jarr.Count;

    x1Count := fTable.px1.Count;
    x2Count := fTable.px2.Count;

    if (jarrCount<x1Count*x2Count) then begin // недостаточно данных в файле
        Result:=False;
        end;

    fTable.py.ChangeCount(x1Count,x2Count);
    fDataLength:=0;

    for i:=0 to x1count-1 do
    for j := 0 to x2count-1 do begin
      fTable.py[i][j]:=jarr.Items[fDataLength].AsType<TJSONNumber>.AsDouble;
      inc(fDataLength);
      end;
  except
    Result := False;
  end;

  if Assigned(jso) then FreeAndNil(jso);
end;
{$ELSE}
function TInterpolBlockXY.LoadDataFromJson():Boolean;
var
  jso: TJSONObject;
  jarr: TJSONArray;
  i,j,x1count,x2count,jarrCount: Integer;
  slist1:TStringList;
  str1:string;
begin
	Result:=True;
  fDataLength:=0;
  slist1:=TStringList.Create;
  slist1.LoadFromFile(ExpandFileName(fFileName));
  str1:=slist1.Text;
  FreeAndNil(slist1);

  jso := TJSONObject(GetJSON(str1));
  try
    // подгружаем ось Х1
    jarr := jso.Arrays['axis1'];
    x1Count:=jarr.Count;
    fTable.Arg1Count := x1Count;

    for j := 0 to x1Count - 1 do begin
      fTable.px1[j]:=jarr.Floats[j];
      end;

    // подгружаем ось Х2
    jarr := jso.Arrays['axis2'];
    x2Count:=jarr.Count;
    fTable.Arg2Count := x2Count;

    for j := 0 to x2Count - 1 do begin
      fTable.px2[j]:=jarr.Floats[j];
      end;

    // читаем dataVolume
    fTable.py.ChangeCount(x1Count,x2Count);
    fDataLength:=0;

    jarr:=jso.Arrays['dataVolume'];

    for i:=0 to x1count-1 do
    for j := 0 to x2count-1 do begin
      fTable.py[i][j]:=jarr.Floats[fDataLength];
      inc(fDataLength);
      end;
  except
    Result:=False;
  end;

	if Assigned(jso) then FreeAndNil(jso);
end;
{$ENDIF}
//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadDataFromTbl(): Boolean;
begin
  //Загрузка данных из файла с таблицей
  fDataLength := 0;
  Result:=True;
  fTable.OpenFromFile(fFileName);
  if (fTable.px1.Count = 0) or (fTable.px2.Count = 0) then begin
    //ErrorEvent(txtErrorReadTable,msError,VisualObject);
    exit(False);
    end;

  fDataLength:=fTable.py.CountX*fTable.py.GetMaxCountY;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.LoadData(): Boolean;
begin
  fDataOk:=False;
  case fInputMode of
    0:// ввести вручную через свойства
      Result:=LoadDataFromProperties();
    1:// в разных файлах
      Result:=LoadDataFrom3Files();
    2:// в одном файле
      begin
        Result:=LoadDataFromJSON();

        if not Result then Result:=LoadDataFromTbl();
        if not Result then begin
          ErrorEvent(txtFileError1+fFileName+txtFileError2,msError,VisualObject);
          exit(False);
          end;
      end;
    3:// через порты
      Result:=LoadDataFromPorts();
    else
      Assert(False,'TInterpolBlockXY метод задания функции не реализован');
      exit(False);
    end;

  if Result then Result:=CheckData();
  if Result then fDataOk:=True;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.CheckData(): Boolean;
begin
  Result := (fTable.px1.Count*fTable.px2.Count=fDataLength);
  if not Result then begin
    ErrorEvent(txtDimError,msError,VisualObject);
    exit(False);
    end;
end;
//----------------------------------------------------------------------------
function TInterpolBlockXY.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
var
  M,N,T: Integer;
begin
  Result:=r_Success;
  case Action of
    i_GetCount:
          begin
          // устанавливает одинаковые количества rows cols
          if Length(cU) > 1 then begin  // TODO проверить, должно быть установление меньшего?
              if GetFullDim( cU[1].Dim ) > GetFullDim( cU[0].Dim ) then
                 cU[0].Dim:=cU[1].Dim
              else
                 cU[1].Dim:=cU[0].Dim;
             cY[0].Dim:=cU[0].Dim;
            end;

          // при задании через порты проверяем их размерность
          if Length(cU) > FUNCS_TABLE  then begin
            N := GetFullDim(cU[ROW_ARGS_ARR].Dim);
            M := GetFullDim(cU[COL_ARGS_ARR].Dim);
            T := GetFullDim(cU[FUNCS_TABLE].Dim);

            if(M*N<>T) then begin
              ErrorEvent(txtDimError, msError, VisualObject);
              exit(r_Fail);
              end;

            end;
          end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

//----------------------------------------------------------------------------
function TInterpolBlockXY.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
 var
 uInd: integer;
 Yval: RealType;
begin
  Result:=r_Success;

  case Action of
    f_InitObjects,
    f_InitState:  // можно сделать общую загрузку и проверки для режимов файла
      begin
       //Загрузка данных из файла с таблицей или портов
       if not LoadData() then begin
         exit(r_Fail);
        end;
      end;

    f_UpdateJacoby,
    f_UpdateOuts,
    f_RestoreOuts,
    f_GoodStep:
      begin
        if not fDataOk then begin
          exit(r_Fail);
          end;


        for uInd:=0 to U[0].Count - 1 do begin

        if not checkXY_inRange(U[0].Arr^[uInd],U[1].Arr^[uInd],Yval) then begin
          Y[0].Arr^[uInd]:=Yval;
          continue;
          end;

        case fInterpolationType of
            0:  // линейная
              Y[0].Arr^[uInd]:=fTable.GetFunValue(U[0].Arr^[uInd],U[1].Arr^[uInd]);

            1:  // кусочно-постоянная
              Y[0].Arr^[uInd]:=fTable.GetFunValueWithoutInterpolation(U[0].Arr^[uInd],U[1].Arr^[uInd]);

            2: // сплайны
              Y[0].Arr^[uInd]:=fTable.GetFunValueBySplineInterpolation(U[0].Arr^[uInd],U[1].Arr^[uInd]);

            3: // Акима
              Y[0].Arr^[uInd]:=fTable.GetFunValueByAkimaInterpolation(U[0].Arr^[uInd],U[1].Arr^[uInd]);

          else
            Assert(False,'TInterpolBlockXY метод интерполяции не реализован');
        end;
        end;
      end;

  end
end;
//--------------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////////

constructor  TInterpolBlockMultiDim.Create;
begin
  inherited;
  IsLinearBlock:=True;
  fInterpolationType:=0;
  fExtrapolationType:=0;

  ftempXp:=TExtArray2.Create(1,1);
  // аргументы и значения функции для вычислений.
  // Могут быть получены - 1. из свойств объекта 2. загружены из файла
  fXtable:=TExtArray2.Create(1,1);
  fFtable:=TExtArray.Create(1);

  // свойства объекта - аргументы и значения функции
  fProp_X:=TExtArray2.Create(1,1);
  fProp_F:=TExtArray.Create(1);

  // внутренние переменные для функции интерполяции
  fU_:=TExtArray.Create(1);
  fV_:=TExtArray.Create(1);
  fAd_:=TIntArray.Create(1);
  fK_:=TIntArray.Create(1);
end;

destructor   TInterpolBlockMultiDim.Destroy;
begin
  FreeAndNil(ftempXp);
  FreeAndNil(fXtable);
  FreeAndNil(fFtable);
  FreeAndNil(fProp_X);
  FreeAndNil(fProp_F);
  FreeAndNil(fU_);
  FreeAndNil(fV_);
  FreeAndNil(fAd_);
  FreeAndNil(fK_);
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
        if not LoadData() then begin
              exit(r_Fail);
              end;

        if fXtable.CountX <= 0 then begin
          ErrorEvent(txtDimensionsNotDefined,msError,VisualObject);
          exit(r_Fail);
          end;

        //Вычисляем суммарную размерность
        p:=fXtable[0].Count;
        for i := 1 to fXtable.CountX - 1 do p:=p*fXtable[i].Count;

        //Проверяем всё ли задано в массиве val_
        if fFtable.Count > 0 then begin
          if fFtable.Count < p then begin
             ErrorEvent(txtOrdinatesDefineIncomplete+IntToStr(p),msWarning,VisualObject);
             exit(r_Fail);
             end;
          end;
      end;

    i_GetCount:
      begin
        if not LoadData() then begin
          exit(r_Fail);
          end;

          //Размерность выхода = размерность входа делённая на размерность матрицы абсцисс
          cY[0].Dim:= SetDim([ GetFullDim(cU[0].Dim) div fXtable.CountX ]);
          //Условие кратности рзмерности
          nn := cY[0].Dim[0]*fXtable.CountX;
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
        if not LoadData() then begin
          exit(r_Fail);
          end;

          //Подчитываем к-во точек по размерности входа
        ftempXp.ChangeCount(GetFullDim(cU[0].Dim) div fXtable.CountX,fXtable.CountX);

        //Инициализируем временные массивы
        fU_.Count  := fXtable.CountX;
        fV_.Count  := 1 shl (fXtable.CountX);
        fAd_.Count := 1 shl (fXtable.CountX);
        fK_.Count  := fXtable.CountX;
      end;

    f_InitState:
      begin
      if not CheckData() then begin
          exit(r_Fail);
          end;
      end;

    f_RestoreOuts,
    f_UpdateOuts,
    f_UpdateJacoby,
    f_GoodStep:
      begin

        if not fDataOk then begin
          exit(r_Fail);
          end;

        j:=0;
        // копируем аргумент из входного вектора U во временное хранилище
        for i := 0 to ftempXp.CountX - 1 do begin
          Move(U[0].Arr^[j],ftempXp[i].Arr^[0],ftempXp[i].Count*SizeOfDouble);
          inc(j,ftempXp[i].Count);
          end;


        case fInterpolationType of
          1: nstep_interp(fXtable,fFtable,ftempXp,Y[0],fExtrapolationType,fK_);
        else
          nlinear_interp(fXtable,fFtable,ftempXp,Y[0],fExtrapolationType,fU_,fV_,fAd_,fK_);
        end;

        end;
      end
end;
//--------------------------------------------------------------------------
function TInterpolBlockMultiDim.LoadData(): Boolean;
begin
  fDataOk:=False;

  case fInputMode of
  0:
    Result := LoadDataFromProperties();
  1:
   begin
    Result := LoadDataFromJSON();
    if not Result then begin
      ErrorEvent(txtFileError1+fFileName+txtFileError2, msError, VisualObject);
      exit(False);
      end;
    end
   else
    begin
      Assert(False,'TInterpolBlockMultiDim метод задания многомерной функции не реализован');
      exit(False);
    end;
  end;

  if Result then Result:=CheckData();
  if Result then fDataOk:=True; // данные корректно загружены
end;
//---------------------------------------------------------------------------
function TInterpolBlockMultiDim.CheckData(): Boolean;
var
  i: Integer;
  Volume: Integer;
begin
  Result:=True;

  Volume := 1;
  for i:=0 to fXtable.CountX-1 do begin
    Volume := Volume*fXtable[i].Count;
    end;

  if (fDataLength<>Volume) then begin
    ErrorEvent(txtDimError, msError, VisualObject);
    exit(False);
    end;

end;
//---------------------------------------------------------------------------
{$IFNDEF FPC}
function TInterpolBlockMultiDim.LoadDataFromJSON(): Boolean;
var
  str1,str2: string;
  jso: TJSONObject;
  jsv: TJSONValue;
  jarr: TJSONArray;
  i,j,axisCount,jarrCount: Integer;

begin
  Result := True;
  jso := nil;
  fDataLength:=0;

  try
    str1 := TFILE.ReadAllText(ExpandFileName(fFileName));
    jso := TJSONObject.ParseJSONValue(str1) as TJSONObject;

    // подгружаем оси
    axisCount:=0;
    for i:=0 to 10 do begin
      str2 := 'axis'+IntToStr(i+1);
      try
          jarr := jso.GetValue<TJSONArray>(str2);
        except
          jarr:=nil;
        end;
      if not Assigned(jarr) then break;

      inc(axisCount);
      end;

    fXtable.ChangeCountX(axisCount);
    for i:=0 to axisCount-1 do begin
      str2 := 'axis'+IntToStr(i+1);
      jarr := jso.GetValue<TJSONArray>(str2);
      jarrCount:=jarr.Count;
      fXtable[i].ChangeCount(jarrCount);

      for j := 0 to jarrCount - 1 do begin
        fXtable[i][j]:=jarr.Items[j].AsType<TJSONNumber>.AsDouble;
        end;

      end;

    // подгружаем тело функции
    jsv := jso.GetValue('dataVolume');
    jarr := jsv as TJSONArray;
    jarrCount := jarr.Count;
    fFtable.ChangeCount(jarrCount);

    for j := 0 to jarrCount - 1 do begin
      fFtable[j]:=jarr.Items[j].AsType<TJSONNumber>.AsDouble;
      inc(fDataLength);
      end;

  except
    Result := False;
  end;

  if Assigned(jso) then FreeAndNil(jso);
end;
{$ELSE}
function TInterpolBlockMultiDim.LoadDataFromJSON(): Boolean;
var
  jso: TJSONObject;
  jarr: TJSONArray;
  i,j,axisCount,jarrCount: Integer;
  slist1:TStringList;
  str1,str2:string;
begin
	Result:=True;
  DataLength:=0;
  slist1:=TStringList.Create;
  slist1.LoadFromFile(ExpandFileName(fFileName));
  str1:=slist1.Text;
  FreeAndNil(slist1);

  jso := TJSONObject(GetJSON(str1));
  try
    // подсчитываем количество осей
    axisCount:=0;
    for i:=0 to 10 do begin
      str2 := 'axis'+IntToStr(i+1);
      try
          jarr := jso.Arrays[str2];
        except
          jarr:=nil;
        end;
      if not Assigned(jarr) then break;
      inc(axisCount);
      end;
    fXtable.ChangeCountX(axisCount);

    // читаем оси
    for i:=0 to axisCount-1 do begin
      str2:='axis'+IntToStr(i+1);
      jarr := jso.Arrays[str2];
      jarrCount:=jarr.Count;
      fXtable[i].ChangeCount(jarrCount);

      for j := 0 to jarrCount - 1 do begin
        fXtable[i][j]:=jarr.Floats[j];
    	  end;
      end;

    // читаем dataVolume
    str2:='dataVolume';
    jarr:=jso.Arrays[str2];

    jarrCount := jarr.Count;
    fFtable.ChangeCount(jarrCount);

    for j := 0 to jarrCount - 1 do begin
      fFtable[j]:=jarr.Floats[j];
      inc(DataLength);
      end;
  except
    Result:=False;
  end;

	if Assigned(jso) then FreeAndNil(jso);
end;
{$ENDIF}

//---------------------------------------------------------------------------
function TInterpolBlockMultiDim.LoadDataFromProperties(): Boolean;
begin
  TExtArray2_cpy(fXtable,fProp_X);
  TExtArray_cpy(fFtable, fProp_F);
  fDataLength := fProp_F.Count;
  Result := True;
end;
//---------------------------------------------------------------------------
function    TInterpolBlockMultiDim.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result<>-1 then exit;

  if StrEqu(ParamName,'outmode') then begin
    Result:=NativeInt(@fExtrapolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'method') then begin
    Result:=NativeInt(@fInterpolationType);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'x') then begin
    Result:=NativeInt(fProp_X);
    DataType:=dtMatrix;
    exit;
    end;

  if StrEqu(ParamName,'values') then begin
    Result:=NativeInt(fProp_F);
    DataType:=dtDoubleArray;
    exit;
    end;

  if StrEqu(ParamName,'inputMode') then begin
    Result:=NativeInt(@fInputMode);
    DataType:=dtInteger;
    exit;
    end;

  if StrEqu(ParamName,'FileName') then begin
    Result:=NativeInt(@fFileName);
    DataType:=dtString;
    exit;
    end;

end;

end.
