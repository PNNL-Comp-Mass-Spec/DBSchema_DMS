/****** Object:  View [dbo].[V_Instrument_Class_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Class_Export]
AS
SELECT IN_class AS Instrument_Class,
       is_purgable AS Is_Purgable,
       raw_data_type AS Raw_Data_Type,
       Comment
FROM dbo.T_Instrument_Class


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Class_Export] TO [DDL_Viewer] AS [dbo]
GO
