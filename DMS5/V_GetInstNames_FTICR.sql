/****** Object:  View [dbo].[V_GetInstNames_FTICR] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE VIEW dbo.V_GetInstNames_FTICR
AS
SELECT *
FROM T_Instrument_Name
WHERE (IN_class = 'FTICR')
GO
