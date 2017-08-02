/****** Object:  StoredProcedure [dbo].[UpdateRunOpLog] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateRunOpLog
/****************************************************
**
**  Desc: 
**		Update selected items from instrument run 
**		tracking-related entities
**
**		@changes tracks the updates to be applied, in XML format
**		Example contents of @changes
**		<run request="206498" usage="USER" proposal="123456" user="1001" />
**		<interval id="268646" note="On hold pending scheduling,Broken[50%],CapDev[25%],StaffNotAvailable[25%],Operator[40677]" />
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:	grk
**  Date:	02/21/2013 grk - Initial release
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
	@changes TEXT, -- see formating note above
	@message VARCHAR(512) output,
	@callingUser VARCHAR(128) = ''
)
AS
	SET XACT_ABORT, NOCOUNT ON
	
	DECLARE @myError int = 0
	DECLARE @myRowCount int = 0
	SET @message = ''

	DECLARE @DebugMode tinyint = 0

	DECLARE @xml XML = CONVERT(XML, @changes)
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	DECLARE @prevID INT = 0
	DECLARE @curID INT = 0
	DECLARE @done INT = 0
	DECLARE @msg VARCHAR(512)

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'UpdateRunOpLog', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	BEGIN TRY

		-----------------------------------------------------------
		-- make temp table to hold requested run changes
		-- and populate it from the input XML
		-----------------------------------------------------------
		--
		CREATE TABLE #RRCHG (
			request int NULL,
			usage NVARCHAR(256) NULL,
			proposal NVARCHAR(256) NULL,
			[emsl_user] NVARCHAR(2048) NULL,
			statusID INT null
		)

		INSERT INTO #RRCHG
			(request, usage,  proposal,emsl_user)
		SELECT
			xmlNode.value('@request', 'nvarchar(256)') request,
			xmlNode.value('@usage', 'nvarchar(256)') usage,
			xmlNode.value('@proposal', 'nvarchar(256)') proposal,
			xmlNode.value('@user', 'nvarchar(256)') emsl_user
		FROM @xml.nodes('//run') AS R(xmlNode)

		-- get current status of request (needed for change log updating)
		UPDATE #RRCHG
		SET statusID = TRSN.State_ID
		FROM #RRCHG
		     INNER JOIN T_Requested_Run TRR
		       ON #RRCHG.request = TRR.ID
		     INNER JOIN T_Requested_Run_State_Name TRSN
		       ON TRR.RDS_Status = TRSN.State_Name

		---------------------------------------------------
		-- create temp table to hold interval changes
		-- and populate it from the input XML
		---------------------------------------------------
		
		CREATE TABLE #INTCHG (
			id int,
			note NVARCHAR(2048)
		)

		INSERT INTO #INTCHG
			(id, note)
		SELECT
			xmlNode.value('@id', 'nvarchar(256)') request,
			xmlNode.value('@note', 'nvarchar(2048)') note
		FROM @xml.nodes('//interval') AS R(xmlNode)

		-----------------------------------------------------------
		-- loop through requested run changes
		-- and validate and update
		-----------------------------------------------------------
		DECLARE 
			@AutoPopulateUserListIfBlank tinyint = 1,
			@eusUsageTypeID INT,
			@eusUsageType varchar(50),
			@eusProposalID varchar(10),
			@eusUsersList varchar(1024),
			@StatusID int
	
		SET @prevID = 0
		SET @curID = 0
		SET @done = 0
		WHILE @done = 0 
		BEGIN --<a>
			SET @curID = 0
			SELECT TOP 1 
				@curID = request,
				@prevID = request,
				@eusUsageType = usage,
				@eusProposalID = proposal,
				@eusUsersList = emsl_user,
				@StatusID = statusID
			FROM #RRCHG
			WHERE request > @prevID
			ORDER BY request
			
			IF @curID = 0
			BEGIN 
				SET @done = 1
			END
			ELSE 
			BEGIN --<c>
				exec @myError = ValidateEUSUsage
							@eusUsageType output,
							@eusProposalID output,
							@eusUsersList output,
							@eusUsageTypeID output,
							@msg output,
							@AutoPopulateUserListIfBlank
				if @myError <> 0
					RAISERROR ('ValidateEUSUsage: %s', 11, 1, @msg)

				-----------------------------------------------------------
				-- 
				-----------------------------------------------------------

				UPDATE T_Requested_Run 
				SET 
					RDS_EUS_Proposal_ID = @eusProposalID,
					RDS_EUS_UsageType = @eusUsageTypeID
				WHERE (ID = @curID)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
					RAISERROR ('Update operation failed: "%s"', 11, 4, @curID)

				-- If @callingUser is defined, then call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
				If Len(@callingUser) > 0
				Begin
					Exec AlterEventLogEntryUser 11, @curID, @StatusID, @callingUser
				End

				-- assign users to the request
				--
				exec @myError = AssignEUSUsersToRequestedRun
										@curID,
										@eusProposalID,
										@eusUsersList,
										@msg output
				if @myError <> 0
					RAISERROR ('AssignEUSUsersToRequestedRun: %s', 11, 20, @msg)
			END --<c>
		END --<a>

		---------------------------------------------------
		-- loop though long intervals and update 
		---------------------------------------------------
		DECLARE @comment varchar(MAX)

		SET @prevID = 0
		SET @curID = 0
		SET @done = 0
		WHILE @done = 0 
		BEGIN --<x>
			SET @curID = 0
			SELECT TOP 1 
				@curID = id,
				@prevID = id,
				@comment = note
			FROM #INTCHG
			WHERE id > @prevID
			ORDER BY id
			
			IF @curID = 0
			BEGIN 
				SET @done = 1
			END
			ELSE 
			BEGIN --<y>
				exec @myError = AddUpdateRunInterval
										@curID output,
										@comment,
										'update',
										@msg output,
										@callingUser 	
				if @myError <> 0
					RAISERROR ('AddUpdateRunInterval: %s', 11, 20, @msg)
			END --<y>
		END --<x>

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output

		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		Exec PostLogEntry 'Error', @message, 'UpdateRunOpLog'
	END CATCH
	
	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRunOpLog] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRunOpLog] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateRunOpLog] TO [DMS2_SP_User] AS [dbo]
GO
