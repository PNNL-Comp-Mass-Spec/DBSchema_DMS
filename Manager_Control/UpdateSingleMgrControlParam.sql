/****** Object:  StoredProcedure [dbo].[UpdateSingleMgrControlParam] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.UpdateSingleMgrControlParam
/****************************************************
**
**	Desc: 
**	Changes single manager params for set of given managers
**  
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	jds
**	Date:	06/20/2007
**			07/31/2007 grk - changed for 'controlfromwebsite' no longer a parameter
**			04/16/2009 mem - Added optional parameter @callingUser; if provided, then UpdateSingleMgrParamWork will populate field Entered_By with this name
**			04/08/2011 mem - Will now add parameter @paramValue to managers that don't yet have the parameter defined
**			04/21/2011 mem - Expanded @managerIDList to varchar(8000)
**			05/11/2011 mem - Fixed bug reporting error resolving @paramValue to @ParamTypeID
**			04/29/2015 mem - Now parsing @managerIDList using udfParseDelimitedIntegerList
**						   - Added parameter @infoOnly
**						   - Renamed the first parameter from @paramValue to @paramName
**    
*****************************************************/
(
	@paramName varchar(32),			-- The parameter name
	@newValue varchar(128),				-- The new value to assign for this parameter
	@managerIDList varchar(8000),		-- manager ID values (numbers, not manager names)
	@callingUser varchar(128) = '',
	@infoOnly tinyint = 0
)
As

	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @ParamTypeID int
	Declare @message varchar(512) = ''

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	-- Assure that @newValue is not null
	Set @newValue = IsNull(@newValue, '')
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	---------------------------------------------------
	-- Create a temporary table that will hold the Entry_ID 
	-- values that need to be updated in T_ParamValue
	---------------------------------------------------
	CREATE TABLE #TmpParamValueEntriesToUpdate (
		EntryID int NOT NULL
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_TmpParamValueEntriesToUpdate ON #TmpParamValueEntriesToUpdate (EntryID)

	CREATE TABLE #TmpMgrIDs (
		MgrID varchar(12) NOT NULL
	)

	---------------------------------------------------
	-- Resolve @paramName to @ParamTypeID
	---------------------------------------------------
	
	Set @ParamTypeID = -1
	
	SELECT @ParamTypeID = ParamID
	FROM T_ParamType
	WHERE ParamName = @paramName
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				

	If @myRowCount = 0
	Begin	
		Set @message = 'Error: Parameter ''' + @paramName + ''' not found in T_ParamType'
		RAISERROR (@message, 10, 1)
		Set @message = ''
		return 51309
	End

	---------------------------------------------------
	-- Parse the manager ID list
	---------------------------------------------------
	--
	INSERT INTO #TmpMgrIDs (MgrID)
	SELECT Cast(Value as varchar(12))
	FROM dbo.udfParseDelimitedIntegerList ( @managerIDList, ',' ) 
	
	If @infoOnly <> 0
	Begin
	
		
		SELECT PV.Entry_ID,
		       M.M_ID,
		       M.M_Name,
		       PV.ParamName,
		       PV.TypeID,
		       PV.[Value],
		       @newValue AS NewValue,
		       Case When IsNull(PV.[Value], '') <> @newValue Then 'Changed' Else 'Unchanged' End As Status
		FROM T_Mgrs M
		     INNER JOIN #TmpMgrIDs
		       ON M.M_ID = #TmpMgrIDs.MgrID
		     INNER JOIN V_ParamValue PV
		       ON PV.MgrID = M.M_ID AND
		          PV.TypeID = @ParamTypeID		
		WHERE M_ControlFromWebsite > 0		      
		UNION
		SELECT NULL AS Entry_ID,
		       M.M_ID,
		       M.M_Name,
		       @paramName,
		       @ParamTypeID,
		       NULL AS [Value],
		       @newValue AS NewValue,
		       'New'
		FROM T_Mgrs M
		     INNER JOIN #TmpMgrIDs
		       ON M.M_ID = #TmpMgrIDs.MgrID
		     LEFT OUTER JOIN T_ParamValue PV
		       ON PV.MgrID = M.M_ID AND
		          PV.TypeID = @ParamTypeID
		WHERE PV.TypeID IS NULL
		
	End
	Else
	Begin

		---------------------------------------------------
		-- Add new entries for Managers in @managerIDList that 
		-- don't yet have an entry in T_ParamValue for parameter @paramName
		--
		-- Adding value '##_DummyParamValue_##' so that 
		--  we'll force a call to UpdateSingleMgrParamWork
		---------------------------------------------------
		
		INSERT INTO T_ParamValue( TypeID,
		                          [Value],
		                          MgrID )
		SELECT @ParamTypeID,
		       '##_DummyParamValue_##',
		       #TmpMgrIDs.MgrID
		FROM T_Mgrs M
		     INNER JOIN #TmpMgrIDs
		       ON M.M_ID = #TmpMgrIDs.MgrID
		     LEFT OUTER JOIN T_ParamValue PV
		       ON PV.MgrID = M.M_ID AND
		          PV.TypeID = @ParamTypeID
		WHERE PV.TypeID IS NULL
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount				
		
		---------------------------------------------------
		-- Find the entries for the Managers in @managerIDList
		-- Populate #TmpParamValueEntriesToUpdate with the entries that need to be updated
		---------------------------------------------------
		--
		INSERT INTO #TmpParamValueEntriesToUpdate( EntryID )
		SELECT PV.Entry_ID
		FROM T_ParamValue PV
		     INNER JOIN T_Mgrs M
		       ON PV.MgrID = M.M_ID
		     INNER JOIN #TmpMgrIDs
		       ON M.M_ID = #TmpMgrIDs.MgrID
		WHERE M_ControlFromWebsite > 0 AND
		      PV.TypeID = @ParamTypeID AND
		      IsNull(PV.[Value], '') <> @newValue
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount				
		--
		if @myError <> 0
		begin
			RAISERROR ('Error finding Manager params to update', 10, 1)
			return 51309
		end

		---------------------------------------------------
		-- Call UpdateSingleMgrParamWork to perform the update, then call 
		-- AlterEnteredByUserMultiID and AlterEventLogEntryUserMultiID for @callingUser
		---------------------------------------------------
		--
		exec @myError = UpdateSingleMgrParamWork @paramName, @newValue, @callingUser
		
	End
	
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateSingleMgrControlParam] TO [Mgr_Config_Admin] AS [dbo]
GO
