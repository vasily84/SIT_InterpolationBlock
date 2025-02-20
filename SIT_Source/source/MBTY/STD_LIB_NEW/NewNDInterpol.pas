//**************************************************************************//
 // Данный исходный код является составной частью системы МВТУ-4             //
 // Программисты:                          //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit NewNDInterpol;

interface

uses Classes, MBTYArrays, DataTypes, SysUtils, abstract_im_interface, RunObjts, Math,
     uCircBufferAlgs, mbty_std_consts, InterpolFuncs;


type
 //Блок многомерной линейной интерполяции
 TNewNDInterpol = class(TRunObject)
 public
   // это свойства
   BorderExtrapolationType:       NativeInt; // ПЕРЕЧИСЛЕНИЕ тип экстраполяции при аргументе за пределами границ
   InterpType:        NativeInt; // ПЕРЕЧИСЛЕНИЕ метод интерполяции

   property_Xarg:            TExtArray2; // матрица аргументов по размерностям
   property_Fval:          TExtArray;  // Вектор значений функции


   Xarg:            TExtArray2; // матрица аргументов по размерностям
   Fval:          TExtArray;  // Вектор значений функции

   // это внутренние переменные
   tmpxp:         TExtArray2;
   u_,v_:         TExtArray;
   ad_,k_:        TIntArray;

   function LoadData(): Boolean;

   function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
   function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
   function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
   constructor    Create(Owner: TObject);override;
   destructor     Destroy;override;
 end;

implementation

//uses RealArrays;
{*******************************************************************************
                       Многомерная линейная интерполяция
*******************************************************************************}
constructor  TNewNDInterpol.Create;
begin
  inherited;
  InterpType:=0;
  BorderExtrapolationType:=0;

  tmpxp:=TExtArray2.Create(0,0);

  // аргументы и значения функции для вычислений.
  // Могут быть получены - 1. из свойств объекта 2. загружены из файла
  Xarg:=TExtArray2.Create(0,0);
  Fval:=TExtArray.Create(0);

  // свойства объекта - аргументы и значения функции
  property_Xarg:=TExtArray2.Create(0,0);
  property_Fval:=TExtArray.Create(0);

  u_:=TExtArray.Create(0);
  v_:=TExtArray.Create(0);
  ad_:=TIntArray.Create(0);
  k_:=TIntArray.Create(0);
end;

destructor   TNewNDInterpol.Destroy;
begin
  FreeAndNil(tmpxp);
  FreeAndNil(Xarg);
  FreeAndNil(Fval);
  FreeAndNil(property_Xarg);
  FreeAndNil(property_Fval);
  FreeAndNil(u_);
  FreeAndNil(v_);
  FreeAndNil(ad_);
  FreeAndNil(k_);
  inherited;
end;

function     TNewNDInterpol.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
 var p,i,nn: NativeInt;
begin
  Result:=r_Success;

  case Action of
    i_GetPropErr: begin // это специальный вызов для проверки размерностей?
                  if (Xarg.CountX > 0) then begin

                    //Вычисляем суммарную размерность
                    p:=Xarg[0].Count;
                    for I := 1 to Xarg.CountX - 1 do p:=p*Xarg[i].Count;

                    //Проверяем всё ли задано в массиве val_
                    if Fval.Count > 0 then begin
                      if Fval.Count < p then begin
                         ErrorEvent(txtOrdinatesDefineIncomplete+IntToStr(p),msWarning,VisualObject);
                      end;
                    end
                    else begin
                      ErrorEvent(txtOrdinatesNotDefinedError,msError,VisualObject);
                      Result:=r_Fail;  //Если возвращаем > 0 - то значит произошла ошибка
                    end;

                  end
                  else begin
                    ErrorEvent(txtDimensionsNotDefined,msError,VisualObject);
                    Result:=r_Fail;  //Если возвращаем > 0 - то значит произошла ошибка
                  end;
                  end;

    i_GetCount:   begin
                    //Размерность выхода = размерность входа делённая на размерность матрицы абсцисс
                    cY[0].Dim:= SetDim([ GetFullDim(cU[0].Dim) div Xarg.CountX ]);
                    //Условие кратности рзмерности
                    nn := cY[0].Dim[0]*Xarg.CountX;
                    if GetFullDim(cU[0].Dim) <> nn then cU[0].Dim:=SetDim([nn]);
                  end
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function    TNewNDInterpol.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result<>0 then exit;

    if StrEqu(ParamName,'outmode') then begin
      Result:=NativeInt(@BorderExtrapolationType);
      DataType:=dtInteger;
      exit;
      end;

    if StrEqu(ParamName,'method') then begin
      Result:=NativeInt(@InterpType);
      DataType:=dtInteger;
      exit;
      end;

    if StrEqu(ParamName,'x') then begin
      Result:=NativeInt(Xarg);
      DataType:=dtMatrix;
      exit;
      end;

    if StrEqu(ParamName,'values') then begin
      Result:=NativeInt(Fval);
      DataType:=dtDoubleArray;
      end;

    ErrorEvent('параметр '+ParamName+' в блоке Многомерной интерполяции не найден', msWarning, VisualObject);
end;

function    TNewNDInterpol.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
 var
    i,j: integer;
begin
  Result:=0;
  case Action of
    f_InitObjects:    begin
                          //Подчитываем к-во точек по размерности входа
                        tmpxp.ChangeCount(GetFullDim(cU[0].Dim) div Xarg.CountX,Xarg.CountX);

                        //Инициализируем временные массивы
                        u_.Count  := Xarg.CountX;
                        v_.Count  := 1 shl (Xarg.CountX);
                        ad_.Count := 1 shl (Xarg.CountX);
                        k_.Count  := Xarg.CountX;
                      end;
    f_RestoreOuts,
    f_InitState,
    f_UpdateOuts,
    f_UpdateJacoby,
    f_GoodStep      : begin
                        LoadData();

                        j:=0;
                        for i := 0 to tmpxp.CountX - 1 do begin
                          Move(U[0].Arr^[j],tmpxp[i].Arr^[0],tmpxp[i].Count*SizeOfDouble);
                          inc(j,tmpxp[i].Count);
                        end;

                        case InterpType of
                          1: nstep_interp(Xarg,Fval,tmpxp,Y[0],BorderExtrapolationType,k_);
                        else
                          nlinear_interp(Xarg,Fval,tmpxp,Y[0],BorderExtrapolationType,u_,v_,ad_,k_);
                        end;

                      end;
  end
end;

function TNewNDInterpol.LoadData(): Boolean;
// загрузить данные из свойств или файлов в расчетные Xarg Fval
var
  Xarg_clone: TExtArray2;
  Fval_clone: TExtArray;
  i,j,k: Integer;
begin
  Result := True;
//TODO - выяснить корректный метод копирования массивов
  Xarg_clone := property_Xarg;
  Fval_clone := property_Fval;

  // копирование одномерного массива
  Fval_clone.Count := Fval.Count;
  for i:=0 to Fval.Count-1 do begin
    Fval_clone[i]:= Fval[i];
    end;

  // копирование многомерного массива
  Xarg_clone.ChangeCount(Xarg.CountX,Xarg.GetMaxCountY);
  for i:=0 to Xarg.CountX-1 do begin
    for j:=0 to Xarg[i].Count-1 do begin
      Xarg_clone[i][j]:= Xarg[i][j];
      end;
    end;

end;

end.
