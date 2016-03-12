/****** Object:  View [dbo].[V_Pipeline_Script_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Pipeline_Script_List_Report
AS
SELECT Script,
       Description,
       Enabled,
       Results_Tag,
       ID,
       Case When Backfill_to_DMS = 0 Then 'N' Else 'Y' End AS Backfill_to_DMS
FROM dbo.T_Scripts

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Script_List_Report] TO [PNL\D3M578] AS [dbo]
GO
