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
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath, InterpolationBlocks_unit,InterpolationBlocks_unit_tests;


type
/////////////////////////////////////////////////////////////////////////////
// блок интерполяции по ТЗ от 3 февраля 2025, от одномерного аргумента
  TInterpolationBlock1 = class(TRunObject)
  protected
    Func: TFndimFunctionByPoints1d; // хранилище наших точек функции

    InputsMode: NativeInt; // ПЕРЕЧИСЛЕНИЕ откуда берем входные данные
    Fdim: NativeInt;                // размерность выходного вектора функции
    //InterpolationType: NativeInt;   // ПЕРЕЧИСЛЕНИЕ тип интерполяции - кусочно-постоянная, линейная, Лагранжа и т.п.
    ExtrapolationType: NativeInt;   // ПЕРЕЧИСЛЕНИЕ тип экстраполяции за пределами определения функции - константа,ноль, интерполяция по крайним точкам
    //LagrangeOrder: NativeInt; // порядок интерполяции для метода Лагранжа
    FileName: string; // имя единого входного файла
    FileNameArgsX: string; // имя входного файла для аргументов при раздельной загрузке
    FileNameFuncTable: string; // имя входного файла для значений функции при раздельной загрузке

    property_Xi_array: TExtArray; // точки аргументов Xi функции, если она задана через свойства объекта
    property_Fi_array: TExtArray; // точки значений Fi функции, если она задана через свойства объекта


    InterpolationType,                       //Переменные, доступные извне
    LagrangeOrder,
    Npoints, // число точек функции
    M_LagrangeShift,
    Nfun:          NativeInt; // размерность выходного вектора функции
    SplineIsNatural:Boolean;
    SplineArr:     TExtArray2;
    Ind:           array of NativeInt;

    x_tab:         TExtArray2; //Массивы изходных данных
    y_tab:         TExtArray2;

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
  Func := TFndimFunctionByPoints1d.Create;

  //TFndimFunctionByPoints1d_testAll('e:\USERDISK\SIM_WORK\БЛОКИ_ИНТЕРПОЛЯЦИИ\InterpolationBlocks_autoTestLog.txt');
end;

destructor  TInterpolationBlock1.Destroy;
begin
  FreeAndNil(property_Xi_array);
  FreeAndNil(property_Fi_array);
  FreeAndNil(Func);
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

  Func.ClearPoints();
  Func.beginPoints;
    for i:=0 to property_Xi_array.Count-1 do begin // идем по входному вектору и добавляем точки в функцию.
      Xp := property_Xi_array.Arr[i];

      for j:=0 to Fdim-1 do begin
        Func.Fval1[j] := property_Fi_array.Arr[i*Fdim+j];
        end;
      Func.addPoint(Xp,PDouble(Func.Fval1));
      end;
  Func.endPoints;

end;

function TInterpolationBlock1.LoadFuncFromFilesXiFi(): Boolean;
label
  OnExit;
var
  tableX,tableF: TTable1;
  i,j: Integer;
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
    ErrorEvent('Размерность функции из файла = '+IntToStr((1+tableF.FunsCount))+' и свойства Fdim= '+IntToStr(Fdim)+' не совпадает',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  Func.ClearPoints();
  Func.beginPoints;

  // идем по входному вектору и добавляем точки в функцию.
    for i:=0 to tableX.px.count-1 do begin
      Xp := tableX.px[i];
      // TODO переделать - дурацкий метод, но работает
      Func.Fval1[0] := tableF.px[i]; // первая точка - из первого столбца аргументов
      for j:=0 to tableF.FunsCount-1 do begin // остаьные точки - из ветора значений
        Func.Fval1[j+1] := tableF.py.Arr[j][i]
        end;

      Func.addPoint(Xp,PDouble(Func.Fval1));
      end;
  Func.endPoints;

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
  i,j: Integer;
  Xp: Double;

begin
  Result := True;
  table1 := TTable1.Create(FileName);
  if not table1.OpenFromFile(FileName) then begin
    ErrorEvent('Файл '+FileName+' невозможно считать',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  if (Fdim <> table1.FunsCount) then begin
    ErrorEvent('Размерность функции из файла = '+IntToStr((table1.FunsCount))+' и свойства Fdim= '+IntToStr(Fdim)+' не совпадает',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  Func.ClearPoints();
  Func.beginPoints;

    for i:=0 to table1.px.count-1 do begin // идем по входному вектору и добавляем точки в функцию.
      Xp := table1.px[i];

      for j:=0 to table1.FunsCount-1 do begin
        Func.Fval1[j] := table1.py.Arr[j][i]
        end;

      Func.addPoint(Xp,PDouble(Func.Fval1));
      end;
  Func.endPoints;

OnExit:
  FreeAndNil(table1);
end;

function TInterpolationBlock1.LoadFuncFromPorts(): Boolean;
var
  i,j: Integer;
  Xp: Double;
begin
  Result := True;
  // 0. проверяем размерности входных портов
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

  Func.ClearPoints();
  Func.beginPoints;
    for i:=0 to U[1].Count-1 do begin // идем по входному вектору и добавляем точки в функцию.
      Xp := U[1][i];
      for j:=0 to Fdim-1 do begin
        Func.Fval1[j] := U[2][i*Fdim+j];
        end;
      Func.addPoint(Xp,PDouble(Func.Fval1));
      end;
  Func.endPoints;

end;

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

end;

{
function   TInterpolationBlock1.RunFunc(var at,h : RealType; Action:Integer):NativeInt;
var
    j,k : Integer;
    Xarg: Double;
begin
  Result := r_Success;

  case Action of
    f_InitState:
              begin
                //------------------------------------------------------------
                // 1. инициализируем наш набор точек ЗАНОВО
                if not LoadFunc() then begin
                  Result := r_Fail;
                  exit;
                  end;

                Func.ExtrapolationType := ExtrapolationType;
                Func.LagrangeOrder := LagrangeOrder;

                if Func.LagrangeOrder>Func.pointsCount then begin
                  Func.LagrangeOrder := Func.pointsCount;
                  end;

              end;

    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep:
              begin
                ///////////////////////////////////////////////////////////////
                // порядок действий -
                // 1.Считаем, что все успешно инициализированно в f_InitState
                // 2. определяем из входа аргумент X
                // 3. делаем необходимый вызов интерполяции
                // 4. формируем и возвращаем вектор-ответ

                //------------------------------------------------------------
                // 1. - TODO - Считаем, что все успешно инициализированно в f_InitState
                // 2. определяем из входа аргумент X
                for k:=0 to U[0].Count-1 do begin
                  Xarg := U[0][k];

                  // 3. делаем необходимый вызов интерполяции
                  case InterpolationType of
                    0:
                      begin
                        Func.IntervalInterpolation(Xarg, PDouble(Func.Fval1));
                      end;
                    1:
                      begin
                        Func.LinearInterpolation(Xarg, PDouble(Func.Fval1));
                      end;
                    2:
                      begin
                        Func.SplineInterpolation(Xarg, PDouble(Func.Fval1));
                      end;
                    3:
                      begin
                        Func.LagrangeInterpolation(Xarg, PDouble(Func.Fval1));
                      end;

                    else
                      begin
                        ErrorEvent('Метод интерполяции функции '+IntToStr(InterpolationType)+' не реализован',msError,VisualObject);
                        Result := r_Fail;
                        exit;
                      end;
                  end;

                  // 4. формируем и возвращаем вектор-ответ
                  for j:=0 to Fdim-1 do begin
                    Y[0][k*Fdim+j] :=  Func.Fval1[j];
                    end;

                end;

                EXIT;   // работа выполнена!!!

                ///////////////////////////////////////////////////////////
              end;
  end;
end;

}
//===========================================================================
function    TInterpolationBlock1.InfoFunc;
begin
  Result:=0;
  case Action of
    i_GetCount:  begin
                   CU[0].Dim:=SetDim([Npoints]);
                   CU[1].Dim:=SetDim([Npoints*Nfun]);
                   CY[0].Dim:=SetDim([GetFullDim(CU[2].Dim)*Nfun]);
                 end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

// оригинальная версия, проверенная временем. После Рефакторинга.
function   TInterpolationBlock1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var
  i,j,c   : Integer;
  py      : PExtArr;
  px      : PExtArr;

function  IsNewData:boolean;
// входной вектор был изменен?
var
  j: integer;
begin
  Result := False;

  for j:=0 to Npoints - 1 do // идем по данным порта, если видим неравенство - данные новые.
    if (x_tab[i].Arr^[j] <> px[j]) or (y_tab[i].Arr^[j] <> py[j]) then begin
      x_tab[i].Arr^[j] := px[j];
      y_tab[i].Arr^[j] := py[j];
      Result:=True;
      end;
end;

begin
  Result:=0;
  case Action of
    f_InitObjects: begin
                     //Здесь устанавливаем нужные размерности вспомогательных
                     SetLength(Ind,GetFullDim(cU[2].Dim));
                     ZeroMemory(Pointer(Ind), GetFullDim(cU[2].Dim)*SizeOf(NativeInt));
                     SplineArr.ChangeCount(5,Npoints);
                     x_tab.ChangeCount(Nfun,Npoints);
                     y_tab.ChangeCount(Nfun,Npoints);
                   end;
    f_InitState,
    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep: begin
                  // U[0] - args - значение аргумента X
                  // U[1] - args_arr - массив заданных значений аргумента
                  // U[2] - func_table - матрица значений функции
                  px := U[1].Arr;
                  py := U[2].Arr;
                  c := 0;

                  for i:=0 to Nfun - 1 do begin
                   case InterpolationType of

                     0: begin // Лагранж
                          for j:=0 to U[0].Count - 1 do begin
                            Y[0].arr^[i*U[0].Count+j] := Lagrange(px^,py^,U[0].arr^[j],LagrangeOrder,M_LagrangeShift);
                            inc(c);
                            end;
                        end;

                     1: begin //Вычисление натурального кубического сплайна
                          if IsNewData or (Action = f_InitState) then begin
                            NaturalSplineCalc(px, py, SplineArr.Arr, Npoints, SplineIsNatural );
                            end;

                          for j:=0 to U[0].Count-1 do begin
                            Y[0].arr^[c] := Interpol(U[0].Arr^[j], SplineArr.Arr, 5, Ind[j] );
                            inc(c);
                            end;
                        end;

                     2: begin // Линейная интерполяция
                          if IsNewData or (Action = f_InitState) then begin
                            LInterpCalc(px, py, SplineArr.Arr, Npoints );
                            end;

                          for j:=0 to U[0].Count-1 do begin
                            Y[0].arr^[c] := Interpol(U[0].Arr^[j], SplineArr.Arr, 3, Ind[j] );
                            inc(c);
                            end;
                        end;

                     end;

                   py:=@py^[Npoints];

		              end
                 end;
  end
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
end.
