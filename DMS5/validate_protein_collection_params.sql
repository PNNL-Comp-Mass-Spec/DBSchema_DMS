/****** Object:  StoredProcedure [dbo].[validate_protein_collection_params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_protein_collection_params]
/****************************************************
**
**  Desc:
**      Validates the organism DB and/or protein collection options
**
**  Auth:   mem
**  Date:   08/26/2010
**          05/15/2012 mem - Now verifying that @organismDBName is 'na' if @protCollNameList is defined, or vice versa
**          09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**          08/19/2013 mem - Auto-clearing @organismDBName if both @organismDBName and @protCollNameList are defined and @organismDBName is the auto-generated FASTA file for the specified protein collection
**          07/12/2016 mem - Now using a synonym when calling validate_analysis_job_protein_parameters in the Protein_Sequences database
**          04/11/2022 mem - Increase warning threshold for length of @protCollNameList to 4000
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/30/2024 mem - Call procedure validate_protein_collection_states()
**
*****************************************************/
(
    @toolName varchar(64),                      -- If blank, then will assume @orgDbReqd=1
    @organismDBName varchar(128) output,
    @organismName varchar(128),
    @protCollNameList varchar(4000) output,     -- Will raise an error if over 4000 characters long; necessary since the Broker DB (DMS_Pipeline) has a 4000 character limit on analysis job parameter values
    @protCollOptionsList varchar(256) output,
    @ownerUsername varchar(64) = '',            -- Only required if the user chooses an "Encrypted" protein collection; as of August 2010 we don't have any encrypted protein collections
    @message varchar(255) = '' output,
    @debugMode tinyint = 0                      -- If non-zero then will display some debug info
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @result int

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    Set @message = ''
    Set @ownerUsername = IsNull(@ownerUsername, '')
    Set @debugMode = IsNull(@debugMode, 0)

    ---------------------------------------------------
    -- Make sure settings for which 'na' is acceptable truly have lowercase 'na' and not 'NA' or 'n/a'
    -- Note that Sql server string comparisons are not case-sensitive, but VB.NET string comparisons are
    --  Therefore, @settingsFileName needs to be lowercase 'na' for compatibility with the analysis manager
    ---------------------------------------------------
    --
    Set @organismDBName =      dbo.validate_na_parameter(@organismDBName, 1)
    Set @protCollNameList =    dbo.validate_na_parameter(@protCollNameList, 1)
    Set @protCollOptionsList = dbo.validate_na_parameter(@protCollOptionsList, 1)


    If @organismDBName = ''      Set @organismDBName = 'na'
    If @protCollNameList = ''    Set @protCollNameList = 'na'
    If @protCollOptionsList = '' Set @protCollOptionsList = 'na'

    ---------------------------------------------------
    -- Lookup orgDbReqd for the analysis tool
    ---------------------------------------------------

    Declare @orgDbReqd int = 0

    If IsNull(@toolName, '') = ''
        Set @orgDbReqd = 1
    Else
    Begin
        SELECT
            @orgDbReqd = AJT_orgDbReqd
        FROM T_Analysis_Tool
        WHERE (AJT_toolName = @toolName)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error looking up tool parameters'
            Return 51038
        End

        If @myRowCount = 0
        Begin
            Set @message = 'Invalid analysis tool "' + @toolName + '"; not found in T_Analysis_Tool'
            Return 51039
        End
    End

    ---------------------------------------------------
    -- Validate the protein collection info
    ---------------------------------------------------

    If Len(@protCollNameList) > 4000
    Begin
        Set @message = 'Protein collection list is too long; maximum length is 4000 characters'
        Return 53110
    End

    --------------------------------------------------------------
    -- Populate #Tmp_ProteinCollections with the protein collections in _protCollNameList
    --------------------------------------------------------------

    CREATE TABLE #Tmp_ProteinCollections (
        RowNumberID int identity(1,1),
        Protein_Collection_Name varchar(128) NOT NULL,
        Collection_State_ID int NOT NULL
    );

    INSERT INTO #Tmp_ProteinCollections (Protein_Collection_Name, Collection_State_ID)
    SELECT Value, 0 AS Collection_State_ID
    FROM dbo.parse_delimited_list(@protCollNameList, ',', 'validate_protein_collection_params');

    --------------------------------------------------------------
    -- Look for protein collections with state 'Offline' or 'Proteins_Deleted'
    --------------------------------------------------------------

    Declare @invalidCount int;
    Declare @offlineCount int;

    Exec @result = validate_protein_collection_states
                       @invalidCount = @invalidCount output,
                       @offlineCount = @offlineCount output,
                       @message      = @message output,
                       @showDebug    = 0;


    If Coalesce(@invalidCount, 0) > 0 Or Coalesce(@offlineCount, 0) > 0
    Begin
        If Coalesce(@message, '') = ''
        Begin
            If @invalidCount > 0
            Begin
                Set @message = 'The protein collection list has ' + Cast(@invalidCount As varchar(12)) + ' invalid protein ' +
                               dbo.check_plural(@invalidCount, 'collection', 'collections');
            End
            Else
            Begin
                Set @message = 'The protein collection list has ' + Cast(@offlineCount As varchar(12)) + ' offline protein ' +
                               dbo.check_plural(@offlineCount, 'collection', 'collections') +
                               '; contact an admin to restore the proteins'
            End
        End

        If Coalesce(@result, 0) = 0
        Begin
            Set @result = 5330;
        End

        Return @result;
    End

    If @orgDbReqd = 0
    Begin
        If @organismDBName <> 'na' OR @protCollNameList <> 'na' OR @protCollOptionsList <> 'na'
        Begin
            Set @message = 'Protein parameters must all be "na"; you have: Legacy Fasta (OrgDBName) = "' + @organismDBName + '", ProteinCollectionList = "' + @protCollNameList + '", ProteinOptionsList = "' + @protCollOptionsList + '"'
            Return 53093
        End

        Return 0
    End

    If Not @organismDBName In ('', 'na') And Not @protCollNameList In ('', 'na')
    Begin
        -- User defined both a Legacy Fasta file and a Protein Collection List
        -- Auto-change @organismDBName to 'na' if possible
        If Exists (SELECT * FROM T_Analysis_Job
                   WHERE AJ_organismDBName = @organismDBName AND
                         AJ_proteinCollectionList = @protCollNameList AND
                         AJ_StateID IN (1, 2, 4, 14))
        Begin
            -- Existing job found with both this legacy fasta file name and this protein collection list
            -- Thus, use the protein collection list and clear @organismDBName
            Set @organismDBName = ''
        End
    End

    If Not @organismDBName In ('', 'na')
    Begin
        If Not @protCollNameList In ('', 'na')
        Begin
            Set @message = 'Cannot define both a Legacy Fasta file and a Protein Collection List; one must be "na"'
            Return 53104
        End

        If @protCollNameList In ('', 'na') and Not @protCollOptionsList In ('', 'na')
        Begin
            Set @protCollOptionsList = 'na'
        End

        -- Verify that @organismDBName is defined in T_Organism_DB_File and that the organism matches up

        If Not Exists (
            SELECT *
            FROM T_Organism_DB_File ODB INNER JOIN
                 T_Organisms O ON ODB.Organism_ID = O.Organism_ID
            WHERE ODB.FileName = @organismDBName AND O.OG_name = @organismName And Active > 0 And Valid > 0
            )
        Begin
            -- Match not found; try matching the name but not the organism
            Declare @OrganismMatch varchar(128) = ''

            SELECT @OrganismMatch = O.OG_name
            FROM T_Organism_DB_File ODB INNER JOIN
                 T_Organisms O ON ODB.Organism_ID = O.Organism_ID
            WHERE (ODB.FileName = @organismDBName) And Active > 0 And Valid > 0
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
            Begin
                Set @message = 'Legacy Fasta file "' + @organismDBName + '" is defined for organism ' + @OrganismMatch + '; you specified organism ' + @organismName + '; cannot continue'
                Return 53120
            End
            Else
            Begin
                -- Match still not found; check if it is disabled

                If Exists (
                    SELECT *
                    FROM T_Organism_DB_File ODB INNER JOIN
                        T_Organisms O ON ODB.Organism_ID = O.Organism_ID
                    WHERE (ODB.FileName = @organismDBName) And (Active = 0 Or Valid = 0)
                    )
                Begin
                    Set @message = 'Legacy Fasta file "' + @organismDBName + '" is disabled and cannot be used (T_Organism_DB_File)'
                    Return 53121
                End
                Else
                Begin
                    Set @message = 'Legacy Fasta file "' + @organismDBName + '" is not a recognized fasta file'
                    Return 53122
                End

            End
        End
    End

    If @debugMode <> 0
    Begin
        Set @message = 'Calling s_validate_analysis_job_protein_parameters: ' +
                           IsNull(@organismName, '??') + '; ' +
                           IsNull(@ownerUsername, '??') + '; ' +
                           IsNull(@organismDBName, '??') + '; ' +
                           IsNull(@protCollNameList, '??') + '; ' +
                           IsNull(@protCollOptionsList, '??')

        Print @message
        -- exec post_log_entry 'Debug',@message, 'validate_protein_collection_params'
        Set @message = ''
    End

    -- Call ProteinSeqs.Protein_Sequences.dbo.validate_analysis_job_protein_parameters
    Exec @result = s_validate_analysis_job_protein_parameters
                       @organismName,
                       @ownerUsername,
                       @organismDBName,
                       @protCollNameList output,
                       @protCollOptionsList output,
                       @message output

    If @result <> 0
    Begin
        Return @result
    End

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[validate_protein_collection_params] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[validate_protein_collection_params] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[validate_protein_collection_params] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[validate_protein_collection_params] TO [Limited_Table_Write] AS [dbo]
GO
