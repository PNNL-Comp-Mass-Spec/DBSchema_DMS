/****** Object:  View [dbo].[V_Ext_PGDump_Instrument_Lookup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Instrument_Lookup
AS
SELECT     dbo.T_Instrument_Name.Instrument_ID AS id, dbo.T_Instrument_Name.IN_name AS instrument_name, 
                      dbo.T_Instrument_Class.IN_class AS instrument_class, '' AS display_name
FROM         dbo.T_Instrument_Class INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Instrument_Class.IN_class = dbo.T_Instrument_Name.IN_class

GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Instrument_Lookup] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Instrument_Lookup] TO [PNL\D3M580] AS [dbo]
GO
