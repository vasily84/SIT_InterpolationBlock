//**************************************************************************//
 // Данный исходный код является составной частью системы SimInTech          //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit RealArrays_Utils;

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, mbty_std_consts;

function TExtArray_IsOrdered(Arr: TExtArray): Boolean;
function TExtArray_HasDuplicates(Arr: TExtArray): Boolean;
procedure TExtArray_Sort_XY_Arr(Xarr,Yarr: TExtArray);


function Load_TExtArray_FromFile(FileName: string; var array1: TExtArray): Boolean;
function Load_2TExtArrays_FromFile(FileName: string; var Xarr,Yarr: TExtArray): Boolean;

function Load_TExtArray2_FromCsvFile(FileName: string; var arrayVect: TExtArray2): Boolean;

function Load_TExtArray_FromBinFile(FileName: string; var array1: TExtArray; Asizeofreal:integer=8): Integer;
procedure Save_TExtArray_ToBinFile(FileName: string; var array1: TExtArray);


procedure TExtArray_cpy(var ADst: TExtArray;const ASrc: TExtArray);
procedure TExtArray2_cpy(var ADst: TExtArray2;const ASrc: TExtArray2);

function TExtArray2_From_TExtArray(var ADstTable: TExtArray2;const ASrc: TExtArray; XCount,YCount: Integer):Boolean;

implementation

uses StrUtils, RealArrays;
//===========================================================================
procedure TExtArray_cpy(var ADst: TExtArray;const ASrc: TExtArray);
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
procedure TExtArray2_cpy(var ADst: TExtArray2;const ASrc: TExtArray2);
// скопировать Asrc->ADst. может изменить память ADst
var
  i,j: Integer;
begin
  // TODO - переделать на Move
  ADst.ChangeCount(ASrc.CountX, ASrc.GetMaxCountY);
  for i:=0 to ASrc.CountX-1 do begin
    ADst[i].Count := ASrc[i].Count;
    for j:=0 to ASrc[i].Count-1 do begin
      ADst[i][j]:= ASrc[i][j];
      end;
    end;

end;

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
procedure TExtArray_Sort_XY_Arr(Xarr,Yarr: TExtArray);
// отсортировать по возрастанию X пары значений (X;Y). Yi - векторный,
// длина Y должна быть кратна X
procedure swapPoint(q,w: Integer);
// поменять точки q,w местами
var
  x1,y1: RealType;
begin
  x1 := Xarr[q];
  Xarr[q] := Xarr[w];
  Xarr[w] := x1;
  y1 := Yarr[q];
  Yarr[q] := Yarr[w];
  Yarr[w] := y1;
end;
//---
var
  minX: RealType;
  minIndex: Integer;
  i,j: Integer;
begin
  for i:=0 to Xarr.Count-2 do begin
    minX := Xarr[i];
    minIndex := i;
    for j:=i+1 to Xarr.Count-1 do begin
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

//---------------------------------------------------------------------------
function Load_TExtArray_FromFile(FileName: string; var array1: TExtArray): Boolean;
// загрузить вектор из файла, отбросив комментарии и форматирование.
var
  slist1: TStringList;
  str1: string;
  v1: RealType;
  i: Integer;
begin
  Result := True;
  FileName := ExpandFileName(FileName);

  try
    slist1 := TStringList.Create;
    slist1.LoadFromFile(FileName);
    RemoveCommentsFromStrings(slist1);
    // TODO!! развернуть вариант с записью данных в одну строчку с разделителем , или ;

    array1.Count := slist1.Count;
    for i:=0 to slist1.Count-1 do begin
      str1 := slist1.Strings[i];
      v1 := StrToFloat(str1);
      array1[i] := v1;
      end;

  except
    Result := False;
  end;

  FreeAndNil(slist1);
end;

//---------------------------------------------------------------------------
function Load_TExtArray2_FromCsvFile(FileName: string; var arrayVect: TExtArray2): Boolean;
// загрузить массив векторов из файла
var
  slist1,slist2: TStringList;
  str1,str2: string;
  v1: RealType;
  i,j: integer;
  countX,countY: Integer;
begin
  Result := True;
  FileName := ExpandFileName(FileName);

  try
    slist1 := TStringList.Create;
    slist2 := TStringList.Create;

    slist1.LoadFromFile(FileName);
    // отбрасываем комментарии и пустые строки
    RemoveCommentsFromStrings(slist1);

    str1 := slist1.Text;
    // замена , на ;
    str1 := StringReplace(str1, ',', ';', [rfReplaceAll, rfIgnoreCase]);
    slist1.Text := str1;
    countX := slist1.Count;
    slist2.Clear;
    slist2.LineBreak:=';';
    slist2.Text := slist1.Strings[0];
    countY:= slist2.Count;

    arrayVect.ChangeCount(countX, countY);

    for i:=0 to countX-1 do begin
      str1 := slist1.Strings[i];

      slist2.Clear;
      slist2.LineBreak := ';';
      slist2.Text := str1;

      if countY<>slist2.Count then Result:=False;
      
      for j:=0 to countY-1 do begin
        str2 := Trim(slist2.Strings[j]);
        v1 := StrToFloat(str2);
        arrayVect[i][j] := v1;
        end;
      end;

  except
    Result := False;
  end;

  FreeAndNil(slist1);
  FreeAndNil(slist2);
end;
//---------------------------------------------------------------------------
function Load_2TExtArrays_FromFile(FileName: string; var Xarr,Yarr: TExtArray): Boolean;
// загрузить массив векторов из файла
var
  slist1,slist2: TStringList;
  str1,str2: string;
  vX,vY: RealType;
  i: integer;
  countX,countY: Integer;
begin
  Result := True;
  FileName := ExpandFileName(FileName);

  try
    slist1 := TStringList.Create;
    slist2 := TStringList.Create;

    slist1.LoadFromFile(FileName);
    // отбрасываем комментарии и пустые строки
    RemoveCommentsFromStrings(slist1);

    str1 := slist1.Text;
    // замена , на ;
    str1 := StringReplace(str1, ',', ';', [rfReplaceAll, rfIgnoreCase]);
    slist1.Text := str1;
    countX := slist1.Count;
    Xarr.Count := countX;
    Yarr.Count := countX;

    for i:=0 to countX-1 do begin
      str1 := slist1.Strings[i];

      slist2.Clear;
      slist2.LineBreak := ';';
      slist2.Text := str1;

      countY := slist2.Count;
      if countY<>2 then Result:=False;

      str2 := Trim(slist2.Strings[0]);
      vX := StrToFloat(str2);

      str2 := Trim(slist2.Strings[1]);
      vY := StrToFloat(str2);

      Xarr[i] := vX;
      Yarr[i] := vY;
      end;

  except
    Result := False;
  end;

  FreeAndNil(slist1);
  FreeAndNil(slist2);
end;

//---------------------------------------------------------------------------
function Load_TExtArray_FromBinFile(FileName: string; var array1: TExtArray; Asizeofreal:integer=8): Integer;
// загрузить данные из файла. Возвращает число считанных значений или отрицательное число в случае ошибки
label
  OnExit;
var
  FileStream: TFileStream;
  ArrayCount, i: Integer;
begin
  FileName := ExpandFileName(FileName);

  if not FileExists(FileName) then begin
    Result:=-1;
    exit;
    end;

  Asizeofreal := sizeof(RealType);

  if Asizeofreal<>8 then begin // пока подгружает только 8 байтные типы
    Result:=-2;
    exit;
    end;

  FileStream := TFileStream.Create(FileName, fmOpenRead);

  if (FileStream.Size mod Asizeofreal)<>0 then begin
    Result:=-3;
    goto OnExit;
    end;

  if (FileStream.Size<=0) then begin
    Result:=-4;
    goto OnExit;
    end;

  ArrayCount:=FileStream.Size div Asizeofreal;

  array1.ChangeCount(ArrayCount);
  FileStream.Read(array1.Arr, FileStream.Size); // вычитываем разом весь массив.

  // проверяем на наличие NAN
  for i:=0 to ArrayCount-1 do begin
    if IsNAN(array1.Arr[i]) then begin
      Result:=-5;
      goto OnExit;
      end;
    end;

  Result := ArrayCount; // Успех, вычитано нормальное количество нормальных чисел

OnExit:
  if Assigned(FileStream) then FreeAndNil(FileStream);
end;
//---------------------------------------------------------------------------
procedure Save_TExtArray_ToBinFile(FileName: string; var array1: TExtArray);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    FileStream.WriteBuffer(array1.Arr, SizeOf(RealType)*array1.Count);
  finally
    FileStream.Free;
  end;
end;
//---------------------------------------------------------------------------

function TExtArray2_From_TExtArray(var ADstTable: TExtArray2;const ASrc: TExtArray; XCount,YCount: Integer):Boolean;
// скопировать данные из массива в таблицу заданной размерности
var
  i,j,k: Integer;
begin
  if(XCount*YCount>Asrc.Count) then begin
    Result := False;
    exit;
    end;

  k:=0;
  ADstTable.ChangeCount(XCount,YCount);
  for  i:=0 to XCount-1 do
    for j:=0 to YCount-1 do begin
      ADstTable[i][j]:=ASrc[k];
      inc(k);
      end;

  Result := True;
end;

end.
