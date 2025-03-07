﻿//**************************************************************************//
// Данный исходный код является составной частью системы SimInTech         //
//*************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

unit Keybrd;

 //***************************************************************************//
 //                Блок ввода с клавиатуры
 //***************************************************************************//

interface

uses {$IFNDEF FPC}Windows,{$ELSE}x,xlib,keysym,{$ENDIF}
     Classes, MBTYArrays, DataTypes, DataObjts, SysUtils, abstract_im_interface, RunObjts,
     mbty_std_consts;

{$IFDEF FPC}
// опрос клавиатуры под Линух на основе Xlib
type TGlobalKbrd = class(TObject)
  public
    dpy: PXDisplay;
    keys_return:chararr32;
    countRef: Integer;
    procedure refresh;
    function isKeyPressed(ASym: TKeySym):Boolean;
    constructor Create;
    destructor Destroy;override;
end;
{$ENDIF}

type
/////////////////////////////////////////////////////////////////////////////
// блок ввода с клавиатуры
  TUserKeybrd = class(TRunObject)
  protected
    property_KeySet: TMultiSelect; // МНОЖЕСТВО строковых названий клавиш, которые мы долны опросить - св-во Объекта
    keyCodesArray: TIntArray; // численные виртуальные коды опрашиваемых клавиш
    // ФУНКЦИЯ ДЛЯ ОТЛАДКИ - проверить, что каждой клавише в property_keySet присвоен код
    function testKeySetAssignment(slist1: TStringList): Boolean;
  public
    function       InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;override;
    function       RunFunc(var at,h : RealType;Action:Integer):NativeInt;override;
    function       GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;override;
    constructor    Create(Owner: TObject);override;
    destructor     Destroy;override;
  end;

/////////////////////////////////////////////////////////////////////////////
{$IFDEF FPC}
var
   kbrd: TGlobalKbrd = nil;
{$ENDIF}
implementation
uses RealArrays, IntArrays;

const
{$IFNDEF ENG}
  txtKeyUnknown1 = 'Значение клавиши "';
  txtKeyUnknown2 = '" не определено';
  txtUselessKeyboard = 'Блок клавиатурного ввода не опрашивает ни одной клавиши';
  txtParamUnknown1 = 'параметр "';
  txtParamUnknown2 = '" в блоке не найден';
{$ELSE}
  txtKeyUnknown1 = 'Button labeled "';
  txtKeyUnknown2 = '" is undefined';
  txtUselessKeyboard = 'UserKeyboard block does not poll any button';
  txtParamUnknown1 = 'parameter "';
  txtParamUnknown2 = '" is undefined';
{$ENDIF}

//---------------------------------------------------------------------------------------
{$IFDEF FPC}
constructor TGlobalKbrd.Create;
begin
  dpy := XOpenDisplay(nil);
  countRef:=0;
end;

destructor TGlobalKbrd.Destroy;
begin
  XCloseDisplay(dpy);
end;

procedure TGlobalKbrd.refresh;
begin
  XQueryKeymap(dpy, keys_return);
end;

function TGlobalKbrd.isKeyPressed(ASym: TKeySym):Boolean;
var
  kkL,kkR: TKeySym;
  b1,b2: Byte;
begin
  // карта нажатых клавиш в Xlib - 32 байта последовательно,
  // где номер клавиши соответствует номеру бита
  b1 := Byte(keys_return[Asym div 8]);
  b2 := (1 shl (Asym mod 8));
  Result := (b1 and b2)<>0;

  if Result then exit; // клавиша нажата, все ок, возврат

  // ниже проверки Left/Right для Shift и Cntl - в SIT Windows одна кнопка,
  // без различий Лево-Право. В Линух они разные
  kkL := XkeySymToKeycode(kbrd.dpy,XK_Control_L);
  if kkL=Asym then begin
    kkR := XkeySymToKeycode(kbrd.dpy,XK_Control_R);
    Result:=isKeyPressed(kkR);
    end;

  kkL := XkeySymToKeycode(kbrd.dpy,XK_Shift_L);
  if kkL=Asym then begin
    kkR := XkeySymToKeycode(kbrd.dpy,XK_Shift_R);
    Result:=isKeyPressed(kkR);
    end;
end;
//-------------------------------------------------------------------------------
{$ENDIF}

constructor TUserKeybrd.Create;
begin
  inherited;
  keyCodesArray := TIntArray.Create(1);
  property_KeySet := TMultiSelect.Create(Self);
  {$IFDEF FPC}
  if not Assigned(kbrd) then kbrd := TGlobalKbrd.Create;
  Inc(kbrd.countRef);
  {$ENDIF}
end;

destructor  TUserKeybrd.Destroy;
begin
  FreeAndNil(keyCodesArray);
  FreeAndNil(property_KeySet);
  {$IFDEF FPC}
  if Assigned(kbrd) then begin
    Dec(kbrd.countRef);
    if(kbrd.countRef=0) then FreeAndNil(kbrd);
    end;
  {$ENDIF}
  inherited;
end;

//---------------------------------------------------------------------------
{$IFDEF FPC}
function VkStringToCode(AKeyCaption: string): Integer;
// возвращает численный код виртуальной клавиши по его текстовому названию
// одной клавише может быть назначено несколько названий, например на разных языках
var
  keyLabel: string;

procedure checkKeyLabel(const AValues: array of string; Num: TKeySym);
// присваивает Result численный код клавиши, если ее текстовое имя перечислено в AValues
var
  str1: string;
  i: Integer;
  kk: TKeySym;
begin
  for i:=0 to Length(AValues)-1 do begin
    str1 := Trim(UpperCase(AValues[i]));
    if (keyLabel=str1) then begin
      kk:=XkeySymToKeycode(kbrd.dpy,Num);
      Result := kk;
      exit;
      end;
    end;
end;

begin
  Result := 0; // виртуальной клавиши с кодом нуль нет. Значит - ничего не нашли
  keyLabel := UpperCase(Trim(AKeyCaption));

  // это цифра или буква
  checkKeyLabel(['0'], XK_0);
  checkKeyLabel(['1'], XK_1);
  checkKeyLabel(['2'], XK_2);
  checkKeyLabel(['3'], XK_3);
  checkKeyLabel(['4'], XK_4);
  checkKeyLabel(['5'], XK_5);
  checkKeyLabel(['6'], XK_6);
  checkKeyLabel(['7'], XK_7);
  checkKeyLabel(['8'], XK_8);
  checkKeyLabel(['9'], XK_9);

  checkKeyLabel(['Q'], XK_Q);
  checkKeyLabel(['W'], XK_W);
  checkKeyLabel(['E'], XK_E);
  checkKeyLabel(['R'], XK_R);
  checkKeyLabel(['T'], XK_T);
  checkKeyLabel(['Y'], XK_Y);
  checkKeyLabel(['U'], XK_U);
  checkKeyLabel(['I'], XK_I);
  checkKeyLabel(['O'], XK_O);
  checkKeyLabel(['P'], XK_P);

  checkKeyLabel(['A'], XK_A);
  checkKeyLabel(['S'], XK_S);
  checkKeyLabel(['D'], XK_D);
  checkKeyLabel(['F'], XK_F);
  checkKeyLabel(['G'], XK_G);
  checkKeyLabel(['H'], XK_H);
  checkKeyLabel(['J'], XK_J);
  checkKeyLabel(['K'], XK_K);
  checkKeyLabel(['L'], XK_L);

  checkKeyLabel(['Z'], XK_A);
  checkKeyLabel(['X'], XK_A);
  checkKeyLabel(['C'], XK_A);
  checkKeyLabel(['V'], XK_A);
  checkKeyLabel(['B'], XK_A);
  checkKeyLabel(['N'], XK_A);
  checkKeyLabel(['M'], XK_A);

  checkKeyLabel(['VK_LBUTTON', 'ЛКМ'], XK_Pointer_Left);
  checkKeyLabel(['VK_RBUTTON', 'ПКМ'], XK_Pointer_Right);
  //checkKeyLabel(['VK_CANCEL','vkCancel'], VK_Cancel);
  //checkKeyLabel(['VK_MBUTTON','vkMButton'], VK_MButton);
  //checkKeyLabel(['VK_XBUTTON1', 'vkXButton1'], VK_XButton1);
  //checkKeyLabel(['VK_XBUTTON2', 'vkXButton2'], VK_XButton2);
  checkKeyLabel(['VK_BACK', 'Backspace'], XK_Backspace);
  checkKeyLabel(['VK_TAB', 'Tab'], XK_Tab);
  checkKeyLabel(['VK_CLEAR', 'vkClear'], XK_Clear);
  checkKeyLabel(['VK_RETURN', 'ВВОД','Enter'], XK_Return);

  checkKeyLabel(['VK_SHIFT', 'Shift'], XK_Shift_L);
  checkKeyLabel(['VK_CONTROL', 'Ctrl'], XK_Control_L);
  checkKeyLabel(['VK_MENU', 'Menu'], XK_Menu);
  checkKeyLabel(['VK_PAUSE', 'vkPause'], XK_Pause);
  checkKeyLabel(['VK_CAPITAL', 'Caps Lock'], XK_Caps_Lock);
  //checkKeyLabel(['VK_KANA', 'vkKana'], VK_Kana);
  //checkKeyLabel(['VK_HANGUL', 'vkHangul'], VK_Hangul);
  //checkKeyLabel(['VK_JUNJA', 'vkJunja'], VK_Junja);
  //checkKeyLabel(['VK_FINAL', 'vkFinal'], VK_Final);
  //checkKeyLabel(['VK_HANJA', 'vkHanja'], VK_Hanja);
  //checkKeyLabel(['VK_KANJI', 'vkKanji'], VK_Kanji);
  //checkKeyLabel(['VK_CONVERT', 'vkConvert'], VK_Convert);
  //checkKeyLabel(['VK_NONCONVERT', 'vkNonConvert'], VK_NonConvert);
  //checkKeyLabel(['VK_ACCEPT', 'vkAccept'], VK_Accept);
  //checkKeyLabel(['VK_MODECHANGE', 'vkModeChange'], VK_ModeChange);
  checkKeyLabel(['VK_ESCAPE', 'Esc'], XK_Escape);
  checkKeyLabel(['VK_SPACE', 'ПРОБЕЛ'], XK_Space);
  checkKeyLabel(['VK_PRIOR', 'Page Up'], XK_Prior);
  checkKeyLabel(['VK_NEXT', 'Page Down'], XK_Next);
  checkKeyLabel(['VK_END', 'End'], XK_End);
  checkKeyLabel(['VK_HOME', 'Home'], XK_Home);
  checkKeyLabel(['VK_LEFT', 'СТРЕЛКА ЛЕВ'], XK_Left);
  checkKeyLabel(['VK_UP', 'СТРЕЛКА ВЕРХ'], XK_Up);
  checkKeyLabel(['VK_RIGHT', 'СТРЕЛКА ПРАВ'], XK_Right);
  checkKeyLabel(['VK_DOWN', 'СТРЕЛКА НИЗ'], XK_Down);
  checkKeyLabel(['VK_SELECT', 'vkSelect'], XK_Select);
  checkKeyLabel(['VK_PRINT', 'vkPrint'], XK_Print);
  checkKeyLabel(['VK_EXECUTE', 'vkExecute'], XK_Execute);
  //checkKeyLabel(['VK_SNAPSHOT', 'vkSnapShot'], XK_SnapShot);
  checkKeyLabel(['VK_INSERT', 'Insert'], XK_Insert);
  checkKeyLabel(['VK_DELETE', 'Delete'], XK_Delete);
  checkKeyLabel(['VK_HELP', 'vkHelp'], XK_Help);

  //checkKeyLabel(['VK_LWIN','Win ЛЕВ'], VK_LWin);
  //checkKeyLabel(['VK_RWIN', 'Win ПРАВ'], VK_RWin);
  //checkKeyLabel(['VK_APPS', 'vkApps'], VK_Apps);
  //checkKeyLabel(['VK_SLEEP', 'vkSleep'], VK_Sleep);
  checkKeyLabel(['VK_NUMPAD0', 'Numpad 0'], XK_KP_0);
  checkKeyLabel(['VK_NUMPAD1', 'Numpad 1'], XK_KP_1);
  checkKeyLabel(['VK_NUMPAD2', 'Numpad 2'], XK_KP_2);
  checkKeyLabel(['VK_NUMPAD3', 'Numpad 3'], XK_KP_3);
  checkKeyLabel(['VK_NUMPAD4', 'Numpad 4'], XK_KP_4);
  checkKeyLabel(['VK_NUMPAD5', 'Numpad 5'], XK_KP_5);
  checkKeyLabel(['VK_NUMPAD6', 'Numpad 6'], XK_KP_6);
  checkKeyLabel(['VK_NUMPAD7', 'Numpad 7'], XK_KP_7);
  checkKeyLabel(['VK_NUMPAD8', 'Numpad 8'], XK_KP_8);
  checkKeyLabel(['VK_NUMPAD9', 'Numpad 9'], XK_KP_9);

  //checkKeyLabel(['VK_MULTIPLY', 'vkMultiply'], VK_Multiply); //106
  //checkKeyLabel(['VK_ADD', 'vkAdd'], VK_Add); //107
  //checkKeyLabel(['VK_SEPARATOR', 'vkSeparator'], VK_Separator); //108
  //checkKeyLabel(['VK_SUBTRACT', 'vkSubtract'], VK_Subtract); //109
  //checkKeyLabel(['VK_DECIMAL', 'vkDecimal'], VK_Decimal); //110
  //checkKeyLabel(['VK_DIVIDE', 'vkDivide'], VK_Divide); //111
  checkKeyLabel(['VK_F1', 'F1'], XK_F1);
  checkKeyLabel(['VK_F2', 'F2'], XK_F2);
  checkKeyLabel(['VK_F3', 'F3'], XK_F3);
  checkKeyLabel(['VK_F4', 'F4'], XK_F4);
  checkKeyLabel(['VK_F5', 'F5'], XK_F5);
  checkKeyLabel(['VK_F6', 'F6'], XK_F6);
  checkKeyLabel(['VK_F7', 'F7'], XK_F7);
  checkKeyLabel(['VK_F8', 'F8'], XK_F8);
  checkKeyLabel(['VK_F9', 'F9'], XK_F9);
  checkKeyLabel(['VK_F10', 'F10'], XK_F10);
  checkKeyLabel(['VK_F11', 'F11'], XK_F11);
  checkKeyLabel(['VK_F12', 'F12'], XK_F12);
  checkKeyLabel(['VK_F13', 'F13'], XK_F13);
  checkKeyLabel(['VK_F14', 'F14'], XK_F14);
  //checkKeyLabel(['VK_F15', 'F15'], VK_F15);
  //checkKeyLabel(['VK_F16', 'F16'], VK_F16);
  //checkKeyLabel(['VK_F17', 'F17'], VK_F17);
  //checkKeyLabel(['VK_F18', 'F18'], VK_F18);
  //checkKeyLabel(['VK_F19', 'F19'], VK_F19);
  //checkKeyLabel(['VK_F20', 'F20'], VK_F20);
  //checkKeyLabel(['VK_F21', 'F21'], VK_F21);
  //checkKeyLabel(['VK_F22', 'F22'], VK_F22);
  //checkKeyLabel(['VK_F23', 'F23'], VK_F23);
  //checkKeyLabel(['VK_F24', 'F24'], VK_F24);
  checkKeyLabel(['VK_NUMLOCK', 'Num Lock'], XK_Num_Lock);
  checkKeyLabel(['VK_SCROLL', 'Scroll Lock'], XK_Scroll_Lock);


  // VK_L & VK_R - left and right Alt, Ctrl and Shift virtual keys.
  //  Used only as parameters to GetAsyncKeyState() and GetKeyState().
  //  No other API or message will distinguish left and right keys in this way.
  //checkKeyLabel(['VK_LSHIFT', 'Shift ЛЕВ'], VK_LShift); //160
  //checkKeyLabel(['VK_RSHIFT', 'Shift ПРАВ'], VK_RShift); //161
  //checkKeyLabel(['VK_LCONTROL', 'Ctrl ЛЕВ'], VK_LControl); //162
  //checkKeyLabel(['VK_RCONTROL', 'Ctrl ПРАВ'], VK_RControl); //163
  //checkKeyLabel(['VK_LMENU', 'Menu ЛЕВ'], VK_LMenu); //163
  //checkKeyLabel(['VK_RMENU', 'Menu ПРАВ'], VK_RMenu); //165

  //
  //checkKeyLabel(['VK_BROWSER_BACK', 'VK_BROWSER_BACK'], VK_BROWSER_BACK);// 166;
  //checkKeyLabel(['VK_BROWSER_FORWARD', 'VK_BROWSER_FORWARD'], VK_BROWSER_FORWARD);// 167;
  //checkKeyLabel(['VK_BROWSER_REFRESH', 'VK_BROWSER_REFRESH'], VK_BROWSER_REFRESH);// 168;
  //checkKeyLabel(['VK_BROWSER_STOP', 'VK_BROWSER_STOP'], VK_BROWSER_STOP);// 169;
  //checkKeyLabel(['VK_BROWSER_SEARCH', 'VK_BROWSER_SEARCH'], VK_BROWSER_SEARCH);// 170;
  //checkKeyLabel(['VK_BROWSER_FAVORITES', 'VK_BROWSER_FAVORITES'], VK_BROWSER_FAVORITES);// 171;
  //checkKeyLabel(['VK_BROWSER_HOME', 'VK_BROWSER_HOME'], VK_BROWSER_HOME);// 172;
  //checkKeyLabel(['VK_VOLUME_MUTE', 'VK_VOLUME_MUTE'], VK_VOLUME_MUTE);// 173;
  //checkKeyLabel(['VK_VOLUME_DOWN', 'VK_VOLUME_DOWN'], VK_VOLUME_DOWN);// 174;
  //checkKeyLabel(['VK_VOLUME_UP', 'VK_VOLUME_UP'], VK_VOLUME_UP);// 175;
  //checkKeyLabel(['VK_MEDIA_NEXT_TRACK', 'VK_MEDIA_NEXT_TRACK'], VK_MEDIA_NEXT_TRACK);// 176;
  //checkKeyLabel(['VK_MEDIA_PREV_TRACK', 'VK_MEDIA_PREV_TRACK'], VK_MEDIA_PREV_TRACK);// 177;
  //checkKeyLabel(['VK_MEDIA_STOP', 'VK_MEDIA_STOP'], VK_MEDIA_STOP);// 178;
  //checkKeyLabel(['VK_MEDIA_PLAY_PAUSE', 'VK_MEDIA_PLAY_PAUSE'], VK_MEDIA_PLAY_PAUSE);// 179;
  //checkKeyLabel(['VK_LAUNCH_MAIL', 'VK_LAUNCH_MAIL'], VK_LAUNCH_MAIL);// 180;
  //checkKeyLabel(['VK_LAUNCH_MEDIA_SELECT', 'VK_LAUNCH_MEDIA_SELECT'], VK_LAUNCH_MEDIA_SELECT);// 181;
  //checkKeyLabel(['VK_LAUNCH_APP1', 'VK_LAUNCH_APP1'], VK_LAUNCH_APP1);// 182;
  //checkKeyLabel(['VK_LAUNCH_APP2', 'VK_LAUNCH_APP2'], VK_LAUNCH_APP2);// 183;

  //
  //checkKeyLabel(['VK_OEM_1', 'VK_OEM_1'], VK_OEM_1);// 186;
  //checkKeyLabel(['VK_OEM_PLUS', 'VK_OEM_PLUS'], VK_OEM_PLUS);// 187;
  //checkKeyLabel(['VK_OEM_COMMA', 'VK_OEM_COMMA'], VK_OEM_COMMA);// 188;
  //checkKeyLabel(['VK_OEM_MINUS', 'VK_OEM_MINUS'], VK_OEM_MINUS);// 189;
  //checkKeyLabel(['VK_OEM_PERIOD', 'VK_OEM_PERIOD'], VK_OEM_PERIOD);// 190;
  //checkKeyLabel(['VK_OEM_2', 'VK_OEM_2'], VK_OEM_2);// 191;
  //checkKeyLabel(['VK_OEM_3', 'VK_OEM_3'], VK_OEM_3);// 192;
  //checkKeyLabel(['VK_OEM_4', 'VK_OEM_4'], VK_OEM_4);// 219;
  //checkKeyLabel(['VK_OEM_5', 'VK_OEM_5'], VK_OEM_5);// 220;
  //checkKeyLabel(['VK_OEM_6', 'VK_OEM_6'], VK_OEM_6);// 221;
  //checkKeyLabel(['VK_OEM_7', 'VK_OEM_7'], VK_OEM_7);// 222;
  //checkKeyLabel(['VK_OEM_8', 'VK_OEM_8'], VK_OEM_8);// 223;
  //checkKeyLabel(['VK_OEM_102', 'VK_OEM_102'], VK_OEM_102);// 226;
  //checkKeyLabel(['VK_PACKET', 'VK_PACKET'], VK_PACKET);// 231

  //
  //checkKeyLabel(['VK_PROCESSKEY', 'vkProcessKey'], XK_ProcessKey); //229
  //checkKeyLabel(['VK_ATTN', 'vkAttn'], VK_Attn); //246
  //checkKeyLabel(['VK_CRSEL', 'vkCrsel'], VK_Crsel); //247
  //checkKeyLabel(['VK_EXSEL', 'vkExsel'], VK_Exsel); //248
  //checkKeyLabel(['VK_EREOF', 'vkErEof'], VK_ErEof); //249
  //checkKeyLabel(['VK_PLAY', 'vkPlay'], VK_Play); //250
  //checkKeyLabel(['VK_ZOOM', 'vkZoom'], VK_Zoom); //251
  //checkKeyLabel(['VK_NONAME', 'vkNoName'], VK_NoName); //252
  //checkKeyLabel(['VK_PA1', 'vkPA1'], VK_PA1); //253
  //checkKeyLabel(['VK_OEM_CLEAR', 'vkOemClear'], VK_Oem_Clear); //254
end;
{$ELSE}
function VkStringToCode(AKeyCaption: string): Integer;
// возвращает численный код виртуальной клавиши по его текстовому названию
// одной клавише может быть назначено несколько названий, например на разных языках
var
  keyLabel: string;

procedure checkKeyLabel(const AValues: array of string; Num: Byte);
// присваивает Result численный код клавиши, если ее текстовое имя перечислено в AValues
var
  str1: string;
  i: Integer;
begin
  for i:=0 to Length(AValues)-1 do begin
    str1 := Trim(UpperCase(AValues[i]));
    if (keyLabel=str1) then begin
      Result := Num;
      exit;
      end;
    end;
end;

var
  b: Byte;
begin
  Result := 0; // виртуальной клавиши с кодом нуль нет. Значит - ничего не нашли
  keyLabel := UpperCase(Trim(AKeyCaption));

  // это цифра или буква
  if Length(keyLabel) = 1 then begin
    b := ORD(keyLabel[1]);
    if (((b>=ORD('0'))and(b<=ORD('9')))or((b>=ORD('A'))and(b<=ORD('Z')))) then begin
      Result:=b;
      exit;
      end;
    end;

  // Virtual Keys, Standard Set, см. Microsoft Windows SDK
  checkKeyLabel(['VK_LBUTTON', 'ЛКМ'], VK_LButton);  //1
  checkKeyLabel(['VK_RBUTTON', 'ПКМ'], VK_RButton); //2
  checkKeyLabel(['VK_CANCEL','vkCancel'], VK_Cancel); //3
  checkKeyLabel(['VK_MBUTTON','vkMButton'], VK_MButton); //4  // NOT contiguous with L & RBUTTON
  checkKeyLabel(['VK_XBUTTON1', 'vkXButton1'], VK_XButton1); //5
  checkKeyLabel(['VK_XBUTTON2', 'vkXButton2'], VK_XButton2); //6
  checkKeyLabel(['VK_BACK', 'Backspace'], VK_Back); //8
  checkKeyLabel(['VK_TAB', 'Tab'], VK_Tab); //9
  checkKeyLabel(['VK_CLEAR', 'vkClear'], VK_Clear); //12
  checkKeyLabel(['VK_RETURN', 'ВВОД','Enter'], VK_Return); //13

  checkKeyLabel(['VK_SHIFT', 'Shift'], VK_Shift); // $10, 16
  checkKeyLabel(['VK_CONTROL', 'Ctrl'], VK_Control); //17
  checkKeyLabel(['VK_MENU', 'Menu'], VK_Menu); //18
  checkKeyLabel(['VK_PAUSE', 'vkPause'], VK_Pause); //19
  checkKeyLabel(['VK_CAPITAL', 'Caps Lock'], VK_Capital); //20
  checkKeyLabel(['VK_KANA', 'vkKana'], VK_Kana); //21
  checkKeyLabel(['VK_HANGUL', 'vkHangul'], VK_Hangul); //22
  checkKeyLabel(['VK_JUNJA', 'vkJunja'], VK_Junja); //23
  checkKeyLabel(['VK_FINAL', 'vkFinal'], VK_Final); //24
  checkKeyLabel(['VK_HANJA', 'vkHanja'], VK_Hanja); //25
  checkKeyLabel(['VK_KANJI', 'vkKanji'], VK_Kanji); //26
  checkKeyLabel(['VK_CONVERT', 'vkConvert'], VK_Convert); //28
  checkKeyLabel(['VK_NONCONVERT', 'vkNonConvert'], VK_NonConvert); //29
  checkKeyLabel(['VK_ACCEPT', 'vkAccept'], VK_Accept); //30
  checkKeyLabel(['VK_MODECHANGE', 'vkModeChange'], VK_ModeChange); //31
  checkKeyLabel(['VK_ESCAPE', 'Esc'], VK_Escape); //27
  checkKeyLabel(['VK_SPACE', 'ПРОБЕЛ'], VK_Space); // $20
  checkKeyLabel(['VK_PRIOR', 'Page Up'], VK_Prior); //33
  checkKeyLabel(['VK_NEXT', 'Page Down'], VK_Next); //34
  checkKeyLabel(['VK_END', 'End'], VK_End); //35
  checkKeyLabel(['VK_HOME', 'Home'], VK_Home); //35
  checkKeyLabel(['VK_LEFT', 'СТРЕЛКА ЛЕВ'], VK_Left); //37
  checkKeyLabel(['VK_UP', 'СТРЕЛКА ВЕРХ'], VK_Up); //38
  checkKeyLabel(['VK_RIGHT', 'СТРЕЛКА ПРАВ'], VK_Right); //39
  checkKeyLabel(['VK_DOWN', 'СТРЕЛКА НИЗ'], VK_Down); //40
  checkKeyLabel(['VK_SELECT', 'vkSelect'], VK_Select); //41
  checkKeyLabel(['VK_PRINT', 'vkPrint'], VK_Print); //42
  checkKeyLabel(['VK_EXECUTE', 'vkExecute'], VK_Execute); //43
  checkKeyLabel(['VK_SNAPSHOT', 'vkSnapShot'], VK_SnapShot); //44
  checkKeyLabel(['VK_INSERT', 'Insert'], VK_Insert); //45
  checkKeyLabel(['VK_DELETE', 'Delete'], VK_Delete); //46
  checkKeyLabel(['VK_HELP', 'vkHelp'], VK_Help); //47' +

  // VK_0 thru VK_9 are the same as ASCII '0' thru '9' ($30 - $39)
  // VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' ($41 - $5A) }

  checkKeyLabel(['VK_LWIN','Win ЛЕВ'], VK_LWin); //91
  checkKeyLabel(['VK_RWIN', 'Win ПРАВ'], VK_RWin); //92
  checkKeyLabel(['VK_APPS', 'vkApps'], VK_Apps); //93
  checkKeyLabel(['VK_SLEEP', 'vkSleep'], VK_Sleep); //95
  checkKeyLabel(['VK_NUMPAD0', 'Numpad 0'], VK_Numpad0); //96
  checkKeyLabel(['VK_NUMPAD1', 'Numpad 1'], VK_Numpad1); //97
  checkKeyLabel(['VK_NUMPAD2', 'Numpad 2'], VK_Numpad2); //98
  checkKeyLabel(['VK_NUMPAD3', 'Numpad 3'], VK_Numpad3); //99
  checkKeyLabel(['VK_NUMPAD4', 'Numpad 4'], VK_Numpad4); //100
  checkKeyLabel(['VK_NUMPAD5', 'Numpad 5'], VK_Numpad5); //101
  checkKeyLabel(['VK_NUMPAD6', 'Numpad 6'], VK_Numpad6); //102
  checkKeyLabel(['VK_NUMPAD7', 'Numpad 7'], VK_Numpad7); //103
  checkKeyLabel(['VK_NUMPAD8', 'Numpad 8'], VK_Numpad8); //104
  checkKeyLabel(['VK_NUMPAD9', 'Numpad 9'], VK_Numpad9); //105

  checkKeyLabel(['VK_MULTIPLY', 'vkMultiply'], VK_Multiply); //106
  checkKeyLabel(['VK_ADD', 'vkAdd'], VK_Add); //107
  checkKeyLabel(['VK_SEPARATOR', 'vkSeparator'], VK_Separator); //108
  checkKeyLabel(['VK_SUBTRACT', 'vkSubtract'], VK_Subtract); //109
  checkKeyLabel(['VK_DECIMAL', 'vkDecimal'], VK_Decimal); //110
  checkKeyLabel(['VK_DIVIDE', 'vkDivide'], VK_Divide); //111
  checkKeyLabel(['VK_F1', 'F1'], VK_F1); //112
  checkKeyLabel(['VK_F2', 'F2'], VK_F2); //113
  checkKeyLabel(['VK_F3', 'F3'], VK_F3); //114
  checkKeyLabel(['VK_F4', 'F4'], VK_F4); //115
  checkKeyLabel(['VK_F5', 'F5'], VK_F5); //116
  checkKeyLabel(['VK_F6', 'F6'], VK_F6); //117
  checkKeyLabel(['VK_F7', 'F7'], VK_F7); //118
  checkKeyLabel(['VK_F8', 'F8'], VK_F8); //119
  checkKeyLabel(['VK_F9', 'F9'], VK_F9); //120
  checkKeyLabel(['VK_F10', 'F10'], VK_F10); //121
  checkKeyLabel(['VK_F11', 'F11'], VK_F11); //122
  checkKeyLabel(['VK_F12', 'F12'], VK_F12); //123
  checkKeyLabel(['VK_F13', 'F13'], VK_F13); //124
  checkKeyLabel(['VK_F14', 'F14'], VK_F14); //125
  checkKeyLabel(['VK_F15', 'F15'], VK_F15); //126
  checkKeyLabel(['VK_F16', 'F16'], VK_F16); //127
  checkKeyLabel(['VK_F17', 'F17'], VK_F17); //128
  checkKeyLabel(['VK_F18', 'F18'], VK_F18); //129
  checkKeyLabel(['VK_F19', 'F19'], VK_F19); //130
  checkKeyLabel(['VK_F20', 'F20'], VK_F20); //131
  checkKeyLabel(['VK_F21', 'F21'], VK_F21); //132
  checkKeyLabel(['VK_F22', 'F22'], VK_F22); //133
  checkKeyLabel(['VK_F23', 'F23'], VK_F23); //134
  checkKeyLabel(['VK_F24', 'F24'], VK_F24); //135
  checkKeyLabel(['VK_NUMLOCK', 'Num Lock'], VK_NumLock); //144
  checkKeyLabel(['VK_SCROLL', 'Scroll Lock'], VK_Scroll); //145


  // VK_L & VK_R - left and right Alt, Ctrl and Shift virtual keys.
  //  Used only as parameters to GetAsyncKeyState() and GetKeyState().
  //  No other API or message will distinguish left and right keys in this way.
  checkKeyLabel(['VK_LSHIFT', 'Shift ЛЕВ'], VK_LShift); //160
  checkKeyLabel(['VK_RSHIFT', 'Shift ПРАВ'], VK_RShift); //161
  checkKeyLabel(['VK_LCONTROL', 'Ctrl ЛЕВ'], VK_LControl); //162
  checkKeyLabel(['VK_RCONTROL', 'Ctrl ПРАВ'], VK_RControl); //163
  checkKeyLabel(['VK_LMENU', 'Menu ЛЕВ'], VK_LMenu); //163
  checkKeyLabel(['VK_RMENU', 'Menu ПРАВ'], VK_RMenu); //165

  //
  checkKeyLabel(['VK_BROWSER_BACK', 'VK_BROWSER_BACK'], VK_BROWSER_BACK);// 166;
  checkKeyLabel(['VK_BROWSER_FORWARD', 'VK_BROWSER_FORWARD'], VK_BROWSER_FORWARD);// 167;
  checkKeyLabel(['VK_BROWSER_REFRESH', 'VK_BROWSER_REFRESH'], VK_BROWSER_REFRESH);// 168;
  checkKeyLabel(['VK_BROWSER_STOP', 'VK_BROWSER_STOP'], VK_BROWSER_STOP);// 169;
  checkKeyLabel(['VK_BROWSER_SEARCH', 'VK_BROWSER_SEARCH'], VK_BROWSER_SEARCH);// 170;
  checkKeyLabel(['VK_BROWSER_FAVORITES', 'VK_BROWSER_FAVORITES'], VK_BROWSER_FAVORITES);// 171;
  checkKeyLabel(['VK_BROWSER_HOME', 'VK_BROWSER_HOME'], VK_BROWSER_HOME);// 172;
  checkKeyLabel(['VK_VOLUME_MUTE', 'VK_VOLUME_MUTE'], VK_VOLUME_MUTE);// 173;
  checkKeyLabel(['VK_VOLUME_DOWN', 'VK_VOLUME_DOWN'], VK_VOLUME_DOWN);// 174;
  checkKeyLabel(['VK_VOLUME_UP', 'VK_VOLUME_UP'], VK_VOLUME_UP);// 175;
  checkKeyLabel(['VK_MEDIA_NEXT_TRACK', 'VK_MEDIA_NEXT_TRACK'], VK_MEDIA_NEXT_TRACK);// 176;
  checkKeyLabel(['VK_MEDIA_PREV_TRACK', 'VK_MEDIA_PREV_TRACK'], VK_MEDIA_PREV_TRACK);// 177;
  checkKeyLabel(['VK_MEDIA_STOP', 'VK_MEDIA_STOP'], VK_MEDIA_STOP);// 178;
  checkKeyLabel(['VK_MEDIA_PLAY_PAUSE', 'VK_MEDIA_PLAY_PAUSE'], VK_MEDIA_PLAY_PAUSE);// 179;
  checkKeyLabel(['VK_LAUNCH_MAIL', 'VK_LAUNCH_MAIL'], VK_LAUNCH_MAIL);// 180;
  checkKeyLabel(['VK_LAUNCH_MEDIA_SELECT', 'VK_LAUNCH_MEDIA_SELECT'], VK_LAUNCH_MEDIA_SELECT);// 181;
  checkKeyLabel(['VK_LAUNCH_APP1', 'VK_LAUNCH_APP1'], VK_LAUNCH_APP1);// 182;
  checkKeyLabel(['VK_LAUNCH_APP2', 'VK_LAUNCH_APP2'], VK_LAUNCH_APP2);// 183;

  //
  checkKeyLabel(['VK_OEM_1', 'VK_OEM_1'], VK_OEM_1);// 186;
  checkKeyLabel(['VK_OEM_PLUS', 'VK_OEM_PLUS'], VK_OEM_PLUS);// 187;
  checkKeyLabel(['VK_OEM_COMMA', 'VK_OEM_COMMA'], VK_OEM_COMMA);// 188;
  checkKeyLabel(['VK_OEM_MINUS', 'VK_OEM_MINUS'], VK_OEM_MINUS);// 189;
  checkKeyLabel(['VK_OEM_PERIOD', 'VK_OEM_PERIOD'], VK_OEM_PERIOD);// 190;
  checkKeyLabel(['VK_OEM_2', 'VK_OEM_2'], VK_OEM_2);// 191;
  checkKeyLabel(['VK_OEM_3', 'VK_OEM_3'], VK_OEM_3);// 192;
  checkKeyLabel(['VK_OEM_4', 'VK_OEM_4'], VK_OEM_4);// 219;
  checkKeyLabel(['VK_OEM_5', 'VK_OEM_5'], VK_OEM_5);// 220;
  checkKeyLabel(['VK_OEM_6', 'VK_OEM_6'], VK_OEM_6);// 221;
  checkKeyLabel(['VK_OEM_7', 'VK_OEM_7'], VK_OEM_7);// 222;
  checkKeyLabel(['VK_OEM_8', 'VK_OEM_8'], VK_OEM_8);// 223;
  checkKeyLabel(['VK_OEM_102', 'VK_OEM_102'], VK_OEM_102);// 226;
  //checkKeyLabel(['VK_PACKET', 'VK_PACKET'], VK_PACKET);// 231

  //
  checkKeyLabel(['VK_PROCESSKEY', 'vkProcessKey'], VK_ProcessKey); //229
  checkKeyLabel(['VK_ATTN', 'vkAttn'], VK_Attn); //246
  checkKeyLabel(['VK_CRSEL', 'vkCrsel'], VK_Crsel); //247
  checkKeyLabel(['VK_EXSEL', 'vkExsel'], VK_Exsel); //248
  checkKeyLabel(['VK_EREOF', 'vkErEof'], VK_ErEof); //249
  checkKeyLabel(['VK_PLAY', 'vkPlay'], VK_Play); //250
  checkKeyLabel(['VK_ZOOM', 'vkZoom'], VK_Zoom); //251
  checkKeyLabel(['VK_NONAME', 'vkNoName'], VK_NoName); //252
  checkKeyLabel(['VK_PA1', 'vkPA1'], VK_PA1); //253
  checkKeyLabel(['VK_OEM_CLEAR', 'vkOemClear'], VK_Oem_Clear); //254
end;
{$ENDIF}
//--------------------------------------------------------------------------
// ФУНКЦИЯ ДЛЯ ОТЛАДКИ - проверить, что каждой клавише в property_keySet присвоен код
function TUserKeybrd.testKeySetAssignment(slist1: TStringList): Boolean;
var
  str1: string;
  j: integer;
begin
  Result:= True;
  for j:=0 to slist1.Count-1 do begin
    str1 := slist1.Strings[j];
    if VkStringToCode(str1)=0 then begin
      ErrorEvent(txtKeyUnknown1 + str1 + txtKeyUnknown2,msError, VisualObject);
      Result := False;
      end;
    end;
end;

//--------------------------------------------------------------------------
function TUserKeybrd.InfoFunc(Action: integer;aParameter: NativeInt):NativeInt;
var
  slist1: TStringList;
  i: Integer;
  str1: string;
begin
  Result := r_Success;

  case Action of
      i_GetPropErr:
        begin
          slist1 := TStringList.Create;
          slist1.LineBreak := #13#10;
          slist1.Text := property_KeySet.Items;

          // проверка, что названия клавиш в наборе привязаны к численному коду
          // РЕКОМЕНДУЮ раскомментировать этот код при добавлении новых клавиш в SimInTech
          // на период отладки
          if False then begin
          //if testKeySetAssignment(slist1)=False then begin
            Result := r_Fail;
            FreeAndNil(slist1);
            exit;
            end;

          // проверка, что идет опрос хотя бы одной клавиши клавиатуры
          if Length(property_KeySet.Selection)=0 then begin
            ErrorEvent(txtUselessKeyboard, msError, VisualObject);
            Result := r_Fail;
            FreeAndNil(slist1);
            exit;
            end;

          // формируем массив кодов назначенных к опросу клавиш
          keyCodesArray.ChangeCount(Length(property_KeySet.Selection));
          for i:=0 to Length(property_KeySet.Selection)-1 do begin
            str1 := slist1.Strings[property_KeySet.Selection[i]];
            keyCodesArray[i] := VkStringToCode(str1);
            // дополнительно проверяем, что клавише назначен код
            if(keyCodesArray[i]=0) then begin
              ErrorEvent(txtKeyUnknown1 + str1 + txtKeyUnknown2,msError, VisualObject);
              Result := r_Fail;
              FreeAndNil(slist1);
              exit;
              end;
            end;

          FreeAndNil(slist1);
        end;

      i_GetCount:
        begin
          cY[0].Dim:=SetDim([keyCodesArray.Count]);
        end
  else
    Result:=inherited InfoFunc(Action,aParameter);
  end;
end;

//---------------------------------------------------------------------------
function TUserKeybrd.RunFunc(var at,h: RealType; Action: Integer):NativeInt;
var
  keyResult: Boolean;
  i: Integer;
  str1: ansistring;
begin
  Result := r_Success;

  case Action of
    f_InitState,
    f_RestoreOuts,
    f_UpdateOuts,
    f_UpdateJacoby,
    f_GoodStep:
      begin
        {$IFDEF FPC}
        kbrd.refresh;
        for i:=0 to keyCodesArray.Count-1 do begin
          keyResult := kbrd.isKeyPressed((keyCodesArray[i]));
          if keyResult then Y[0][i] := 1.
                       else Y[0][i] := 0.;
          end;
        {$ELSE}
        for i:=0 to keyCodesArray.Count-1 do begin
          keyResult := GetAsyncKeyState(Integer(keyCodesArray[i]))<>0;
          if keyResult then Y[0][i] := 1.
                       else Y[0][i] := 0.;
          end;
        {$ENDIF}
      end;
  end
end;
//--------------------------------------------------------------------------
function TUserKeybrd.GetParamID(const ParamName:string;var DataType:TDataType;var IsConst: boolean):NativeInt;
begin
  Result := inherited GetParamID(ParamName,DataType,IsConst);
  if Result <> -1 then exit;

  if StrEqu(ParamName,'KeySet') then begin
      Result:=NativeInt(property_KeySet);
      DataType:=dtMultiSelect;
      exit;
    end;

  ErrorEvent(txtParamUnknown1 + ParamName + txtParamUnknown2, msWarning, VisualObject);
end;

//===========================================================================

////////////////////////////////////////////////////////////////////////////////
end.
