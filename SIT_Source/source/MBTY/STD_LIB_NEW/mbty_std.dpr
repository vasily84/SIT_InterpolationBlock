
 //**************************************************************************//
 // Данный исходный код является составной частью системы МВТУ-4             //
 // Программисты:        Тимофеев К.А., Ходаковский В.В.                     //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

library mbty_std;

  //**************************************************************************//
  //      Стандартная библиотека автоматики                                   //
  //      Авторы: Тимофеев К.А., Ходаковский В.В., февраль-март 2005 г.       //
  //      Код этой библиотеки основан на стандартной библиотеке блоков МВТУ-3.//
  //**************************************************************************//

uses
  simmm,
  Classes,
  Info in 'Info.pas',
  lae_objects,
  Data_blocks in 'Data_blocks.pas',
  dif in 'dif.pas',
  discrete in 'discrete.pas',
  Func_blocks in 'Func_blocks.pas',
  Keys in 'Keys.pas',
  Logs in 'Logs.pas',
  mbty_std_consts in 'mbty_std_consts.pas',
  Nonlines in 'Nonlines.pas',
  Operations in 'Operations.pas',
  src in 'src.pas',
  Stat_Blocks in 'Stat_Blocks.pas',
  Timers in 'Timers.pas',
  trigger in 'trigger.pas',
  Vectors in 'Vectors.pas',
  uOptimizers in 'uOptimizers.pas',
  InterpolationBlocks in 'InterpolationBlocks.pas',
  Keybrd in 'Keybrd.pas',
  NewNDInterpol in 'NewNDInterpol.pas',
  TExtArray_Utils in 'TExtArray_Utils.pas',
  Unit_TFromTable2dNew in 'Unit_TFromTable2dNew.pas';

{$R *.res}

  //Эта функция возвращает адрес структуры DllInfo
function  GetEntry:Pointer;
begin
  Result:=@DllInfo;
end;

exports
  GetEntry name 'GetEntry',                               //Функция получения адреса структуры DllInfo
  CreateObject name 'CreateObject';                       //Функция создания объекта

begin
end.
