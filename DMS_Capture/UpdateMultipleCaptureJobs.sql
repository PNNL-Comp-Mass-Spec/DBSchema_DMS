/****** Object:  StoredProcedure [dbo].[UpdateMultipleCaptureJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateMultipleCaptureJobs
/****************************************************
**
**	Desc:
**      Updates capture jobs in list
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	01/04/2010 grk - initial release
**			01/14/2010 grk - enabled all modes
**			01/28/2010 grk - added UpdateParameters action
**			10/25/2010 mem - Now raising an error if @mode is empty or invalid
**			04/28/2011 mem - Set defaults for @action and @mode
**			03/24/2016 mem - Switch to using udfParseDelimitedIntegerList to parse the list of jobs
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW instead of RAISERROR
**
*****************************************************/
(
    @JobList varchar(6000),
    @action VARCHAR(32) = 'Retry',		-- Hold, Ignore, Release, Retry, UpdateParameters 
    @mode varchar(12) = 'Update',		-- Update or Preview
    @message varchar(512)= '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on
	
	-- Required to avoid warnings when RetrySelectedJobs is called
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_WARNINGS ON
	SET ANSI_PADDING ON

	declare @myError int = 0
	declare @myRowCount int = 0

	set @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'UpdateMultipleCaptureJobs', @raiseError = 1;
	
	If @authorized = 0
	Begin
		Throw 51000, 'Access denied', 1;
	End

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	if IsNull(@JobList, '') = ''
	begin
		set @message = 'Job list is empty';
		THROW 51001, @message, 1;
	end

	Set @Mode = IsNull(@mode, '')
	
	If Not @Mode IN ('Update', 'Preview')
	begin
		If @action = 'Retry'
			set @message = 'Mode should be Update when Action is Retry';
		Else
			set @message = 'Mode should be Update or Preview';
			
		THROW 51002, @message, 1;
	end
	
   	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'UpdateMultipleCaptureJobs'

   	---------------------------------------------------
	-- update parameters for jobs
	---------------------------------------------------

	IF @action = 'UpdateParameters' AND @mode = 'update'
	BEGIN --<update params>
		begin transaction @transName
		EXEC @myError = UpdateParametersForJob @jobList, @message  output, 0
		IF @myError <> 0
			rollback transaction @transName
		ELSE 
	 		commit transaction @transName
		GOTO Done
	END --<update params>


	IF @action = 'UpdateParameters' AND @mode = 'preview'
	BEGIN --<update params>
		GOTO Done
	END --<update params>

	---------------------------------------------------
	--  Create temporary table to hold list of jobs
	---------------------------------------------------
 
 	CREATE TABLE #SJL (
		Job INT,
		Dataset VARCHAR(256) NULL
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary job table';
		THROW 51003, @message, 1;
	end

 	---------------------------------------------------
	-- Populate table from job list  
	---------------------------------------------------

	INSERT INTO #SJL (Job)
	SELECT Distinct Value
	FROM dbo.udfParseDelimitedIntegerList(@jobList, ',')
	ORDER BY Value
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	if @myError <> 0
	begin
		set @message = 'Error populating temporary job table';
		THROW 51004, @message, 1;
	end

   	---------------------------------------------------
	-- future: verify that jobs exist?
	---------------------------------------------------
	--
	
	
   	---------------------------------------------------
	-- retry jobs
	---------------------------------------------------

	IF @action = 'Retry' AND @mode = 'update'
	BEGIN --<retry>
		begin transaction @transName
		EXEC @myError = RetrySelectedJobs @message output
		IF @myError <> 0
			rollback transaction @transName
		ELSE 
	 		commit transaction @transName
		GOTO Done
	END --<retry>

   	---------------------------------------------------
	-- Hold
	---------------------------------------------------
	IF @action = 'Hold' AND @mode = 'update'
	BEGIN --<hold>
		begin transaction @transName

		UPDATE
		  T_Jobs
		SET
		  State = 100
		WHERE
		  Job IN ( SELECT
					Job
				   FROM
					#SJL )
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		IF @myError <> 0
			rollback transaction @transName
		ELSE 
	 		commit transaction @transName
		GOTO Done
	END --<hold>

   	---------------------------------------------------
	-- Ignore
	---------------------------------------------------
	IF @action = 'Ignore' AND @mode = 'update'
	BEGIN --<Ignore>
		begin transaction @transName

		UPDATE
		  T_Jobs
		SET
		  State = 101
		WHERE
		  Job IN ( SELECT
					Job
				   FROM
					#SJL )
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		IF @myError <> 0
			rollback transaction @transName
		ELSE 
	 		commit transaction @transName
		GOTO Done
	END --<Ignore>

   	---------------------------------------------------
	-- Release
	---------------------------------------------------
	IF @action = 'Release' AND @mode = 'update'
	BEGIN --<Release>
		begin transaction @transName

		UPDATE
		  T_Jobs
		SET
		  State = 1
		WHERE
		  Job IN ( SELECT
					Job
				   FROM
					#SJL )
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		IF @myError <> 0
			rollback transaction @transName
		ELSE 
	 		commit transaction @transName
		GOTO Done
	END --<Release>

   	---------------------------------------------------
	-- delete?
	---------------------------------------------------

	-- RemoveSelectedJobs 0, @message output, 0

   	---------------------------------------------------
	-- if we reach this point, action was not implemented
	---------------------------------------------------
	
	SET @message = 'The ACTION "' + @action + '" is not implemented.'
	SET @myError = 1

   	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMultipleCaptureJobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateMultipleCaptureJobs] TO [DMS_SP_User] AS [dbo]
GO
