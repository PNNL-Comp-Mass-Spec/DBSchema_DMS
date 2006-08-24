/****** Object:  View [dbo].[V_GetInstNames_LCQ] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE VIEW dbo.V_GetInstNames_LCQ
AS
SELECT *
FROM T_Instrument_Name
WHERE (IN_class = 'LCQ')
GO
