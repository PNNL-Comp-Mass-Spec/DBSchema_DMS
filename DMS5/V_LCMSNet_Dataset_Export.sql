/****** Object:  View [dbo].[V_LCMSNet_Dataset_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LCMSNet_Dataset_Export]
AS
SELECT DS.Dataset_Num AS Dataset,
       E.Experiment_Num AS Experiment,
	   DS.DS_created AS Created,
	   DS.Dataset_ID AS ID,
	   DSN.DSS_name AS State,
	   Inst.IN_name AS Instrument       
FROM T_Dataset DS
     INNER JOIN T_DatasetStateName DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
     INNER JOIN T_Instrument_Name Inst
       ON DS.DS_instrument_name_ID = Inst.Instrument_ID    
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID     
WHERE E.Experiment_Num <> 'Tracking'


GO
GRANT VIEW DEFINITION ON [dbo].[V_LCMSNet_Dataset_Export] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LCMSNet_Dataset_Export] TO [PNL\D3M580] AS [dbo]
GO
