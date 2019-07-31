/****** Object:  UserDefinedFunction [dbo].[GetExistingJobsMatchingJobRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetExistingJobsMatchingJobRequest]
/****************************************************
**
**  Desc: 
**      Builds delimited list of existing jobs
**      for the given analysis job request, searching
**      for the jobs using the analysis tool name, parameter
**      file name, and settings file name specified by the 
**      analysis request.  For Peptide_Hit tools, also uses 
**      organism DB file name and organism name and
**      protein collection list and protein options list
**
**  Return value: delimited list
**
**  Auth:   grk
**  Date:   12/06/2005 grk - Initial release
**          03/28/2006 grk - added protein collection fields
**          08/30/2006 grk - fixed selection logic to handle auto-generated fasta file names https://prismtrac.pnl.gov/trac/ticket/218
**          01/26/2007 mem - now getting organism name from T_Organisms (Ticket #368)
**          10/11/2007 mem - Expanded protein collection list size to 4000 characters (https://prismtrac.pnl.gov/trac/ticket/545)
**          03/27/2009 mem - Updated Where clause logic for Peptide_Hit jobs to ignore organism name when using a Protein Collection List
**          05/03/2012 mem - Now comparing the special processing field
**          09/25/2012 mem - Expanded @organismDBName to varchar(128)
**          07/30/2019 mem - Get dataset ID from T_Analysis_Job_Request_Datasets
**          07/31/2019 mem - Remove unused table from query join list
**    
*****************************************************/
(
    @requestID int
)
RETURNS @job_list TABLE (
    job int
)
AS
BEGIN

    Declare @myRowCount Int = 0
    Declare @myError Int = 0

    Declare @analysisToolName varchar(64),
            @parmFileName varchar(255),
            @settingsFileName varchar(255),
            @organismDBName varchar(128),
            @organismName varchar(255),
            @resultType varchar(32),
            @proteinCollectionList varchar(4000),
            @proteinOptionsList varchar(256),
            @specialProcessing varchar(512)
        
    -- Lookup the entries for @RequestID in T_Analysis_Job_Request
    --
    SELECT @analysisToolName = AJR.AJR_analysisToolName,
           @parmFileName = AJR.AJR_parmFileName,
           @settingsFileName = AJR.AJR_settingsFileName,
           @organismDBName = AJR.AJR_organismDBName,
           @organismName = Org.OG_Name,
           @proteinCollectionList = AJR.AJR_proteinCollectionList,
           @proteinOptionsList = AJR.AJR_proteinOptionsList,
           @specialProcessing = AJR.AJR_specialProcessing
    FROM T_Analysis_Job_Request AJR
         INNER JOIN T_Organisms Org
           ON AJR.AJR_organism_ID = Org.Organism_ID
    WHERE AJR.AJR_requestID = @RequestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myRowCount = 1
    Begin
        -- Lookup the ResultType for @analysisToolName
        --
        SELECT @resultType = AJT_resultType
        FROM  T_Analysis_Tool
        WHERE AJT_toolName = @analysisToolName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
            
        Set @resultType = IsNull(@resultType, 'Unknown')
            
        -- When looking for existing jobs, if the analysis tool is not a Peptide_Hit tool,
        --  then we ignore OrganismDBName, Organism Name, Protein Collection List, and Protein Options List
        --
        -- If the tool is a Peptide_Hit tool, then we only consider Organism Name when searching
        --  against a legacy Fasta file (i.e. when the Protein Collection List is 'na')

        INSERT INTO @job_list( job )
        SELECT AJ.AJ_jobID
        FROM ( SELECT Dataset_ID
               FROM T_Analysis_Job_Request_Datasets
               WHERE Request_ID = @requestID ) DSList
             INNER JOIN T_Analysis_Job AJ
               ON AJ.AJ_datasetID = DSList.Dataset_ID
             INNER JOIN T_Analysis_Tool AJT
               ON AJ.AJ_analysisToolID = AJT.AJT_toolID
             INNER JOIN T_Organisms Org
               ON AJ.AJ_organismID = Org.Organism_ID
        WHERE AJT.AJT_toolName = @analysisToolName AND
              AJ.AJ_parmFileName = @parmFileName AND
              AJ.AJ_settingsFileName = @settingsFileName AND
              ISNULL(AJ.AJ_specialProcessing, '') = ISNULL(@specialProcessing, '') AND
              (@resultType NOT LIKE '%Peptide_Hit%' OR
               @resultType LIKE '%Peptide_Hit%' AND 
               (
                   (    @proteinCollectionList <> 'na' AND
                        AJ.AJ_proteinCollectionList = @proteinCollectionList AND
                        AJ.AJ_proteinOptionsList = @proteinOptionsList
                   ) OR
                   (    @proteinCollectionList = 'na' AND
                        AJ.AJ_proteinCollectionList = @proteinCollectionList AND
                        AJ.AJ_organismDBName = @organismDBName AND
                        Org.OG_name = @organismName
                   )
               )
              )
        GROUP BY AJ.AJ_jobID
        ORDER BY AJ.AJ_jobID

    End
        
    RETURN
END


GO
GRANT VIEW DEFINITION ON [dbo].[GetExistingJobsMatchingJobRequest] TO [DDL_Viewer] AS [dbo]
GO
