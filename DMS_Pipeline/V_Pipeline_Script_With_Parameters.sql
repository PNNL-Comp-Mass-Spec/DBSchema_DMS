/****** Object:  View [dbo].[V_Pipeline_Script_With_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view V_Pipeline_Script_With_Parameters as 
SELECT        Script
FROM            T_Scripts
WHERE        (Enabled = 'Y') AND (NOT (Parameters IS NULL))
GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Script_With_Parameters] TO [DDL_Viewer] AS [dbo]
GO
