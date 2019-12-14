/****** Object:  View [dbo].[V_ParamID_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_ParamID_Entry]
AS
SELECT ParamID,
       ParamName,
       PicklistName,
       Comment
FROM T_ParamType


GO
