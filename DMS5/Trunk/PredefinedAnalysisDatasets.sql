/****** Object:  StoredProcedure [dbo].[PredefinedAnalysisDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE PredefinedAnalysisDatasets
/****************************************************
** 
**  Desc: 
**  Shows datasets that satisfy 
**  a given predefined analysis rule 
**
**  Return values: 0: success, otherwise, error code
** 
**  Parameters:
**
**  Auth:	grk
**  Date:	06/22/2005
**			03/03/2006 mem - Fixed bug involving evaluation of @datasetNameCriteria
**			08/06/2008 mem - Added new filter criteria: SeparationType, CampaignExclusion, ExperimentExclusion, and DatasetExclusion (Ticket #684)
**    
*****************************************************/
	@ruleID int,
	@message varchar(512) output
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	---------------------------------------------------
	-- 
	---------------------------------------------------


	declare @instrumentClassCriteria varchar(1024)
	declare @campaignNameCriteria varchar(1024)
	declare @experimentNameCriteria varchar(1024)
	declare @instrumentNameCriteria varchar(1024)
	declare @organismNameCriteria varchar(1024)
	declare @labellingInclCriteria varchar(1024)
	declare @labellingExclCriteria varchar(1024)
	declare @datasetNameCriteria varchar(1024)
	declare @expCommentCriteria varchar(1024)

	declare @separationTypeCriteria varchar(64)
	declare @campaignExclCriteria varchar(128)
	declare @experimentExclCriteria varchar(128)
	declare @datasetExclCriteria varchar(128)	


	SELECT     
		@instrumentClassCriteria = AD_instrumentClassCriteria,
		@campaignNameCriteria = AD_campaignNameCriteria,
		@experimentNameCriteria = AD_experimentNameCriteria,
		@instrumentNameCriteria = AD_instrumentNameCriteria,
		@organismNameCriteria = AD_organismNameCriteria,
		@labellingInclCriteria = AD_labellingInclCriteria,
		@labellingExclCriteria = AD_labellingExclCriteria,
		@datasetNameCriteria = AD_datasetNameCriteria,
		@expCommentCriteria = AD_expCommentCriteria,
		@separationTypeCriteria = AD_separationTypeCriteria,
		@campaignExclCriteria = AD_campaignExclCriteria,
		@experimentExclCriteria = AD_experimentExclCriteria,
		@datasetExclCriteria = AD_datasetExclCriteria
	FROM T_Predefined_Analysis
	WHERE (AD_ID = @ruleID )

/*
	print 'InstrumentClass: ' + @instrumentClassCriteria
	print 'CampaignName: ' + @campaignNameCriteria 
	print 'Experiment: ' + @experimentNameCriteria 
	print 'InstrumentName: ' + @instrumentNameCriteria 
	print 'OrganismName: ' + @organismNameCriteria 
	print 'LabellingIncl: ' + @labellingInclCriteria 
	print 'LabellingExcl: ' + @labellingExclCriteria 
	print 'DatasetName: ' + @datasetNameCriteria
	print 'ExperimentComment: ' + @expCommentCriteria
	print 'SeparationType: ' + @separationTypeCriteria
	print 'CampaignExcl: ' + @campaignExclCriteria
	print 'ExperimentExcl: ' + @experimentExclCriteria
	print 'DatasetExcl: ' + @datasetExclCriteria
*/

	SELECT Dataset,
	       ID,
	       InstrumentClass,
	       Instrument,
	       Campaign,
	       Experiment,
	       Organism,
	       Experiment_Labelling,
	       Experiment_Comment,
	       Dataset_Comment,
	       Separation_Type
	FROM V_Predefined_Analysis_Dataset_Info
	WHERE	((InstrumentClass LIKE @instrumentClassCriteria) OR (@instrumentClassCriteria = '')) 
		AND ((Instrument LIKE @instrumentNameCriteria) OR (@instrumentNameCriteria = '')) 
		AND ((Campaign LIKE  @campaignNameCriteria) OR (@campaignNameCriteria = '')) 
		AND ((Experiment LIKE @experimentNameCriteria) OR (@experimentNameCriteria = '')) 
		AND ((Experiment_Labelling LIKE  @labellingInclCriteria) OR (@labellingInclCriteria = '')) 
		AND (NOT(Experiment_Labelling LIKE @labellingExclCriteria) OR (@labellingExclCriteria = ''))
		AND ((Separation_Type LIKE @separationTypeCriteria) OR (@separationTypeCriteria = '')) 
		AND (NOT (Campaign LIKE @campaignExclCriteria) OR (@campaignExclCriteria = ''))
		AND (NOT (Experiment LIKE @experimentExclCriteria) OR (@experimentExclCriteria = ''))
		AND (NOT (Dataset LIKE @datasetExclCriteria) OR (@datasetExclCriteria = ''))
		AND ((Organism LIKE @organismNameCriteria) OR (@organismNameCriteria = '')) 
		AND ((Dataset LIKE @datasetNameCriteria) OR (@datasetNameCriteria = '')) 
		AND ((Experiment_Comment LIKE @expCommentCriteria) OR (@expCommentCriteria = '')) 
	ORDER BY ID DESC

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[PredefinedAnalysisDatasets] TO [DMS_User]
GO
GRANT EXECUTE ON [dbo].[PredefinedAnalysisDatasets] TO [DMS2_SP_User]
GO
