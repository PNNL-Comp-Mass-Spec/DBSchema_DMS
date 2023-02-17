/****** Object:  View [dbo].[V_Requested_Run_Batch_Group_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Requested_Run_Batch_Group_Picklist
AS
SELECT Batch_Group_ID AS ID,
       Batch_Group,
       CAST(Batch_Group_ID AS varchar(12)) + ': ' + Batch_Group AS ID_with_Batch_Group
FROM T_Requested_Run_Batch_Group


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Group_Picklist] TO [DDL_Viewer] AS [dbo]
GO
