/****** Object:  View [dbo].[V_AI_User_Funded_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_AI_User_Funded_Datasets]
AS
SELECT dbo.T_Dataset.Dataset_Num, 
   dbo.T_Instrument_Name.IN_name AS Instrument, 
   dbo.T_Dataset.DS_created AS Date, T.Experiment, 
   AI.Value AS [Proposal Number]
FROM dbo.V_Experiment_Detail_Report_Ex T INNER JOIN
   dbo.V_Aux_Info_Value AI ON T.ID = AI.Target_ID INNER JOIN
   dbo.T_Dataset ON T.ID = dbo.T_Dataset.Exp_ID INNER JOIN
   dbo.T_Instrument_Name ON 
   dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
WHERE (AI.Target = 'Experiment') AND (AI.Category = 'Accounting') 
   AND (AI.Subcategory = 'Funding') AND 
   (AI.Item = 'Proposal Number') AND (AI.Value <> '')

GO
GRANT VIEW DEFINITION ON [dbo].[V_AI_User_Funded_Datasets] TO [DDL_Viewer] AS [dbo]
GO
