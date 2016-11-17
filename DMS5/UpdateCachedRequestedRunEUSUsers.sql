/****** Object:  StoredProcedure [dbo].[UpdateCachedRequestedRunEUSUsers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE UpdateCachedRequestedRunEUSUsers
/****************************************************
**
**	Desc:	Updates the data in T_Active_Requested_Run_Cached_EUS_Users
**			This table tracks the list of EUS users for each active requested run
**
**			We only track active requested runs because V_Scheduled_Run_Export
**			only returns active requested runs, and that view is the primary
**			beneficiary of T_Active_Requested_Run_Cached_EUS_Users
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	11/16/2016 mem - Initial Version
**
*****************************************************/
(
	@RequestID int = 0,					-- Specific Request to update, or 0 to update all active Requested Runs
	@message varchar(255) = '' output
)
AS

	Set XACT_ABORT, nocount on

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Set @RequestID = IsNull(@RequestID, 0)
	set @message = ''

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'	
	
	Begin Try

		If @RequestID <> 0
		Begin
			-- Updating a specific requested run
			If Not Exists (SELECT * FROM T_Requested_Run WHERE RDS_Status = 'Active' AND ID = @RequestID)
			Begin
				-- The request is not active; assure there is no cached entry
				If Exists (SELECT * FROM T_Active_Requested_Run_Cached_EUS_Users WHERE Request_ID = @RequestID)
				Begin			
					DELETE T_Active_Requested_Run_Cached_EUS_Users 
					WHERE Request_ID = @RequestID
				End
				
				Goto Done
			End
		End
	
		-- Updating all active requested runs
		-- or updating a single, active requested run
		
		set ansi_warnings off

		MERGE T_Active_Requested_Run_Cached_EUS_Users AS t
		USING (SELECT ID AS Request_ID, 
					dbo.GetRequestedRunEUSUsersList(ID, 'V') AS User_List
			FROM T_Requested_Run
			WHERE RDS_Status = 'Active' AND (@RequestID = 0 OR ID = @RequestID)
		) AS s
		ON ( t.Request_ID = s.Request_ID)
		WHEN MATCHED AND (
			ISNULL( NULLIF(t.User_List, s.User_List),
					NULLIF(s.User_List, t.User_List)) IS NOT NULL
			)
		THEN UPDATE SET 
			User_List = s.User_List
		WHEN NOT MATCHED BY TARGET THEN
			INSERT(Request_ID, User_List)
			VALUES(s.Request_ID, s.User_List)
		WHEN NOT MATCHED BY SOURCE AND @RequestID = 0 THEN DELETE;
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	
		set ansi_warnings on
		
		If @myError <> 0
		begin
			set @message = 'Error updating T_Active_Requested_Run_Cached_EUS_Users via merge (ErrorID = ' + Convert(varchar(12), @myError) + ')'
			execute PostLogEntry 'Error', @message, 'UpdateCachedRequestedRunEUSUsers'
			goto Done
		end

	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateCachedRequestedRunEUSUsers')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch
			
Done:
	Return @myError

GO
