/****** Object:  View [dbo].[V_Entity_Rename_Log] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Entity_Rename_Log]
AS
SELECT ERL.Entry_ID,
       ERL.Target_Type,
       ET.Name,
       ERL.Target_ID,
       ERL.Old_Name,
       ERL.New_Name,
       ERL.Entered,
       ERL.Entered_By,
       ET.Target_Table,
       ET.Target_ID_Column
FROM dbo.T_Entity_Rename_Log AS ERL
     INNER JOIN dbo.T_Event_Target AS ET
       ON ERL.Target_Type = ET.ID


GO
