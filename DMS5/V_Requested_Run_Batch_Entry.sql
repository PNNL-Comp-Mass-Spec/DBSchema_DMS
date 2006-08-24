/****** Object:  View [dbo].[V_Requested_Run_Batch_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Requested_Run_Batch_Entry
AS
SELECT     
T_Requested_Run_Batches.ID AS ID, 
T_Requested_Run_Batches.Batch AS Name, 
T_Requested_Run_Batches.Description AS Description, 
dbo.GetBatchRequestedRunList(T_Requested_Run_Batches.ID) AS RequestedRunList, 
T_Users.U_PRN AS OwnerPRN
FROM         T_Requested_Run_Batches INNER JOIN
                      T_Users ON T_Requested_Run_Batches.Owner = T_Users.ID

GO
