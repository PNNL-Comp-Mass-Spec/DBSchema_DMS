/****** Object:  UserDefinedFunction [dbo].[get_dms_file_storage_paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dms_file_storage_paths]
/****************************************************
**
**  Desc:
**  Returns internal path
**
**  Return values: Path to the folder for given entity and type
**
**  Auth:   grk
**  Date:   04/28/2010
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @id INT,
    @type varchar(32)
)
RETURNS @table_variable TABLE (package VARCHAR(128), path_local_root VARCHAR(128), path_shared_root VARCHAR(128), path_folder VARCHAR(256))
AS
    BEGIN
      IF @type = 'sample_submission'
        BEGIN
            INSERT INTO @table_variable (package, path_local_root, path_shared_root, path_folder)
            SELECT
                'Sample_Submission_' + CONVERT(VARCHAR(12), @ID),
                Path_Local_Root,
                Path_Shared_Root,
                dbo.get_dms_file_storage_path(Campaign_Num, @ID, @type) AS path_folder
            FROM
                T_Sample_Submission
                INNER JOIN T_Campaign ON T_Sample_Submission.Campaign_ID = T_Campaign.Campaign_ID
                INNER JOIN dbo.T_Prep_File_Storage ON dbo.T_Sample_Submission.Storage_Path = dbo.T_Prep_File_Storage.ID
            WHERE T_Sample_Submission.ID = @ID
        END

    RETURN
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_dms_file_storage_paths] TO [DDL_Viewer] AS [dbo]
GO
