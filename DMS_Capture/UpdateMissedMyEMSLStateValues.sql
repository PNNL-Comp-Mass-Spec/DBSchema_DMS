/****** Object:  StoredProcedure [dbo].[UpdateMissedMyEMSLStateValues] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateMissedMyEMSLStateValues
/****************************************************
**
**  Desc:
**		Updates the MyEMSLState values for datasets and/or jobs
**		that have entries in T_MyEMSL_Uploads yet have
**		a MyEMSLState value of 0
**
**		This should normally not be necessary; thus, if any
**		updates are performed, we will post an error message
**		to the log
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	mem
**  Date:	09/10/2013 mem - Initial version
**    
*****************************************************/
(
	@WindowDays int = 30,
	@infoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	--
	set @WindowDays = IsNull(@WindowDays, 30)
	set @infoOnly = IsNull(@infoOnly, 0)
	set @message = ''
	
	If @WindowDays < 1
		Set @WindowDays = 1

	---------------------------------------------------
	-- Create a temporary table to hold the datasets or jobs that need to be updated
	---------------------------------------------------
	--
	CREATE TABLE #Tmp_IDsToUpdate
	(
		EntityID int NOT NULL
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_IDsToUpdate ON #Tmp_IDsToUpdate(EntityID)
	
	--------------------------------------------
	-- Look for datasets that have a value of 0 for MyEMSLState 
	-- and were uploaded to MyEMSL within the last @WindowDays days
	--------------------------------------------
	-- 
	INSERT INTO #Tmp_IDsToUpdate(EntityID)	
	SELECT DISTINCT LookupQ.Dataset_ID
	FROM S_DMS_T_Dataset_Archive DA
	     INNER JOIN ( SELECT Dataset_ID
	                  FROM T_MyEMSL_Uploads
	                  WHERE StatusURI_PathID > 1 AND
	                        Entered >= DATEADD(day, -@WindowDays, GETDATE()) AND
	                        ISNULL(Subfolder, '') = '' 
	                 ) LookupQ
	       ON DA.AS_Dataset_ID = LookupQ.Dataset_ID
	WHERE MyEMSLState < 1
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount > 0
	Begin
		Set @message = 'Found ' + Convert(varchar(12), @myRowCount) + ' dataset(s) that need MyEMSLState set to 1: '
		
		-- Append the dataset IDs
		SELECT @message = @message + Convert(varchar(12), EntityID) + ', '
		FROM #Tmp_IDsToUpdate
		
		-- Remove the trailing comma
		Set @message = Substring(@message, 1, Len(@message)-1)
		
		If @infoOnly > 0
			Print @message
		Else
		Begin
			UPDATE S_DMS_T_Dataset_Archive
			SET MyEMSLState = 1
			WHERE AS_Dataset_ID IN (SELECT EntityID FROM #Tmp_IDsToUpdate) AND
			      MyEMSLState < 1
			      
			exec PostLogEntry 'Error', @message, 'UpdateMissedMyEMSLStateValues'
		End
	End
	
	TRUNCATE TABLE #Tmp_IDsToUpdate
	
	
	--------------------------------------------
	-- Look for analysis jobs that have a value of 0 for AJ_MyEMSLState 
	-- and were uploaded to MyEMSL within the last @WindowDays days
	--------------------------------------------
	-- 		
	INSERT INTO #Tmp_IDsToUpdate(EntityID)	
	SELECT DISTINCT J.AJ_JobID
	FROM S_DMS_T_Analysis_Job J
	     INNER JOIN ( SELECT Dataset_ID,
	                         Subfolder
	                  FROM T_MyEMSL_Uploads
	                  WHERE StatusURI_PathID > 1 AND
	                        Entered >= DATEADD(day, -@WindowDays, GETDATE()) AND
	                        ISNULL(Subfolder, '') <> '' 
	                 ) LookupQ
	       ON J.AJ_DatasetID = LookupQ.Dataset_ID AND
	          J.AJ_ResultsFolderName = LookupQ.Subfolder
	WHERE J.AJ_MyEMSLState < 1
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount > 0
	Begin
		Set @message = 'Found ' + Convert(varchar(12), @myRowCount) + ' analysis job(s) that need MyEMSLState set to 1: '
		
		-- Append the Job IDs
		SELECT @message = @message + Convert(varchar(12), EntityID) + ', '
		FROM #Tmp_IDsToUpdate
		
		-- Remove the trailing comma
		Set @message = Substring(@message, 1, Len(@message)-1)
		
		If @infoOnly > 0
			Print @message
		Else
		Begin
		
			UPDATE S_DMS_T_Analysis_Job
			SET AJ_MyEMSLState = 1
			WHERE AJ_JobID IN (SELECT EntityID FROM #Tmp_IDsToUpdate) AND
			      AJ_MyEMSLState < 1
			      
			exec PostLogEntry 'Error', @message, 'UpdateMissedMyEMSLStateValues'
		End
	End
	
	return @myError
	
GO
