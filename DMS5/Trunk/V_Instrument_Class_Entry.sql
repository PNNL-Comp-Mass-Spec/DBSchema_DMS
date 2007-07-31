/****** Object:  View [dbo].[V_Instrument_Class_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Instrument_Class_Entry
AS
SELECT IN_class AS InstrumentClass, 
    is_purgable AS IsPurgable, 
    raw_data_type AS RawDataType, 
    requires_preparation AS RequiresPreparation, 
    Allowed_Dataset_Types AS AllowedDatasetTypes
FROM dbo.T_Instrument_Class

GO
