/****** Object:  View [dbo].[V_Param_ID_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_ID_Entry]
AS
SELECT ParamID As param_id,
       ParamName As param_name,
       PicklistName As picklist_name,
       comment
FROM T_ParamType


GO
