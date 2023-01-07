/****** Object:  View [dbo].[V_Internal_Standards_Postdigest_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Internal_Standards_Postdigest_Picklist
AS
SELECT Internal_Std_Mix_ID AS id,
       name,
       description
FROM dbo.t_internal_standards
WHERE (Active = 'A') AND (Type IN ('Postdigest', 'All')) AND
    (Internal_Std_Mix_ID > 0)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Internal_Standards_Postdigest_Picklist] TO [DDL_Viewer] AS [dbo]
GO
