/****** Object:  View [dbo].[V_Ext_Dataset_Exists] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Ext_Dataset_Exists]
AS
select AS_Dataset_id as ds_id
from T_Dataset_Archive DA
	join T_DatasetArchiveStateName DASN on DA.AS_state_ID = DASN.DASN_StateID and DASN.DASN_StateName = 'complete'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Dataset_Exists] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Dataset_Exists] TO [PNL\D3M580] AS [dbo]
GO
