/****** Object:  StoredProcedure [dbo].[ValidateAnalysisJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateAnalysisJobParameters]
/****************************************************
**
**  Desc:   Validates analysis job parameters and returns internal
**          values converted from external values (input arguments)
**
**  Note: This procedure depends upon the caller having created
**        temporary table #TD and populating it with the dataset names
**
**  This stored procedure will call ValidateAnalysisJobRequestDatasets to populate the remaining columns
**
**  CREATE TABLE #TD (
**      Dataset_Num varchar(128),
**      Dataset_ID int NULL,
**      IN_class varchar(64) NULL,
**      DS_state_ID int NULL,
**      AS_state_ID int NULL,
**      Dataset_Type varchar(64) NULL,
**      DS_rating smallint NULL,
**      Job int NULL,                       -- Only in the temp table created by AddAnalysisJobGroup; unused here
**      Dataset_Unreviewed tinyint NULL     -- Only in the temp table created by AddAnalysisJobGroup; unused here
**  )
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   04/04/2006 grk - supersedes MakeAnalysisJobX
**          05/01/2006 grk - modified to conditionally call
**                          Protein_Sequences.dbo.validate_analysis_job_protein_parameters
**          06/01/2006 grk - removed dataset archive state restriction
**          08/30/2006 grk - removed restriction for dataset state verification that limited it to "add" mode (http://prismtrac.pnl.gov/trac/ticket/219)
**          11/30/2006 mem - Now checking dataset type against AJT_allowedDatasetTypes in T_Analysis_Tool (Ticket #335)
**          12/20/2006 mem - Now assuring dataset rating is not -2=Data Files Missing (Ticket #339)
**          09/06/2007 mem - Updated to reflect Protein_Sequences DB move to server ProteinSeqs
**          10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**          09/12/2008 mem - Now calling ValidateNAParameter for the various parameters that can be 'na' (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**                         - Changed @paramFileName and @settingsFileName to be input/output parameters instead of input only
**          01/14/2009 mem - Now raising an error if @protCollNameList is over 2000 characters long (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          01/28/2009 mem - Now checking for settings files in T_Settings_Files instead of on disk (Ticket #718, http://prismtrac.pnl.gov/trac/ticket/718)
**          12/18/2009 mem - Now using T_Analysis_Tool_Allowed_Dataset_Type to determine valid dataset types for a given analysis tool
**          12/21/2009 mem - Now validating that the parameter file tool and the settings file tool match the tool defined by @toolName
**          02/11/2010 mem - Now assuring dataset rating is not -1 (or -2)
**          05/05/2010 mem - Now calling AutoResolveNameToPRN to check if @ownerPRN contains a person's real name rather than their username
**          05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**          08/26/2010 mem - Now calling ValidateProteinCollectionParams to validate the protein collection info
**          11/12/2010 mem - Now using T_Analysis_Tool_Allowed_Instrument_Class to determine valid instrument classes for a given analysis tool
**          01/12/2012 mem - Now validating that the analysis tool is active (T_Analysis_Tool.AJT_active > 0)
**          09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**          11/12/2012 mem - Moved dataset validation logic to ValidateAnalysisJobRequestDatasets
**          11/28/2012 mem - Added candidate code to validate that high res MSn datasets are centroided if using MSGFDB
**          01/11/2013 mem - Renamed MSGF-DB search tool to MSGFPlus
**          03/05/2013 mem - Added parameter @autoRemoveNotReleasedDatasets
**          04/02/2013 mem - Now updating @message if it is blank yet @result is non-zero
**          02/28/2014 mem - Now throwing an error if trying to search a large Fasta file with a parameter file that will result in a very slow search
**          03/13/2014 mem - Added custom message to be displayed when trying to reset a MAC job
**                         - Added optional parameter @Job
**          07/18/2014 mem - Now validating that files over 400 MB in size are using MSGFPlus_SplitFasta
**          03/02/2015 mem - Now validating that files over 500 MB in size are using MSGFPlus_SplitFasta
**          04/08/2015 mem - Now validating that profile mode high res MSn datasets are centroided if using MSGFPlus
**                         - Added optional parameters @autoUpdateSettingsFileToCentroided and @Warning
**          04/23/2015 mem - Now passing @toolName to ValidateAnalysisJobRequestDatasets
**          05/01/2015 mem - Now preventing the use of parameter files with more than one dynamic mod when the fasta file is over 2 GB in size
**          06/24/2015 mem - Added parameter @showDebugMessages
**          12/16/2015 mem - No longer auto-switching the settings file to a centroided one if high res MSn spectra; only switching if profile mode MSn spectra
**          07/12/2016 mem - Force priority to 4 if using @organismDBName and it has a size over 400 MB
**          07/20/2016 mem - Tweak error messages
**          04/19/2017 mem - Validate the settings file for SplitFasta tools
**          12/06/2017 mem - Add parameter @allowNewDatasets
**          07/19/2018 mem - Increase the threshold for requiring SplitFASTA searches from 400 MB to 600 MB
**          07/11/2019 mem - Auto-change parameter file names from MSGFDB_ to MSGFPlus_
**          07/30/2019 mem - Update comments and capitalization
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          03/10/2021 mem - Add logic for MaxQuant
**          03/15/2021 mem - Validate that the settings file and/or parameter file are defined for tools that require them
**          05/26/2021 mem - Use @allowNonReleasedDatasets when calling ValidateAnalysisJobRequestDatasets
**          08/26/2021 mem - Add logic for MSFragger
**          10/05/2021 mem - Show custom message if @toolName contains an inactive _dta.txt based MS-GF+ tool
**          11/08/2021 mem - Allow instrument class 'Data_Folders' and dataset type 'DataFiles' (both used by instrument 'DMS_Pipeline_Data') to apply to all analysis tools
**          06/30/2022 mem - Rename parameter file argument
**
*****************************************************/
(
    @toolName varchar(64),
    @paramFileName varchar(255) output,
    @settingsFileName varchar(255) output,
    @organismDBName varchar(128) output,        -- Legacy fasta file; typically 'na'
    @organismName varchar(128),
    @protCollNameList varchar(4000) output,        -- Will raise an error if over 2000 characters long; necessary since the Broker DB (DMS_Pipeline) has a 2000 character limit on analysis job parameter values
    @protCollOptionsList varchar(256) output,
    @ownerPRN varchar(64) output,
    @mode varchar(12),                            -- Used to tweak the warning if @analysisToolID is not found in T_Analysis_Tool
    @userID int output,
    @analysisToolID int output,
    @organismID int output,
    @message varchar(512) output,
    @autoRemoveNotReleasedDatasets tinyint = 0,
    @Job int = 0,
    @autoUpdateSettingsFileToCentroided tinyint = 1,
    @allowNewDatasets tinyint = 0,                -- When 0, all datasets must have state 3 (Complete); when 1, will also allow datasets with state 1 or 2 (New or Capture In Progress)
    @Warning varchar(255) = '' output,
    @priority int = 2 output,
    @showDebugMessages tinyint = 0
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    Set @message = ''
    Set @Warning = ''

    Set @showDebugMessages = IsNull(@showDebugMessages, 0)

    Declare @datasetList varchar(1024)
    Declare @paramFileTool varchar(128) = '??NoMatch??'
    Declare @settingsFileTool varchar(128)
    Declare @result int

    Declare @toolActive tinyint = 0
    Declare @settingsFileRequired tinyint = 0
    Declare @paramFileRequired tinyint = 0
    Declare @allowNonReleasedDatasets Tinyint = 0

    ---------------------------------------------------
    -- Validate the datasets in #TD
    ---------------------------------------------------

    If @mode In ('Update', 'PreviewUpdate')
    Begin
        Set @allowNonReleasedDatasets = 1
    End

    exec @result = ValidateAnalysisJobRequestDatasets
                        @message output,
                        @autoRemoveNotReleasedDatasets=@autoRemoveNotReleasedDatasets,
                        @toolName=@toolName,
                        @allowNewDatasets=@allowNewDatasets,
                        @allowNonReleasedDatasets=@allowNonReleasedDatasets,
                        @showDebugMessages=@showDebugMessages

    If @result <> 0
    Begin
        If IsNull(@message, '') = ''
        Begin
            Set @message = 'Error code ' + Convert(varchar(12), @result) + ' returned by ValidateAnalysisJobRequestDatasets in ValidateAnalysisJobParameters'
            If @showDebugMessages <> 0
                print @message
        End
        return @result
    End

    ---------------------------------------------------
    -- Resolve user ID for operator PRN
    ---------------------------------------------------

    execute @userID = GetUserID @ownerPRN

    If @userID > 0
    Begin
        -- SP GetUserID recognizes both a username and the form 'LastName, FirstName (Username)'
        -- Assure that @ownerPRN contains simply the username
        --
        SELECT @ownerPRN = U_PRN
        FROM T_Users
        WHERE ID = @userID
    End
    Else
    Begin
        ---------------------------------------------------
        -- @ownerPRN did not resolve to a User_ID
        -- In case a name was entered (instead of a PRN),
        --  try to auto-resolve using the U_Name column in T_Users
        ---------------------------------------------------
        Declare @MatchCount int
        Declare @NewPRN varchar(64)

        exec AutoResolveNameToPRN @ownerPRN, @MatchCount output, @NewPRN output, @userID output

        If @MatchCount = 1
        Begin
            -- Single match was found; update @ownerPRN
            Set @ownerPRN = @NewPRN
        End
        Else
        Begin
            Set @message = 'Could not find entry in database for owner PRN "' + @ownerPRN + '"'
            If @showDebugMessages <> 0
                print @message

            return 51019
        End
    End

    ---------------------------------------------------
    -- Get analysis tool ID from tool name
    ---------------------------------------------------
    --
    execute @analysisToolID = GetAnalysisToolID @toolName

    If @analysisToolID = 0
    Begin
        Set @message = 'Could not find entry in database for analysis tool "' + @toolName + '"'
            If @showDebugMessages <> 0
                print @message

        return 53102
    End

    ---------------------------------------------------
    -- Verify the tool name and get its requirements
    ---------------------------------------------------
    --
    SELECT @toolActive = AJT_Active,
           @settingsFileRequired = SettingsFileRequired,
           @paramFileRequired = ParamFileRequired
    FROM T_Analysis_Tool
    WHERE AJT_toolID = @analysisToolID

    ---------------------------------------------------
    -- Make sure the analysis tool is active
    ---------------------------------------------------

    If @toolActive = 0
    Begin
        If @toolName In ('MSGFPlus', 'MSGFPlus_DTARefinery')
        Begin
            Set @message = 'The MSGFPlus tool used concatenated _dta.txt files, which are PNNL-specific. Please use tool MSGFPlus_MzML instead (for example requests, see https://dms2.pnl.gov/analysis_job_request/report/-/-/-/-/StartsWith__MSGFPlus_MzML/-/- )'
        End
        Else If @toolName in ('MSGFPlus_SplitFasta', 'MSGFPlus_DTARefinery_SplitFasta')
        Begin
            Set @message = 'The MSGFPlus SplitFasta tool used concatenated _dta.txt files, which are PNNL-specific. Please use tool MSGFPlus_MzML instead (for example requests, see https://dms2.pnl.gov/analysis_job_request/report/-/-/-/-/StartsWith__MSGFPlus_MzML_SplitFasta/-/- )'
        End
        Else If @mode = 'reset' And (@toolName LIKE 'MAC[_]%' Or @toolName = 'MaxQuant_DataPkg' Or @toolName = 'MSFragger_DataPkg')
        Begin
            Set @message = @toolName + ' jobs must be reset by clicking Edit on the Pipeline Job Detail report'
            If IsNull(@Job, 0) > 0
                Set @message = @message + '; see https://dms2.pnl.gov/pipeline_jobs/show/' + Convert(varchar(12), @Job)
            Else
                Set @message = @message + '; see https://dms2.pnl.gov/pipeline_jobs/report/-/-/~Aggregation'
        End
        Else
        Begin
            Set @message = 'Analysis tool "' + @toolName + '" is not active and thus cannot be used for this operation (ToolID ' + Convert(varchar(12), @analysisToolID) + ')'
        End

        If @showDebugMessages <> 0
            print @message

        return 53103
    End

    ---------------------------------------------------
    -- Get organism ID using organism name
    ---------------------------------------------------
    --
    execute @organismID = GetOrganismID @organismName
    If @organismID = 0
    Begin
        Set @message = 'Could not find entry in database for organism "' + @organismName + '"'
        If @showDebugMessages <> 0
            print @message

        return 53105
    End

    ---------------------------------------------------
    -- Check tool/instrument compatibility for datasets
    ---------------------------------------------------

    -- Find datasets that are not compatible with tool
    --
    Set @datasetList = ''
    --
    SELECT @datasetList = @datasetList +
                          CASE WHEN @datasetList = ''
                               THEN Dataset_Num
                               ELSE ', ' + Dataset_Num
                          END
    FROM #TD
    WHERE IN_class <> 'Data_Folders' And
          IN_class NOT IN ( SELECT AIC.Instrument_Class
                            FROM T_Analysis_Tool AnTool
                                 INNER JOIN T_Analysis_Tool_Allowed_Instrument_Class AIC
                                   ON AnTool.AJT_toolID = AIC.Analysis_Tool_ID
                            WHERE AnTool.AJT_toolName = @toolName )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error checking dataset instrument classes against tool'
        If @showDebugMessages <> 0
            print @message

        return 51007
    End

    If @datasetList <> ''
    Begin
        Set @message = 'The instrument class for the following datasets is not compatible with the analysis tool: "' + @datasetList + '"'
        If @showDebugMessages <> 0
            print @message

        return 51007
    End

    ---------------------------------------------------
    -- Check tool/dataset type compatibility for datasets
    ---------------------------------------------------

    -- find datasets that are not compatible with tool
    --
    Set @datasetList = ''
    --
    SELECT @datasetList = @datasetList +
                          CASE WHEN @datasetList = ''
                               THEN Dataset_Num
                               ELSE ', ' + Dataset_Num
                          END
    FROM #TD
    WHERE Dataset_Type <> 'DataFiles' And
          Dataset_Type NOT IN ( SELECT ADT.Dataset_Type
                                FROM T_Analysis_Tool_Allowed_Dataset_Type ADT
                                     INNER JOIN T_Analysis_Tool Tool
                                       ON ADT.Analysis_Tool_ID = Tool.AJT_toolID
                                WHERE Tool.AJT_toolName = @toolName )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error checking dataset types against tool'
        If @showDebugMessages <> 0
            print @message

        return 51008
    End

    If @datasetList <> ''
    Begin
        Set @message = 'The dataset type for the following datasets is not compatible with the analysis tool: "' + @datasetList + '"'
        If @showDebugMessages <> 0
            print @message

        return 51008
    End

    ---------------------------------------------------
    -- Make sure settings for which 'na' is acceptable truly have lowercase 'na' and not 'NA' or 'n/a'
    ---------------------------------------------------
    --
    Set @settingsFileName =    dbo.ValidateNAParameter(@settingsFileName, 1)
    Set @paramFileName =        dbo.ValidateNAParameter(@paramFileName, 1)

    ---------------------------------------------------
    -- Check for settings file or parameter file being 'na' when not allowed
    ---------------------------------------------------

    If @settingsFileRequired > 0 And @settingsFileName = 'na'
    Begin
        Set @message = 'A settings file is required for analysis tool "' + @toolName + '"'

        If @showDebugMessages <> 0
            print @message

        return 51009
    End

    If @paramFileRequired > 0 And @paramFileName = 'na'
    Begin
        Set @message = 'A parameter file is required for analysis tool "' + @toolName + '"'

        If @showDebugMessages <> 0
            print @message

        return 51010
    End

    ---------------------------------------------------
    -- Validate param file for tool
    ---------------------------------------------------
    --
    Set @result = 0
    --
    If @paramFileName <> 'na'
    Begin
        If @paramFileName Like 'MSGFDB[_]%'
        Begin
            Set @paramFileName = 'MSGFPlus_' + Substring(@paramFileName, 8, 500)
        End

        If Exists (SELECT * FROM dbo.T_Param_Files WHERE (Param_File_Name = @paramFileName) AND (Valid <> 0))
        Begin
            -- The specified parameter file is valid
            -- Make sure the parameter file tool corresponds to @toolName

            If Not Exists (
                SELECT *
                FROM T_Param_Files PF
                     INNER JOIN T_Analysis_Tool ToolList
                       ON PF.Param_File_Type_ID = ToolList.AJT_paramFileType
                WHERE (PF.Param_File_Name = @paramFileName) AND
                      (ToolList.AJT_toolName = @toolName)
                )
            Begin
                SELECT TOP 1 @paramFileTool = ToolList.AJT_toolName
                FROM T_Param_Files PF
                     INNER JOIN T_Analysis_Tool ToolList
                 ON PF.Param_File_Type_ID = ToolList.AJT_paramFileType
                WHERE (PF.Param_File_Name = @paramFileName)
                ORDER BY ToolList.AJT_toolID

                Set @message = 'Parameter file "' + IsNull(@paramFileName, '??') + '" is for tool ' + IsNull(@paramFileTool, '??') + '; not ' + IsNull(@toolName, '??')
                If @showDebugMessages <> 0
                    print @message

                return 53111
            End
        End
        Else
        Begin
            -- Parameter file either does not exist or is inactive
            --
            If Exists (SELECT * FROM dbo.T_Param_Files WHERE (Param_File_Name = @paramFileName) AND (Valid = 0))
                Set @message = 'Parameter file is inactive and cannot be used' + ':"' + @paramFileName + '"'
            Else
                Set @message = 'Parameter file could not be found' + ':"' + @paramFileName + '"'

            If @showDebugMessages <> 0
                print @message

            return 53109
        End
    End

    ---------------------------------------------------
    -- Validate settings file for tool
    ---------------------------------------------------

    If @settingsFileName <> 'na'
    Begin
        If Not Exists (SELECT * FROM dbo.T_Settings_Files WHERE (File_Name = @settingsFileName) AND (Active <> 0))
        Begin
            -- Settings file either does not exist or is inactive
            --
            If Exists (SELECT * FROM dbo.T_Settings_Files WHERE (File_Name = @settingsFileName) AND (Active = 0))
                Set @message = 'Settings file is inactive and cannot be used' + ':"' + @settingsFileName + '"'
            Else
                Set @message = 'Settings file could not be found' + ':"' + @settingsFileName + '"'

            If @showDebugMessages <> 0
                print @message

            return 53108
        End

        -- The specified settings file is valid
        -- Make sure the settings file tool corresponds to @toolName

        If Not Exists (
            SELECT *
            FROM V_Settings_File_Picklist SFP
            WHERE (SFP.File_Name = @settingsFileName) AND
                    (SFP.Analysis_Tool = @toolName)
            )
        Begin

            SELECT TOP 1 @settingsFileTool = SFP.Analysis_Tool
            FROM V_Settings_File_Picklist SFP
                    INNER JOIN T_Analysis_Tool ToolList
                    ON SFP.Analysis_Tool = ToolList.AJT_toolName
            WHERE (SFP.File_Name = @settingsFileName)
            ORDER BY ToolList.AJT_toolID

            Set @message = 'Settings file "' + @settingsFileName + '" is for tool ' + @settingsFileTool + '; not ' + @toolName
            If @showDebugMessages <> 0
                print @message

            return 53112
        End

        If @showDebugMessages <> 0
            print '  @autoUpdateSettingsFileToCentroided=' + Cast(@autoUpdateSettingsFileToCentroided as varchar(12))

        If IsNull(@autoUpdateSettingsFileToCentroided, 1) <> 0
        Begin
            ---------------------------------------------------
            -- If the dataset has profile mode MS/MS spectra and the search tool is MSGFPlus, we must centroid the spectra
            ---------------------------------------------------

            Declare @ProfileModeMSn tinyint = 0

            If Exists (SELECT *
                    FROM #TD INNER JOIN T_Dataset_Info DI ON DI.Dataset_ID = #TD.Dataset_ID
                    WHERE DI.ProfileScanCount_MSn > 0)
            Begin
                Set @ProfileModeMSn = 1
            End

            If @showDebugMessages <> 0
            Begin
                print '  @ProfileModeMSn=' + Cast(@ProfileModeMSn as varchar(12))
                print '  @toolName=' + @toolName
            End

            If @ProfileModeMSn > 0 AND @toolName IN ('MSGFPlus', 'MSGFPlus_DTARefinery', 'MSGFPlus_SplitFasta')
            Begin
                -- The selected settings file must use MSConvert with Centroiding enabled
                -- DeconMSn potentially works, but it can cause more harm than good

                Declare @AutoCentroidName varchar(255) = ''

                SELECT @AutoCentroidName = SF.MSGFPlus_AutoCentroid
                FROM T_Settings_Files SF
                     INNER JOIN T_Analysis_Tool AnTool
                       ON SF.Analysis_Tool = AnTool.AJT_toolName
                WHERE SF.File_Name = @settingsFileName AND
                      SF.Analysis_Tool = @toolName

                If @showDebugMessages <> 0
                Begin
                    print '  @settingsFileName=' + @settingsFileName
                    print '  @AutoCentroidName=' + IsNull(@AutoCentroidName, '<< Not Defined >>')
                End

                If IsNull(@AutoCentroidName, '') <> ''
                Begin
                    Set @settingsFileName = @AutoCentroidName

                    Set @Warning = 'Note: Auto-updated the settings file to ' + @AutoCentroidName + ' because this job has a profile-mode MSn dataset'

                    If @showDebugMessages <> 0
                        print @Warning

                End

                Declare @DtaGenerator varchar(512)
                Declare @CentroidSetting varchar(512) = ''

                CREATE TABLE #Tmp_SettingsFile_Values (
                    KeyName varchar(512) NULL,
                    Value varchar(512) NULL
                )

                INSERT INTO #Tmp_SettingsFile_Values (KeyName, Value)
                SELECT xmlNode.value('@key', 'nvarchar(512)') AS KeyName,
                    xmlNode.value('@value', 'nvarchar(512)') AS Value
                FROM T_Settings_Files cross apply Contents.nodes('//item') AS R(xmlNode)
                WHERE (File_Name = @settingsFileName) AND (Analysis_Tool = @toolName)

                SELECT @DtaGenerator = Value
                FROM #Tmp_SettingsFile_Values
                WHERE KeyName = 'DtaGenerator'

                If IsNull(@DtaGenerator, '') = ''
                Begin
                    Set @message = 'Settings file "' + @settingsFileName + '" does not have DtaGenerator defined; unable to verify that centroiding is enabled'
                    If @showDebugMessages <> 0
                        print @message

                    return 53113
                End

                If @DtaGenerator = 'MSConvert.exe'
                Begin
                    SELECT @CentroidSetting = Value
                    FROM #Tmp_SettingsFile_Values
                    WHERE KeyName = 'CentroidMGF'

                    Set @CentroidSetting = IsNull(@CentroidSetting, 'False')
                End

                If @DtaGenerator = 'DeconMSN.exe'
                Begin
                    SELECT @CentroidSetting = Value
                    FROM #Tmp_SettingsFile_Values
                    WHERE KeyName = 'CentroidDTAs'

                    Set @CentroidSetting = IsNull(@CentroidSetting, 'False')
                End

                If @CentroidSetting <> 'True'
                Begin
                    If IsNull(@CentroidSetting, '') = ''
                        Set @message = 'MSGF+ requires that HMS-HMSn spectra be centroided; settings file "' + @settingsFileName + '" does not use MSConvert or DeconMSn for DTA Generation; unable to determine if centroiding is enabled'
                    Else
                        Set @message = 'MSGF+ requires that HMS-HMSn spectra be centroided; settings file "' + @settingsFileName + '" does not appear to have centroiding enabled'

                    If @showDebugMessages <> 0
                        print @message
                End
            End
        End

    End

    ---------------------------------------------------
    -- Check protein parameters
    ---------------------------------------------------

    exec @result = ValidateProteinCollectionParams
                    @toolName,
                    @organismDBName output,
                    @organismName,
                    @protCollNameList output,
                    @protCollOptionsList output,
                    @ownerPRN,
                    @message output,
                    @debugMode=@showDebugMessages

    If @result <> 0
    Begin
        If IsNull(@message, '') = ''
        Begin
            Set @message = 'Error code ' + Convert(varchar(12), @result) + ' returned by ValidateProteinCollectionParams in ValidateAnalysisJobParameters'
        End

        If @showDebugMessages <> 0
            print @message

        return @result
    End

    ---------------------------------------------------
    -- Make sure the user is not scheduling an extremely long MS-GF+ search (with non-compatible settings)
    -- Also possibly alter @priority
    ---------------------------------------------------

    If @organismDBName <> 'na' And @organismDBName <> ''
    Begin
        Declare @FileSizeKB real = 0
        Declare @SizeDescription varchar(24) = ''

        SELECT @FileSizeKB = File_Size_KB
        FROM T_Organism_DB_File
        WHERE FileName = @organismDBName

        If @FileSizeKB > 0
        Begin
            Declare @FileSizeMB real = @FileSizeKB/1024.0
            Declare @FileSizeGB real = @FileSizeMB/1024.0

            If @FileSizeGB < 1
                Set @SizeDescription = Cast(Cast(@FileSizeMB As int) As varchar(12)) + ' MB'
            Else
                Set @SizeDescription = Cast(Cast(@FileSizeGB As decimal(9,1)) As varchar(12)) + ' GB'
        End

        -- Bump priority if the file is over 400 MB in size
        If IsNull(@FileSizeKB, 0) > 400*1024
        Begin
            If @priority < 4
                Set @priority = 4
        End

        If @toolName Like '%MSGFPlus%'
        Begin
            -- Check for a file over 500 MB in size
            If IsNull(@FileSizeKB, 0) > 500*1024 Or
               @organismDBName In (
                    'ORNL_Proteome_Study_Soil_1606Orgnsm2012-08-24.fasta',
                    'ORNL_Proteome_Study_Soil_1606Orgnsm2012-08-24_reversed.fasta',
                    'uniprot_2012_1_combined_bacterial_sprot_trembl_2012-02-20.fasta',
                    'uniprot2012_7_ArchaeaBacteriaFungiSprotTrembl_2012-07-11.fasta',
                    'uniref50_2013-02-14.fasta',
                    'uniref90_2013-02-14.fasta',
                    'BP_Sediment_Genomes_Jansson_stop-to-stop_6frames.fasta',
                    'GOs_PredictedByClustering_2009-02-11.fasta',
                    'Shew_MR1_GOs_Meso_2009-02-11.fasta',
                    'Switchgrass_Rhiz_MG-RAST_metagenome_DecoyWithContams_2013-10-10.fasta')
            Begin
                If Not
                ( @paramFileName Like '%PartTryp_NoMods%' Or
                    @paramFileName Like '%PartTryp_StatCysAlk.txt' Or
                    @paramFileName Like '%PartTryp_StatCysAlk_[0-9]%ppm%' Or
                    @paramFileName Like '%[_]Tryp[_]%'
                )
                Begin
                    Set @message = 'Legacy fasta file "' + @organismDBName + '" is very large (' + @SizeDescription + '); you must choose a parameter file that is fully tryptic (MSGFDB_Tryp_) or is partially tryptic but has no dynamic mods (MSGFDB_PartTryp_NoMods)'
                    Set @result = 65350

                    If @showDebugMessages <> 0
                        print @message

                    return @result
                End
            End

            -- Check for a file over 2 GB in size
            If IsNull(@FileSizeKB, 0) > 2*1024*1024 Or
               @organismDBName In (
                'uniprot_2012_1_combined_bacterial_sprot_trembl_2012-02-20.fasta',
                'uniprot2012_7_ArchaeaBacteriaFungiSprotTrembl_2012-07-11.fasta',
                'uniref90_2013-02-14.fasta',
                'Uniprot_ArchaeaBacteriaFungi_SprotTrembl_2014-4-16.fasta',
                'Kansas_metagenome_12902_TrypPig_Bov_2014-11-25.fasta',
                'HoplandAll_assembled_Tryp_Pig_Bov_2015-04-06.fasta')
            Begin
                Declare @DynModCount int = 0

                SELECT @DynModCount = Count(*)
                FROM V_Param_File_Mass_Mods
                WHERE Param_File_Name = @paramFileName AND
                    Mod_Type_Symbol = 'D'

                If IsNull(@DynModCount, 0) > 1
                Begin
                    -- Parameter has more than one dynamic mod; this search will take too long
                    Set @message = 'Legacy fasta file "' + @organismDBName + '" is very large (' + @SizeDescription + '); you cannot use a parameter file with ' + Cast(@DynModCount as varchar(12)) + ' dynamic mods.  Preferably use a parameter file with no dynamic mods (though you _might_ get away with 1 dynamic mod).'
                    Set @result = 65351

                    If @showDebugMessages <> 0
                        print @message

                    return @result
                End
            End

            -- If using MSGF+ and the file is over 600 MB, then you must use MSGFPlus_SplitFasta
            If IsNull(@FileSizeKB, 0) > 600*1024
            Begin
                If @toolName Like '%MSGF%' And Not @toolName Like '%SplitFasta%'
                Begin
                    Set @message = 'Legacy fasta file "' + @organismDBName + '" is very large (' + @SizeDescription + '); you must use analysis tool MSGFPlus_SplitFasta or MSGFPlus_MzML_SplitFasta'
                    Set @result = 65352

                    If @showDebugMessages <> 0
                        print @message

                    return @result
                End
            End
        End

    End

    If @toolName Like '%SplitFasta%'
    Begin
        -- Assure that the settings file has SplitFasta=True and NumberOfClonedSteps > 1

        Declare @xml xml
        Declare @numberOfClonedSteps int = 0
        Declare @splitFasta varchar(128) = ''

        SELECT @xml = Contents
        FROM T_Settings_Files
        WHERE [File_Name] = @settingsFileName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myRowCount = 0
        Begin
            Set @message = 'Settings file not found: ' + @settingsFileName
            If @showDebugMessages <> 0
                print @message
            return 53114
        End

        SELECT @splitFasta = SettingValue
        FROM ( SELECT b.value('@key', 'varchar(128)') as SettingName,
                      b.value('@value', 'varchar(128)') as SettingValue
               FROM @xml.nodes('/sections/section/item') as a(b)
             ) ParseQ
        WHERE SettingName = 'SplitFasta'
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myRowCount = 0 Or IsNull(@splitFasta, 'False') <> 'True'
        Begin
            Set @message = 'Search tool ' + @toolName + ' requires a SplitFasta settings file'
            If @showDebugMessages <> 0
                print @message
            return 53115
        End

        Select @numberOfClonedSteps = SettingValue
        From ( SELECT b.value('@key', 'varchar(128)') as SettingName,
                      b.value('@value', 'int') as SettingValue
               FROM @xml.nodes('/sections/section/item') as a(b)
             ) ParseQ
        WHERE SettingName = 'NumberOfClonedSteps'
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myRowCount = 0 Or IsNull(@numberOfClonedSteps, 0) < 1
        Begin
            Set @message = 'Search tool ' + @toolName + ' requires a SplitFasta settings file'
            If @showDebugMessages <> 0
                print @message
            return 53116
        End

    End

    If @result <> 0 And @showDebugMessages <> 0 And IsNull(@message, '') <> ''
        print @message

    return @result

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateAnalysisJobParameters] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateAnalysisJobParameters] TO [Limited_Table_Write] AS [dbo]
GO
