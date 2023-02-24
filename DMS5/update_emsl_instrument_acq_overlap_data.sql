/****** Object:  StoredProcedure [dbo].[UpdateEMSLInstrumentAcqOverlapData] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateEMSLInstrumentAcqOverlapData]
/****************************************************
**
**  Desc:
**    Populate field Dataset_ID_Acq_Overlap in T_EMSL_Instrument_Usage_Report
**    This is used to track datasets with identical acquisition start times
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/17/2022 mem - Initial version
**
*****************************************************/
(
    @instrument varchar(64),
    @year int,                          -- If 0, process all rows for the given instrument
    @month int,                         -- If 0, do not filter on month
    @message varchar(512) = '' output,
    @infoOnly tinyint = 0               -- Preview updates if non-zero; if 2 also show the contents of #Tmp_DatasetStartTimes; if 3 also show #Tmp_UpdatesToApply without joining to T_EMSL_Instrument_Usage_Report
)
AS
    SET XACT_ABORT, NOCOUNT ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @dmsInstrumentID Int
    Declare @itemType varchar(128)
    Declare @startDate datetime
    Declare @endDate datetime

    Declare @entryID int
    Declare @continue tinyint
    Declare @startTime datetime
    Declare @datasetID int
    Declare @lastSeq int

    Set @instrument = IsNull(@instrument, '')
    Set @year = IsNull(@year, 0)
    Set @month = IsNull(@month, 0)

    Set @message = LTrim(RTrim(IsNull(@message, '')))
    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateEMSLInstrumentAcqOverlapData', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ------------------------------------------------------
    -- Validate parameters
    ------------------------------------------------------
    --
    If @instrument = ''
    Begin
        Set @message = '@instrument must be defined'
        RAISERROR (@message, 10, 1)
    End

    SELECT @dmsInstrumentID = Instrument_ID
    FROM T_Instrument_Name
    WHERE IN_name = @instrument
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Invalid DMS instrument name: ' + @instrument
        RAISERROR (@message, 10, 1)
    End

    BEGIN TRY

        ---------------------------------------------------
        -- Temporary table for rows to process
        ---------------------------------------------------

        CREATE TABLE #Tmp_DatasetStartTimes (
            ID int Identity(1,1) Not Null,
            DMS_Inst_ID int Not Null,
            ItemType varchar(128) Not Null,         -- 'Dataset' or 'Interval'
            StartTime datetime Not Null,
            Datasets int Null                       -- Number of datasets or number of long intervals with this start time
        )

        -- ItemType and Datasets are included here so that they're included in the index, removing the need for a table lookup
        Create Unique Clustered Index #IX_Tmp_DatasetStartTimes_ID_Datasets On #Tmp_DatasetStartTimes (ID, ItemType, Datasets)

        -- Also create an index that supports StartTime lookup by dataset and type
        Create Unique Index #IX_Tmp_DatasetStartTimes_InstID_StartTime On #Tmp_DatasetStartTimes (DMS_Inst_ID, ItemType, StartTime)

        ---------------------------------------------------
        -- Temporary table to hold rows to update when previewing updates
        ---------------------------------------------------

        CREATE TABLE #Tmp_UpdatesToApply (
            ID Int Identity(1,1) Not Null,
            DMS_Inst_ID int Not Null,
            ItemType varchar(128) Not Null,         -- 'Dataset' or 'Interval'
            Start datetime Not Null,
            Dataset_ID int Not Null,
            Seq Int Not Null,
            Dataset varchar(256) Null,
            Dataset_ID_Acq_Overlap int Null
        )

        If @year <= 0
        Begin
            INSERT INTO #Tmp_DatasetStartTimes( DMS_Inst_ID,
                                                ItemType,
                                                StartTime,
                                                Datasets )
            SELECT DMS_Inst_ID,
                   [Type],
                   Start,
                   Count(*)
            FROM T_EMSL_Instrument_Usage_Report
            WHERE DMS_Inst_ID = @dmsInstrumentID
            GROUP BY DMS_Inst_ID, [Type], Start
            ORDER BY DMS_Inst_ID, [Type], Start
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @infoOnly > 0
            Begin
                Print 'Processing ' + Cast(@myRowCount As Varchar(12)) + ' start times for instrument ' + @instrument + ' in T_EMSL_Instrument_Usage_Report (no date filter)'
            End
        End
        Else
        Begin
            If @month <= 0
            Begin
                Set @startDate = CONVERT(varchar(12), @year) + '-01-01'
                Set @endDate =   CONVERT(varchar(12), @year + 1) + '-01-01'
            End
            Else
            Begin
                Set @startDate = CONVERT(varchar(12), @year) + '-' + CONVERT(varchar(12), @month) + '-01'
                Set @endDate = DateAdd(month, 1, @startDate)
            End

            INSERT INTO #Tmp_DatasetStartTimes( DMS_Inst_ID,
                                                ItemType,
                                                StartTime,
                                                Datasets )
            SELECT DMS_Inst_ID,
                   [Type],
                   Start,
                   Count(*)
            FROM T_EMSL_Instrument_Usage_Report
            WHERE Start >= @startDate AND
                  Start < @endDate AND
                  DMS_Inst_ID = @dmsInstrumentID
            GROUP BY DMS_Inst_ID, [Type], Start
            ORDER BY DMS_Inst_ID, [Type], Start
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @infoOnly > 0
            Begin
                Print 'Processing '  + Cast(@myRowCount As Varchar(12)) + ' start times for instrument ' + @instrument + ' in T_EMSL_Instrument_Usage_Report'
                Print 'Filtering for Start between ' + Convert(varchar(32), @startDate, 101) + ' and ' + Convert(varchar(32), @endDate, 101)
            End
        End

        If @infoOnly = 0
        Begin
            -- Set Dataset_ID_Acq_Overlap to Null for any entries where it is currently not null,
            -- yet there is only one dataset (or interval) for the given start time
            --
            UPDATE T_EMSL_Instrument_Usage_Report
            SET Dataset_ID_Acq_Overlap = NULL
            FROM T_EMSL_Instrument_Usage_Report InstUsage
                 INNER JOIN ( SELECT DMS_Inst_ID,
                                     ItemType,
                                     StartTime
                              FROM #Tmp_DatasetStartTimes
                              WHERE Datasets = 1 ) FilterQ
                   ON InstUsage.DMS_Inst_ID = FilterQ.DMS_Inst_ID And
                      InstUsage.[Type] = FilterQ.ItemType AND
                      InstUsage.Start = FilterQ.StartTime
            WHERE NOT Dataset_ID_Acq_Overlap IS NULL
        End

        If @infoOnly = 2
        Begin
            Select *
            From #Tmp_DatasetStartTimes
        End

        Set @entryID = -1
        Set @continue = 1

        While @continue = 1
        Begin -- <a>
            SELECT TOP 1 @entryID = ID,
                         @dmsInstrumentID = DMS_Inst_ID,
                         @itemType = ItemType,
                         @startTime = StartTime
            FROM #Tmp_DatasetStartTimes
            WHERE ID > @entryID And Datasets > 1
            ORDER BY ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @continue = 0
            Else
            Begin
                -- Find the best dataset ID to represent the group of datasets (or group of intervals) that start at @startTime
                -- Choose the dataset (or interval) with the longest runtime
                --   If ties, sort by dataset name

                -- If a dataset was deleted from DMS then re-uploaded under a new name,
                -- table T_EMSL_Instrument_Usage_Report may have two rows for the dataset
                -- Since this query uses an inner join, it will grab the Dataset_ID of the existing dataset

                Set @datasetID = Null
                Set @lastSeq = Null

                SELECT TOP 1 @datasetID = InstUsage.Dataset_ID,
                             @lastSeq = Seq
                FROM T_EMSL_Instrument_Usage_Report InstUsage
                     INNER JOIN T_Dataset DS
                       ON InstUsage.Dataset_ID = DS.Dataset_ID
                WHERE InstUsage.DMS_Inst_ID = @dmsInstrumentID AND
                      InstUsage.Start = @startTime AND
                      InstUsage.[Type] = @itemType
                ORDER BY InstUsage.Minutes DESC, DS.Dataset_Num ASC, Seq DESC
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    -- All of the entries in T_EMSL_Instrument_Usage_Report with this start time are missing from T_Dataset
                    -- Re-query, this time only using T_EMSL_Instrument_Usage_Report

                    SELECT TOP 1 @datasetID = Dataset_ID,
                                 @lastSeq = Seq
                    FROM T_EMSL_Instrument_Usage_Report
                    WHERE DMS_Inst_ID = @dmsInstrumentID AND
                          Start = @startTime AND
                          [Type] = @itemType
                    ORDER BY Minutes DESC, Dataset_ID DESC, Seq DESC
                End

                If @infoOnly = 0
                Begin
                    -- Store Null in Dataset_ID_Acq_Overlap for dataset ID @datasetID
                    -- Store @datasetID in Dataset_ID_Acq_Overlap for the other datasets that start at @startTime
                    -- @lastSeq is used to assure that only one entry has a null value for Dataset_ID_Acq_Overlap
                    --
                    UPDATE T_EMSL_Instrument_Usage_Report
                    SET Dataset_ID_Acq_Overlap = CASE WHEN Dataset_ID = @datasetID AND Seq = @lastSeq
                                                      THEN NULL
                                                      ELSE @datasetID
                                                 END

                    WHERE DMS_Inst_ID = @dmsInstrumentID AND
                          Start = @startTime AND
                          [Type] = @itemType
                End
                Else
                Begin
                    INSERT INTO #Tmp_UpdatesToApply( DMS_Inst_ID,
                                                     ItemType,
                                                     Start,
                                                     Dataset_ID,
                                                     Seq,
                                                     Dataset,
                                                     Dataset_ID_Acq_Overlap )
                    SELECT InstUsage.DMS_Inst_ID,
                           InstUsage.[Type],
                           InstUsage.Start,
                           InstUsage.Dataset_ID,
                           InstUsage.Seq,
                           DS.Dataset_Num,
                           CASE WHEN InstUsage.Dataset_ID = @datasetID AND InstUsage.Seq = @lastSeq
                                THEN NULL
                                ELSE @datasetID
                           END
                    FROM T_EMSL_Instrument_Usage_Report InstUsage
                         LEFT OUTER JOIN T_Dataset DS
                           ON InstUsage.Dataset_ID = DS.Dataset_ID
                    WHERE InstUsage.DMS_Inst_ID = @dmsInstrumentID AND
                          InstUsage.Start = @startTime AND
                          InstUsage.[Type] = @itemType
                    ORDER BY CASE WHEN InstUsage.Dataset_ID = @datasetID And Seq = @lastSeq THEN 1
                                  WHEN InstUsage.Dataset_ID = @datasetID THEN 2
                                  ELSE 3
                             END,
                             DS.Dataset_Num
                End
            End
        End -- </a>

        If @infoOnly > 0
        Begin
            If @infoOnly = 3
            Begin
                SELECT U.*
                FROM #Tmp_UpdatesToApply U
                ORDER BY ID
            End

            SELECT U.ID,
                   U.DMS_Inst_ID,
                   U.ItemType,
                   U.Start,
                   InstUsage.Minutes,
                   U.Dataset_ID,
                   U.Seq,
                   U.Dataset,
                   U.Dataset_ID_Acq_Overlap
            FROM #Tmp_UpdatesToApply U
                 INNER JOIN T_EMSL_Instrument_Usage_Report InstUsage
                   ON U.Dataset_ID = InstUsage.Dataset_ID AND
                      U.Start = InstUsage.Start AND
                      U.ItemType = InstUsage.[Type] AND
                      U.Seq = InstUsage.Seq
            ORDER BY ID
        End

    END TRY
    BEGIN CATCH

        EXEC FormatErrorMessage @message output, @myError output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'UpdateEMSLInstrumentAcqOverlapData'

    END CATCH

    RETURN @myError

GO
