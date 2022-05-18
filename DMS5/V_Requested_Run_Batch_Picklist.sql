/****** Object:  View [dbo].[V_Requested_Run_Batch_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Requested_Run_Batch_Picklist
As
SELECT ID, Batch As Name, CAST(ID AS VARCHAR(12)) + ': ' + Batch As Id_with_Name
FROM T_Requested_Run_Batches   


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Picklist] TO [DDL_Viewer] AS [dbo]
GO
