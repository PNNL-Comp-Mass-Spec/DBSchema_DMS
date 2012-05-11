/****** Object:  View [dbo].[V_Ext_Experiment_Exists] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Ext_Experiment_Exists]
AS
SELECT DISTINCT EX1.Exp_ID as ex_id
FROM T_Experiments EX1
	JOIN T_Dataset D ON D.Exp_ID = EX1.Exp_ID 
	JOIN T_Dataset_Archive DSA ON DSA.AS_Dataset_ID = D.Dataset_ID 
	JOIN T_DatasetArchiveStateName DSN ON DSN.DASN_StateID = DSA.AS_state_ID AND DSN.DASN_StateName = 'Complete'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Experiment_Exists] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Experiment_Exists] TO [PNL\D3M580] AS [dbo]
GO
