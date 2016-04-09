/****** Object:  StoredProcedure [dbo].[StoreQCDMResults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.StoreQCDMResults
/****************************************************
** 
**	Desc:	Updates the QCDM information for the dataset specified by @DatasetID
**			If @DatasetID is 0, then will use the dataset name defined in @ResultsXML
**			If @DatasetID is non-zero, then will validate that the Dataset Name in the XML corresponds
**			to the dataset ID specified by @DatasetID
**
**			Typical XML file contents
**
**			 <QCDM_Results>
**			   <Dataset>QC_Shew_13_02_pt1ug_c_29May13_Draco_13-05-16</Dataset>
**			   <SMAQC_Job>949552</SMAQC_Job>
**			   <Quameter_Job>1221129</Quameter_Job>
**			   <Measurements>
**			      <Measurement Name="QCDM">0.12345</Measurement>
**			   </Measurements>
**			 </QCDM_Results>
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	06/04/2013 mem - Initial version (modelled after StoreSMAQCResults)
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**    
*****************************************************/
(
	@DatasetID int = 0,				-- If this value is 0, then will determine the dataset name using the contents of @ResultsXML
	@ResultsXML xml,				-- XML holding the QCDM results for a single dataset
	@message varchar(255) = '' output,
	@infoOnly tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @DatasetName varchar(128)
	Declare @DatasetIDCheck int

	-----------------------------------------------------------
	-- Create the table to hold the data
	-----------------------------------------------------------

	Declare @DatasetInfoTable table (
		Dataset_ID int NULL ,
		Dataset_Name varchar (128) NOT NULL ,
		SMAQC_Job int NULL,				-- Analysis job used to generate the SMAQC results
		Quameter_Job int NULL			-- Analysis job used to generate the Quameter results
	)


	Declare @MeasurementsTable table (
		[Name] varchar(64) NOT NULL,
		ValueText varchar(64) NULL,
		Value float NULL
	)

	Declare @KnownMetricsTable table (
		Dataset_ID int NOT NULL,
		QCDM float NULL
	)
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @DatasetID = IsNull(@DatasetID, 0)
	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	
	---------------------------------------------------
	-- Parse out the dataset name from @ResultsXML
	-- If this parse fails, there is no point in continuing
	---------------------------------------------------
	
	SELECT @DatasetName = DSName
	FROM (SELECT @ResultsXML.value('(/QCDM_Results/Dataset)[1]', 'varchar(128)') AS DSName
	     ) LookupQ
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error extracting the dataset name from @ResultsXML'
		goto Done
	end
		
	If @myRowCount = 0 or IsNull(@DatasetName, '') = ''
	Begin
		set @message = 'XML in @ResultsXML is not in the expected form; Could not match /QCDM_Results/Dataset'
		Set @myError = 50000
		goto Done
	End
	
	---------------------------------------------------
	-- Parse the contents of @ResultsXML to populate @DatasetInfoTable
	---------------------------------------------------
	--
	INSERT INTO @DatasetInfoTable (
		Dataset_ID,
		Dataset_Name,
		SMAQC_Job,
		Quameter_Job
	)
	SELECT	@DatasetID AS DatasetID,
			@DatasetName AS Dataset,
			@ResultsXML.value('(/QCDM_Results/SMAQC_Job)[1]', 'int') AS SMAQC_Job,
			@ResultsXML.value('(/QCDM_Results/Quameter_Job)[1]', 'int') AS Quameter_Job
			
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error extracting data from @ResultsXML'
		goto Done
	end

	
	---------------------------------------------------
	-- Now extract out the Measurement information
	---------------------------------------------------
	--
	INSERT INTO @MeasurementsTable ([Name], ValueText)
	SELECT [Name], ValueText
	FROM (	SELECT  xmlNode.value('.', 'varchar(64)') AS ValueText,
				xmlNode.value('@Name', 'varchar(64)') AS [Name]
		FROM   @ResultsXML.nodes('/QCDM_Results/Measurements/Measurement') AS R(xmlNode)
	) LookupQ
	WHERE NOT ValueText IS NULL	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error parsing Measurement nodes in @ResultsXML'
		goto Done
	end
	
	---------------------------------------------------
	-- Update or Validate Dataset_ID in @DatasetInfoTable
	---------------------------------------------------
	--
	If @DatasetID = 0
	Begin
		UPDATE @DatasetInfoTable
		SET Dataset_ID = DS.Dataset_ID
		FROM @DatasetInfoTable Target
		     INNER JOIN T_Dataset DS
		       ON Target.Dataset_Name = DS.Dataset_Num
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount = 0
		Begin
			Set @message = 'Warning: dataset not found in table T_Dataset: ' + @DatasetName
			Set @myError = 50001
			Goto Done
		End
		
		-- Update @DatasetID
		SELECT @DatasetID = Dataset_ID
		FROM @DatasetInfoTable
		
	End
	Else
	Begin
	
		-- @DatasetID was non-zero
		-- Validate the dataset name in @DatasetInfoTable against T_Dataset
	
		SELECT @DatasetIDCheck = DS.Dataset_ID
		FROM @DatasetInfoTable Target
		     INNER JOIN T_Dataset DS
		     ON Target.Dataset_Name = DS.Dataset_Num
		       
		If @DatasetIDCheck <> @DatasetID
		Begin
			Set @message = 'Error: dataset ID values for ' + @DatasetName + ' do not match; expecting ' + Convert(varchar(12), @DatasetIDCheck) + ' but stored procedure param @DatasetID is ' + Convert(varchar(12), @DatasetID)
			Set @myError = 50002
			Goto Done
		End
	End
		
	-----------------------------------------------
	-- Populate the Value column in @MeasurementsTable
	-- If any of the metrics has a non-numeric value, then the Value column will remain Null
	-----------------------------------------------
	
	UPDATE @MeasurementsTable
	SET Value = Convert(float, FilterQ.ValueText)
	FROM @MeasurementsTable Target
	     INNER JOIN ( SELECT Name,
	                         ValueText
	                  FROM @MeasurementsTable
	                  WHERE Not Try_Convert(float, ValueText) Is Null
	                ) FilterQ
	       ON Target.Name = FilterQ.Name


	-- Do not allow values to be larger than 1E+38 or smaller than -1E+38
	UPDATE @MeasurementsTable
	SET Value = 1E+38
	WHERE Value > 1E+38

	UPDATE @MeasurementsTable
	SET Value = -1E+38
	WHERE Value < -1E+38

	
	-----------------------------------------------
	-- Populate @KnownMetricsTable using data in @MeasurementsTable
	-- Use a Pivot to extract out the known columns
	-----------------------------------------------
	
	INSERT INTO @KnownMetricsTable (Dataset_ID,
                                    QCDM
                                  )
	SELECT @DatasetID,
            QCDM
	FROM ( SELECT [Name],
	              [Value]
	       FROM @MeasurementsTable ) AS SourceTable
	     PIVOT ( MAX([Value])
	             FOR Name
	             IN ( [QCDM] ) 
	            ) AS PivotData


	If @infoOnly <> 0
	Begin
		-----------------------------------------------
		-- Preview the data, then exit
		-----------------------------------------------
		
		SELECT *
		FROM @DatasetInfoTable

		SELECT *
		FROM @MeasurementsTable
		
		SELECT *
		FROM @KnownMetricsTable
		
		Goto Done
	End

	-----------------------------------------------
	-- Add/Update T_Dataset_QC using a MERGE statement
	-----------------------------------------------
	--
	MERGE T_Dataset_QC AS target
	USING 
		(SELECT	M.Dataset_ID, 
                QCDM
		 FROM @KnownMetricsTable M INNER JOIN 
		      @DatasetInfoTable DI ON M.Dataset_ID = DI.Dataset_ID
		) AS Source (Dataset_ID, 
                     QCDM)
	    ON (target.Dataset_ID = Source.Dataset_ID)
	
	WHEN Matched 
		THEN UPDATE 
			Set QCDM = Source.QCDM,
				QCDM_Last_Affected = GetDate()
				
	WHEN Not Matched THEN
		INSERT (Dataset_ID, 
		        QCDM,
				QCDM_Last_Affected 
			   )
		VALUES ( Source.Dataset_ID, 
		         Source.QCDM,
				 GetDate()
			   )

	;
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating T_Dataset_QC'
		goto Done
	end	

		
	Set @message = 'QCDM measurement storage successful'

	Set @message = 'QCDM measurement storage skipped (not yet coded)'

	
Done:

	If @myError <> 0
	Begin
		If @message = ''
			Set @message = 'Error in StoreQCDMResults'
		
		Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
		
		If @InfoOnly = 0
			Exec PostLogEntry 'Error', @message, 'StoreQCDMResults'
	End
	
	If Len(@message) > 0 AND @InfoOnly <> 0
		Print @message

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	If IsNull(@DatasetName, '') = ''
		Set @UsageMessage = 'Dataset ID: ' + Convert(varchar(12), @DatasetID)
	Else
		Set @UsageMessage = 'Dataset: ' + @DatasetName

	If @InfoOnly = 0
		Exec PostUsageLogEntry 'StoreQCDMResults', @UsageMessage

	Return @myError

GO
GRANT EXECUTE ON [dbo].[StoreQCDMResults] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreQCDMResults] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[StoreQCDMResults] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[StoreQCDMResults] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreQCDMResults] TO [svc-dms] AS [dbo]
GO
