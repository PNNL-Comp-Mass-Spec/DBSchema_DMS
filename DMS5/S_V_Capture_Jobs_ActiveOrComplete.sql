/****** Object:  Synonym [dbo].[S_V_Capture_Jobs_ActiveOrComplete] ******/
CREATE SYNONYM [dbo].[S_V_Capture_Jobs_ActiveOrComplete] FOR [DMS_Capture].[dbo].[V_Capture_Jobs_ActiveOrComplete]
GO
GRANT VIEW DEFINITION ON [dbo].[S_V_Capture_Jobs_ActiveOrComplete] TO [DDL_Viewer] AS [dbo]
GO
