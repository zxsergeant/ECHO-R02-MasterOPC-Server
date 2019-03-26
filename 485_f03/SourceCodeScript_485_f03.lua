-- ����� ���������� � ���� MODBUS �� ������� 03 (��� �� ������ 3.5 � ����) ��� MasterOPC Universal Modbus Server

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


-- ## �������� �������������� ��������� ������
err,Pu = modbus.ReadHoldingRegistersAsInt16( 9, 1, true,"10325476" );
if err==true then
server.message( "Connection error");
return;
end;
doublebyte = Pu[1];
--server.Message( "Pu1=",Pu[1] );
multiplier = bit.BitRshift ( doublebyte, 8 );
server.Message( "multiplier=",multiplier );

-- ## ������������ �������� ������
if value_qual==OPC_QUALITY_GOOD and multiplier>=0 and multiplier<=5 then
A = (10^ (multiplier - 3 ));
value = value * A;
--server.Message( "value=",value );
server.WriteCurrentTag( value,value_qual,aaa );
else server.WriteCurrentTag( 0, OPC_QUALITY_BAD );
end;


-- �������� ��� �������������, ���������� ��� � ���� ����������
doublebyte=bit.BitAnd( doublebyte, 255 );
server.Message( "ErrCode=",doublebyte );
server.WriteTagByRelativeName( "dev_status",doublebyte,value_qual );

end