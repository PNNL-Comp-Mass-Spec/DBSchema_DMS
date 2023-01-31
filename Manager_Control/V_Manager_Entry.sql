/****** Object:  View [dbo].[V_Manager_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Manager_Entry]
AS
SELECT M_ID AS manager_id,
       M_Name AS manager_name,
       M_ControlFromWebsite AS control_from_website
FROM T_Mgrs


GO
