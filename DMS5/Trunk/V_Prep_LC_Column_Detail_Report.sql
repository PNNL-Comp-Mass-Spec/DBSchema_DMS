/****** Object:  View [dbo].[V_Prep_LC_Column_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Prep_LC_Column_Detail_Report AS 
 SELECT 
	Column_Name AS [Column Name],
	Mfg_Name AS [Mfg Name],
	Mfg_Model AS [Mfg Model],
	Mfg_Serial_Number AS [Mfg Serial Number],
	Packing_Mfg AS [Packing Mfg],
	Packing_Type AS [Packing Type],
	Particle_size AS [Particle size],
	Particle_type AS [Particle type],
	Column_Inner_Dia AS [Column Inner Dia],
	Column_Outer_Dia AS [Column Outer Dia],
	Length AS [Length],
	State AS [State],
	Operator_PRN AS [Operator PRN],
	Comment AS [Comment],
	Created AS [Created],
	ID AS [ID]
FROM T_Prep_LC_Column

GO
