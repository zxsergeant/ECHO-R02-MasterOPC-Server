-- Опрос устройства в сети MODBUS по команде 03 (для ПО версии 3.5 и выше) для MasterOPC Universal Modbus Server

-- Initialization
function OnInit()
end
-- Uninitialization
function OnClose()
end
-- Processing
function OnRead()
--
local value, value_qual, doublebyte, multiplier, A, err, i;
local Pu, timestamp = {}
value,value_qual = server.ReadCurrentTag ();


-- ## получаем масштабирующий множитель объёма
err,Pu = modbus.ReadHoldingRegistersAsInt16( 9, 1, true,"10325476" );
if err==true then
server.message( "Connection error");
return;
end;
doublebyte = Pu[1];
--server.Message( "Pu1=",Pu[1] );
multiplier = bit.BitRshift ( doublebyte, 8 );
server.Message( "multiplier=",multiplier );

-- ## масштабируем значение объёма
if value_qual==OPC_QUALITY_GOOD and multiplier>=0 and multiplier<=5 then
A = (10^ (multiplier - 3 ));
value = value * A;
--server.Message( "value=",value );
server.WriteCurrentTag( value,value_qual,aaa );
else server.WriteCurrentTag( 0, OPC_QUALITY_BAD );
end;


-- получаем код неисправности, записываем его в свою переменную
doublebyte=bit.BitAnd( doublebyte, 255 );
server.Message( "ErrCode=",doublebyte );
server.WriteTagByRelativeName( "dev_status",doublebyte,value_qual );

end
