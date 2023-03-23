/****** Object:  StoredProcedure [dbo].[add_analysis_job_group] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_analysis_job_group]
/****************************************************
**
**  Desc:   Adds new analysis jobs for list of datasets
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/29/2004
**          04/01/2004 grk - fixed error return
**          06/07/2004 to 4/04/2006 -- multiple updates
**          04/05/2006 grk - major rewrite
**          04/10/2006 grk - widened size of list argument to 6000 characters
**          11/30/2006 mem - Added column Dataset_Type to #TD (Ticket #335)
**          12/19/2006 grk - Added propagation mode (Ticket #348)
**          12/20/2006 mem - Added column DS_rating to #TD (Ticket #339)
**          02/07/2007 grk - eliminated "Spectra Required" states (Ticket #249)
**          02/15/2007 grk - added associated processor group (Ticket #383)
**          02/21/2007 grk - removed @assignedProcessor  (Ticket #383)
**          10/11/2007 grk - Expand protein collection list size to 4000 characters (https://prismtrac.pnl.gov/trac/ticket/545)
**          02/19/2008 grk - add explicit NULL column attribute to #TD
**          02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call alter_event_log_entry_user or alter_event_log_entry_user_multi_id (Ticket #644)
**          05/27/2008 mem - Increased @EntryTimeWindowSeconds value to 45 seconds when calling alter_event_log_entry_user_multi_id
**          09/12/2008 mem - Now passing @paramFileName and @settingsFileName ByRef to validate_analysis_job_parameters (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**          02/27/2009 mem - Expanded @comment to varchar(512)
**          04/15/2009 grk - handles wildcard DTA folder name in comment field (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          08/05/2009 grk - assign job number from separate table (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**          08/05/2009 mem - Now removing duplicates when populating #TD
**                         - Updated to use get_new_job_id_block to obtain job numbers
**          09/17/2009 grk - Don't make new jobs for datasets with existing jobs (optional mode) (Ticket #747, http://prismtrac.pnl.gov/trac/ticket/747)
**          09/19/2009 grk - Improved return message
**          09/23/2009 mem - Updated to handle requests with state "New (Review Required)"
**          12/21/2009 mem - Now updating field AJR_jobCount in T_Analysis_Job_Request when @requestID is > 1
**          04/22/2010 grk - try-catch for error handling
**          05/05/2010 mem - Now passing @ownerUsername to validate_analysis_job_parameters as input/output
**          05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**          01/31/2011 mem - Expanded @datasetList to varchar(max)
**          02/24/2011 mem - No longer skipping jobs with state "No Export" when finding datasets that have existing, matching jobs
**          03/29/2011 grk - added @specialProcessing argument (http://redmine.pnl.gov/issues/304)
**          05/24/2011 mem - Now populating column AJ_DatasetUnreviewed
**          06/15/2011 mem - Now ignoring organism, protein collection, and organism DB when looking for existing jobs and the analysis tool does not use an organism database
**          09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**          11/08/2012 mem - Now auto-updating @protCollOptionsList to have "seq_direction=forward" if it contains "decoy" and the search tool is MSGFDB and the parameter file does not contain "NoDecoy"
**          01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**          03/26/2013 mem - Now calling alter_event_log_entry_user after updating T_Analysis_Job_Request
**          03/27/2013 mem - Now auto-updating @ownerUsername to @callingUser if @callingUser maps to a valid user
**          06/06/2013 mem - Now setting job state to 19="Special Proc. Waiting" if analysis tool has Use_SpecialProcWaiting enabled
**          04/08/2015 mem - Now passing @autoUpdateSettingsFileToCentroided and @warning to validate_analysis_job_parameters
**          05/28/2015 mem - No longer creating processor group entries (thus @associatedProcessorGroup is ignored)
**          12/17/2015 mem - Now considering @specialProcessing when looking for existing jobs
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          05/18/2016 mem - Include the Request ID in error messages
**          07/12/2016 mem - Pass @priority to validate_analysis_job_parameters
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2017 mem - Set @allowNewDatasets to 0 when calling validate_analysis_job_parameters
**          05/11/2018 mem - When the settings file is Decon2LS_DefSettings.xml, also match jobs with a settings file of 'na'
**          06/12/2018 mem - Send @maxLength to append_to_text
**          07/30/2019 mem - Call update_cached_job_request_existing_jobs after creating new jobs
**          03/10/2021 mem - Add @dataPackageID
**          03/11/2021 mem - Associate new pipeline-based jobs with their analysis job request
**          03/15/2021 mem - Read setting CacheFolderRootPath from MaxQuant settings files
**                         - Update settings file, parameter file, protein collection, etc. in T_Analysis_Job for newly created MaxQuant jobs
**          03/16/2021 mem - Add check for MSXMLGenerator being 'skip'
**          06/01/2021 mem - Raise an error if @mode is invalid
**          08/26/2021 mem - Add support for data package based MSFragger jobs
**          11/15/2021 mem - Use custom messages when creating a single job
**          02/02/2022 mem - Include the settings file name in the job parameters when creating a data package based job
**          02/12/2022 mem - Add MSFragger job parameters to the settings for data package based MSFragger jobs
**          02/18/2022 mem - Add MSFragger DatabaseSplitCount to the settings for data package based MSFragger jobs
**          03/03/2022 mem - Add support for MSFragger options AutoDefineExperimentGroupWithDatasetName and AutoDefineExperimentGroupWithExperimentName
**          03/17/2022 mem - Log errors only after parameters have been validated
**          06/30/2022 mem - Rename parameter file argument
**          07/01/2022 mem - Rename auto generated parameters to use ParamFileName and ParamFileStoragePath
**          07/29/2022 mem - Assure that the parameter file and settings file names are not null
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetList varchar(max),                      -- Ignored if @dataPackageID is a positive integer
    @priority int = 2,
    @toolName varchar(64),
    @paramFileName varchar(255),
    @settingsFileName varchar(255),
    @organismDBName varchar(128),                   -- Legacy FASTA name; 'na' if using protein collections
    @organismName varchar(128),
    @protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
    @ownerUsername varchar(32),                          -- Will get updated to @callingUser if @callingUser is valid
    @comment varchar(512) = null,
    @specialProcessing varchar(512) = null,
    @requestID int,                                 -- 0 if not associated with a request; otherwise, Request ID in T_Analysis_Job_Request
    @dataPackageID int = 0,
    @associatedProcessorGroup varchar(64) = '',     -- Processor group; deprecated in May 2015
    @propagationMode varchar(24) = 'Export',        -- 'Export', 'No Export'
    @removeDatasetsWithJobs varchar(12) = 'Y',
    @mode varchar(12),                              -- 'add' or 'preview'
    @message varchar(512) = '' output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(512)
    Declare @list varchar(1024)
    Declare @jobID int
    Declare @jobIDStart int
    Declare @jobIDEnd int

    Declare @jobStateID int
    Declare @requestStateID int = 0

    Declare @jobCountToBeCreated int = 0
    Declare @msgForLog varchar(2000)
    Declare @backfillError int
    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_analysis_job_group', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @requestID = Coalesce(@requestID, 0)

    Set @dataPackageID = Coalesce(@dataPackageID, 0)
    If @dataPackageID < 0
        Set @dataPackageID = 0

    Set @datasetList = LTrim(RTrim(Coalesce(@datasetList, '')))

    Set @mode = Coalesce(@mode, '')

    If Not @mode in ('add', 'preview')
    Begin
        RAISERROR ('Invalid mode: should be "add" or "preview", not "%s"', 11, 117, @mode)
    End

    ---------------------------------------------------
    -- We either need datasets or a data package
    ---------------------------------------------------

    If @dataPackageID > 0
    Begin
        Set @datasetList = ''
    End
    Else If @datasetList = ''
    Begin
        RAISERROR ('Dataset list is empty for request %d', 11, 1, @requestID)
    End

    Set @paramFileName = LTrim(RTrim(Coalesce(@paramFileName, '')))
    Set @settingsFileName = LTrim(RTrim(Coalesce(@settingsFileName, '')))

    /*
    ---------------------------------------------------
    -- Deprecated in May 2015: resolve processor group ID
    ---------------------------------------------------
    --
    Declare @gid int
    Set @gid = 0
    --
    If @associatedProcessorGroup <> ''
    Begin
        SELECT @gid = ID
        FROM T_Analysis_Job_Processor_Group
        WHERE (Group_Name = @associatedProcessorGroup)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error trying to resolve processor group name for request %d', 11, 8, @requestID)
        --
        If @gid = 0
            RAISERROR ('Processor group name not found for request %d', 11, 9, @requestID)
    End
    */

    ---------------------------------------------------
    -- Create temporary table to hold list of datasets
    ---------------------------------------------------

    CREATE TABLE #TD (
        Dataset_Name varchar(128),
        Dataset_ID int NULL,
        IN_class varchar(64) NULL,
        DS_state_ID int NULL,
        AS_state_ID int NULL,
        Dataset_Type varchar(64) NULL,
        DS_rating smallint NULL,
        Job int NULL,
        Dataset_Unreviewed tinyint NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Failed to create temporary table for request %d', 11, 7, @requestID)

    CREATE CLUSTERED INDEX #IX_TD_Dataset_Name ON #TD (Dataset_Name)

    If @dataPackageID > 0
    Begin
        If Not @toolName In ('MaxQuant', 'MSFragger')
            RAISERROR ('%s is not a compatible tool for job requests with a data package; the only supported tools are MaxQuant and MSFragger', 11, 7, @toolName)

        If @requestID <= 0
            RAISERROR ('Data-package based jobs must be associated with an analysis job request', 11, 7)

        ---------------------------------------------------
        -- Populate table using the datasets currently associated with the data package
        -- Remove any duplicates that may be present
        ---------------------------------------------------
        --
        INSERT INTO #TD (Dataset_Name)
        SELECT DISTINCT Dataset
        FROM S_V_Data_Package_Datasets_Export
        WHERE Data_Package_ID = @dataPackageID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Set @jobCountToBeCreated = @myRowCount
        --
        If @myError <> 0
            RAISERROR ('Error populating temporary table', 11, 8)

        If @jobCountToBeCreated = 0
            RAISERROR ('Data package does not have any datasets associated with it', 11, 10)
    End
    Else
    Begin
        ---------------------------------------------------
        -- Populate table from dataset list
        -- Using Select Distinct to make sure any duplicates are removed
        ---------------------------------------------------
        --
        INSERT INTO #TD (Dataset_Name)
        SELECT DISTINCT LTrim(RTrim(Item))
        From make_table_from_list(@datasetList)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error populating temporary table for request %d', 11, 7, @requestID)
        --
        Set @jobCountToBeCreated = @myRowCount

        -- Make sure the Dataset names do not have carriage returns or line feeds

        UPDATE #TD
        SET Dataset_Name = Replace(Dataset_Name, char(13), '')
        WHERE Dataset_Name LIKE '%' + char(13) + '%'

        UPDATE #TD
        SET Dataset_Name = Replace(Dataset_Name, char(10), '')
        WHERE Dataset_Name LIKE '%' + char(10) + '%'
    End

     ---------------------------------------------------
    -- Assure that we are not running a decoy search if using MSGFPlus, TopPIC, or MaxQuant (since those tools auto-add decoys)
    -- However, if the parameter file contains _NoDecoy in the name, we'll allow @protCollOptionsList to contain Decoy
    ---------------------------------------------------
    --
    If (@toolName LIKE 'MSGFPlus%' Or @toolName LIKE 'TopPIC%' Or @toolName LIKE 'MaxQuant%') And @protCollOptionsList Like '%decoy%' And @paramFileName Not Like '%[_]NoDecoy%'
    Begin
        Set @protCollOptionsList = 'seq_direction=forward,filetype=fasta'

        If Coalesce(@message, '') = '' And @toolName LIKE 'MSGFPlus%'
            Set @message = 'Note: changed protein options to forward-only since MS-GF+ parameter files typically have tda=1'

        If Coalesce(@message, '') = '' And @toolName LIKE 'TopPIC%'
            Set @message = 'Note: changed protein options to forward-only since TopPIC parameter files typically have Decoy=True'

        If Coalesce(@message, '') = '' And @toolName LIKE 'MaxQuant%'
            Set @message = 'Note: changed protein options to forward-only since MaxQuant parameter files typically have <decoyMode>revert</decoyMode>'
    End

    If (@toolName LIKE 'MSFragger%') And @protCollOptionsList Like '%forward%' And @paramFileName Not Like '%[_]NoDecoy%'
    Begin
        Set @protCollOptionsList = 'seq_direction=decoy,filetype=fasta'

        If Coalesce(@message, '') = '' And @toolName LIKE 'MSFragger%'
            Set @message = 'Note: changed protein options to decoy-mode since MSFragger expects the FASTA file to have decoy proteins'
    End

    ---------------------------------------------------
    -- Auto-update @ownerUsername to @callingUser if possible
    ---------------------------------------------------
    If Len(@callingUser) > 0
    Begin
        Declare @newUsername varchar(128) = @callinguser
        Declare @slashIndex int = CHARINDEX('\', @newUsername)

        If @slashIndex > 0
            Set @newUsername = SUBSTRING(@newUsername, @slashIndex+1, LEN(@newUsername))

        If Exists (SELECT * FROM T_Users Where U_PRN = @newUsername)
            Set @ownerUsername = @newUsername
    End

    ---------------------------------------------------
    -- If @removeDatasetsWithJobs is not "N",
    --  find datasets from temp table that have existing
    --  jobs that match criteria from request
    -- If AJT_orgDbReqd = 0, we ignore organism, protein collection, and organism DB
    ---------------------------------------------------
    --
    Declare @datasetCountToRemove INT = 0

    Declare @removedDatasets varchar(4096) = ''
    --
    If @dataPackageID = 0 And @removeDatasetsWithJobs <> 'N'
    Begin --<remove>
        Declare @matchingJobDatasets Table (
            Dataset varchar(128)
        )
        --
        INSERT INTO @matchingJobDatasets(Dataset)
        SELECT DS.Dataset_Num AS Dataset
        FROM
            T_Dataset DS INNER JOIN
            T_Analysis_Job AJ ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
            T_Analysis_Tool AJT ON AJ.AJ_analysisToolID = AJT.AJT_toolID INNER JOIN
            T_Organisms Org ON AJ.AJ_organismID = Org.Organism_ID  INNER JOIN
            T_Analysis_State_Name ASN ON AJ.AJ_StateID = ASN.AJS_stateID INNER JOIN
            #TD ON #TD.Dataset_Name = DS.Dataset_Num
        WHERE
            (NOT (AJ.AJ_StateID IN (5))) AND
            AJT.AJT_toolName = @toolName AND
            AJ.AJ_parmFileName = @paramFileName AND
            (AJ.AJ_settingsFileName = @settingsFileName OR
             AJ.AJ_settingsFileName = 'na' AND @settingsFileName = 'Decon2LS_DefSettings.xml') AND
            ( (    @protCollNameList = 'na' AND AJ.AJ_organismDBName = @organismDBName AND
                Org.OG_name = Coalesce(@organismName, Org.OG_name)
              ) OR
              (    @protCollNameList <> 'na' AND
                AJ.AJ_proteinCollectionList = Coalesce(@protCollNameList, AJ.AJ_proteinCollectionList) AND
                AJ.AJ_proteinOptionsList = Coalesce(@protCollOptionsList, AJ.AJ_proteinOptionsList)
              ) OR
              (
                AJT.AJT_orgDbReqd = 0
              )
            ) AND
            Coalesce(AJ.AJ_specialProcessing, '') = Coalesce(@specialProcessing, '')
        GROUP BY DS.Dataset_Num
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error trying to find datasets with existing jobs for request %d', 11, 97, @requestID)

        Set @datasetCountToRemove = @myRowCount

        If @datasetCountToRemove > 0
        Begin --<remove-a>
            -- remove datasets from list that have existing jobs
            --
            DELETE FROM #TD
            WHERE Dataset_Name IN (SELECT Dataset FROM @matchingJobDatasets)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            Set @jobCountToBeCreated = @jobCountToBeCreated - @myRowCount

            -- make list of removed datasets
            --
            Declare @threshold Smallint = 5

            If @datasetCountToRemove = 1
                Set @removedDatasets = '1 skipped dataset that has an existing job: '
            Else
                Set @removedDatasets = CONVERT(varchar(12), @datasetCountToRemove) + ' skipped datasets that have existing jobs: '

            SELECT TOP(@threshold) @removedDatasets = @removedDatasets + Dataset + ', '
            FROM @matchingJobDatasets

            If @datasetCountToRemove > @threshold
            Begin
                Set @removedDatasets = @removedDatasets + ' (more datasets not shown)'
            End
        End --<remove-a>
    End --<remove>


    ---------------------------------------------------
    -- Resolve propagation mode
    ---------------------------------------------------
    Declare @propMode smallint
    Set @propMode = CASE @propagationMode
                        WHEN 'Export' THEN 0
                        WHEN 'No Export' THEN 1
                        ELSE 0
                    END

    ---------------------------------------------------
    -- validate job parameters
    ---------------------------------------------------
    --
    Declare @userID int
    Declare @analysisToolID int
    Declare @organismID int
    --
    Declare @result int = 0
    Declare @warning varchar(255) = ''

    Set @organismName = Ltrim(Rtrim(@organismName))

    exec @result = validate_analysis_job_parameters
                            @toolName = @toolName,
                            @paramFileName = @paramFileName output,
                            @settingsFileName = @settingsFileName output,
                            @organismDBName = @organismDBName output,
                            @organismName = @organismName,
                            @protCollNameList = @protCollNameList output,
                            @protCollOptionsList = @protCollOptionsList output,
                            @ownerUsername = @ownerUsername output,
                            @mode = @mode,
                            @userID = @userID output,
                            @analysisToolID = @analysisToolID output,
                            @organismID = @organismID output,
                            @message = @msg output,
                            @AutoRemoveNotReleasedDatasets = 0,
                            @autoUpdateSettingsFileToCentroided = 1,
                            @allowNewDatasets = 0,
                            @Warning = @warning output,
                            @priority = @priority output
    --
    If @result <> 0
        RAISERROR ('validate_analysis_job_parameters: %s for request %d', 11, 8, @msg, @requestID)

    If Coalesce(@warning, '') <> ''
    Begin
        Set @comment = dbo.append_to_text(@comment, @warning, 0, '; ', 512)
    End

    ---------------------------------------------------
    -- New jobs typically have state 1
    -- Update @jobStateID to 19="Special Proc. Waiting" if necessary
    ---------------------------------------------------
    --
    Set @jobStateID = 1
    --
    If Coalesce(@specialProcessing, '') <> '' AND
       Exists (SELECT * FROM T_Analysis_Tool WHERE AJT_toolName = @toolName AND Use_SpecialProcWaiting > 0)
    Begin
        Set @jobStateID = 19
    End

    ---------------------------------------------------
    -- Populate the Dataset_Unreviewed column in #TD
    ---------------------------------------------------
    --
    UPDATE #TD
    SET Dataset_Unreviewed = CASE WHEN DS.DS_rating = -10 THEN 1 ELSE 0 END
    FROM T_Dataset DS
        INNER JOIN #TD
        ON DS.Dataset_Num = #TD.Dataset_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @dataPackageID > 0
    Begin
        If @mode = 'add'
        Begin
            ---------------------------------------------------
            -- Make sure the job request is in state 1=new or state 5=new (Review Required)
            ---------------------------------------------------
            --
            SELECT @requestStateID = AJR_State
            FROM T_Analysis_Job_Request
            WHERE AJR_RequestID = @requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Error looking up request state in T_Analysis_Job_Request for request %d', 11, 7, @requestID)

            Set @requestStateID = Coalesce(@requestStateID, 0)

            If Not @requestStateID IN (1, 5)
            Begin
                -- Request ID is non-zero and request is not in state 1 or state 5
                RAISERROR ('Request is not in state New; cannot create an aggregation job for request %d', 11, 9, @requestID)
            End
        End

        Set @logErrors = 1

        If @toolName In ('MaxQuant', 'MSFragger')
        Begin -- <MaxQuant_MSFragger>
            Declare @paramFileStoragePath varchar(128)

            SELECT @paramFileStoragePath = AJT_parmFileStoragePath
            FROM T_analysis_tool
            WHERE AJT_toolName = @toolName
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                RAISERROR ('Tool %s not found in T_analysis_tool', 11, 9, @toolName)

            CREATE TABLE #Tmp_SettingsFile_Values_DataPkgJob (
                KeyName varchar(512) NULL,
                Value varchar(512) NULL
            )

            -- Populate the temporary Table by parsing the XML in the Contents column of table T_Settings_Files
            INSERT INTO #Tmp_SettingsFile_Values_DataPkgJob (KeyName, Value)
            SELECT xmlNode.value('@key', 'nvarchar(512)') AS KeyName,
                   xmlNode.value('@value', 'nvarchar(512)') AS Value
            FROM T_Settings_Files cross apply Contents.nodes('//item') AS R(xmlNode)
            WHERE (File_Name = @settingsFileName) AND (Analysis_Tool = @toolName)

            Declare @createMzMLFilesFlag varchar(12) = 'False'
            Declare @msXmlGenerator varchar(64) = ''
            Declare @msXMLOutputType varchar(32) = ''
            Declare @centroidMSXML varchar(12) = ''
            Declare @centroidPeakCountToRetain varchar(12) = ''
            Declare @cacheFolderRootPath varchar(128) = ''
            Declare @msFraggerJavaMemorySize varchar(24) = ''
            Declare @databaseSplitCount varchar(24) = ''
            Declare @matchBetweenRuns varchar(24) = ''
            Declare @autoDefineExperimentGroupWithDatasetName varchar(24) = ''
            Declare @autoDefineExperimentGroupWithExperimentName varchar(24) = ''
            Declare @runPeptideProphet varchar(24) = ''
            Declare @runProteinProphet varchar(24) = ''
            Declare @runPercolator varchar(24) = ''
            Declare @generatePeptideLevelSummary varchar(24) = ''
            Declare @generateProteinLevelSummary varchar(24) = ''
            Declare @ms1QuantDisabled varchar(24) = ''
            Declare @runFreeQuant varchar(24) = ''
            Declare @runIonQuant varchar(24) = ''
            Declare @reporterIonMode varchar(24) = ''
            Declare @featureDetectionMZTolerance varchar(24) = ''
            Declare @featureDetectionRTTolerance varchar(24) = ''
            Declare @mbrMinimumCorrelation varchar(24) = ''
            Declare @mbrRTTolerance varchar(24) = ''
            Declare @mbrIonFdr varchar(24) = ''
            Declare @mbrPeptideFdr varchar(24) = ''
            Declare @mbrProteinFdr varchar(24) = ''
            Declare @normalizeIonIntensities varchar(24) = ''
            Declare @minIonsForProteinQuant varchar(24) = ''

            SELECT @msXmlGenerator = Value
            FROM #Tmp_SettingsFile_Values_DataPkgJob
            WHERE KeyName = 'MSXMLGenerator'

            SELECT @msXMLOutputType = Value
            FROM #Tmp_SettingsFile_Values_DataPkgJob
            WHERE KeyName = 'MSXMLOutputType'

            SELECT @centroidMSXML = Value
            FROM #Tmp_SettingsFile_Values_DataPkgJob
            WHERE KeyName = 'CentroidMSXML'

            SELECT @centroidPeakCountToRetain = Value
            FROM #Tmp_SettingsFile_Values_DataPkgJob
            WHERE KeyName = 'CentroidPeakCountToRetain'

            SELECT @cacheFolderRootPath = Value
            FROM #Tmp_SettingsFile_Values_DataPkgJob
            WHERE KeyName = 'CacheFolderRootPath'

            If @toolName = 'MSFragger'
            Begin
                SELECT @msFraggerJavaMemorySize = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MSFraggerJavaMemorySize'

                SELECT @databaseSplitCount = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'DatabaseSplitCount'

                SELECT @matchBetweenRuns = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MatchBetweenRuns'

                SELECT @autoDefineExperimentGroupWithDatasetName = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'AutoDefineExperimentGroupWithDatasetName'

                SELECT @autoDefineExperimentGroupWithExperimentName = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'AutoDefineExperimentGroupWithExperimentName'

                SELECT @runPeptideProphet = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'RunPeptideProphet'

                SELECT @runProteinProphet = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'RunProteinProphet'

                SELECT @runPercolator = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'RunPercolator'

                SELECT @generatePeptideLevelSummary = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'GeneratePeptideLevelSummary'

                SELECT @generateProteinLevelSummary = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'GenerateProteinLevelSummary'

                SELECT @ms1QuantDisabled = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MS1QuantDisabled'

                SELECT @runFreeQuant = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'RunFreeQuant'

                SELECT @runIonQuant = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'RunIonQuant'

                SELECT @reporterIonMode = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'ReporterIonMode'

                SELECT @featureDetectionMZTolerance = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'FeatureDetectionMZTolerance'

                SELECT @featureDetectionRTTolerance = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'FeatureDetectionRTTolerance'

                SELECT @mbrMinimumCorrelation = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MbrMinimumCorrelation'

                SELECT @mbrRTTolerance = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MbrRTTolerance'

                SELECT @mbrIonFdr = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MbrIonFdr'

                SELECT @mbrPeptideFdr = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MbrPeptideFdr'

                SELECT @mbrProteinFdr = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MbrProteinFdr'

                SELECT @normalizeIonIntensities = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'NormalizeIonIntensities'

                SELECT @minIonsForProteinQuant = Value
                FROM #Tmp_SettingsFile_Values_DataPkgJob
                WHERE KeyName = 'MinIonsForProteinQuant'
            End

            If Len(@msXmlGenerator) > 0 And Len(@msXMLOutputType) > 0 And @msXmlGenerator <> 'skip'
            Begin
                Set @createMzMLFilesFlag= 'True'
            End

            If Len(@cacheFolderRootPath) = 0
            Begin
                RAISERROR ('%s settings file is missing parameter CacheFolderRootPath', 11, 9, @toolName)
            End

            ---------------------------------------------------
            -- Add (or preview) a new aggregation job for data package @dataPackageID
            ---------------------------------------------------
            --
            Declare @pipelineJob int = 0
            Declare @resultsFolderName varchar(128)
            Declare @jobParam varchar(8000) =    -- TODO: Remove parameter named 'DatasetNum'
               '<Param Section="JobParameters" Name="CreateMzMLFiles" Value="' + @createMzMLFilesFlag + '" />
                <Param Section="JobParameters" Name="DatasetNum" Value="Aggregation" />
                <Param Section="JobParameters" Name="DatasetName" Value="Aggregation" />
                <Param Section="JobParameters" Name="CacheFolderRootPath" Value="' + @cacheFolderRootPath + '" />
                <Param Section="JobParameters" Name="SettingsFileName" Value="' + @settingsFileName + '" />
                <Param Section="MSXMLGenerator" Name="MSXMLGenerator" Value="' + @msXmlGenerator + '" />
                <Param Section="MSXMLGenerator" Name="MSXMLOutputType" Value="' + @msXMLOutputType + '" />
                <Param Section="MSXMLGenerator" Name="CentroidMSXML" Value="' + @centroidMSXML + '" />
                <Param Section="MSXMLGenerator" Name="CentroidPeakCountToRetain" Value="' + @centroidPeakCountToRetain + '" />
                <Param Section="PeptideSearch" Name="ParamFileName" Value="' + @paramFileName + ' " />
                <Param Section="PeptideSearch" Name="ParamFileStoragePath" Value="' + @paramFileStoragePath + '" />
                <Param Section="PeptideSearch" Name="OrganismName" Value="' + @organismName + ' " />
                <Param Section="PeptideSearch" Name="ProteinCollectionList" Value="' + @protCollNameList + '" />
                <Param Section="PeptideSearch" Name="ProteinOptions" Value="' +  @protCollOptionsList + '" />
                <Param Section="PeptideSearch" Name="LegacyFastaFileName" Value="' + @organismDBName + '" />'

            If @toolName = 'MSFragger'
            Begin
                If Coalesce(@msFraggerJavaMemorySize, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="MSFragger" Name="MSFraggerJavaMemorySize" Value="' + @msFraggerJavaMemorySize + '" />'
                End

                If Coalesce(@databaseSplitCount, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="MSFragger" Name="DatabaseSplitCount" Value="' + @databaseSplitCount + '" />'
                End

                If Coalesce(@matchBetweenRuns, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="MatchBetweenRuns" Value="' + @matchBetweenRuns + '" />'
                End

                If Coalesce(@autoDefineExperimentGroupWithDatasetName, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="AutoDefineExperimentGroupWithDatasetName" Value="' + @autoDefineExperimentGroupWithDatasetName + '" />'
                End

                If Coalesce(@autoDefineExperimentGroupWithExperimentName, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="AutoDefineExperimentGroupWithExperimentName" Value="' + @autoDefineExperimentGroupWithExperimentName + '" />'
                End

                If Coalesce(@runPeptideProphet, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="RunPeptideProphet" Value="' + @runPeptideProphet + '" />'
                End

                If Coalesce(@runProteinProphet, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="RunProteinProphet" Value="' + @runProteinProphet + '" />'
                End

                If Coalesce(@runPercolator, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="RunPercolator" Value="' + @runPercolator + '" />'
                End

                If Coalesce(@generatePeptideLevelSummary, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="GeneratePeptideLevelSummary" Value="' + @generatePeptideLevelSummary + '" />'
                End

                If Coalesce(@generateProteinLevelSummary, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="GenerateProteinLevelSummary" Value="' + @generateProteinLevelSummary + '" />'
                End

                If Coalesce(@ms1QuantDisabled, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="MS1QuantDisabled" Value="' + @ms1QuantDisabled + '" />'
                End

                If Coalesce(@runFreeQuant, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="RunFreeQuant" Value="' + @runFreeQuant + '" />'
                End

                If Coalesce(@runIonQuant, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="RunIonQuant" Value="' + @runIonQuant + '" />'
                End

                If Coalesce(@reporterIonMode, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="Philosopher" Name="ReporterIonMode" Value="' + @reporterIonMode + '" />'
                End

                If Coalesce(@featureDetectionMZTolerance, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="IonQuant" Name="FeatureDetectionMZTolerance" Value="' + @featureDetectionMZTolerance + '" />'
                End

                If Coalesce(@featureDetectionRTTolerance, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="IonQuant" Name="FeatureDetectionRTTolerance" Value="' + @featureDetectionRTTolerance + '" />'
                End

                If Coalesce(@mbrMinimumCorrelation, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="IonQuant" Name="MbrMinimumCorrelation" Value="' + @mbrMinimumCorrelation + '" />'
                End

                If Coalesce(@mbrRTTolerance, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="IonQuant" Name="MbrRTTolerance" Value="' + @mbrRTTolerance + '" />'
                End

                If Coalesce(@mbrIonFdr, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="IonQuant" Name="MbrIonFdr" Value="' + @mbrIonFdr + '" />'
                End

                If Coalesce(@mbrPeptideFdr, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="IonQuant" Name="MbrPeptideFdr" Value="' + @mbrPeptideFdr + '" />'
                End

                If Coalesce(@mbrProteinFdr, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="IonQuant" Name="MbrProteinFdr" Value="' + @mbrProteinFdr + '" />'
                End

                If Coalesce(@normalizeIonIntensities, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="IonQuant" Name="NormalizeIonIntensities" Value="' + @normalizeIonIntensities + '" />'
                End

                If Coalesce(@minIonsForProteinQuant, '') <> ''
                Begin
                    Set @jobParam = @jobParam +
                    '<Param Section="IonQuant" Name="MinIonsForProteinQuant" Value="' + @minIonsForProteinQuant + '" />'
                End
            End

            If @mode <> 'add'
            Begin
                Set @mode = 'previewAdd'
            End

            Declare @scriptName varchar(64) = 'Undefined_Script'

            If @toolName = 'MaxQuant'
            Begin
                Set @scriptName = 'MaxQuant_DataPkg'
            End

            If @toolName = 'MSFragger'
            Begin
                Set @scriptName = 'MSFragger_DataPkg'
            End

            -- Call add_update_local_job_in_broker
            exec @myError = dbo.s_pipeline_add_update_local_job
                                @job = @pipelineJob output,
                                @scriptName = @scriptName,
                                @datasetName = 'Aggregation',
                                @priority = @priority,
                                @jobParam = @jobParam,
                                @comment = @comment,
                                @ownerUsername = @ownerUsername,
                                @dataPackageID = @dataPackageID,
                                @resultsFolderName = @resultsFolderName output,
                                @mode = @mode,
                                @message = @message output,
                                @callingUser = @callingUser,
                                @debugMode = 0

            if @myError <> 0
            Begin
                Set @msgForLog = 'Error code ' + Cast(@myError as varchar(12)) + ' s_pipeline_add_update_local_job: ' + Coalesce(@message, '??')
                exec post_log_entry 'Error', @msgForLog, 'add_analysis_job_group'
            End

            If @myError = 0 And @pipelineJob > 0
            Begin
                -- Insert details for the job into T_Analysis_Job
                exec @backfillError = dbo.backfill_pipeline_jobs @infoOnly = 0, @jobsToProcess = 0, @startJob = @pipelineJob, @message = @msgForLog output

                If @backfillError = 0
                Begin
                    -- Associate the new job with this job request
                    -- Also update settings file, parameter file, protein collection, etc.
                    --
                    UPDATE T_Analysis_Job
                    SET AJ_requestID = @requestID,
                        AJ_settingsFileName = @settingsFileName,
                        AJ_parmFileName = @paramFileName,
                        AJ_organismID = @organismID,
                        AJ_proteinCollectionList = @protCollNameList,
                        AJ_proteinOptionsList = @protCollOptionsList,
                        AJ_organismDBName = @organismDBName
                    WHERE AJ_jobID = @pipelineJob
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                End
                Else
                Begin
                    Set @msgForLog = 'Error code ' + Cast(@backfillError as varchar(12)) + ' calling backfill_pipeline_jobs: ' + Coalesce(@msgForLog, '??')
                    exec post_log_entry 'Error', @msgForLog, 'add_analysis_job_group'
                End
            End

        End -- </MaxQuant_MSFragger>

        If @myError = 0 And @mode = 'add'
        Begin
            ---------------------------------------------------
            -- Mark request as used
            ---------------------------------------------------
            --
            Set @requestStateID = 2

            UPDATE T_Analysis_Job_Request
            SET AJR_state = @requestStateID
            WHERE AJR_requestID = @requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Update operation failed setting state to %d for request %d', 11, 8, @requestStateID, @requestID)

            If Len(@callingUser) > 0
            Begin
                -- @callingUser is defined; call alter_event_log_entry_user or alter_event_log_entry_user_multi_id
                -- to alter the Entered_By field in T_Event_Log
                --
                Exec alter_event_log_entry_user 12, @requestID, @requestStateID, @callingUser
            End

            Set @message = ' Created aggregation job ' + Cast(@pipelineJob as varchar(12)) + ' for '
        End
        Else
        Begin
            If @myError = 0
            Begin
                Set @message = ' Would create an aggregation job for '
            End
        End

        If @myError = 0
        Begin
            Set @message = @message + CONVERT(varchar(12), @jobCountToBeCreated) + ' datasets'
        End

        Return @myError
    End

    If @mode = 'add'
    Begin -- <add>

        If @jobCountToBeCreated = 0 AND @datasetCountToRemove > 0
            RAISERROR ('No jobs were made for request %d because there were existing jobs for all datasets in the list', 11, 94, @requestID)

        ---------------------------------------------------
        -- Start transaction
        ---------------------------------------------------
        --
        Declare @transName varchar(32)
        Set @transName = 'add_analysis_job_group'
        Begin transaction @transName

        ---------------------------------------------------
        -- create a new batch if multiple jobs being created
        ---------------------------------------------------
        Declare @batchID int = 0
        --
        Declare @numDatasets int = 0

        SELECT @numDatasets = count(*) FROM #TD
        --
        If @numDatasets = 0
            RAISERROR ('No datasets in list to create jobs for request %d', 11, 17, @requestID)
        --
        If @numDatasets > 1
        Begin
            INSERT INTO T_Analysis_Job_Batches
                (Batch_Description)
            VALUES ('Auto')
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Error trying to create new batch when making jobs for request %d', 11, 7, @requestID)

            -- return ID of newly created batch
            --
            Set @batchID = SCOPE_IDENTITY()
        End

        ---------------------------------------------------
        -- Deal with request
        ---------------------------------------------------
        --
        If @requestID = 0
        Begin
            Set @requestID = 1 -- for the default request
        End
        Else
        Begin
            -- make sure @requestID is in state 1=new or state 5=new (Review Required)

            SELECT @requestStateID = AJR_State
            FROM T_Analysis_Job_Request
            WHERE AJR_RequestID = @requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
                RAISERROR ('Error looking up request state in T_Analysis_Job_Request for request %d', 11, 7, @requestID)

            Set @requestStateID = Coalesce(@requestStateID, 0)

            If @requestStateID IN (1, 5)
            Begin
                -- Mark request as used
                --
                Set @requestStateID = 2

                UPDATE T_Analysis_Job_Request
                SET AJR_state = @requestStateID
                WHERE AJR_requestID = @requestID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                    RAISERROR ('Update operation failed setting state to %d for request %d', 11, 8, @requestStateID, @requestID)

                If Len(@callingUser) > 0
                Begin
                    -- @callingUser is defined; call alter_event_log_entry_user or alter_event_log_entry_user_multi_id
                    -- to alter the Entered_By field in T_Event_Log
                    --
                    Exec alter_event_log_entry_user 12, @requestID, @requestStateID, @callingUser
                End
            End
            Else
            Begin
                -- Request ID is non-zero and request is not in state 1 or state 5
                RAISERROR ('Request is not in state New; cannot create jobs for request %d', 11, 9, @requestID)
            End
        End

        ---------------------------------------------------
        -- Get new job number for every dataset
        -- in temporary table
        ---------------------------------------------------

        -- Stored procedure get_new_job_id_block will populate #TmpNewJobIDs
        CREATE TABLE #TmpNewJobIDs (ID int)

        exec @myError = get_new_job_id_block @numDatasets, 'Job created in DMS'
        If @myError <> 0
            RAISERROR ('Error obtaining block of Job IDs', 11, 10)

        -- Use the job number information in #TmpNewJobIDs to update #TD
        -- If we know the first job number in #TmpNewJobIDs, then we can use
        --  the Row_Number() function to update #TD

        Set @jobIDStart = 0
        Set @jobIDEnd = 0

        SELECT @jobIDStart = MIN(ID),
               @jobIDEnd = MAX(ID)
        FROM #TmpNewJobIDs

        -- Make sure @jobIDStart and @jobIDEnd define a contiguous block of jobs
        If @jobIDEnd - @jobIDStart + 1 <> @numDatasets
            RAISERROR ('get_new_job_id_block did not return a contiguous block of jobs; requested %d jobs but job range is %d to %d', 11, 11, @numDatasets, @jobIDStart, @jobIDEnd)

        -- The JobQ subquery uses Row_Number() and @jobIDStart to define the new job numbers for each entry in #TD
        UPDATE #TD
        SET Job = JobQ.ID
        FROM #TD
             INNER JOIN ( SELECT Dataset_ID,
                                 Row_Number() OVER ( ORDER BY Dataset_ID ) + @jobIDStart - 1 AS ID
                          FROM #TD ) JobQ
               ON #TD.Dataset_ID = JobQ.Dataset_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        ---------------------------------------------------
        -- insert a new job in analysis job table for
        -- every dataset in temporary table
        ---------------------------------------------------
        --
        INSERT INTO T_Analysis_Job (
            AJ_jobID,
            AJ_priority,
            AJ_created,
            AJ_analysisToolID,
            AJ_parmFileName,
            AJ_settingsFileName,
            AJ_organismDBName,
            AJ_proteinCollectionList,
            AJ_proteinOptionsList,
            AJ_organismID,
            AJ_datasetID,
            AJ_comment,
            AJ_specialProcessing,
            AJ_owner,
            AJ_batchID,
            AJ_StateID,
            AJ_requestID,
            AJ_propagationMode,
            AJ_DatasetUnreviewed
        ) SELECT
            Job,
            @priority,
            getdate(),
            @analysisToolID,
            @paramFileName,
            @settingsFileName,
            @organismDBName,
            @protCollNameList,
            @protCollOptionsList,
            @organismID,
            #TD.Dataset_ID,
            REPLACE(@comment, '#DatasetNum#', CONVERT(varchar(12), #TD.Dataset_ID)),
            @specialProcessing,
            @ownerUsername,
            @batchID,
            @jobStateID,
            @requestID,
            @propMode,
            Coalesce(Dataset_Unreviewed, 1)
        FROM #TD
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            -- set request status to 'incomplete'
            If @requestID > 1
            Begin
                Set @requestStateID = 4

                UPDATE    T_Analysis_Job_Request
                SET        AJR_state = @requestStateID
                WHERE    AJR_requestID = @requestID

                If Len(@callingUser) > 0
                Begin
                    -- @callingUser is defined; call alter_event_log_entry_user or alter_event_log_entry_user_multi_id
                    -- to alter the Entered_By field in T_Event_Log
                    --
                    Exec alter_event_log_entry_user 12, @requestID, @requestStateID, @callingUser
                End
            End
            --
            RAISERROR ('Insert new job operation failed', 11, 7)
        End
        --
        Set @jobCountToBeCreated = @myRowCount

        If @batchID = 0 AND @myRowCount = 1
        Begin
            -- Added a single job; cache the jobID value
            Set @jobID = SCOPE_IDENTITY()
        End
        /*
        ---------------------------------------------------
        -- Deprecated in May 2015: create associations with processor group for new
        -- jobs, if group ID is given
        ---------------------------------------------------

        If @gid <> 0
        Begin
            -- if single job was created, get its identity directly
            --
            If @batchID = 0 AND @myRowCount = 1
            Begin
                INSERT INTO T_Analysis_Job_Processor_Group_Associations
                    (Job_ID, Group_ID)
                VALUES
                    (@jobID, @gid)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            --
            -- if multiple jobs were created, get job identities
            -- from all jobs using new batch ID
            --
            If @batchID <> 0 AND @myRowCount >= 1
            Begin
                INSERT INTO T_Analysis_Job_Processor_Group_Associations
                    (Job_ID, Group_ID)
                SELECT
                    AJ_jobID, @gid
                FROM
                    T_Analysis_Job
                WHERE
                    (AJ_batchID = @batchID)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End
            --
            If @myError <> 0
                RAISERROR ('Error Associating job with processor group', 11, 7)
        End
        */

        commit transaction @transName

        If @requestID > 1
        Begin
            -------------------------------------------------
            -- Update the AJR_jobCount field for this job request
            -------------------------------------------------

            UPDATE T_Analysis_Job_Request
            SET AJR_jobCount = StatQ.JobCount
            FROM T_Analysis_Job_Request AJR
                INNER JOIN ( SELECT AJR.AJR_requestID,
                                    SUM(CASE WHEN AJ.AJ_jobID IS NULL
                                             THEN 0
                                             ELSE 1
                                        END) AS JobCount
                            FROM T_Analysis_Job_Request AJR
                                INNER JOIN T_Users U
                                    ON AJR.AJR_requestor = U.ID
                                INNER JOIN T_Analysis_Job_Request_State AJRS
                                    ON AJR.AJR_state = AJRS.ID
                                INNER JOIN T_Organisms Org
                                    ON AJR.AJR_organism_ID = Org.Organism_ID
                                LEFT OUTER JOIN T_Analysis_Job AJ
                                    ON AJR.AJR_requestID = AJ.AJ_requestID
                            WHERE AJR.AJR_requestID = @requestID
                            GROUP BY AJR.AJR_requestID
                            ) StatQ
                ON AJR.AJR_requestID = StatQ.AJR_requestID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Exec update_cached_job_request_existing_jobs @processingMode = 0, @requestId = @requestId, @infoOnly = 0

        End

        If Len(@callingUser) > 0
        Begin
            -- @callingUser is defined; call alter_event_log_entry_user or alter_event_log_entry_user_multi_id
            -- to alter the Entered_By field in T_Event_Log
            --
            If @batchID = 0
                Exec alter_event_log_entry_user 5, @jobID, @jobStateID, @callingUser
            Else
            Begin
                -- Populate a temporary table with the list of Job IDs just created
                CREATE TABLE #TmpIDUpdateList (
                    TargetID int NOT NULL
                )

                CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)

                INSERT INTO #TmpIDUpdateList (TargetID)
                SELECT DISTINCT AJ_jobID
                FROM T_Analysis_Job
                WHERE AJ_batchID = @batchID

                Exec alter_event_log_entry_user_multi_id 5, @jobStateID, @callingUser, @EntryTimeWindowSeconds=45
            End
        End
    End -- </add>

    ---------------------------------------------------
    -- build message
    ---------------------------------------------------
Explain:
    If @jobCountToBeCreated = 1
    Begin
        If @mode = 'add'
            Set @message = ' There was 1 job created.'
        Else
            Set @message = ' There would be 1 job created.'
    End
    Else
    Begin
        If @mode = 'add'
            Set @message = ' There were '
        Else
            Set @message = ' There would be '

        Set @message = @message + CONVERT(varchar(12), @jobCountToBeCreated) + ' jobs created.'
    End

    If @datasetCountToRemove > 0
    Begin
        If @mode = 'add'
            Set @removedDatasets = ' Jobs were not made for ' + @removedDatasets
        Else
            Set @removedDatasets = ' Jobs would not be made for ' + @removedDatasets

        Set @message = @message + @removedDatasets
    End

    End Try
    Begin Catch
        EXEC format_error_message @message output, @myError output

        Set @msgForLog = ERROR_MESSAGE()

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec post_log_entry 'Error', @msgForLog, 'add_analysis_job_group'
        End
    End Catch

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_analysis_job_group] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_analysis_job_group] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_analysis_job_group] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_analysis_job_group] TO [Limited_Table_Write] AS [dbo]
GO
