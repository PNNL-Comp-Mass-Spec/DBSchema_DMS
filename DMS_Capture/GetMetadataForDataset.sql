/****** Object:  StoredProcedure [dbo].[GetMetadataForDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetMetadataForDataset
/****************************************************
**
**	Desc: Gets metadata for given dataset name
**    into temporary table created by caller
**
**	Return values: 0: success, otherwise, error code
**                    recordset containing keyword-value pairs
**                    for all metadata items
**
**	Parameters: 
**
**		Auth: grk
**		10/29/2009 grk - Initial release
**		11/03/2009 dac - Corrected name of dataset number column in global metadata
**    
*****************************************************/
(
	@datasetNum varchar(128)
)
	As
	set nocount on

	---------------------------------------------------
	-- 
	---------------------------------------------------
	declare @stepParmSectionName varchar(32)
	set @stepParmSectionName = 'Meta'
	--

	---------------------------------------------------
	-- insert "global" metadata
	---------------------------------------------------

	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Investigation', 'Proteomics')
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Instrument_Type', 'Mass spectrometer') 

	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_Number', @datasetNum) 

	---------------------------------------------------
	-- get main metadata
	-- and insert it into temporary table
	---------------------------------------------------

	declare @DS_created datetime
	declare @IN_name varchar(50)
	declare @DS_comment varchar(500)
	declare @DS_sec_sep varchar(64)
	declare @DS_well_num varchar(64)
	declare @Experiment_Num varchar(64)
	declare @EX_researcher_PRN varchar(64)
	declare @EX_organism_name varchar(64)
	declare @EX_comment varchar(500)
	declare @EX_sample_concentration varchar(64)
	declare @EX_lab_notebook_ref varchar(64)
	declare @Campaign_Num varchar(64)
	declare @CM_Project_Num varchar(64)
	declare @CM_comment varchar(500)
	declare @CM_created datetime
	declare @EX_Reason varchar(500)
	declare @EX_cell_culture_list varchar(500)

	--
	SELECT 
	@DS_created = DS_created, 
	@IN_name = IN_name, 
	@DS_comment = DS_comment, 
	@DS_sec_sep= DS_sec_sep, 
	@DS_well_num = DS_well_num, 
	@Experiment_Num = Experiment_Num, 
	@EX_researcher_PRN= EX_researcher_PRN, 
	@EX_organism_name = EX_organism_name, 
	@EX_comment = EX_comment, 
	@EX_sample_concentration = EX_sample_concentration, 
	@EX_lab_notebook_ref = EX_lab_notebook_ref, 
	@Campaign_Num = Campaign_Num, 
	@CM_Project_Num = CM_Project_Num, 
	@CM_comment = CM_comment, 
	@CM_created = CM_created,
	@EX_Reason = EX_Reason, 
	@EX_cell_culture_list = EX_cell_culture_list
	FROM V_DMS_Get_Dataset_Info 
	WHERE (Dataset_Num = @datasetNum)
	--
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_created', @DS_created) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Instrument_name', @IN_name) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_comment', @DS_comment) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_sec_sep', @DS_sec_sep) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Dataset_well_num', @DS_well_num) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_Num', @Experiment_Num) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_researcher_PRN', @EX_researcher_PRN) 

	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_Reason', @EX_Reason) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_Cell_Culture', @EX_cell_culture_list) 

	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_organism_name', @EX_organism_name) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_comment', @EX_comment) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_sample_concentration', @EX_sample_concentration) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Experiment_lab_notebook_ref', @EX_lab_notebook_ref) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_Num', @Campaign_Num) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_Project_Num', @CM_Project_Num) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_comment', @CM_comment) 
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Meta_Campaign_created', @CM_created) 

	---------------------------------------------------
	-- get auxiliary data for experiment 
	-- and insert it into temporary table
	---------------------------------------------------

	INSERT INTO #ParamTab ([Section], [Name], Value)  
	SELECT @stepParmSectionName AS [Section], 'Meta_Aux_Info:' + Target + ':' + Category + '.' + Subcategory + '.' + Item AS [Name], [Value]
	FROM V_DMS_Get_Experiment_Metadata
	WHERE Experiment_Num = @Experiment_Num
	ORDER BY [Name]


	return
GO
