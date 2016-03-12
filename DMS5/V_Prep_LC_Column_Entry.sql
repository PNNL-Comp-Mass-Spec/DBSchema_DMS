/****** Object:  View [dbo].[V_Prep_LC_Column_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Prep_LC_Column_Entry AS 
 SELECT 
	Column_Name AS ColumnName,
	Mfg_Name AS MfgName,
	Mfg_Model AS MfgModel,
	Mfg_Serial_Number AS MfgSerialNumber,
	Packing_Mfg AS PackingMfg,
	Packing_Type AS PackingType,
	Particle_size AS Particlesize,
	Particle_type AS Particletype,
	Column_Inner_Dia AS ColumnInnerDia,
	Column_Outer_Dia AS ColumnOuterDia,
	Length AS Length,
	State AS State,
	Operator_PRN AS OperatorPRN,
	Comment AS Comment,
	Created AS Created,
	ID AS ID
FROM T_Prep_LC_Column

GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Column_Entry] TO [PNL\D3M578] AS [dbo]
GO
