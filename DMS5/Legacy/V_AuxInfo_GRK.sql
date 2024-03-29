/****** Object:  View [dbo].[V_AuxInfo_GRK] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_AuxInfo_GRK
AS
SELECT T_AuxInfo_Description.Name AS Name,
       T_AuxInfo_Value.Value,
       T_AuxInfo_Description.Aux_Subcategory_ID,
       T_AuxInfo_Value.Target_ID,
       T_AuxInfo_Description.Sequence
FROM T_AuxInfo_Description
     INNER JOIN T_AuxInfo_Value
       ON T_AuxInfo_Description.ID = T_AuxInfo_Value.Aux_Description_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_AuxInfo_GRK] TO [DDL_Viewer] AS [dbo]
GO
