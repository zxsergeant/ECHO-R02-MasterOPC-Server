-- Initialization
function OnInit()
end
-- Uninitialization
function OnClose()
end
-- Processing
function OnBeforeReading()
end

--------------------------------------------------------------------------------
-- Функция получения текщих результатов измерений с устройства по RS232
--------------------------------------------------------------------------------
function OnAfterReading()
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
    --server.WriteCurrentTag(dest[6],OPC_QUALITY_GOOD);
    server.WriteTagByRelativeName("Status",dest[6],OPC_QUALITY_GOOD);
    server.WriteTagByRelativeName("H",dest[1],OPC_QUALITY_GOOD);
    server.WriteTagByRelativeName("Q",dest[2]*3600,OPC_QUALITY_GOOD);
    --масштабируем значение объёма
    --if dest[5]>=0 and dest[5]<=5 then
    dest[5] = (10^ (dest[5] - 3 ));
    dest[3] = dest[3] * dest[5];
    server.WriteTagByRelativeName("U",dest[3],OPC_QUALITY_GOOD);
    server.WriteTagByRelativeName("Working_time",dest[4],OPC_QUALITY_GOOD);
    --end;
  else
    --server.WriteCurrentTag(0,OPC_QUALITY_BAD);
    server.WriteTagByRelativeName("Status",0,OPC_QUALITY_BAD);
    server.WriteTagByRelativeName("H",0,OPC_QUALITY_BAD);
    server.WriteTagByRelativeName("Q",0,OPC_QUALITY_BAD);
    server.WriteTagByRelativeName("U",0,OPC_QUALITY_BAD);
    server.WriteTagByRelativeName("Working_time",0,OPC_QUALITY_BAD);
    return false,0; --запрос некорректен, возвращаем соответствующий флаг
  end;
 end
