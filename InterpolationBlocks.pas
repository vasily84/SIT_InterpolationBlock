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
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath, InterpolationBlocks_unit;


type

// отладочный блок-компонент возвращает максимальное скалярное число из всех
  // векторных входов
  TMyInterpolationBlock1 = class(TRunObject)
  protected
    Func: TFndimFunctionByPoints1d; // хранилище наших точек функции

    Fdim: NativeInt;                // размерность выходного вектора функции
    InterpolationType: NativeInt;   // тип интерполяции - кусочно-постоянная, линейная, Лагранжа и т.п.
    ExtrapolationType: NativeInt;   // тип экстраполяции за пределами определения функции - константа, кусочно-постоянная и т.д.
    LagrangeOrder: NativeInt; // порядок интерполяции для метода Лагранжа

  public
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
  end;

///////////////////////////////////////////////////////////////////////////////
 //Блок многомерной линейной интерполяции

 TMyNDimInterpolationOld = class(TRunObject)
 public
   tmpxp:         TExtArray2;
   outmode:       NativeInt;
   method:        NativeInt;
   x_:            TExtArray2;
   val_:          TExtArray;
   u_,v_:         TExtArray;
   ad_,k_:        TIntArray;
   function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
   function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
   function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
   constructor    Create(Owner: TObject);override;
   destructor     Destroy;override;
 end;


  //Блок - интерполяция (по Лагранжу или сплайновая с произвольным порядком)
  TMyInterpOld = class(TRunObject)
  protected
    SplineArr:     TExtArray2;
    Ind:           array of NativeInt;
    x_tab:         TExtArray2; //Массивы иcходных данных
    y_tab:         TExtArray2;
  public
    //Переменные, доступные извне
    Met,
    Order,
    N,
    M,
    Nfun:          NativeInt;  // число функции - только 1 поддерживает
    SplineIsNatural:Boolean;
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
  end;

  // отладочный блок-компонент для быстрой проверки размерностей. Математическая операция - взятие модуля
  //Размерности входных векторов долны совпадать. Размерность выходного вектора равна размерности входных.
  TMyAbs1 = class(TRunObject)
  protected
    a:             TExtArray;
  public
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
  end;

  // отладочный блок-компонент возвращает максимальное скалярное число из всех
  // векторных входов
  TMyMaxInputs1 = class(TRunObject)
  protected
    Func: TFndimFunctionByPoints1d;
    Ndim: NativeInt;
  public
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
  end;

implementation

//===========================================================================
constructor TMyInterpolationBlock1.Create;
begin
  inherited;
  IsLinearBlock:=True;
  Func := TFndimFunctionByPoints1d.Create;
end;

destructor  TMyInterpolationBlock1.Destroy;
begin
  FreeAndNil(Func);
  inherited;
end;

function    TMyInterpolationBlock1.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

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

                   //TODO зачем устанавливать размерность выходного вектора - УЗНАТЬ
                   CY[0].Dim:=SetDim([Fdim]);
                 end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function   TMyInterpolationBlock1.RunFunc(var at,h : RealType; Action:Integer):NativeInt;
var
    i,j : Integer;
    v,vmax   : RealType;
    Xp   : double;
    i0,j0: Integer;
    Xarg: Double;

begin
  Result := r_Success;

  case Action of
    f_InitState,
    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep:
              begin
                ///////////////////////////////////////////////////////////////
                // порядок действий -
                // 0. проверяем размерности входных портов
                // 1. инициализируем наш набор точек ЗАНОВО
                // 2. определяем из входа аргумент X
                // 3. делаем необходимый вызов интерполяции
                // 4. формируем и возвращаем вектор-ответ

                // 0. проверяем размерности входных портов
                if Length(U)<>3 then begin
                  ErrorEvent('Число входных портов не равно 3',msError,VisualObject);
                  Result := r_Fail;
                  exit;
                  end;

                if U[0].Count<>Fdim*U[1].Count then begin //проверка корректности входных размеров
                  ErrorEvent('Число значений Fi и аргументов Xi входной функции не совпадает',msError,VisualObject);
                  Result := r_Fail;
                  exit;
                  end;

                // 1. инициализируем наш набор точек ЗАНОВО
                Func.ClearPoints();

                Func.beginPoints;
                for i:=0 to U[0].Count-1 do begin // идем по входному вектору и добавляем точки в функцию.
                  Xp := U[1][i];
                  
                  for j:=0 to Fdim-1 do begin
                    Func.Fval1[j] := U[0][i*Fdim+j];
                    end;

                  Func.addPoint(Xp,PDouble(Func.Fval1));
                  end;
                Func.endPoints;

                // 2. определяем из входа аргумент X
                Xarg := U[2][0];

                // 3. делаем необходимый вызов интерполяции
                if InterpolationType=1 then begin // линейная
                  Func.LinearInterpolation(Xarg, PDouble(Func.Fval1));
                  end
                else begin                       // кусочно-постоянная
                  Func.IntervalInterpolation(Xarg, PDouble(Func.Fval1));
                  end;

                // 4. формируем и возвращаем вектор-ответ
                for j:=0 to Fdim-1 do begin
                  Y[0][j] :=  Func.Fval1[j];
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
{*******************************************************************************
                       Многомерная линейная интерполяция
*******************************************************************************}
constructor  TMyNDimInterpolationOld.Create;
begin
  inherited;
  method:=0;
  outmode:=0;
  tmpxp:=TExtArray2.Create(0,0);
  x_:=TExtArray2.Create(0,0);
  val_:=TExtArray.Create(0);
  u_:=TExtArray.Create(0);
  v_:=TExtArray.Create(0);
  ad_:=TIntArray.Create(0);
  k_:=TIntArray.Create(0);
end;

destructor   TMyNDimInterpolationOld.Destroy;
begin
  tmpxp.Free;
  x_.Free;
  val_.Free;
  u_.Free;
  v_.Free;
  ad_.Free;
  k_.Free;
  inherited;
end;

function     TMyNDimInterpolationOld.InfoFunc;
 var p,i,nn: NativeInt;
begin
  Result:=0;
  case Action of
    i_GetPropErr: if (x_.CountX > 0) then begin

                    //Вычисляем суммарную размерность
                    p:=x_[0].Count;
                    for I := 1 to x_.CountX - 1 do p:=p*x_[i].Count;

                    //Проверяем всё ли задано в массиве val_
                    if val_.Count > 0 then begin
                      if val_.Count < p then begin
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
    i_GetCount:   begin
                    //Размерность выхода = размерность входа делённая на размерность матрицы абсцисс
                    cY[0].Dim:= SetDim([ GetFullDim(cU[0].Dim) div x_.CountX ]);
                    //Условие кратности рзмерности
                    nn := cY[0].Dim[0]*x_.CountX;
                    if GetFullDim(cU[0].Dim) <> nn then cU[0].Dim:=SetDim([nn]);
                  end
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function    TMyNDimInterpolationOld.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result = -1 then begin
    if StrEqu(ParamName,'outmode') then begin
      Result:=NativeInt(@outmode);
      DataType:=dtInteger;
    end
    else
    if StrEqu(ParamName,'method') then begin
      Result:=NativeInt(@method);
      DataType:=dtInteger;
    end
    else
    if StrEqu(ParamName,'x') then begin
      Result:=NativeInt(x_);
      DataType:=dtMatrix;
    end
    else
    if StrEqu(ParamName,'values') then begin
      Result:=NativeInt(val_);
      DataType:=dtDoubleArray;
    end;
  end
end;

function    TMyNDimInterpolationOld.RunFunc;
 var
    i,j: integer;
begin
  Result:=0;
  case Action of
    f_InitObjects:    begin
                        //Подчитываем к-во точек по размерности входа
                        tmpxp.ChangeCount(GetFullDim(cU[0].Dim) div x_.CountX,x_.CountX);
                        //Инициализируем временные массивы
                        u_.Count  := x_.CountX;
                        v_.Count  := 1 shl (x_.CountX);
                        ad_.Count := 1 shl (x_.CountX);
                        k_.Count  := x_.CountX;
                      end;
    f_RestoreOuts,
    f_InitState,
    f_UpdateOuts,
    f_UpdateJacoby,
    f_GoodStep      : begin
                        j:=0;
                        for i := 0 to tmpxp.CountX - 1 do begin
                          Move(U[0].Arr^[j],tmpxp[i].Arr^[0],tmpxp[i].Count*SizeOfDouble);
                          inc(j,tmpxp[i].Count);
                        end;

                        case method of
                          1: nstep_interp(x_,val_,tmpxp,Y[0],outmode,k_);
                        else
                          nlinear_interp(x_,val_,tmpxp,Y[0],outmode,u_,v_,ad_,k_);
                        end;

                      end;
  end
end;



{*******************************************************************************
                            Интерполяция
*******************************************************************************}
constructor TMyInterpOld.Create;
begin
  inherited;
  // почему массивы двумерные?
  SplineArr:=TExtArray2.Create(1,1);
  x_tab:=TExtArray2.Create(1,1);
  y_tab:=TExtArray2.Create(1,1);
  SplineIsNatural:=True;
end;

destructor  TMyInterpOld.Destroy;
begin
  inherited;
  FreeAndNil(SplineArr);
  FreeAndNil(x_tab);
  FreeAndNil(y_tab);
end;

function    TMyInterpOld.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

    if StrEqu(ParamName,'met') then begin
      Result:=NativeInt(@met);
      DataType:=dtInteger;
      exit;
    end;

    if StrEqu(ParamName,'m') then begin
      Result:=NativeInt(@m);
      DataType:=dtInteger;
      exit;
    end;

    if StrEqu(ParamName,'n') then begin
      Result:=NativeInt(@n);
      DataType:=dtInteger;
      exit;
    end;

    if StrEqu(ParamName,'nfun') then begin
      Result:=NativeInt(@nfun);
      DataType:=dtInteger;
      exit;
    end;

    if StrEqu(ParamName,'order') then begin
      Result:=NativeInt(@order);
      DataType:=dtInteger;
      exit;
    end;

    if StrEqu(ParamName,'isnatural') then begin
      Result:=NativeInt(@SplineIsNatural);
      DataType:=dtBool;
      exit;
    end;

end;

function    TMyInterpOld.InfoFunc;
begin
  Result:=0;
  case Action of
    i_GetCount:  begin
                   CU[0].Dim:=SetDim([N]);
                   CU[1].Dim:=SetDim([N*Nfun]);
                   CY[0].Dim:=SetDim([GetFullDim(CU[2].Dim)*Nfun]);
                 end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function   TMyInterpOld.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var i,j,c   : Integer;
    py      : PExtArr;
    px      : PExtArr;

 function  CheckChanges:boolean;
  var j: integer;
 begin
   Result:=False;
   for j:=0 to N - 1 do
     if (x_tab[i].Arr^[j] <> px[j]) or (y_tab[i].Arr^[j] <> py[j]) then begin
       x_tab[i].Arr^[j]:=px[j];
       y_tab[i].Arr^[j]:=py[j];
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
                     SplineArr.ChangeCount(5,N);
                     x_tab.ChangeCount(Nfun,N);
                     y_tab.ChangeCount(Nfun,N);
                   end;
    f_InitState,
    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep: begin
                  px:=U[0].Arr;
                  py:=U[1].arr;
                  c:=0;
                  for i:=0 to Nfun - 1 do begin
                   case Met of
                   0: for j:=0 to U[2].Count - 1 do begin
                         Y[0].arr^[i*U[2].Count+j]:=Lagrange(px^,py^,U[2].arr^[j],Order,M);
                         inc(c);
                      end;
                   1: begin
                       //Вычисление натурального кубического сплайна
                       if CheckChanges or (Action = f_InitState) then NaturalSplineCalc(px,py,SplineArr.Arr,N,SplineIsNatural);
                       for j:=0 to U[2].Count - 1 do begin
                         Y[0].arr^[c] :=Interpol(U[2].Arr^[j],SplineArr.Arr,5,Ind[j]);
                         inc(c);
                       end
                      end;
                   2: begin
                       if CheckChanges or (Action = f_InitState) then LInterpCalc(px,py,SplineArr.Arr,N);
                       for j:=0 to U[2].Count - 1 do begin
                         Y[0].arr^[c] :=Interpol(U[2].Arr^[j],SplineArr.Arr,3,Ind[j]);
                         inc(c);
                       end
                      end;
                   end;
                   py:=@py^[N];

		              end
                 end;
  end
end;

//===========================================================================
constructor TMyMaxInputs1.Create;
begin
  inherited;
  IsLinearBlock:=True;
end;

destructor  TMyMaxInputs1.Destroy;
begin
  inherited;
end;

function    TMyMaxInputs1.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

  if StrEqu(ParamName,'Ndim') then begin
    Result:=NativeInt(@Ndim);
    DataType:=dtInteger;
    exit;
  end;

end;

function    TMyMaxInputs1.InfoFunc;
  var i,j,maxn,maxd,dimi:  integer;
  val:Double;
begin
  Result := r_Success;

  case Action of
    i_GetInit:   Result := r_Success;
    i_GetCount:  begin
                   if Length( cU ) = 0 then begin  // входной вектор нулевой длины - невозможная ситуация
                     ErrorEvent(txtSumErr,msError,VisualObject);
                     Result:=r_Fail;
                     exit;
                   end;
                   for i:=0 to Length(cU)-1 do begin
                     end;
                   //CU[0].Dim:=SetDim([Ndim]);
                   //CU[1].Dim:=SetDim([Ndim*Ndim]);
                   //CY[0].Dim:=SetDim([GetFullDim(CU[2].Dim)*Ndim]);
                   CY[0].Dim:=SetDim([1]);//SetDim([GetFullDim(CU[2].Dim)*Ndim]);
                 end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function   TMyMaxInputs1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var i,j : Integer;
    v,vmax   : RealType;
    k   : double;
    i0,j0: Integer;

begin
  Result := r_Success;

  case Action of
    f_InitState,
    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep:
              begin
                vmax:=U[0][0];
                for i:=0 to Length(U)-1 do begin
                  for j:=0 to U[i].count-1 do begin
                    v:=U[i][j];
                    if v>vmax then vmax:=v;
                    end;
                  end;

                Y[0][0] := vmax;
              end;
  end;
end;

//===========================================================================
//===========================================================================
constructor TMyAbs1.Create;
begin
  inherited;
  a:=TExtArray.Create(0);
  IsLinearBlock:=True;
end;

destructor  TMyAbs1.Destroy;
begin
  inherited;
  FreeAndNil(a);
end;

function    TMyAbs1.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result = -1 then begin
    if StrEqu(ParamName,'a') then begin
      Result:=NativeInt(a);
      DataType:=dtDoubleArray;
    end;
  end
end;

function    TMyAbs1.InfoFunc;
  var i,maxn,maxd,dimi:  integer;
begin
  Result := r_Success;

  case Action of
    i_GetCount:  begin
                   if Length( cU ) = 0 then begin  // входной вектор нулевой длины - невозможная ситуация
                     ErrorEvent(txtSumErr,msError,VisualObject);
                     Result:=r_Fail;
                     exit;
                   end;

                   //Для определениы выходной размерности используем
                   //максимальную вычисленную размерность
                   maxn:=0;
                   maxd:=GetFullDim(CU[maxn].Dim);
                   for i:=1 to Length(cU) - 1 do begin
                     dimi:=GetFullDim(CU[i].Dim);
                     if dimi > maxd then begin
                       maxd:=dimi;
                       maxn:=i;
                     end;
                   end;

                   CY[0].Dim:=CU[maxn].Dim;
                   for i:=1 to Length(cU) - 1 do cU[i].Dim:=cU[maxn].Dim;
                 end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function   TMyAbs1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var i,j : Integer;
    s,v   : RealType;
    k   : double;
    i0,j0: Integer;

begin
  Result:=0;
  case Action of
    f_InitState,
    f_RestoreOuts,
    f_UpdateJacoby,
    f_UpdateOuts,
    f_GoodStep:
              begin
                for i:=0 to Y[0].count - 1 do begin
                   s:=0;
                   k:=1;
                   if i < a.Count then begin
                       k:=a.Arr^[i];
                     end  else begin
                       ErrorEvent('входная размерность больше вектора а',msError,VisualObject);
                     end;

                   for j:=0 to Length( cU ) - 1 do begin
                     s:=s + U[j].Arr^[i]*k;
                   end;
                   //Y[0].Arr^[i]:=s;
                   Y[0].Arr^[i]:=abs(s);
                  end

                 {
                  for i:=0 to Y[0].count - 1 do begin
                   s:=0;
                   k:=1;
                   for j:=0 to Length( cU ) - 1 do begin
                     if j < a.Count then k:=a.Arr^[j];
                     //s:=s + U[j].Arr^[i]*k;
                     s:=s + U[j].Arr^[i]*k;
                   end;
                   //Y[0].Arr^[i]:=s;
                   Y[0].Arr^[i]:=abs(s);
                 end
                 }
              end;
  end;
end;
//===========================================================================

//---------------------------------------------------------------------------
end.
