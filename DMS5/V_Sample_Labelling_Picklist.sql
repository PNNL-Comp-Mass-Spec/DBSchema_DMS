/****** Object:  View [dbo].[V_Sample_Labelling_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Sample_Labelling_Picklist
As
SELECT ID, Label
FROM T_Sample_Labelling


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Labelling_Picklist] TO [DDL_Viewer] AS [dbo]
GO
