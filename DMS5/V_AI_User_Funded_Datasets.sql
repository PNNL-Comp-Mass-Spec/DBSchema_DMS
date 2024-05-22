/****** Object:  View [dbo].[V_AI_User_Funded_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_AI_User_Funded_Datasets]
AS
SELECT DS.Dataset_Num AS dataset,
       InstName.IN_name AS instrument,
       DS.DS_created AS DATE,
       E.Experiment_Num AS experiment,
       AI.Value AS proposal_number
FROM dbo.T_Experiments E
     INNER JOIN dbo.V_Aux_Info_Value AI
       ON E.Exp_ID = AI.Target_ID
     INNER JOIN dbo.T_Dataset DS
       ON E.Exp_ID = DS.Exp_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
WHERE AI.Target = 'Experiment' AND
      AI.Category = 'Accounting' AND
      AI.Subcategory = 'Funding' AND
      AI.Item = 'Proposal Number' AND
      AI.Value <> ''

GO
GRANT VIEW DEFINITION ON [dbo].[V_AI_User_Funded_Datasets] TO [DDL_Viewer] AS [dbo]
GO
