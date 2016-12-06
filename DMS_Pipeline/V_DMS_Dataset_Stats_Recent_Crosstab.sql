/****** Object:  View [dbo].[V_DMS_Dataset_Stats_Recent_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_Dataset_Stats_Recent_Crosstab
AS
SELECT State,
       Dataset_State,
       Finnigan_Ion_Trap,
       LTQ_FT,
       Thermo_Exactive,
       BRUKERFTMS,
       Triple_Quad,
       Finnigan_FTICR,
       IMS_Agilent_TOF
FROM S_DMS_V_Dataset_Stats_Recent_Crosstab

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Dataset_Stats_Recent_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
