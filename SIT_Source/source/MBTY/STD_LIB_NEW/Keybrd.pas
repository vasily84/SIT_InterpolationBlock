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
    VK_keys: string;
    VK_codes: TIntArray;
  public
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
  end;

///////////////////////////////////////////////////////////////////////////////

implementation

uses System.UITypes;

constructor TUserKeybrd.Create;
begin
  inherited;
  vk_codes := TIntArray.Create(1);
end;

destructor  TUserKeybrd.Destroy;
begin
  //
  FreeAndNil(vk_codes);
  inherited;
end;

function VkStringToCode(k: string): SmallInt;
// возвращает численный код виртуальной клавиши
var
  keyLabel:string;

procedure testKeyLabel(val1,val2:string; Num: Byte);
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

  // Virtual Keys, Standard Set
  testKeyLabel('VK_LBUTTON', 'vkLButton', vkLButton);  //1
  testKeyLabel('VK_RBUTTON', 'vkRButton', vkRButton); //2
  testKeyLabel('VK_CANCEL','vkCancel', vkCancel); //3
  testKeyLabel('VK_MBUTTON','vkMButton', vkMButton); //4  // NOT contiguous with L & RBUTTON
  testKeyLabel('VK_XBUTTON1', 'vkXButton1', vkXButton1); //5
  testKeyLabel('VK_XBUTTON2', 'vkXButton2', vkXButton2); //6
  testKeyLabel('VK_BACK', 'vkBack', vkBack); //8
  testKeyLabel('VK_TAB', 'vkTab', vkTab); //9
  testKeyLabel('VK_CLEAR', 'vkClear', vkClear); //12
  testKeyLabel('VK_RETURN', 'vkReturn', vkReturn); //13
  testKeyLabel('VK_SHIFT', 'vkShift', vkShift); // $10, 16
  testKeyLabel('VK_CONTROL', 'vkControl', vkControl); //17
  testKeyLabel('VK_MENU', 'vkMenu', vkMenu); //18
  testKeyLabel('VK_PAUSE', 'vkPause', vkPause); //19
  testKeyLabel('VK_CAPITAL', 'vkCapital', vkCapital); //20
  testKeyLabel('VK_KANA', 'vkKana', vkKana); //21
  testKeyLabel('VK_HANGUL', 'vkHangul', vkHangul); //22
  testKeyLabel('VK_JUNJA', 'vkJunja', vkJunja); //23
  testKeyLabel('VK_FINAL', 'vkFinal', vkFinal); //24
  testKeyLabel('VK_HANJA', 'vkHanja', vkHanja); //25
  testKeyLabel('VK_KANJI', 'vkKanji', vkKanji); //26
  testKeyLabel('VK_CONVERT', 'vkConvert', vkConvert); //28
  testKeyLabel('VK_NONCONVERT', 'vkNonConvert', vkNonConvert); //29
  testKeyLabel('VK_ACCEPT', 'vkAccept', vkAccept); //30
  testKeyLabel('VK_MODECHANGE', 'vkModeChange', vkModeChange); //31
  testKeyLabel('VK_ESCAPE', 'vkEscape', vkEscape); //27
  testKeyLabel('VK_SPACE', 'vkSpace', vkSpace); // $20
  testKeyLabel('VK_PRIOR', 'vkPrior', vkPrior); //33
  testKeyLabel('VK_NEXT', 'vkNext', vkNext); //34
  testKeyLabel('VK_END', 'vkEnd', vkEnd); //35
  testKeyLabel('VK_HOME', 'vkHome', vkHome); //35
  testKeyLabel('VK_LEFT', 'vkLeft', vkLeft); //37
  testKeyLabel('VK_UP', 'vkUp', vkUp); //38
  testKeyLabel('VK_RIGHT', 'vkRight', vkRight); //39
  testKeyLabel('VK_DOWN', 'vkDown', vkDown); //40
  testKeyLabel('VK_SELECT', 'vkSelect', vkSelect); //41
  testKeyLabel('VK_PRINT', 'vkPrint', vkPrint); //42
  testKeyLabel('VK_EXECUTE', 'vkExecute', vkExecute); //43
  testKeyLabel('VK_SNAPSHOT', 'vkSnapShot', vkSnapShot); //44
  testKeyLabel('VK_INSERT', 'vkInsert', vkInsert); //45
  testKeyLabel('VK_DELETE', 'vkDelete', vkDelete); //46
  testKeyLabel('VK_HELP', 'vkHelp', vkHelp); //47' +

// VK_0 thru VK_9 are the same as ASCII '0' thru '9' ($30 - $39)
// VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' ($41 - $5A) }

  testKeyLabel('VK_LWIN','vkLWin', vkLWin); //91
  testKeyLabel('VK_RWIN', 'vkRWin', vkRWin); //92
  testKeyLabel('VK_APPS', 'vkApps', vkApps); //93
  testKeyLabel('VK_SLEEP', 'vkSleep', vkSleep); //95
  testKeyLabel('VK_NUMPAD0', 'vkNumpad0', vkNumpad0); //96
  testKeyLabel('VK_NUMPAD1', 'vkNumpad1', vkNumpad1); //97
  testKeyLabel('VK_NUMPAD2', 'vkNumpad2', vkNumpad2); //98
  testKeyLabel('VK_NUMPAD3', 'vkNumpad3', vkNumpad3); //99
  testKeyLabel('VK_NUMPAD4', 'vkNumpad4', vkNumpad4); //100
  testKeyLabel('VK_NUMPAD5', 'vkNumpad5', vkNumpad5); //101
  testKeyLabel('VK_NUMPAD6', 'vkNumpad6', vkNumpad6); //102
  testKeyLabel('VK_NUMPAD7', 'vkNumpad7', vkNumpad7); //103
  testKeyLabel('VK_NUMPAD8', 'vkNumpad8', vkNumpad8); //104
  testKeyLabel('VK_NUMPAD9', 'vkNumpad9', vkNumpad9); //105
  testKeyLabel('VK_MULTIPLY', 'vkMultiply', vkMultiply); //106
  testKeyLabel('VK_ADD', 'vkAdd', vkAdd); //107
  testKeyLabel('VK_SEPARATOR', 'vkSeparator', vkSeparator); //108
  testKeyLabel('VK_SUBTRACT', 'vkSubtract', vkSubtract); //109
  testKeyLabel('VK_DECIMAL', 'vkDecimal', vkDecimal); //110
  testKeyLabel('VK_DIVIDE', 'vkDivide', vkDivide); //111


  //
  testKeyLabel('VK_F1', 'vkF1', vkF1); //112
  testKeyLabel('VK_F2', 'vkF2', vkF2); //113
  testKeyLabel('VK_F3', 'vkF3', vkF3); //114
  testKeyLabel('VK_F4', 'vkF4', vkF4); //115
  testKeyLabel('VK_F5', 'vkF5', vkF5); //116
  testKeyLabel('VK_F6', 'vkF6', vkF6); //117
  testKeyLabel('VK_F7', 'vkF7', vkF7); //118
  testKeyLabel('VK_F8', 'vkF8', vkF8); //119
  testKeyLabel('VK_F9', 'vkF9', vkF9); //120
  testKeyLabel('VK_F10', 'vkF10', vkF10); //121
  testKeyLabel('VK_F11', 'vkF11', vkF11); //122
  testKeyLabel('VK_F12', 'vkF12', vkF12); //123
  testKeyLabel('VK_F13', 'vkF13', vkF13); //124
  testKeyLabel('VK_F14', 'vkF14', vkF14); //125
  testKeyLabel('VK_F15', 'vkF15', vkF15); //126
  testKeyLabel('VK_F16', 'vkF16', vkF16); //127
  testKeyLabel('VK_F17', 'vkF17', vkF17); //128
  testKeyLabel('VK_F18', 'vkF18', vkF18); //129
  testKeyLabel('VK_F19', 'vkF19', vkF19); //130
  testKeyLabel('VK_F20', 'vkF20', vkF20); //131
  testKeyLabel('VK_F21', 'vkF21', vkF21); //132
  testKeyLabel('VK_F22', 'vkF22', vkF22); //133
  testKeyLabel('VK_F23', 'vkF23', vkF23); //134
  testKeyLabel('VK_F24', 'vkF24', vkF24); //135
  testKeyLabel('VK_NUMLOCK', 'vkNumLock', vkNumLock); //144
  testKeyLabel('VK_SCROLL', 'vkScroll', vkScroll); //145

// VK_L & VK_R - left and right Alt, Ctrl and Shift virtual keys.
//  Used only as parameters to GetAsyncKeyState() and GetKeyState().
//  No other API or message will distinguish left and right keys in this way.
  testKeyLabel('VK_LSHIFT', 'vkLShift', vkLShift); //160
  testKeyLabel('VK_RSHIFT', 'vkRShift', vkRShift); //161
  testKeyLabel('VK_LCONTROL', 'vkLControl', vkLControl); //162
  testKeyLabel('VK_RCONTROL', 'vkRControl', vkRControl); //163
  testKeyLabel('VK_LMENU', 'vkLMenu', vkLMenu); //163
  testKeyLabel('VK_RMENU', 'vkRMenu', vkRMenu); //165

  //
  testKeyLabel('VK_BROWSER_BACK', 'VK_BROWSER_BACK', VK_BROWSER_BACK);// 166;
  testKeyLabel('VK_BROWSER_FORWARD', 'VK_BROWSER_FORWARD', VK_BROWSER_FORWARD);// 167;
  testKeyLabel('VK_BROWSER_REFRESH', 'VK_BROWSER_REFRESH', VK_BROWSER_REFRESH);// 168;
  testKeyLabel('VK_BROWSER_STOP', 'VK_BROWSER_STOP', VK_BROWSER_STOP);// 169;
  testKeyLabel('VK_BROWSER_SEARCH', 'VK_BROWSER_SEARCH', VK_BROWSER_SEARCH);// 170;
  testKeyLabel('VK_BROWSER_FAVORITES', 'VK_BROWSER_FAVORITES', VK_BROWSER_FAVORITES);// 171;
  testKeyLabel('VK_BROWSER_HOME', 'VK_BROWSER_HOME', VK_BROWSER_HOME);// 172;
  testKeyLabel('VK_VOLUME_MUTE', 'VK_VOLUME_MUTE', VK_VOLUME_MUTE);// 173;
  testKeyLabel('VK_VOLUME_DOWN', 'VK_VOLUME_DOWN', VK_VOLUME_DOWN);// 174;
  testKeyLabel('VK_VOLUME_UP', 'VK_VOLUME_UP', VK_VOLUME_UP);// 175;
  testKeyLabel('VK_MEDIA_NEXT_TRACK', 'VK_MEDIA_NEXT_TRACK', VK_MEDIA_NEXT_TRACK);// 176;
  testKeyLabel('VK_MEDIA_PREV_TRACK', 'VK_MEDIA_PREV_TRACK', VK_MEDIA_PREV_TRACK);// 177;
  testKeyLabel('VK_MEDIA_STOP', 'VK_MEDIA_STOP', VK_MEDIA_STOP);// 178;
  testKeyLabel('VK_MEDIA_PLAY_PAUSE', 'VK_MEDIA_PLAY_PAUSE', VK_MEDIA_PLAY_PAUSE);// 179;
  testKeyLabel('VK_LAUNCH_MAIL', 'VK_LAUNCH_MAIL', VK_LAUNCH_MAIL);// 180;
  testKeyLabel('VK_LAUNCH_MEDIA_SELECT', 'VK_LAUNCH_MEDIA_SELECT', VK_LAUNCH_MEDIA_SELECT);// 181;
  testKeyLabel('VK_LAUNCH_APP1', 'VK_LAUNCH_APP1', VK_LAUNCH_APP1);// 182;
  testKeyLabel('VK_LAUNCH_APP2', 'VK_LAUNCH_APP2', VK_LAUNCH_APP2);// 183;

  //
  testKeyLabel('VK_OEM_1', 'VK_OEM_1', VK_OEM_1);// 186;
  testKeyLabel('VK_OEM_PLUS', 'VK_OEM_PLUS', VK_OEM_PLUS);// 187;
  testKeyLabel('VK_OEM_COMMA', 'VK_OEM_COMMA', VK_OEM_COMMA);// 188;
  testKeyLabel('VK_OEM_MINUS', 'VK_OEM_MINUS', VK_OEM_MINUS);// 189;
  testKeyLabel('VK_OEM_PERIOD', 'VK_OEM_PERIOD', VK_OEM_PERIOD);// 190;
  testKeyLabel('VK_OEM_2', 'VK_OEM_2', VK_OEM_2);// 191;
  testKeyLabel('VK_OEM_3', 'VK_OEM_3', VK_OEM_3);// 192;
  testKeyLabel('VK_OEM_4', 'VK_OEM_4', VK_OEM_4);// 219;
  testKeyLabel('VK_OEM_5', 'VK_OEM_5', VK_OEM_5);// 220;
  testKeyLabel('VK_OEM_6', 'VK_OEM_6', VK_OEM_6);// 221;
  testKeyLabel('VK_OEM_7', 'VK_OEM_7', VK_OEM_7);// 222;
  testKeyLabel('VK_OEM_8', 'VK_OEM_8', VK_OEM_8);// 223;
  testKeyLabel('VK_OEM_102', 'VK_OEM_102', VK_OEM_102);// 226;
  testKeyLabel('VK_PACKET', 'VK_PACKET', VK_PACKET);// 231
  //
  testKeyLabel('VK_PROCESSKEY', 'vkProcessKey', vkProcessKey); //229
  testKeyLabel('VK_ATTN', 'vkAttn', vkAttn); //246
  testKeyLabel('VK_CRSEL', 'vkCrsel', vkCrsel); //247
  testKeyLabel('VK_EXSEL', 'vkExsel', vkExsel); //248
  testKeyLabel('VK_EREOF', 'vkErEof', vkErEof); //249
  testKeyLabel('VK_PLAY', 'vkPlay', vkPlay); //250
  testKeyLabel('VK_ZOOM', 'vkZoom', vkZoom); //251
  testKeyLabel('VK_NONAME', 'vkNoName', vkNoName); //252
  testKeyLabel('VK_PA1', 'vkPA1', vkPA1); //253
  testKeyLabel('VK_OEM_CLEAR', 'vkOemClear', vkOemClear); //254

end;
//===========================================================================

function TUserKeybrd.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
var
  StrList: TStringList;
  i,arr1count: Integer;
  arr1: array[0..255] of SmallInt;
  str1: string;
  code1: SmallInt;
begin
  Result:=r_Success;

  case Action of
      i_GetCount:
        begin
          //cY[0].Dim:=SetDim([VK_codes.Count]);

          StrList := TStringList.Create;
          StrList.Delimiter       := ',';
          StrList.StrictDelimiter := True;
          StrList.DelimitedText   := VK_keys;

          arr1count:=0;

          for i := 0 to StrList.Count-1 do begin
            str1 := Trim(StrList.Strings[i]);
            if str1='' then begin
              ErrorEvent('",," встречено в форматной строке блока UserKeybrd. Используйте vk_space для указания клавиши пробела',msError,VisualObject);
              Result:=r_Fail;
              exit;
              end;

            code1 := VkStringToCode(str1); // берем численный код виртуальной клавиши из ее названия
            if code1<>0 then begin
              arr1[arr1count] := code1;
              Inc(arr1count);
              end;
            end;

          vk_codes.ChangeCount(arr1count);
          for i:=0 to arr1count-1 do begin
            vk_codes[i] := arr1[i];
            end;

          cY[0].Dim:=SetDim([VK_codes.Count]);
          FreeAndNil(StrList);
        end
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

function TUserKeybrd.RunFunc(var at,h : RealType;Action:Integer):NativeInt;
var
  keyResult: SmallInt;
  i: Integer;
// непонятки с NeedRemoteData - управление из базы сигналов или других частей программы? Выяснить
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

  if StrEqu(ParamName,'VK_keys') then begin
    Result:=NativeInt(@VK_keys);
    DataType:=dtString;
    exit;
  end;

  ErrorEvent('параметр '+ParamName+' в блоке UserKeybrd не найден', msWarning, VisualObject);
end;

//===========================================================================

////////////////////////////////////////////////////////////////////////////////
end.
