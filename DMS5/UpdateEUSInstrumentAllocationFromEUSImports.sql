/****** Object:  StoredProcedure [dbo].[UpdateEUSInstrumentAllocationFromEUSImports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateEUSInstrumentAllocationFromEUSImports]
/****************************************************
**
**	Desc: 
**  Updates information in T_EMSL_Instrument_Allocation from EUS
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	06/29/2011 grk - Initial version
**			09/02/2011 mem - Now calling PostUsageLogEntry
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
		-- Start transaction
		---------------------------------------------------

		declare @transName varchar(32)
		set @transName = 'UpdateEUSInstrumentAllocationFromEUSImports'
		begin transaction @transName

	
		DELETE FROM T_EMSL_Instrument_Allocation

		INSERT  INTO T_EMSL_Instrument_Allocation
				( EUS_Instrument_ID ,
				  Ext_Display_Name ,
				  Proposal_ID ,
				  Allocated_Hours ,
				  FY ,
				  Ext_Requested_Hours
				)
				SELECT  INSTRUMENT_ID AS EUS_Instrument_ID ,
						EUS_DISPLAY_NAME AS Ext_Display_Name ,
						PROPOSAL_ID AS Proposal_ID ,
						ALLOCATED_HOURS AS Allocated_Hours ,
						FY ,
						REQUESTED_HOURS
				FROM    V_EUS_Import_Requested_Allocated_Hours AS Source
				WHERE   ( NOT ( ALLOCATED_HOURS IS NULL )
						)
		commit transaction @transName

	End Try
	Begin Catch
		rollback transaction @transName
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateEUSInstrumentAllocationFromEUSImports')
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
	Exec PostUsageLogEntry 'UpdateEUSInstrumentAllocationFromEUSImports', @UsageMessage

	Return @myError



GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSInstrumentAllocationFromEUSImports] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSInstrumentAllocationFromEUSImports] TO [PNL\D3M580] AS [dbo]
GO
