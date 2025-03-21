//**************************************************************************//
 // Данный исходный код является составной частью системы SimInTech          //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit RealArrays_Utils;

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}Classes, DataTypes, Data_blocks;

function TExtArray_IsOrdered(aArr: TExtArray): Boolean;
function TExtArray_HasDuplicates(aArr: TExtArray): Boolean;
procedure TExtArray_Sort_XY_Arr(aXarr,aYarr: TExtArray);


function Load_TExtArray_FromFile(aFileName: string; var aArray1: TExtArray): Boolean;
function Load_2TExtArrays_FromFile(aFileName: string; var aXarr,aYarr: TExtArray): Boolean;

function Load_TExtArray2_FromCsvFile(aFileName: string; var aArrayVect: TExtArray2): Boolean;

function Load_TExtArray_FromBinFile(aFileName: string; var aArray1: TExtArray; Asizeofreal:integer=8): Integer;
procedure Save_TExtArray_ToBinFile(aFileName: string; var aArray1: TExtArray);


procedure TExtArray_cpy(var ADst: TExtArray;const ASrc: TExtArray);
procedure TExtArray2_cpy(var ADst: TExtArray2;const ASrc: TExtArray2);

function TExtArray2_From_TExtArray(var ADstTable: TExtArray2;const ASrc: TExtArray; XCount,YCount: Integer):Boolean;

implementation
uses SysUtils, StrUtils, RealArrays, Math;

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

function TExtArray_IsOrdered(aArr: TExtArray): Boolean;
// проверить, упорядочен ли массив
var
  i: Integer;
begin
  Result := True;
  for i:=0 to aArr.Count-2 do begin
    if(aArr[i+1]<aArr[i]) then begin
      exit(False);
      end;
    end;
end;
//---------------------------------------------------------------------------
function TExtArray_HasDuplicates(aArr: TExtArray): Boolean;
// проверить, есть ли дупликаты значений в массиве
var
  i: Integer;
begin
  Result := False;
  for i:=0 to aArr.Count-2 do begin
    if(aArr[i+1]=aArr[i]) then begin
      exit(True);
      end;
    end;
end;

//----------------------------------------------------------------------------
procedure TExtArray_Sort_XY_Arr(aXarr,aYarr: TExtArray);
// отсортировать по возрастанию X пары значений (X;Y). Yi - векторный,
// длина Y должна быть кратна X
procedure swapPoint(q,w: Integer);
// поменять точки q,w местами
var
  x1,y1: RealType;
begin
  x1 := aXarr[q];
  aXarr[q] := aXarr[w];
  aXarr[w] := x1;
  y1 := aYarr[q];
  aYarr[q] := aYarr[w];
  aYarr[w] := y1;
end;
//---
var
  minX: RealType;
  minIndex: Integer;
  i,j: Integer;
begin
  for i:=0 to aXarr.Count-2 do begin
    minX := aXarr[i];
    minIndex := i;
    for j:=i+1 to aXarr.Count-1 do begin
      if minX>aXarr[j] then begin
        minX := aXarr[j];
        minIndex := j;
        end;
      end;

    if minIndex<>i then swapPoint(i,minIndex);
    end;
end;
//===========================================================================
//---------------------------------------------------------------------------
procedure RemoveCommentsFromStrings(var aStrings:TStringList);
// пустые строки, строки начинающиеся с $, части строк за // - отбрасываем
var
  slist2: TStringList;
  i,position: Integer;
  str1: string;
begin
  slist2 := TStringList.Create;
  // отбрасываем комментарии и пустые строки
  for i:=0 to aStrings.Count-1 do begin
    str1 := aStrings.Strings[i];
    if StartsText('$', str1) then continue;

    position := Pos('//',str1);
    if position>=1 then begin // отбрасываем закомментированый хвост
      SetLength(str1, position);
      end;

    str1 := Trim(str1);
    if str1='' then continue; // отбрасываем пустые строки
    slist2.Add(str1);
    end;

  aStrings.Assign(slist2);
  FreeAndNil(slist2);
end;

//---------------------------------------------------------------------------
function Load_TExtArray_FromFile(aFileName: string; var aArray1: TExtArray): Boolean;
// загрузить вектор из файла, отбросив комментарии и форматирование.
var
  slist1: TStringList;
  str1: string;
  v1: RealType;
  i: Integer;
begin
  Result := True;
  aFileName := ExpandFileName(aFileName);

  try
    slist1 := TStringList.Create;
    slist1.LoadFromFile(aFileName);
    RemoveCommentsFromStrings(slist1);
    // TODO!! развернуть вариант с записью данных в одну строчку с разделителем , или ;

    aArray1.Count := slist1.Count;
    for i:=0 to slist1.Count-1 do begin
      str1 := slist1.Strings[i];
      v1 := StrToFloat(str1);
      aArray1[i] := v1;
      end;

  except
    Result := False;
  end;

  FreeAndNil(slist1);
end;

//---------------------------------------------------------------------------
function Load_TExtArray2_FromCsvFile(aFileName: string; var aArrayVect: TExtArray2): Boolean;
// загрузить массив векторов из файла
var
  slist1,slist2: TStringList;
  str1,str2: string;
  v1: RealType;
  i,j: integer;
  countX,countY: Integer;
begin
  Result := True;
  aFileName := ExpandFileName(aFileName);

  try
    slist1 := TStringList.Create;
    slist2 := TStringList.Create;

    slist1.LoadFromFile(aFileName);
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

    aArrayVect.ChangeCount(countX, countY);

    for i:=0 to countX-1 do begin
      str1 := slist1.Strings[i];

      slist2.Clear;
      slist2.LineBreak := ';';
      slist2.Text := str1;

      if countY<>slist2.Count then Result:=False;
      
      for j:=0 to countY-1 do begin
        str2 := Trim(slist2.Strings[j]);
        v1 := StrToFloat(str2);
        aArrayVect[i][j] := v1;
        end;
      end;

  except
    Result := False;
  end;

  FreeAndNil(slist1);
  FreeAndNil(slist2);
end;
//---------------------------------------------------------------------------
function Load_2TExtArrays_FromFile(aFileName: string; var aXarr,aYarr: TExtArray): Boolean;
// загрузить массив векторов из файла
var
  slist1,slist2: TStringList;
  str1,str2: string;
  vX,vY: RealType;
  i: integer;
  countX,countY: Integer;
begin
  Result := True;
  aFileName := ExpandFileName(aFileName);

  try
    slist1 := TStringList.Create;
    slist2 := TStringList.Create;

    slist1.LoadFromFile(aFileName);
    // отбрасываем комментарии и пустые строки
    RemoveCommentsFromStrings(slist1);

    str1 := slist1.Text;
    // замена , на ;
    str1 := StringReplace(str1, ',', ';', [rfReplaceAll, rfIgnoreCase]);
    slist1.Text := str1;
    countX := slist1.Count;
    aXarr.Count := countX;
    aYarr.Count := countX;

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

      aXarr[i] := vX;
      aYarr[i] := vY;
      end;

  except
    Result := False;
  end;

  FreeAndNil(slist1);
  FreeAndNil(slist2);
end;

//---------------------------------------------------------------------------
function Load_TExtArray_FromBinFile(aFileName: string; var aArray1: TExtArray; Asizeofreal:integer=8): Integer;
// загрузить данные из файла. Возвращает число считанных значений или отрицательное число в случае ошибки
label
  OnExit;
var
  FileStream: TFileStream;
  ArrayCount, i: Integer;
begin
  aFileName := ExpandFileName(aFileName);

  if not FileExists(aFileName) then begin
    exit(-1);
    end;

  Asizeofreal := sizeof(RealType);

  if Asizeofreal<>8 then begin // пока подгружает только 8 байтные типы
    exit(-2);
    end;

  FileStream := TFileStream.Create(aFileName, fmOpenRead);

  if (FileStream.Size mod Asizeofreal)<>0 then begin
    Result:=-3;
    goto OnExit;
    end;

  if (FileStream.Size<=0) then begin
    Result:=-4;
    goto OnExit;
    end;

  ArrayCount:=FileStream.Size div Asizeofreal;

  aArray1.ChangeCount(ArrayCount);
  FileStream.Read(aArray1.Arr, FileStream.Size); // вычитываем разом весь массив.

  // проверяем на наличие NAN
  for i:=0 to ArrayCount-1 do begin
    if IsNAN(aArray1.Arr[i]) then begin
      Result:=-5;
      goto OnExit;
      end;
    end;

  Result := ArrayCount; // Успех, вычитано нормальное количество нормальных чисел

OnExit:
  if Assigned(FileStream) then FreeAndNil(FileStream);
end;
//---------------------------------------------------------------------------
procedure Save_TExtArray_ToBinFile(aFileName: string; var aArray1: TExtArray);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(aFileName, fmCreate);
  try
    FileStream.WriteBuffer(aArray1.Arr, SizeOf(RealType)*aArray1.Count);
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
    exit(False);
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
