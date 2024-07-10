/****** Object:  View [dbo].[V_Pipeline_Script_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Pipeline_Script_Parameters
As
-- This view is used by https://dms2.pnl.gov/pipeline_jobs/create
-- When the user clicks a script name, the code references this view using a URL similar to these
--   https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/PRIDE_Converter
--   https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/MAC_iTRAQ
--   https://dms2.pnl.gov/pipeline_jobs/parameter_form/0/MSFragger_DataPkg
--
-- This view casts the XML to varchar(max) to workaround a bug in the SQLSRV driver used by CodeIgniter on the the DMS website
SELECT ID,
       Script,
       Cast(Parameters AS varchar(MAX)) AS Parameters,
       Cast(Fields AS varchar(MAX)) As Fields
FROM T_Scripts


GO
