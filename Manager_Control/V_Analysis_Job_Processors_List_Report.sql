/****** Object:  View [dbo].[V_Analysis_Job_Processors_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Analysis_Job_Processors_List_Report]
AS
SELECT M.M_ID AS ID,
       M.M_Name AS Name,
       MT.MT_TypeName AS Type
FROM T_Mgrs M
     INNER JOIN T_MgrTypes MT
       ON M.M_TypeID = MT.MT_TypeID

GO
