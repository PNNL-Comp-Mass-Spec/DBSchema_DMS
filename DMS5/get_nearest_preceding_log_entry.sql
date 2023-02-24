/****** Object:  UserDefinedFunction [dbo].[get_nearest_preceding_log_entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_nearest_preceding_log_entry]
/****************************************************
**
**  Desc:
**
**  Return value: nearest preceeding log message
**
**  Parameters:
**
**  Auth:   grk
**  Date:   08/28/2012
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/17/2020 mem - Updated field name in T_EMSL_Instrument_Usage_Report
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @seq int,
    @omitText SMALLINT = 0
)
RETURNS varchar(4096)
AS
    BEGIN
        Declare @Message varchar(4096) = ''

        Declare @EMSLInstID int ,
            @Instrument varchar(64) ,
            @Type varchar(128) ,
            @Start datetime ,
            @Minutes int ,
            @Proposal varchar(32) ,
            @Usage varchar(32) ,
            @Users varchar(1024) ,
            @Operator int ,
            @Comment varchar(4096) ,
            @Year int ,
            @Month int ,
            @DatasetID int

        SELECT @EMSLInstID = InstUsage.EMSL_Inst_ID,
               @Instrument = InstName.IN_Name,
               @Type = InstUsage.TYPE,
               @Start = InstUsage.Start,
               @Minutes = InstUsage.Minutes,
               @Proposal = InstUsage.Proposal,
               @Usage = IsNull(InstUsageType.Name, ''),
               @Users = InstUsage.Users,
               @Operator = InstUsage.Operator,
               @Comment = InstUsage.[Comment],
               @Year = InstUsage.[Year],
               @Month = InstUsage.[Month],
               @DatasetID = InstUsage.Dataset_ID
        FROM    T_EMSL_Instrument_Usage_Report InstUsage
             INNER JOIN T_Instrument_Name InstName
               ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
             LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
               ON InstUsage.Usage_Type = InstUsageType.ID
        WHERE   ( Seq = @Seq )

        IF @Usage <> 'ONSITE' AND ISNULL(@Comment, '') = ''
        BEGIN
            Declare @opNote varchar(4096) = '', @opNoteTime datetime , @opNoteID int = 0
            Declare @confNote varchar(4096) = '', @confNoteTime datetime , @confNoteID int = 0

            SELECT TOP(1)
                @opNoteID = ID,
                @opNoteTime = Entered,
                @opNote = CASE WHEN @OmitText > 0 THEN ISNULL(Note, '') ELSE '' END
            FROM T_Instrument_Operation_History
            WHERE Instrument = @Instrument AND Entered < @Start
            ORDER BY Entered DESC

            SELECT TOP ( 1 )
                @confNoteID = ID,
                @confNoteTime = Date_Of_Change ,
                @confNote = CASE WHEN @OmitText > 0 THEN ISNULL(DESCRIPTION, '') ELSE '' END
            FROM    T_Instrument_Config_History
            WHERE Instrument = @Instrument AND Date_Of_Change < @Start
            ORDER BY Date_Of_Change DESC

           Set @message = CASE WHEN @opNoteTime > @confNoteTime
                               THEN '[Op Log:' + CONVERT(varchar(128), @opNoteID)
                                    + '] ' + @opNote
                               ELSE '[Config Log:' + CONVERT(varchar(128), @confNoteID)
                                    + '] ' + @confNote
                          END
        END
        RETURN @Message
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_nearest_preceding_log_entry] TO [DDL_Viewer] AS [dbo]
GO
