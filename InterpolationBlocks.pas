//**************************************************************************//
 // ƒанный исходный код €вл€етс€ составной частью системы ћ¬“”-4             //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit InterpolationBlocks;

 //***************************************************************************//
 //                Ѕлоки интерпол€ции
 //***************************************************************************//

 {
 создан на основе оригинальной библиотеки mbty_std
 реализаци€ одномерной и двухмерной интерпол€ции, где исходные данные могут быть
 заданы в виде констант - векторов и матриц, и в виде внешних файлов.
 }

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath;


type
{
Ѕлок интерпол€ции, универсальный. —оздан на основе блоков из mbtu_std
}

  TInterpolationBlock1 = class(TRunObject)
  protected
    // эта часть от TFromTable2D
    table:         TTable2;

    // эта часть от TInterp
    SplineArr:     TExtArray2;
    Ind:           array of NativeInt;
    x_tab:         TExtArray2;
    y_tab:         TExtArray2;
  public
    // эта часть от TFromTable2D
    FileName:      string;
    interp_method: NativeInt;

    // эта часть от TInterp
    Met,
    Order,
    N,
    M,
    Nfun:          NativeInt;
    SplineIsNatural:Boolean;

    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       InfoFunc_TFromTable2D(Action: integer;aParameter: NativeInt):NativeInt;
    function       InfoFunc_TInterp(Action: integer;aParameter: NativeInt):NativeInt;


    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       RunFunc_TFromTable2D(var at,h : RealType;Action:Integer):NativeInt;
    function       RunFunc_TInterp(var at,h : RealType;Action:Integer):NativeInt;

    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
    function       GetOutParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    function       ReadParam(ID: NativeInt;ParamType:TDataType;DestData: Pointer;DestDataType: TDataType;MoveData:TMoveProc):boolean;override;
  end;

const
  interp_method_linear = 0;    // методы интерпол€ции
  interp_method_linear_noextra = 1;
  interp_piecewise_constant =2;

  Met_polynom_Lagrange = 0;
  Met_cube_spline = 1;
  Met_linear = 2;

implementation

{*******************************************************************************
            ƒвумерна€ интерпол€ци€ по таблице из файла
*******************************************************************************}
constructor  TInterpolationBlock1.Create;
begin
  inherited;
  // эта часть от TFromTable2D
  table:=TTable2.Create('');
  interp_method:=0;

  // эта часть от TInterp
  SplineArr:=TExtArray2.Create(1,1);
  x_tab:=TExtArray2.Create(1,1);
  y_tab:=TExtArray2.Create(1,1);
  SplineIsNatural:=True;
end;

destructor   TInterpolationBlock1.Destroy;
begin
  inherited;
  // эта часть от TFromTable2D
  table.Free;

  // эта часть от TInterp
  SplineArr.Free;
  x_tab.Free;
  y_tab.Free;
end;

//----------------------------------------------------------------------------
function    TInterpolationBlock1.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then Exit;

  // параметры от TFromTable2D
  if StrEqu(ParamName,'interp_method') then begin
      Result:=NativeInt(@interp_method);
      DataType:=dtInteger;
    end
  else
    if StrEqu(ParamName,'filename') then begin
      Result:=NativeInt(@FileName);
      DataType:=dtString;
    end

  else // эта часть от TInterp
  if StrEqu(ParamName,'met') then begin
      Result:=NativeInt(@met);
      DataType:=dtInteger;
    end
  else
    if StrEqu(ParamName,'m') then begin
      Result:=NativeInt(@m);
      DataType:=dtInteger;
    end
  else
    if StrEqu(ParamName,'n') then begin
      Result:=NativeInt(@n);
      DataType:=dtInteger;
    end
  else
    if StrEqu(ParamName,'nfun') then begin
      Result:=NativeInt(@nfun);
      DataType:=dtInteger;
    end
  else
    if StrEqu(ParamName,'order') then begin
      Result:=NativeInt(@order);
      DataType:=dtInteger;
    end
  else
    if StrEqu(ParamName,'isnatural') then begin
      Result:=NativeInt(@SplineIsNatural);
      DataType:=dtBool;
    end

end;
//---------------------------------------------------------------------------

function TInterpolationBlock1.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
begin
  //Result := InfoFunc_TFromTable2D(Action,aParameter);
  Result := InfoFunc_TInterp(Action,aParameter);
end;
//---------------------------------------------------------------------------

function TInterpolationBlock1.InfoFunc_TFromTable2D(Action: integer;aParameter: NativeInt):NativeInt;
begin
  Result:=0;
  case Action of
    i_GetInit:   Result:=0;
    i_GetCount:  begin
                   cY[0]:=cU[0];
                   cU[1]:=cU[0];
                 end;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;
//---------------------------------------------------------------------------

function TInterpolationBlock1.InfoFunc_TInterp(Action: integer;aParameter: NativeInt):NativeInt;
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
//---------------------------------------------------------------------------

function    TInterpolationBlock1.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
begin
  //Result := RunFunc_TFromTable2D(at,h,Action);
  Result := RunFunc_TInterp(at,h,Action);
end;
//---------------------------------------------------------------------------

function    TInterpolationBlock1.RunFunc_TFromTable2D(var at,h : RealType;Action:Integer):NativeInt;
 var i: integer;
begin
  Result:=0;

  case Action of
    f_InitObjects: begin
                     //«агрузка данных из файла с таблицей
                     table.OpenFromFile(FileName);
                     if (table.px1.Count = 0) or (table.px2.Count = 0) then begin
                       ErrorEvent(txtErrorReadTable,msError,VisualObject);
                       Result:=r_Fail;
                     end;
                   end;

    f_UpdateJacoby,
    f_InitState,
    f_UpdateOuts,
    f_RestoreOuts,
    f_GoodStep:   case interp_method of
                    1: begin
                         for i:=0 to U[0].Count - 1 do
                           Y[0].Arr^[i]:=table.GetFunValueWithoutExtrapolation(U[0].Arr^[i],U[1].Arr^[i]);
                       end;
                    2: begin
                         for i:=0 to U[0].Count - 1 do
                           Y[0].Arr^[i]:=table.GetFunValueWithoutInterpolation(U[0].Arr^[i],U[1].Arr^[i]);
                       end;
                  else
                    for i:=0 to U[0].Count - 1 do
                      Y[0].Arr^[i]:=table.GetFunValue(U[0].Arr^[i],U[1].Arr^[i]);
                  end;

  end
end;
//----------------------------------------------------------------------------

function    TInterpolationBlock1.RunFunc_TInterp(var at,h : RealType;Action:Integer):NativeInt;
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
                     //«десь устанавливаем нужные размерности вспомогательных
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
                       //¬ычисление натурального кубического сплайна
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

//---------------------------------------------------------------------------
function TInterpolationBlock1.GetOutParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
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
//---------------------------------------------------------------------------

function TInterpolationBlock1.ReadParam(ID: NativeInt;ParamType:TDataType;DestData: Pointer;DestDataType: TDataType;MoveData:TMoveProc):boolean;
 var i: integer;
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

//---------------------------------------------------------------------------
end.
