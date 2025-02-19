//**************************************************************************//
 // Данный исходный код является составной частью системы МВТУ-4             //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit Keybrd;

 //***************************************************************************//
 //                Блок ввода с клавиатуры
 //***************************************************************************//

interface

uses {$IFNDEF FPC}Windows,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts, Math, LinFuncs,
     tbls, Data_blocks, InterpolFuncs, mbty_std_consts, uExtMath, InterpolationBlocks_unit,InterpolationBlocks_unit_tests;


type
/////////////////////////////////////////////////////////////////////////////
// блок ввода с клавиатуры
  TUserKeybrd = class(TRunObject)
  protected
    KeysSet: TMultiSelect; // МНОЖЕСТВО строковых названий клавиш, которые мы долны опросить - св-во Объекта
    VK_codes: TIntArray; // численные виртуальные коды опрашиваемых клавиш
  public
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
  end;

///////////////////////////////////////////////////////////////////////////////

implementation

uses System.UITypes, RealArrays, IntArrays;

constructor TUserKeybrd.Create;
begin
  inherited;
  vk_codes := TIntArray.Create(1);
  KeysSet := TMultiSelect.Create(Self);
end;

destructor  TUserKeybrd.Destroy;
begin
  FreeAndNil(vk_codes);
  FreeAndNil(KeysSet);
  inherited;
end;

function VkStringToCode(k: string): SmallInt;
// возвращает численный код виртуальной клавиши
var
  keyLabel:string;

procedure checkKeyLabel(val1, val2: string; Num: Byte);
begin
  if ((keyLabel=UpperCase(val1))or((keyLabel= UpperCase(val2)))) then begin
    Result := Num;
    end;
end;

var
  b: Byte;
begin
  Result := 0; // виртуальной клавиши с кодом ноль нет. Значит - ничего не нашли
  keyLabel := UpperCase(Trim(k));

  // это цифра или буква
  if Length(keyLabel)=1 then begin
    b := ORD(keyLabel[1]);
    if (((b>=vk0)and(b<=vk9))or((b>=vkA)and(b<=vkZ))) then begin
      Result:=b;
      exit;
      end;
    end;

  // Virtual Keys, Standard Set, см. Microsoft Windows SDK
  checkKeyLabel('VK_LBUTTON', 'ЛКМ', vkLButton);  //1
  checkKeyLabel('VK_RBUTTON', 'ПКМ', vkRButton); //2
  checkKeyLabel('VK_CANCEL','vkCancel', vkCancel); //3
  checkKeyLabel('VK_MBUTTON','vkMButton', vkMButton); //4  // NOT contiguous with L & RBUTTON
  checkKeyLabel('VK_XBUTTON1', 'vkXButton1', vkXButton1); //5
  checkKeyLabel('VK_XBUTTON2', 'vkXButton2', vkXButton2); //6
  checkKeyLabel('VK_BACK', 'Backspace', vkBack); //8
  checkKeyLabel('VK_TAB', 'Tab', vkTab); //9
  checkKeyLabel('VK_CLEAR', 'vkClear', vkClear); //12
  checkKeyLabel('VK_RETURN', 'ВВОД', vkReturn); //13
    checkKeyLabel('VK_RETURN', 'Enter', vkReturn); //13
  checkKeyLabel('VK_SHIFT', 'Shift', vkShift); // $10, 16
  checkKeyLabel('VK_CONTROL', 'Ctrl', vkControl); //17
  checkKeyLabel('VK_MENU', 'Menu', vkMenu); //18
  checkKeyLabel('VK_PAUSE', 'vkPause', vkPause); //19
  checkKeyLabel('VK_CAPITAL', 'Caps Lock', vkCapital); //20
  checkKeyLabel('VK_KANA', 'vkKana', vkKana); //21
  checkKeyLabel('VK_HANGUL', 'vkHangul', vkHangul); //22
  checkKeyLabel('VK_JUNJA', 'vkJunja', vkJunja); //23
  checkKeyLabel('VK_FINAL', 'vkFinal', vkFinal); //24
  checkKeyLabel('VK_HANJA', 'vkHanja', vkHanja); //25
  checkKeyLabel('VK_KANJI', 'vkKanji', vkKanji); //26
  checkKeyLabel('VK_CONVERT', 'vkConvert', vkConvert); //28
  checkKeyLabel('VK_NONCONVERT', 'vkNonConvert', vkNonConvert); //29
  checkKeyLabel('VK_ACCEPT', 'vkAccept', vkAccept); //30
  checkKeyLabel('VK_MODECHANGE', 'vkModeChange', vkModeChange); //31
  checkKeyLabel('VK_ESCAPE', 'Esc', vkEscape); //27
  checkKeyLabel('VK_SPACE', 'ПРОБЕЛ', vkSpace); // $20
  checkKeyLabel('VK_PRIOR', 'Page Up', vkPrior); //33
  checkKeyLabel('VK_NEXT', 'Page Down', vkNext); //34
  checkKeyLabel('VK_END', 'End', vkEnd); //35
  checkKeyLabel('VK_HOME', 'Home', vkHome); //35
  checkKeyLabel('VK_LEFT', 'СТРЕЛКА ЛЕВ', vkLeft); //37
  checkKeyLabel('VK_UP', 'СТРЕЛКА ВЕРХ', vkUp); //38
  checkKeyLabel('VK_RIGHT', 'СТРЕЛКА ПРАВ', vkRight); //39
  checkKeyLabel('VK_DOWN', 'СТРЕЛКА НИЗ', vkDown); //40
  checkKeyLabel('VK_SELECT', 'vkSelect', vkSelect); //41
  checkKeyLabel('VK_PRINT', 'vkPrint', vkPrint); //42
  checkKeyLabel('VK_EXECUTE', 'vkExecute', vkExecute); //43
  checkKeyLabel('VK_SNAPSHOT', 'vkSnapShot', vkSnapShot); //44
  checkKeyLabel('VK_INSERT', 'Insert', vkInsert); //45
  checkKeyLabel('VK_DELETE', 'Delete', vkDelete); //46
  checkKeyLabel('VK_HELP', 'vkHelp', vkHelp); //47' +

// VK_0 thru VK_9 are the same as ASCII '0' thru '9' ($30 - $39)
// VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' ($41 - $5A) }

  checkKeyLabel('VK_LWIN','Win ЛЕВ', vkLWin); //91
  checkKeyLabel('VK_RWIN', 'Win ПРАВ', vkRWin); //92
  checkKeyLabel('VK_APPS', 'vkApps', vkApps); //93
  checkKeyLabel('VK_SLEEP', 'vkSleep', vkSleep); //95
  checkKeyLabel('VK_NUMPAD0', 'vkNumpad0', vkNumpad0); //96
  checkKeyLabel('VK_NUMPAD1', 'vkNumpad1', vkNumpad1); //97
  checkKeyLabel('VK_NUMPAD2', 'vkNumpad2', vkNumpad2); //98
  checkKeyLabel('VK_NUMPAD3', 'vkNumpad3', vkNumpad3); //99
  checkKeyLabel('VK_NUMPAD4', 'vkNumpad4', vkNumpad4); //100
  checkKeyLabel('VK_NUMPAD5', 'vkNumpad5', vkNumpad5); //101
  checkKeyLabel('VK_NUMPAD6', 'vkNumpad6', vkNumpad6); //102
  checkKeyLabel('VK_NUMPAD7', 'vkNumpad7', vkNumpad7); //103
  checkKeyLabel('VK_NUMPAD8', 'vkNumpad8', vkNumpad8); //104
  checkKeyLabel('VK_NUMPAD9', 'vkNumpad9', vkNumpad9); //105
  checkKeyLabel('VK_MULTIPLY', 'vkMultiply', vkMultiply); //106
  checkKeyLabel('VK_ADD', 'vkAdd', vkAdd); //107
  checkKeyLabel('VK_SEPARATOR', 'vkSeparator', vkSeparator); //108
  checkKeyLabel('VK_SUBTRACT', 'vkSubtract', vkSubtract); //109
  checkKeyLabel('VK_DECIMAL', 'vkDecimal', vkDecimal); //110
  checkKeyLabel('VK_DIVIDE', 'vkDivide', vkDivide); //111
  checkKeyLabel('VK_F1', 'F1', vkF1); //112
  checkKeyLabel('VK_F2', 'F2', vkF2); //113
  checkKeyLabel('VK_F3', 'F3', vkF3); //114
  checkKeyLabel('VK_F4', 'F4', vkF4); //115
  checkKeyLabel('VK_F5', 'F5', vkF5); //116
  checkKeyLabel('VK_F6', 'F6', vkF6); //117
  checkKeyLabel('VK_F7', 'F7', vkF7); //118
  checkKeyLabel('VK_F8', 'F8', vkF8); //119
  checkKeyLabel('VK_F9', 'F9', vkF9); //120
  checkKeyLabel('VK_F10', 'F10', vkF10); //121
  checkKeyLabel('VK_F11', 'F11', vkF11); //122
  checkKeyLabel('VK_F12', 'F12', vkF12); //123
  checkKeyLabel('VK_F13', 'F13', vkF13); //124
  checkKeyLabel('VK_F14', 'F14', vkF14); //125
  checkKeyLabel('VK_F15', 'F15', vkF15); //126
  checkKeyLabel('VK_F16', 'F16', vkF16); //127
  checkKeyLabel('VK_F17', 'F17', vkF17); //128
  checkKeyLabel('VK_F18', 'F18', vkF18); //129
  checkKeyLabel('VK_F19', 'F19', vkF19); //130
  checkKeyLabel('VK_F20', 'F20', vkF20); //131
  checkKeyLabel('VK_F21', 'F21', vkF21); //132
  checkKeyLabel('VK_F22', 'F22', vkF22); //133
  checkKeyLabel('VK_F23', 'F23', vkF23); //134
  checkKeyLabel('VK_F24', 'F24', vkF24); //135
  checkKeyLabel('VK_NUMLOCK', 'Num Lock', vkNumLock); //144
  checkKeyLabel('VK_SCROLL', 'Scroll Lock', vkScroll); //145

{
// исключили эту часть кодов, ибо нет уверенности что  она работает единообразно в Windows, Linux, RaspberryPi
// но удалять этот комментарий тоже не нужно - при кастомизации под конретную ОС он точно пригодится

// VK_L & VK_R - left and right Alt, Ctrl and Shift virtual keys.
//  Used only as parameters to GetAsyncKeyState() and GetKeyState().
//  No other API or message will distinguish left and right keys in this way.
  checkKeyLabel('VK_LSHIFT', 'Shift ЛЕВ', vkLShift); //160
  checkKeyLabel('VK_RSHIFT', 'Shift ПРАВ', vkRShift); //161
  checkKeyLabel('VK_LCONTROL', 'Ctrl ЛЕВ', vkLControl); //162
  checkKeyLabel('VK_RCONTROL', 'Ctrl ПРАВ', vkRControl); //163
  checkKeyLabel('VK_LMENU', 'Menu ЛЕВ', vkLMenu); //163
  checkKeyLabel('VK_RMENU', 'Menu ПРАВ', vkRMenu); //165

  //
  checkKeyLabel('VK_BROWSER_BACK', 'VK_BROWSER_BACK', VK_BROWSER_BACK);// 166;
  checkKeyLabel('VK_BROWSER_FORWARD', 'VK_BROWSER_FORWARD', VK_BROWSER_FORWARD);// 167;
  checkKeyLabel('VK_BROWSER_REFRESH', 'VK_BROWSER_REFRESH', VK_BROWSER_REFRESH);// 168;
  checkKeyLabel('VK_BROWSER_STOP', 'VK_BROWSER_STOP', VK_BROWSER_STOP);// 169;
  checkKeyLabel('VK_BROWSER_SEARCH', 'VK_BROWSER_SEARCH', VK_BROWSER_SEARCH);// 170;
  checkKeyLabel('VK_BROWSER_FAVORITES', 'VK_BROWSER_FAVORITES', VK_BROWSER_FAVORITES);// 171;
  checkKeyLabel('VK_BROWSER_HOME', 'VK_BROWSER_HOME', VK_BROWSER_HOME);// 172;
  checkKeyLabel('VK_VOLUME_MUTE', 'VK_VOLUME_MUTE', VK_VOLUME_MUTE);// 173;
  checkKeyLabel('VK_VOLUME_DOWN', 'VK_VOLUME_DOWN', VK_VOLUME_DOWN);// 174;
  checkKeyLabel('VK_VOLUME_UP', 'VK_VOLUME_UP', VK_VOLUME_UP);// 175;
  checkKeyLabel('VK_MEDIA_NEXT_TRACK', 'VK_MEDIA_NEXT_TRACK', VK_MEDIA_NEXT_TRACK);// 176;
  checkKeyLabel('VK_MEDIA_PREV_TRACK', 'VK_MEDIA_PREV_TRACK', VK_MEDIA_PREV_TRACK);// 177;
  checkKeyLabel('VK_MEDIA_STOP', 'VK_MEDIA_STOP', VK_MEDIA_STOP);// 178;
  checkKeyLabel('VK_MEDIA_PLAY_PAUSE', 'VK_MEDIA_PLAY_PAUSE', VK_MEDIA_PLAY_PAUSE);// 179;
  checkKeyLabel('VK_LAUNCH_MAIL', 'VK_LAUNCH_MAIL', VK_LAUNCH_MAIL);// 180;
  checkKeyLabel('VK_LAUNCH_MEDIA_SELECT', 'VK_LAUNCH_MEDIA_SELECT', VK_LAUNCH_MEDIA_SELECT);// 181;
  checkKeyLabel('VK_LAUNCH_APP1', 'VK_LAUNCH_APP1', VK_LAUNCH_APP1);// 182;
  checkKeyLabel('VK_LAUNCH_APP2', 'VK_LAUNCH_APP2', VK_LAUNCH_APP2);// 183;

  //
  checkKeyLabel('VK_OEM_1', 'VK_OEM_1', VK_OEM_1);// 186;
  checkKeyLabel('VK_OEM_PLUS', 'VK_OEM_PLUS', VK_OEM_PLUS);// 187;
  checkKeyLabel('VK_OEM_COMMA', 'VK_OEM_COMMA', VK_OEM_COMMA);// 188;
  checkKeyLabel('VK_OEM_MINUS', 'VK_OEM_MINUS', VK_OEM_MINUS);// 189;
  checkKeyLabel('VK_OEM_PERIOD', 'VK_OEM_PERIOD', VK_OEM_PERIOD);// 190;
  checkKeyLabel('VK_OEM_2', 'VK_OEM_2', VK_OEM_2);// 191;
  checkKeyLabel('VK_OEM_3', 'VK_OEM_3', VK_OEM_3);// 192;
  checkKeyLabel('VK_OEM_4', 'VK_OEM_4', VK_OEM_4);// 219;
  checkKeyLabel('VK_OEM_5', 'VK_OEM_5', VK_OEM_5);// 220;
  checkKeyLabel('VK_OEM_6', 'VK_OEM_6', VK_OEM_6);// 221;
  checkKeyLabel('VK_OEM_7', 'VK_OEM_7', VK_OEM_7);// 222;
  checkKeyLabel('VK_OEM_8', 'VK_OEM_8', VK_OEM_8);// 223;
  checkKeyLabel('VK_OEM_102', 'VK_OEM_102', VK_OEM_102);// 226;
  checkKeyLabel('VK_PACKET', 'VK_PACKET', VK_PACKET);// 231
  //
  checkKeyLabel('VK_PROCESSKEY', 'vkProcessKey', vkProcessKey); //229
  checkKeyLabel('VK_ATTN', 'vkAttn', vkAttn); //246
  checkKeyLabel('VK_CRSEL', 'vkCrsel', vkCrsel); //247
  checkKeyLabel('VK_EXSEL', 'vkExsel', vkExsel); //248
  checkKeyLabel('VK_EREOF', 'vkErEof', vkErEof); //249
  checkKeyLabel('VK_PLAY', 'vkPlay', vkPlay); //250
  checkKeyLabel('VK_ZOOM', 'vkZoom', vkZoom); //251
  checkKeyLabel('VK_NONAME', 'vkNoName', vkNoName); //252
  checkKeyLabel('VK_PA1', 'vkPA1', vkPA1); //253
  checkKeyLabel('VK_OEM_CLEAR', 'vkOemClear', vkOemClear); //254
}
end;
//===========================================================================

function TUserKeybrd.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
var
  slist1: TStringList;
  i,j: Integer;
  str1: string;
begin
  Result:=r_Success;

  case Action of
      i_GetCount:
        begin
          slist1 := TStringList.Create;
          slist1.LineBreak := #13#10;
          slist1.Text := KeysSet.Items;

          // проверка, что все имена клавиш заданы верно
          for j:=0 to slist1.Count-1 do begin
            str1 := slist1.Strings[j];
            if VkStringToCode(str1)=0 then begin
              ErrorEvent('Значение клавиши "'+str1+'" не определено в UserKeybrd',msError,VisualObject);
              Result:=r_Fail;
              FreeAndNil(slist1);
              exit;
              end;
            end;

          vk_codes.ChangeCount(Length(KeysSet.Selection));

          for i:=0 to Length(KeysSet.Selection)-1 do begin
            str1 := slist1.Strings[KeysSet.Selection[i]];
            vk_codes[i] := VkStringToCode(str1);
            end;

          cY[0].Dim:=SetDim([VK_codes.Count]);

          if Length(KeysSet.Selection)=0 then begin
            ErrorEvent('Блок клавиатурного ввода не опрашивает ни одной клавиши',msError,VisualObject);
            end;

          FreeAndNil(slist1);
        end
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function TUserKeybrd.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var
  keyResult: SmallInt;
  i: Integer;
begin
  Result:=0;
  case Action of
    f_InitState,
    f_RestoreOuts,
    f_UpdateOuts,
    f_UpdateJacoby,
    f_GoodStep:
                  for i:=0 to vk_codes.Count-1 do begin
                    keyResult := GetAsyncKeyState(ShortInt(vk_codes[i]));
                    if keyResult<>0 then Y[0][i] := 1.
                                    else Y[0][i] := 0.;
                    end;
  end
end;

function TUserKeybrd.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result := inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

  if StrEqu(ParamName,'KeysSet') then begin
      Result:=NativeInt(KeysSet);
      DataType:=dtMultiSelect;
      exit;
    end;

  ErrorEvent('параметр '+ParamName+' в блоке UserKeybrd не найден', msWarning, VisualObject);
end;

//===========================================================================

////////////////////////////////////////////////////////////////////////////////
end.
