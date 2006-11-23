/****** Object:  StoredProcedure [dbo].[FindExistingJobsForJobParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FindExistingJobsForJobParams
/****************************************************
**
**	Desc: 
**    Check how many existing jobs already exist that
**    satisfy given set of parameters
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: grk
**		Date: 12/7/2005
**			  04/04/2006 grk - increased sized of param file name
**			  03/28/2006 grk - added protein collection fields
**			  04/07/2006 grk - eliminated job to request map table
**    
*****************************************************/
    @datasetList varchar(3500),
    @priority int = 2,
	@toolName varchar(64),
    @parmFileName varchar(255),
    @settingsFileName varchar(64),
    @organismDBName varchar(64),
    @organismName varchar(64),
	@proteinCollectionList varchar(512),
	@proteinOptionsList varchar(256),
    @ownerPRN varchar(32),
    @comment varchar(255) = null,
    @requestID int,
	@assignedProcessor varchar(64),
	@mode varchar(12), 
	@message varchar(512) output
AS
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
		
	---------------------------------------------------
	-- temporary table to hold dataset list
	---------------------------------------------------
	
	create table #XT (
		dataset varchar(128),
		ID int NULL
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temp table'
		goto Done
	end

	---------------------------------------------------
	-- convert dataset list to table entries
	---------------------------------------------------
	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @tPos int
	set @tPos = 1
	declare @tFld varchar(128)

	set @count = 0
	set @done = 0

	while @done = 0 and @myError = 0
	begin
		set @count = @count + 1

		-- process the  next field from the ID list
		--
		set @tFld = ''
		execute @done = NextField @datasetList, @delim, @tPos output, @tFld output
		
		if @tFld <> ''
		begin
			INSERT INTO #XT (dataset) VALUES (@tFld)
		end
	end

	---------------------------------------------------
	-- get dataset IDs
	---------------------------------------------------
	
	update #XT
	Set ID = T_Dataset.Dataset_ID
	FROM #XT INNER JOIN 
	T_Dataset ON T_Dataset.Dataset_Num = #XT.dataset
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to update dataset IDs'
		goto Done
	end
	
	---------------------------------------------------
	-- convert organism name to ID
	---------------------------------------------------

	declare @organismID int
	execute @organismID = GetOrganismID @organismName

	---------------------------------------------------
	-- convert tool name to ID
	---------------------------------------------------

	declare @analysisToolID int
	execute @analysisToolID = GetAnalysisToolID @toolName

	---------------------------------------------------
	-- look for existing jobs
	---------------------------------------------------


	-- Lookup the ResultType for @toolName
	--
	declare @resultType varchar(32)
	--
	SELECT @resultType = AJT_resultType
	FROM  T_Analysis_Tool
	WHERE AJT_toolName = @toolName
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

	SELECT  AJ.AJ_jobID as Job, 
	ASN.AJS_name as State, 
	AJ.AJ_created as Created, 
	AJ.AJ_start as Start, 
	AJ.AJ_finish as Finish
	FROM
		#XT INNER JOIN
		T_Dataset DS ON #XT.ID = DS.Dataset_ID INNER JOIN
		T_Analysis_Job AJ ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
		T_Analysis_Tool AJT ON AJ.AJ_analysisToolID = AJT.AJT_toolID INNER JOIN
		T_Organisms Org ON AJ.AJ_organismID = Org.Organism_ID  INNER JOIN
        T_Analysis_State_Name ASN ON AJ.AJ_StateID = ASN.AJS_stateID
	WHERE
		AJT.AJT_toolName = @toolName AND 
		AJ.AJ_parmFileName = @parmFileName AND 
		AJ.AJ_settingsFileName = @settingsFileName AND 
		Org.OG_name = IsNull(@organismName, Org.OG_name) AND
		AJ.AJ_proteinCollectionList = IsNull(@proteinCollectionList, AJ.AJ_proteinCollectionList) AND 
		AJ.AJ_proteinOptionsList = IsNull(@proteinOptionsList, AJ.AJ_proteinOptionsList)  
	ORDER BY AJ.AJ_jobID

Done:
	RETURN @myError



GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForJobParams] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForJobParams] TO [DMS_User]
GO
