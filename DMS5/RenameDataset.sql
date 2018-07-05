/****** Object:  StoredProcedure [dbo].[RenameDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RenameDataset]
/****************************************************
**
**  Desc: 
**      Renames a dataset in T_Dataset
**      Renames associated jobs in the DMS_Capture and DMS_Pipeline databases
**
**  Return values: 0: success, otherwise, error code
** 
**  Auth:   mem
**          01/25/2013 mem - Initial version
**          07/08/2016 mem - Now show old/new names and jobs even when @infoOnly is 0
**          12/06/2016 mem - Include file rename statements
**          03/06/2017 mem - Validate that @datasetNameNew is no more than 80 characters long
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          07/03/2018 mem - Rename files in T_Dataset_Files
**                         - Update commands for renaming the dataset directory and dataset file
**    
*****************************************************/
(
    @datasetNameOld varchar(128) = '',
    @datasetNameNew varchar(128) = '',
    @message varchar(512) = '' output,
    @infoOnly tinyint = 1
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    Declare @datasetID int = 0
    Declare @datasetFolderPath varchar(255) = ''
    Declare @storageServerSharePath varchar(255)
    Declare @lastSlashReverseText int

    Declare @jobsToUpdate table (Job int not null)
    Declare @job int = 0
    
    Declare @suffixID int
    Declare @fileSuffix varchar(64)
    
    Declare @continue tinyint
    Declare @continue2 tinyint
    
    Declare @toolBaseName varchar(64)
    Declare @resultsFolder varchar(128)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'RenameDataset', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    --------------------------------------------
    -- Validate the inputs
    --------------------------------------------
    --
    Set @datasetNameOld = ISNULL(@datasetNameOld, '')
    Set @datasetNameNew = ISNULL(@datasetNameNew, '')

    If @datasetNameOld = ''
    Begin
        Set @message = '@datasetNameOld is empty; unable to continue'
        Goto Done
    End

    If @datasetNameNew = ''
    Begin
        Set @message = '@datasetNameNew is empty; unable to continue'
        Goto Done
    End

    If Len(@datasetNameNew) > 80
    Begin
        Set @message = 'New dataset name cannot be more than 80 characters in length'
        Goto Done
    End
    
    --------------------------------------------
    -- Lookup the dataset ID
    --------------------------------------------
    --
    SELECT @datasetID = Dataset_ID
    FROM dbo.T_Dataset
    WHERE Dataset_Num = @datasetNameOld

    If IsNull(@datasetID, 0) = 0
    Begin
        -- Old dataset name not found; perhaps it was already renamed in T_Dataset
        SELECT @datasetID = Dataset_ID
        FROM dbo.T_Dataset
        WHERE Dataset_Num = @datasetNameNew
    End
    Else
    Begin

        -- Old dataset name found; make sure the new name is not already in use
        If Exists (SELECT * FROM dbo.T_Dataset WHERE Dataset_Num = @datasetNameNew)
        Begin
            Set @message = 'New dataset name already exists; unable to rename ' + @datasetNameOld + ' to ' + @datasetNameNew
            Goto Done
        End

    End

    If @datasetID = 0
    Begin
        Set @message = 'Dataset not found using either the old name or the new name (' +  @datasetNameOld + ' or ' + @datasetNameNew + ')'
        Goto Done
    End
            
    -- Lookup the share folder for this dataset
    SELECT @datasetFolderPath = Dataset_Folder_Path
    FROM V_Dataset_Folder_Paths
    WHERE Dataset_ID = @datasetID

    -- Extract the parent directory path from @datasetFolderPath
    Set @lastSlashReverseText = CharIndex('\', Reverse(@datasetFolderPath))
    Set @storageServerSharePath = Substring(@datasetFolderPath, 1, Len(@datasetFolderPath) - @lastSlashReverseText)

    If @InfoOnly = 0 
    Begin
        --------------------------------------------
        -- Rename the dataset in T_Dataset
        --------------------------------------------
        --
        If Not Exists (Select * from T_Dataset WHERE Dataset_Num = @datasetNameNew)
        Begin
            SELECT Dataset_Num AS DatasetNameOld,
                   @datasetNameNew AS DatasetNameNew,
                   Dataset_ID,
                   DS_Created
            FROM T_Dataset
            WHERE Dataset_Num IN (@datasetNameOld, @datasetNameNew)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            UPDATE T_Dataset
            SET Dataset_Num = @datasetNameNew,
                DS_folder_name = @datasetNameNew
            WHERE Dataset_ID = @datasetID AND Dataset_Num = @datasetNameOld
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @message = 'Renamed dataset "' + @datasetNameOld + '" to "' + @datasetNameNew + '"'
            print @message
                
            Exec PostLogEntry 'Normal', @message, 'RenameDataset'
        End

        -- Rename any files in T_Dataset_Files
        If Exists (Select * from T_Dataset_Files WHERE Dataset_ID = @datasetID)
        Begin
            UPDATE T_Dataset_Files
            SET File_Path = REPLACE(File_Path, @datasetNameOld, @datasetNameNew)
            FROM T_Dataset_Files
            WHERE Dataset_ID = @datasetID
        End        
    End
    Else
    Begin
        -- Preview the changes
        
        If Exists (Select * from T_Dataset WHERE Dataset_Num = @datasetNameNew)
        Begin
            SELECT @datasetNameOld AS DatasetNameOld,
                   Dataset_Num AS DatasetNameNew,
                   Dataset_ID,
                   DS_Created
            FROM T_Dataset
            WHERE Dataset_Num IN (@datasetNameOld, @datasetNameNew)
        End
        Else
        Begin
            SELECT Dataset_Num AS DatasetNameOld,
                   @datasetNameNew AS DatasetNameNew,
                   Dataset_ID,
                   DS_Created
            FROM T_Dataset
            WHERE Dataset_Num IN (@datasetNameOld, @datasetNameNew)
        End

        If Exists (Select * from T_Dataset_Files WHERE Dataset_ID = @datasetID)
        Begin
            SELECT Dataset_File_ID, Dataset_ID, File_Path, REPLACE(File_Path, @datasetNameOld, @datasetNameNew) AS File_Path_New
            FROM   T_Dataset_Files
            WHERE Dataset_ID = @datasetID
        End        

    End

    --------------------------------------------
    -- Show commands for renaming the dataset directory and .raw file
    --------------------------------------------
    --
    Print 'Pushd ' + @storageServerSharePath
    Print 'Rename ' + @datasetNameOld + ' ' + @datasetNameNew
    Print 'cd ' + @datasetNameNew
    Print 'Move ' + @datasetNameOld + '.raw ' + @datasetNameNew + '.raw'

    --------------------------------------------
    -- Update jobs in the DMS_Capture database
    --------------------------------------------
    --
    DELETE FROM @jobsToUpdate
    
    INSERT INTO @jobsToUpdate (Job)
    SELECT Job 
    FROM DMS_Capture.dbo.T_Jobs 
    WHERE dataset = @datasetNameOld
    ORDER BY Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    SELECT Job AS Capture_Job, Script, State, Dataset, @datasetNameNew as Dataset_Name_New, Dataset_ID, Imported
    FROM DMS_Capture.dbo.T_Jobs 
    WHERE Job In (Select Job from @jobsToUpdate)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @InfoOnly = 0 And Exists (Select * From @jobsToUpdate)
    Begin
        Set @continue = 1
        Set @job = 0
    End
    Else
    Begin
        Set @continue = 0
    End

    --------------------------------------------
    -- Update analysis jobs in DMS_Capture if @InfoOnly is 0
    --------------------------------------------
    --
    While @continue = 1
    Begin
        SELECT TOP 1 @job = Job
        FROM @jobsToUpdate
        WHERE Job > @job
        ORDER BY Job        
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        
        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin
        
            exec DMS_Capture.dbo.AddUpdateJobParameter @job, 'JobParameters', 'Dataset', @datasetNameNew, @infoonly=0
            exec DMS_Capture.dbo.AddUpdateJobParameter @job, 'JobParameters', 'Folder',  @datasetNameNew, @infoonly=0
            
            UPDATE DMS_Capture.dbo.T_Jobs 
            Set Dataset = @datasetNameNew
            WHERE Job = @job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End

    End
    
    --------------------------------------------
    -- Update jobs in the DMS_Pipeline database
    --------------------------------------------
    --
    DELETE FROM @jobsToUpdate
    
    INSERT INTO @jobsToUpdate (Job)
    SELECT Job 
    FROM DMS_Pipeline.dbo.T_Jobs 
    WHERE Dataset = @datasetNameOld
    ORDER BY Job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    SELECT Job AS Pipeline_Job, Script, State, Dataset, @datasetNameNew as Dataset_Name_New, Dataset_ID, Imported
    FROM DMS_Pipeline.dbo.T_Jobs 
    WHERE Job In (Select Job from @jobsToUpdate)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @InfoOnly = 0 And Exists (Select * From @jobsToUpdate)
    Begin
        Set @continue = 1
        Set @job = 0
    End
    Else
    Begin
        Set @continue = 0
    End
    
    While @continue = 1
    Begin
        SELECT TOP 1 @job = Job
        FROM @jobsToUpdate
        WHERE Job > @job
        ORDER BY Job        
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        
        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin
        
            exec DMS_Pipeline.dbo.AddUpdateJobParameter @job, 'JobParameters', 'DatasetNum',        @datasetNameNew, @infoonly=0
            exec DMS_Pipeline.dbo.AddUpdateJobParameter @job, 'JobParameters', 'DatasetFolderName', @datasetNameNew, @infoonly=0
            
            UPDATE DMS_Pipeline.dbo.T_Jobs 
            Set Dataset = @datasetNameNew
            WHERE Job = @job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End
    End

    --------------------------------------------
    -- Show example commands for renaming the job files
    --------------------------------------------
    --
    CREATE TABLE #Tmp_Extensions (
        SuffixID int identity(1,1),
        FileSuffix varchar(64) NOT null
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_Extensions_ID on #Tmp_Extensions(SuffixID)
    CREATE UNIQUE INDEX #IX_Tmp_Extensions_Suffix on #Tmp_Extensions(FileSuffix)    

    DELETE FROM @jobsToUpdate
    
    INSERT INTO @jobsToUpdate (Job)
    SELECT Job 
    FROM V_Analysis_Job_Export 
    WHERE Dataset = @datasetNameOld
    ORDER BY Job
    
    Set @continue = 1
    Set @job = 0
    
    Declare @jobFileUpdateCount int = 0
    
    Print ''
    Print 'Note: given the prevalence of the dataset name in result files, it is often easier to just delete the result folders and re-run the jobs'

    While @continue > 0
    Begin
        SELECT TOP 1 @job = Job
        FROM @jobsToUpdate
        WHERE Job > @job
        ORDER BY Job        
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Truncate Table #Tmp_Extensions
        
        If @myRowCount = 0
        Begin
            --------------------------------------------
            -- Show example commands for renaming QC files
            --------------------------------------------
            --
            Set @continue = 0
            Set @resultsFolder = 'QC'
            
            Insert Into #Tmp_Extensions (FileSuffix) Values 
                ('_BPI_MS.png'),('_BPI_MSn.png'),
                ('_HighAbu_LCMS.png'),('_HighAbu_LCMS_MSn.png'),
                ('_LCMS.png'),('_LCMS_MSn.png'),
                ('_TIC.png'),('_DatasetInfo.xml')
        End
        Else
        Begin
            SELECT @toolBaseName = Tool.AJT_toolBasename,
                    @resultsFolder = ResultsFolder
            FROM V_Analysis_Job_Export AJE
                    INNER JOIN T_Analysis_Tool Tool
                    ON AJE.AnalysisTool = Tool.AJT_toolName
            WHERE Job = @job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
            Begin
                If @toolBaseName = 'Decon2LS'
                Begin
                    Insert Into #Tmp_Extensions (FileSuffix) Values 
                        ('_isos.csv'), ('_scans.csv'),
                        ('_BPI_MS.png'), ('_HighAbu_LCMS.png'), ('_HighAbu_LCMS_zoom.png'),
                        ('_LCMS.png'), ('_LCMS_zoom.png'),
                        ('_TIC.png'), ('_log.txt')
                End
                
                If @toolBaseName = 'MASIC'
                Begin
                    Insert Into #Tmp_Extensions (FileSuffix) Values 
                        ('_MS_scans.csv'), ('_MSMS_scans.csv'),('_MSMethod.txt'), 
                        ('_ScanStats.txt'), ('_ScanStatsConstant.txt'), ('_ScanStatsEx.txt'), 
                        ('_SICstats.txt'),('_DatasetInfo.xml'),('_SICs.zip')
                End

                If @toolBaseName Like 'MSGFPlus%'
                Begin
                    Insert Into #Tmp_Extensions (FileSuffix) Values 
                        ('_msgfplus.mzid.gz'),('_msgfplus_fht.txt'), ('_msgfplus_fht_MSGF.txt'),
                        ('_msgfplus_PepToProtMap.txt'), ('_msgfplus_PepToProtMapMTS.txt'),
                        ('_msgfplus_syn.txt'), ('_msgfplus_syn_ModDetails.txt'),
                        ('_msgfplus_syn_ModSummary.txt'),('_msgfplus_syn_MSGF.txt'),
                        ('_msgfplus_syn_ProteinMods.txt'),('_msgfplus_syn_ResultToSeqMap.txt'),
                        ('_msgfplus_syn_SeqInfo.txt'),('_msgfplus_syn_SeqToProteinMap.txt'),
                        ('_ScanType.txt'),('_pepXML.zip')

                End
            End
        End
        
        If @jobFileUpdateCount = 0
            Print 'Example commands for renaming job files'

        Print ''
        Print 'cd ' + @resultsFolder
        
        If Exists (Select * From #Tmp_Extensions)
            Set @continue2 = 1
        Else
            Set @continue2 = 0
            
        Set @suffixID = 0
        Set @fileSuffix = ''
        
        While @continue2 = 1
        Begin
            SELECT TOP 1 @suffixID = SuffixID,
                         @fileSuffix = FileSuffix
            FROM #Tmp_Extensions
            WHERE SuffixID > @suffixID
            ORDER BY SuffixID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @continue2 = 0
            Else
            Begin
                Print 'Move ' + @datasetNameOld + @fileSuffix + ' ' + @datasetNameNew + @fileSuffix
                Set @jobFileUpdateCount = @jobFileUpdateCount + 1
            End

        End
        
        Print 'cd ..'
        
    End

    Print 'popd'
    Print ''
    Print ''

    If @jobFileUpdateCount > 0
    Begin
        Select 'See the console output for ' + Cast(@jobFileUpdateCount as varchar(9)) + ' dataset/job file update commands' as Comment
    End
    
     ---------------------------------------------------
    -- Done
     ---------------------------------------------------
Done:

    If @message <> ''
    Begin
        Select @message as Message
    End
    
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RenameDataset] TO [DDL_Viewer] AS [dbo]
GO
