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
  for i:=0 to aArr.Count-2 do
    if(aArr[i+1]<aArr[i]) then exit(False);

end;
//---------------------------------------------------------------------------
function TExtArray_HasDuplicates(aArr: TExtArray): Boolean;
// проверить, есть ли дупликаты значений в массиве
var
  i,j: Integer;
begin
  Result := False;
  for i:=0 to aArr.Count-2 do
    for j:=i+1 to aArr.Count-1 do begin
      if(aArr[i]=aArr[j]) then exit(True);
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
// табы заменяем на пробелы
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

  // замена табов на пробелы - ибо люди и текстовые редакторы часто используют пробелы вместо табов и наоборот
  slist2.Text := StringReplace(slist2.Text, #9, ' ', [rfReplaceAll, rfIgnoreCase]);

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
// загрузить массив векторов из csv-файла. Возможные разделители - запятая, двоеточие,
// таб, пробел. Пробелы и табы могут быть смешаны. Все вектора должны быть одинаковой длины.
function findDelim(aStr: string): string;
begin
  if Pos(';',aStr)>0 then Exit(';');
  if Pos(',',aStr)>0 then Exit(',');
  if Pos(#9,aStr)>0 then Exit(#9);   // табуляция
  // самый дурацкий вариант - разделитель пробел
  Result := ' ';
end;
//------
var
  slRows,slCols: TStringList;
  str1,str2,strLineBreak: string;
  v1: RealType;
  i,j,k,NN: integer;
  countRows,countCols: Integer;
begin
  Result := True;
  aFileName := ExpandFileName(aFileName);

  try
    slRows := TStringList.Create;
    slCols := TStringList.Create;

    slRows.LoadFromFile(aFileName);
    // отбрасываем комментарии и пустые строки
    RemoveCommentsFromStrings(slRows);

    countRows := slRows.Count;

    strLineBreak := findDelim(slRows.Strings[0]);
    slCols.Clear;
    slCols.LineBreak:=strLineBreak;
    slCols.Text := slRows.Strings[0];

    // подсчитываем реальное число значимых записей в строке.
    NN:=0;
    for k:=0 to slCols.Count-1 do begin
      str2 := Trim(slCols.Strings[k]);
      if str2='' then continue;
      inc(NN);
      end;

    countCols:= NN;
    aArrayVect.ChangeCount(countRows, countCols);

    for i:=0 to countRows-1 do begin
      str1 := slRows.Strings[i];

      slCols.Clear;
      slCols.LineBreak := strLineBreak;
      slCols.Text := str1;

      NN:=0;
      for j:=0 to slCols.Count-1 do begin
        str2 := Trim(slCols.Strings[j]);
        if str2='' then continue; // не обрабатываем пустые символы

        v1 := StrToFloat(str2);
        aArrayVect[i][NN] := v1;
        inc(NN);
        if NN>=countCols then break;
        end;

      if NN<>countCols then begin
        Result:=False;
        break;
        end;
      end;

  except
    Result := False;
  end;

  FreeAndNil(slRows);
  FreeAndNil(slCols);
end;
//---------------------------------------------------------------------------
function Load_2TExtArrays_FromFile(aFileName: string; var aXarr,aYarr: TExtArray): Boolean;
// загрузить 2 массива из файла
var
  csvArr: TExtArray2;
begin
  csvArr := TExtArray2.Create(1,1);
  Result := Load_TExtArray2_FromCsvFile(aFileName, csvArr);
  if Result and (csvArr.GetMaxCountY=2) then begin
    TExtArray_cpy(aXarr,csvArr.Arr[0]);
    TExtArray_cpy(aYarr,csvArr.Arr[1]);
    end;
  FreeAndNil(csvArr);
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
