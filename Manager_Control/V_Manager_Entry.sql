/****** Object:  View [dbo].[V_Manager_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Manager_Entry]
AS
SELECT M_ID AS ManagerID,
       M_Name AS ManagerName,
       M_ControlFromWebsite AS ControlFromWebsite
FROM T_Mgrs

GO
