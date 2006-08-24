/****** Object:  View [dbo].[V_Dataset_Instrument_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Dataset_Instrument_List_Report
AS
SELECT     T_Instrument_Name.IN_name AS Instrument, T_Dataset.Dataset_Num AS Dataset, T_Dataset.Dataset_ID AS ID, T_Dataset.DS_created AS Created, 
                      T_Requested_Run_History.ID AS Request, T_Requested_Run_History.RDS_Oper_PRN AS Requestor, T_Experiments.Experiment_Num AS Experiment,
                       T_Experiments.EX_researcher_PRN AS Researcher, T_Campaign.Campaign_Num AS Campaign
FROM         T_Dataset INNER JOIN
                      T_Experiments ON T_Dataset.Exp_ID = T_Experiments.Exp_ID INNER JOIN
                      T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
                      T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID LEFT OUTER JOIN
                      T_Requested_Run_History ON T_Dataset.Dataset_ID = T_Requested_Run_History.DatasetID


GO
