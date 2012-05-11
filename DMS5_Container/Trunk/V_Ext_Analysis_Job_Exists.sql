/****** Object:  View [dbo].[V_Ext_Analysis_Job_Exists] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Ext_Analysis_Job_Exists]
AS
SELECT AJ_jobID as aj_id
FROM T_Analysis_Job AJ1
	JOIN T_Dataset_Archive DSA ON DSA.AS_Dataset_ID = AJ1.AJ_DatasetID 
	JOIN T_DatasetArchiveStateName DSN ON DSN.DASN_StateID = DSA.AS_state_ID AND DSN.DASN_StateName = 'Complete'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Analysis_Job_Exists] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Analysis_Job_Exists] TO [PNL\D3M580] AS [dbo]
GO
