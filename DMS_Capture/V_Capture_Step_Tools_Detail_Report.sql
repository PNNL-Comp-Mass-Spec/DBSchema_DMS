/****** Object:  View [dbo].[V_Capture_Step_Tools_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Capture_Step_Tools_Detail_Report
AS
SELECT     ID, Name, Description, Bionet_Required, Only_On_Storage_Server, Instrument_Capacity_Limited, Holdoff_Interval_Minutes, Number_Of_Retries
FROM         dbo.T_Step_Tools

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Step_Tools_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
