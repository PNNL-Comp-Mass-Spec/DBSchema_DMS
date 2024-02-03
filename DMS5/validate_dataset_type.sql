/****** Object:  StoredProcedure [dbo].[validate_dataset_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_dataset_type]
/****************************************************
**
**  Desc:   Validates the dataset type defined in T_Dataset for the given dataset
**          based on the contents of T_Dataset_ScanTypes
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/13/2010 mem - Initial version
**          05/14/2010 mem - Added support for the generic scan types MSn and HMSn
**          05/17/2010 mem - Updated @autoDefineOnAllMismatches to default to 1
**          08/30/2011 mem - Updated to prevent MS-HMSn from getting auto-defined
**          03/27/2012 mem - Added support for GC-MS
**          08/15/2012 mem - Added support for IMS-HMS-HMSn
**          10/08/2012 mem - No longer overriding dataset type MALDI-HMS
**          10/19/2012 mem - Improved support for IMS-HMS-HMSn
**          02/28/2013 mem - No longer overriding dataset type C60-SIMS-HMS
**          05/08/2014 mem - No longer updating the dataset comment with "Auto-switched dataset type from HMS-HMSn to HMS-HCD-HMSn"
**          01/13/2016 mem - Add support for ETciD and EThcD spectra
**          08/25/2016 mem - Do not change the dataset type from EI-HMS to HMS
**                         - Do not update the dataset comment when auto-changing an HMS dataset
**          04/28/2017 mem - Do not update the dataset comment when auto-changing an IMS dataset
**          06/12/2018 mem - Send @maxLength to append_to_text
**          06/03/2019 mem - Check for 'IMS' in ScanFilter
**          10/10/2020 mem - No longer update the comment when auto switching the dataset type
**          10/13/2020 mem - Add support for datasets that only have MS2 spectra (they will be assigned dataset type HMS or MS, despite the fact that they have no MS1 spectra; this is by design)
**          05/26/2021 mem - Add support for low res HCD
**          07/01/2021 mem - Auto-switch from HMS-CID-MSn to HMS-MSn
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/02/2023 mem - Use renamed table names
**          06/12/2023 mem - Sum actual scan counts, not simply 0 or 1
**          01/10/2024 mem - Add support for DIA datasets
**          01/30/2024 mem - Auto-switch from HMS-CID-HMSn to HMS-HMSn
**
*****************************************************/
(
    @datasetID int,
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0,
    @autoDefineOnAllMismatches tinyint = 1
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    Declare @dataset varchar(256)
    Declare @WarnMessage varchar(512)

    Declare @currentDatasetType varchar(64)
    Declare @datasetTypeAutoGen varchar(64)
    Declare @newDatasetType varchar(64)

    Declare @autoDefineDSType tinyint

    Declare @actualCountMS int
    Declare @actualCountHMS int
    Declare @actualCountGCMS int

    Declare @actualCountCIDMSn int
    Declare @actualCountCIDHMSn int
    Declare @actualCountETDMSn int
    Declare @actualCountETDHMSn int
    Declare @actualCountHCDMSn int
    Declare @actualCountHCDHMSn int

    Declare @actualCountETciDMSn int
    Declare @actualCountETciDHMSn int
    Declare @actualCountEThcDMSn int
    Declare @actualCountEThcDHMSn int

    Declare @actualCountAnyMSn int
    Declare @actualCountAnyHMSn int

    Declare @actualCountDIA int
    Declare @actualCountMRM int
    Declare @actualCountPQD int

    Declare @newDSTypeID int

    Declare @hasIMS Tinyint = 0

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    Set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @autoDefineOnAllMismatches = IsNull(@autoDefineOnAllMismatches, 0)

    -----------------------------------------------------------
    -- Lookup the dataset type for the given Dataset ID
    -----------------------------------------------------------

    Set @currentDatasetType = ''

    SELECT @dataset = Dataset_Num,
           @currentDatasetType = DST.DST_name
    FROM T_Dataset DS
         LEFT OUTER JOIN T_Dataset_Type_Name DST
           ON DS.DS_type_ID = DST.DST_Type_ID
    WHERE DS.Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Dataset ID not found in T_Dataset: ' + Convert(varchar(12), @datasetID)
        Set @myError = 50000
        Goto Done
    End

    IF Not Exists (SELECT * FROM T_Dataset_ScanTypes WHERE Dataset_ID = @datasetID)
    Begin
        Set @message = 'Warning: Scan type info not found in T_Dataset_ScanTypes for dataset ' + @dataset
        Set @myError = 0
        Goto Done
    End

    -- Use the following to summarize the various ScanType values in T_Dataset_ScanTypes
    -- SELECT ScanType, COUNT(*) AS ScanTypeCount
    -- FROM T_Dataset_ScanTypes
    -- GROUP BY ScanType

    -----------------------------------------------------------
    -- Summarize the scan type information in T_Dataset_ScanTypes
    -----------------------------------------------------------

    SELECT
           @actualCountMS      = SUM(CASE WHEN ScanType = 'MS'    Then ScanCount Else 0 End),
           @actualCountHMS     = SUM(CASE WHEN ScanType = 'HMS'   Then ScanCount Else 0 End),
           @actualCountGCMS    = SUM(CASE WHEN ScanType = 'GC-MS' Then ScanCount Else 0 End),

           @actualCountAnyMSn  = SUM(CASE WHEN ScanType LIKE '%-MSn'    OR ScanType = 'MSn'   Then ScanCount Else 0 End),
           @actualCountAnyHMSn = SUM(CASE WHEN ScanType LIKE '%-HMSn'   OR ScanType = 'HMSn'  Then ScanCount Else 0 End),

           @actualCountCIDMSn  = SUM(CASE WHEN ScanType LIKE '%CID-MSn'  OR ScanType = 'MSn'  Then ScanCount Else 0 End),
           @actualCountCIDHMSn = SUM(CASE WHEN ScanType LIKE '%CID-HMSn' OR ScanType = 'HMSn' Then ScanCount Else 0 End),

           @actualCountETDMSn  = SUM(CASE WHEN ScanType LIKE '%ETD-MSn'  Then ScanCount Else 0 End),
           @actualCountETDHMSn = SUM(CASE WHEN ScanType LIKE '%ETD-HMSn' Then ScanCount Else 0 End),

           @actualCountHCDMSn  = SUM(CASE WHEN ScanType LIKE '%HCD-MSn'  Then ScanCount Else 0 End),
           @actualCountHCDHMSn = SUM(CASE WHEN ScanType LIKE '%HCD-HMSn' Then ScanCount Else 0 End),

           @actualCountETciDMSn  = SUM(CASE WHEN ScanType LIKE '%ETciD-MSn'  Then ScanCount Else 0 End),
           @actualCountETciDHMSn = SUM(CASE WHEN ScanType LIKE '%ETciD-HMSn' Then ScanCount Else 0 End),
           @actualCountEThcDMSn  = SUM(CASE WHEN ScanType LIKE '%EThcD-MSn'  Then ScanCount Else 0 End),
           @actualCountEThcDHMSn = SUM(CASE WHEN ScanType LIKE '%EThcD-HMSn' Then ScanCount Else 0 End),

           @actualCountDIA = SUM(CASE WHEN ScanType LIKE 'DIA%' Then ScanCount Else 0 End),
           @actualCountMRM = SUM(CASE WHEN ScanType LIKE '%SRM' OR ScanType LIKE '%MRM' OR ScanType LIKE 'Q[1-3]MS' Then ScanCount Else 0 End),
           @actualCountPQD = SUM(CASE WHEN ScanType LIKE '%PQD%' Then ScanCount Else 0 End)

    FROM T_Dataset_ScanTypes
    WHERE Dataset_ID = @datasetID
    GROUP BY Dataset_ID

    If @infoOnly <> 0
    Begin
       SELECT @actualCountMS AS ActualCountMS,
              @actualCountHMS AS ActualCountHMS,
              @actualCountGCMS AS ActualCountGCMS,
              @actualCountAnyMSn As ActualCountAnyMSn,
              @actualCountAnyHMSn As ActualCountAnyHMSn,
              @actualCountCIDMSn AS ActualCountCIDMSn,
              @actualCountCIDHMSn AS ActualCountCIDHMSn,
              @actualCountETDMSn AS ActualCountETDMSn,
              @actualCountETDHMSn AS ActualCountETDHMSn,
              @actualCountHCDMSn AS ActualCountHCDMSn,
              @actualCountHCDHMSn AS ActualCountHCDHMSn,
              @actualCountETciDMSn AS ActualCountETciDMSn,
              @actualCountETciDHMSn AS ActualCountETciDHMSn,
              @actualCountEThcDMSn AS ActualCountEThcDMSn,
              @actualCountEThcDHMSn AS ActualCountEThcDHMSn,
              @actualCountMRM AS ActualCountMRM,
              @actualCountPQD AS ActualCountPQD,
              @actualCountDIA AS ActualCountDIA

    End

    -----------------------------------------------------------
    -- Compare the actual scan type counts to the current dataset type
    -----------------------------------------------------------

    Set @datasetTypeAutoGen = ''
    Set @newDatasetType = ''
    Set @autoDefineDSType = 0
    Set @WarnMessage = ''

    If @actualCountMRM > 0
    Begin
        -- Auto switch to MRM if not MRM or SRM

        If Not (@currentDatasetType LIKE '%SRM' OR
                @currentDatasetType LIKE '%MRM' OR
                @currentDatasetType LIKE '%SIM')
        Begin
            Set @newDatasetType = 'MRM'
        End

        Goto FixDSType
    End

    If Exists (SELECT * FROM T_Dataset_ScanTypes WHERE Dataset_ID = @datasetID And ScanFilter = 'IMS')
    Begin
        Set @hasIMS = 1
    End

    If @hasIMS > 0 And @currentDatasetType Like 'HMS%'
    Begin
        Set @newDatasetType = 'IMS-' + @currentDatasetType
        Goto FixDSType
    End

    If @hasIMS = 0 And @currentDatasetType Like 'IMS-%MS%'
    Begin
        Set @newDatasetType = Substring(@currentDatasetType, 5, 100)
        Goto FixDSType
    End

    If @actualCountHMS > 0 AND Not (@currentDatasetType LIKE 'HMS%' OR @currentDatasetType LIKE '%-HMS' OR @currentDatasetType LIKE 'IMS-HMS%')
    Begin
        -- Dataset contains HMS spectra, but the current dataset type doesn't reflect that this is an HMS dataset

        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @infoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountHMS > 0 AND Not (@currentDatasetType LIKE ''HMS%'' Or @currentDatasetType LIKE ''%-HMS'')'
        End
        Else
            Set @newDatasetType = ' an HMS-based dataset type'

        Goto AutoDefineDSType
    End


    If (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountHCDHMSn + @actualCountETciDHMSn + @actualCountEThcDHMSn) > 0 AND Not @currentDatasetType LIKE '%-HMSn%'
    Begin
        -- Dataset contains CID, ETD, or HCD HMSn spectra, but the current dataset type doesn't reflect that this is an HMSn dataset

        If @currentDatasetType IN ('IMS-HMS', 'IMS-HMS-MSn')
        Begin
            Set @newDatasetType = 'IMS-HMS-HMSn'
        End
        Else
        Begin
            If Not @currentDatasetType LIKE 'IMS%'
            Begin
                Set @autoDefineDSType = 1
                If @infoOnly = 1
                    Print 'Set @autoDefineDSType=1 because (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountHCDHMSn + @actualCountETciDHMSn + @actualCountEThcDHMSn) > 0 AND Not @currentDatasetType LIKE ''%-HMSn%'''

            End
            Else
                Set @newDatasetType = ' an HMS-based dataset type'
        End

        Goto AutoDefineDSType
    End

    If (@actualCountCIDMSn + @actualCountETDMSn + @actualCountHCDMSn + @actualCountETciDMSn + @actualCountEThcDMSn) > 0 AND Not @currentDatasetType LIKE '%-MSn%'
    Begin
        -- Dataset contains CID or ETD MSn spectra, but the current dataset type doesn't reflect that this is an MSn dataset
        If @currentDatasetType = 'IMS-HMS'
        Begin
            Set @newDatasetType = 'IMS-HMS-MSn'
        End
        Else
        Begin
            If Not @currentDatasetType LIKE 'IMS%'
            Begin
                Set @autoDefineDSType = 1
                If @infoOnly = 1
                    Print 'Set @autoDefineDSType=1 because (@actualCountCIDMSn + @actualCountETDMSn + @actualCountHCDMSn + @actualCountETciDMSn + @actualCountEThcDMSn) > 0 AND Not @currentDatasetType LIKE ''%-MSn%'''

            End
            Else
                Set @newDatasetType = ' an MSn-based dataset type'
        End

        Goto AutoDefineDSType
    End

    If (@actualCountETDMSn + @actualCountETDHMSn) > 0 AND Not @currentDatasetType LIKE '%ETD%'
    Begin
        -- Dataset has ETD scans, but current dataset type doesn't reflect this
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @infoOnly = 1
                Print 'Set @autoDefineDSType=1 because (@actualCountETDMSn + @actualCountETDHMSn) > 0 AND Not @currentDatasetType LIKE ''%ETD%'''
        End
        Else
            Set @newDatasetType = ' an ETD-based dataset type'

        Goto AutoDefineDSType
    End

    If @actualCountHCDMSn + @actualCountHCDHMSn > 0 AND Not @currentDatasetType LIKE '%HCD%'
    Begin
        -- Dataset has HCD scans, but current dataset type doesn't reflect this
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @infoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountHCDMSn + @actualCountHCDHMSn > 0 AND Not @currentDatasetType LIKE ''%HCD%'''
        End
        Else
            Set @newDatasetType = ' an HCD-based dataset type'

        Goto AutoDefineDSType
    End

    If @actualCountPQD > 0 AND Not @currentDatasetType LIKE '%PQD%'
    Begin
        -- Dataset has PQD scans, but current dataset type doesn't reflect this
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @infoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountPQD > 0 AND Not @currentDatasetType LIKE ''%PQD%'''
        End
        Else
            Set @newDatasetType = ' a PQD-based dataset type'

        Goto AutoDefineDSType
    End


    If @actualCountHCDMSn + @actualCountHCDHMSn = 0 AND @currentDatasetType LIKE '%HCD%'
    Begin
        -- Dataset does not have HCD scans, but current dataset type says it does
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @infoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountHCDMSn + @actualCountHCDHMSn = 0 AND @currentDatasetType LIKE ''%HCD%'''
        End
        Else
        Begin
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no HCD scans are present'
        End

        Goto AutoDefineDSType
    End

    If (@actualCountETDMSn + @actualCountETDHMSn) = 0 AND @currentDatasetType LIKE '%ETD%'
    Begin
        -- Dataset does not have ETD scans, but current dataset type says it does
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @infoOnly = 1
                Print 'Set @autoDefineDSType=1 because (@actualCountETDMSn + @actualCountETDHMSn) = 0 AND @currentDatasetType LIKE ''%ETD%'''
        End
        Else
        Begin
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no ETD scans are present'
        End

        Goto AutoDefineDSType
    End

    If @actualCountAnyMSn > 0 AND Not @currentDatasetType LIKE '%-MSn%'
    Begin
        -- Dataset contains MSn spectra, but the current dataset type doesn't reflect that this is an MSn dataset
        If @currentDatasetType = 'IMS-HMS'
        Begin
            Set @newDatasetType = 'IMS-HMS-MSn'
        End
        Else
        Begin
            If Not @currentDatasetType LIKE 'IMS%'
            Begin
                Set @autoDefineDSType = 1
                If @infoOnly = 1
                    Print 'Set @autoDefineDSType=1 because @actualCountAnyMSn > 0 AND Not @currentDatasetType LIKE ''%-MSn%'''
            End
            Else
                Set @newDatasetType = ' an MSn-based dataset type'
        End

        Goto AutoDefineDSType
    End

    If (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountHCDHMSn + @actualCountETciDHMSn + @actualCountEThcDHMSn) = 0 AND @currentDatasetType LIKE '%-HMSn%'
    Begin
        -- Dataset does not have HMSn scans, but current dataset type says it does
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @infoOnly = 1
                Print 'Set @autoDefineDSType=1 because (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountHCDHMSn + @actualCountETciDHMSn + @actualCountEThcDHMSn) = 0 AND @currentDatasetType LIKE ''%-HMSn%'''
        End
        Else
        Begin
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no high res MSn scans are present'
        End

        Goto AutoDefineDSType
    End

    If (@actualCountCIDMSn + @actualCountETDMSn + @actualCountHCDMSn + @actualCountETciDMSn + @actualCountEThcDMSn) = 0 AND @currentDatasetType LIKE '%-MSn%'
    Begin
        -- Dataset does not have MSn scans, but current dataset type says it does
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @infoOnly = 1
                Print 'Set @autoDefineDSType=1 because (@actualCountCIDMSn + @actualCountETDMSn + @actualCountHCDMSn + @actualCountETciDMSn + @actualCountEThcDMSn) = 0 AND @currentDatasetType LIKE ''%-MSn%'''
        End
        Else
        Begin
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no low res MSn scans are present'
        End

        Goto AutoDefineDSType
    End

    If @actualCountHMS = 0 AND (@currentDatasetType LIKE 'HMS%' Or @currentDatasetType LIKE '%-HMS')
    Begin
        -- Dataset does not have HMS scans, but current dataset type says it does
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @infoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountHMS = 0 AND (@currentDatasetType LIKE ''HMS%'' Or @currentDatasetType LIKE ''%-HMS'')'
        End
        Else
        Begin
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no HMS scans are present'
        End

        Goto AutoDefineDSType
    End

    If @actualCountAnyHMSn > 0 AND Not @currentDatasetType LIKE '%-HMSn%'
    Begin
        -- Dataset contains HMSn spectra, but the current dataset type doesn't reflect that this is an HMSn dataset
        If @currentDatasetType = 'IMS-HMS'
        Begin
            Set @newDatasetType = 'IMS-HMS-HMSn'
        End
        Else
        Begin
            If Not @currentDatasetType LIKE 'IMS%'
            Begin
                Set @autoDefineDSType = 1
                If @infoOnly = 1
                    Print 'Set @autoDefineDSType=1 because @actualCountAnyHMSn > 0 AND Not @currentDatasetType LIKE ''%-HMSn%'''
            End
            Else
                Set @newDatasetType = ' an HMSn-based dataset type'
        End

        Goto AutoDefineDSType
    End

    -----------------------------------------------------------
    -- Possibly auto-generate the dataset type
    -- If @autoDefineDSType is non-zero then will update the dataset type to this value
    -- Otherwise, will compare to the actual dataset type and post a warning if they differ
    -----------------------------------------------------------

AutoDefineDSType:

    If Not @currentDatasetType LIKE 'IMS%' AND NOT @currentDatasetType IN ('MALDI-HMS', 'C60-SIMS-HMS')
    Begin
        -- Auto-define the dataset type based on the scan type counts
        -- The auto-defined types will be one of the following:
            -- MS
            -- HMS
            -- MS-MSn
            -- HMS-MSn
            -- HMS-HMSn
            -- GC-MS
        -- In addition, if HCD scans are present, -HCD will be in the middle
        -- Furthermore, if ETD scans are present, -ETD or -CID/ETD will be in the middle
        -- If ETciD or EThcD scans are present, -ETciD or -EThcD will be in the middle
        -- Finally, if DIA scans are present, the dataset type will start with DIA-

        If @actualCountHMS > 0
            Set @datasetTypeAutoGen = 'HMS'
        Else
        Begin
            Set @datasetTypeAutoGen = 'MS'

            If @actualCountMS = 0 And (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountHCDHMSn + @actualCountETciDHMSn + @actualCountEThcDHMSn + @actualCountAnyHMSn) > 0
            Begin
                -- Dataset only has fragmentation spectra and no MS1 spectra
                -- Since all of the fragmentation spectra are high res, use 'HMS'
                Set @datasetTypeAutoGen = 'HMS'
            End

            If @actualCountGCMS > 0
            Begin
                Set @datasetTypeAutoGen = 'GC-MS'
            End
        End

        If (@actualCountETciDMSn + @actualCountEThcDMSn + @actualCountETciDHMSn + @actualCountEThcDHMSn) > 0
        Begin
            -- Has ETciD or EThcD spectra

            If (@actualCountETciDMSn + @actualCountETciDHMSn) > 0 AND (@actualCountEThcDMSn + @actualCountEThcDHMSn) > 0
            Begin
                Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-ETciD-EThcD'
            End
            Else
            Begin

                If (@actualCountETciDMSn + @actualCountETciDHMSn) > 0
                Begin
                    Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-ETciD'
                End

                If (@actualCountEThcDMSn + @actualCountEThcDHMSn) > 0
                Begin
                    Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-EThcD'
                End

            End

            If (@actualCountETciDHMSn + @actualCountEThcDHMSn) > 0
                Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-HMSn'
            Else
                Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-MSn'

        End
        Else
        Begin
            -- No ETciD or EThcD spectra

            If @actualCountHCDMSn + @actualCountHCDHMSn > 0
                Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-HCD'

            IF @actualCountPQD > 0
                Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-PQD'

            If (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountHCDHMSn) > 0
            Begin
                -- One or more High res CID, ETD, or HCD MSn spectra
                If (@actualCountETDMSn + @actualCountETDHMSn) > 0
                Begin
                    -- One or more ETD spectra
                    If @actualCountCIDHMSn > 0
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-CID/ETD-HMSn'
                    Else If @actualCountCIDMSn > 0
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-CID/ETD-MSn'
                    Else If @actualCountETDHMSn > 0
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-ETD-HMSn'
                    Else
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-ETD-MSn'
                End
                Else
                Begin
                    -- No ETD spectra
                    If @actualCountCIDHMSn > 0
                         Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-CID-HMSn'
                    Else If @actualCountCIDMSn > 0 OR @actualCountPQD > 0
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-CID-MSn'
                    Else
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-HMSn'
                End
            End
            Else
            Begin
                -- No high res MSn spectra

                If (@actualCountCIDMSn + @actualCountETDMSn + @actualCountHCDMSn) > 0
                Begin
                    -- One or more Low res CID, ETD, or HCD MSn spectra
                    If (@actualCountETDMSn) > 0
                    Begin
                        -- One or more ETD spectra
                        If @actualCountCIDMSn > 0
                            Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-CID/ETD'
                        Else
                            Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-ETD'
                    End
                    Else
                    Begin
                        -- No ETD spectra
                        If @actualCountCIDMSn > 0 OR @actualCountPQD > 0
                            Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-CID'
                        Else
                            Set @datasetTypeAutoGen = @datasetTypeAutoGen
                    End

                    Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-MSn'
                End

            End

            -- Possibly auto-fix the auto-generated dataset type
            If @datasetTypeAutoGen = 'HMS-HCD'
            Begin
                If @actualCountHCDMSn > 0 And @actualCountHCDHMSn = 0
                    Set @datasetTypeAutoGen = 'HMS-HCD-MSn'
                Else
                    Set @datasetTypeAutoGen = 'HMS-HCD-HMSn'
            End

            If @datasetTypeAutoGen = 'HMS-CID-MSn'
            Begin
                Set @datasetTypeAutoGen = 'HMS-MSn'
            End

            If @datasetTypeAutoGen = 'HMS-CID-HMSn'
            Begin
                Set @datasetTypeAutoGen = 'HMS-HMSn'
            End

            If @actualCountDIA > 0
            Begin
                Set @datasetTypeAutoGen = 'DIA-' + @datasetTypeAutoGen
            End
        End
    End

    If @datasetTypeAutoGen <> '' AND @autoDefineOnAllMismatches <> 0
    Begin
        Set @autoDefineDSType = 1
        If @infoOnly = 1
            Print 'Set @autoDefineDSType=1 because @datasetTypeAutoGen <> '''' (it is ' + @datasetTypeAutoGen + ') AND @autoDefineOnAllMismatches <> 0'
    End

    If @autoDefineDSType <> 0
    Begin
        If @datasetTypeAutoGen <> @currentDatasetType And @datasetTypeAutoGen <> ''
            Set @newDatasetType = @datasetTypeAutoGen
    End
    Else
    Begin
        If @newDatasetType = '' And @WarnMessage = ''
        Begin
            If @datasetTypeAutoGen <> @currentDatasetType And @datasetTypeAutoGen <> ''
            Begin
                Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' while auto-generated type is ' + @datasetTypeAutoGen
            End
        End
    End

FixDSType:

    -----------------------------------------------------------
    -- If a warning message was defined, display it
    -----------------------------------------------------------
    --
    If @WarnMessage <> '' And Not (@currentDatasetType Like 'IMS%' and @datasetTypeAutoGen Like 'IMS%')
    Begin
        Set @message = @WarnMessage
        Goto Done
    End

    -----------------------------------------------------------
    -- If a new dataset is defined, update the dataset type
    -----------------------------------------------------------
    --
    If @newDatasetType <> ''
    Begin
        Set @newDSTypeID = 0

        SELECT @newDSTypeID = DST_Type_ID
        FROM T_Dataset_Type_Name
        WHERE DST_name = @newDatasetType
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @newDSTypeID <> 0
        Begin

            If @newDatasetType = 'HMS' And @currentDatasetType = 'EI-HMS'
            Begin
                -- Leave the dataset type as 'EI-HMS'
                If @infoOnly <> 0
                Begin
                    Select 'Leaving dataset type unchanged as ' + @currentDatasetType AS Comment
                End
                Goto Done
            End

            Set @message = 'Auto-switched dataset type from ' + @currentDatasetType + ' to ' + @newDatasetType

            If @infoOnly = 0
            Begin
                UPDATE T_Dataset
                SET DS_Type_ID = @newDSTypeID
                WHERE Dataset_ID = @datasetID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            Else
            Begin
                SELECT @newDatasetType AS NewDatasetType,
                       @newDSTypeID AS NewDSTypeID
            End
        End
        Else
        Begin
            Set @message = 'Unrecognized dataset type based on actual scan types; need to auto-switch from ' + @currentDatasetType + ' to ' + @newDatasetType

            If @infoOnly = 0
            Begin
                Declare @logMessage varchar(1024)
                Set @logMessage = @message + ' for dataset ID ' + Cast(@datasetID as varchar(12)) + ' (' + @dataset + ')'

                Exec post_log_entry 'Error', @logMessage, 'validate_dataset_type'
            End
        End
    End

Done:
    If @infoOnly <> 0
    Begin
        If Len(@message) = 0
        Begin
            Set @message = 'Dataset type is valid: ' + @currentDatasetType
        End

        Print @message + ' (' + @dataset + ')'
        SELECT @message as Message, @dataset As Dataset
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[validate_dataset_type] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[validate_dataset_type] TO [Limited_Table_Write] AS [dbo]
GO
