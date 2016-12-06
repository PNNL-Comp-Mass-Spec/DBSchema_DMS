/****** Object:  View [dbo].[V_LC_Column_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_LC_Column_Entry
AS
SELECT     T_LC_Column.SC_Column_Number, T_LC_Column.SC_Packing_Mfg, T_LC_Column.SC_Packing_Type, T_LC_Column.SC_Particle_size, 
                      T_LC_Column.SC_Particle_type, T_LC_Column.SC_Column_Inner_Dia, T_LC_Column.SC_Column_Outer_Dia, T_LC_Column.SC_Length, 
                      T_LC_Column.SC_Operator_PRN, T_LC_Column.SC_Comment, T_LC_Column.ID, T_LC_Column_State_Name.LCS_Name
FROM         T_LC_Column INNER JOIN
                      T_LC_Column_State_Name ON T_LC_Column.SC_State = T_LC_Column_State_Name.LCS_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Column_Entry] TO [DDL_Viewer] AS [dbo]
GO
