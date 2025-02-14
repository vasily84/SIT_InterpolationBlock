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
// блок интерполяции по ТЗ от 3 февраля 2025, от одномерного аргумент
  TMyInterpolationBlock1 = class(TRunObject)
  protected
    Func: TFndimFunctionByPoints1d; // хранилище наших точек функции

    InputsMode: NativeInt; // ПЕРЕЧИСЛЕНИЕ откуда берем входные данные
    Fdim: NativeInt;                // размерность выходного вектора функции
    InterpolationType: NativeInt;   // ПЕРЕЧИСЛЕНИЕ тип интерполяции - кусочно-постоянная, линейная, Лагранжа и т.п.
    ExtrapolationType: NativeInt;   // ПЕРЕЧИСЛЕНИЕ тип экстраполяции за пределами определения функции - константа,ноль, интерполяция по крайним точкам
    LagrangeOrder: NativeInt; // порядок интерполяции для метода Лагранжа
    FileName: string; // имя единого входного файла
    FileNameArgsX: string; // имя входного файла для аргументов при раздельной загрузке
    FileNameFuncTable: string; // имя входного файла для значений функции при раздельной загрузке
    Xi_array: TExtArray; // точки аргуметнов Xi функции, если она задана через свойства объекта
    Fi_array: TExtArray; // точки значений Fi функции, если она задана через свойства объекта

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

//===========================================================================
constructor TMyInterpolationBlock1.Create;
begin
  inherited;
  IsLinearBlock:=True;
  Xi_array := TExtArray.Create(1); // точки аргументов Xi функции, если она задана через свойства объекта
  Fi_array:= TExtArray.Create(1); // точки значений Fi функции, если она задана через свойства объекта
  Func := TFndimFunctionByPoints1d.Create;

  //TFndimFunctionByPoints1d_testAll('e:\USERDISK\SIM_WORK\БЛОКИ_ИНТЕРПОЛЯЦИИ\InterpolationBlocks_autoTestLog.txt');
end;

destructor  TMyInterpolationBlock1.Destroy;
begin
  FreeAndNil(Xi_array);
  FreeAndNil(Fi_array);
  FreeAndNil(Func);
  inherited;
end;

function    TMyInterpolationBlock1.GetParamID;
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
    Result:=NativeInt(Xi_array);
    DataType:=dtDoubleArray;
    exit;
  end;

  if StrEqu(ParamName,'Fi_array') then begin
    Result:=NativeInt(Fi_array);
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

  ErrorEvent('параметр '+ParamName+' не найден', msWarning, VisualObject);
end;

function    TMyInterpolationBlock1.InfoFunc;
  var i,j,maxn,maxd,dimi:  integer;
  val:Double;
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
//---------------------------------------------------------------------------

function TMyInterpolationBlock1.LoadFuncFromProperties(): Boolean;
var
  i,j: Integer;
  Xp: Double;
begin
  Result := True;

  if Fi_array.Count<>Fdim*Xi_array.Count then begin //проверка корректности входных размеров
    ErrorEvent('Число значений Fi_array и аргументов Xi_array входной функции не совпадает',msError,VisualObject);
    Result := False;
    exit;
    end;

  Func.ClearPoints();
  Func.beginPoints;
    for i:=0 to Xi_array.Count-1 do begin // идем по входному вектору и добавляем точки в функцию.
      Xp := Xi_array.Arr[i];

      for j:=0 to Fdim-1 do begin
        Func.Fval1[j] := Fi_array.Arr[i*Fdim+j];
        end;
      Func.addPoint(Xp,PDouble(Func.Fval1));
      end;
  Func.endPoints;

end;

function TMyInterpolationBlock1.LoadFuncFromFilesXiFi(): Boolean;
label
  OnExit;
var
  tableX,tableF: TTable1;
  i,j,k, m,n: Integer;
  Xp,v: Double;

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


  Func.ClearPoints();
  // TODO сбой памяти при закрытии - выснить как изменять то, что в свойствах
  Fdim := 1+tableF.FunsCount;
  Func.setFdim(Fdim);
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

function TMyInterpolationBlock1.LoadFuncFromFile(): Boolean;
label
  OnExit;
var
  table1: TTable1;
  i,j,k, m,n: Integer;
  Xp,v: Double;

begin
  Result := True;
  table1 := TTable1.Create(FileName);
  if not table1.OpenFromFile(FileName) then begin
    ErrorEvent('Файл '+FileName+' невозможно считать',msError,VisualObject);
    Result := False;
    goto OnExit;
    end;

  Func.ClearPoints();
  // TODO - сбой памяти при закрытии - как изменять то, что в свойствах???
  Fdim := table1.FunsCount;
  Func.setFdim(Fdim);

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

function TMyInterpolationBlock1.LoadFuncFromPorts(): Boolean;
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

function TMyInterpolationBlock1.LoadFunc(): Boolean;
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

function   TMyInterpolationBlock1.RunFunc(var at,h : RealType; Action:Integer):NativeInt;
var
    i,j,k : Integer;
    v,vmax   : RealType;
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

//===========================================================================

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
end.
