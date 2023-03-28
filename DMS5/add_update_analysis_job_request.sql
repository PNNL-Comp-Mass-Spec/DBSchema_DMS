/****** Object:  StoredProcedure [dbo].[add_update_analysis_job_request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_analysis_job_request]
/****************************************************
**
**  Desc:
**      Adds new analysis job request to request queue
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/9/2003
**          02/11/2006 grk - added validation for tool compatibility
**          03/28/2006 grk - added protein collection fields
**          04/04/2006 grk - increased sized of param file name
**          04/04/2006 grk - modified to use validate_analysis_job_parameters
**          04/10/2006 grk - widened size of list argument to 6000 characters
**          04/11/2006 grk - modified logic to allow changing name of exising request
**          08/31/2006 grk - restored apparently missing prior modification http://prismtrac.pnl.gov/trac/ticket/217
**          10/16/2006 jds - added support for work package number
**          10/16/2006 mem - updated to force @state to 'new' if @mode = 'add'
**          11/13/2006 mem - Now calling validate_protein_collection_list_for_datasets to validate @protCollNameList
**          11/30/2006 mem - Added column Dataset_Type to #TD (Ticket:335)
**          12/20/2006 mem - Added column DS_rating to #TD (Ticket:339)
**          01/26/2007 mem - Switched to organism ID instead of organism name (Ticket:368)
**          05/22/2007 mem - Updated to prevent addition of duplicate datasets to  (Ticket:481)
**          10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**          01/17/2008 grk - Modified error codes to help debugging DMS2.  Also had to add explicit NULL column attribute to #TD
**          02/22/2008 mem - Updated to convert @comment to '' if null (Ticket:648, http://prismtrac.pnl.gov/trac/ticket/648)
**          09/12/2008 mem - Now passing @paramFileName and @settingsFileName ByRef to validate_analysis_job_parameters (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**          09/24/2008 grk - Increased size of comment argument (and column in database)(Ticket:692, http://prismtrac.pnl.gov/trac/ticket/692)
**          12/02/2008 grk - Disallow editing unless in "New" state
**          09/19/2009 grk - Added field to request admin review (Ticket #747, http://prismtrac.pnl.gov/trac/ticket/747)
**          09/19/2009 grk - Allowed updates from any state
**          09/22/2009 grk - changed state "review_required" to "New (Review Required)"
**          09/22/2009 mem - Now setting state to "New (Review Required)" if @State = 'new' and @adminReviewReqd='Yes'
**          10/02/2009 mem - Revert to only allowing updates if the state is "New" or "New (Review Required)"
**          02/12/2010 mem - Now assuring that rating is not -5 (note: when converting a job request to jobs, you can manually add datasets with a rating of -5; procedure add_analysis_job_group will allow them to be included)
**          04/21/2010 grk - try-catch for error handling
**          05/05/2010 mem - Now passing @requestorUsername to validate_analysis_job_parameters as input/output
**          05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**          03/21/2011 mem - Expanded @datasets to varchar(max) and @requestName to varchar(128)
**                         - Now using SCOPE_IDENTITY() to determine the ID of the newly added request
**          03/29/2011 grk - added @specialProcessing argument (http://redmine.pnl.gov/issues/304)
**          05/16/2011 mem - Now auto-removing duplicate datasets and auto-formatting @datasets
**          04/02/2012 mem - Now auto-removing datasets named 'Dataset' or 'Dataset_Num' in @datasets
**          05/15/2012 mem - Added @organismDBName
**          07/16/2012 mem - Now auto-changing @protCollOptionsList to "seq_direction=forward,filetype=fasta" if the tool is MSGFDB and the options start with "seq_direction=decoy"
**          07/24/2012 mem - Now allowing @protCollOptionsList to be "seq_direction=decoy,filetype=fasta" for MSGFDB searches where the parameter file name contains "_NoDecoy"
**          09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**          11/05/2012 mem - Now auto-changing the settings file from FinniganDefSettings.xml to FinniganDefSettings_DeconMSN.xml if the request contains HMS% datasets
**          11/05/2012 mem - Now disallowing mixing low res MS datasets with high res HMS dataset
**          11/12/2012 mem - Moved dataset validation logic to validate_analysis_job_request_datasets
**          11/14/2012 mem - Now assuring that @toolName is properly capitalized
**          11/20/2012 mem - Removed parameter @workPackage
**          12/13/2013 mem - Updated @mode to support 'PreviewAdd'
**          01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**          03/05/2013 mem - Added parameter @autoRemoveNotReleasedDatasets, which is passed to validate_analysis_job_parameters
**          03/26/2013 mem - Added parameter @callingUser
**          04/09/2013 mem - Now automatically updating the settings file to the MSConvert equivalent if processing QExactive data
**          05/22/2013 mem - Now preventing an update of analysis job requests only if they have existing analysis jobs (previously would examine AJR_state in T_Analysis_Job_Request)
**          06/10/2013 mem - Now filtering on Analysis_Tool when checking whether an HMS_AutoSupersede file exists for the given settings file
**          03/28/2014 mem - Auto-changing @protCollOptionsList to "seq_direction=decoy,filetype=fasta" if the tool is MODa and the options start with "seq_direction=forward"
**          03/30/2015 mem - Now passing @toolName to auto_update_settings_file_to_centroid
**                         - Now using T_Dataset_Info.ProfileScanCount_MSn to look for datasets with profile-mode MS/MS spectra
**          04/08/2015 mem - Now passing @autoUpdateSettingsFileToCentroided=0 to validate_analysis_job_parameters
**          10/09/2015 mem - Now allowing the request name and comment to be updated even if a request has associated jobs
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/11/2016 mem - Disabled forcing use of MSConvert for QExactive datasets
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          11/23/2016 mem - Include the request name when calling post_log_entry from within the catch block
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2017 mem - Set @allowNewDatasets to 1 when calling validate_analysis_job_parameters
**          05/23/2018 mem - Do not allow @requestorUsername to be the autouser (login H09090911)
**          06/12/2018 mem - Send @maxLength to append_to_text
**          04/17/2019 mem - Auto-change @protCollOptionsList to "seq_direction=forward,filetype=fasta" when running TopPIC
**          04/23/2019 mem - Auto-change @protCollOptionsList to "seq_direction=decoy,filetype=fasta" when running MSFragger
**          07/30/2019 mem - Store dataset info in T_Analysis_Job_Request_Datasets instead of AJR_datasets
**                         - Call update_cached_job_request_existing_jobs after creating / updating an analysis job request
**          05/28/2020 mem - Auto-update the settings file if the samples used TMTpro
**          03/10/2021 mem - Add @dataPackageID and remove @adminReviewReqd
**          05/28/2021 mem - Add @mode 'append', which can be be used to add additional datasets to an existing analysis job request, regardless of state
**                         - When using append mode, optionally Set @state to 'new' to also reset the state
**          10/15/2021 mem - Require that @dataPackageID be defined when using a match between runs parameter file for MaxQuant and MSFragger
**          03/10/2022 mem - Replace spaces and tabs in the dataset list with commas
**          05/23/2022 mem - Rename requester argument
**          06/30/2022 mem - Rename parameter file argument
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/22/2023 mem - Rename column in temp table
**                         - Also auto-remove datasets named 'Dataset Name' and 'Dataset_Name' from #TD
**          03/27/2023 mem - Add support for DIA-NN and synchronize protein collection options validation with add_analysis_job_group
**
*****************************************************/
(
    @datasets varchar(max),
    @requestName varchar(128),
    @toolName varchar(64),
    @paramFileName varchar(255),
    @settingsFileName varchar(255),
    @protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
    @organismName varchar(128),
    @organismDBName varchar(128) = 'na',        -- Legacy fasta file; typically 'na'
    @requesterUsername varchar(32),
    @comment varchar(512) = null,
    @specialProcessing varchar(512) = null,
    @dataPackageID int = 0,
    @state varchar(32),                         -- Includes 'new', 'used', and 'inactive' (see T_Analysis_Job_Request_State)
    @requestID int output,
    @mode varchar(12) = 'add',                  -- 'add', 'update', 'append', or 'PreviewAdd'
    @message varchar(512) output,
    @autoRemoveNotReleasedDatasets tinyint = 0,
    @callingUser varchar(128)=''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError INT = 0
    Declare @myRowCount INT = 0

    Declare @AutoSupersedeName varchar(255) = ''
    Declare @MsgToAppend varchar(255)
    Declare @logErrors tinyint = 0
    Declare @datasetMin varchar(128) = null
    Declare @datasetMax varchar(128) = NULL

    Declare @tmtProDatasets int = 0
    Declare @datasetCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_analysis_job_request', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @requestName = Coalesce(@requestName, '')
    Set @comment = Coalesce(@comment, '')

    Set @message = ''

    Declare @msg varchar(512)

    If @requestName = ''
        RAISERROR ('Cannot add: request name cannot be blank', 11, 4)

    Set @requesterUsername = Ltrim(Rtrim(Coalesce(@requesterUsername, '')))

    If @requesterUsername = 'H09090911' Or @requesterUsername = 'Autouser'
        RAISERROR ('Cannot add: the "Requested by" username cannot be the Autouser', 11, 4)

    Set @dataPackageID = Coalesce(@dataPackageID, 0)
    If @dataPackageID < 0
        Set @dataPackageID = 0

    Set @datasets = LTrim(RTrim(Coalesce(@datasets, '')))
    Set @datasets = Replace(Replace(@datasets, ' ', ','), Char(9), ',')

    ---------------------------------------------------
    -- Resolve mode against presence or absence
    -- of request in database, and its current state
    ---------------------------------------------------

    Declare @hit int
    Declare @curState int

    -- Cannot create an entry with a duplicate name
    --
    If @mode IN ('add', 'PreviewAdd')
    Begin
        IF Exists (SELECT AJR_requestID FROM T_Analysis_Job_Request WHERE AJR_requestName = @requestName)
            RAISERROR ('Cannot add: request with same name already in database', 11, 4)
    End

    -- Cannot update a non-existent entry
    -- If the entry already exists and has jobs associated with it, only allow for updating the comment field
    --
    If @mode = 'update'
    Begin
        Set @hit = 0
        SELECT @hit = AJR_requestID,
               @curState = AJR_state
        FROM T_Analysis_Job_Request
        WHERE (AJR_requestID = @requestID)
        --
        If @hit = 0
            RAISERROR ('Cannot update: entry is not in database', 11, 5)

        If Exists (Select * From T_Analysis_Job Where AJ_RequestID = @requestID)
        Begin
            -- The request has jobs associated with it

            Declare @currentName varchar(128)
            Declare @currentComment varchar(512)

            SELECT @currentName = AJR_requestName,
                   @currentComment = AJR_comment
            FROM T_Analysis_Job_Request
            WHERE (AJR_requestID = @requestID)

            If @currentName <> @requestName OR @currentComment <> @comment
            Begin
                UPDATE T_Analysis_Job_Request
                SET AJR_requestName = @requestName,
                    AJR_comment = @comment
                WHERE (AJR_requestID = @requestID)

                If @currentName <> @requestName AND @currentComment <> @comment
                    Set @message = 'Updated the request name and comment'
                Else
                Begin
                    If @currentName <> @requestName
                        Set @message = 'Updated the request name'

                    If @currentComment <> @comment
                        Set @message = 'Updated the request comment'
                End

                Goto Done
            End
            Else
            Begin
                RAISERROR ('Entry has analysis jobs associated with it; only the comment and name can be updated', 11, 24)
            End
        End
    End

    ---------------------------------------------------
    -- We either need datasets or a data package
    ---------------------------------------------------

    If @dataPackageID > 0 And @datasets <> ''
        RAISERROR ('Dataset list must be empty when a Data Package ID is defined', 11, 1)

    If @dataPackageID = 0 And @datasets = ''
        RAISERROR ('Dataset list is empty', 11, 1)

    ---------------------------------------------------
    -- Create temporary table to hold list of datasets
    -- This procedure populates column Dataset_Name
    -- Procedure validate_analysis_job_request_datasets (called by validate_analysis_job_parameters) will populate the remaining columns
    ---------------------------------------------------

    CREATE TABLE #TD (
        Dataset_Name varchar(128),
        Dataset_ID int NULL,
        IN_class varchar(64) NULL,
        DS_state_ID int NULL,
        AS_state_ID int NULL,
        Dataset_Type varchar(64) NULL,
        DS_rating smallint NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Failed to create temporary table', 11, 10)

    If @dataPackageID > 0
    Begin
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
        Set @datasetCount = @myRowCount
        --
        If @myError <> 0
            RAISERROR ('Error populating temporary table', 11, 8)

        If @datasetCount = 0
            RAISERROR ('Data package does not have any datasets associated with it', 11, 10)
    End
    Else
    Begin
        ---------------------------------------------------
        -- Populate table from dataset list
        -- Remove any duplicates that may be present
        ---------------------------------------------------
        --
        INSERT INTO #TD (Dataset_Name)
        SELECT DISTINCT Item
        FROM make_table_from_list (@datasets)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        Set @datasetCount = @myRowCount
        --
        If @myError <> 0
            RAISERROR ('Error populating temporary table', 11, 8)

        ---------------------------------------------------
        -- Auto-delete dataset column names from #TD
        ---------------------------------------------------
        --
        DELETE FROM #TD
        WHERE Dataset_Name IN ('Dataset', 'Dataset Name', 'Dataset_Name', 'Dataset_Num')
    End

    ---------------------------------------------------
    -- Find the first and last dataset in #TD
    ---------------------------------------------------
    --
    SELECT @myRowCount = Count(*)
    FROM #TD

    If @myRowCount = 1
    Begin
        SELECT @datasetMin = Min(Dataset_Name)
        FROM #TD
    End

    If @myRowCount > 1
    Begin
        SELECT @datasetMin = Min(Dataset_Name),
               @datasetMax = Max(Dataset_Name)
        FROM #TD
    End

    ---------------------------------------------------
    -- Create and populate the temporary table used by validate_protein_collection_list_for_dataset_table
    ---------------------------------------------------
    --
    CREATE TABLE #TmpDatasets (
        Dataset_Name varchar(128) Not NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Failed to create temporary table #TmpDatasets'
        RAISERROR (@msg, 11, 1)
        return 51007
    End

    CREATE UNIQUE CLUSTERED INDEX #IX_TmpDatasets ON #TmpDatasets
    (
        Dataset_Name
    )

    INSERT INTO #TmpDatasets( Dataset_Name )
    SELECT Dataset_Name
    FROM #TD
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Validate @protCollNameList
    -- Note that validate_protein_collection_list_for_dataset_table
    --  will populate @message with an explanatory note
    --  if @protCollNameList is updated
    ---------------------------------------------------
    --
    Declare @collectionCountAdded int
    Declare @result int
    Set @result = 0

    Set @protCollNameList = LTrim(RTrim(Coalesce(@protCollNameList, '')))
    If Len(@protCollNameList) > 0 And dbo.validate_na_parameter(@protCollNameList, 1) <> 'na'
    Begin
        exec @result = validate_protein_collection_list_for_dataset_table
                            @protCollNameList=@protCollNameList output,
                            @collectionCountAdded=@collectionCountAdded output,
                            @showMessages=1,
                            @message=@message output

        If @result <> 0
            return @result
    End

    ---------------------------------------------------
    -- Validate job parameters
    -- Note that validate_analysis_job_parameters calls validate_analysis_job_request_datasets
    -- and that validate_analysis_job_request_datasets populates Dataset_ID, etc. in #TD
    ---------------------------------------------------
    --
    Declare @userID int
    Declare @analysisToolID int
    Declare @organismID int
    --
    Set @result = 0
    --
    exec @result = validate_analysis_job_parameters
                            @toolName = @toolName,
                            @paramFileName = @paramFileName output,
                            @settingsFileName = @settingsFileName output,
                            @organismDBName = @organismDBName output,
                            @organismName = @organismName,
                            @protCollNameList = @protCollNameList output,
                            @protCollOptionsList = @protCollOptionsList output,
                            @ownerUsername = @requesterUsername output,
                            @mode = '', -- blank validation mode to suppress dataset state checking
                            @userID = @userID output,
                            @analysisToolID = @analysisToolID output,
                            @organismID = @organismID output,
                            @message = @msg output,
                            @autoRemoveNotReleasedDatasets = @autoRemoveNotReleasedDatasets,
                            @autoUpdateSettingsFileToCentroided = 0,
                            @allowNewDatasets = 1
    --
    If @result <> 0
        RAISERROR (@msg, 11, 8)


    ---------------------------------------------------
    -- Assure that @toolName is properly capitalized
    ---------------------------------------------------
    --
    SELECT @toolName = AJT_toolName
    FROM T_Analysis_Tool
    WHERE AJT_toolName = @toolName

    ---------------------------------------------------
    -- Assure that we are not running a decoy search if using MSGFPlus, TopPIC, or MaxQuant (since those tools auto-add decoys)
    -- However, if the parameter file contains _NoDecoy in the name, we'll allow @protCollOptionsList to contain Decoy
    ---------------------------------------------------
    --
    If (@toolName LIKE 'MSGFPlus%' Or @toolName LIKE 'TopPIC%' Or @toolName LIKE 'MaxQuant%' Or @toolName Like 'DiaNN%') And
       @protCollOptionsList Like '%decoy%' And
       @paramFileName Not Like '%[_]NoDecoy%'
    Begin
        Set @protCollOptionsList = 'seq_direction=forward,filetype=fasta'

        If Coalesce(@message, '') = '' And @toolName LIKE 'MSGFPlus%'
            Set @message = 'Note: changed protein options to forward-only since MS-GF+ parameter files typically have tda=1'

        If Coalesce(@message, '') = '' And @toolName LIKE 'TopPIC%'
            Set @message = 'Note: changed protein options to forward-only since TopPIC parameter files typically have Decoy=True'

        If Coalesce(@message, '') = '' And @toolName LIKE 'MaxQuant%'
            Set @message = 'Note: changed protein options to forward-only since MaxQuant parameter files typically have <decoyMode>revert</decoyMode>'

        If Coalesce(@message, '') = '' And @toolName LIKE 'DiaNN%'
            Set @message = 'Note: changed protein options to forward-only since DIA-NN expects the FASTA file to not have decoy proteins'
    End

    ---------------------------------------------------
    -- Assure that we are running a decoy search if using MODa or MSFragger
    -- However, if the parameter file contains _NoDecoy in the name, we'll allow @protCollOptionsList to contain Decoy
    ---------------------------------------------------
    --
    If (@toolName LIKE 'MODa%' Or @toolName LIKE 'MSFragger%') And @protCollOptionsList Like '%forward%' And @paramFileName Not Like '%[_]NoDecoy%'
    Begin
        Set @protCollOptionsList = 'seq_direction=decoy,filetype=fasta'

        If Coalesce(@message, '') = ''
            Set @message = 'Note: changed protein options to decoy since ' + @toolName + ' expects the FASTA file to have decoy proteins'
    End

    /*
     * Disabled in March 2016 because not always required
     *
    ---------------------------------------------------
    -- Auto-update the settings file if one or more HMS datasets are present
    -- but the user chose a settings file that is not appropriate for HMS datasets
    ---------------------------------------------------
    --
    IF EXISTS (SELECT * FROM #TD WHERE Dataset_Type LIKE 'hms%' OR Dataset_Type LIKE 'ims-hms%')
    Begin
        -- Possibly auto-update the settings file

        SELECT @AutoSupersedeName = HMS_AutoSupersede
        FROM T_Settings_Files
        WHERE [File_Name] = @settingsFileName AND
               Analysis_Tool = @toolName

        If Coalesce(@AutoSupersedeName, '') <> ''
        Begin
            Set @settingsFileName = @AutoSupersedeName

            Set @MsgToAppend = 'Note: Auto-updated the settings file to ' + @AutoSupersedeName + ' because one or more HMS datasets are included in this job request'
            Set @message = dbo.append_to_text(@message, @MsgToAppend, 0, ';', 512)
        End
    End
    */

    -- Declare @QExactiveDSCount int = 0
    Declare @ProfileModeMSnDatasets int = 0

    /*
     * Disabled in March 2016 because not always required
     *
    -- Count the number of QExactive datasets
    --
    SELECT @QExactiveDSCount = COUNT(*)
    FROM #TD
            INNER JOIN T_Dataset DS ON #TD.Dataset_Name = DS.Dataset_Num
            INNER JOIN T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
            INNER JOIN T_Instrument_Group InstGroup ON InstName.IN_Group = InstGroup.IN_Group
    WHERE InstGroup.IN_Group = 'QExactive'
    */

    -- Count the number of datasets with profile mode MS/MS
    --
    SELECT @ProfileModeMSnDatasets = Count(Distinct DS.Dataset_ID)
    FROM #TD
            INNER JOIN T_Dataset DS ON #TD.Dataset_Name = DS.Dataset_Num
            INNER JOIN T_Dataset_Info DI ON DS.Dataset_ID = DI.Dataset_ID
    WHERE DI.ProfileScanCount_MSn > 0

    If @ProfileModeMSnDatasets > 0
    Begin
        -- Auto-update the settings file since we have one or more Q Exactive datasets or one or more datasets with profile-mode MS/MS spectra
        Set @AutoSupersedeName = dbo.auto_update_settings_file_to_centroid(@settingsFileName, @toolName)

        If Coalesce(@AutoSupersedeName, '') <> @settingsFileName
        Begin
            Set @settingsFileName = @AutoSupersedeName
            Set @MsgToAppend = 'Note: Auto-updated the settings file to ' + @AutoSupersedeName

            If @ProfileModeMSnDatasets > 0
                Set @MsgToAppend = @MsgToAppend + ' because one or more datasets in this job request has profile-mode MSn spectra'
            Else
                Set @MsgToAppend = @MsgToAppend + ' because one or more QExactive datasets are included in this job request'

            Set @message = dbo.append_to_text(@message, @MsgToAppend, 0, ';', 512)
        End
    End

    ---------------------------------------------------
    -- Auto-change the settings file if TMTpro samples
    ---------------------------------------------------
    --
    If (@toolName LIKE 'MSGFPlus%' AND @settingsFileName LIKE '%TMT%')
    Begin
        SELECT @tmtProDatasets = Count(Distinct DS.Dataset_ID)
        FROM #TD
            INNER JOIN T_Dataset DS ON #TD.Dataset_Name = DS.Dataset_Num
            INNER JOIN T_Experiments E ON DS.Exp_ID = E.Exp_ID
        WHERE E.EX_Labelling = 'TMT16' OR DS.Dataset_Num LIKE '%TMTpro%'

        If @tmtProDatasets > @datasetCount / 2.0
        Begin
            -- At least half of the datasets are 16-plex TMT; auto-update the settings file name, if necessary
            If @settingsFileName = 'IonTrapDefSettings_MzML_StatCysAlk_6plexTMT.xml'
            Begin
                Set @settingsFileName = 'IonTrapDefSettings_MzML_StatCysAlk_16plexTMT.xml'
            End

            IF @settingsFileName = 'IonTrapDefSettings_MzML_6plexTMT.xml'
            Begin
                Set @settingsFileName = 'IonTrapDefSettings_MzML_16plexTMT.xml'
            End
        End
    End

    ---------------------------------------------------
    -- If adding/updating a match-between-runs job, require that a data package is defined
    ---------------------------------------------------

    If @toolName Like 'MSFragger%' And @dataPackageID = 0 And (@settingsFileName Like '%MatchBetweenRun%' Or @settingsFileName Like '%MBR%')
    Begin
        RAISERROR ('Use a data package to define datasets when performing a match-between-runs search with MSFragger', 11, 4)
    End

    If @toolName Like 'MaxQuant%'And @dataPackageID = 0 And (@paramFileName Like '%MatchBetweenRun%' Or @paramFileName Like '%MBR%')
    Begin
        RAISERROR ('Use a data package to define datasets when performing a match-between-runs search with MaxQuant', 11, 4)
    End

    ---------------------------------------------------
    -- If mode is add, force @state to 'new'
    ---------------------------------------------------
    --
    IF @mode IN ('add', 'PreviewAdd')
    BEGIN
        -- Lookup the name for state "New"
        SELECT @state = StateName
        FROM T_Analysis_Job_Request_State
        WHERE (ID = 1)
    END

    ---------------------------------------------------
    -- Resolve state name to ID
    ---------------------------------------------------
    --
    Declare @stateID int = -1

    SELECT @stateID = ID
    FROM T_Analysis_Job_Request_State
    WHERE StateName = @state

    If @stateID = -1
        RAISERROR ('Could not resolve state name to ID', 11, 221)

    Set @logErrors = 1

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------

    If @mode = 'add'
    Begin
        Declare @newRequestNumber int

        Begin Tran

        INSERT INTO T_Analysis_Job_Request
        (
            AJR_requestName,
            AJR_created,
            AJR_analysisToolName,
            AJR_parmFileName,
            AJR_settingsFileName,
            AJR_organismDBName,
            AJR_organism_ID,
            AJR_proteinCollectionList,
            AJR_proteinOptionsList,
            AJR_comment,
            AJR_specialProcessing,
            AJR_state,
            AJR_requestor,
            Dataset_Min,
            Dataset_Max,
            Data_Package_ID
        )
        VALUES
        (
            @requestName,
            getdate(),
            @toolName,
            @paramFileName,
            @settingsFileName,
            @organismDBName,
            @organismID,
            @protCollNameList,
            @protCollOptionsList,
            @comment,
            @specialProcessing,
            @stateID,
            @userID,
            @datasetMin,
            @datasetMax,
            Case When @dataPackageId > 0 Then @dataPackageId Else Null End
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed for T_Analysis_Job_Request', 11, 9)
        --
        Set @newRequestNumber = SCOPE_IDENTITY()

        INSERT INTO T_Analysis_Job_Request_Datasets( Request_ID,
                                                     Dataset_ID )
        SELECT @newRequestNumber, #TD.Dataset_ID
        FROM #TD
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed for T_Analysis_Job_Request_Datasets', 11, 9)

        Commit Tran

        -- return ID of the newly created request
        --
        Set @requestID = cast(@newRequestNumber as varchar(32))

        If Len(@callingUser) > 0
        Begin
            -- @callingUser is defined; call alter_event_log_entry_user or alter_event_log_entry_user_multi_id
            -- to alter the Entered_By field in T_Event_Log
            --
            Exec alter_event_log_entry_user 12, @requestID, @stateID, @callingUser
        End

        Exec update_cached_job_request_existing_jobs @processingMode = 0, @requestId = @requestId, @infoOnly = 0

    End -- add mode

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    If @mode = 'PreviewAdd'
    Begin
        Set @message = 'Would create request "' + @requestName + '" with parameter file "' + @paramFileName + '" and settings file "' + @settingsFileName + '"'
    End

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode In ('update', 'append')
    Begin
        -- Update the request
        Set @myError = 0

        Begin Tran

        UPDATE T_Analysis_Job_Request
        SET AJR_requestName = @requestName,
            AJR_analysisToolName = @toolName,
            AJR_parmFileName = @paramFileName,
            AJR_settingsFileName = @settingsFileName,
            AJR_organismDBName = @organismDBName,
            AJR_organism_ID = @organismID,
            AJR_proteinCollectionList = @protCollNameList,
            AJR_proteinOptionsList = @protCollOptionsList,
            AJR_comment = @comment,
            AJR_specialProcessing = @specialProcessing,
            AJR_state = @stateID,
            AJR_requestor = @userID,
            Dataset_Min = @datasetMin,
            Dataset_Max = @datasetMax,
            Data_Package_ID = Case When @dataPackageId > 0 Then @dataPackageId Else Null End
        WHERE (AJR_requestID = @requestID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed for T_Analysis_Job_Request, RequestID "%d"', 11, 4, @requestID)
        ;

        MERGE T_Analysis_Job_Request_Datasets AS t
        USING (SELECT @requestID As Request_ID, Dataset_ID FROM #TD) AS s
        ON (t.Dataset_ID = s.Dataset_ID AND t.Request_ID = s.Request_ID)
        -- Note: all of the columns in table T_Analysis_Job_Request_Datasets are primary keys or identity columns; there are no updatable columns
        WHEN NOT MATCHED BY TARGET THEN
            INSERT(Request_ID, Dataset_ID)
            VALUES(s.Request_ID, s.Dataset_ID)
        WHEN NOT MATCHED BY SOURCE AND t.Request_ID = @requestID THEN Delete;
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed for T_Analysis_Job_Request_Datasets, RequestID "%d"', 11, 4, @requestID)

        Commit Tran

        If Len(@callingUser) > 0
        Begin
            -- @callingUser is defined; call alter_event_log_entry_user or alter_event_log_entry_user_multi_id
            -- to alter the Entered_By field in T_Event_Log
            --
            Exec alter_event_log_entry_user 12, @requestID, @stateID, @callingUser
        End

        Exec update_cached_job_request_existing_jobs @processingMode = 0, @requestId = @requestId, @infoOnly = 0

    End -- update mode

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Request ' + @requestName
            exec post_log_entry 'Error', @logMessage, 'add_update_analysis_job_request'
        End

    END CATCH

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_analysis_job_request] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_analysis_job_request] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_analysis_job_request] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_analysis_job_request] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_analysis_job_request] TO [Limited_Table_Write] AS [dbo]
GO
