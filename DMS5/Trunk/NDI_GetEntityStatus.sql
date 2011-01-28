/****** Object:  StoredProcedure [dbo].[NDI_GetEntityStatus] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE NDI_GetEntityStatus 
/****************************************************
**
**	Desc: Gets Process Status for a given DMS 
**        Processing Entity (Request, Dataset, Analysis Job)
**
**	Return values: 0: success, otherwise, error number
**
**	Parameters: 
**
**		Auth: kja
**		Date: 06/02/2006
**    
*****************************************************/
(
		@entityID int,
		@entityType varchar(64),
		@entityStatus varchar(64) output,
		@message varchar(256) output
)
As

	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @result int
	
	declare @msg varchar(256)
	
	declare @checkTableName varchar(128)
	declare @statusFieldName varchar(128)
	declare @tmpEntityStatus varchar(64)

	---------------------------------------------------
	-- Validate input
	---------------------------------------------------
	
	if @entityType = 'RunRequest'
	begin
		set @checkTableName = 'V_DEPkgr_All_Run_Requests'
		set @statusFieldName = 'Completed'
	end
	/*	Possible States:
		0 - Incomplete
		1 - Complete
	*/
	
	if @entityType = 'Dataset'
	begin
		set @checkTableName = 'V_DEPkgr_Datasets'
		set @statusFieldName = 'Dataset_Status'
	/*  Possible States:
		'New'
		'Capture In Progress'
		'Complete'
		'Inactive'
		'Capture Failed'
		'Received'
		'Not Ready'
		'Restore Required'
		'Restore In Progress'
		'Restore Failed'
		'Prep. In Progress'
		'Preparation Failed'
	*/
	end

	if @entityType = 'AnalysisRequest'
	begin
		set @checkTableName = 'V_DEPkgr_Analysis_Request'
		set @statusFieldName = 'State'  
	/*	Possible States:
		'na'
		'New'
		'Used'
		'Inactive'
		'Incomplete'
	*/
	end
	
	if @entityType = 'AnalysisJob'
	begin
		set @checkTableName = 'V_DEPkgr_Analysis_Jobs'
		set @statusFieldName = 'Analysis_Job_State'
	end
	/*	Possible States:
		'(none)'
		'New'
		'Job In Progress'
		'Results Received'
		'Complete'
		'Failed'
		'Transfer Failed'
		'No Intermediate Files Created'
		'Holding'
		'Transfer In Progress'
		'Spectra Required'
		'Spectra Req. In Progress'
		'Spectra Req. Failed'
		'No Export'
		'SpecialClusterFailed'
		'Data Extraction Required'
		'Data Extraction In Progress'
		'Data Extraction Failed'
	*/
GO
GRANT VIEW DEFINITION ON [dbo].[NDI_GetEntityStatus] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NDI_GetEntityStatus] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[NDI_GetEntityStatus] TO [PNL\D3M580] AS [dbo]
GO
