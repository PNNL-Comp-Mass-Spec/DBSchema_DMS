/****** Object:  View [dbo].[V_LC_Column_Dataset_Count] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_LC_Column_Dataset_Count
AS
SELECT     T_LC_Column.SC_Column_Number AS [Column Number], T_LC_Column_State_Name.LCS_Name AS State, COUNT(T_Dataset.Dataset_ID) 
                      AS [Number of Datasets]
FROM         T_Dataset INNER JOIN
                      T_LC_Column ON T_Dataset.DS_LC_column_ID = T_LC_Column.ID INNER JOIN
                      T_LC_Column_State_Name ON T_LC_Column.SC_State = T_LC_Column_State_Name.LCS_ID
GROUP BY T_LC_Column.SC_Column_Number, T_LC_Column_State_Name.LCS_Name

GO
