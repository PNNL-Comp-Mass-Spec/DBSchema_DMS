/****** Object:  StoredProcedure [dbo].[ValidateDatasetType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.ValidateDatasetType
/****************************************************
** 
**	Desc:	Validates the dataset type defined in T_Dataset for the given dataset
**			based on the contents of T_Dataset_ScanTypes
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	05/13/2010 mem - Initial version
**			05/14/2010 mem - Added support for the generic scan types MSn and HMSn
**			05/17/2010 mem - Updated @AutoDefineOnAllMismatches to default to 1
**			08/30/2011 mem - Updated to prevent MS-HMSn from getting auto-defined
**			03/27/2012 mem - Added support for GC-MS
**			08/15/2012 mem - Added support for IMS-HMS-HMSn
**			10/08/2012 mem - No longer overriding dataset type MALDI-HMS
**			10/19/2012 mem - Improved support for IMS-HMS-HMSn
**			02/28/2013 mem - No longer overriding dataset type C60-SIMS-HMS
**			05/08/2014 mem - No longer updated the dataset comment with "Auto-switched dataset type from HMS-HMSn to HMS-HCD-HMSn"
**    
*****************************************************/
(
	@DatasetID int,
	@message varchar(255) = '' output,
	@infoOnly tinyint = 0,
	@AutoDefineOnAllMismatches tinyint = 1
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @Dataset varchar(256)	
	Declare @DSComment varchar(512)
	Declare @WarnMessage varchar(512)
	
	Declare @CurrentDatasetType varchar(64)
	Declare @DSTypeAutoGen varchar(64)
	Declare @NewDatasetType varchar(64)
	
	Declare @AutoDefineDSType tinyint

	Declare @ActualCountMS int
	Declare @ActualCountHMS int
	Declare @ActualCountGCMS int
	
	Declare @ActualCountCIDMSn int
	Declare @ActualCountCIDHMSn int
	Declare @ActualCountETDMSn int
	Declare @ActualCountETDHMSn int

	Declare @ActualCountMRM int
	Declare @ActualCountHCD int
	Declare @ActualCountPQD int

	Declare @NewDSTypeID int
	
	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------

	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @AutoDefineOnAllMismatches = IsNull(@AutoDefineOnAllMismatches, 0)

	-----------------------------------------------------------
	-- Lookup the dataset type for the given Dataset ID
	-----------------------------------------------------------

	Set @CurrentDatasetType = ''
	
	SELECT @Dataset = Dataset_Num,
	       @DSComment = IsNull(DS.DS_comment, ''),
	       -- @DSTypeIDCurrent = DS.DS_type_ID, 
	       @CurrentDatasetType = DST.DST_name
	FROM T_Dataset DS
	     LEFT OUTER JOIN T_DatasetTypeName DST
	       ON DS.DS_type_ID = DST.DST_Type_ID
	WHERE (DS.Dataset_ID = @DatasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount = 0
	Begin
		Set @message = 'Dataset ID not found in T_Dataset: ' + Convert(varchar(12), @DatasetID)
		Set @myError = 50000
		Goto Done
	End
	
	IF Not Exists (SELECT * FROM T_Dataset_ScanTypes WHERE Dataset_ID = @DatasetID)
	Begin
		Set @message = 'Warning: Scan type info not found in T_Dataset_ScanTypes for dataset ' + @Dataset
		Set @myError = 0
		Goto Done
	End

	-- Use the following to summarize the various ScanType values in T_Dataset_ScanTypes
	-- SELECT ScanType, COUNT(*) AS ScanTypeCount
	-- FROM T_Dataset_ScanTypes
	-- GROUP BY ScanType
	
	-----------------------------------------------------------
	-- Summarize the scan type information in T_Dataset_ScanTypes
	-----------------------------------------------------------

	SELECT 
	       @ActualCountMS   = SUM(CASE WHEN ScanType = 'MS'  Then 1 Else 0 End),
	       @ActualCountHMS  = SUM(CASE WHEN ScanType = 'HMS' Then 1 Else 0 End),
	       @ActualCountGCMS   = SUM(CASE WHEN ScanType = 'GC-MS'  Then 1 Else 0 End),
	
           @ActualCountCIDMSn  = SUM(CASE WHEN ScanType LIKE '%CID-MSn'  OR ScanType = 'MSn'  Then 1 Else 0 End),
           @ActualCountCIDHMSn = SUM(CASE WHEN ScanType LIKE '%CID-HMSn' OR ScanType = 'HMSn' Then 1 Else 0 End),

           @ActualCountETDMSn  = SUM(CASE WHEN ScanType LIKE '%ETD-MSn' Then 1 Else 0 End),
           @ActualCountETDHMSn = SUM(CASE WHEN ScanType LIKE '%ETD-HMSn' Then 1 Else 0 End),
           
	       @ActualCountMRM = SUM(CASE WHEN ScanType LIKE '%SRM' or ScanType LIKE '%MRM' OR ScanType LIKE 'Q[1-3]MS' Then 1 Else 0 End),
	       @ActualCountHCD = SUM(CASE WHEN ScanType LIKE '%HCD%' Then 1 Else 0 End),
	       @ActualCountPQD = SUM(CASE WHEN ScanType LIKE '%PQD%' Then 1 Else 0 End)
	
	FROM T_Dataset_ScanTypes
	WHERE Dataset_ID = @DatasetID
	GROUP BY Dataset_ID
	
	If @InfoOnly <> 0
	Begin
		   SELECT @ActualCountMS AS ActualCountMS,
		          @ActualCountHMS AS ActualCountHMS,
		          @ActualCountGCMS AS ActualCountGCMS,
		          @ActualCountCIDMSn AS ActualCountCIDMSn,
		          @ActualCountCIDHMSn AS ActualCountCIDHMSn,
		          @ActualCountETDMSn AS ActualCountETDMSn,
		          @ActualCountETDHMSn AS ActualCountETDHMSn,
		          @ActualCountMRM AS ActualCountMRM,
		          @ActualCountHCD AS ActualCountHCD,
		          @ActualCountPQD AS ActualCountPQD

	End

	-----------------------------------------------------------
	-- Compare the actual scan type counts to the current dataset type
	-----------------------------------------------------------

	Set @DSTypeAutoGen = ''
	Set @NewDatasetType = ''
	Set @AutoDefineDSType = 0
	Set @WarnMessage = ''
	
	If @ActualCountMRM > 0
	Begin
		-- Auto switch to MRM if not MRM or SRM
	
		If Not (@CurrentDatasetType LIKE '%SRM' OR
	            @CurrentDatasetType LIKE '%MRM' OR
	            @CurrentDatasetType LIKE '%SIM')
		Begin
			Set @NewDatasetType = 'MRM'
		End
	
		Goto FixDSType
	End
	

	If @ActualCountHMS > 0 AND Not (@CurrentDatasetType LIKE 'HMS%' Or @CurrentDatasetType LIKE '%-HMS' OR @CurrentDatasetType LIKE 'IMS-HMS%')
	Begin
		-- Dataset contains HMS spectra, but the current dataset type doesn't reflect that this is an HMS dataset

		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because @ActualCountHMS > 0 AND Not (@CurrentDatasetType LIKE ''HMS%'' Or @CurrentDatasetType LIKE ''%-HMS'')'
		End
		Else
			Set @NewDatasetType = ' an HMS-based dataset type'	

		Goto AutoDefineDSType
	End
	

	If (@ActualCountCIDHMSn + @ActualCountETDHMSn) > 0 AND Not @CurrentDatasetType LIKE '%-HMSn%'
	Begin
		-- Dataset contains CID or ETD HMSn spectra, but the current dataset type doesn't reflect that this is an HMSn dataset

		If @CurrentDatasetType IN ('IMS-HMS', 'IMS-HMS-MSn')
		Begin
			Set @NewDatasetType = 'IMS-HMS-HMSn'
		End
		Else
		Begin
			If Not @CurrentDatasetType LIKE 'IMS%'
			Begin
				Set @AutoDefineDSType = 1
				If @InfoOnly = 1
					Print 'Set @AutoDefineDSType=1 because (@ActualCountCIDHMSn + @ActualCountETDHMSn) > 0 AND Not @CurrentDatasetType LIKE ''%-HMSn%'''

			End
			Else
				Set @NewDatasetType = ' an HMS-based dataset type'	
		End
		
		Goto AutoDefineDSType
	End


	If (@ActualCountCIDMSn + @ActualCountETDMSn) > 0 AND Not @CurrentDatasetType LIKE '%-MSn%'
	Begin
		-- Dataset contains CID or ETD MSn spectra, but the current dataset type doesn't reflect that this is an MSn dataset
		If @CurrentDatasetType = 'IMS-HMS'
		Begin
			Set @NewDatasetType = 'IMS-HMS-MSn'
		End
		Else
		Begin
			If Not @CurrentDatasetType LIKE 'IMS%'
			Begin
				Set @AutoDefineDSType = 1
				If @InfoOnly = 1
					Print 'Set @AutoDefineDSType=1 because (@ActualCountCIDMSn + @ActualCountETDMSn) > 0 AND Not @CurrentDatasetType LIKE ''%-MSn%'''

			End
			Else
				Set @NewDatasetType = ' an MSn-based dataset type'
		End
			
		Goto AutoDefineDSType
	End

	If (@ActualCountETDMSn + @ActualCountETDHMSn) > 0 AND Not @CurrentDatasetType LIKE '%ETD%'
	Begin
		-- Dataset has ETD scans, but current dataset type doesn't reflect this
		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because (@ActualCountETDMSn + @ActualCountETDHMSn) > 0 AND Not @CurrentDatasetType LIKE ''%ETD%'''
		End
		Else
			Set @NewDatasetType = ' an ETD-based dataset type'	

		Goto AutoDefineDSType
	End

	If @ActualCountHCD > 0 AND Not @CurrentDatasetType LIKE '%HCD%'
	Begin
		-- Dataset has HCD scans, but current dataset type doesn't reflect this
		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because @ActualCountHCD > 0 AND Not @CurrentDatasetType LIKE ''%HCD%'''
		End
		Else
			Set @NewDatasetType = ' an HCD-based dataset type'
		
		Goto AutoDefineDSType
	End

	If (@ActualCountETDMSn + @ActualCountETDHMSn) > 0 AND Not @CurrentDatasetType LIKE '%ETD%'
	Begin
		-- Dataset has ETD scans, but current dataset type doesn't reflect this
		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because (@ActualCountETDMSn + @ActualCountETDHMSn) > 0 AND Not @CurrentDatasetType LIKE ''%ETD%'''
		End
		Else
			Set @NewDatasetType = ' an ETD-based dataset type'	

		Goto AutoDefineDSType
	End

	If @ActualCountPQD > 0 AND Not @CurrentDatasetType LIKE '%PQD%'
	Begin
		-- Dataset has PQD scans, but current dataset type doesn't reflect this
		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because @ActualCountPQD > 0 AND Not @CurrentDatasetType LIKE ''%PQD%'''
		End
		Else
			Set @NewDatasetType = ' a PQD-based dataset type'
		
		Goto AutoDefineDSType
	End


	If @ActualCountHCD = 0 AND @CurrentDatasetType LIKE '%HCD%'
	Begin
		-- Dataset does not have HCD scans, but current dataset type says it does
		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because @ActualCountHCD = 0 AND @CurrentDatasetType LIKE ''%HCD%'''
		End
		Else
			Set @WarnMessage = 'Warning: Dataset type is ' + @CurrentDatasetType + ' but no HCD scans are present'
		
		Goto AutoDefineDSType
	End

	If (@ActualCountETDMSn + @ActualCountETDHMSn) = 0 AND @CurrentDatasetType LIKE '%ETD%'
	Begin
		-- Dataset does not have ETD scans, but current dataset type says it does
		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because (@ActualCountETDMSn + @ActualCountETDHMSn) = 0 AND @CurrentDatasetType LIKE ''%ETD%'''
		End
		Else
			Set @WarnMessage = 'Warning: Dataset type is ' + @CurrentDatasetType + ' but no ETD scans are present'
		
		Goto AutoDefineDSType
	End
		
	If (@ActualCountCIDHMSn + @ActualCountETDHMSn + @ActualCountHCD) = 0 AND @CurrentDatasetType LIKE '%-HMSn%'
	Begin
		-- Dataset does not have HMSn scans, but current dataset type says it does
		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because (@ActualCountCIDHMSn + @ActualCountETDHMSn + @ActualCountHCD) = 0 AND @CurrentDatasetType LIKE ''%-HMSn%'''
		End
		Else
			Set @WarnMessage = 'Warning: Dataset type is ' + @CurrentDatasetType + ' but no high res MSn scans are present'
		
		Goto AutoDefineDSType
	End

	If (@ActualCountCIDMSn + @ActualCountETDMSn) = 0 AND @CurrentDatasetType LIKE '%-MSn%'
	Begin
		-- Dataset does not have MSn scans, but current dataset type says it does
		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because (@ActualCountCIDMSn + @ActualCountETDMSn) = 0 AND @CurrentDatasetType LIKE ''%-MSn%'''
		End
		Else
			Set @WarnMessage = 'Warning: Dataset type is ' + @CurrentDatasetType + ' but no low res MSn scans are present'
		
		Goto AutoDefineDSType
	End


	If @ActualCountHMS = 0 AND (@CurrentDatasetType LIKE 'HMS%' Or @CurrentDatasetType LIKE '%-HMS')
	Begin
		-- Dataset does not have HMS scans, but current dataset type says it does		
		If Not @CurrentDatasetType LIKE 'IMS%'
		Begin
			Set @AutoDefineDSType = 1
			If @InfoOnly = 1
				Print 'Set @AutoDefineDSType=1 because @ActualCountHMS = 0 AND (@CurrentDatasetType LIKE ''HMS%'' Or @CurrentDatasetType LIKE ''%-HMS'')'
		End
		Else
			Set @WarnMessage = 'Warning: Dataset type is ' + @CurrentDatasetType + ' but no HMS scans are present'
		
		Goto AutoDefineDSType
	End



	-----------------------------------------------------------
	-- Possibly auto-generate the dataset type 
	-- If @AutoDefineDSType is non-zero then will update the dataset type to this value
	-- Otherwise, will compare to the actual dataset type and post a warning if they differ
	-----------------------------------------------------------

AutoDefineDSType:
	
	If Not @CurrentDatasetType LIKE 'IMS%' AND NOT @CurrentDatasetType IN ('MALDI-HMS', 'C60-SIMS-HMS')
	Begin
		-- Auto-define the dataset type based on the scan type counts
		-- The auto-defined types will be one of the following:
			-- MS
			-- HMS
			-- MS-MSn
			-- HMS-MSn
			-- HMS-HMSn
			-- GC-MS
		-- In addition, if HCD scans are present, then -HCD will be in the middle
		-- Furthermore, if ETD scans are present, then -ETD or -CID/ETD will be in the middle

		If @ActualCountHMS > 0
			Set @DSTypeAutoGen = 'HMS'
		Else
		Begin
			Set @DSTypeAutoGen = 'MS'
			
			If @ActualCountMS = 0 And (@ActualCountCIDHMSn + @ActualCountETDHMSn + @ActualCountHCD) > 0
			Begin
				-- Dataset only has fragmentation spectra and no MS1 spectra
				-- Since all of the fragmentation spectra are high res, use 'HMS'
				Set @DSTypeAutoGen = 'HMS'
			End
			
			If @ActualCountGCMS > 0
			Begin
				Set @DSTypeAutoGen = 'GC-MS'
			End
		End
		
		If @ActualCountHCD > 0
			Set @DSTypeAutoGen = @DSTypeAutoGen + '-HCD'

		iF @ActualCountPQD > 0
			Set @DSTypeAutoGen = @DSTypeAutoGen + '-PQD'
		
		If (@ActualCountCIDHMSn + @ActualCountETDHMSn) > 0
		Begin
			-- One or more High res CID or ETD MSn spectra
			If (@ActualCountETDMSn + @ActualCountETDHMSn) > 0
			Begin
				-- One or more ETD spectra
				If (@ActualCountCIDMSn + @ActualCountCIDHMSn) > 0
					Set @DSTypeAutoGen = @DSTypeAutoGen + '-CID/ETD-HMSn'
				Else
					Set @DSTypeAutoGen = @DSTypeAutoGen + '-ETD-HMSn'
			End
			Else
			Begin
				-- No ETD spectra
				If @ActualCountHCD > 0 OR @ActualCountPQD > 0
					Set @DSTypeAutoGen = @DSTypeAutoGen + '-CID-HMSn'
				Else
					Set @DSTypeAutoGen = @DSTypeAutoGen + '-HMSn'
			End			
		End
		Else
		Begin
			
			If (@ActualCountCIDMSn + @ActualCountETDMSn) > 0
			Begin
				-- One or more Low res CID or ETD MSn spectra
				If (@ActualCountETDMSn + @ActualCountETDHMSn) > 0
				Begin
					-- One or more ETD spectra
					If @ActualCountCIDMSn > 0
						Set @DSTypeAutoGen = @DSTypeAutoGen + '-CID/ETD-MSn'
					Else
						Set @DSTypeAutoGen = @DSTypeAutoGen + '-ETD-MSn'
				End
				Else
				Begin
					-- No ETD spectra
					If @ActualCountHCD > 0 OR @ActualCountPQD > 0
						Set @DSTypeAutoGen = @DSTypeAutoGen + '-CID-MSn'
					Else
						Set @DSTypeAutoGen = @DSTypeAutoGen + '-MSn'
				End			
			End
		
		End
		
		
		-- Possibly auto-fix the auto-generated dataset type
		If @DSTypeAutoGen = 'HMS-HCD'
			Set @DSTypeAutoGen = 'HMS-HCD-HMSn'
	
	End

	If @DSTypeAutoGen <> '' AND @AutoDefineOnAllMismatches <> 0
	Begin
		Set @AutoDefineDSType = 1	
		If @InfoOnly = 1
			Print 'Set @AutoDefineDSType=1 because @DSTypeAutoGen <> '''' AND @AutoDefineOnAllMismatches <> 0'
	End
	
	If @AutoDefineDSType <> 0
	Begin
		If @DSTypeAutoGen <> @CurrentDatasetType And @DSTypeAutoGen <> ''
			Set @NewDatasetType = @DSTypeAutoGen
	End
	Else
	Begin
		If @NewDatasetType = '' And @WarnMessage = ''
		Begin
			If @DSTypeAutoGen <> @CurrentDatasetType And @DSTypeAutoGen <> ''
				Set @WarnMessage = 'Warning: Dataset type is ' + @CurrentDatasetType + ' while auto-generated type is ' + @DSTypeAutoGen
		End
	End
	

FixDSType:
	
	-----------------------------------------------------------
	-- If a warning message was defined, display it
	-----------------------------------------------------------
	--
	If @WarnMessage <> ''
	Begin
		Set @message = @WarnMessage

		Exec @DSComment = AppendToText @DSComment, @message, @AddDuplicateText = 0, @Delimiter = '; '
	
		If @infoOnly = 0
		Begin
			UPDATE T_Dataset
			SET DS_Comment = @DSComment
			WHERE Dataset_ID = @DatasetID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		End

		Goto Done
	End

	-----------------------------------------------------------
	-- If a new dataset is defined, then update the dataset type
	-----------------------------------------------------------
	--
	If @NewDatasetType <> ''
	Begin
		Set @NewDSTypeID = 0
	
		SELECT @NewDSTypeID = DST_Type_ID
		FROM T_DatasetTypeName
		WHERE (DST_name = @NewDatasetType)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	
		If @NewDSTypeID <> 0
		Begin
			-- Append a message to the dataset comment
			-- However, do not append "Auto-switched dataset type from HMS-HMSn to HMS-HCD-HMSn" since this happens for nearly every Q-Exactive dataset
			--
			If Not (@CurrentDatasetType = 'HMS-HMSn' And @NewDatasetType = 'HMS-HCD-HMSn')
			Begin
				Set @message = 'Auto-switched dataset type from ' + @CurrentDatasetType + ' to ' + @NewDatasetType + ' on ' + SUBSTRING(CONVERT(varchar(32), GETDATE(), 121), 1, 10)
				Exec @DSComment = AppendToText @DSComment, @message, @AddDuplicateText = 0, @Delimiter = '; '
			End
			
			If @infoOnly = 0
			Begin
				UPDATE T_Dataset
				SET DS_Type_ID = @NewDSTypeID,
				    DS_Comment = @DSComment
				WHERE Dataset_ID = @DatasetID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
			End

		End		
		Else
		Begin
			Set @message = 'Unrecognized dataset type based on actual scan types; need to auto-switch from ' + @CurrentDatasetType + ' to ' + @NewDatasetType

			Exec @DSComment = AppendToText @DSComment, @message, @AddDuplicateText = 0, @Delimiter = '; '

			If @infoOnly = 0
			Begin
				UPDATE T_Dataset
				SET DS_Comment = @DSComment
				WHERE Dataset_ID = @DatasetID
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
			End
		End
	End

 
Done:

	If @InfoOnly <> 0
	Begin
		If Len(@message) = 0
			Set @message = 'Dataset type is valid: ' + @CurrentDatasetType
			
		Print @message
		SELECT @message as Message
	End
			
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[ValidateDatasetType] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateDatasetType] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateDatasetType] TO [PNL\D3M580] AS [dbo]
GO
