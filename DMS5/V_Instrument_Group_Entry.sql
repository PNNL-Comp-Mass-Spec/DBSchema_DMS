/****** Object:  View [dbo].[V_Instrument_Group_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Group_Entry]
AS
SELECT
	I.IN_Group AS instrument_group,
	I.usage,
    I.comment,
	I.active,
	I.sample_prep_visible,
    I.requested_run_visible,
	I.allocation_tag,
	ISNULL(DT.DST_name, '') AS default_dataset_type_name
FROM T_Instrument_Group I
     LEFT OUTER JOIN dbo.T_Dataset_Type_Name DT
       ON I.Default_Dataset_Type = DT.DST_Type_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_Entry] TO [DDL_Viewer] AS [dbo]
GO
