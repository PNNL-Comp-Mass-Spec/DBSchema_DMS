/****** Object:  StoredProcedure [dbo].[MakeNewJobsFromDMSArchiveReqd] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE MakeNewJobsFromDMSArchiveReqd
/****************************************************
**
**	Desc: 
**    create new jobs from DMS datasets 
**    that are in archive required state
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	12/17/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			01/30/2017 mem - Switch from DateDiff to DateAdd
**    
*****************************************************/
(
	@infoOnly tinyint = 0,
	@message varchar(512) output,
	@ImportWindowDays INT = 10,
	@LoggingEnabled TINYINT = 0
)
As
	Set nocount on
	
	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	---------------------------------------------------
	-- temp table to hold candidate jobs
	---------------------------------------------------

	CREATE TABLE #AUJobs(
		Dataset varchar(128),
		Dataset_ID int
		)

	---------------------------------------------------
	-- get datasets from DMS that are in archive required state
	---------------------------------------------------

	INSERT INTO #AUJobs( Dataset,
	                     Dataset_ID )
	SELECT Dataset,
	       Dataset_ID
	FROM V_DMS_Dataset_Archive_Status
	WHERE AS_state_ID = 1 AND
	      DS_state_ID = 3 AND
	      AS_state_Last_Affected > DateAdd(day, -@ImportWindowDays, GetDate())
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting candidate DatasetArchive steps'
		goto Done
	end

	---------------------------------------------------
	-- make jobs
	---------------------------------------------------
	--
	IF @infoOnly = 0
	BEGIN
		INSERT INTO T_Jobs (Script, Dataset, Dataset_ID, Comment)
		SELECT DISTINCT
		  'DatasetArchive' AS Script,
		  Dataset,
		  Dataset_ID,
		  'Created from direct DMS import' AS Comment
		FROM
		  #AUJobs			
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to add new DatasetArchive steps'
			goto Done
		end
	END


	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	If @LoggingEnabled = 1 AND @myError > 0 AND @message <> ''
	Begin
		exec PostLogEntry 'Error', @message, 'MakeNewJobsFromDMSArchiveReqd'
	End

GO
GRANT VIEW DEFINITION ON [dbo].[MakeNewJobsFromDMSArchiveReqd] TO [DDL_Viewer] AS [dbo]
GO
