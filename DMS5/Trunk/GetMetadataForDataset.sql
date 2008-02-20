/****** Object:  StoredProcedure [dbo].[GetMetadataForDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure GetMetadataForDataset
/****************************************************
**
**	Desc: Gets metadata for given dataset name
**
**	Return values: 0: success, otherwise, error code
**                    recordset containing keyword-value pairs
**                    for all metadata items
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 4/9/2002
**		Modified: DAC, 02/18/2008 -- changed @datasetNum from 64 chars to 128 to be consistent
**                                 with max length allowed in dataset table
**    
*****************************************************/
 (
  @datasetNum varchar(128)
 )
As
 set nocount on
 
 ---------------------------------------------------
 -- temporary table to hold metadata pairs
 ---------------------------------------------------

 Create Table #metaD
  (
  mTag varchar(250) Not Null,
  mVal varchar(500)  Null
  )
  
 ---------------------------------------------------
 -- insert "global" metadata
 ---------------------------------------------------

 INSERT INTO #metaD(mTag, mVal) VALUES ('Investigation', 'Proteomics')
 INSERT INTO #metaD(mTag, mVal) VALUES ('Instrument_Type', 'Mass spectrometer') 
 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Dataset Number', @datasetNum) 
 
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
 FROM V_DatasetFullDetails 
 WHERE (Dataset_Num = @datasetNum)
 --
 INSERT INTO #metaD(mTag, mVal) VALUES ('Dataset_created', @DS_created) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Instrument_name', @IN_name) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Dataset_comment', @DS_comment) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Dataset_sec_sep', @DS_sec_sep) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Dataset_well_num', @DS_well_num) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Experiment_Num', @Experiment_Num) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Experiment_researcher_PRN', @EX_researcher_PRN) 

 INSERT INTO #metaD(mTag, mVal) VALUES ('Experiment_Reason', @EX_Reason) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Experiment_Cell_Culture', @EX_cell_culture_list) 

 INSERT INTO #metaD(mTag, mVal) VALUES ('Experiment_organism_name', @EX_organism_name) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Experiment_comment', @EX_comment) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Experiment_sample_concentration', @EX_sample_concentration) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Experiment_lab_notebook_ref', @EX_lab_notebook_ref) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Campaign_Num', @Campaign_Num) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Campaign_Project_Num', @CM_Project_Num) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Campaign_comment', @CM_comment) 
 INSERT INTO #metaD(mTag, mVal) VALUES ('Campaign_created', @CM_created) 

/**/
 ---------------------------------------------------
 -- get auxiliary data for dataset 
 -- and insert it into temporary table
 ---------------------------------------------------
 
 INSERT INTO #metaD(mTag, mVal)
 SELECT AI.Target + ':' + AI.Category + '.' + AI.Subcategory + '.' + AI.Item AS Tag, 
   AI.Value
 FROM T_Dataset T INNER JOIN
   V_AuxInfo_Value AI ON T.Dataset_ID = AI.Target_ID
 WHERE (AI.Target = 'Dataset') AND 
   (T.Dataset_Num = @datasetNum)
 Order by Tag
   
 ---------------------------------------------------
 -- get auxiliary data for experiment 
 -- and insert it into temporary table
 ---------------------------------------------------

 INSERT INTO #metaD(mTag, mVal)
 SELECT AI.Target + ':' + AI.Category + '.' + AI.Subcategory + '.' + AI.Item AS Tag, 
   AI.Value
 FROM T_Experiments T INNER JOIN
   V_AuxInfo_Value AI ON T.Exp_ID = AI.Target_ID
 WHERE (AI.Target = 'Experiment') AND 
   (T.Experiment_Num = @Experiment_Num)
 Order by Tag

 set nocount off
 
 ---------------------------------------------------
 -- export contents of temporary table into recordset
 ---------------------------------------------------

 select * from #metaD
 
 return
GO
GRANT EXECUTE ON [dbo].[GetMetadataForDataset] TO [DMS_SP_User]
GO
GRANT EXECUTE ON [dbo].[GetMetadataForDataset] TO [DMSWebUser]
GO
