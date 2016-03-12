/****** Object:  StoredProcedure [dbo].[UpdateEUSInstrumentsFromEUSImports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateEUSInstrumentsFromEUSImports]
/****************************************************
**
**	Desc: 
**  Updates information in T_EMSL_Instruments from EUS
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	06/29/2011 grk - Initial version
**          07/19/2011 grk - "Last_Affected"
**			09/02/2011 mem - Now calling PostUsageLogEntry
**          03/27/2012 grk - Added EUS_Active_Sw and EUS_Primary_Instrument
**    
*****************************************************/
(
	@message varchar(512)='' output
)
As
	Set Nocount On

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @MergeUpdateCount int
	Declare @MergeInsertCount int
	Declare @MergeDeleteCount int
	
	Set @MergeUpdateCount = 0
	Set @MergeInsertCount = 0
	Set @MergeDeleteCount = 0

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try

		---------------------------------------------------
		-- Create the temporary table that will be used to
		-- track the number of inserts, updates, and deletes 
		-- performed by the MERGE statement
		---------------------------------------------------
		
		CREATE TABLE #Tmp_UpdateSummary (
			UpdateAction varchar(32)
		)
		
		--CREATE CLUSTERED INDEX #IX_Tmp_UpdateSummary ON #Tmp_UpdateSummary (UpdateAction)

		Set @CurrentLocation = 'Update T_EUS_Proposals'
		
		---------------------------------------------------
		-- Use a MERGE Statement to synchronize 
		-- T_ with V_
		---------------------------------------------------

		MERGE T_EMSL_Instruments AS Target
			USING 
				( SELECT    INSTRUMENT_ID AS Instrument_ID ,
							INSTRUMENT_NAME AS Instrument_Name ,
							EUS_DISPLAY_NAME AS Display_Name ,
							AVAILABLE_HOURS AS Available_Hours,
							ACTIVE_SW AS Active_Sw, 
							PRIMARY_INSTRUMENT AS Primary_Instrument
				  FROM      dbo.V_EUS_Import_Instruments Source
				) AS Source ( Instrument_ID, Instrument_Name, Display_Name,
							  Available_Hours, Active_Sw, Primary_Instrument )
			ON ( target.EUS_Instrument_ID = source.Instrument_ID )
			WHEN MATCHED 
				THEN
		UPDATE    SET
				EUS_Instrument_Name = Instrument_Name ,
				EUS_Display_Name = Display_Name ,
				EUS_Available_Hours = Available_Hours,
				Last_Affected = GETDATE(),
				EUS_Active_Sw = Active_Sw,
				EUS_Primary_Instrument = Primary_Instrument
			WHEN NOT MATCHED BY TARGET
				THEN
		INSERT  (
				  EUS_Instrument_ID ,
				  EUS_Instrument_Name ,
				  EUS_Display_Name,
				  EUS_Available_Hours,
				  EUS_Active_Sw,
				  EUS_Primary_Instrument
				) VALUES
				( source.Instrument_ID ,
				  source.Instrument_Name ,
				  source.Display_Name ,
				  source.Available_Hours,
				  source.Active_Sw,
				  source.Primary_Instrument
				)
		OUTPUT $ACTION INTO #Tmp_UpdateSummary ;


		set @MergeUpdateCount = 0
		set @MergeInsertCount = 0
		set @MergeDeleteCount = 0

		SELECT @MergeInsertCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'INSERT'

		SELECT @MergeUpdateCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'UPDATE'

		SELECT @MergeDeleteCount = COUNT(*)
		FROM #Tmp_UpdateSummary
		WHERE UpdateAction = 'DELETE'
		
		If @MergeUpdateCount > 0 OR @MergeInsertCount > 0 OR @MergeDeleteCount > 0
		Begin
			Set @message = 'Updated T_EUS_Proposals: ' + Convert(varchar(12), @MergeInsertCount) + ' added; ' + Convert(varchar(12), @MergeUpdateCount) + ' updated'
			
			If @MergeDeleteCount > 0
				Set @message = @message + '; ' + Convert(varchar(12), @MergeDeleteCount) + ' deleted'
				
			Exec PostLogEntry 'Normal', @message, 'UpdateEUSInstrumentsFromEUSImports'
			Set @message = ''
		End
		
	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateEUSInstrumentsFromEUSImports')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch

	---------------------------------------------------
	-- Done
	---------------------------------------------------
			
Done:
	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = ''
	Exec PostUsageLogEntry 'UpdateEUSInstrumentsFromEUSImports', @UsageMessage

	Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSInstrumentsFromEUSImports] TO [PNL\D3M578] AS [dbo]
GO
