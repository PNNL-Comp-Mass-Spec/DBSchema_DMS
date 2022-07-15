/****** Object:  UserDefinedFunction [dbo].[CheckEMSLUsageItemValidity] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[CheckEMSLUsageItemValidity]
/****************************************************
**
**  Desc:
**      Check EMSL usage item validity
**
**  Return value: error message
**
**  Auth:   grk
**  Date:   08/28/2012
**          08/31/2012 grk - fixed spelling error in message
**          10/03/2012 grk - Maintenance usage no longer requires comment
**          03/20/2013 mem - Changed from Call_Type to Proposal_Type
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          10/05/2016 mem - Add one day to the proposal end date
**          03/17/2017 mem - Only call MakeTableFromList if @Users is a comma separated list
**          04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**          04/17/2020 mem - Updated field name in T_EMSL_Instrument_Usage_Report
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**
*****************************************************/
(
    @Seq int
)
RETURNS varchar(4096)
As
Begin
    Declare @Message varchar(4096) = ''

    Declare @EMSLInstID int ,
        @Instrument varchar(64) ,
        @Type varchar(128) ,
        @Start datetime ,
        @Minutes int ,
        @Proposal varchar(32) ,
        @Usage varchar(32) ,
        @Users varchar(1024) ,
        @Operator int,
        @Comment varchar(4096) ,
        @Year int ,
        @Month int ,
        @DatasetID int

    Declare @ProposalId varchar(10) ,
        @Title varchar(2048) ,
        @StateID int ,
        @ImportDate datetime ,
        @ProposalType varchar(100) ,
        @ProposalStartDate datetime ,
        @ProposalEndDate datetime ,
        @LastAffected datetime

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
    FROM T_EMSL_Instrument_Usage_Report InstUsage
         INNER JOIN T_Instrument_Name InstName
           ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
         LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
           ON InstUsage.Usage_Type = InstUsageType.ID
    WHERE (InstUsage.Seq = @Seq)

    IF @Usage = 'CAP_DEV' AND @Operator Is Null
        Set @Message = @Message + 'Capability Development requires an instrument operator ID' + ', '

    IF NOT @Usage IN ('ONSITE', 'MAINTENANCE') AND ISNULL(@Comment, '') = ''
        Set @Message = @Message + 'Missing Comment' + ', '

    IF @Usage = 'OFFSITE' AND @Proposal = ''
        Set @Message = @Message + 'Missing Proposal' + ', '

    IF @Usage = 'ONSITE' AND Try_Parse(SUBSTRING(@Proposal, 1, 1) as int) Is Null
        Set @Message = @Message + 'Preliminary Proposal number' + ', '

    SELECT  @ProposalId = Proposal_ID ,
            @Title = Title ,
            @StateID = State_ID ,
            @ImportDate = Import_Date ,
            @ProposalType = Proposal_Type ,
            @ProposalStartDate = Proposal_Start_Date ,
            @ProposalEndDate = DateAdd(day, 1, Proposal_End_Date) ,
            @LastAffected = Last_Affected
    FROM    T_EUS_Proposals
    WHERE   Proposal_ID = @Proposal

    IF @Usage = 'ONSITE' AND @ProposalId IS null
        Set @Message = @Message + 'Proposal number is not in ERS' + ', '

    IF NOT @ProposalId IS NULL
    BEGIN
    IF @Usage = 'ONSITE' AND  NOT ( @Start BETWEEN @ProposalStartDate AND @ProposalEndDate )
        Set @Message = @Message + 'Run start not between proposal start/end dates' + ', '
    END

    IF NOT @ProposalId IS NULL
    BEGIN
        Declare @hits int = 0
        If @Users Like '%,%'
        Begin
            SELECT @hits = COUNT(*)
            FROM dbo.MakeTableFromList ( @Users )
                 INNER JOIN ( SELECT Proposal_ID,
                                     Person_ID
                              FROM T_EUS_Proposal_Users
                              WHERE Proposal_ID = @Proposal ) TZ
                   ON Person_ID = Try_Parse(Item as int)
        End
        Else
        Begin
            SELECT @hits = COUNT(*)
            FROM T_EUS_Proposal_Users
            WHERE Proposal_ID = @Proposal And Person_ID = Try_Parse(@Users as int)
        End

        IF @hits = 0
            Set @Message = @Message + 'No users were listed for proposal' + ', '
    END

    RETURN @Message
End

GO
GRANT VIEW DEFINITION ON [dbo].[CheckEMSLUsageItemValidity] TO [DDL_Viewer] AS [dbo]
GO
