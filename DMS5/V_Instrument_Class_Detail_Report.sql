/****** Object:  View [dbo].[V_Instrument_Class_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Instrument_Class_Detail_Report]
AS
SELECT IN_class AS instrument_class,
       is_purgable AS is_purgeable,
       raw_data_type,
       -- Obsolete: requires_preparation,
       comment,
       dbo.xml_to_html(Params) AS params
FROM dbo.T_Instrument_Class

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Class_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
