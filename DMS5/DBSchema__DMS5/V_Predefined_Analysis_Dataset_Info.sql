/****** Object:  View [dbo].[V_Predefined_Analysis_Dataset_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Predefined_Analysis_Dataset_Info
AS
SELECT     dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.T_Experiments.EX_comment AS Experiment_Comment, dbo.T_Experiments.EX_Labelling AS Experiment_Labelling, 
                      dbo.T_Experiments.EX_organism_name AS Organism, dbo.T_Instrument_Name.IN_name AS Instrument, 
                      dbo.T_Instrument_Name.IN_class AS InstrumentClass, dbo.T_Dataset.DS_comment AS Dataset_Comment, dbo.T_Dataset.Dataset_ID AS ID, 
                      dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.DS_rating AS Rating
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID

GO
