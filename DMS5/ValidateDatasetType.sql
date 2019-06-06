/****** Object:  StoredProcedure [dbo].[ValidateDatasetType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateDatasetType]
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
**          06/12/2018 mem - Send @maxLength to AppendToText
**          06/03/2019 mem - Check for 'IMS' in ScanFilter
**    
*****************************************************/
(
    @datasetID int,
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0,
    @autoDefineOnAllMismatches tinyint = 1
)
As
    set nocount on
    
    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    Declare @dataset varchar(256)    
    Declare @datasetComment varchar(512)
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

    Declare @actualCountETciDMSn int
    Declare @actualCountETciDHMSn int
    Declare @actualCountEThcDMSn int
    Declare @actualCountEThcDHMSn int

    Declare @actualCountMRM int
    Declare @actualCountHCD int
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
           @datasetComment = IsNull(DS.DS_comment, ''),
           -- @datasetTypeIDCurrent = DS.DS_type_ID, 
           @currentDatasetType = DST.DST_name
    FROM T_Dataset DS
         LEFT OUTER JOIN T_DatasetTypeName DST
           ON DS.DS_type_ID = DST.DST_Type_ID
    WHERE (DS.Dataset_ID = @datasetID)
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
           @actualCountMS = SUM(CASE WHEN ScanType = 'MS'  Then 1 Else 0 End),
           @actualCountHMS  = SUM(CASE WHEN ScanType = 'HMS' Then 1 Else 0 End),
           @actualCountGCMS   = SUM(CASE WHEN ScanType = 'GC-MS'  Then 1 Else 0 End),
    
           @actualCountCIDMSn  = SUM(CASE WHEN ScanType LIKE '%CID-MSn'  OR ScanType = 'MSn'  Then 1 Else 0 End),
           @actualCountCIDHMSn = SUM(CASE WHEN ScanType LIKE '%CID-HMSn' OR ScanType = 'HMSn' Then 1 Else 0 End),

           @actualCountETDMSn  = SUM(CASE WHEN ScanType LIKE '%ETD-MSn'  Then 1 Else 0 End),
           @actualCountETDHMSn = SUM(CASE WHEN ScanType LIKE '%ETD-HMSn' Then 1 Else 0 End),

           @actualCountETciDMSn  = SUM(CASE WHEN ScanType LIKE '%ETciD-MSn'  Then 1 Else 0 End),
           @actualCountETciDHMSn = SUM(CASE WHEN ScanType LIKE '%ETciD-HMSn' Then 1 Else 0 End),
           @actualCountEThcDMSn  = SUM(CASE WHEN ScanType LIKE '%EThcD-MSn'  Then 1 Else 0 End),
           @actualCountEThcDHMSn = SUM(CASE WHEN ScanType LIKE '%EThcD-HMSn' Then 1 Else 0 End),
            
           @actualCountMRM = SUM(CASE WHEN ScanType LIKE '%SRM' or ScanType LIKE '%MRM' OR ScanType LIKE 'Q[1-3]MS' Then 1 Else 0 End),
           @actualCountHCD = SUM(CASE WHEN ScanType LIKE '%HCD%' Then 1 Else 0 End),
           @actualCountPQD = SUM(CASE WHEN ScanType LIKE '%PQD%' Then 1 Else 0 End)
           
    FROM T_Dataset_ScanTypes
    WHERE Dataset_ID = @datasetID
    GROUP BY Dataset_ID
    
    If @InfoOnly <> 0
    Begin
           SELECT @actualCountMS AS ActualCountMS,
                  @actualCountHMS AS ActualCountHMS,
                  @actualCountGCMS AS ActualCountGCMS,
                  @actualCountCIDMSn AS ActualCountCIDMSn,
                  @actualCountCIDHMSn AS ActualCountCIDHMSn,
                  @actualCountETDMSn AS ActualCountETDMSn,
                  @actualCountETDHMSn AS ActualCountETDHMSn,
                  @actualCountETciDMSn AS ActualCountETciDMSn,
                  @actualCountETciDHMSn AS ActualCountETciDHMSn,
                  @actualCountEThcDMSn AS ActualCountEThcDMSn,
                  @actualCountEThcDHMSn AS ActualCountEThcDHMSn,
                  @actualCountMRM AS ActualCountMRM,
                  @actualCountHCD AS ActualCountHCD,
                  @actualCountPQD AS ActualCountPQD

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
    
    If Exists (Select * FROM T_Dataset_ScanTypes WHERE Dataset_ID = @datasetID And ScanFilter = 'IMS')
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
            If @InfoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountHMS > 0 AND Not (@currentDatasetType LIKE ''HMS%'' Or @currentDatasetType LIKE ''%-HMS'')'
        End
        Else
            Set @newDatasetType = ' an HMS-based dataset type'    

        Goto AutoDefineDSType
    End
    

    If (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountETciDHMSn + @actualCountEThcDHMSn) > 0 AND Not @currentDatasetType LIKE '%-HMSn%'
    Begin
        -- Dataset contains CID or ETD HMSn spectra, but the current dataset type doesn't reflect that this is an HMSn dataset

        If @currentDatasetType IN ('IMS-HMS', 'IMS-HMS-MSn')
        Begin
            Set @newDatasetType = 'IMS-HMS-HMSn'
        End
        Else
        Begin
            If Not @currentDatasetType LIKE 'IMS%'
            Begin
                Set @autoDefineDSType = 1
                If @InfoOnly = 1
                    Print 'Set @autoDefineDSType=1 because (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountETciDHMSn + @actualCountEThcDHMSn) > 0 AND Not @currentDatasetType LIKE ''%-HMSn%'''

            End
            Else
                Set @newDatasetType = ' an HMS-based dataset type'    
        End
        
        Goto AutoDefineDSType
    End

    If (@actualCountCIDMSn + @actualCountETDMSn + @actualCountETciDMSn + @actualCountEThcDMSn) > 0 AND Not @currentDatasetType LIKE '%-MSn%'
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
                If @InfoOnly = 1
                    Print 'Set @autoDefineDSType=1 because (@actualCountCIDMSn + @actualCountETDMSn + @actualCountETciDMSn + @actualCountEThcDMSn) > 0 AND Not @currentDatasetType LIKE ''%-MSn%'''

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
            If @InfoOnly = 1
                Print 'Set @autoDefineDSType=1 because (@actualCountETDMSn + @actualCountETDHMSn) > 0 AND Not @currentDatasetType LIKE ''%ETD%'''
        End
        Else
            Set @newDatasetType = ' an ETD-based dataset type'    

        Goto AutoDefineDSType
    End

    If @actualCountHCD > 0 AND Not @currentDatasetType LIKE '%HCD%'
    Begin
        -- Dataset has HCD scans, but current dataset type doesn't reflect this
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @InfoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountHCD > 0 AND Not @currentDatasetType LIKE ''%HCD%'''
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
            If @InfoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountPQD > 0 AND Not @currentDatasetType LIKE ''%PQD%'''
        End
        Else
            Set @newDatasetType = ' a PQD-based dataset type'
        
        Goto AutoDefineDSType
    End


    If @actualCountHCD = 0 AND @currentDatasetType LIKE '%HCD%'
    Begin
        -- Dataset does not have HCD scans, but current dataset type says it does
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @InfoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountHCD = 0 AND @currentDatasetType LIKE ''%HCD%'''
        End
        Else
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no HCD scans are present'
        
        Goto AutoDefineDSType
    End

    If (@actualCountETDMSn + @actualCountETDHMSn) = 0 AND @currentDatasetType LIKE '%ETD%'
    Begin
        -- Dataset does not have ETD scans, but current dataset type says it does
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @InfoOnly = 1
                Print 'Set @autoDefineDSType=1 because (@actualCountETDMSn + @actualCountETDHMSn) = 0 AND @currentDatasetType LIKE ''%ETD%'''
        End
        Else
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no ETD scans are present'
        
        Goto AutoDefineDSType
    End
        
    If (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountHCD + @actualCountETciDHMSn + @actualCountEThcDHMSn) = 0 AND @currentDatasetType LIKE '%-HMSn%'
    Begin
        -- Dataset does not have HMSn scans, but current dataset type says it does
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @InfoOnly = 1
                Print 'Set @autoDefineDSType=1 because (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountHCD + @actualCountETciDHMSn + @actualCountEThcDHMSn) = 0 AND @currentDatasetType LIKE ''%-HMSn%'''
        End
        Else
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no high res MSn scans are present'
        
        Goto AutoDefineDSType
    End

    If (@actualCountCIDMSn + @actualCountETDMSn + @actualCountETciDMSn + @actualCountEThcDMSn) = 0 AND @currentDatasetType LIKE '%-MSn%'
    Begin
        -- Dataset does not have MSn scans, but current dataset type says it does
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @InfoOnly = 1
                Print 'Set @autoDefineDSType=1 because (@actualCountCIDMSn + @actualCountETDMSn + @actualCountETciDMSn + @actualCountEThcDMSn) = 0 AND @currentDatasetType LIKE ''%-MSn%'''
        End
        Else
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no low res MSn scans are present'
        
        Goto AutoDefineDSType
    End

    If @actualCountHMS = 0 AND (@currentDatasetType LIKE 'HMS%' Or @currentDatasetType LIKE '%-HMS')
    Begin
        -- Dataset does not have HMS scans, but current dataset type says it does        
        If Not @currentDatasetType LIKE 'IMS%'
        Begin
            Set @autoDefineDSType = 1
            If @InfoOnly = 1
                Print 'Set @autoDefineDSType=1 because @actualCountHMS = 0 AND (@currentDatasetType LIKE ''HMS%'' Or @currentDatasetType LIKE ''%-HMS'')'
        End
        Else
            Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' but no HMS scans are present'
        
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
        -- And finally, if ETciD or EThcD scans are present, -ETciD or -EThcD will be in the middle
        
        If @actualCountHMS > 0
            Set @datasetTypeAutoGen = 'HMS'
        Else
        Begin
            Set @datasetTypeAutoGen = 'MS'
            
            If @actualCountMS = 0 And (@actualCountCIDHMSn + @actualCountETDHMSn + @actualCountHCD + @actualCountETciDHMSn + @actualCountEThcDHMSn) > 0
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
            
            If @actualCountHCD > 0
                Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-HCD'

            IF @actualCountPQD > 0
                Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-PQD'
            
            If (@actualCountCIDHMSn + @actualCountETDHMSn) > 0
            Begin
                -- One or more High res CID or ETD MSn spectra
                If (@actualCountETDMSn + @actualCountETDHMSn) > 0
                Begin
                    -- One or more ETD spectra
                    If (@actualCountCIDMSn + @actualCountCIDHMSn) > 0
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-CID/ETD'
                    Else
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-ETD'        
                End
                Else
                Begin
                    -- No ETD spectra
                    If @actualCountHCD > 0 OR @actualCountPQD > 0
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-CID'
                    Else
                        Set @datasetTypeAutoGen = @datasetTypeAutoGen
                End
            
                Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-HMSn'
            End
            Else
            Begin
                -- No high res MSn spectra
                
                If (@actualCountCIDMSn + @actualCountETDMSn) > 0
                Begin
                    -- One or more Low res CID or ETD MSn spectra
                    If (@actualCountETDMSn + @actualCountETDHMSn) > 0
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
                        If @actualCountHCD > 0 OR @actualCountPQD > 0
                            Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-CID'
                        Else
                            Set @datasetTypeAutoGen = @datasetTypeAutoGen
                    End

                    Set @datasetTypeAutoGen = @datasetTypeAutoGen + '-MSn'
                End
            
            End
                    
            -- Possibly auto-fix the auto-generated dataset type
            If @datasetTypeAutoGen = 'HMS-HCD'
                Set @datasetTypeAutoGen = 'HMS-HCD-HMSn'
        End
    End

    If @datasetTypeAutoGen <> '' AND @autoDefineOnAllMismatches <> 0
    Begin
        Set @autoDefineDSType = 1    
        If @InfoOnly = 1
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
                Set @WarnMessage = 'Warning: Dataset type is ' + @currentDatasetType + ' while auto-generated type is ' + @datasetTypeAutoGen
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

        Set @datasetComment = dbo.AppendToText(@datasetComment, @message, 0, '; ', 512)
    
        If @infoOnly = 0
        Begin
            UPDATE T_Dataset
            SET DS_Comment = @datasetComment
            WHERE Dataset_ID = @datasetID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

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
        FROM T_DatasetTypeName
        WHERE (DST_name = @newDatasetType)
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
            
            -- Append a message to the dataset comment
            -- However, do not append "Auto-switched dataset type from HMS-HMSn to HMS-HCD-HMSn" since this happens for nearly every Q-Exactive dataset
            -- Also, do not append any change that includes ETciD or EThcD because those are commonly auto-added
            -- Additionally, do not update the comment when changing from HMS to HMS-HMSn (happens quite often, and is a fairly harmless change)
            --
            Set @message = 'Auto-switched dataset type from ' + @currentDatasetType + ' to ' + @newDatasetType
            
            Declare @messageAppend varchar(128)
            
            If @currentDatasetType Like 'HMS%' And @newDatasetType Like 'HMS%MSn' Or            
               @newDatasetType LIKE '%ETciD%' Or
               @newDatasetType LIKE '%EThcD%'               
            Begin
                -- Switching from HMS, HMS-MSn, HMS-HCD-HMSn, or similar to a more specific HMS-xxx-MSn type; do not update the dataset comment
                Set @messageAppend = @message
            End
            Else
            Begin
                Set @messageAppend = @message + ' on ' + SUBSTRING(CONVERT(varchar(32), GETDATE(), 121), 1, 10)
                Set @datasetComment = dbo.AppendToText(@datasetComment, @messageAppend, 0, '; ', 512)
                Set @messageAppend = ''
            End
            
            If @infoOnly = 0
            Begin
                UPDATE T_Dataset
                SET DS_Type_ID = @newDSTypeID,
                    DS_Comment = @datasetComment
                WHERE Dataset_ID = @datasetID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            Else
            Begin
                SELECT @newDatasetType AS NewDatasetType,
                       @newDSTypeID AS NewDSTypeID,
                       CASE
                           WHEN @messageAppend = '' THEN @datasetComment
                           ELSE @messageAppend
                       END AS [Comment]
            End

        End        
        Else
        Begin
            Set @message = 'Unrecognized dataset type based on actual scan types; need to auto-switch from ' + @currentDatasetType + ' to ' + @newDatasetType

            Set @datasetComment = dbo.AppendToText(@datasetComment, @message, 0, '; ', 512)

            If @infoOnly = 0
            Begin
                UPDATE T_Dataset
                SET DS_Comment = @datasetComment
                WHERE Dataset_ID = @datasetID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
        End
    End

 
Done:

    If @InfoOnly <> 0
    Begin
        If Len(@message) = 0
            Set @message = 'Dataset type is valid: ' + @currentDatasetType
            
        Print @message + ' (' + @dataset + ')'
        SELECT @message as Message, @dataset As Dataset
    End
            
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[ValidateDatasetType] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateDatasetType] TO [Limited_Table_Write] AS [dbo]
GO
