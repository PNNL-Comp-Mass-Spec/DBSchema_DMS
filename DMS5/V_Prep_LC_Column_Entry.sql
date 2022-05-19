/****** Object:  View [dbo].[V_Prep_LC_Column_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Prep_LC_Column_Entry
AS
SELECT
	column_name,
	mfg_name,
	mfg_model,
	mfg_serial_number,
	packing_mfg,
	packing_type,
	particle_size,
	particle_type,
	column_inner_dia,
	column_outer_dia,
	length,
	state,
	operator_prn,
	comment,
	created,
	id
FROM T_Prep_LC_Column


GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Column_Entry] TO [DDL_Viewer] AS [dbo]
GO
