-- Initialization
function OnInit()
end
-- Uninitialization
function OnClose()
end
-- Processing
function OnBeforeReading()
end
-- Processing
function OnAfterReading()
  --------------------------------------------------------------------------------
  -- Функция #66 получение текщих результатов измерений с устройства
  --------------------------------------------------------------------------------
  local send={}; --массив отправляемых чисел
  table.insert(send,server.GetCurrentDeviceAddress( )); -- адрес устройства
  table.insert(send,0x66); --собственно сама команда
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
    server.WriteTagByRelativeName("Status",dest[9],OPC_QUALITY_GOOD);
    server.WriteTagByRelativeName("H",dest[4],OPC_QUALITY_GOOD);
    server.WriteTagByRelativeName("Q",dest[5]*3600,OPC_QUALITY_GOOD);
    --масштабируем значение объёма
    dest[8] = (10^ (dest[8] - 3 ));
    dest[6] = dest[6] * dest[8];
    server.WriteTagByRelativeName("U",dest[6],OPC_QUALITY_GOOD);
    server.WriteTagByRelativeName("Working_time",dest[7],OPC_QUALITY_GOOD);
  else
    server.WriteTagByRelativeName("Status",0,OPC_QUALITY_BAD);
    server.WriteTagByRelativeName("H",0,OPC_QUALITY_BAD);
    server.WriteTagByRelativeName("Q",0,OPC_QUALITY_BAD);
    server.WriteTagByRelativeName("U",0,OPC_QUALITY_BAD);
    server.WriteTagByRelativeName("Working_time",0,OPC_QUALITY_BAD);
    return false,0; --запрос некорректен, возвращаем соответствующий флаг
    end;
  end
