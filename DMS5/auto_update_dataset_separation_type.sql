/****** Object:  StoredProcedure [dbo].[AutoUpdateDatasetSeparationType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AutoUpdateDatasetSeparationType]
/****************************************************
**
**  Desc:   Possibly update the separation type for the specified datasets,
**          based on the current separation type name and acquisition length
**
**  Auth:   mem
**  Date:   10/09/2020
**
*****************************************************/
(
    @startDatasetId int,
    @endDatasetId int,
    @infoOnly tinyint = 1,              -- Set to 2 to view detailed messages
    @message varchar(512) = '' output
)
AS
    Set NoCount On

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    Set @startDatasetId = IsNull(@startDatasetId, 0)
    Set @endDatasetId = IsNull(@endDatasetId, 0)
    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @message = ''

    Declare @datasetId int = @startDatasetId - 1
    Declare @acqLengthMinutes int

    Declare @continue int
    Declare @sortID int

    Declare @datasetName varchar(128)
    Declare @separationType varchar(64)
    Declare @optimalSeparationType varchar(64)

    Declare @datasetsProcessed int
    Declare @updateCount int

    ---------------------------------------------------
    -- Create a temporary table to track update stats
    ---------------------------------------------------

    CREATE TABLE #TmpUpdateStats (
        SeparationType varchar(64),
        UpdatedSeparationType varchar(64),
        UpdateCount int,
        SortID int null
    )

    CREATE UNIQUE INDEX #IX_TmpUpdateStats ON #TmpUpdateStats (SeparationType, UpdatedSeparationType)

    ---------------------------------------------------
    -- Loop through the datasets
    ---------------------------------------------------
    --
    While @datasetId <= @endDatasetId
    Begin
        SELECT TOP 1
            @datasetId = Dataset_ID,
            @datasetName = Dataset_Num,
            @separationType = DS_sec_sep,
            @acqLengthMinutes = Acq_Length_Minutes
        FROM T_Dataset
        Where Dataset_ID > @datasetId
        ORDER BY Dataset_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @datasetId = @endDatasetId + 1
        End
        Else
        Begin
            If @infoOnly > 1
            Begin
                Print ''
                Print 'Processing separation type ' + @separationType + ', acq length ' + CAST(@acqLengthMinutes as VARCHAR(12)) + ' minutes, for dataset ' + @datasetName
            END

            EXEC AutoUpdateSeparationType @separationType, @acqLengthMinutes, @optimalSeparationType = @optimalSeparationType output

            IF @separationType <> @optimalSeparationType
            Begin
                If @infoOnly <> 0
                Begin
                    Print 'Would update separation type from ' + @separationType + ' to ' + @optimalSeparationType + ' for dataset ' + @datasetName
                End
                Else
                Begin
                    Update T_Dataset
                    Set DS_sec_sep = @optimalSeparationType
                    Where Dataset_ID = @datasetId
                End

                SELECT @updateCount = UpdateCount
                FROM #TmpUpdateStats
                WHERE SeparationType = @separationType AND
                      UpdatedSeparationType = @optimalSeparationType
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    INSERT INTO #TmpUpdateStats (SeparationType, UpdatedSeparationType, UpdateCount)
                    VALUES (@separationType, @optimalSeparationType, 1)
                End
                Else
                Begin
                    UPDATE #TmpUpdateStats
                    Set UpdateCount = @updateCount + 1
                    WHERE SeparationType = @separationType AND
                          UpdatedSeparationType = @optimalSeparationType
                End

            End

            Set @datasetsProcessed = @datasetsProcessed + 1
        End
    End

    Print 'Examined ' + CAST(@datasetsProcessed as VARCHAR(12)) + ' datasets'

    ---------------------------------------------------
    -- Populate the SortID column
    ---------------------------------------------------
    --
    UPDATE #TmpUpdateStats
    SET SortID = SortingQ.SortID
    FROM #TmpUpdateStats
         INNER JOIN ( SELECT SeparationType,
                             UpdatedSeparationType,
                             ROW_NUMBER() OVER ( ORDER BY SeparationType, UpdatedSeparationType ) AS
                               SortID
                      FROM #TmpUpdateStats ) SortingQ
           ON #TmpUpdateStats.SeparationType = SortingQ.SeparationType AND
              #TmpUpdateStats.UpdatedSeparationType = SortingQ.UpdatedSeparationType

    ---------------------------------------------------
    -- Show the update stats
    ---------------------------------------------------
    --
    SELECT SeparationType, UpdatedSeparationType, UpdateCount
    FROM #TmpUpdateStats
    ORDER BY SortID

    If @infoOnly = 0
    Begin
        ---------------------------------------------------
        -- Log the update stats
        ---------------------------------------------------
        --
        Set @separationType = ''
        Set @sortID = 0
        Set @continue = 1

        While @continue > 0
        Begin
            SELECT Top 1
                 @separationType = SeparationType,
                 @optimalSeparationType = UpdatedSeparationType,
                 @updateCount = UpdateCount,
                 @sortID = SortID
            FROM #TmpUpdateStats
            WHERE SortID > @sortID
            ORDER BY SortID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                Set @message = 'Changed separation type from ' + @separationType + ' to ' + @optimalSeparationType + ' for ' + CAST(@updateCount as varchar(12)) + ' dataset'

                If @updateCount > 1
                Begin
                    Set @message = @message + 's'
                End

                EXEC PostLogEntry 'Normal', @message, 'AutoUpdateDatasetSeparationType'
            End
        End
    End

    return 0

GO
