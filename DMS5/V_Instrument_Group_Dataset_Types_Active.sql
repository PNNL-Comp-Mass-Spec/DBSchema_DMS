/****** Object:  View [dbo].[V_Instrument_Group_Dataset_Types_Active] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Group_Dataset_Types_Active]
AS
SELECT InstGroup.IN_Group AS InstrumentGroup,
       TypeName.DST_name AS DefaultDatasetType,
       dbo.GetInstrumentGroupDatasetTypeList(InstGroup.IN_Group, ',') AS AllowedDatasetTypes
FROM T_Instrument_Group InstGroup
     INNER JOIN T_DatasetTypeName TypeName
       ON InstGroup.Default_Dataset_Type = TypeName.DST_Type_ID
WHERE InstGroup.Active = 1 AND
      InstGroup.Requested_Run_Visible = 1

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_Dataset_Types_Active] TO [DDL_Viewer] AS [dbo]
GO
