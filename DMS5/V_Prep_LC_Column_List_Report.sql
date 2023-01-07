/****** Object:  View [dbo].[V_Prep_LC_Column_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Prep_LC_Column_List_Report]
AS
SELECT dbo.T_Prep_LC_Column.Column_Name AS column_name, dbo.T_Prep_LC_Column.Mfg_Name AS mfg_name,
       dbo.T_Prep_LC_Column.Mfg_Model AS mfg_model, dbo.T_Prep_LC_Column.Mfg_Serial_Number AS mfg_serial_number,
       dbo.T_Prep_LC_Column.Packing_Mfg AS packing_mfg, dbo.T_Prep_LC_Column.Packing_Type AS packing_type,
       dbo.T_Prep_LC_Column.Particle_size AS particle_size, dbo.T_Prep_LC_Column.Particle_type AS particle_type,
       dbo.T_Prep_LC_Column.Column_Inner_Dia AS column_inner_dia, dbo.T_Prep_LC_Column.Column_Outer_Dia AS column_outer_dia,
       dbo.T_Prep_LC_Column.length, SUM(dbo.T_Prep_LC_Run.Number_Of_Runs) AS runs, dbo.T_Prep_LC_Column.state,
       dbo.T_Prep_LC_Column.Operator_PRN AS operator_prn, dbo.T_Prep_LC_Column.comment, dbo.T_Prep_LC_Column.created
FROM dbo.T_Prep_LC_Column LEFT OUTER JOIN
                      dbo.T_Prep_LC_Run ON dbo.T_Prep_LC_Column.Column_Name = dbo.T_Prep_LC_Run.LC_Column
GROUP BY dbo.T_Prep_LC_Column.Column_Name, dbo.T_Prep_LC_Column.Mfg_Name, dbo.T_Prep_LC_Column.Mfg_Model,
         dbo.T_Prep_LC_Column.Mfg_Serial_Number, dbo.T_Prep_LC_Column.Packing_Mfg, dbo.T_Prep_LC_Column.Packing_Type,
         dbo.T_Prep_LC_Column.Particle_size, dbo.T_Prep_LC_Column.Particle_type, dbo.T_Prep_LC_Column.Column_Inner_Dia,
         dbo.T_Prep_LC_Column.Column_Outer_Dia, dbo.T_Prep_LC_Column.Length, dbo.T_Prep_LC_Column.State, dbo.T_Prep_LC_Column.Operator_PRN,
         dbo.T_Prep_LC_Column.Comment, dbo.T_Prep_LC_Column.Created


GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Column_List_Report] TO [DDL_Viewer] AS [dbo]
GO
