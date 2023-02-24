/****** Object:  UserDefinedFunction [dbo].[get_requested_run_eus_users_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_requested_run_eus_users_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of EUS users for
**  given requested run
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   02/15/2006
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @requestID int,
    @mode char(1) = 'I' -- 'N', 'V'
)
RETURNS varchar(1024)
AS
    BEGIN
        declare @list varchar(1024)
        set @list = ''

        IF @mode = 'I'
        BEGIN
            SELECT
                @list = @list + CASE
                                    WHEN @list = '' THEN CAST(EUS_Person_ID AS varchar(12))
                                    ELSE ', ' + CAST(EUS_Person_ID AS varchar(12))
                                END
            FROM
            T_Requested_Run_EUS_Users INNER JOIN
            T_EUS_Users ON T_Requested_Run_EUS_Users.EUS_Person_ID = T_EUS_Users.PERSON_ID
            WHERE     (T_Requested_Run_EUS_Users.Request_ID = @requestID)
        END

        IF @mode = 'N'
        BEGIN
            SELECT
                @list = @list + CASE
                                    WHEN @list = '' THEN NAME_FM
                                    ELSE '; ' + NAME_FM
                                END
            FROM
            T_Requested_Run_EUS_Users INNER JOIN
            T_EUS_Users ON T_Requested_Run_EUS_Users.EUS_Person_ID = T_EUS_Users.PERSON_ID
            WHERE     (T_Requested_Run_EUS_Users.Request_ID = @requestID)
        END

        IF @mode = 'V'
        BEGIN
            SELECT
                @list = @list + CASE
                                    WHEN @list = '' THEN NAME_FM + ' (' + CAST(EUS_Person_ID AS varchar(12)) + ')'
                                    ELSE '; ' + NAME_FM + ' (' + CAST(EUS_Person_ID AS varchar(12)) + ')'
                                END
            FROM
            T_Requested_Run_EUS_Users INNER JOIN
            T_EUS_Users ON T_Requested_Run_EUS_Users.EUS_Person_ID = T_EUS_Users.PERSON_ID
            WHERE     (T_Requested_Run_EUS_Users.Request_ID = @requestID)
            if @list = '' set @list = '(none)'
        END
/**/
        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_requested_run_eus_users_list] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_requested_run_eus_users_list] TO [public] AS [dbo]
GO
