/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunFactors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateRequestedRunFactors
/****************************************************
**
**	Desc: 
**	Update requested run factors from input XML list 
**
**	@factorList will look like this if it comes from web page http://dms2.pnl.gov/requested_run_factors/param
**
**      <id type="Request" />
**      <r i="193911" f="Factor1" v="Aa" />
**      <r i="194113" f="Factor1" v="Bb" />
**      <r i="205898" f="Factor2" v="Aa" />
**      <r i="194113" f="Factor2" v="Bb" />
**
**
**  The "type" attribute of the <id> tag defines what the "i" attributes map to
**
**	Second example for web page http://dms2.pnl.gov/requested_run_factors/param
**
**      <id type="Dataset" />
**      <r i="OpSaliva_009_a_7Mar11_Phoenix_11-01-17" f="Factor1" v="Aa" />
**      <r i="OpSaliva_009_b_7Mar11_Phoenix_11-01-20" f="Factor1" v="Bb" />
**      <r i="OpSaliva_009_a_7Mar11_Phoenix_11-01-17" f="Factor2" v="Aa" />
**      <r i="OpSaliva_009_b_7Mar11_Phoenix_11-01-20" f="Factor2" v="Bb" />
**
**
**	XML coming from stored procedure MakeAutomaticRequestedRunFactors will look like the following
**	Here, the identifier is RequestID
**
**      <r i="193911" f="Factor1" v="Aa" />
**      <r i="194113" f="Factor1" v="Bb" />
**      <r i="205898" f="Factor2" v="Aa" />
**
**
**	One other supported format uses DatasetID.  If any records contain "d" attributes, then the "type" attribute of the <id> tag is ignored
**
**      <r d="214536" f="Factor1" v="Aa" />
**      <r d="214003" f="Factor1" v="Bb" />
**      <r d="213522" f="Factor2" v="Aa" />
**

**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date:	02/20/2010 grk - initial release
**			03/17/2010 grk - expanded blacklist
**			03/22/2010 grk - allow dataset id
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			12/08/2011 mem - Added additional blacklisted factor names: Experiment, Dataset, Name, and Status
**			12/09/2011 mem - Now checking for invalid Requested Run IDs
**			12/15/2011 mem - Added support for the "type" attribute in the <id> tag
**			09/12/2012 mem - Now auto-removing columns Dataset_ID, Dataset, or Experiment if they are present as factor names
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**    
*****************************************************/
(
	@factorList text,
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = '',
	@infoOnly tinyint = 0				-- Set to 1 to preview the changes that would be made
)
As
	SET NOCOUNT ON 

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @Msg2 varchar(512)
	Declare @invalidCount int
	
	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------
	
	SET @message = ''

	If IsNull(@callingUser, '') = ''
		SET @callingUser = REPLACE(SUSER_SNAME(), 'PNL\', '')
	
	Set @infoOnly = IsNull(@infoOnly, 0)
		
	-----------------------------------------------------------
	-- temp table to hold factors
	-----------------------------------------------------------
	--
	CREATE TABLE #TMP (
		Entry_ID int Identity(1,1),
		Identifier varchar(128) null,		-- Could be RequestID or DatasetName
		Factor varchar(128) null,
		Value varchar(128) null,
		DatasetID INT null,					-- DatasetID; not always present
		RequestID INT null,
		UpdateSkipCode tinyint			-- 0 to update, 1 means unchanged, 2 means invalid factor name
	)

	-----------------------------------------------------------
	-- Copy @factorList text variable into the XML variable
	-----------------------------------------------------------
	SET @xml = @factorList

	-----------------------------------------------------------
	-- Check whether the XML contains <id type="Request" />
	-- Note that this will be ignored if entries like the following exist in the XML:
	--    <r d="214536" f="Factor1" v="Aa" />
	-----------------------------------------------------------
	--
	Declare @IDType varchar(256)
	
	SELECT @IDType = xmlNode.value('@type', 'nvarchar(256)')
	FROM @xml.nodes('//id') AS R(xmlNode)

	If IsNull(@IDType, '') = ''
	Begin
		-- Assume @IDType is RequestID
		Set @IDType = 'RequestID'
	End
	
	-- Auto-update @IDType if needed
	If @IDType = 'Request'
		Set @IDType = 'RequestID'

	If @IDType = 'DatasetName' OR @IDType Like 'Dataset_Name'
		Set @IDType = 'Dataset'
	
	
	-----------------------------------------------------------
	-- populate temp table with new parameters
	-----------------------------------------------------------
	--
	INSERT INTO #TMP
		(Identifier, Factor, Value, DatasetID, UpdateSkipCode)
	SELECT
		xmlNode.value('@i', 'nvarchar(256)') Identifier,
		xmlNode.value('@f', 'nvarchar(256)') Factor,
		xmlNode.value('@v', 'nvarchar(256)') Value,
		xmlNode.value('@d', 'nvarchar(256)') DatasetID,		-- Only sometimes present
		0 AS UpdateSkipCode
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
	-- If table contains DatasetID values, then auto-populate the Identifier column with RequestIDs
 	-----------------------------------------------------------

	IF EXISTS (SELECT * FROM #TMP WHERE Not DatasetID IS NULL)
	Begin -- <a>
		IF Exists (SELECT * FROM #TMP WHERE DatasetID IS NULL)
		Begin
			set @message = 'Encountered a mix of XML tag attributes; if using the "d" attribute for DatasetID, then all entries must have "d" defined'
			IF @infoOnly <> 0
				SELECT * FROM #Tmp
			return 51016
		End
		
		UPDATE #TMP
		SET Identifier = RR.ID
		FROM #TMP
			INNER JOIN dbo.T_Requested_Run RR
			ON #TMP.DatasetID = RR.DatasetID
		WHERE #TMP.Identifier IS NULL
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		-- The identifier column now contains RequestID values
		Set @IDType = 'RequestID'

		IF Exists (SELECT * FROM #TMP WHERE Identifier IS NULL)
		begin
			set @message = 'Unable to resolve DatasetID to RequestID for one or more entries (DatasetID not found in Requested Run table)'
			
			-- Construct a list of DatasetIDs that are not present in T_Requested_Run
			Set @Msg2 = ''
			Select @Msg2 = @Msg2 + #TMP.DatasetID + ', '
			FROM #TMP
			WHERE Identifier Is Null
			
			If IsNull(@Msg2, '') <> ''
			Begin
				-- Append @Msg2 to @message
				set @message = @message + '; error with: ' + Substring(@Msg2, 1, Len(@Msg2)-1)
			End
			
			IF @infoOnly <> 0
				SELECT * FROM #Tmp
				
			return 51017
		end
		
	End -- </a>
	

	-----------------------------------------------------------
	-- Validate @IDType
	-----------------------------------------------------------

	If Not @IDType IN ('RequestID', 'DatasetID', 'Job', 'Dataset')
	Begin
		set @message = 'Identifier type "' + @IDType + '" was not recognized; should be RequestID, DatasetID, Job, or Dataset (i.e. Dataset Name)'
		IF @infoOnly <> 0
			SELECT * FROM #Tmp
		return 51018
	End		
	
	-----------------------------------------------------------
	-- Make sure the identifiers are all numeric for certain types
	-----------------------------------------------------------
	--
	If @IDType IN ('RequestID', 'DatasetID', 'Job')
	Begin
		Set @Msg2 = ''
		
		SELECT @Msg2 = @Msg2 + Identifier + ','
		FROM #Tmp
		WHERE Try_Convert(int, Identifier) Is Null
		--
		If IsNull(@Msg2, '') <> ''
		Begin
			-- One or more entries is non-numeric
			set @message = 'Identifier keys must all be integers when Identifier column contains ' + @IDType + '; error with: ' + Substring(@Msg2, 1, Len(@Msg2)-1)
			IF @infoOnly <> 0
				SELECT * FROM #Tmp
			return 51019
		End             
	End
	
	-----------------------------------------------------------
	-- Populate column RequestID using the Identifier column
	-----------------------------------------------------------
	--
	If @IDType = 'RequestID'
	Begin
		-- Identifier is Requestid
		UPDATE #Tmp
		SET RequestID = Convert(int, Identifier)		
	End

	If @IDType = 'DatasetID'
	Begin
		-- Identifier is DatasetID
		UPDATE #Tmp
		SET RequestID = RR.ID,
		    DatasetID = Convert(int, #Tmp.Identifier)
		FROM #Tmp
		     INNER JOIN T_Requested_Run RR
		       ON Convert(int, #Tmp.Identifier) = RR.DatasetID

	End

	If @IDType = 'Dataset'
	Begin
		-- Identifier is Dataset Name		
		UPDATE #Tmp
		SET RequestID = RR.ID,
		    DatasetID = DS.Dataset_ID
		FROM #Tmp
		     INNER JOIN T_Dataset DS
		       ON #Tmp.Identifier = DS.Dataset_Num
		     INNER JOIN T_Requested_Run RR
		       ON RR.DatasetID = DS.Dataset_ID

	End

	If @IDType = 'Job'
	Begin
		-- Identifier is Job
		UPDATE #Tmp
		SET RequestID = RR.ID,
		    DatasetID = DS.Dataset_ID
		FROM #Tmp
		     INNER JOIN T_Analysis_Job AJ
		       ON Convert(int, #Tmp.Identifier) = AJ.AJ_jobID
		     INNER JOIN T_Dataset DS
		       ON DS.Dataset_ID = AJ.AJ_datasetID
		     INNER JOIN T_Requested_Run RR
		       ON RR.DatasetID = DS.Dataset_ID

	End		
	
 	-----------------------------------------------------------
	-- Check for unresolved requests
	-----------------------------------------------------------
	--
	Set @myRowCount = 0
	Set @invalidCount = 0
	
	SELECT @myRowCount = Count(*),
	       @invalidCount = Sum(CASE WHEN RequestID IS NULL THEN 1 ELSE 0 END)
	FROM ( SELECT DISTINCT Identifier,
	                       RequestID
	       FROM #TMP ) InnerQ
	
	IF @invalidCount > 0
	begin
		If @invalidCount = @myRowCount
			Set @message = 'Unable to determine RequestID for all ' + Convert(varchar(12), @myRowCount) + ' items'
		Else
			Set @message = 'Unable to determine RequestID for ' + Convert(varchar(12), @invalidCount) + ' of ' + Convert(varchar(12), @myRowCount) + ' items'
			
		Set @message = @message + '; treating the Identifier column as ' + @IDType
		
		IF @infoOnly <> 0
			SELECT * FROM #Tmp
			
		return 51020
	end
	
	-----------------------------------------------------------
	-- validate factor names
	-----------------------------------------------------------
	--
	DECLARE	@badFactorNames VARCHAR(8000) = ''	
	--
	SELECT
		@badFactorNames = @badFactorNames + 
			CASE 
			WHEN PATINDEX('%[^0-9A-Za-z_.]%', Factor) > 0
			THEN CASE WHEN @badFactorNames = '' THEN Factor ELSE ', ' + Factor END
			ELSE ''
			END
	FROM ( SELECT DISTINCT Factor
	       FROM #TMP 
	      ) LookupQ
	
	IF @badFactorNames <> ''
	begin
		If Len(@badFactorNames) < 256
			set @message = 'Unacceptable characters in factor names "' + @badFactorNames + '"'
		Else
			set @message = 'Unacceptable characters in factor names "' + LEFT(@badFactorNames, 256) + '..."'
			
		IF @infoOnly <> 0
			SELECT * FROM #Tmp
			
		return 51027
	end

	-----------------------------------------------------------
	-- Auto-delete data that cannot be a factor
	-- These column names could be present if the user
	-- saved the results of a list report (or of http://dms2.pnl.gov/requested_run_factors/param) 
	-- to a text file, then edited the data in Excel, then included the extra columns when copying from Excel
	--
	-- Name is not a valid factor name since it is used to label the Requested Run Name column at http://dms2.pnl.gov/requested_run_factors/param
	-----------------------------------------------------------
	
	UPDATE #TMP
	Set UpdateSkipCode = 2
	WHERE Factor IN ('BatchID', 'Experiment', 'Dataset', 'Status', 'Request', 'Name')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	IF @myRowCount > 0 And @infoOnly <> 0
	Begin
		SELECT *, Case When UpdateSkipCode = 2 Then 'Yes' Else 'No' End As AutoSkip_Invalid_Factor
		FROM #TMP
		
	End
	
	-----------------------------------------------------------
	-- Make sure factor name is not in blacklist
	-- Note that Javascript code behind http://dms2.pnl.gov/requested_run_factors/param
	--  auto-removes column "Block" if it is present
	-----------------------------------------------------------
	--
	Set @badFactorNames = ''
	
	SELECT @badFactorNames = @badFactorNames + Factor  + ', '
	FROM ( SELECT DISTINCT Factor
	       FROM #TMP
	       WHERE Factor IN ('Block', 'Run Order', 'Type') 
	     ) LookupQ
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	IF @badFactorNames <> ''
	begin
		-- Remove the trailing comma
		Set @badFactorNames = Substring(@badFactorNames, 1, Len(@badFactorNames)-1)

		If @myRowCount = 1
			set @message = 'Invalid factor name: ' + @badFactorNames
		Else		
			set @message = 'Invalid factor names: ' + @badFactorNames
		
		IF @infoOnly <> 0
			SELECT * FROM #Tmp
		
		return 51015
	end

	-----------------------------------------------------------
	-- Auto-remove standard DMS names from the factor table
	-----------------------------------------------------------
	-- 
	DELETE FROM #Tmp
	WHERE Factor IN ('Dataset_ID', 'Dataset', 'Experiment')
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	
	-----------------------------------------------------------
	-- Check for invalid Request IDs in the factors table
	-----------------------------------------------------------
	--
	DECLARE	@InvalidRequestIDs VARCHAR(8000) = ''
	--
	SELECT @InvalidRequestIDs = @InvalidRequestIDs + Convert(varchar(12), RequestID) + ', '
	FROM #TMP
	     LEFT OUTER JOIN T_Requested_Run RR
	       ON #Tmp.RequestID = RR.ID
	WHERE UpdateSkipCode = 0 And RR.ID IS NULL

	--
	IF @InvalidRequestIDs <> ''
	begin
		-- Remove the trailing comma
		Set @InvalidRequestIDs = Substring(@InvalidRequestIDs, 1, Len(@InvalidRequestIDs)-1)
		
		set @message =  'Invalid Requested Run IDs: ' + @InvalidRequestIDs
		IF @infoOnly <> 0
			SELECT * FROM #Tmp
		return 51013
	end
	
	
	-----------------------------------------------------------
	-- Flag values that are unchanged
	-----------------------------------------------------------
	--
	UPDATE #TMP
	SET UpdateSkipCode = 1
	WHERE UpdateSkipCode = 0 AND
	      EXISTS ( SELECT *
	               FROM T_Factor
	               WHERE T_Factor.Type = 'Run_Request' AND
	                     #tmp.RequestID = T_Factor.TargetID AND
	                     #tmp.Factor = T_Factor.Name AND
	                     #tmp.Value = T_Factor.Value )


	
	IF @infoOnly <> 0
	Begin
		-- Preview the contents of the #Tmp table
		SELECT * 
		FROM #Tmp
	End
	Else
	Begin -- <CommitChanges>
		
		-----------------------------------------------------------
		-- Remove blank values from factors table
		-----------------------------------------------------------
		--
		DELETE FROM T_Factor
		WHERE T_Factor.Type = 'Run_Request' AND
		      EXISTS ( SELECT *
		               FROM #TMP
		               WHERE UpdateSkipCode = 0 AND
		                     #tmp.RequestID = T_Factor.TargetID AND
		                     #tmp.Factor = T_Factor.Name AND
		                     #tmp.Value = '' )
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
		SET Value = #TMP.Value
		FROM T_Factor AS TF
		     INNER JOIN #TMP
		       ON #TMP.RequestID = TF.TargetID AND
		          #TMP.Factor = TF.Name AND
		          TF.Type = 'Run_Request'
		WHERE UpdateSkipCode = 0 AND
		      #tmp.Value <> TF.Value
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
		INSERT INTO dbo.T_Factor( Type,
		                          TargetID,
		                          Name,
		                          Value )
		SELECT 'Run_Request' AS TYPE,
		       RequestID AS TargetID,
		       Factor AS Name,
		       Value
		FROM #TMP
		WHERE UpdateSkipCode = 0 AND
		      #tmp.Value <> '' AND
		      NOT EXISTS ( SELECT *
		                FROM T_Factor
		                   WHERE #tmp.RequestID = T_Factor.TargetID AND
		                         #tmp.Factor = T_Factor.Name AND
		                         T_Factor.Type = 'Run_Request' )
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
		DECLARE @changeSummary varchar(max) = ''
		--
		SELECT @changeSummary = @changeSummary + '<r i="' + CONVERT(varchar(12), RequestID) + '" f="' + Factor + '" v="' + Value + '" />'
		FROM #TMP
		WHERE UpdateSkipCode = 0
		
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
		
	End -- </CommitChanges>
	
	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512) = ''
	Set @UsageMessage = ''
	Exec PostUsageLogEntry 'UpdateRequestedRunFactors', @UsageMessage

	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunFactors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunFactors] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunFactors] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateRequestedRunFactors] TO [PNL\D3M580] AS [dbo]
GO
