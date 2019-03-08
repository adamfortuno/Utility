SELECT CAST(record as xml).value('(/Record/@id)[1]', 'int') AS [RecordID]
, CAST(record as xml).value('(/Record/ConnectivityTraceRecord/RecordTime)[1]', 'datetime') AS [RecordTime]
, CAST(record as xml).value('(/Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(max)') AS [RecordType]
, CAST(record as xml).value('(/Record/ConnectivityTraceRecord/Spid)[1]', 'varchar(max)') AS [SPID]
, CAST(record as xml).value('(/Record/ConnectivityTraceRecord/RemoteHost)[1]', 'varchar(max)') AS [RemoteHost]
, CAST(record as xml).value('(/Record/ConnectivityTraceRecord/RemotePort)[1]', 'int') AS [RemotePort]
, CAST(record as xml).value('(/Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'smallint') AS [ErrorNumber]
, CAST(record as xml).value('(/Record/ConnectivityTraceRecord/State)[1]', 'tinyint') AS [ErrorState]
, CAST(record AS XML) AS [msg]
FROM sys.dm_os_ring_buffers rbuff
WHERE rbuff.ring_buffer_type = 'RING_BUFFER_CONNECTIVITY'
--AND CAST(record as xml).value('(/Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(max)') = 'Error'
ORDER BY CAST(record as xml).value('(/Record/ConnectivityTraceRecord/RecordTime)[1]', 'datetime') ASC;

select * 
from sys.dm_exec_connections 
where client_net_address IN ('10.152.51.141', '10.152.51.142')