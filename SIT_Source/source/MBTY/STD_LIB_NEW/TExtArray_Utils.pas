//**************************************************************************//
 // Данный исходный код является составной частью системы SimInTech          //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit TExtArray_Utils;

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath, System.StrUtils;


function TExtArray_IsOrdered(Arr: TExtArray): Boolean;
function TExtArray_HasDuplicates(Arr: TExtArray): Boolean;
procedure TExtArray_Sort_XY_Arr(Xarr: TExtArray; Yarr: TExtArray; NPoints,Fdim: Integer);


function Load_TExtArray_FromBracketFile(FileName: string; var array1: TExtArray): Boolean;
function Load_TExtArray2_FromBracketFile(FileName: string; var arrayVect: TExtArray2): Boolean;

procedure TExtArray_cpy(ADst: TExtArray;const ASrc: TExtArray);

implementation

uses RealArrays;
//===========================================================================
procedure TExtArray_cpy(ADst: TExtArray;const ASrc: TExtArray);
// скопировать Asrc->ADst. может изменить память ADst
var
  i: Integer;
begin
  // TODO - переделать на Move
  ADst.Count := ASrc.Count;
  for i:=0 to ASrc.Count-1 do begin
    ADst[i] := ASrc[i];
    end;
end;
//----------------------------------------------------------------------------
function TExtArray_IsOrdered(Arr: TExtArray): Boolean;
// проверить, упорядочен ли массив
var
  i: Integer;
begin
  Result := True;
  for i:=0 to Arr.Count-2 do begin
    if(Arr[i+1]<Arr[i]) then begin
      Result := False;
      exit;
      end;
    end;
end;
//---------------------------------------------------------------------------
function TExtArray_HasDuplicates(Arr: TExtArray): Boolean;
// проверить, есть ли дупликаты значений в массиве
var
  i: Integer;
begin
  Result := False;
  for i:=0 to Arr.Count-2 do begin
    if(Arr[i+1]=Arr[i]) then begin
      Result := True;
      exit;
      end;
    end;
end;

//----------------------------------------------------------------------------
procedure TExtArray_Sort_XY_Arr(Xarr: TExtArray; Yarr: TExtArray; NPoints,Fdim: Integer);
// отсортировать по возрастанию X пары значений (X;Y). Yi - векторный,
// длина Y должна быть кратна X
procedure swapPoint(q,w: Integer);
// поменять точки q,w местами
var
  x1,y1: RealType;
  ff1: Integer;
begin
  x1 := Xarr[q];
  Xarr[q] := Xarr[w];
  Xarr[w] := x1;

  for ff1:=0 to Fdim-1 do begin // странное расположение массивов в памяти, но как есть
    y1 := Yarr[q+ff1*NPoints];
    Yarr[q+ff1*NPoints] := Yarr[w+ff1*NPoints];
    Yarr[w+ff1*NPoints] := y1;
    end;

end;
//----
var
  minX: RealType;
  minIndex: Integer;
  i,j: Integer;
begin
  for i:=0 to NPoints-2 do begin
    minX := Xarr[i];
    minIndex := i;
    for j:=i+1 to NPoints-1 do begin
      if minX>Xarr[j] then begin
        minX := Xarr[j];
        minIndex := j;
        end;
      end;

    if minIndex<>i then swapPoint(i,minIndex);
    end;
end;
//===========================================================================
//---------------------------------------------------------------------------
procedure RemoveCommentsFromStrings(var Strings:TStringList);
// пустые строки, строки начинающиеся с $, части строк за // - отбрасываем
var
  slist2: TStringList;
  i,position: Integer;
  str1: string;
begin
  slist2 := TStringList.Create;
  // отбрасываем комментарии и пустые строки
  for i:=0 to Strings.Count-1 do begin
    str1 := Strings.Strings[i];
    if StartsText('$', str1) then continue;

    position := Pos('//',str1);
    if position>=1 then begin // отбрасываем закомментированый хвост
      SetLength(str1, position);
      end;

    str1 := Trim(str1);
    if str1='' then continue; // отбрасываем пустые строки
    slist2.Add(str1);
    end;

  Strings.Assign(slist2);
  FreeAndNil(slist2);
end;
//--------------------------------------------------------------------------

function Load_TExtArray2_FromBracketFile(FileName: string; var arrayVect: TExtArray2): Boolean;
// загрузить массив векторов из файла
var
  slist1,slist2,slist3: TStringList;
  str1,str2: string;
  v1: RealType;
  i,j: integer;
begin
  // пример файла [[0 , 1 , 2 , 9];[0 , 5 , 8];[0 , 3]]
  // пустые строки, строки начинающиеся с $, части строк за // - отбрасываем
  Result := True;
  try
    slist1 := TStringList.Create;
    slist2 := TStringList.Create;
    slist3 := TStringList.Create;

    slist1.LoadFromFile(FileName);
    // отбрасываем комментарии и пустые строки
    RemoveCommentsFromStrings(slist1);

    slist1.LineBreak := ';';

    str1 := slist1.Text;
    //TODO - добавить проверку наличия двойных скобок.
    // заменяем двойные скобки на одинарные
    str1 := StringReplace(str1, '[[', '[', [rfReplaceAll, rfIgnoreCase]);
    str1 := StringReplace(str1, ']]', ']', [rfReplaceAll, rfIgnoreCase]);

    // случай запятые вместо двоеточий.
    str1 := StringReplace(str1, '],', '];', [rfReplaceAll, rfIgnoreCase]);
    str1 := StringReplace(str1, '] ,', '];', [rfReplaceAll, rfIgnoreCase]);

    slist1.Text := str1;

    arrayVect.ChangeCount(slist1.Count, 1);

    for i:=0 to slist1.Count-1 do begin
      str1 := slist1.Strings[i];
      str1 := StringReplace(str1, '[', ' ', [rfReplaceAll, rfIgnoreCase]);
      str1 := StringReplace(str1, ']', ' ', [rfReplaceAll, rfIgnoreCase]);
      str1 := StringReplace(str1, ';', ' ', [rfReplaceAll, rfIgnoreCase]);

      slist2.Clear;
      slist2.LineBreak := ',';
      slist2.Text := str1;

      arrayVect[i].Count := slist2.Count;
      for j:=0 to slist2.Count-1 do begin
        str2 := slist2.Strings[j];
        v1 := StrToFloat(str2);
        arrayVect[i][j] := v1;
        end;
      end;
  except
    Result := False;
  end;

  FreeAndNil(slist1);
  FreeAndNil(slist2);
  FreeAndNil(slist3);
end;

//---------------------------------------------------------------------------
function Load_TExtArray_FromBracketFile(FileName: string; var array1: TExtArray): Boolean;
// загрузить вектор из файла
var
  slist1: TStringList;
  str1: string;
  v1: RealType;
  i: Integer;
begin
  // пример файла [0 , 0.1 , 1.1 , 1.2 , 3.5 , 3.3 , 6.1 , 6.2 , 7.1 , 7.2 , 9.1 , 9.2 , 8.1 , 8.3 , 5.6 , 5.9 , 3.7 , 3.9 , 18.1 , 18.3 , 15.6 , 5.9 , 13.7 , 13.9]
  Result := True;

  try
    slist1 := TStringList.Create;
    slist1.LoadFromFile(FileName);
    RemoveCommentsFromStrings(slist1);

    slist1.LineBreak := ',';
    str1 := slist1.Text;
    str1 := StringReplace(str1, '[', ' ', [rfReplaceAll, rfIgnoreCase]);
    str1 := StringReplace(str1, ']', ' ', [rfReplaceAll, rfIgnoreCase]);
    slist1.Text := str1;

    array1.Count := slist1.Count;

    for i:=0 to slist1.Count-1 do begin
      str1 := slist1.Strings[i];
      str1 := StringReplace(str1, '[', ' ', [rfReplaceAll, rfIgnoreCase]);
      str1 := StringReplace(str1, ';', ' ', [rfReplaceAll, rfIgnoreCase]);
      str1 := StringReplace(str1, ']', ' ', [rfReplaceAll, rfIgnoreCase]);

      v1 := StrToFloat(str1);
      array1[i] := v1;
      end;

  except
    Result := False;
  end;

  FreeAndNil(slist1);
end;

end.
