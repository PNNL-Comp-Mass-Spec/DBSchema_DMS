/****** Object:  View [dbo].[V_LC_Column_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Column_List_Report]
AS
SELECT T_LC_Column.SC_Column_Number AS [Column Name], T_LC_Column_State_Name.LCS_Name AS State, T_LC_Column.SC_Created AS Created, 
       T_LC_Column.SC_Packing_Mfg AS [Packing Mfg.], T_LC_Column.SC_Packing_Type AS [Packing Type], 
       T_LC_Column.SC_Particle_size AS [Particle Size], T_LC_Column.SC_Particle_type AS [Particle Type], T_LC_Column.SC_Column_Inner_Dia AS [I.D.], 
       T_LC_Column.SC_Column_Outer_Dia AS [O.D.], T_LC_Column.SC_Length AS Length, T_LC_Column.SC_Operator_PRN AS Operator, 
       T_LC_Column.SC_Comment AS Comment, T_LC_Column.ID As [Column_ID]
FROM T_LC_Column INNER JOIN
     T_LC_Column_State_Name ON T_LC_Column.SC_State = T_LC_Column_State_Name.LCS_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Column_List_Report] TO [DDL_Viewer] AS [dbo]
GO
