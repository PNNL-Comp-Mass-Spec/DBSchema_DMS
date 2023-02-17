/****** Object:  StoredProcedure [dbo].[UpdateManagerControlParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.UpdateManagerControlParams
/****************************************************
**
**	Desc: 
**	Changes manager params for set of given managers
**  
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	jds
**	Date:	06/20/2007
**			07/27/2007 jds - Added support for parameters that do not exist for a manager
**			07/31/2007 grk - Factored out param change logic into 'SetParamForManagerList'
**			03/28/2008 jds - Renamed Paramx variables to ParamValx for clarity
**			04/16/2009 mem - Added optional parameter @callingUser; if provided, then SetParamForManagerList will populate field Entered_By with this name
**    
*****************************************************/
(
	@mode varchar(32),					-- Unused in this procedure
	@paramVal1 varchar(512),			-- New value to assign for parameter #1
	@param1Type varchar(50),			-- Parameter name #1
	@paramVal2 varchar(512),			-- New value to assign for parameter #2
	@param2Type varchar(50),			-- Parameter name #2
	@paramVal3 varchar(512),			-- etc.
	@param3Type varchar(50),
	@paramVal4 varchar(512),
	@param4Type varchar(50),
	@paramVal5 varchar(512),
	@param5Type varchar(50),
	@managerIDList varchar(2048),		-- manager ID values (numbers, not manager names)
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @message varchar(512)
	set @message = ''
	
	---------------------------------------------------
	-- Get list of managers to be updated
	---------------------------------------------------
	-- temp table to hold list
	--
	Create table #ManagerIDList(
		ID int
	)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to create temp table', 10, 1)
		return 51090
	end

	--Insert IDs into temp table
	--
	INSERT INTO #ManagerIDList
	SELECT Item FROM MakeTableFromList(@managerIDList)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to populate temp table', 10, 1)
		return 51091
	end

	-- remove managers that are not enabled for update
	--
	DELETE FROM #ManagerIDList
	WHERE ID IN
	(
		SELECT M_ID
		FROM T_Mgrs
		WHERE (M_ControlFromWebsite = 0)
	)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to remove disabled managers from temp table', 10, 1)
		return 51092
	end
	
	---------------------------------------------------
	-- Call SetParamForManagerList to update the managers
	---------------------------------------------------

	if IsNull(@param1Type, '') <> ''
	begin
		exec @myError = SetParamForManagerList @paramVal1, @param1Type, @message output, @callingUser
		if @myError <> 0
		begin
			RAISERROR (@message, 10, 1)
			return @myError
		end
	end
	--
	if IsNull(@param2Type, '') <> ''
	begin
		exec @myError = SetParamForManagerList @paramVal2, @param2Type, @message output, @callingUser
		if @myError <> 0
		begin
			RAISERROR (@message, 10, 1)
			return @myError
		end
	end
	--
	if IsNull(@param3Type, '') <> ''
	begin
		exec @myError = SetParamForManagerList @paramVal3, @param3Type, @message output, @callingUser
		if @myError <> 0
		begin
			RAISERROR (@message, 10, 1)
			return @myError
		end
	end
	--
	if IsNull(@param4Type, '') <> ''
	begin
		exec @myError = SetParamForManagerList @paramVal4, @param4Type, @message output, @callingUser
		if @myError <> 0
		begin
			RAISERROR (@message, 10, 1)
			return @myError
		end
	end
	--
	if IsNull(@param5Type, '') <> ''
	begin
		exec @myError = SetParamForManagerList @paramVal5, @param5Type, @message output, @callingUser
		if @myError <> 0
		begin
			RAISERROR (@message, 10, 1)
			return @myError
		end
	end

	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateManagerControlParams] TO [Mgr_Config_Admin] AS [dbo]
GO
