/****** Object:  View [dbo].[V_Internal_Standards_Postdigest_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Internal_Standards_Postdigest_Picklist
AS
SELECT Internal_Std_Mix_ID AS ID, Name, Description
FROM dbo.T_Internal_Standards
WHERE (Active = 'A') AND (Type IN ('Postdigest', 'All')) AND 
    (Internal_Std_Mix_ID > 0)

GO
