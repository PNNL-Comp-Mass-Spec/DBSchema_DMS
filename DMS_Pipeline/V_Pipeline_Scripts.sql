/****** Object:  View [dbo].[V_Pipeline_Scripts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Pipeline_Scripts]
AS
-- This view is used by https://dms2.pnl.gov/pipeline_jobs/create
-- When the user clicks a script name, the code references this view using a URL similar to these
--   https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/PRIDE_Converter
--   https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/MAC_iTRAQ
--   https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/MSFragger_DataPkg
--   https://dms2.pnl.gov/pipeline_script/dot/MSGFPlus (linked to from https://dms2.pnl.gov/pipeline_script/show/MSGFPlus using "Script")
--
-- This view casts the XML to varchar(max) to workaround a bug in the SQLSRV driver used by CodeIgniter on the the DMS website
SELECT id,
       script,
       description,
       enabled,
       results_tag,
       backfill_to_dms,
       Cast(Contents AS varchar(MAX)) AS contents,
       Cast(Parameters AS varchar(MAX)) AS parameters,
       Cast(Fields AS varchar(MAX)) As fields
FROM T_Scripts

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Scripts] TO [DDL_Viewer] AS [dbo]
GO
