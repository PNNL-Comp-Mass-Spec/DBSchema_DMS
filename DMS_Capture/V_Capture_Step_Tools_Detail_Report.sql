/****** Object:  View [dbo].[V_Capture_Step_Tools_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Capture_Step_Tools_Detail_Report
AS
SELECT id, name, description, bionet_required, only_on_storage_server, instrument_capacity_limited, holdoff_interval_minutes, number_of_retries
FROM dbo.T_Step_Tools


GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Step_Tools_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
