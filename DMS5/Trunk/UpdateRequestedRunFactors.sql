/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateRequestedRunFactors
/****************************************************
**
**	Desc: 
**	Update requested run factors from input XML list 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: grk
**	02/20/2010 grk - initial release
**	03/17/2010 grk - expanded blacklist
**	03/22/2010 grk - allow datset id
**    
*****************************************************/
	@factorList text,
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = ''
As
	SET NOCOUNT ON 

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	SET @message = ''

	-----------------------------------------------------------
	-- temp table to hold factors
	-----------------------------------------------------------
	--
	CREATE TABLE #TMP (		
		Dataset INT null,
		Request INT,
		Factor VARCHAR(128),
		Value VARCHAR(128)
	)

	-----------------------------------------------------------
	-- populate temp table with new parameters
	-----------------------------------------------------------
	--
	SET @xml = @factorList
	--
	INSERT INTO #TMP
		(Dataset, Request, Factor, Value )
	select
		xmlNode.value('@d', 'nvarchar(256)') Dataset,
		xmlNode.value('@i', 'nvarchar(256)') Request,
		xmlNode.value('@f', 'nvarchar(256)') Factor,
		xmlNode.value('@v', 'nvarchar(256)') Value
	FROM @xml.nodes('//r') AS R(xmlNode)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to convert list'
		return 51009
	end

 	-----------------------------------------------------------
	-- update temp table with request ids looked up via dataset
	----------------------------------------------------------- 
	--
	UPDATE #TMP
	SET Request = T_Requested_Run.ID
	FROM #TMP INNER JOIN dbo.T_Requested_Run ON Dataset = DatasetID
	WHERE Request IS NULL AND NOT dataset IS NULL 

 	-----------------------------------------------------------
	-- unresolved requests
	-----------------------------------------------------------
	--
	IF EXISTS(SELECT * FROM #TMP WHERE Request IS NULL)
	begin
		set @message = 'Not all requests have vaild IDs'
		return 51017
	end

	-----------------------------------------------------------
	-- get rid of unchanged existing values
	-----------------------------------------------------------
	--
	DELETE FROM #TMP
	WHERE
	EXISTS ( 
		SELECT *
		FROM
			T_Factor
		WHERE
			T_Factor.Type = 'Run_Request'
			AND #tmp.Request = T_Factor.TargetID
			AND #tmp.Factor = T_Factor.Name
			AND #tmp.Value = T_Factor.Value 
	)

	-----------------------------------------------------------
	-- validate factor names
	-----------------------------------------------------------
	--
	DECLARE	@badFactorNames VARCHAR(8000)
	SET @badFactorNames = ''
	--
	SELECT
		@badFactorNames = @badFactorNames + 
			CASE 
			WHEN PATINDEX('%[^0-9A-Za-z_.]%', Factor) > 0
			THEN CASE WHEN @badFactorNames = '' THEN Factor ELSE ', ' + Factor END
			ELSE ''
			END
	FROM
	#TMP
	IF @badFactorNames != ''
	begin
		set @message = 'Unacceptable characters in factor names "' + LEFT(@badFactorNames, 256) + '..."'
		return 51027
	end

	-----------------------------------------------------------
	-- make sure factor not in blacklist
	-----------------------------------------------------------
	--
	SELECT @badFactorNames = @badFactorNames + Factor  + ', '
	FROM #TMP 
	WHERE Factor IN ('Block', 'Run Order', 'Request', 'Type')
	--
	IF @badFactorNames <> ''
	begin
		set @message =  'Invalid factor names:' + @badFactorNames
		return 51012
	end

	-----------------------------------------------------------
	-- remove blank values from factors table
	-----------------------------------------------------------
	--
	DELETE 
	FROM 
		T_Factor
	WHERE 
		T_Factor.Type = 'Run_Request' AND
		EXISTS (
			SELECT * 
			FROM #TMP
			WHERE #tmp.Request = T_Factor.TargetID AND #tmp.Factor = T_Factor.Name AND #tmp.Value = ''
		)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error removing blank values from factors table'
		return 51001
	end

	-----------------------------------------------------------
	-- update existing items in factors tables
	-----------------------------------------------------------
	--
	UPDATE T_Factor
		SET value = #TMP.Value
	FROM
		T_Factor AS TF INNER JOIN 
		#TMP ON #TMP.Request = TF.TargetID AND #TMP.Factor = TF.Name
	WHERE
		#tmp.Value <> TF.Value
		AND TF.Type = 'Run_Request'
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating changed values in factors table'
		return 51002
	end

	-----------------------------------------------------------
	-- add new factors
	-----------------------------------------------------------
	--
	INSERT INTO dbo.T_Factor
        ( Type, TargetID, Name, Value )
	SELECT  
		'Run_Request' AS Type, Request AS TargetID, Factor AS Name, Value 
	FROM #TMP
		WHERE
		#tmp.Value <> '' AND
		NOT EXISTS (
			SELECT * 
			FROM T_Factor
			WHERE #tmp.Request = T_Factor.TargetID AND #tmp.Factor = T_Factor.Name AND T_Factor.Type = 'Run_Request'
		)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error adding new factors to factors table'
		return 51003
	end

	-----------------------------------------------------------
	-- convert changed items to XML for logging
	-----------------------------------------------------------
	--
	DECLARE @changeSummary varchar(max)
	set @changeSummary = ''
	--
	SELECT @changeSummary = @changeSummary + '<r i="' + CONVERT(varchar(12), Request) + '" f="' + Factor + '" v="' + Value + '" />'
	FROM #TMP
	
	-----------------------------------------------------------
	-- log changes
	-----------------------------------------------------------
	--
	IF @changeSummary <> ''
	BEGIN
		INSERT INTO T_Factor_Log
			(changed_by, changes)
		VALUES
			(@callingUser, @changeSummary)
	END

	-----------------------------------------------------------
	-- 
	-----------------------------------------------------------
	--

	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunFactors] TO [DMS2_SP_User] AS [dbo]
GO
