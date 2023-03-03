/****** Object:  View [dbo].[V_DatasetDetails_Analysis] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_DatasetDetails_Analysis
AS
SELECT     dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Dataset.Dataset_Num AS Dataset,
                      dbo.T_Instrument_Name.IN_name AS Instrument, dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path AS Path,
                      dbo.T_Dataset.DS_folder_name AS Folder, dbo.T_Organisms.OG_name AS Organism, dbo.T_Dataset_State_Name.DSS_name AS State,
                      dbo.T_Dataset_Type_Name.DST_name AS Type, dbo.T_Dataset.DS_created AS Created, dbo.T_Experiments.EX_comment,
                      dbo.T_Dataset_Rating_Name.DRN_name AS Rating
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Dataset_State_Name ON dbo.T_Dataset.DS_state_ID = dbo.T_Dataset_State_Name.Dataset_state_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Dataset_Type_Name ON dbo.T_Dataset.DS_type_ID = dbo.T_Dataset_Type_Name.DST_Type_ID INNER JOIN
                      dbo.T_Dataset_Rating_Name ON dbo.T_Dataset.DS_rating = dbo.T_Dataset_Rating_Name.DRN_state_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_DatasetDetails_Analysis] TO [DDL_Viewer] AS [dbo]
GO
