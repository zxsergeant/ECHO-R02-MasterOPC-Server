---------------------------------------------------------------------------
-- Функция приёма n строк почасового архива, начиная с i-й
---------------------------------------------------------------------------
function ReadECHOi4(nlin)
  local send={}; --массив отправляемых чисел
  table.insert(send,0xAA); --маркер начала команды
  table.insert(send,0x04); --команда
  table.insert(send,0x00); --1-й байт-параметр – ст. байт числа i;
  table.insert(send,0x01); --2-й байт-параметр – мл. байт числа i;
  table.insert(send,nlin); --число n;
  local sendmask={"byte","byte","byte","byte","byte"}; --маска отправляемого запроса
  local dest={};
  local destmask={};
  local nlin1=nlin;
  repeat
    --увеличиваем маску принимаемого запросана на величину строк запроса
    table.insert(destmask,"int32:1:0123");
    table.insert(destmask,"byte:4");
    nlin1=nlin1-1;
  until nlin1<=0
  --определяем размер получаемых данных в байтах
  local err,len;
  local n=0;
  local nbyte=2+nlin*8;
  repeat
    --посылка и получение запроса в устройство
    err,dest,len=server.SendAndReceiveDataByMask(2,5,sendmask,send,destmask,nbyte);
    n=n+1;
    --условие выхода - корректный ответ или превышение запросов
  until err>=0 or n>=server.GetCurrentDeviceRetry()
  if err>=0 then
    --local multipler=0.1;
    local err1,multipler=GetMultipler();
    nlin1=nlin;
    local a=1;
    repeat
      dest[a]=dest[a]*multipler;
      a=a+5;
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
  table.insert(send,0xAA); --добавляем в таблицу первый элемент - идентификатор команды
  table.insert(send,0x02); --добавляем в таблицу второй элемент - текущие результаты измерений
  local sendmask={"byte","byte"}; --маска отправляемого запроса
  local dest={}; --массив полученных чисел
  local destmask={"float:2:0123","int32:2:0123","byte","byte"}; --маска принимаемого запроса
  local err,len;
  local n=0;
  repeat
    --посылка и получение запроса в устройство
    err,dest,len=server.SendAndReceiveDataByMask(0,2,sendmask,send,destmask,18);
    n=n+1;
    --условие выхода - корректный ответ или превышение запросов
  until err>=0 or n>=server.GetCurrentDeviceRetry()
  --обработка результатов
  if err>=0 then
    dest[5] = (10^ (dest[5] - 3 ));
    return true,dest[5];
  else
    return false,0; --запрос некорректен, возвращаем соответствующий флаг
  end;
end
---------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------
function OnInit()

   read=false;

   end
---------------------------------------------------------------------------
-- Uninitialization
---------------------------------------------------------------------------
function OnClose()
end
--
---------------------------------------------------------------------------
-- Processing
---------------------------------------------------------------------------

function OnRead()
  local errok;--={}; --массив полученных чисел
  if read==false
  then do
    local dest={}; --массив полученных чисел
    local deep=server.ReadSubDeviceExtProperty("Часов, почасового архива");
    --
    errok,dest=ReadECHOi4(deep); --Запрос данных с прибора
    --
    if errok<=0 then return;
    end;

    local a=1;
    repeat
      --
      Err,timesec = time.PackTime(2000+FromBCD(dest[a+4]),FromBCD(dest[a+3]),FromBCD(dest[a+2]),FromBCD(dest[a+1]),00,00);
      ts = time.TimeToTimeStamp(timesec,0);
      server.WriteCurrentTagToHda(dest[a],OPC_QUALITY_GOOD,ts)
      a=a+5;
      deep=deep-1;
    until deep<=0
    read=true;
    end;
    ------------------------
  else do
    local dest={}; --массив полученных чисел
    local deep=1;
    errok,dest=ReadECHOi4(deep); --Запрос данных с прибора

    if errok<=0 then return;
    end;

    local a=1;
    Err,timesec = time.PackTime(2000+FromBCD(dest[a+4]),FromBCD(dest[a+3]),FromBCD(dest[a+2]),FromBCD(dest[a+1]),00,00);
    ts = time.TimeToTimeStamp(timesec,0);

    server.WriteCurrentTag(dest[4],OPC_QUALITY_GOOD,ts);
    server.WriteCurrentTagToHda(dest[a],OPC_QUALITY_GOOD,ts)

    end;

    end;
  end
