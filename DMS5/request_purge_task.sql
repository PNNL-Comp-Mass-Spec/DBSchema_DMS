/****** Object:  StoredProcedure [dbo].[RequestPurgeTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RequestPurgeTask]
/****************************************************
**
**  Desc: 
**      Looks for dataset that is best candidate to be purged
**      If found, dataset archive status is set to 'Purge In Progress'
**      and information needed for purge task is returned
**      in the output arguments
**
**      Alternatively, if @infoOnly is > 0, then will return the
**      next N datasets that would be purged on the specified server,
**      or on a series of servers (if @StorageServerName and/or @ServerDisk are blank)
**      N is 10 if @infoOnly = 1; N is @infoOnly if @infoOnly is greater than 1
**
**      Note that PreviewPurgeTaskCandidates calls this procedure, sending a positive value for @infoOnly
**
**  Return values: 0: success, otherwise, error code
**    
**  If DatasetID is returned 0, no available dataset was found
**
**  Example syntax for Preview:
**     exec RequestPurgeTask 'proto-9', @ServerDisk='g:\', @infoOnly = 1
**
**  Auth:   grk
**  Date:   03/04/2003
**          02/11/2005 grk - added @RawDataType to output
**          06/02/2009 mem - Decreased population of #PD to be limited to 2 rows
**          12/13/2010 mem - Added @infoOnly and defined defaults for several parameters
**          12/30/2010 mem - Updated to allow @StorageServerName and/or @ServerDisk to be blank
**                         - Added @PreviewSql
**          01/04/2011 mem - Now initially favoring datasets at least 4 months old, then checking datasets where the most recent job was a year ago, then looking at newer datasets
**          01/11/2011 dac/mem - Modified for use with new space manager
**          01/11/2011 dac - Added samba path for dataset as return param
**          02/01/2011 mem - Added parameter @ExcludeStageMD5RequiredDatasets
**          01/10/2012 mem - Now using V_Purgeable_Datasets_NoInterest_NoRecentJob instead of V_Purgeable_Datasets_NoInterest
**          01/16/2012 mem - Now returning Instrument, Dataset_Created, and Dataset_YearQuarter when @PreviewSql > 0
**          01/18/2012 mem - Now including Instrument, DatasetCreated, and DatasetYearQuarter when requesting an actual purge task (@infoOnly = 0)
**                         - Using @infoOnly = -1 will now show the parameter table that would be returned if an actual purge task were assigned
**          06/14/2012 mem - Now sorting by Purge_Priority, then by OrderByCol
**                         - Now including PurgePolicy in the job parameters table (0=Auto, 1=Purge All except QC Subfolder, 2=Purge All)
**                         - Now looking for state 3, 14, or 15 when actually selecting a dataset to purge
**          06/07/2013 mem - Now sorting by Archive_State_ID, Purge_Priority, then OrderByCol
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          02/02/2018 mem - Change the return code for "dataset not found" to 53000
**          02/01/2023 mem - Use new view names
**    
*****************************************************/
(
    @StorageServerName varchar(64),                    -- Storage server to use, for example 'proto-9'; if blank, then returns candidates for all storage servers; when blank, then @ServerDisk is ignored
    @ServerDisk varchar(256),                        -- Disk on storage server to use, for example 'g:\'; if blank, then returns candidates for all drives on given server (or all servers if @StorageServerName is blank)
    @ExcludeStageMD5RequiredDatasets tinyint = 1,    -- If 1, then excludes datasets with StageMD5_Required > 0
    @message varchar(512) = '' output,
    @infoOnly int = 0,                                -- Set to positive number to preview the candidates; 1 will preview the first 10 candidates; values over 1 will return the specified number of candidates; Set to -1 to preview the Parameter table that would be returned if a single purge task candidate was chosen from #PD
    @PreviewSql tinyint = 0
)
As
    set nocount on

    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Declare @CandidateCount int
    Declare @PreviewCount int

    Declare @Continue tinyint
    Declare @PurgeViewEntryID int
    Declare @PurgeViewName varchar(64)
    Declare @PurgeViewSourceDesc varchar(90)
    Declare @HoldoffDays int
    Declare @OrderByCol varchar(64)

    Declare
        @dataset varchar(128) = '',
        @DatasetID int = 0,
        @Folder varchar(256) = '', 
        @storagePath varchar(256), 
        @ServerDiskExternal varchar(256) = '',
        @RawDataType varchar(32) = '',
        @NoDatasetFound int = 53000,
        @SambaStoragePath varchar(128) = '',
        @Instrument varchar(128) = '',
        @DatasetCreated datetime,
        @DatasetYearQuarter varchar(32) = '',
        @PurgePolicy tinyint
        
    Declare @S varchar(2048)
    
    Set @CandidateCount = 0
    Set @PreviewCount = 2
    Set @message = ''
    
    --------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------
    Set @StorageServerName = IsNull(@StorageServerName, '')
    
    If @StorageServerName = ''
        Set @ServerDisk = ''
    Else
        Set @ServerDisk = IsNull(@ServerDisk, '')

    Set @ExcludeStageMD5RequiredDatasets = IsNull(@ExcludeStageMD5RequiredDatasets, 1)
    Set @InfoOnly = IsNull(@InfoOnly, 0)

    If @infoOnly <= 0
    Begin
        -- Verify that both @StorageServerName and @ServerDisk are specified
        If @StorageServerName = '' OR @ServerDisk = ''
        Begin
            Set @message = 'Error, both a storage server and a storage disk must be specified when @infoOnly <= 0'
            Set @myError = 50000
            Goto Done
        End
    End
    Else
    Begin
        If @infoOnly > 1
            Set @PreviewCount = @infoOnly
        Else
            Set @PreviewCount = 10
    End
    
    Set @PreviewSql = IsNull(@PreviewSql, 0)
    

    --------------------------------------------------
    -- Temporary table to hold candidate purgeable datasets
    ---------------------------------------------------

    CREATE TABLE #PD (
        EntryID int identity(1,1),
        DatasetID  int,
        MostRecent  datetime,
        Source varchar(90),
        StorageServerName varchar(64) NULL,
        ServerVol varchar(128) NULL,
        Purge_Priority tinyint
    ) 

    CREATE INDEX #IX_PD_StorageServerAndVol ON #PD (StorageServerName, ServerVol)

    CREATE TABLE #TmpStorageVolsToSkip (
        StorageServerName varchar(64),
        ServerVol varchar(128)
    )
    
    CREATE TABLE #TmpPurgeViews (
        EntryID int identity(1,1),
        PurgeViewName varchar(64),
        HoldoffDays int,
        OrderByCol varchar(64)    ,    
    )
    
    ---------------------------------------------------
    -- Reset AS_StageMD5_Required for any datasets with AS_purge_holdoff_date older than the current date/time
    ---------------------------------------------------
    
    UPDATE T_Dataset_Archive
    SET AS_StageMD5_Required = 0
    WHERE AS_StageMD5_Required > 0 AND
          ISNULL(AS_purge_holdoff_date, GETDATE()) <= GETDATE()
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- populate temporary table with a small pool of 
    -- purgeable datasets for given storage server
    ---------------------------------------------------
    
    -- The candidates come from three separate views, which we define in #TmpPurgeViews
    --
    -- We're querying each view twice because we want to first purge datasets at least 
    --   ~4 months old with rating No Interest, 
    --   then purge datasets that are 6 months old and don't have a job, 
    --   then purge datasets with the most recent job over 365 days ago, 
    -- If we still don't have enough candidates, we query the views again to start purging newer datasets
    
    INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoInterest_NoRecentJob', 120, 'Created')
    
    INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoJob',                  180, 'Created')

    INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets',                        365, 'MostRecentJob')

    INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoInterest_NoRecentJob', 21,  'Created')

    INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets_NoJob',                  21,  'Created')
    
    INSERT INTO #TmpPurgeViews (PurgeViewName, HoldoffDays, OrderByCol)
    VALUES ('V_Purgeable_Datasets',     21,  'MostRecentJob')
    
    ---------------------------------------------------
    -- Process each of the views in #TmpPurgeViews
    ---------------------------------------------------
    
    Set @Continue = 1
    Set @PurgeViewEntryID = 0
    
    While @Continue = 1
    Begin -- <a>
    
        SELECT TOP 1 @PurgeViewEntryID = EntryID,
                     @PurgeViewName = PurgeViewName,
                     @HoldoffDays = HoldoffDays,
                     @OrderByCol = OrderByCol
        FROM #TmpPurgeViews
        WHERE EntryID > @PurgeViewEntryID
        ORDER BY EntryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        
        If @myRowCount = 0
            Set @Continue = 0
        Else
        Begin -- <b>
            
            /*
            ** The following is a simpler query that can be used when 
            **   looking for candidates on a specific volume on a specific server
            ** It is more efficient than the larger query below (which uses Row_Number() to rank things)
            ** However, it doesn't run that much faster, and thus, for simplicity, we're always using the larger query
            **
                Set @S = ''

                Set @S = @S + ' INSERT INTO #PD( DatasetID,'
                Set @S = @S +                  ' MostRecent,'
                Set @S = @S +                  ' Source,'
                Set @S = @S +                  ' StorageServerName,'
                Set @S = @S +                  ' ServerVol,'
                Set @S = @S +                  ' Purge_Priority)'
                Set @S = @S + ' SELECT TOP (' + Convert(varchar(12), @PreviewCount) + ')'
                Set @S = @S +        ' Dataset_ID, '
                Set @S = @S +          @OrderByCol + ', '
                Set @S = @S +        '''' + @PurgeViewName + ''' AS Source,'
                Set @S = @S +        ' StorageServerName,'
                Set @S = @S +        ' ServerVol,'
                Set @S = @S +        ' Purge_Priority'
                Set @S = @S + ' FROM ' + @PurgeViewName
                Set @S = @S + ' WHERE     (StorageServerName = ''' + @StorageServerName + ''')'
                Set @S = @S +       ' AND (ServerVol = ''' + @ServerDisk + ''')'

                If @ExcludeStageMD5RequiredDatasets > 0
                    Set @S = @S +   ' AND (StageMD5_Required = 0) '
                
                If @HoldoffDays >= 0
                    Set @S = @S +   ' AND (DATEDIFF(DAY, ' + @OrderByCol + ', GetDate()) > ' + Convert(varchar(24), @HoldoffDays) + ')'
                
                Set @S = @S + ' ORDER BY Purge_Priority, ' + @OrderByCol + ', Dataset_ID'
            */
            
            Set @PurgeViewSourceDesc = @PurgeViewName
            If @HoldoffDays >= 0
                Set @PurgeViewSourceDesc = @PurgeViewSourceDesc + '_' + Convert(varchar(24), @HoldoffDays) + 'MinDays'
            
            ---------------------------------------------------
            -- Find the top @PreviewCount candidates for each drive on each server 
            -- (limiting by @StorageServerName or @ServerDisk if they are defined)
            ---------------------------------------------------
            --
            Set @S = ''
            Set @S = @S + ' INSERT INTO #PD( DatasetID,'
            Set @S = @S +                  ' MostRecent,'
            Set @S = @S +                  ' Source,'
            Set @S = @S +                  ' StorageServerName,'
            Set @S = @S +                  ' ServerVol,'
            Set @S = @S +                  ' Purge_Priority)'            
            Set @S = @S + ' SELECT Dataset_ID, '
            Set @S = @S +          @OrderByCol + ', '
            Set @S = @S +        ' Source,'
            Set @S = @S +        ' StorageServerName,'
            Set @S = @S +        ' ServerVol,'
            Set @S = @S +        ' Purge_Priority'
            Set @S = @S + ' FROM ( SELECT Src.Dataset_ID, '
            Set @S = @S +                'Src.' + @OrderByCol + ', '
            Set @S = @S +               '''' + @PurgeViewSourceDesc + ''' AS Source,'
            Set @S = @S +               ' Row_Number() OVER ( PARTITION BY Src.StorageServerName, Src.ServerVol '
            Set @S = @S +                                   ' ORDER BY Src.Archive_State_ID, Src.Purge_Priority, Src.' + @OrderByCol + ', Src.Dataset_ID ) AS RowNumVal,'
            Set @S = @S +               ' Src.StorageServerName,'
            Set @S = @S +               ' Src.ServerVol,'
            Set @S = @S +               ' Src.StageMD5_Required,'
            Set @S = @S +               ' Src.Archive_State_ID,'
            Set @S = @S +         ' Src.Purge_Priority'
            Set @S = @S +        ' FROM ' + @PurgeViewName + ' Src'
            Set @S = @S +               ' LEFT OUTER JOIN #TmpStorageVolsToSkip '
            Set @S = @S +                 ' ON Src.StorageServerName = #TmpStorageVolsToSkip.StorageServerName AND'
            Set @S = @S +                ' Src.ServerVol         = #TmpStorageVolsToSkip.ServerVol '
            Set @S = @S + ' LEFT OUTER JOIN #PD '
            Set @S = @S +                 ' ON Src.Dataset_ID = #PD.DatasetID'
            Set @S = @S +        ' WHERE #TmpStorageVolsToSkip.StorageServerName IS NULL'
            Set @S = @S +               ' AND #PD.DatasetID IS NULL '
            
            If @ExcludeStageMD5RequiredDatasets > 0
                    Set @S = @S +       ' AND (StageMD5_Required = 0) '
                    
            If @StorageServerName <> ''
                Set @S = @S +  ' AND (Src.StorageServerName = ''' + @StorageServerName + ''')'

            If @ServerDisk <> ''
                Set @S = @S +           ' AND (Src.ServerVol = ''' + @ServerDisk + ''')'

            If @HoldoffDays >= 0
                Set @S = @S +           ' AND (' + @OrderByCol + ' < DateAdd(Day, -' + Cast(@HoldoffDays as varchar(12)) + ', GetDate()) )'
            
            Set @S = @S +     ') LookupQ'
            Set @S = @S + ' WHERE RowNumVal <= ' + Cast(@PreviewCount as varchar(12))
            Set @S = @S + ' ORDER BY StorageServerName, ServerVol, Archive_State_ID, Purge_Priority, ' + @OrderByCol + ', Dataset_ID'
            
            If @PreviewSql <> 0
                Print @S
                
            Exec (@S)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @message = 'Error populating temporary table'
                goto done
            End
            
            Set @CandidateCount = @CandidateCount + @myRowCount
        
        
            If (@infoOnly <= 0)
            Begin
                If @CandidateCount > 0
                    Set @continue = 0
            End
            Else
            Begin -- <c>
                If @StorageServerName <> '' AND @ServerDisk <> ''
                Begin
                    If @CandidateCount >= @PreviewCount
                        Set @Continue = 0
                End
                Else
                Begin -- <d>
                    ---------------------------------------------------
                    -- Count the number of candidates on each volume on each storage server
                    -- Add entries to #TmpStorageVolsToSkip
                    ---------------------------------------------------
                    --
                    INSERT INTO #TmpStorageVolsToSkip( StorageServerName,
                                                       ServerVol )
                    SELECT Src.StorageServerName,
                           Src.ServerVol
                    FROM ( SELECT StorageServerName,
                                  ServerVol
                           FROM #PD
                           GROUP BY StorageServerName, ServerVol
                           HAVING COUNT(*) >= @PreviewCount 
                         ) AS Src
                         LEFT OUTER JOIN #TmpStorageVolsToSkip AS Target
                           ON Src.StorageServerName = Target.StorageServerName AND
                              Src.ServerVol = Target.ServerVol
                    WHERE Target.ServerVol IS NULL
                    
                End -- </d>
                
            End -- </c>
        
        End -- </b>
    End -- </a>
    
        
    If @infoOnly > 0
    Begin
        ---------------------------------------------------
        -- Preview the purge task candidates, then exit
        ---------------------------------------------------
        --
        SELECT #PD.*,
               DFP.Dataset,
               DFP.Dataset_Folder_Path,
               DFP.Archive_Folder_Path,
               DA.AS_State_ID AS Achive_State_ID,
               DA.AS_State_Last_Affected AS Achive_State_Last_Affected,
               DA.AS_Purge_Holdoff_Date AS Purge_Holdoff_Date,
               DA.AS_Instrument_Data_Purged AS Instrument_Data_Purged,
               dbo.udfCombinePaths(SPath.SP_vol_name_client, SPath.SP_path) AS Storage_Path_Client,
               dbo.udfCombinePaths(SPath.SP_vol_name_Server, SPath.SP_path) AS Storage_Path_Server,
               ArchPath.AP_archive_path AS Archive_Path_Unix,
               DS.DS_folder_name AS Dataset_Folder_Name,
               DFP.Instrument,
               DFP.Dataset_Created,
               DFP.Dataset_YearQuarter
        FROM #PD
             INNER JOIN T_Dataset_Archive DA
               ON DA.AS_Dataset_ID = #PD.DatasetID
             INNER JOIN V_Dataset_Folder_Paths_Ex DFP
               ON DA.AS_Dataset_ID = DFP.Dataset_ID
             INNER JOIN T_Dataset DS
               ON DS.Dataset_ID = DA.AS_Dataset_ID
             INNER JOIN T_Storage_Path SPath
         ON DS.DS_storage_path_ID = SPath.SP_path_ID
             INNER JOIN T_Archive_Path ArchPath
               ON DA.AS_storage_path_ID = ArchPath.AP_path_ID
        ORDER BY #PD.EntryID

        Goto Done        
    End
    
    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------
    --
    Declare @transName varchar(32)
    Set @transName = 'RequestPurgeTask'
    Begin transaction @transName

    ---------------------------------------------------
    -- Select and lock a specific purgeable dataset by joining
    -- from the local pool to the actual archive table
    ---------------------------------------------------
    
    SELECT TOP 1 @datasetID = AS_Dataset_ID
    FROM T_Dataset_Archive WITH ( HoldLock )
         INNER JOIN #PD
           ON DatasetID = AS_Dataset_ID
    WHERE (AS_state_ID IN (3, 14, 15))
    ORDER BY #PD.EntryID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        Set @message = 'could not load temporary table'
        Goto done
    End
    
    If @datasetID = 0
    Begin
        rollback transaction @transName
        Set @message = 'no datasets found'
        Set @myError = @NoDatasetFound
        Goto done
    End
    
    If @infoOnly = 0
    Begin
        ---------------------------------------------------
        -- update archive state to show purge in progress
        ---------------------------------------------------

        UPDATE T_Dataset_Archive
        SET AS_state_ID = 7 -- "purge in progress"
        WHERE (AS_Dataset_ID = @datasetID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Update operation failed'
            goto done
        End
    End
    
    commit transaction @transName

    ---------------------------------------------------
    -- get information for assigned dataset
    ---------------------------------------------------
    --
    SELECT @dataset = DS.Dataset_Num,
           @DatasetID = DS.Dataset_ID,
           @Folder = DS.DS_folder_name,
           @ServerDisk = SPath.SP_vol_name_server,
           @storagePath = SPath.SP_path,
           @ServerDiskExternal = SPath.SP_vol_name_client,
           @RawDataType = InstClass.raw_data_type,
           @SambaStoragePath = T_Archive_Path.AP_network_share_path,
           @Instrument = DFP.Instrument,
           @DatasetCreated = DFP.Dataset_Created,
           @DatasetYearQuarter = DFP.Dataset_YearQuarter,
           @PurgePolicy = DA.Purge_Policy
    FROM T_Dataset DS
         INNER JOIN T_Dataset_Archive DA
           ON DS.Dataset_ID = DA.AS_Dataset_ID
         INNER JOIN T_Storage_Path SPath
           ON DS.DS_storage_path_ID = SPath.SP_path_ID
         INNER JOIN T_Instrument_Name InstName
           ON DS.DS_instrument_name_ID = InstName.Instrument_ID
         INNER JOIN T_Instrument_Class InstClass
           ON InstName.IN_class = InstClass.IN_class
         INNER JOIN T_Archive_Path
           ON DA.AS_storage_path_ID = T_Archive_Path.AP_path_ID
         INNER JOIN V_Dataset_Folder_Paths_Ex DFP
           ON DA.AS_Dataset_ID = DFP.Dataset_ID
    WHERE DS.Dataset_ID = @datasetID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0 or @myRowCount <> 1
    Begin
        Set @message = 'Find purgeable dataset operation failed'
        goto done
    End

    ---------------------------------------------------
    -- temp table to hold job parameters
    ---------------------------------------------------
    --
    CREATE TABLE #ParamTab
    (
        [Name] VARCHAR(128),
        [Value] VARCHAR(MAX)
    )

    ---------------------------------------------------
    -- populate job parameters table
    ---------------------------------------------------
    -- 
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('dataset', @dataset)
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('DatasetID', @DatasetID)
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('Folder', @Folder)
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('StorageVol', @ServerDisk)
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('storagePath', @storagePath)
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('StorageVolExternal', @ServerDiskExternal)
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('RawDataType', @RawDataType)
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('SambaStoragePath', @SambaStoragePath)    
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('Instrument', @Instrument)
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('DatasetCreated', Convert(varchar(64), @DatasetCreated, 120))
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('DatasetYearQuarter', @DatasetYearQuarter)
    INSERT INTO #ParamTab( Name, Value ) VALUES  ('PurgePolicy', @PurgePolicy)
    

    ---------------------------------------------------
    -- output parameters as resultset 
    ---------------------------------------------------
    --
    SELECT
        Name AS Parameter,
        Value
    FROM
        #ParamTab

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError


GO
GRANT EXECUTE ON [dbo].[RequestPurgeTask] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPurgeTask] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestPurgeTask] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestPurgeTask] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPurgeTask] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestPurgeTask] TO [svc-dms] AS [dbo]
GO
