/****** Object:  StoredProcedure [dbo].[refresh_cached_organism_db_info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[refresh_cached_organism_db_info]
/****************************************************
**
**  Desc:
**      Updates T_DMS_Organism_DB_Info in MT_Main
**
**      However, does not delete extra rows; use refresh_cached_organism_db_info in MT_Main for a full synchronization, including deletes
**
**  Return values: 0 if no error; otherwise error code
**
**  Auth:   mem
**  Date:   01/24/2014
**          01/31/2020 mem - Add @returnCode, which duplicates the integer returned by this procedure; @returnCode is varchar for compatibility with Postgres error codes
**          07/27/2022 mem - Tabs to spaces
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(255) = '' output,
    @returnCode varchar(64) = '' output
)
AS
    set nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Set @returnCode = ''

    ---------------------------------------------------
    -- Use a MERGE Statement to synchronize T_DMS_Organism_DB_Info with V_Protein_Collection_List_Export
    ---------------------------------------------------
    --

    MERGE MT_Main.dbo.T_DMS_Organism_DB_Info AS target
    USING (SELECT ID, FileName, Organism, Description, Active,
                  NumProteins, NumResidues, Organism_ID, OrgFile_RowVersion
        FROM MT_Main.dbo.V_DMS_Organism_DB_File_Import
    ) AS Source ( ID, FileName, Organism, Description, Active,
                  NumProteins, NumResidues, Organism_ID, OrgFile_RowVersion)
    ON (target.ID = source.ID)
    WHEN Matched AND ( target.Cached_RowVersion <> Source.OrgFile_RowVersion) THEN
    UPDATE Set
            FileName = Source.FileName,
            Organism = Source.Organism,
            Description = IsNull(Source.Description, ''),
            Active = Source.Active,
            NumProteins = IsNull(Source.NumProteins, 0),
            NumResidues = IsNull(Source.NumResidues, 0),
            Organism_ID = Source.Organism_ID,
            Cached_RowVersion = Source.OrgFile_RowVersion,
            Last_Affected = GetDate()
    WHEN Not Matched THEN
    INSERT ( ID, FileName, Organism, Description, Active,
             NumProteins, NumResidues, Organism_ID, Cached_RowVersion, Last_Affected)
    VALUES ( Source.ID, Source.FileName, Source.Organism, Source.Description, Source.Active,
             Source.NumProteins, Source.NumResidues, Source.Organism_ID, Source.OrgFile_RowVersion, GetDate())
    ;

    Set @returnCode = Cast(@myError As varchar(64))
    Return @myError

GO
GRANT EXECUTE ON [dbo].[refresh_cached_organism_db_info] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[refresh_cached_organism_db_info] TO [proteinseqs\ftms] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[refresh_cached_organism_db_info] TO [svc-dms] AS [dbo]
GO
