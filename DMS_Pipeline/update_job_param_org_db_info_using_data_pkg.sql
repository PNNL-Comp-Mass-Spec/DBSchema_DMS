/****** Object:  StoredProcedure [dbo].[UpdateJobParamOrgDbInfoUsingDataPkg] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateJobParamOrgDbInfoUsingDataPkg]
/****************************************************
**
**  Desc:
**      Create or update entries for OrganismName, LegacyFastaFileName,
**      ProteinOptions, and ProteinCollectionList in T_Job_Parameters
**      for the specified job using the specified data package
**
**  Auth:   mem
**  Date    03/20/2012 mem - Initial version
**          09/11/2012 mem - Updated warning message used when data package does not have any jobs with a protein collection or legacy fasta file
**          08/14/2013 mem - Now using the job script name which is used to decide whether or not to report a warning via @message
**          03/09/2021 mem - Add support for MaxQuant
**          01/31/2022 mem - Add support for MSFragger
**                         - Add parameters @debugMode and @scriptNameForDebug
**          02/01/2023 mem - Use new synonym name
**
*****************************************************/
(
    @job int,
    @dataPackageID int,
    @deleteIfInvalid tinyint = 0,            -- When 1, deletes entries for OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList if @dataPackageID = 0, or @dataPackageID points to a non-existent data package, or if the data package doesn't have any Peptide_Hit jobs (MAC Jobs) or doesn't have any datasets (MaxQuant job)
    @debugMode tinyint = 0,
    @scriptNameForDebug varchar(64) = '',
    @message varchar(512)= '' output,
    @callingUser varchar(128) = ''
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @messageAddon varchar(256)

    Declare @orgDBInfo table (
        EntryID int Identity(1,1) NOT NULL,
        OrganismName varchar(128) NULL,
        LegacyFastaFileName varchar(128) NULL,
        ProteinCollectionList varchar(2000) NULL,
        ProteinOptions varchar(256) NULL,
        UseCount int NOT NULL
    )

    Declare @scriptName varchar(64) = ''
    Declare @organismName varchar(128) = ''
    Declare @legacyFastaFileName varchar(128) = ''
    Declare @proteinCollectionList varchar(2000) = ''
    Declare @proteinOptions varchar(256) = ''

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --

    If @job Is Null Or @dataPackageID Is Null
    Begin
        Set @message = '@job and @dataPackageID are required'
        Return 50000
    End

    Set @deleteIfInvalid = IsNull(@deleteIfInvalid, 0)
    Set @debugMode = IsNull(@debugMode, 0)
    Set @message = ''

    If @debugMode > 0
    Begin
        Print ''
        Print 'Examining parameters for job ' + Cast(@Job As Varchar(12)) + ', script ' + @scriptNameForDebug

        Set @scriptName = @scriptNameForDebug
    End
    Else
    Begin
        ---------------------------------------------------
        -- Lookup the name of the job script
        ---------------------------------------------------
        --
        SELECT @scriptName = Script
        FROM T_Jobs
        WHERE Job = @job

        Set @scriptName = IsNull(@scriptName, '??')
    End

    ---------------------------------------------------
    -- Validate @dataPackageID
    ---------------------------------------------------
    --

    Declare @matchCount int = 0

    SELECT @matchCount = COUNT(*)
    FROM S_Data_Package_Details
    WHERE ID = @dataPackageID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @matchCount = 0
    Begin
        Set @message = 'Data package ' + Convert(varchar(12), @dataPackageID) + ' not found in the Data_Package database'
        Set @dataPackageID = -1

        If @debugMode > 0
            Print 'UpdateJobParamOrgDbInfoUsingDataPkg: ' + @message
    End

    If @dataPackageID > 0 AND NOT @scriptName LIKE 'MaxQuant%' AND NOT @scriptName LIKE 'MSFragger%'
    Begin -- <a>
        If @debugMode > 0
            Print 'UpdateJobParamOrgDbInfoUsingDataPkg: Looking update OrgDB info for jobs associated with data package ' + Cast(@dataPackageID As Varchar(12)) + ' for script ' + @scriptName

        ---------------------------------------------------
        -- Lookup the OrgDB info for jobs associated with data package @dataPackageID
        ---------------------------------------------------
        --
        INSERT INTO @orgDBInfo( OrganismName,
                                LegacyFastaFileName,
                                ProteinCollectionList,
                                ProteinOptions,
                                UseCount )
        SELECT organism,
               CASE
                   WHEN IsNull(protein_collection_list, 'na') <> 'na' AND
                        IsNull(protein_options_list, 'na')    <> 'na' THEN 'na'
                   ELSE organism_db_name
               END AS Legacy_Fasta_File_Name,
               protein_collection_list,
               protein_options_list,
               COUNT(*) AS UseCount
        FROM dbo.S_DMS_V_Get_Pipeline_Job_Parameters J
        WHERE Job IN ( SELECT Job
                       FROM [S_Data_Package_Analysis_Jobs]
                       WHERE Data_Package_ID = @dataPackageID
                     ) AND
              J.Org_DB_Required <> 0
        GROUP BY organism, organism_db_name, protein_collection_list, protein_options_list
        ORDER BY COUNT(*) DESC
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ---------------------------------------------------
        -- Check for invalid data
        ---------------------------------------------------
        --
        If @myRowCount = 0
        Begin
            if @scriptName Not In ('Global_Label-Free_AMT_Tag', 'MultiAlign', 'MultiAlign_Aggregator')
                Set @message = 'Note: Data package ' + Convert(varchar(12), @dataPackageID) + ' either has no jobs or has no jobs with a protein collection or legacy fasta file; pipeline job parameters will not contain organism, fasta file, or protein collection'

            Set @dataPackageID = -1
        End
        Else
        Begin -- <b>
            If @myRowCount > 1
            Begin
                -- Mix of protein collections / fasta files defined

                Set @organismName = 'InvalidData'
                Set @legacyFastaFileName = 'na'
                Set @proteinCollectionList = 'MixOfOrgDBs_DataPkg_' + Convert(varchar(12), @dataPackageID) + '_UniqueComboCount_' + Convert(varchar(12), @myRowCount)
                Set @proteinOptions = 'seq_direction=forward,filetype=fasta'

            End
            Else
            Begin
                -- @myRowCount is 1

                SELECT @organismName = OrganismName,
                       @legacyFastaFileName = LegacyFastaFileName,
                       @proteinCollectionList = ProteinCollectionList,
                       @proteinOptions = ProteinOptions
                FROM @orgDBInfo

            End

            If @debugMode > 0
            Begin
                Print ''
                Print 'UpdateJobParamOrgDbInfoUsingDataPkg would update the following parameters for job ' + Cast (@Job As Varchar(12))
                Print '  OrganismName=         ' + @organismName
                Print '  LegacyFastaFileName=  ' + @legacyFastaFileName
                Print '  ProteinCollectionList=' + @proteinCollectionList
                Print '  ProteinOptions=       ' + @proteinOptions
            End
            Else
            Begin
                Exec AddUpdateJobParameter @job, 'PeptideSearch', 'OrganismName',          @value=@organismName,          @DeleteParam=0
                Exec AddUpdateJobParameter @job, 'PeptideSearch', 'LegacyFastaFileName',   @value=@legacyFastaFileName,   @DeleteParam=0
                Exec AddUpdateJobParameter @job, 'PeptideSearch', 'ProteinCollectionList', @value=@proteinCollectionList, @DeleteParam=0
                Exec AddUpdateJobParameter @job, 'PeptideSearch', 'ProteinOptions',        @value=@proteinOptions,        @DeleteParam=0
            End

            Set @message = 'Defined OrgDb related parameters for job ' + Convert(varchar(12), @job)

        End -- </b>

    End -- </a>

    If @dataPackageID <= 0
    Begin
        ---------------------------------------------------
        -- One of the following is tue:
        --   Data package ID was invalid
        --   For MAC jobs, the data package does not have any jobs with a protein collection or legacy fasta file
        --   For MaxQuant or MSFragger jobs, the data package does not have any datasets
        ---------------------------------------------------
        --

        If @deleteIfInvalid <> 0
        Begin
            If @debugMode > 0
            Begin
                Print ''
                Print 'UpdateJobParamOrgDbInfoUsingDataPkg would delete following parameters for job ' + Cast (@Job As Varchar(12)) + ' since the data package ID is 0'
                Print '  OrganismName'
                Print '  LegacyFastaFileName'
                Print '  ProteinCollectionList'
                Print '  ProteinOptions'
            End
            Else
            Begin
                Exec AddUpdateJobParameter @job, 'PeptideSearch', 'OrganismName',          @value='',  @DeleteParam=1
                Exec AddUpdateJobParameter @job, 'PeptideSearch', 'LegacyFastaFileName',   @value='',  @DeleteParam=1
                Exec AddUpdateJobParameter @job, 'PeptideSearch', 'ProteinCollectionList', @value='',  @DeleteParam=1
                Exec AddUpdateJobParameter @job, 'PeptideSearch', 'ProteinOptions',        @value='',  @DeleteParam=1
            End

            Set @messageAddon = 'Deleted OrgDb related parameters from the PeptideSearch section of the job parameters for job ' + Convert(varchar(12), @job)

            If IsNull(@message, '') = ''
                Set @message = @messageAddon
            Else
                Set @message = @message + '; ' + @messageAddon

        End
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobParamOrgDbInfoUsingDataPkg] TO [DDL_Viewer] AS [dbo]
GO
