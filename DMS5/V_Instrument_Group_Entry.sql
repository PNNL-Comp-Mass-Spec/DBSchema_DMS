/****** Object:  View [dbo].[V_Instrument_Group_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Instrument_Group_Entry] AS 
SELECT 
	I.IN_Group AS InstrumentGroup,
	I.Usage,
    I.Comment,
	I.Active,
	I.Allocation_Tag,
	ISNULL(DT.DST_name, '') AS DefaultDatasetTypeName
FROM T_Instrument_Group I 
     LEFT OUTER JOIN dbo.T_DatasetTypeName DT
       ON I.Default_Dataset_Type = DT.DST_Type_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_Entry] TO [DDL_Viewer] AS [dbo]
GO
