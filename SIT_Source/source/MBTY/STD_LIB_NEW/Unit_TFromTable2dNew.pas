unit Unit_TFromTable2dNew;

interface
uses Classes, MBTYArrays, DataTypes, SysUtils, abstract_im_interface, RunObjts,
  math, tbls, mbty_std_consts,Data_blocks;

//Двумерная линейная интерполяция по таблице из файла
 type
  TFromTable2DNew = class(TRunObject)
  protected
    table:         TTable2;
  public
    filename:      string;
    interp_method: NativeInt;
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
    function       GetOutParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    function       ReadParam(ID: NativeInt;ParamType:TDataType;DestData: Pointer;DestDataType: TDataType;MoveData:TMoveProc):boolean;override;
  end;


implementation

{*******************************************************************************
            Двумерная линейная интерполяция по таблице из файла
*******************************************************************************}
constructor  TFromTable2DNew.Create;
begin
  inherited;
  table:=TTable2.Create('');
  interp_method:=0;
end;

destructor   TFromTable2DNew.Destroy;
begin
  inherited;
  table.Free;
end;

function    TFromTable2DNew.GetParamID;
begin
  Result:=inherited GetParamID(ParamName,DataType,IsConst);
  if Result = -1 then begin
    if StrEqu(ParamName,'interp_method') then begin
      Result:=NativeInt(@interp_method);
      DataType:=dtInteger;
    end
    else
    if StrEqu(ParamName,'filename') then begin
      Result:=NativeInt(@filename);
      DataType:=dtString;
    end;
  end
end;

function     TFromTable2DNew.InfoFunc;
begin
  Result:=0;
  case Action of
    i_GetInit:   Result:=0;
    i_GetCount:  if Length(cU) > 1 then begin
                    if GetFullDim( CU[1].Dim ) > GetFullDim( CU[0].Dim ) then
                       CU[0].Dim:=CU[1].Dim
                    else
                       CU[1].Dim:=CU[0].Dim;
                   cY[0]:=cU[0];
                 end
                 else
                   Result:=r_Fail;
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function    TFromTable2DNew.RunFunc;
 var i: integer;
begin
  Result:=0;
  case Action of
    f_InitObjects: begin
                     //Загрузка данных из файла с таблицей
                     table.OpenFromFile(FileName);
                     if (table.px1.Count = 0) or (table.px2.Count = 0) then begin
                       ErrorEvent(txtErrorReadTable,msError,VisualObject);
                       Result:=r_Fail;  //Если возвращаем > 0 - то значит произошла ошибка
                     end;
                   end;
    f_UpdateJacoby,
    f_InitState,
    f_UpdateOuts,
    f_RestoreOuts,
    f_GoodStep:   case interp_method of
                    0:  // линейная
                      begin
                      for i:=0 to U[0].Count - 1 do
                        Y[0].Arr^[i]:=table.GetFunValue(U[0].Arr^[i],U[1].Arr^[i]);

                      end;
                    1:  // линейная без экстраполяции
                       begin
                         for i:=0 to U[0].Count - 1 do
                           Y[0].Arr^[i]:=table.GetFunValueWithoutExtrapolation(U[0].Arr^[i],U[1].Arr^[i]);
                       end;
                    2:  // кусочно-постоянная
                       begin
                         for i:=0 to U[0].Count - 1 do
                           Y[0].Arr^[i]:=table.GetFunValueWithoutInterpolation(U[0].Arr^[i],U[1].Arr^[i]);
                       end;
                    3: // сплайны
                      begin
                          for i:=0 to U[0].Count - 1 do
                           Y[0].Arr^[i]:=table.GetFunValueBySplineInterpolation(U[0].Arr^[i],U[1].Arr^[i]);
                      end;
                    4: // акима
                      begin
                          for i:=0 to U[0].Count - 1 do
                           Y[0].Arr^[i]:=table.GetFunValueByAkimaInterpolation(U[0].Arr^[i],U[1].Arr^[i]);
                      end;
                  else
                    //
                  end;

  end
end;

function       TFromTable2DNew.GetOutParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
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

function       TFromTable2DNew.ReadParam(ID: NativeInt;ParamType:TDataType;DestData: Pointer;DestDataType: TDataType;MoveData:TMoveProc):boolean;
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



end.
