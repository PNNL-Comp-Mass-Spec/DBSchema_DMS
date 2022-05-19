/****** Object:  View [dbo].[V_Requested_Run_Batch_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Requested_Run_Batch_Picklist
As
SELECT ID, Batch, CAST(ID As VARCHAR(12)) + ': ' + Batch As ID_with_Batch
FROM T_Requested_Run_Batches 


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Picklist] TO [DDL_Viewer] AS [dbo]
GO
