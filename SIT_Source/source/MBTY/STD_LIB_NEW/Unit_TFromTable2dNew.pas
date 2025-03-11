unit Unit_TFromTable2dNew;

interface
uses Classes, MBTYArrays, DataTypes, SysUtils, abstract_im_interface, RunObjts,
  math, tbls, mbty_std_consts, Data_blocks, TExtArray_Utils;

//Двумерная линейная интерполяция по таблице из файла
 type
  TFromTable2DNew = class(TRunObject)
  protected
    table:         TTable2;
  public
    fileName,fileNameArgs,fileNameVals:      string;
    interp_method: NativeInt;
    extrType: NativeInt;
    inputType: NativeInt;

    prop_X1_arr, prop_X2_arr: TExtArray;
    prop_DataTable: TExtArray2;

    function LoadDataFromPorts(): Boolean;
    function LoadDataFromProperties(): Boolean;
    function LoadDataFromFiles12():Boolean;
    function LoadDataFromFile(): Boolean;
    function LoadData(): Boolean;
    function checkXY_Range(var aX1,aX2: RealType;var aZvalue: RealType): Boolean;

    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
    // TODO - выяснить, что это было?
    function       GetOutParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    function       ReadParam(ID: NativeInt;ParamType:TDataType;DestData: Pointer;DestDataType: TDataType;MoveData:TMoveProc):boolean;override;
  end;

implementation
uses RealArrays;

const
  // назначения входных портов
  ROW_ARG = 0;
  COL_ARG = 1;
  ROW_ARGS_ARR = 2;
  COL_ARGS_ARR = 3;
  FUNCS_TABLE = 4;


{*******************************************************************************
            Двумерная линейная интерполяция по таблице из файла
*******************************************************************************}
constructor TFromTable2DNew.Create;
begin
  inherited;
  table:=TTable2.Create('');
  interp_method:=0;
  prop_X1_arr:= TExtArray.Create(1);
  prop_X2_arr:= TExtArray.Create(1);
  prop_DataTable:= TExtArray2.Create(1,1);
end;

destructor TFromTable2DNew.Destroy;
begin
  FreeAndNil(table);
  FreeAndNil(prop_X1_arr);
  FreeAndNil(prop_X2_arr);
  FreeAndNil(prop_DataTable);
  inherited;
end;

function TFromTable2DNew.GetParamID;
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
    Result:=NativeInt(@interp_method);
    DataType:=dtInteger;
    end;

  if StrEqu(ParamName,'extrType') then begin
    Result:=NativeInt(@extrType);
    DataType:=dtInteger;
    end;

  if StrEqu(ParamName,'inputType') then begin
    Result:=NativeInt(@inputType);
    DataType:=dtInteger;
    end;

  if StrEqu(ParamName,'filename') then begin
    Result:=NativeInt(@fileName);
    DataType:=dtString;
    end;

  if StrEqu(ParamName,'fileNameArgs') then begin
    Result:=NativeInt(@fileNameArgs);
    DataType:=dtString;
    end;
if StrEqu(ParamName,'fileNameVals') then begin
    Result:=NativeInt(@fileNameVals);
    DataType:=dtString;
    end;

end;

//----------------------------------------------------------------------------
function TFromTable2DNew.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result:=r_Success;
  case Action of
    i_GetInit:   Result:=r_Success;
    i_GetCount:  if Length(cU) > 1 then begin
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
function TFromTable2DNew.checkXY_Range(var aX1,aX2: RealType;var aZvalue: RealType): Boolean;
// проверить, что аргументы aX и aY находится внутри диапазона определения функции.
// возвращает - True - аргументы находится внутри диапазона и экстраполяция не требуется.
// иначе - False, и изменяет AYValue на значение экстраполяции
var
  // признаки нахождения аргументов в границах диапазонов
  //x1_belowRange,x1_inRange,x1_aboveRange,x2_belowRange,x2_inRange,x2_aboveRange: Boolean;
  x1_inRange,x2_inRange: Boolean;
begin

  if ExtrType=2 then begin // экстраполировать границы для заданного метода
    Result := True;
    exit;
    end;

  x1_inRange := ((aX1>=table.px1[0])and(aX1<=table.px1[table.Arg1Count-1]));
  x2_inRange := ((aX2>=table.px2[0])and(aX2<=table.px2[table.Arg2Count-1]));

  // TODO - if (x1_inRange or x2_inRange) then begin - по идее должно быть так - обсудить
  if (x1_inRange or x2_inRange) then begin // в диапазоне, экстраполяция не требуется
    Result := True;
    exit;
    end;

  // за пределами диапазона, тип экстраполяции - ноль за пределами диапазона
  if ExtrType=1 then begin
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
function TFromTable2DNew.LoadDataFromPorts(): Boolean;
var
  i,j,k,M,N: Integer;
  f: RealType;
begin
  N := U[ROW_ARGS_ARR].Count;
  M := U[COL_ARGS_ARR].Count;
  // TODO - проверка размерности
  if M*N<>U[FUNCS_TABLE].Count then begin
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
function TFromTable2DNew.LoadDataFromProperties(): Boolean;
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
function TFromTable2DNew.LoadDataFromFiles12(): Boolean;
begin
  Result := False;
end;
//----------------------------------------------------------------------------
function TFromTable2DNew.LoadDataFromFile(): Boolean;
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
function TFromTable2DNew.LoadData(): Boolean;
begin
case inputType of
  0:// ввести вручную через свойства
    Result:=LoadDataFromProperties();
  1:// в разных файлах
    Result:=LoadDataFromFiles12();
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
function TFromTable2DNew.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
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
    f_UpdateJacoby,
    f_InitState,
    f_UpdateOuts,
    f_RestoreOuts,
    f_GoodStep:
      begin
        //TODO - Загрузка данных из порта - почему сразу не выставляет данные на порту, неведомо
        if inputType=3 then LoadDataFromPorts();

        case interp_method of

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
            Assert(False,'Table2d interpolation method not implemented');
        end;
      end;

  end
end;
//--------------------------------------------------------------------------
// TODO - зачем это так сделано? выяснить.
function TFromTable2DNew.GetOutParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
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
function TFromTable2DNew.ReadParam(ID: NativeInt;ParamType:TDataType;DestData: Pointer;DestDataType: TDataType;MoveData:TMoveProc):boolean;
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

end.
