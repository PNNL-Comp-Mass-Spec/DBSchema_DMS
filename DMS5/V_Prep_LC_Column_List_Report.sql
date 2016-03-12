/****** Object:  View [dbo].[V_Prep_LC_Column_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Prep_LC_Column_List_Report
AS
SELECT     dbo.T_Prep_LC_Column.Column_Name AS [Column Name], dbo.T_Prep_LC_Column.Mfg_Name AS [Mfg Name], 
                      dbo.T_Prep_LC_Column.Mfg_Model AS [Mfg Model], dbo.T_Prep_LC_Column.Mfg_Serial_Number AS [Mfg Serial Number], 
                      dbo.T_Prep_LC_Column.Packing_Mfg AS [Packing Mfg], dbo.T_Prep_LC_Column.Packing_Type AS [Packing Type], 
                      dbo.T_Prep_LC_Column.Particle_size AS [Particle size], dbo.T_Prep_LC_Column.Particle_type AS [Particle type], 
                      dbo.T_Prep_LC_Column.Column_Inner_Dia AS [Column Inner Dia], dbo.T_Prep_LC_Column.Column_Outer_Dia AS [Column Outer Dia], 
                      dbo.T_Prep_LC_Column.Length, SUM(dbo.T_Prep_LC_Run.Number_Of_Runs) AS Runs, dbo.T_Prep_LC_Column.State, 
                      dbo.T_Prep_LC_Column.Operator_PRN AS [Operator PRN], dbo.T_Prep_LC_Column.Comment, dbo.T_Prep_LC_Column.Created
FROM         dbo.T_Prep_LC_Column LEFT OUTER JOIN
                      dbo.T_Prep_LC_Run ON dbo.T_Prep_LC_Column.Column_Name = dbo.T_Prep_LC_Run.LC_Column
GROUP BY dbo.T_Prep_LC_Column.Column_Name, dbo.T_Prep_LC_Column.Mfg_Name, dbo.T_Prep_LC_Column.Mfg_Model, 
                      dbo.T_Prep_LC_Column.Mfg_Serial_Number, dbo.T_Prep_LC_Column.Packing_Mfg, dbo.T_Prep_LC_Column.Packing_Type, 
                      dbo.T_Prep_LC_Column.Particle_size, dbo.T_Prep_LC_Column.Particle_type, dbo.T_Prep_LC_Column.Column_Inner_Dia, 
                      dbo.T_Prep_LC_Column.Column_Outer_Dia, dbo.T_Prep_LC_Column.Length, dbo.T_Prep_LC_Column.State, dbo.T_Prep_LC_Column.Operator_PRN, 
                      dbo.T_Prep_LC_Column.Comment, dbo.T_Prep_LC_Column.Created

GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Column_List_Report] TO [PNL\D3M578] AS [dbo]
GO
