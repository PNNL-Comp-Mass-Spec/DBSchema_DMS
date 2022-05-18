/****** Object:  View [dbo].[V_Biomaterial_Type_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Biomaterial_Type_Picklist
AS
SELECT ID, Name
FROM T_Cell_Culture_Type_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Type_Picklist] TO [DDL_Viewer] AS [dbo]
GO
