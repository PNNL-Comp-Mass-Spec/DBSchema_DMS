/****** Object:  StoredProcedure [dbo].[UpdateCachedInstrumentUsageByProposal] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateCachedInstrumentUsageByProposal]
/****************************************************
**
**  Desc:   Updates the data in T_Cached_Instrument_Usage_by_Proposal
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/02/2013 mem - Initial Version
**          02/23/2016 mem - Add set XACT_ABORT on
**          02/10/2022 mem - Add new usage type codes added to T_EUS_UsageType on 2021-05-26
**                         - Use the last 12 months for determining usage (previously used last two fiscal years)
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

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128)
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
                WHERE TD.DS_rating > 1
                      AND TRR.RDS_EUS_UsageType IN (16, 19, 20, 21)           -- User, User_Unknown, User_Onsite, User_Remote
                      AND TD.DS_state_ID = 3                                  -- Complete
                      AND TD.Acq_Time_Start >= DateAdd(Month, -12, GetDate()) -- The last 12 months (previously used >= dbo.GetFiscalYearStart(1))
                      AND NOT TRR.RDS_EUS_Proposal_ID IS NULL
                GROUP BY TIN.IN_Group, TRR.RDS_EUS_Proposal_ID
            ) AS Source (IN_Group, EUS_Proposal_ID, Actual_Hours)
        ON (target.IN_Group = source.IN_Group AND target.EUS_Proposal_ID = source.EUS_Proposal_ID)
        WHEN Matched AND
             IsNull(target.Actual_Hours, 0) <> IsNull(source.Actual_Hours, 0)
        THEN UPDATE
            Set Actual_Hours = source.Actual_Hours
        WHEN Not Matched THEN
            INSERT (IN_Group, EUS_Proposal_ID, Actual_Hours)
            VALUES (source.IN_Group, source.EUS_Proposal_ID, source.Actual_Hours)
        WHEN NOT MATCHED BY SOURCE THEN
            DELETE
        ;

        If @myError <> 0
        Begin
            Set @message = 'Error updating T_Cached_Instrument_Usage_by_Proposal via merge (ErrorID = ' + Convert(varchar(12), @myError) + ')'
            Execute PostLogEntry 'Error', @message, 'UpdateCachedInstrumentUsage'
            Goto Done
        End

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
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedInstrumentUsageByProposal] TO [DDL_Viewer] AS [dbo]
GO
