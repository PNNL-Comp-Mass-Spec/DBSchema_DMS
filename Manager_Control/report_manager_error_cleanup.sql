/****** Object:  StoredProcedure [dbo].[ReportManagerErrorCleanup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ReportManagerErrorCleanup 
/****************************************************
**
**	Desc: 
**		Reports that the manager tried to auto-cleanup
**		when there is a flag file or non-empty working directory
**
**	Auth:	mem
**	Date:	09/10/2009 mem - Initial version
**
*****************************************************/
(
	@ManagerName varchar(128),
	@State int = 0,					-- 1 = Cleanup Attempt start, 2 = Cleanup Successful, 3 = Cleanup Failed
	@FailureMsg varchar(512) = '',
	@message varchar(512) = '' output
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Declare @MgrID int	
	Declare @MgrNameLocal varchar(128)
	Declare @ParamID int

	Declare @MessageType varchar(64)
	
	Declare @CleanupMode varchar(256)
	
	---------------------------------------------------
	-- Cleanup the inputs
	---------------------------------------------------
	
	Set @ManagerName = IsNull(@ManagerName, '')
	Set @State = IsNull(@State, 0)
	Set @FailureMsg = IsNull(@FailureMsg, '')
	Set @message = ''
	
	---------------------------------------------------
	-- Confirm that the manager name is valid
	---------------------------------------------------

	SELECT  @MgrID = M_ID,
			@MgrNameLocal = M_Name
	FROM T_Mgrs
	WHERE (M_Name = @ManagerName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	if @myRowCount <> 1
	begin
		set @myError = 52002
		set @message = 'Could not find entry for manager: ' + @ManagerName
		goto Done
	end

	Set @ManagerName = @MgrNameLocal
	
	---------------------------------------------------
	-- Validate @State
	---------------------------------------------------
	
	If @State < 1 or @State > 3
	Begin
		set @myError = 52003
		set @message = 'Invalid value for @State; should be 1, 2 or 3'
		goto Done
	End
	
	---------------------------------------------------
	-- Log this cleanup event
	---------------------------------------------------
	
	Set @MessageType = 'Error'
	Set @Message = 'Unknown @State value'
	
	If @State = 1
	Begin
		Set @MessageType = 'Normal'
		Set @Message = 'Manager ' + @ManagerName + ' is attempting auto error cleanup'
	End

	If @State = 2
	Begin
		Set @MessageType = 'Normal'
		Set @Message = 'Automated error cleanup succeeded for ' + @ManagerName
	End

	If @State = 3
	Begin
		Set @MessageType = 'Normal'
		Set @Message = 'Automated error cleanup failed for ' + @ManagerName
		If @FailureMsg <> ''
			Set @message = @message + '; ' + @FailureMsg
	End
	
	Exec PostLogEntry @MessageType, @Message, 'ReportManagerErrorCleanup'

	---------------------------------------------------
	-- Lookup the value of ManagerErrorCleanupMode in T_ParamValue
	---------------------------------------------------

	Set @CleanupMode = '0'
	
	SELECT @CleanupMode = T_ParamValue.Value
	FROM T_ParamValue
	     INNER JOIN T_ParamType
	       ON T_ParamValue.TypeID = T_ParamType.ParamID
	WHERE (T_ParamType.ParamName = 'ManagerErrorCleanupMode') AND
	      (T_ParamValue.MgrID = @MgrID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	    
	If @myRowCount = 0
	Begin
		-- Entry not found; make a new entry for 'ManagerErrorCleanupMode' in the T_ParamValue table
		Set @ParamID = 0
		
		SELECT @ParamID = ParamID
		FROM T_ParamType
		WHERE (ParamName = 'ManagerErrorCleanupMode')
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @ParamID > 0
		Begin
			INSERT INTO T_ParamValue (MgrID, TypeID, Value)
			VALUES (@MgrID, @ParamID, '0')
			
			Set @CleanupMode = '0'
		End
	End
	
	If LTrim(RTrim(@CleanupMode)) = '1'
	Begin
		-- Manager is set to auto-cleanup only once; change 'ManagerErrorCleanupMode' to 0
		UPDATE T_ParamValue
		SET Value = '0'
		FROM T_ParamValue
		     INNER JOIN T_ParamType
		       ON T_ParamValue.TypeID = T_ParamType.ParamID
		WHERE (T_ParamType.ParamName = 'ManagerErrorCleanupMode') AND
		      (T_ParamValue.MgrID = @MgrID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		if @myError <> 0
		Begin
			Set @Message = 'Error setting ManagerErrorCleanupMode to 0 in T_ParamValue for manager ' + @ManagerName
			Exec PostLogEntry 'Error', @message, 'ReportManagerErrorCleanup'
		End
		Else
		Begin
			If @myRowCount = 0
				Set @message = @Message + '; Entry not found in T_ParamValue for ManagerErrorCleanupMode; this is unexpected'
			Else
				Set @message = @Message + '; Decremented ManagerErrorCleanupMode to 0 in T_ParamValue'
		End
	End
	

	---------------------------------------------------
	-- Exit the procedure
	---------------------------------------------------
Done:
	return @myError
	
GO
GRANT EXECUTE ON [dbo].[ReportManagerErrorCleanup] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportManagerErrorCleanup] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportManagerErrorCleanup] TO [svc-dms] AS [dbo]
GO
