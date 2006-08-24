/****** Object:  View [dbo].[V_Internal_Standards_Predigest_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Internal_Standards_Predigest_Picklist
AS
SELECT     Internal_Std_Mix_ID AS ID, Name, Description
FROM         T_Internal_Standards
WHERE     (Internal_Std_Mix_ID > 0) AND (Active = 'A') AND (Type IN ('Predigest', 'All'))

GO
