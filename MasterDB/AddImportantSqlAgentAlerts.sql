-- Add important SQL Agent Alerts
-- Change Alert names and operator_name as needed
-- Glenn Berry
-- SQLskills
-- 9-10-2012
--
-- Downloaded from http://www.simple-talk.com/sql/database-administration/provisioning-a-new-sql-server-instance-%E2%80%93-part-three
--
-- Additional alerts added 3/25/2013 based on guidance at http://www.brentozar.com/blitz/configure-sql-server-alerts/

USE [msdb];
GO

-- Change @OperatorName as needed
-- Alert Names start with the name of the server
DECLARE @OperatorName SYSNAME = N'Matthew Monroe';
DECLARE @Sev16AlertName SYSNAME = N'MonroeAlert - Sev 16 Warning: Execution Problem';
DECLARE @Sev17AlertName SYSNAME = N'MonroeAlert - Sev 17 Error: Insufficient Resources';
DECLARE @Sev18AlertName SYSNAME = N'MonroeAlert - Sev 18 Error: Nonfatal Internal Error Detected';
DECLARE @Sev19AlertName SYSNAME = N'MonroeAlert - Sev 19 Error: Fatal Error in Resource';
DECLARE @Sev20AlertName SYSNAME = N'MonroeAlert - Sev 20 Error: Fatal Error in Current Process';
DECLARE @Sev21AlertName SYSNAME = N'MonroeAlert - Sev 21 Error: Fatal Error in Database Process';
DECLARE @Sev22AlertName SYSNAME = N'MonroeAlert - Sev 22 Error: Fatal Error: Table Integrity Suspect';
DECLARE @Sev23AlertName SYSNAME = N'MonroeAlert - Sev 23 Error: Fatal Error Database Integrity Suspect';
DECLARE @Sev24AlertName SYSNAME = N'MonroeAlert - Sev 24 Error: Fatal Hardware Error';
DECLARE @Sev25AlertName SYSNAME = N'MonroeAlert - Sev 25 Error: Fatal Error';
DECLARE @Error823AlertName SYSNAME = N'MonroeAlert - Error 823: I/O subsystem problem';
DECLARE @Error824AlertName SYSNAME = N'MonroeAlert - Error 824: I/O subsystem problem';
DECLARE @Error825AlertName SYSNAME = N'MonroeAlert - Error 825: Read-Retry Required';


-- Sev 16 Warning
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev16AlertName)
Begin
	EXEC msdb.dbo.sp_add_alert @name = @Sev16AlertName, 
	              @message_id=0, 
	              @Severity=16, 
	              @enabled=1, 
	              @delay_between_responses=900, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000';
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev16AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Sev 17 Error: Insufficient Resources
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev17AlertName)
Begin
	EXEC msdb.dbo.sp_add_alert @name = @Sev17AlertName, 
	              @message_id=0, 
	              @Severity=17, 
	              @enabled=1, 
	              @delay_between_responses=900, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000';
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev17AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Sev 18 Error: Nonfatal Internal Error Detected
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev18AlertName)
Begin
	EXEC msdb.dbo.sp_add_alert @name = @Sev18AlertName, 
	              @message_id=0, 
	              @Severity=18, 
	              @enabled=1, 
	              @delay_between_responses=900, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000';
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev18AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Sev 19 Error: Fatal Error in Resource
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev19AlertName)
Begin
	EXEC msdb.dbo.sp_add_alert @name = @Sev19AlertName, 
	              @message_id=0, 
	              @Severity=19, 
	              @enabled=1, 
	              @delay_between_responses=60, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000';
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev19AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Sev 20 Error: Fatal Error in Current Process
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev20AlertName)
Begin	
	EXEC msdb.dbo.sp_add_alert @name = @Sev20AlertName, 
	              @message_id=0, 
	              @Severity=20, 
	              @enabled=1, 
	              @delay_between_responses=60, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000'
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev20AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Sev 21 Error: Fatal Error in Database Process
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev21AlertName)
Begin	
	EXEC msdb.dbo.sp_add_alert @name = @Sev21AlertName, 
	              @message_id=0, 
	              @Severity=21, 
	              @enabled=1, 
	              @delay_between_responses=60, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000'
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev21AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Sev 22 Error: Fatal Error Table Integrity Suspect
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev22AlertName)
Begin	
	EXEC msdb.dbo.sp_add_alert @name = @Sev22AlertName, 
	              @message_id=0, 
	              @Severity=22, 
	              @enabled=1, 
	              @delay_between_responses=60, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000'
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev22AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Sev 23 Error: Fatal Error Database Integrity Suspect
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev23AlertName)
Begin	
	EXEC msdb.dbo.sp_add_alert @name = @Sev23AlertName, 
	              @message_id=0, 
	              @Severity=23, 
	              @enabled=1, 
	              @delay_between_responses=60, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000'
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev23AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Sev 24 Error: Fatal Hardware Error
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev24AlertName)
Begin	
	EXEC msdb.dbo.sp_add_alert @name = @Sev24AlertName, 
	              @message_id=0, 
	              @Severity=24, 
	              @enabled=1, 
	              @delay_between_responses=60, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000'
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev24AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Sev 25 Error: Fatal Error
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Sev25AlertName)
Begin
	EXEC msdb.dbo.sp_add_alert @name = @Sev25AlertName, 
	              @message_id=0, 
	              @Severity=25, 
	              @enabled=1, 
	              @delay_between_responses=60, 
	              @include_event_description_in=1, 
	              @job_id=N'00000000-0000-0000-0000-000000000000'
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Sev25AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Error 823
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Error823AlertName)
Begin
	EXEC msdb.dbo.sp_add_alert @name = @Error823AlertName, 
	              @message_id=823, 
	              @Severity=0, 
	              @enabled=1, 
	              @delay_between_responses=900, 
	              @include_event_description_in=1, 
	              @category_name=N'[Uncategorized]', 
	              @job_id=N'00000000-0000-0000-0000-000000000000';
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Error823AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

-- Error 824
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Error824AlertName)
Begin
	EXEC msdb.dbo.sp_add_alert @name = @Error824AlertName, 
	              @message_id=824, 
	              @Severity=0, 
	              @enabled=1, 
	              @delay_between_responses=900, 
	              @include_event_description_in=1, 
	              @category_name=N'[Uncategorized]', 
	              @job_id=N'00000000-0000-0000-0000-000000000000';
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Error824AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End


-- Error 825: Read-Retry Required
If Not Exists (SELECT * FROM msdb.dbo.sysalerts where name = @Error825AlertName)
Begin
	EXEC msdb.dbo.sp_add_alert @name = @Error825AlertName, 
	              @message_id=825, 
	              @Severity=0, 
	              @enabled=1, 
	              @delay_between_responses=900, 
	              @include_event_description_in=1, 
	              @category_name=N'[Uncategorized]', 
	              @job_id=N'00000000-0000-0000-0000-000000000000';
	
	EXEC msdb.dbo.sp_add_notification @alert_name = @Error825AlertName, 
	@operator_name=@OperatorName, @notification_method = 1;
End

GO