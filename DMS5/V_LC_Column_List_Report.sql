/****** Object:  View [dbo].[V_LC_Column_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Column_List_Report]
AS
SELECT T_LC_Column.SC_Column_Number AS column_name, T_LC_Column_State_Name.LCS_Name AS state, T_LC_Column.SC_Created AS created,
       T_LC_Column.SC_Packing_Mfg AS packing_mfg, T_LC_Column.SC_Packing_Type AS packing_type,
       T_LC_Column.SC_Particle_size AS particle_size, T_LC_Column.SC_Particle_type AS particle_type, T_LC_Column.SC_Column_Inner_Dia AS inner_diam,
       T_LC_Column.SC_Column_Outer_Dia AS outer_diam, T_LC_Column.SC_Length AS length, T_LC_Column.SC_Operator_PRN AS operator,
       T_LC_Column.SC_Comment AS comment, T_LC_Column.ID As column_id
FROM T_LC_Column INNER JOIN
     T_LC_Column_State_Name ON T_LC_Column.SC_State = T_LC_Column_State_Name.LCS_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Column_List_Report] TO [DDL_Viewer] AS [dbo]
GO
