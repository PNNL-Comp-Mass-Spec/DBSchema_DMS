/****** Object:  StoredProcedure [dbo].[ValidateProteinCollectionParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ValidateProteinCollectionParams]
/****************************************************
**
**  Desc:   Validates the organism DB and/or protein collection options
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   08/26/2010
**          05/15/2012 mem - Now verifying that @organismDBName is 'na' if @protCollNameList is defined, or vice versa
**          09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**          08/19/2013 mem - Auto-clearing @organismDBName if both @organismDBName and @protCollNameList are defined and @organismDBName is the auto-generated FASTA file for the specified protein collection
**          07/12/2016 mem - Now using a synonym when calling validate_analysis_job_protein_parameters in the Protein_Sequences database
**          04/11/2022 mem - Increase warning threshold for length of @protCollNameList to 4000
**
*****************************************************/
(
    @toolName varchar(64),                      -- If blank, then will assume @orgDbReqd=1
    @organismDBName varchar(128) output,
    @organismName varchar(128),
    @protCollNameList varchar(4000) output,     -- Will raise an error if over 4000 characters long; necessary since the Broker DB (DMS_Pipeline) has a 4000 character limit on analysis job parameter values
    @protCollOptionsList varchar(256) output,
    @ownerPRN varchar(64) = '',                 -- Only required if the user chooses an "Encrypted" protein collection; as of August 2010 we don't have any encrypted protein collections
    @message varchar(255) = '' output,
    @debugMode tinyint = 0                      -- If non-zero then will display some debug info
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @result int

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    Set @message = ''
    Set @ownerPRN = IsNull(@ownerPRN, '')
    Set @debugMode = IsNull(@debugMode, 0)

    ---------------------------------------------------
    -- Make sure settings for which 'na' is acceptable truly have lowercase 'na' and not 'NA' or 'n/a'
    -- Note that Sql server string comparisons are not case-sensitive, but VB.NET string comparisons are
    --  Therefore, @settingsFileName needs to be lowercase 'na' for compatibility with the analysis manager
    ---------------------------------------------------
    --
    Set @organismDBName =      dbo.ValidateNAParameter(@organismDBName, 1)
    Set @protCollNameList =    dbo.ValidateNAParameter(@protCollNameList, 1)
    Set @protCollOptionsList = dbo.ValidateNAParameter(@protCollOptionsList, 1)


    if @organismDBName = '' set @organismDBName = 'na'
    if @protCollNameList = '' set @protCollNameList = 'na'
    if @protCollOptionsList = '' set @protCollOptionsList = 'na'

    ---------------------------------------------------
    -- Lookup orgDbReqd for the analysis tool
    ---------------------------------------------------
    --
    declare @orgDbReqd int
    set @orgDbReqd = 0

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
        if @myError <> 0
        begin
            set @message = 'Error looking up tool parameters'
            return 51038
        end

        if @myRowCount = 0
        begin
            set @message = 'Invalid analysis tool "' + @toolName + '"; not found in T_Analysis_Tool'
            return 51039
        end
    End

    ---------------------------------------------------
    -- Validate the protein collection info
    ---------------------------------------------------

    if Len(@protCollNameList) > 4000
    begin
        set @message = 'Protein collection list is too long; maximum length is 4000 characters'
        return 53110
    end
    --
    if @orgDbReqd = 0
    begin
        if @organismDBName <> 'na' OR @protCollNameList <> 'na' OR @protCollOptionsList <> 'na'
        begin
            set @message = 'Protein parameters must all be "na"; you have: Legacy Fasta (OrgDBName) = "' + @organismDBName + '", ProteinCollectionList = "' + @protCollNameList + '", ProteinOptionsList = "' + @protCollOptionsList + '"'
            return 53093
        end
    end
    else
    begin
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
                set @message = 'Cannot define both a Legacy Fasta file and a Protein Collection List; one must be "na"'
                return 53104
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
                WHERE (ODB.FileName = @organismDBName) AND (O.OG_name = @organismName) And Active > 0 And Valid > 0
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
                --

                If @myRowCount > 0
                Begin
                    set @message = 'Legacy Fasta file "' + @organismDBName + '" is defined for organism ' + @OrganismMatch + '; you specified organism ' + @organismName + '; cannot continue'
                    return 53120
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
                        set @message = 'Legacy Fasta file "' + @organismDBName + '" is disabled and cannot be used (T_Organism_DB_File)'
                        return 53121
                    End
                    Else
                    Begin
                        set @message = 'Legacy Fasta file "' + @organismDBName + '" is not a recognized fasta file'
                        return 53122
                    End

                End

            End


        End

        if @debugMode <> 0
        begin
            Set @message =  'Calling s_validate_analysis_job_protein_parameters: ' +
                                IsNull(@organismName, '??') + '; ' +
                                IsNull(@ownerPRN, '??') + '; ' +
                                IsNull(@organismDBName, '??') + '; ' +
                                IsNull(@protCollNameList, '??') + '; ' +
                                IsNull(@protCollOptionsList, '??')

            Print @message
            -- exec PostLogEntry 'Debug',@message, 'ValidateProteinCollectionParams'
            Set @message = ''
        end

        -- Call ProteinSeqs.Protein_Sequences.dbo.validate_analysis_job_protein_parameters
        exec @result = s_validate_analysis_job_protein_parameters
                            @organismName,
                            @ownerPRN,
                            @organismDBName,
                            @protCollNameList output,
                            @protCollOptionsList output,
                            @message output


        if @result <> 0
        begin
            return 53108
        end
    end

    return 0
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionParams] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ValidateProteinCollectionParams] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ValidateProteinCollectionParams] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateProteinCollectionParams] TO [Limited_Table_Write] AS [dbo]
GO
