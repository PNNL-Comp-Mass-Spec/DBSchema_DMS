/****** Object:  StoredProcedure [dbo].[AddBOMTrackingDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddBOMTrackingDatasets]
/****************************************************
**
**  Desc:
**      Adds new tracking dataset for the first of the month
**      for all actively tracked instruments
**      for the given year and month
**
**      If @month is 'next', adds a tracking dataset for the beginning of the next month
**
**  Auth:   grk
**  Date:   12/16/2012
**          12/16/2012 grk - initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/14/2022 mem - Assure that msg is not an empty string when @mode is 'debug'
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2012, Battelle Memorial Institute
*****************************************************/
(
    @month varchar(16) = '',                -- current month, if blank
    @year varchar(16) = '',                 -- current year, if blank
    @mode varchar(12) = 'add',              -- 'add, 'info' (just show instrument names), or 'debug' (call AddBOMTrackingDataset and preview tracking datasets)
    @callingUser varchar(128)  = 'D3E154'   -- Ron Moore
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @message varchar(512) = ''

    ---------------------------------------------------
    -- temp table to hold list of tracked instruments
    ---------------------------------------------------

    CREATE TABLE #TI (
        Entry_ID int IDENTITY(1,1) NOT NULL,
        inst varchar(64),
        result INT NULL,
        msg varchar(512) NULL
    )

    BEGIN TRY

        ---------------------------------------------------
        -- Get list of tracked instruments
        ---------------------------------------------------

        INSERT INTO #TI (inst)
        SELECT VT.Name
        FROM dbo.V_Instrument_Tracked VT

        ---------------------------------------------------
        -- Loop through tracked instruments
        -- and try to make BOM tracking dataset for each
        ---------------------------------------------------

        Declare @continue tinyint = 1
        Declare @entryID int = -1
        Declare @instrumentName varchar(64)
        Declare @msg varchar(512) = ''
        Declare @err varchar(16) = ''
        Declare @returnCode Int

        While @continue > 0
        Begin --<loop>
            Set @instrumentName = ''

            SELECT TOP 1
                @instrumentName = inst,
                @entryID = Entry_ID
            FROM #TI
            WHERE Entry_ID > @entryID
            ORDER BY Entry_ID ASC

            If @instrumentName = ''
            Begin
                Set @continue = 0
            End
            Else
            Begin --<a>
                If @mode in ('debug', 'info') 
                Begin
                    PRINT '->' + @instrumentName
                End

                If @mode in ('add', 'debug')
                Begin --<b>
                    EXEC @returnCode = AddBOMTrackingDataset
                                            @month,
                                            @year,
                                            @instrumentName,
                                            @mode,
                                            @msg OUTPUT,
                                            @callingUser

                    If @mode = 'debug' And Coalesce(@msg, '') = ''
                    Begin
                        Set @msg = 'Called AddBOMTrackingDataset with @mode=''debug'''
                    End
                End --<b>

                UPDATE #TI
                SET result = @returnCode,
                    msg = @msg
                WHERE Entry_ID = @entryID

            End --<a>
        End --<loop>

        If @mode in ('debug', 'info')
        Begin
            SELECT * FROM #TI
        End

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message OUTPUT, @myError OUTPUT
        Exec PostLogEntry 'Error', @message, 'AddBOMTrackingDatasets'
    END CATCH

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddBOMTrackingDatasets] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddBOMTrackingDatasets] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddBOMTrackingDatasets] TO [PNL\D3M578] AS [dbo]
GO
