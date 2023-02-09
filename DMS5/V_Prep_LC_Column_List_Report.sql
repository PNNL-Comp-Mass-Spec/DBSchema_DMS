/****** Object:  View [dbo].[V_Prep_LC_Column_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Prep_LC_Column_List_Report]
AS
SELECT LC_Col.Column_Name AS column_name,
       LC_Col.Mfg_Name AS mfg_name,
       LC_Col.Mfg_Model AS mfg_model,
       LC_Col.Mfg_Serial_Number AS mfg_serial_number,
       LC_Col.Packing_Mfg AS packing_mfg,
       LC_Col.Packing_Type AS packing_type,
       LC_Col.Particle_size AS particle_size,
       LC_Col.Particle_type AS particle_type,
       LC_Col.Column_Inner_Dia AS column_inner_dia,
       LC_Col.Column_Outer_Dia AS column_outer_dia,
       LC_Col.length,
       SUM(Run.Number_Of_Runs) AS runs,
       LC_Col.state,
       LC_Col.Operator_PRN AS operator_username,
       LC_Col.comment,
       LC_Col.created
FROM dbo.T_Prep_LC_Column LC_Col LEFT OUTER JOIN
                      dbo.T_Prep_LC_Run Run ON LC_Col.Column_Name = Run.LC_Column
GROUP BY LC_Col.Column_Name, LC_Col.Mfg_Name, LC_Col.Mfg_Model,
         LC_Col.Mfg_Serial_Number, LC_Col.Packing_Mfg, LC_Col.Packing_Type,
         LC_Col.Particle_size, LC_Col.Particle_type, LC_Col.Column_Inner_Dia,
         LC_Col.Column_Outer_Dia, LC_Col.Length, LC_Col.State, LC_Col.Operator_PRN,
         LC_Col.Comment, LC_Col.Created

GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Column_List_Report] TO [DDL_Viewer] AS [dbo]
GO
