/****** Object:  View [dbo].[V_Manager_Type_Report_All] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Manager_Type_Report_All]
AS
SELECT DISTINCT MT.MT_TypeName AS Manager_Type,
                MT.MT_TypeID AS ID
FROM T_MgrTypes MT
     JOIN T_Mgrs M
       ON M.M_TypeID = MT.MT_TypeID
     JOIN T_ParamValue PV
       ON PV.MgrID = M.M_ID AND
          M.M_TypeID = MT.MT_TypeID

GO
