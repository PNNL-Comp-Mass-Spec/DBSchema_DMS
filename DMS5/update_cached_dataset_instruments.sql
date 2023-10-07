/****** Object:  StoredProcedure [dbo].[update_cached_dataset_instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_dataset_instruments]
/****************************************************
**
**  Desc:   Updates T_Cached_Dataset_Instruments
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   04/15/2019 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @processingMode tinyint = 0,            -- 0 to only add new datasets; 1 to add new datasets and update existing information
    @datasetId Int = 0,                     -- When non-zero, a single dataset ID to add / update
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @processingMode = IsNull(@processingMode, 0)
    Set @datasetId = IsNull(@datasetId, 0)
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    If @datasetId > 0 And @infoOnly = 0
    Begin
        MERGE [dbo].[T_Cached_Dataset_Instruments] AS t
        USING (SELECT DS.Dataset_ID,
                      DS.DS_instrument_name_ID As Instrument_ID,
                      InstName.IN_name As Instrument
                FROM T_Dataset DS
                    INNER JOIN T_Instrument_Name InstName
                      ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                WHERE DS.Dataset_ID = @datasetId) as s
        ON ( t.[Dataset_ID] = s.[Dataset_ID])
        WHEN MATCHED AND (
            t.[Instrument_ID] <> s.[Instrument_ID] OR
            t.[Instrument] <> s.[Instrument]
            )
        THEN UPDATE SET
            [Instrument_ID] = s.[Instrument_ID],
            [Instrument] = s.[Instrument]
        WHEN NOT MATCHED BY TARGET THEN
            INSERT([Dataset_ID], [Instrument_ID], [Instrument])
            VALUES(s.[Dataset_ID], s.[Instrument_ID], s.[Instrument]);

        Goto Done
    End


    ------------------------------------------------
    -- Add new datasets to T_Cached_Dataset_Instruments
    ------------------------------------------------
    --
    If @processingMode = 0 Or @infoOnly > 0
    Begin

        If @infoOnly > 0
        Begin
            ------------------------------------------------
            -- Preview the addition of new datasets
            ------------------------------------------------

            SELECT DS.Dataset_ID,
                   DS.DS_instrument_name_ID,
                   InstName.IN_name,
                   'Dataset to add to T_Cached_Dataset_Instruments' As Status
            FROM T_Dataset DS
                 INNER JOIN T_Instrument_Name InstName
                   ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                 LEFT OUTER JOIN T_Cached_Dataset_Instruments CachedInst
                   ON DS.Dataset_ID = CachedInst.Dataset_ID
            WHERE CachedInst.Dataset_ID IS Null
            ORDER BY DS.Dataset_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Select 'No datasets need to be added to T_Cached_Dataset_Instruments' As Status
        End
        Else
        Begin
            ------------------------------------------------
            -- Add new datasets
            ------------------------------------------------

            INSERT INTO T_Cached_Dataset_Instruments( Dataset_ID,
                                                      Instrument_ID,
                                                      Instrument )
            SELECT DS.Dataset_ID,
                   DS.DS_instrument_name_ID,
                   InstName.IN_name
            FROM T_Dataset DS
                 INNER JOIN T_Instrument_Name InstName
                   ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                 LEFT OUTER JOIN T_Cached_Dataset_Instruments CachedInst
                   ON DS.Dataset_ID = CachedInst.Dataset_ID
            WHERE CachedInst.Dataset_ID IS NULL
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
                Set @message = 'Added ' + Convert(varchar(12), @myRowCount) + ' new ' + dbo.check_plural(@myRowCount, 'dataset', 'datasets')
        End

    End

    If @processingMode > 0
    Begin

        If @infoOnly > 0
        Begin
            ------------------------------------------------
            -- Preview the update of cached info
            ------------------------------------------------

            SELECT t.Dataset_ID,
                   t.Instrument_ID,
                   s.Instrument_ID AS InstID_New,
                   t.Instrument,
                   s.Instrument AS InstName_New,
                   'Dataset to update in T_Instrument_Name' As Status
            FROM T_Cached_Dataset_Instruments t
                 INNER JOIN ( SELECT DS.Dataset_ID,
                                     DS.DS_instrument_name_ID AS Instrument_ID,
                                     InstName.IN_name AS Instrument
                              FROM T_Dataset DS
                                   INNER JOIN T_Instrument_Name InstName
                                     ON DS.DS_instrument_name_ID = InstName.Instrument_ID ) s
                   ON t.Dataset_ID = s.Dataset_ID
            WHERE t.[Instrument_ID] <> s.[Instrument_ID] OR
                  t.[Instrument] <> s.[Instrument]
            ORDER BY t.Dataset_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                SELECT 'No data in T_Cached_Dataset_Instruments needs to be updated' As Status

        End
        Else
        Begin

            ------------------------------------------------
            -- Update cached info
            ------------------------------------------------

            MERGE [dbo].[T_Cached_Dataset_Instruments] AS t
            USING (SELECT DS.Dataset_ID,
                          DS.DS_instrument_name_ID As Instrument_ID,
                          InstName.IN_name As Instrument
                   FROM T_Dataset DS
                        INNER JOIN T_Instrument_Name InstName
                          ON DS.DS_instrument_name_ID = InstName.Instrument_ID) as s
            ON ( t.[Dataset_ID] = s.[Dataset_ID])
            WHEN MATCHED AND (
                t.[Instrument_ID] <> s.[Instrument_ID] OR
                t.[Instrument] <> s.[Instrument]
                )
            THEN UPDATE SET
                [Instrument_ID] = s.[Instrument_ID],
                [Instrument] = s.[Instrument]
            WHEN NOT MATCHED BY TARGET THEN
                INSERT([Dataset_ID], [Instrument_ID], [Instrument])
                VALUES(s.[Dataset_ID], s.[Instrument_ID], s.[Instrument])
            WHEN NOT MATCHED BY Source THEN DELETE;
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
                Set @message = dbo.append_to_text(@message,
                                                Convert(varchar(12), @myRowCount) + dbo.check_plural(@myRowCount, ' dataset was updated', ' datasets were updated') + ' via a merge',
                                                0, '; ', 512)
        End

    End

Done:
    -- Exec post_log_entry 'Debug', @message, 'update_cached_dataset_instruments'
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_cached_dataset_instruments] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_cached_dataset_instruments] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_cached_dataset_instruments] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_cached_dataset_instruments] TO [DMS2_SP_User] AS [dbo]
GO
