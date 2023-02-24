/****** Object:  UserDefinedFunction [dbo].[get_dms_file_storage_path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dms_file_storage_path]
/****************************************************
**
**  Desc:
**  Returns internal path
**
**  Return values:
**
**  Auth:   grk
**  Date:   05/12/2010
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @campaign varchar(64),
    @id varchar(12),
    @type varchar(32)
)
RETURNS varchar(512)
AS
Begin
    declare @filePath varchar(512)

    SELECT @filePath =
        CASE
            WHEN @ID IS NULL THEN ''
            WHEN @type = 'sample_submission' THEN 'Campaigns\Campaign_' + REPLACE(@campaign, ' ', '_') + '\Shipment_Receiving\Sample_Sub_' + @ID
            WHEN @type = 'prep_lc' THEN 'Prep_LC_Run_' + @ID
            ELSE '' END

    RETURN @filePath
End

GO
GRANT VIEW DEFINITION ON [dbo].[get_dms_file_storage_path] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_dms_file_storage_path] TO [DMS2_SP_User] AS [dbo]
GO
