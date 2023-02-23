/****** Object:  View [dbo].[V_Pipeline_Script_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Script_Entry]
AS
-- When the length of data in an XML column for a given row surpasses a threshold, 
-- the SQLSRV driver used by CodeIgniter on the the DMS website will try to allocate 
-- a huge amount of memory, leading to an exception, for example:
--   Allowed memory size of 4294967296 bytes exhausted (tried to allocate 11014923786071231195 bytes) 
--   in /vendor/codeigniter4/framework/system/Database/SQLSRV/Result.php on line 142
--
-- Casting to varchar(max) prevents the error
SELECT id,
       script,
       description,
       enabled,
       results_tag,
       Case When Backfill_to_DMS = 0 Then 'N' Else 'Y' End AS backfill_to_dms,
       Cast(contents As Varchar(Max)) As contents,      -- Cast the XML to varchar(max)
       Cast(parameters As Varchar(Max)) As parameters,  -- Cast the XML to varchar(max)
       Cast(fields As Varchar(Max)) As Fields           -- Cast the XML to varchar(max)
FROM dbo.T_Scripts


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Script_Entry] TO [DDL_Viewer] AS [dbo]
GO
