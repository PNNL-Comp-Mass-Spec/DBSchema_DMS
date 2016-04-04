USE master;

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET NOCOUNT ON;

-- --------------------------------------------------------------------------------------------------------
-- DROP OBJECTS IF THEY EXIST
-- --------------------------------------------------------------------------------------------------------
IF EXISTS ( SELECT  *
           FROM    sys.server_triggers
           WHERE   name = N'trig_Drop_Database_Safety_Catch' )
   BEGIN
       DROP TRIGGER trig_Drop_Database_Safety_Catch ON ALL SERVER;
   END;
GO
-- --------------------------------------------------------------------------------------------------------
-- CREATE THE SERVER TRIGGER
-- --------------------------------------------------------------------------------------------------------
/*
Name:
(C) Andy Jones
mailto:andrew@aejsoftware.co.uk

Description: -
Prohibits the dropping of a database. You first have to drop this trigger.

Change History: -
1.0 23/11/2015 Created.
*/
CREATE TRIGGER trig_Drop_Database_Safety_Catch ON ALL SERVER
   FOR DROP_DATABASE
AS
   SET NOCOUNT ON;

RAISERROR('Are you sure you want to drop this database? First disable or drop trigger trig_Drop_Database_Safety_Catch in the master database',16,1);
ROLLBACK;
GO
