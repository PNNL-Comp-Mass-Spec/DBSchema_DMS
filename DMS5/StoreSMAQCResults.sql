/****** Object:  StoredProcedure [dbo].[StoreSMAQCResults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.StoreSMAQCResults
/****************************************************
** 
**	Desc:	Updates the SMAQC information for the dataset specified by @DatasetID
**			If @DatasetID is 0, then will use the dataset name defined in @ResultsXML
**			If @DatasetID is non-zero, then will validate that the Dataset Name in the XML corresponds
**			to the dataset ID specified by @DatasetID
**
**			Typical XML file contents
**
**			<SMAQC_Results>
**			  <Dataset>Shew119-01_17july02_earth_0402-10_4-20</Dataset>
**			  <Job>780000</Job>
**			  <Measurements>
**			    <Measurement Name="C_1A">0.002028</Measurement>
**			    <Measurement Name="C_1B">0.00583</Measurement>
**			    <Measurement Name="C_2A">23.5009</Measurement>
**			    <Measurement Name="C_3B">25.99</Measurement>
**			    <Measurement Name="C_4A">23.28</Measurement>
**			    <Measurement Name="C_4B">26.8</Measurement>
**			    <Measurement Name="C_4C">27.18</Measurement>
**			  </Measurements>
**			</SMAQC_Results>
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	12/06/2011 mem - Initial version (modelled after UpdateDatasetFileInfoXML)
**			02/13/2012 mem - Added 32 more metrics
**			04/29/2012 mem - Replaced P_1 with P_1A and P_1B
**			05/02/2012 mem - Added C_2B, C_3A, and P_2B
**			09/17/2012 mem - Now assuring that the values are no larger than 1E+38
**			07/01/2013 mem - Added support for PSM_Source_Job
**			08/08/2013 mem - Now storing MS1_5C in MassErrorPPM if MassErrorPPM is null; 
**							   Note that when running Dta_Refinery, MassErrorPPM will be populated with the mass error value prior to DtaRefinery
**							   while MassErrorPPM_Refined will have the post-refinement error.  In that case, MS1_5C will have the 
**							   post-refinement mass error (because that value comes from MSGF+ and MSGF+ uses the refined _dta.txt file)
**    
*****************************************************/
(
	@DatasetID int = 0,				-- If this value is 0, then will determine the dataset name using the contents of @ResultsXML
	@ResultsXML xml,				-- XML holding the SMAQC results for a single dataset
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
		Job int NULL,				-- Analysis job used to generate the SMAQC results
		PSM_Source_Job int NULL		-- MSGF+ or X!Tandem job whose results were used by SMAQDC
	)


	Declare @MeasurementsTable table (
		[Name] varchar(64) NOT NULL,
		ValueText varchar(64) NULL,
		Value float NULL
	)

	Declare @KnownMetricsTable table (
		Dataset_ID int NOT NULL,
		C_1A float NULL,
		C_1B float NULL,
		C_2A float NULL,
		C_2B float NULL,
		C_3A float NULL,
		C_3B float NULL,
		C_4A float NULL,
		C_4B float NULL,
		C_4C float NULL,
		DS_1A float NULL,
		DS_1B float NULL,
		DS_2A float NULL,
		DS_2B float NULL,
		DS_3A float NULL,
		DS_3B float NULL,
		IS_1A float NULL,
		IS_1B float NULL,
		IS_2 float NULL,
		IS_3A float NULL,
		IS_3B float NULL,
		IS_3C float NULL,
		MS1_1 float NULL,
		MS1_2A float NULL,
		MS1_2B float NULL,
		MS1_3A float NULL,
		MS1_3B float NULL,
		MS1_5A float NULL,
		MS1_5B float NULL,
		MS1_5C float NULL,
		MS1_5D float NULL,
		MS2_1 float NULL,
		MS2_2 float NULL,
		MS2_3 float NULL,
		MS2_4A float NULL,
		MS2_4B float NULL,
		MS2_4C float NULL,
		MS2_4D float NULL,
		P_1A float NULL,
		P_1B float NULL,
		P_2A float NULL,
		P_2B float NULL,
		P_2C float NULL,
		P_3 float NULL
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
	FROM (SELECT @ResultsXML.value('(/SMAQC_Results/Dataset)[1]', 'varchar(128)') AS DSName
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
		set @message = 'XML in @ResultsXML is not in the expected form; Could not match /SMAQC_Results/Dataset'
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
		Job,
		PSM_Source_Job
	)
	SELECT	@DatasetID AS DatasetID,
			@DatasetName AS Dataset,
			@ResultsXML.value('(/SMAQC_Results/Job)[1]', 'int') AS Job,
			@ResultsXML.value('(/SMAQC_Results/PSM_Source_Job)[1]', 'int') AS PSM_Source_Job
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error extracting data from @ResultsXML'
		goto Done
	end

	
	---------------------------------------------------
	-- Now extract out the SMAQC Measurement information
	---------------------------------------------------

	--
	INSERT INTO @MeasurementsTable ([Name], ValueText)
	SELECT [Name], ValueText
	FROM (	SELECT  xmlNode.value('.', 'varchar(64)') AS ValueText,
				xmlNode.value('@Name', 'varchar(64)') AS [Name]
		FROM   @ResultsXML.nodes('/SMAQC_Results/Measurements/Measurement') AS R(xmlNode)
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
	                  WHERE IsNumeric(ValueText) = 1 
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
	
	INSERT INTO @KnownMetricsTable( Dataset_ID,
                               C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C, 
                                    DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B, 
                                    IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C, 
                                    MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D, 
                                    MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
                                    P_1A, P_1B, P_2A, P_2B, P_2C, P_3
                                  )
	SELECT @DatasetID,
	       C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C, 
           DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B, 
           IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C, 
           MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D, 
           MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
           P_1A, P_1B, P_2A, P_2B, P_2C, P_3
	FROM ( SELECT [Name],
	              [Value]
	       FROM @MeasurementsTable ) AS SourceTable
	     PIVOT ( MAX([Value])
	             FOR Name
	             IN ( [C_1A], [C_1B], [C_2A], [C_2B], [C_3A], [C_3B], [C_4A], [C_4B], [C_4C],
                      [DS_1A], [DS_1B], [DS_2A], [DS_2B], [DS_3A], [DS_3B], 
                      [IS_1A], [IS_1B], [IS_2], [IS_3A], [IS_3B], [IS_3C], 
                      [MS1_1], [MS1_2A], [MS1_2B], [MS1_3A], [MS1_3B], [MS1_5A], [MS1_5B], [MS1_5C], [MS1_5D], 
                      [MS2_1], [MS2_2], [MS2_3], [MS2_4A], [MS2_4B], [MS2_4C], [MS2_4D], 
                      [P_1A], [P_1B], [P_2A], [P_2B], [P_2C], [P_3] ) ) AS PivotData


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
                DI.Job,
                DI.PSM_Source_Job,
                C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C, 
                DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B, 
                IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C, 
                MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D, 
                MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
                P_1A, P_1B, P_2A, P_2B, P_2C, P_3
		 FROM @KnownMetricsTable M INNER JOIN 
		      @DatasetInfoTable DI ON M.Dataset_ID = DI.Dataset_ID
		) AS Source (Dataset_ID, SMAQC_Job, PSM_Source_Job,
                     C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C, 
                     DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B, 
                     IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C, 
                     MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D, 
                     MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
                     P_1A, P_1B, P_2A, P_2B, P_2C, P_3)
	    ON (target.Dataset_ID = Source.Dataset_ID)
	
	WHEN Matched 
		THEN UPDATE 
			Set SMAQC_Job = Source.SMAQC_Job,
			    PSM_Source_Job = Source.PSM_Source_Job,
			    C_1A = Source.C_1A, C_1B = Source.C_1B, C_2A = Source.C_2A, C_2B = Source.C_2B, C_3A = Source.C_3A, C_3B = Source.C_3B, C_4A = Source.C_4A, C_4B = Source.C_4B, C_4C = Source.C_4C, 
			    DS_1A = Source.DS_1A, DS_1B = Source.DS_1B, DS_2A = Source.DS_2A, DS_2B = Source.DS_2B, DS_3A = Source.DS_3A, DS_3B = Source.DS_3B, 
			    IS_1A = Source.IS_1A, IS_1B = Source.IS_1B, IS_2 = Source.IS_2, IS_3A = Source.IS_3A, IS_3B = Source.IS_3B, IS_3C = Source.IS_3C, 
			    MS1_1 = Source.MS1_1, MS1_2A = Source.MS1_2A, MS1_2B = Source.MS1_2B, MS1_3A = Source.MS1_3A, MS1_3B = Source.MS1_3B, MS1_5A = Source.MS1_5A, MS1_5B = Source.MS1_5B, MS1_5C = Source.MS1_5C, MS1_5D = Source.MS1_5D, 
			    MS2_1 = Source.MS2_1, MS2_2 = Source.MS2_2, MS2_3 = Source.MS2_3, MS2_4A = Source.MS2_4A, MS2_4B = Source.MS2_4B, MS2_4C = Source.MS2_4C, MS2_4D = Source.MS2_4D,
			    P_1A = Source.P_1A, P_1B = Source.P_1B, P_2A = Source.P_2A, P_2B = Source.P_2B, P_2C = Source.P_2C, P_3 = Source.P_3,
			    MassErrorPPM = IsNull(Target.MassErrorPPM, Source.MS1_5C),
				Last_Affected = GetDate()
				
	WHEN Not Matched THEN
		INSERT (Dataset_ID, 
		        SMAQC_Job,
		        PSM_Source_Job,
		        C_1A, C_1B, C_2A, C_2B, C_3A, C_3B, C_4A, C_4B, C_4C, 
		        DS_1A, DS_1B, DS_2A, DS_2B, DS_3A, DS_3B, 
		        IS_1A, IS_1B, IS_2, IS_3A, IS_3B, IS_3C, 
		        MS1_1, MS1_2A, MS1_2B, MS1_3A, MS1_3B, MS1_5A, MS1_5B, MS1_5C, MS1_5D, 
		        MS2_1, MS2_2, MS2_3, MS2_4A, MS2_4B, MS2_4C, MS2_4D,
		        P_1A, P_1B, P_2A, P_2B, P_2C, P_3, MassErrorPPM,
				Last_Affected 
			   )
		VALUES ( Source.Dataset_ID, 
		         Source.SMAQC_Job,
		         Source.PSM_Source_Job,
		         Source.C_1A, Source.C_1B, Source.C_2A, Source.C_2B, Source.C_3A, Source.C_3B, Source.C_4A, Source.C_4B, Source.C_4C, 
		         Source.DS_1A, Source.DS_1B, Source.DS_2A, Source.DS_2B, Source.DS_3A, Source.DS_3B, 
		         Source.IS_1A, Source.IS_1B, Source.IS_2, Source.IS_3A, Source.IS_3B, Source.IS_3C, 
		         Source.MS1_1, Source.MS1_2A, Source.MS1_2B, Source.MS1_3A, Source.MS1_3B, Source.MS1_5A, Source.MS1_5B, Source.MS1_5C, Source.MS1_5D, 
		         Source.MS2_1, Source.MS2_2, Source.MS2_3, Source.MS2_4A, Source.MS2_4B, Source.MS2_4C, Source.MS2_4D,
		         Source.P_1A, Source.P_1B, Source.P_2A, Source.P_2B, Source.P_2C, Source.P_3, 
		         Source.MS1_5C,  -- Store MS1_5C in MassErrorPPM; if DTA_Refinery is run in the future, then MassErrorPPM will get auto-updated to the pre-refinement value computed by DTA_Refinery
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

		
	Set @message = 'SMAQC measurement storage successful'
	
Done:

	If @myError <> 0
	Begin
		If @message = ''
			Set @message = 'Error in StoreSMAQCResults'
		
		Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
		
		If @InfoOnly = 0
			Exec PostLogEntry 'Error', @message, 'StoreSMAQCResults'
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
		Exec PostUsageLogEntry 'StoreSMAQCResults', @UsageMessage

	Return @myError

GO
GRANT EXECUTE ON [dbo].[StoreSMAQCResults] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[StoreSMAQCResults] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[StoreSMAQCResults] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreSMAQCResults] TO [svc-dms] AS [dbo]
GO
