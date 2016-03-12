/****** Object:  View [dbo].[V_Internal_Standards_Predigest_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Internal_Standards_Predigest_Picklist
AS
SELECT Internal_Std_Mix_ID AS ID, Name, Description
FROM dbo.T_Internal_Standards
WHERE (Active = 'A') AND (Type IN ('Predigest', 'All')) AND 
    (Internal_Std_Mix_ID > 0)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Internal_Standards_Predigest_Picklist] TO [PNL\D3M578] AS [dbo]
GO
