/****** Object:  StoredProcedure [dbo].[ReindexDatabase] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ReindexDatabase
/****************************************************
**
**	Desc: 
**		Reindexes the key tables in the database
**
**		To view the tables with the largest indices, use:
**
**			SELECT Table_Name,
**				   SUM(Space_Used_MB) AS Total_Space_Used
**			FROM dbo.V_Table_Index_Sizes
**			GROUP BY Table_Name
**			ORDER BY Total_Space_Used DESC
**
**	Return values: 0:  success, otherwise, error code
**
**	Auth:	mem
**	Date:	05/21/2008
**			08/05/2010 mem - Added 6 new tables to reindex
**			11/21/2012 mem - Removed T_Analysis_Log
**			05/28/2015 mem - Removed T_Analysis_Job_Processor_Group_Associations
**    
*****************************************************/
(
	@message varchar(512) = '' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowcount int
	set @myRowcount = 0
	set @myError = 0
	
	Declare @TableCount int
	Set @TableCount = 0

	declare @UpdateEnabled tinyint
	
	Set @message = ''
	
	-----------------------------------------------------------
	-- Reindex the data tables
	-----------------------------------------------------------
	DBCC DBREINDEX (T_Event_Log, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_AuxInfo_Value, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Analysis_Job_Status_History, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Analysis_Job, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Analysis_Job_ID, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Dataset, '', 90)
	Set @TableCount = @TableCount + 1
		
	DBCC DBREINDEX (T_Dataset_Archive, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Dataset_ScanTypes, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Experiments, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Experiment_Cell_Cultures, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Experiment_Group_Members, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Health_Entries, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Log_Entries, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Filter_Set_Criteria, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Material_Locations, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Analysis_Job_Request, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Sample_Prep_Request_Updates, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Requested_Run_EUS_Users, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Requested_Run, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Analysis_Job_Batches, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Param_File_Mass_Mods, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Experiment_Groups, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Param_Entries, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_LC_Column, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Cell_Culture, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Param_Files, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_EUS_Proposals, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Sample_Prep_Request, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Requested_Run_Batches, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Organism_DB_File, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_EUS_Proposal_Users, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Campaign, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Filter_Set_Criteria_Groups, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Predefined_Analysis, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Users, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Experiment_Annotations, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_EUS_Users, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Organisms, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Acceptable_Param_Entries, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_Material_Log, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_MTS_PT_DB_Jobs_Cached, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_MTS_MT_DB_Jobs_Cached, '', 90)
	Set @TableCount = @TableCount + 1
	
	DBCC DBREINDEX (T_MTS_Peak_Matching_Tasks_Cached, '', 90)
	Set @TableCount = @TableCount + 1

	-----------------------------------------------------------
	-- Log the reindex
	-----------------------------------------------------------
	
	Set @message = 'Reindexed ' + Convert(varchar(12), @TableCount) + ' tables'
	Exec PostLogEntry 'Normal', @message, 'ReindexDatabase'

Done:
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ReindexDatabase] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReindexDatabase] TO [Limited_Table_Write] AS [dbo]
GO
