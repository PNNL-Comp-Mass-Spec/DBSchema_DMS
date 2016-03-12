/****** Object:  View [dbo].[V_Pipeline_Script_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Pipeline_Script_Entry] as 
SELECT ID,
       Script,
       Description,
       Enabled,
       Results_Tag AS ResultsTag,
       Case When Backfill_to_DMS = 0 Then 'N' Else 'Y' End AS BackfillToDMS,
       Contents,
       Parameters,
       Fields
FROM dbo.T_Scripts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Script_Entry] TO [PNL\D3M578] AS [dbo]
GO
