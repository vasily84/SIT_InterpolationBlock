
 //**************************************************************************//
 // Данный исходный код является составной частью системы МВТУ-4             //
 // Программисты:        Тимофеев К.А., Ходаковский В.В.                     //
 //**************************************************************************//

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF} 
 
unit Info;

  //**************************************************************************//
  //         Здесь находится список объектов и функция для их создания        //
  //**************************************************************************//

interface

uses Classes, InterfaceUnit,DataTypes, DataObjts, abstract_im_interface, RunObjts;

  //Инициализация библиотеки
function  Init:boolean;
  //Процедура создания объекта
function  CreateObject(Owner:Pointer;const Name: string):Pointer;
  //Уничтожение библиотеки
procedure Release;

  //Главная информационая запись библиотеки
  //Она содержит ссылки на процедуры инициализации, завершения библиотеки
  //и функцию создания объектов
const
  DllInfo: TDllInfo =
  (
    Init:         Init;
    Release:      Release;
    CreateObject: CreateObject;
  );

implementation

uses Src, Dif, Operations, Nonlines, Discrete, Vectors, Func_blocks, Keys,
     Logs, Trigger,Timers,Data_blocks, Stat_Blocks, lae_objects, uOptimizers,
     elec_base, uCrossZero, InterpolationBlocks, InterpolationBlocks_unit;// in 'InterpolationBlocks.pas';

function  Init:boolean;
begin
  //Если библиотека инициализирована правильно, то функция должна вернуть True
  Result:=True;
  //Присваиваем папку с корневой директорией базы данных программы
  DBRoot:=DllInfo.Main.DataBasePath^;

  //Здесь можно произвести регистрацию дополнительных функций интерпретатора
  //при помощи функции DllInfo.Main.RegisterFuncs
  //для того чтобы подключить функции к оболочке надо внести библиотеку в список плагинов графического редактора.

end;


type
  TClassRecord = packed record
    Name:     string;
    RunClass: TRunClass;
  end;

  //**************************************************************************//
  //    Таблица классов имеющихся в стандартной библиотеке блоков МВТУ        //
  //    в соответствии с этой таблицей создаются соответсвующие run-объекты   //
  //**************************************************************************//
const
  ClassTable:array[0..209] of TClassRecord =
  (
    //Блоки - источники
    (Name:'ttimesource' ;RunClass:TTimeSource),
    (Name:'ttimestep'   ;RunClass:TTimeStep),
    (Name:'tconst'      ;RunClass:TConst),
    (Name:'tlinear'     ;RunClass:TLinear),
    (Name:'tstep'       ;RunClass:TStep),
    (Name:'tparabola'   ;RunClass:TParabola),
    (Name:'tpolynom'    ;RunClass:TPolynom),
    (Name:'tsin'        ;RunClass:TSin),
    (Name:'texp'        ;RunClass:TExp),
    (Name:'thyper'      ;RunClass:THyper),
    (Name:'tpila'       ;RunClass:TPila),
    (Name:'tinvpila'    ;RunClass:TInvPila),
    (Name:'ttriangle'   ;RunClass:TTriangle),
    (Name:'tmeandr'     ;RunClass:TMeandr),
    (Name:'timpgen'     ;RunClass:TImpGen),
    (Name:'tlom'        ;RunClass:TLom),
    (Name:'tmultistep'  ;RunClass:TMultiStep),
    (Name:'tsteady'     ;RunClass:TSteady),
    (Name:'tgauss'      ;RunClass:TGauss),
    (Name:'tstepcycle'  ;RunClass:TStepCycle),
    (Name:'tsinuscycle' ;RunClass:TSinusCycle),

    //Динамические блоки
    (Name:'tintegrator' ;RunClass:TIntegrator),
    (Name:'taperiodika1';RunClass:TAperiodika1),
    (Name:'tstates';     RunClass:TStates),
    (Name:'tfunctional'; RunClass:TFunctional),
    (Name:'tkoleb';      RunClass:TKoleb),
    (Name:'tforceaperiodika';RunClass:TForceAperiodika),
    (Name:'tdifaperiodika';RunClass:TDifAperiodika),
    (Name:'tintegraperiodika';RunClass:TIntergAperiodika),
    (Name:'tlimitintegrator';RunClass:TLimitIntegrator),
    (Name:'tvarintegrator';RunClass:TVarIntegrator),
    (Name:'tws';         RunClass:TWs),
    (Name:'tdiff';       RunClass:TDiff),
    (Name:'tcrosszero';  RunClass:TCrossZero),
    (Name:'ttolpointer'; RunClass:TTolPointer),
    (Name:'tresetintegrator'; RunClass:TResetLimitIntegrator),
    (Name:'tperiodicintegrator'; RunClass:TPeriodicIntegrator),

    //Операции
    (Name:'tsum'        ;RunClass:TSum),
    (Name:'tvecsum'     ;RunClass:TVecSum),
    (Name:'tmul'        ;RunClass:TMul),
    (Name:'tvecmul'     ;RunClass:TVecMul),
    (Name:'tscalarmul'  ;RunClass:TScalarMul),
    (Name:'tscalaradd'  ;RunClass:TScalarAdd),
    (Name:'tvectoramp'  ;RunClass:TVectorAmp),
    (Name:'tdiv'        ;RunClass:TDiv),
    (Name:'tscalardiv'  ;RunClass:TScalarDiv),
    (Name:'tabs'        ;RunClass:TAbs),
    (Name:'tsign'       ;RunClass:TSign),
    (Name:'trazm'       ;RunClass:TRazm),
    (Name:'tcompensator';RunClass:TCompensator),
    (Name:'tcase'       ;RunClass:TCase),
    (Name:'tfirstactive';RunClass:TFirstActive),
    (Name:'ttrap'       ;RunClass:TTrap),
    (Name:'tempty'      ;RunClass:TEmpty),
    (Name:'tcaseactive' ;RunClass:TCaseActive),
    (Name:'tint'        ;RunClass:TInt),
    (Name:'tfrac'       ;RunClass:TFrac),
    (Name:'tdotproduct' ;RunClass:TVectorDotProduct),

    //Векторные операции
    (Name:'tmultiplexor';RunClass:TMultiplexor),
    (Name:'tdemultiplexor';RunClass:TDemultiplexor),
    (Name:'tunpackmatrix'; RunClass:TUnPackMatrix),
    (Name:'tpackmatrix'; RunClass:TPackMatrix),
    (Name:'tselectvector';RunClass:TSelectVector),
    (Name:'tlae';        RunClass:TLAE),
    (Name:'tmatrixmul';  RunClass:TMatrixMul),
    (Name:'ttransponse'; RunClass:TTransponse),
    (Name:'tinterp';     RunClass:TInterp),
    (Name:'tmnk';        RunClass:TMNK),

    //Стандартные функциональные блоки
    (Name:'tpowerfunc';  RunClass:TPowerFunc),
    (Name:'tlinearfunc'; RunClass:TLinearFunc),
    (Name:'tpokazfunc';  RunClass:TPokazFunc),
    (Name:'tvarpokazfunc';RunClass:TVarPokazFunc),
    (Name:'tsinfunc';    RunClass:TSinFunc),
    (Name:'tarcsinfunc'; RunClass:TArcSinFunc),
    (Name:'tarccosfunc'; RunClass:TArcCosFunc),
    (Name:'tarctgfunc';  RunClass:TArcTgFunc),
    (Name:'tarcctgfunc'; RunClass:TArcCtgFunc),
    (Name:'tshfunc';     RunClass:TShFunc),
    (Name:'tchfunc';     RunClass:TChFunc),
    (Name:'tthfunc';     RunClass:TThFunc),
    (Name:'tcthfunc';    RunClass:TCthFunc),
    (Name:'tlnfunc';     RunClass:TLnFunc),
    (Name:'tlgfunc';     RunClass:TLgFunc),
    (Name:'tln0func';    RunClass:TLn0Func),
    (Name:'tlg0func';    RunClass:TLg0Func),
    (Name:'thyperfunc';  RunClass:THyperFunc),
    (Name:'tparabolafunc';RunClass:TParabolaFunc),
    (Name:'tpolynomfunc';RunClass:TPolynomFunc),
    (Name:'texpfunc';    RunClass:TExpFunc),
    (Name:'tlineconvert';RunClass:TLineConvert),
    (Name:'tsqrt';       RunClass:TSQRT),
    (Name:'tatan2';      RunClass:TAtan2Func),
    (Name:'tsincos';     RunClass:TSinCosFunc),

    //Блоки - переключатели
    (Name:'tkey0';       RunClass:TKey0),
    (Name:'tkey1';       RunClass:TKey1),
    (Name:'tkey2';       RunClass:TKey2),
    (Name:'tkey3';       RunClass:TKey3),
    (Name:'tkey4';       RunClass:TKey4),
    (Name:'tkey5';       RunClass:TKey5),
    (Name:'tkey6';       RunClass:TKey6),
    (Name:'tkey7';       RunClass:TKey7),
    (Name:'tkey8';       RunClass:TKey8),

    //Логические блоки
    (Name:'tclctrigger'; RunClass:TTrigger_TR),
    (Name:'ttrigger_ts'; RunClass:TTrigger_TS),
    (Name:'ttrigger_t';  RunClass:TTrigger_T),
    (Name:'ttrigger';    RunClass:TTrigger_R),
    (Name:'ttrigger_s';  RunClass:TTrigger_S),
    (Name:'ttrigger_d';  RunClass:TTrigger_D),
    (Name:'tvartrigger'; RunClass:TVarTrigger),
    (Name:'tbool';       RunClass:TBool),
    (Name:'tnot';        RunClass:TNot),
    (Name:'tand';        RunClass:TAnd),
    (Name:'tor';         RunClass:TOr),
    (Name:'tmn';         RunClass:TMN),
    (Name:'ttimecheck';  RunClass:TTimeCheck),
    (Name:'taccept_on';  RunClass:TTimeAccept_On),
    (Name:'taccept_of';  RunClass:TTimeAccept_Of),
    (Name:'taccept_onof';RunClass:TTimeAccept_OnOf),
    (Name:'tone';        RunClass:TOne),
    (Name:'tonevar';     RunClass:TOneVar),
    (Name:'tcounter';    RunClass:TCounter),
    (Name:'txor';        RunClass:TXOR),
    (Name:'tnotxor';     RunClass:TNotXOR),
    (Name:'toneimpulse'; RunClass:TOneImpulse),
    (Name:'timpulse';    RunClass:TImpulse),
    (Name:'timpulse_r';  RunClass:TImpulse_R),
    (Name:'timpulse_l';  RunClass:TImpulse_L),
    (Name:'toneimpulse_on';RunClass:TOneImpulse_On),
    (Name:'toneimpulse_of';RunClass:TOneImpulse_Of),
    (Name:'toneimpulse_onof';RunClass:TOneImpulse_OnOf),  
    (Name:'tvecor';      RunClass:TVecOr),
    (Name:'tvecand';     RunClass:TVecAnd),
    (Name:'tmnbyelement';RunClass:TMNByElement),
    (Name:'tcommutator'; RunClass:TCommutator),
    (Name:'tfirstevent'; RunClass:TFirstEvent),
    (Name:'tbitoperations'; RunClass:TBitwizeOperations),
    (Name:'tbitpack';    RunClass:TBitPack),
    (Name:'tbitunpack';  RunClass:TBitUnPack),
    (Name:'tbitnot';     RunClass:TBitwizeNot),
    (Name:'tintcommutator';RunClass:TIntCommutator),

    //Дискретные блоки
    (Name:'tdisaperiodika';RunClass:TDisAperiodika),
    (Name:'tstepdelay';  RunClass:TStepDelay),
    (Name:'tzerosub';    RunClass:TZeroSub),
    (Name:'textrapolator';RunClass:TExtrapolator),
    (Name:'tdisdelay';   RunClass:TDisDelay),
    (Name:'tdisdiff';    RunClass:TDisDiff),
    (Name:'twz';         RunClass:TDisWs),
    (Name:'tinvwz';      RunClass:TInvDisWs),
    (Name:'tdisstates';  RunClass:TDisStates),
    (Name:'tdispid';     RunClass:TDisPID),
    (Name:'tanalaperiodika';RunClass:TAnalAperiodika),
    (Name:'tdisintegrator';RunClass:TDisIntegrator),
    (Name:'tgoodstep';RunClass:TGoodStepValue),

    //Блоки считывания и записи данных
    (Name:'tfromfile';   RunClass:TFromFile),
    (Name:'tfromtable';  RunClass:TFromTable),
    (Name:'ttableall';   RunClass:TTableAll),
    (Name:'tfromtable2d';RunClass:TFromTable2D),
    (Name:'treadstrings';RunClass:TReadStrings),
    (Name:'ttofile';     RunClass:TToFile),
    (Name:'timportfile'; RunClass:TImportFile),
    (Name:'texportfile'; RunClass:TExportFile),
    (Name:'texportnozero';RunClass:TExportNozero),

    //Статистические блоки
    (Name:'tstatmean';   RunClass:TStatMean),
    (Name:'tstatrms';    RunClass:TStatRMS),
    (Name:'tstatm3';     RunClass:TStatM3),
    (Name:'tstatm4';     RunClass:TStatM4),
    (Name:'tstatcorcoef';RunClass:TStatCorCoef),
    (Name:'tstathist';   RunClass:TStatHist),
    (Name:'tstatspectr'; RunClass:TStatSpectrum),
    (Name:'tstatdblspectr';RunClass:TDblSpectrum),
    (Name:'tstatcorfunc';RunClass:TStatCorFunc),

    //Нелинейные (в т.ч. решатели НАУ)
    (Name:'tlimit';      RunClass:TLimit),
    (Name:'ttimemem';    RunClass:TTimeMem),
    (Name:'tvaluemem';   RunClass:TValueMem),
    (Name:'timpulsfunc'; RunClass:TImpulseFunc),
    (Name:'tluft';       RunClass:TLuft),
    (Name:'tzazor';      RunClass:TZazor),
    (Name:'tvaluequant'; RunClass:TValueQuant),
    (Name:'tizlom';      RunClass:TIzlom),
    (Name:'tminmaxall';  RunClass:TMinMaxAll),
    (Name:'tminmaxu';    RunClass:TMinMaxU),
    (Name:'tminmax';     RunClass:TMinMax),
    (Name:'tlomstatic';  RunClass:TLomStatic),
    (Name:'tdifflimit';  RunClass:TDiffLimit),
    (Name:'tlineinsense';RunClass:TLineInsense),
    (Name:'treleinsense';RunClass:TReleInsense),
    (Name:'trele';       RunClass:TRele),
    (Name:'tlinelimitinsense';RunClass:TLineLimitInsense),
    (Name:'tlinelimit';  RunClass:TLineLimit),
    (Name:'tvardelay';   RunClass:TVarDelay),
    (Name:'tidealdelay'; RunClass:TIdealDelay),
    (Name:'tyfy';        RunClass:TyFy),
    (Name:'tfy0';        RunClass:TFy0),
    (Name:'tndinterpol'; RunClass:TNDimInterpolation),

    //Глобальная система ЛАУ
    (Name:'laeresult';   RunClass:TGetLAEResult),
    (Name:'laecoefs';    RunClass:TSetLAEKoefs),
    (Name:'laenumber';   RunClass:TEquCounter),
    (Name:'laesettings'; RunClass:TLAEParamsSetter),

    //Оптимизация выходных параметров под заданные входные критерии
    (Name:'toptimize';   RunClass:TOptimize),

    //Блоки для задания матрицы метода узловых потенциалов
    (Name:'telconductor';  RunClass:TElConductor),
    (Name:'telbound';      RunClass:TElBound),
    (Name:'telvoltmeter';  RunClass:TElIdealVoltmeter),
    (Name:'telampermeter'; RunClass:TElIdealAmpermeter),
    (Name:'tcontourprops'; RunClass:TConturPropertiesBlock),
    (Name:'telqpol';       RunClass:TElQpol),
    (Name:'telrestriction';RunClass:TConturRestrictionBlock),

    //Дополнительные триггеры
    (Name:'TTrigger_RCS';     RunClass:TTrigger_RCS),
    (Name:'TTrigger_SCR';     RunClass:TTrigger_SCR),
    (Name:'TTrigger_JK';      RunClass:TTrigger_JK),
    //

     (Name:'TMyInterpolationBlock1';      RunClass:TMyInterpolationBlock1)
  );


  //Это процедура создания объектов
  //она возвращает интерфейс на объект-плагин
function  CreateObject(Owner:Pointer;const Name: string):Pointer;
 var i: integer;
begin
  Result:=nil;
  for i:=0 to High(ClassTable) do if StrEqu(Name,ClassTable[i].Name) then begin
    Result:=ClassTable[i].RunClass.Create(Owner);
    exit;
  end;
end;

procedure Release;
begin

end;

end.
