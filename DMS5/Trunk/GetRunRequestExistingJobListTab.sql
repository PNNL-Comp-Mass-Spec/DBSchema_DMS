/****** Object:  UserDefinedFunction [dbo].[GetRunRequestExistingJobListTab] ******/
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetRunRequestExistingJobListTab
/****************************************************
**
**	Desc: 
**  Builds delimited list of existing jobs
**  for the given analysis job request, searching
**  for the jobs using the analysis tool name, parameter
**  file name, and settings file name specified by the 
**  analysis request.  For Peptide_Hit tools, also uses 
**  organism DB file name and organism name and
**  protein collection list and protein options list
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk, mem
**		Date: 12/06/2005
**			  03/28/2006 grk - added protein collection fields
**			  08/30/2006 grk - fixed selection logic to handle auto-generated fasta file names https://prismtrac.pnl.gov/trac/ticket/218
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

		declare @myRowCount int
		declare @myError int
		set @myRowCount = 0
		set @myError = 0

		declare @list varchar(1024)
		set @list = ''

		declare @analysisToolName varchar(64),
				@parmFileName varchar(255),
				@settingsFileName varchar(255),
				@organismDBName varchar(64),
				@organismName varchar(255),
				@resultType varchar(32),
				@proteinCollectionList varchar(512),
				@proteinOptionsList varchar(256)
		
		-- Lookup the entries for @RequestID in T_Analysis_Job_Request
		--
		SELECT	@analysisToolName = AJR_analysisToolName, 
				@parmFileName = AJR_parmFileName, 
				@settingsFileName = AJR_settingsFileName, 
				@organismDBName = AJR_organismDBName, 
				@organismName = AJR_organismName,
				@proteinCollectionList =AJR_proteinCollectionList,
				@proteinOptionsList = AJR_proteinOptionsList
		FROM  T_Analysis_Job_Request
		WHERE AJR_requestID = @RequestID
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
			
			-- When looking for existing jobs, filter on organismDBName and organism
			-- only if the analysis tool is a Peptide_Hit tool.  Otherwise, update
			-- organismDBName and organism to NULL so that the following
			-- Select query will effectively ignore them when filtering
			--
			If @resultType NOT LIKE '%Peptide_Hit%'
			Begin
				Set @organismDBName = NULL
				Set @organismName = NULL
				Set @proteinCollectionList  = NULL
				Set @proteinOptionsList  = NULL
			End

			INSERT INTO @job_list
					(job)
			SELECT  AJ.AJ_jobID
			FROM	GetRunRequestDatasetList(@RequestID) DSList INNER JOIN
					T_Dataset DS ON DSList.dataset = DS.Dataset_Num INNER JOIN
					T_Analysis_Job AJ ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
					T_Analysis_Tool AJT ON AJ.AJ_analysisToolID = AJT.AJT_toolID INNER JOIN
					T_Organisms Org ON AJ.AJ_organismID = Org.Organism_ID
			WHERE	AJT.AJT_toolName = @analysisToolName AND 
					AJ.AJ_parmFileName = @parmFileName AND 
					AJ.AJ_settingsFileName = @settingsFileName AND 
					(	(AJ.AJ_organismDBName = IsNull(@organismDBName, AJ.AJ_organismDBName) AND
						 AJ.AJ_proteinCollectionList = IsNull(@proteinCollectionList, AJ.AJ_proteinCollectionList) AND 
						 AJ.AJ_proteinOptionsList = IsNull(@proteinOptionsList, AJ.AJ_proteinOptionsList)
						) OR
						(AJ.AJ_organismDBName <> 'na' AND AJ.AJ_organismDBName = IsNull(@organismDBName, AJ.AJ_organismDBName)) OR
						(AJ.AJ_proteinCollectionList <> 'na' AND
						 AJ.AJ_proteinCollectionList = IsNull(@proteinCollectionList, AJ.AJ_proteinCollectionList) AND 
						 AJ.AJ_proteinOptionsList = IsNull(@proteinOptionsList, AJ.AJ_proteinOptionsList)
						)
					) AND 
					Org.OG_name = IsNull(@organismName, Org.OG_name)
			GROUP BY AJ.AJ_jobID
			ORDER BY AJ.AJ_jobID

		End
		
		RETURN
	END


GO
