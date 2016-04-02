/****** Object:  StoredProcedure [dbo].[AddDatasetsToPredefinedSchedulingQueue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddDatasetsToPredefinedSchedulingQueue
/****************************************************
**
**	Desc:	Adds datasets to T_Predefined_Analysis_Scheduling_Queue
**			so that they can be checked against the predefined analysis job rules
**
**			Useful for processing a set of datasets after creating a new predefine
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	03/31/2016 mem - Initial Version
**
*****************************************************/
(
	@DatasetIDs varchar(4000) = '',			-- List of dataset IDs (comma, tab, or newline separated)	
	@InfoOnly tinyint = 0,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @DatasetIDs = IsNull(@DatasetIDs, '')
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @callingUser = IsNull(@callingUser, '')
	
	If @callingUser = ''
	Begin
		Set @callingUser = SUSER_SNAME()
	End
	
	---------------------------------------------------
	-- Create a temporary table to keep track of the datasets
	---------------------------------------------------

	CREATE TABLE #Tmp_DatasetsToProcess (
		Dataset_ID int NOT NULL,
		IsValid tinyint NOT NULL,
		AlreadyWaiting tinyint NOT NULL
	)

	INSERT INTO #Tmp_DatasetsToProcess (Dataset_ID, IsValid, AlreadyWaiting)
	SELECT DISTINCT Value, 0, 0
	FROM dbo.udfParseDelimitedIntegerList(@DatasetIDs, ',')	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	---------------------------------------------------
	-- Look for invalid dataset IDs
	---------------------------------------------------
	
	UPDATE #Tmp_DatasetsToProcess
	SET IsValid = 1
	FROM #Tmp_DatasetsToProcess Target
	     INNER JOIN T_Dataset DS
	       ON Target.Dataset_ID = DS.Dataset_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If Exists (SELECT * FROM #Tmp_DatasetsToProcess WHERE IsValid = 0)
	Begin
		Print 'One or more dataset IDs was not present in T_Dataset'
	End

	---------------------------------------------------
	-- Look for Datasets already present in T_Predefined_Analysis_Scheduling_Queue
	-- with state 'New'
	---------------------------------------------------

	UPDATE #Tmp_DatasetsToProcess
	SET AlreadyWaiting = 1
	FROM #Tmp_DatasetsToProcess Target
	     INNER JOIN T_Predefined_Analysis_Scheduling_Queue SchedQueue
	       ON Target.Dataset_ID = SchedQueue.Dataset_ID AND
	          SchedQueue.State = 'New'
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If Exists (SELECT * FROM #Tmp_DatasetsToProcess WHERE AlreadyWaiting = 1)
	Begin
		Print 'One or more dataset IDs is already in T_Predefined_Analysis_Scheduling_Queue with state "New"'
	End

	If @infoOnly > 0
	Begin
		SELECT Source.Dataset_ID,
		       CASE
		       WHEN AlreadyWaiting > 0 THEN 'Already in T_Predefined_Analysis_Scheduling_Queue with state "New"'
		       ELSE CASE
		            WHEN IsValid = 0 THEN 'Unknown dataset_id'
		            ELSE ''
		            END
		       END AS Error_Message,
		       @callingUser AS CallingUser,
		       '' AS AnalysisToolNameFilter,
		       1 AS ExcludeDatasetsNotReleased,
		       1 AS PreventDuplicateJobs,
		       'New' AS State
		FROM #Tmp_DatasetsToProcess Source
		     LEFT OUTER JOIN T_Dataset DS
		       ON Source.Dataset_ID = DS.Dataset_ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

	End
	Else
	Begin
		INSERT INTO T_Predefined_Analysis_Scheduling_Queue( Dataset_ID,
		                                                    CallingUser,
		                                                    AnalysisToolNameFilter,
		                                                    ExcludeDatasetsNotReleased,
		                                                    PreventDuplicateJobs,
		                                                    State,
		                                                    Message )
		SELECT Dataset_ID,
		       @callingUser,
		       '' AS AnalysisToolNameFilter,
		       1 AS ExcludeDatasetsNotReleased,
		       1 AS PreventDuplicateJobs,
		       'New' AS State,
		       '' AS Message
		FROM #Tmp_DatasetsToProcess
		WHERE IsValid = 1 And AlreadyWaiting = 0
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Print 'Added ' + Cast(@myRowCount as varchar(9)) + ' datasets to T_Predefined_Analysis_Scheduling_Queue'
		
	End

Done:
	return @myError



GO
