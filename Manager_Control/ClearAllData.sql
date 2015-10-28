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
**	Date:	08/27/2015 mem - Initial release
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

		IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Table1_T_Table2')	
		  ALTER TABLE dbo.T_Job_Steps
			DROP CONSTRAINT FK_T_Table1_T_Table2

	End
	
	-------------------------------------------------
	-- Truncate tables
	-------------------------------------------------

	If @infoOnly = 0
	Begin
		Select 'Deleting data' AS Task
		
				
		DELETE T_ParamValue
		FROM T_Mgrs INNER JOIN
		   T_ParamValue ON T_Mgrs.M_ID = T_ParamValue.MgrID
		WHERE (NOT (T_Mgrs.M_Name LIKE 'proto-[5-6]%')) AND (NOT (T_Mgrs.M_Name LIKE 'pub-10%')) AND 
		   (NOT (T_Mgrs.M_Name LIKE '%params%')) AND (NOT (T_Mgrs.M_Name LIKE 'monroe%'))
		
		TRUNCATE TABLE T_ParamValue_OldManagers
		
		TRUNCATE TABLE T_OldManagers
		
		TRUNCATE TABLE T_Log_Entries
		
		TRUNCATE TABLE T_Event_Log
				
		Select 'Deletion Complete' AS Task
	End
	Else
	Begin
		SELECT 'T_ParamValue_OldManagers'
		UNION
		SELECT 'T_OldManagers'
		UNION
		SELECT 'T_Log_Entries'
		UNION
		SELECT 'T_Event_Log'
		
		ORDER BY 1
		
	End

	-------------------------------------------------
	-- Add back foreign keys
	-------------------------------------------------

	If @infoOnly = 0
	Begin
		-- Nothing to do here
		Set @myError = @myError
	End
			
Done:
	If @message <> ''
		Print @message
		
	return @myError

GO
