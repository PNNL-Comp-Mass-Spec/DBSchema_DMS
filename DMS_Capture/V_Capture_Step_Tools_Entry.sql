/****** Object:  View [dbo].[V_Capture_Step_Tools_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Capture_Step_Tools_Entry
AS
SELECT id,
       name,
       description,
       bionet_required,
       only_on_storage_server,
       instrument_capacity_limited
FROM dbo.T_Step_Tools

GO
GRANT VIEW DEFINITION ON [dbo].[V_Capture_Step_Tools_Entry] TO [DDL_Viewer] AS [dbo]
GO
