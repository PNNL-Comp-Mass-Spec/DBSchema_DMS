/****** Object:  View [dbo].[V_Dataset_Instrument_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Instrument_List_Report
AS
SELECT     dbo.T_Instrument_Name.IN_name AS Instrument, dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.Dataset_ID AS ID, 
                      dbo.T_Dataset.DS_created AS Created, dbo.T_Requested_Run.ID AS Request, dbo.T_Requested_Run.RDS_Oper_PRN AS Requestor, 
                      dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Experiments.EX_researcher_PRN AS Researcher, 
                      dbo.T_Campaign.Campaign_Num AS Campaign
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID LEFT OUTER JOIN
                      dbo.T_Requested_Run ON dbo.T_Dataset.Dataset_ID = dbo.T_Requested_Run.DatasetID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Instrument_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Instrument_List_Report] TO [PNL\D3M580] AS [dbo]
GO
