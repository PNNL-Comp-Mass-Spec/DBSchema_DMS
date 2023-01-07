/****** Object:  View [dbo].[V_LC_Column_Dataset_Count] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Column_Dataset_Count]
AS
Select T_LC_Column.SC_Column_Number AS column_name,
       T_LC_Column_State_Name.LCS_Name AS state,
       COUNT(T_Dataset.Dataset_ID) AS number_of_datasets
FROM T_Dataset INNER JOIN
     T_LC_Column ON T_Dataset.DS_LC_column_ID = T_LC_Column.ID INNER JOIN
     T_LC_Column_State_Name ON T_LC_Column.SC_State = T_LC_Column_State_Name.LCS_ID
GROUP BY T_LC_Column.SC_Column_Number, T_LC_Column_State_Name.LCS_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Column_Dataset_Count] TO [DDL_Viewer] AS [dbo]
GO
