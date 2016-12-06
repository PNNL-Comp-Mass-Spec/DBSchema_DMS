/****** Object:  View [dbo].[V_Capture_Method_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Capture_Method_Picklist
AS
SELECT DISTINCT IN_capture_method AS val
FROM         dbo.T_Instrument_Name
WHERE     (IN_status = 'active')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Method_Picklist] TO [DDL_Viewer] AS [dbo]
GO
