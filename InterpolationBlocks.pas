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

  // блок интерполяции N-мерной функции одного аргумента
  TMyInterpolationBlock1 = class(TRunObject)
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
end;

destructor  TMyInterpolationBlock1.Destroy;
begin
  inherited;
end;

function    TMyInterpolationBlock1.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

  if StrEqu(ParamName,'Ndim') then begin
    Result:=NativeInt(@Ndim);
    DataType:=dtInteger;
    exit;
  end;

end;

function    TMyInterpolationBlock1.InfoFunc;
  var i,maxn,maxd,dimi:  integer;
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

                   CU[0].Dim:=SetDim([Ndim]);
                   CU[1].Dim:=SetDim([Ndim*Ndim]);
                   CY[0].Dim:=SetDim([GetFullDim(CU[2].Dim)*Ndim]);
                 end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function   TMyInterpolationBlock1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
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
                       ErrorEvent('входная размерность больше ветора а',msError,VisualObject);
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
