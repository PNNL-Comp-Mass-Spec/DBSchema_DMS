/****** Object:  StoredProcedure [dbo].[UpdateEUSInstrumentsFromEUSImports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateEUSInstrumentsFromEUSImports]
/****************************************************
**
**  Desc:   Updates information in T_EMSL_Instruments from EUS
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   06/29/2011 grk - Initial version
**          07/19/2011 grk - "Last_Affected"
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          03/27/2012 grk - Added EUS_Active_Sw and EUS_Primary_Instrument
**          05/12/2021 mem - Use new NEXUS-based views
**
*****************************************************/
(
    @message varchar(512) = '' output
)
As
    Set Nocount On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @mergeUpdateCount int = 0
    Declare @mergeInsertCount int = 0
    Declare @mergeDeleteCount int = 0

    Declare @callingProcName varchar(128)
    Declare @currentLocation varchar(128) = 'Start'

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

        Set @currentLocation = 'Update T_EMSL_Instruments'

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- T_EMSL_Instruments with V_NEXUS_Import_Instruments
        ---------------------------------------------------

        MERGE T_EMSL_Instruments AS Target
        USING
            ( SELECT    instrument_id AS Instrument_ID ,
                        instrument_name AS Instrument_Name ,
                        eus_display_name AS Display_Name ,
                        available_hours AS Available_Hours,
                        active_sw AS Active_Sw,
                        primary_instrument AS Primary_Instrument
              FROM      dbo.V_NEXUS_Import_Instruments Source
            ) AS Source ( Instrument_ID, Instrument_Name, Display_Name,
                          Available_Hours, Active_Sw, Primary_Instrument )
        ON ( target.EUS_Instrument_ID = source.Instrument_ID )
        WHEN MATCHED
            THEN UPDATE SET
                EUS_Instrument_Name = Instrument_Name ,
                EUS_Display_Name = Display_Name ,
                EUS_Available_Hours = Available_Hours,
                Last_Affected = GETDATE(),
                EUS_Active_Sw = Active_Sw,
                EUS_Primary_Instrument = Primary_Instrument
        WHEN NOT MATCHED BY TARGET
            THEN INSERT  (
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

        Set @mergeUpdateCount = 0
        Set @mergeInsertCount = 0
        Set @mergeDeleteCount = 0

        SELECT @mergeInsertCount = COUNT(*)
        FROM #Tmp_UpdateSummary
        WHERE UpdateAction = 'INSERT'

        SELECT @mergeUpdateCount = COUNT(*)
        FROM #Tmp_UpdateSummary
        WHERE UpdateAction = 'UPDATE'

        SELECT @mergeDeleteCount = COUNT(*)
        FROM #Tmp_UpdateSummary
        WHERE UpdateAction = 'DELETE'

        If @mergeUpdateCount > 0 OR @mergeInsertCount > 0 OR @mergeDeleteCount > 0
        Begin
            Set @message = 'Updated T_EMSL_Instruments: ' + Convert(varchar(12), @mergeInsertCount) + ' added; ' + Convert(varchar(12), @mergeUpdateCount) + ' updated'

            If @mergeDeleteCount > 0
                Set @message = @message + '; ' + Convert(varchar(12), @mergeDeleteCount) + ' deleted'

            Exec PostLogEntry 'Normal', @message, 'UpdateEUSInstrumentsFromEUSImports'
            Set @message = ''
        End

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        Set @callingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateEUSInstrumentsFromEUSImports')
        exec LocalErrorHandler  @callingProcName, @currentLocation, @LogError = 1,
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

    Declare @usageMessage varchar(512) = ''
    Exec PostUsageLogEntry 'UpdateEUSInstrumentsFromEUSImports', @usageMessage

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSInstrumentsFromEUSImports] TO [DDL_Viewer] AS [dbo]
GO
