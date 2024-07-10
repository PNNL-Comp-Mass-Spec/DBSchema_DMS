/****** Object:  View [dbo].[V_Capture_Scripts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Capture_Scripts]
AS
SELECT id,
       script,
       description,
       enabled,
       results_tag,
       Cast(Contents AS varchar(MAX)) AS contents
FROM dbo.T_Scripts

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Scripts] TO [DDL_Viewer] AS [dbo]
GO
