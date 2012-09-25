/****** Object:  View [dbo].[V_Operations_Tasks_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Operations_Tasks_Entry] AS 
 SELECT 
	ID AS ID,
	Tab AS Tab,
	Requestor AS Requestor,
	Requested_Personal AS RequestedPersonal,
	Assigned_Personal AS AssignedPersonal,
	Description AS Description,
	Comments AS Comments,
	Status AS Status,
	Priority AS Priority,
	Created AS Created
FROM T_Operations_Tasks

GO
