/****** Object:  View [dbo].[V_Data_Package_Analysis_Jobs_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Analysis_Jobs_Export]
AS
SELECT Data_Pkg_ID,
       Job,
       Dataset,
       Tool,
       Package_Comment,
       Item_Added,
       Data_Pkg_ID AS Data_Package_ID
FROM dbo.T_Data_Package_Analysis_Jobs

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Analysis_Jobs_Export] TO [DDL_Viewer] AS [dbo]
GO
