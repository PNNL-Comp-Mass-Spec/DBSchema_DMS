/****** Object:  View [dbo].[V_Instrument_Class_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Class_Export]
AS
SELECT IN_class AS instrument_class,
       is_purgable AS is_purgeable,
       raw_data_type AS raw_data_type,
       comment
FROM dbo.T_Instrument_Class


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Class_Export] TO [DDL_Viewer] AS [dbo]
GO
