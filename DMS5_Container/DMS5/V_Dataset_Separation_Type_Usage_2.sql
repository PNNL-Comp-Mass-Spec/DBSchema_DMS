/****** Object:  View [dbo].[V_Dataset_Separation_Type_Usage_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Separation_Type_Usage_2
AS
SELECT        'x' AS Sel, [Usage Last 12 Months], [Separation Type], [Separation Type Comment], [Dataset Usage All Years], [Most Recent Use]
FROM            dbo.V_Dataset_Separation_Type_Usage

GO
