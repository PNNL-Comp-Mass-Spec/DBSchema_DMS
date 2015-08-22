/****** Object:  StoredProcedure [dbo].[ClearAllData] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE ClearAllData
/****************************************************
** 
**	Desc: 
**		This is a DANGEROUS procedure that will clear all
**		data from all of the tables in this database
**
**		This is useful for creating test databases
**		or for migrating the DMS databases to a new laboratory
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	08/20/2015 mem - Initial release
**    
*****************************************************/
(
	@ServerNameFailsafe varchar(64) = 'Pass in the name of the current server to confirm that you truly want to delete data',
	@CurrentDateFailsafe varchar(64) = 'Enter the current date, in the format yyyy-mm-dd',
	@infoOnly tinyint = 1,
	@message varchar(255) = '' output
)
As
	Set NoCount On
	
	declare @myRowCount int
	declare @myError int
	set @myRowCount = 0
	set @myError = 0

	set @infoOnly = IsNull(@infoOnly, 1)
	set @message = ''

	-------------------------------------------------
	-- Verify that we truly should do this
	-------------------------------------------------
	
	If @ServerNameFailsafe <> @@ServerName
	Begin
		set @message = 'You must enter the name of the server hosting this database'		
		Goto Done
	End
	
	Declare @userDate date 
	set @userDate = Convert(date, @CurrentDateFailsafe)
	
	If IsNull(@userDate, '') = '' OR @userDate <> Cast(GetDate() as Date)
	Begin
		set @message = 'You must set @CurrentDateFailsafe to the current date, in the form yyyy-mm-dd'		
		Goto Done
	End

	-------------------------------------------------
	-- Remove foreign keys
	-------------------------------------------------

	If @infoOnly = 0
	Begin

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Job_Steps_T_Step_Tool_Versions')	
		  ALTER TABLE dbo.T_Job_Steps
			DROP CONSTRAINT FK_T_Job_Steps_T_Step_Tool_Versions
		
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Job_Steps_T_Jobs')	
		  ALTER TABLE dbo.T_Job_Steps
			DROP CONSTRAINT FK_T_Job_Steps_T_Jobs
		
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Job_Step_Dependencies_T_Job_Steps')	
		  ALTER TABLE dbo.T_Job_Step_Dependencies
			DROP CONSTRAINT FK_T_Job_Step_Dependencies_T_Job_Steps

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Job_Parameters_T_Jobs')	
		  ALTER TABLE dbo.T_Job_Parameters
			DROP CONSTRAINT FK_T_Job_Parameters_T_Jobs

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_MyEMSL_Uploads_T_URI_Paths_StatusURI')	
		  ALTER TABLE dbo.T_MyEMSL_Uploads
			DROP CONSTRAINT FK_T_MyEMSL_Uploads_T_URI_Paths_StatusURI
		
		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_MyEMSL_Uploads_T_URI_Paths_ContentURI')	
		  ALTER TABLE dbo.T_MyEMSL_Uploads
			DROP CONSTRAINT FK_T_MyEMSL_Uploads_T_URI_Paths_ContentURI
		
	End
	
	-------------------------------------------------
	-- Truncate tables
	-------------------------------------------------

	If @infoOnly = 0
	Begin
		Select 'Deleting data' AS Task

		TRUNCATE TABLE T_Dataset_Info_XML
		TRUNCATE TABLE T_Job_Events
		TRUNCATE TABLE T_Job_Parameters
		TRUNCATE TABLE T_Job_Parameters_History
		TRUNCATE TABLE T_Job_Step_Dependencies		
		TRUNCATE TABLE T_Job_Step_Dependencies_History
		TRUNCATE TABLE T_Job_Step_Events
		TRUNCATE TABLE T_Job_Step_Processing_Log
		TRUNCATE TABLE T_Job_Step_Status_History
		TRUNCATE TABLE T_Job_Steps
		TRUNCATE TABLE T_Job_Steps_History
		TRUNCATE TABLE T_Jobs
		TRUNCATE TABLE T_Jobs_History
		TRUNCATE TABLE T_MyEMSL_Uploads
		
		DELETE FROM T_Local_Processors WHERE Not Processor_Name LIKE 'Proto-5%'
		DELETE FROM T_Machines WHERE Not Machine LIKE 'Proto-5%'
		
		DELETE FROM T_Processor_Tool
		WHERE (NOT Processor_Name LIKE 'proto-5%')
		
		DELETE FROM T_Processor_Instrument
		WHERE (Instrument_Name <> '15T_FTICR')

		TRUNCATE TABLE T_Log_Entries
		TRUNCATE TABLE T_Processor_Status
		
		TRUNCATE TABLE T_Scripts_History
		TRUNCATE TABLE T_Step_Tool_Versions
		TRUNCATE TABLE T_URI_Paths
		
		Select 'Deletion Complete' AS Task
	End
	Else
	Begin
		SELECT 'T_Dataset_Info_XML'
		UNION
		SELECT 'T_Data_Folder_Create_Queue'
		UNION
		SELECT 'T_Job_Events'
		UNION
		SELECT 'T_Job_Parameters'
		UNION
		SELECT 'T_Job_Parameters_History'
		UNION
		SELECT 'T_Job_Step_Dependencies		'
		UNION
		SELECT 'T_Job_Step_Dependencies_History'
		UNION
		SELECT 'T_Job_Step_Events'
		UNION
		SELECT 'T_Job_Step_Processing_Log'
		UNION
		SELECT 'T_Job_Step_Status_History'
		UNION
		SELECT 'T_Job_Steps'
		UNION
		SELECT 'T_Job_Steps_History'
		UNION
		SELECT 'T_Jobs'
		UNION
		SELECT 'T_Jobs_History'
		UNION
		SELECT 'T_Local_Processors'
		UNION
		SELECT 'T_Machines'
		UNION
		SELECT 'T_MyEMSL_Uploads'
		UNION
		SELECT 'T_Processor_Tool'
		UNION
		SELECT 'T_URI_Paths'
		UNION
		SELECT 'T_Log_Entries'
		UNION
		SELECT 'T_Processor_Status'
		UNION
		SELECT 'T_Scripts_History'
		UNION
		SELECT 'T_Step_Tool_Versions'
		ORDER BY 1
		
	End

	-------------------------------------------------
	-- Add back foreign keys
	-------------------------------------------------

	If @infoOnly = 0
	Begin
		alter table T_Job_Parameters add
			constraint FK_T_Job_Parameters_T_Jobs foreign key(Job) references T_Jobs(Job) on delete cascade;
	
		alter table T_Job_Steps add
			constraint FK_T_Job_Steps_T_Step_Tool_Versions foreign key(Tool_Version_ID) references T_Step_Tool_Versions(Tool_Version_ID),
			constraint FK_T_Job_Steps_T_Jobs foreign key(Job) references T_Jobs(Job) on delete cascade;
	
		alter table T_Job_Step_Dependencies add
			constraint FK_T_Job_Step_Dependencies_T_Job_Steps foreign key(Job,Step_Number) references T_Job_Steps(Job,Step_Number) on update cascade on delete cascade;

		alter table T_MyEMSL_Uploads add
			constraint FK_T_MyEMSL_Uploads_T_URI_Paths_StatusURI foreign key(StatusURI_PathID) references T_URI_Paths(URI_PathID),
			constraint FK_T_MyEMSL_Uploads_T_URI_Paths_ContentURI foreign key(ContentURI_PathID) references T_URI_Paths(URI_PathID);

	End
			
Done:
	If @message <> ''
		Print @message
		
	return @myError

GO
