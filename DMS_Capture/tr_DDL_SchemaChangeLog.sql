/****** Object:  DdlTrigger [tr_DDL_SchemaChangeLog] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [tr_DDL_SchemaChangeLog] ON DATABASE 
FOR DDL_DATABASE_LEVEL_EVENTS AS 

    SET NOCOUNT ON

    DECLARE @data XML
    DECLARE @schema SYSNAME
    DECLARE @object SYSNAME
    DECLARE @eventType SYSNAME

    SET @data = EVENTDATA()
    SET @eventType = @data.value('(/EVENT_INSTANCE/EventType)[1]', 'SYSNAME')
    SET @schema = @data.value('(/EVENT_INSTANCE/SchemaName)[1]', 'SYSNAME')
    SET @object = @data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'SYSNAME') 

    INSERT [dbo].[SchemaChangeLog] 
        (
        [CreateDate],
        [LoginName], 
        [ComputerName],
        [DBName],
        [SQLEvent], 
        [Schema], 
        [ObjectName], 
        [SQLCmd], 
        [XmlEvent]
        ) 
    SELECT
        GETDATE(),
        SUSER_NAME(), 
		HOST_NAME(),   
        @data.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'SYSNAME'),
        @eventType, 
        @schema, 
        @object, 
        @data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'), 
        @data
;
GO

ENABLE TRIGGER [tr_DDL_SchemaChangeLog] ON DATABASE
GO

