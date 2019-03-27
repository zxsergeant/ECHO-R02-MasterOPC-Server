---------------------------------------------------------------------------
-- Функция (69) приёма n строк посуточного архива, начиная с i-й
---------------------------------------------------------------------------
function ReadECHO69(nlin)
  local send={}; --массив отправляемых чисел
  table.insert(send,Address); --адрес
  table.insert(send,0x69); --функция
  table.insert(send,0x00); --1-й байт-параметр – ст. байт числа i;
  table.insert(send,0x01); --2-й байт-параметр – мл. байт числа i;
  table.insert(send,nlin); --число n;
  local sendmask={"byte","byte","byte","byte","byte"}; --маска отправляемого запроса
  local dest={}; --массив полученных чисел
  local destmask={"byte:3"}; --маска принимаемого запроса
  local nlin1=nlin;
  repeat
    --увеличиваем маску принимаемого запросана на величину строк запроса
    table.insert(destmask,"int32:1:0123");
    table.insert(destmask,"byte:3");
    nlin1=nlin1-1;
  until nlin1<=0
  --определяем размер получаемых данных в байтах
  local err,len;
  local n=0;
  local nbyte=5+nlin*7;
    repeat
    --посылка и получение запроса в устройство
    err,dest,len=server.SendAndReceiveDataByMask(2,5,sendmask,send,destmask,nbyte);
    n=n+1;
    --условие выхода - корректный ответ или превышение запросов
  until err>=0 or n>=server.GetCurrentDeviceRetry()
  if err>=0 then
    --local multipler=server.ReadTagByRelativeName("multipler");
    local err1,multipler=GetMultipler();
    nlin1=nlin;
    local a=4;
    repeat
      dest[a]=dest[a]*multipler;
      a=a+4;
      nlin1=nlin1-1;
    until nlin1<=0
    return err,dest;
  else
    read=false;
    return -1,0; --запрос некорректен, возвращаем соответствующий флаг
    end;
  end
---------------------------------------------------------------------------
--Функция преобразования BCD в int число
---------------------------------------------------------------------------
function FromBCD(register)
  local shift=register;
  local bytes={};
  local exp=1;
  local number=0;
  for i=1,4,1 do
    local byte=bit.BitAnd(shift,0xF);--получаем правый полубайт маскированием
    number=number+byte*exp; --умножаем число и прибавляем к сохраненному
    exp=exp*10; --увеличиваем степень умножения
    shift=bit.BitRshift(shift,4); --делаем сдвиг вправо
  end
  return number; --возвращаем число
end
---------------------------------------------------------------------------
--Функция получения множителя из текущих значений (функция #66)
---------------------------------------------------------------------------
function GetMultipler()
  local send={}; --массив отправляемых чисел
  table.insert(send,Address); --добавляем первый элемент - идентификатор команды
  table.insert(send,0x66); --добавляем второй элемент - текущие результаты измерений
  local sendmask={"byte","byte"}; --маска отправляемого запроса
  local dest={}; --массив полученных чисел
  local destmask={"byte:3","float:2:0123","int32:2:0123","byte:2"}; --маска принимаемого запроса
  local err,len;
  local n=0;
  repeat
    --посылка и получение запроса в устройство
    err,dest,len=server.SendAndReceiveDataByMask(2,2,sendmask,send,destmask,23);
    n=n+1;
    --условие выхода - корректный ответ или превышение запросов
  until err>=0 or n>=server.GetCurrentDeviceRetry()
  --обработка результатов
  if err>=0 then
    dest[8] = (10^ (dest[8] - 3 ));
    return true,dest[8];
  else
    return false,0; --запрос некорректен, возвращаем соответствующий флаг
    end;
  end
---------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------
function OnInit()
    Address =  server.ReadSubDeviceExtProperty("Адрес");
    read=false;
end
---------------------------------------------------------------------------
-- Uninitialization
---------------------------------------------------------------------------
function OnClose()

end
---------------------------------------------------------------------------
-- Processing
---------------------------------------------------------------------------
function OnRead()
  local errok;--={}; --массив полученных чисел
  if read==false
  then do
    local dest={}; --массив полученных чисел
    local deep=server.ReadSubDeviceExtProperty("Суток посуточного архива");
    errok,dest=ReadECHO69(deep); --Запрос данных с прибора
      if errok<=0 then return;
      end;
    local a=4;
    repeat
      Err,timesec = time.PackTime(2000+FromBCD(dest[a+3]),FromBCD(dest[a+2]),FromBCD(dest[a+1]),00,00,00);
      ts = time.TimeToTimeStamp(timesec,0);
      server.WriteCurrentTagToHda(dest[a],OPC_QUALITY_GOOD,ts)
      a=a+4;
      deep=deep-1;
    until deep<=0
    read=true;
    end;
  else do
    local dest={}; --массив полученных чисел
    local deep=1;
    errok,dest=ReadECHO69(deep); --Запрос данных с прибора
    if errok<=0 then return;
    end;
    local a=4;
    Err,timesec = time.PackTime(2000+FromBCD(dest[a+3]),FromBCD(dest[a+2]),FromBCD(dest[a+1]),00,00,00);
    ts = time.TimeToTimeStamp(timesec,0);
    server.WriteCurrentTag(dest[4],OPC_QUALITY_GOOD,ts);
    server.WriteCurrentTagToHda(dest[a],OPC_QUALITY_GOOD,ts)
    end;
    end;
  end
