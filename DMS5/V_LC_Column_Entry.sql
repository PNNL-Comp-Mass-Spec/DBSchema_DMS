/****** Object:  View [dbo].[V_LC_Column_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_LC_Column_Entry]
AS
SELECT C.SC_Column_Number AS lc_column,
       C.SC_Packing_Mfg AS packing_mfg,
       C.SC_Packing_Type AS packing_type,
       C.SC_Particle_size AS particle_size,
       C.SC_Particle_type AS particle_type,
       C.SC_Column_Inner_Dia AS column_inner_dia,
       C.SC_Column_Outer_Dia AS column_outer_dia,
       C.SC_Length AS column_length,
       C.SC_Operator_PRN AS operator_username,
       C.SC_Comment AS comment,
       C.id As column_id,
       SN.LCS_Name AS column_state
FROM T_LC_Column C
     INNER JOIN T_LC_Column_State_Name SN
       ON C.SC_State = SN.LCS_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Column_Entry] TO [DDL_Viewer] AS [dbo]
GO
