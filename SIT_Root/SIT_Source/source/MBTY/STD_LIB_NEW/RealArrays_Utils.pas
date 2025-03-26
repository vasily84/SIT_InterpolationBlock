//**************************************************************************//
 // Данный исходный код является составной частью системы SimInTech          //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit RealArrays_Utils;

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}Classes, DataTypes, Data_blocks,tbls;

function TExtArray_IsOrdered(aArr: TExtArray): Boolean;
function TExtArray_HasDuplicates(aArr: TExtArray): Boolean;
procedure TExtArray_Sort_XY_Arr(aXarr,aYarr: TExtArray);
procedure TTable2_Sort(aTable: TTable2);

function Load_TExtArray_FromFile(aFileName: string; var aArray1: TExtArray): Boolean;
function Load_2TExtArrays_FromFile(aFileName: string; var aXarr,aYarr: TExtArray): Boolean;

function Load_TExtArray2_FromCsvFile(aFileName: string; var aArrayVect: TExtArray2): Boolean;

function Load_TExtArray_FromBinFile(aFileName: string; var aArray1: TExtArray; Asizeofreal:integer=8): Integer;
procedure Save_TExtArray_ToBinFile(aFileName: string; var aArray1: TExtArray);

procedure TExtArray_cpy(var ADst: TExtArray;const ASrc: TExtArray);
procedure TExtArray2_cpy(var ADst: TExtArray2;const ASrc: TExtArray2);

function TExtArray_IsSame(const aVect1,aVect2: TExtArray): Boolean;
function TExtArray2_IsSame(const aParam1,aParam2: TExtArray2): Boolean;

function TExtArray2_From_TExtArray(var ADstTable: TExtArray2;const ASrc: TExtArray; XCount,YCount: Integer):Boolean;

implementation
uses SysUtils, StrUtils, RealArrays, Math;

//===========================================================================
procedure TExtArray_cpy(var ADst: TExtArray;const ASrc: TExtArray);
// скопировать Asrc->ADst. может изменить память ADst
begin
  ADst.Count := ASrc.Count;
  Move(Asrc.Arr^[0], ADst.Arr^[0],SizeOfDouble*ADst.Count);
end;
//----------------------------------------------------------------------------
procedure TExtArray2_cpy(var ADst: TExtArray2;const ASrc: TExtArray2);
// скопировать Asrc->ADst. может изменить память ADst
var
  i: Integer;
begin
  ADst.ChangeCount(ASrc.CountX, ASrc.GetMaxCountY);
  for i:=0 to ASrc.CountX-1 do begin
    ADst[i].Count := ASrc[i].Count;
    Move(ASrc[i].Arr^[0], ADst[i].Arr^[0], ADst[i].Count*SizeOfDouble);
    end;
end;

function TExtArray_IsSame(const aVect1,aVect2: TExtArray):Boolean;
// массивы одинаковы?
begin
  if aVect1.Count<>aVect2.Count then Exit(False);
  Result:=CompareMem(@aVect1.Arr[0],@aVect2.Arr[0],SizeOfDouble*aVect1.Count);
end;

function TExtArray2_IsSame(const aParam1,aParam2: TExtArray2): Boolean;
// массивы одинаковы?
var
  i,j: Integer;
begin
  if aParam1.CountX<> aParam2.CountX then Exit(False);

  for i:=0 to aParam2.CountX-1 do begin
    if aParam1[i].Count<> aParam2[i].Count then Exit(False);

    for j:=0 to aParam2[i].Count-1 do
      if aParam1[i][j]<>aParam2[i][j] then Exit(False);

    end;

  Result:=True;
end;

function TExtArray_IsOrdered(aArr: TExtArray): Boolean;
// проверить, упорядочен ли массив
var
  i: Integer;
begin
  for i:=0 to aArr.Count-2 do
    if(aArr[i+1]<aArr[i]) then exit(False);

  Result := True;
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
// отсортировать по возрастанию X пары значений (X;Y)
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
  tailOrdered: Boolean;
begin
  for i:=0 to aXarr.Count-2 do begin
    minX := aXarr[i];
    minIndex := i;
    tailOrdered:=True;
    for j:=i+1 to aXarr.Count-1 do begin
      if minX>aXarr[j] then begin
        minX := aXarr[j];
        minIndex := j;
        end;
      if aXarr[j-1]>aXarr[j] then tailOrdered:=False; // хвост массива неупорядочен
      end;

    if minIndex<>i then swapPoint(i,minIndex);
    if tailOrdered then break;  // остаток массива упорядочен, сортировка завершена
    end;
end;
//---------------------------------------------------------------------------
procedure TTable2_swapRows(aTable: TTable2; aRowI,aRowJ: Integer);
var
  y: RealType;
  i:Integer;
begin
  y:=aTable.px1[aRowI];
  aTable.px1[aRowI]:=aTable.px1[aRowj];
  aTable.px1[aRowJ]:=y;

  for i:=0 to aTable.py.GetMaxCountY-1 do begin
    y:=aTable.py[aRowI][i];
    aTable.py[aRowI][i]:=aTable.py[aRowj][i];
    aTable.py[aRowJ][i]:=y;
    end;
end;

procedure TTable2_swapCols(aTable: TTable2; aColI,aColJ: Integer);
var
  y: RealType;
  i:Integer;
begin
  y:=aTable.px2[aColI];
  aTable.px2[aColI]:=aTable.px2[aColJ];
  aTable.px2[aColJ]:=y;

  for i:=0 to aTable.py.CountX-1 do begin
    y:=aTable.py[i][aColI];
    aTable.py[i][aColI]:=aTable.py[i][aColJ];
    aTable.py[i][aColJ]:=y;
    end;
end;

procedure TTable2_Sort(aTable: TTable2);
// отсортировать таблицу по возрастанию аргументов строк и столбцов
var
  minVal: RealType;
  minIndex: Integer;
  i,j: Integer;
  tailOrdered: Boolean;
begin

  for i:=0 to aTable.px1.Count-2 do begin
    minVal := aTable.px1[i];
    minIndex := i;
    tailOrdered:=True;
    for j:=i+1 to aTable.px1.Count-1 do begin
      if minVal>aTable.px1[j] then begin
        minVal := aTable.px1[j];
        minIndex := j;
        end;
      if aTable.px1[j-1]>aTable.px1[j] then tailOrdered:=False; // хвост массива неупорядочен
      end;

    if minIndex<>i then TTable2_swapRows(aTable,i,minIndex);
    if tailOrdered then break;  // остаток массива упорядочен, сортировка завершена
    end;

  for i:=0 to aTable.px2.Count-2 do begin
    minVal := aTable.px2[i];
    minIndex := i;
    tailOrdered:=True;
    for j:=i+1 to aTable.px2.Count-1 do begin
      if minVal>aTable.px2[j] then begin
        minVal := aTable.px2[j];
        minIndex := j;
        end;
      if aTable.px2[j-1]>aTable.px2[j] then tailOrdered:=False; // хвост массива неупорядочен
      end;

    if minIndex<>i then TTable2_swapCols(aTable,i,minIndex);
    if tailOrdered then break;  // остаток массива упорядочен, сортировка завершена
    end;

end;

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
function findDelim(aStr: string): string;
begin
  if Pos(';',aStr)>0 then Exit(';');
  if Pos(',',aStr)>0 then Exit(',');
  if Pos('|',aStr)>0 then Exit('|');
  if Pos(#9,aStr)>0 then Exit(#9);   // табуляция
  // самый дурацкий вариант - разделитель пробел
  Result := ' ';
end;

//---------------------------------------------------------------------------
function Load_TExtArray_FromFile(aFileName: string; var aArray1: TExtArray): Boolean;
// загрузить вектор из файла, отбросив комментарии и форматирование.
var
  slist1: TStringList;
  str1,strLineBreak: string;
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
    str1 := slist1.Text;
    strLineBreak := findDelim(str1);
    // замена табов на пробелы - ибо люди и текстовые редакторы часто используют пробелы вместо табов и наоборот
    str1 := StringReplace(str1, #13#10, strLineBreak, [rfReplaceAll, rfIgnoreCase]);

    slist1.Clear;
    slist1.LineBreak:=strLineBreak;
    slist1.Text := str1;

    // удаляем пустые строки - могут появится из-за двойных пробелов и т.п.
    RemoveCommentsFromStrings(slist1);
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
var
  slRows,slCols: TStringList;
  str2,strLineBreak: string;
  v1: RealType;
  i,j: integer;
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
    RemoveCommentsFromStrings(slCols);
    countCols:= slCols.Count;
    aArrayVect.ChangeCount(countRows, countCols);

    for i:=0 to countRows-1 do begin
      slCols.Clear;
      slCols.LineBreak := strLineBreak;
      slCols.Text := slRows.Strings[i];
      RemoveCommentsFromStrings(slCols);

      if slCols.Count<>countCols then begin
        Result:=False;
        break;
        end;

      for j:=0 to slCols.Count-1 do begin
        str2 := Trim(slCols.Strings[j]);
        v1 := StrToFloat(str2);
        aArrayVect[i][j] := v1;
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
  i: Integer;
begin
  csvArr := TExtArray2.Create(1,1);
  Result := Load_TExtArray2_FromCsvFile(aFileName, csvArr);
  if Result and (csvArr.GetMaxCountY=2) then begin
    aXarr.Count := csvArr.CountX;
    aYarr.Count := csvArr.CountX;

    for i:=0 to csvArr.CountX-1 do begin
      aXarr[i] := csvArr.Arr[i][0];
      aYarr[i] := csvArr.Arr[i][1];
      end;
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
