/****** Object:  StoredProcedure [dbo].[UpdateCachedInstrumentUsageByProposal] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE UpdateCachedInstrumentUsageByProposal
/****************************************************
**
**	Desc:	Updates the data in T_Cached_Instrument_Usage_by_Proposal
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	12/02/2013 mem - Initial Version
**			02/23/2016 mem - Add set XACT_ABORT on
**
*****************************************************/
(
	@message varchar(255) = '' output
)
AS

	Set XACT_ABORT, nocount on

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	set @message = ''

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try
		Set @CurrentLocation = 'Update T_Cached_Instrument_Usage_by_Proposal'
		--
		MERGE T_Cached_Instrument_Usage_by_Proposal AS target
		USING 
			(
				SELECT TIN.IN_Group,
				       TRR.RDS_EUS_Proposal_ID,
				       CONVERT(float, SUM(TD.Acq_Length_Minutes) / 60.0) AS Actual_Hours
				FROM T_Dataset AS TD
				     INNER JOIN T_Requested_Run AS TRR
				       ON TD.Dataset_ID = TRR.DatasetID
				     INNER JOIN T_Instrument_Name AS TIN
				       ON TIN.Instrument_ID = TD.DS_instrument_name_ID
				WHERE (TD.DS_rating > 1)
				      AND (TRR.RDS_EUS_UsageType = 16)                       -- User
				      AND (TD.DS_state_ID = 3)                               -- Complete
				      AND (TD.Acq_Time_Start >= dbo.GetFiscalYearStart(1))   -- The current fiscal year, plus the previous fiscal year
				      AND NOT TRR.RDS_EUS_Proposal_ID IS NULL
				GROUP BY TIN.IN_Group, TRR.RDS_EUS_Proposal_ID
			) AS Source (IN_Group, EUS_Proposal_ID, Actual_Hours)
		ON (target.IN_Group = source.IN_Group AND target.EUS_Proposal_ID = source.EUS_Proposal_ID)
		WHEN Matched AND 
					(	IsNull(target.Actual_Hours, 0) <> IsNull(source.Actual_Hours, 0)
					)
			THEN UPDATE 
				Set	Actual_Hours = source.Actual_Hours				
		WHEN Not Matched THEN
			INSERT (IN_Group, EUS_Proposal_ID, Actual_Hours
					)
			VALUES (source.IN_Group, source.EUS_Proposal_ID, source.Actual_Hours)
		WHEN NOT MATCHED BY SOURCE THEN
			DELETE 
		;
	
		if @myError <> 0
		begin
			set @message = 'Error updating T_Cached_Instrument_Usage_by_Proposal via merge (ErrorID = ' + Convert(varchar(12), @myError) + ')'
			execute PostLogEntry 'Error', @message, 'UpdateCachedInstrumentUsage'
			goto Done
		end

	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateCachedInstrumentUsage')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch
			
Done:
	Return @myError

GO
