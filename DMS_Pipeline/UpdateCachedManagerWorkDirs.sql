/****** Object:  StoredProcedure [dbo].[UpdateCachedManagerWorkDirs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateCachedManagerWorkDirs
/****************************************************
**
**	Desc:
**  Update the cached working directory for each manager
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**	Date:	10/05/2016 mem - Initial release
**
*****************************************************/
(    
    @infoOnly tinyint = 0
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int

	set @myError = 0
	set @myRowCount = 0
	
	Set @infoOnly = IsNull(@infoOnly, 0)

	Declare @message varchar(512)
	
	Declare @CallingProcName varchar(128)
	Declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	---------------------------------------------------
	-- Create a temporary table to cache the data
	---------------------------------------------------
	
	CREATE TABLE #Tmp_MgrWorkDirs (
	    ID             int NOT NULL,
	    Processor_Name varchar(128) NOT NULL,
	    MgrWorkDir     varchar(255) NULL
	)

	CREATE CLUSTERED INDEX IX_Tmp_MgrWorkDirs ON #Tmp_MgrWorkDirs (ID)
	
	Begin Try

	 	---------------------------------------------------
		-- Populate a temporary table with the new information
		-- Date in S_Manager_Control_V_MgrWorkDir will be of the form
		-- \\ServerName\C$\DMS_WorkDir1
		---------------------------------------------------
		--
		INSERT INTO #Tmp_MgrWorkDirs (ID, Processor_Name, MgrWorkDir)
		SELECT ID,
		       Processor_Name,
		       Replace(MgrWorkDirs.WorkDir_AdminShare, '\\ServerName\', '\\' + Machine + '\') AS MgrWorkDir
		FROM [S_Manager_Control_V_MgrWorkDir] MgrWorkDirs
		     INNER JOIN T_Local_Processors LP
		       ON MgrWorkDirs.M_Name = LP.Processor_Name
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	
		If @infoOnly <> 0		
		Begin
			SELECT Target.*, Src.MgrWorkDir AS MgrWorkDir_New
			FROM #Tmp_MgrWorkDirs Src
			     INNER JOIN T_Local_Processors Target
			       ON Src.Processor_Name = Target.Processor_Name
			WHERE Target.WorkDir_AdminShare <> Src.MgrWorkDir OR
			      Target.WorkDir_AdminShare IS NULL AND NOT Src.MgrWorkDir IS NULL

		End
		Else
		Begin
			UPDATE T_Local_Processors
			SET WorkDir_AdminShare = Src.MgrWorkDir
			FROM #Tmp_MgrWorkDirs Src
			     INNER JOIN T_Local_Processors Target
			       ON Src.Processor_Name = Target.Processor_Name
			WHERE Target.WorkDir_AdminShare <> Src.MgrWorkDir OR
			      Target.WorkDir_AdminShare IS NULL AND NOT Src.MgrWorkDir IS NULL
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			If @myRowCount > 0
			Begin
				Set @message = 'Updated WorkDir_AdminShare for ' + 
				               Cast(@myRowCount as Varchar(8)) + dbo.CheckPlural(@myRowCount, ' manager', ' managers') + 
				               ' in T_Local_Processors'

				exec PostLogEntry 'Normal', @message, 'UpdateCachedManagerWorkDirs'
			End
			
		End

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateCachedManagerWorkDirs')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output

	End Catch

 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
Done:
		
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedManagerWorkDirs] TO [DDL_Viewer] AS [dbo]
GO
