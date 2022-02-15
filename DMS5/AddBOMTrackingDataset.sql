/****** Object:  StoredProcedure [dbo].[AddBOMTrackingDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddBOMTrackingDataset]
/****************************************************
**
**  Desc:
**      Adds new tracking dataset for the beginning of the month (BOM)
**      for the given year, month, and instrument 
**
**      If @month is 'next', adds a tracking dataset for the beginning of the next month
**
**  Auth:   grk
**  Date:   12/14/2012
**          12/14/2012 grk - initial release
**          12/16/2012 grk - added concept of 'next' month
**          02/01/2013 grk - fixed broken logic for specifying year/month
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/14/2022 mem - Update error messages to show the correct dataset name
**                         - When @mode is 'debug', update @message to include the run start date and dataset name
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2012, Battelle Memorial Institute
*****************************************************/
(
    @month varchar(16) = '',
    @year varchar(16) = '',
    @instrumentName varchar(64),
    @mode varchar(12) = 'add',              -- 'add' or 'debug'
    @message varchar(512) output,
    @callingUser varchar(128)  = 'D3E154'   -- Ron Moore
)
As
    Set XACT_ABORT, nocount on

    Declare @myError INT = 0

    ---------------------------------------------------
    -- validate input arguments
    ---------------------------------------------------
    If ISNULL(@instrumentName, '') = ''
    Begin
        RAISERROR ('Instrument name cannot be empty', 11, 10)
    End

    ---------------------------------------------------
    -- Declare parameters for making BOM tracking dataset
    ---------------------------------------------------

    Declare @datasetNum varchar(128)
    Declare @runStart varchar(32)
    Declare @experimentNum varchar(64) = 'Tracking'
    Declare @operPRN varchar(64) = @callingUser
    Declare @runDuration varchar(16) = '10'
    Declare @comment varchar(512) = ''
    Declare @eusProposalID varchar(10) = ''
    Declare @eusUsageType varchar(50) = 'MAINTENANCE'
    Declare @eusUsersList varchar(1024) = ''

    BEGIN TRY
        set @message = ''

        ---------------------------------------------------
        -- Determine the BOM date to use
        ---------------------------------------------------

        Declare @now datetime = GETDATE()
        Declare @mn varchar(24) = @month
        Declare @yr varchar(24) = @year

        If @month = '' OR @month = 'next'
        Begin
            Set @mn = CONVERT(varchar(12), DATEPART(MONTH, @now))
        End

        If @year = '' OR @month = 'next'
        Begin
            Set @yr = CONVERT(varchar(12), DATEPART(YEAR, @now))
        End

        Declare @bom datetime = @mn + '/1/' + @yr + ' 12:00:00:000AM'

        If @month = 'next'
        Begin
            Set @bom = DATEADD(MONTH, 1, @bom)        -- Beginning of the next month after @bom
        End

        Set @runStart = @bom

        Declare @dateLabel varchar(24) = REPLACE(CONVERT(varchar(15), @bom, 6), ' ', '')

        Set @datasetNum = @instrumentName + '_' + @dateLabel

        ---------------------------------------------------
        -- is it OK to make the dataset?
        ---------------------------------------------------

        Declare @instID INT = 0

        SELECT @instID = Instrument_ID 
        FROM dbo.T_Instrument_Name 
        WHERE IN_name = @instrumentName

        If @instID = 0
        Begin
            RAISERROR ('Instrument "%s" cannot be found', 11, 20, @instrumentName)
        End

        If EXISTS (SELECT * FROM dbo.T_Dataset WHERE Dataset_Num = @datasetNum)
        Begin
            RAISERROR ('Dataset "%s" already exists', 11, 21, @datasetNum)
        End

        Declare @conflictingDataset varchar(128) = ''
        Declare @datasetID Int = 0

        SELECT @conflictingDataset = Dataset_Num 
        FROM dbo.T_Dataset 
        WHERE Acq_Time_Start = @bom AND DS_instrument_name_ID = @instID

        If (@conflictingDataset <> '')
        Begin
            RAISERROR ('Dataset "%s" has same start time', 11, 22, @conflictingDataset)
        End

        Set @conflictingDataset = ''

        SELECT @conflictingDataset = Dataset_Num, @datasetID = Dataset_ID
        FROM T_Dataset
        WHERE (Not (Acq_Time_Start IS NULL)) AND
              (Not (Acq_Time_End IS NULL)) AND
              @bom BETWEEN Acq_Time_Start AND Acq_Time_End AND
              DS_instrument_name_ID = @instID
        
        If (@conflictingDataset <> '')
        Begin
            RAISERROR ('Tracking dataset would overlap existing dataset "%s", Dataset ID %d', 11, 23, @conflictingDataset, @datasetID)
        End

        If @mode = 'debug'
        Begin
            ---------------------------------------------------
            -- Show debug info
            ---------------------------------------------------

            PRINT 'Dataset:        ' + @datasetNum
            PRINT 'Run Start:      ' + @runStart
            PRINT 'Experiment:     ' + @experimentNum
            PRINT 'Operator PRN:   ' + @operPRN
            PRINT 'Run Duration:   ' + @runDuration
            PRINT 'Comment:        ' + @comment
            PRINT 'EUS Proposal:   ' + @eusProposalID
            PRINT 'EUS Usage Type: ' + @eusUsageType
            PRINT 'EUS Users:      ' + @eusUsersList
            PRINT 'mode:           ' + @mode

            Set @message = 'Would create dataset with run start ' + Cast(@runStart As Varchar(24)) + ', name=' + @datasetNum
        End

        If @mode = 'add'
        Begin
            ---------------------------------------------------
            -- Add the tracking dataset
            ---------------------------------------------------

            EXEC @myError = AddUpdateTrackingDataset
                                @datasetNum,
                                @experimentNum,
                                @operPRN,
                                @instrumentName,
                                @runStart,
                                @runDuration,
                                @comment,
                                @eusProposalID,
                                @eusUsageType,
                                @eusUsersList,
                                @mode,
                                @message output,
                                @callingUser
        End


    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message OUTPUT, @myError OUTPUT

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'AddBOMTrackingDataset'
    END CATCH

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddBOMTrackingDataset] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddBOMTrackingDataset] TO [DMS2_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddBOMTrackingDataset] TO [PNL\D3M578] AS [dbo]
GO
