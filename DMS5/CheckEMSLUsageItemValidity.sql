/****** Object:  UserDefinedFunction [dbo].[CheckEMSLUsageItemValidity] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.CheckEMSLUsageItemValidity
/****************************************************
**
**	Desc: 
**
**	Return value: error message
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	08/28/2012
**          08/31/2012 grk - fixed spelling error in message
**          10/03/2012 grk - Maintenance usage no longer requires comment
**			03/20/2013 mem - Changed from Call_Type to Proposal_Type
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
**			10/05/2016 mem - Add one day to the proposal end date
**			03/17/2017 mem - Only call MakeTableFromList if @Users is a comma separated list
**			04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
**    
*****************************************************/
(
	@Seq INT
)
RETURNS varchar(4096)
AS
	BEGIN
		DECLARE @Message VARCHAR(4096) = ''

		DECLARE @EMSLInstID INT ,
			@Instrument VARCHAR(64) ,
			@Type VARCHAR(128) ,
			@Start DATETIME ,
			@Minutes INT ,
			@Proposal VARCHAR(32) ,
			@Usage VARCHAR(32) ,
			@Users VARCHAR(1024) ,
			@Operator VARCHAR(64) ,
			@Comment VARCHAR(4096) ,
			@Year INT ,
			@Month INT ,
			@ID INT 

		DECLARE @ProposalId VARCHAR(10) ,
			@Title VARCHAR(2048) ,
			@StateID INT ,
			@ImportDate DATETIME ,
			@ProposalType VARCHAR(100) ,
			@ProposalStartDate DATETIME ,
			@ProposalEndDate DATETIME ,
			@LastAffected DATETIME 


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
		       @ID = InstUsage.ID
		FROM T_EMSL_Instrument_Usage_Report InstUsage
		     INNER JOIN T_Instrument_Name InstName
		       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
		     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
		       ON InstUsage.Usage_Type = InstUsageType.ID
		WHERE (InstUsage.Seq = @Seq)

		IF @Usage = 'CAP_DEV' AND ISNULL(@Operator, '') = ''
			SET @Message = @Message + 'Capability Development requires an operator' + ', ' 

		IF NOT @Usage IN ('ONSITE', 'MAINTENANCE') AND ISNULL(@Comment, '') = ''
			SET @Message = @Message + 'Missing Comment' + ', ' 

		IF @Usage = 'OFFSITE' AND @Proposal = '' 
			SET @Message = @Message + 'Missing Proposal' + ', ' 

		IF @Usage = 'ONSITE' AND Try_Convert(int, SUBSTRING(@Proposal, 1, 1)) Is Null
			SET @Message = @Message + 'Preliminary Proposal number' + ', '

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
			SET @Message = @Message + 'Proposal number is not in ERS' + ', '

		IF NOT @ProposalId IS NULL
		BEGIN 
		IF @Usage = 'ONSITE' AND  NOT ( @Start BETWEEN @ProposalStartDate AND @ProposalEndDate )
			SET @Message = @Message + 'Run start not between proposal start/end dates' + ', '
		END


		IF NOT @ProposalId IS NULL
		BEGIN 
			DECLARE @hits INT = 0
			If @Users Like '%,%'
			Begin
				SELECT @hits = COUNT(*)
				FROM dbo.MakeTableFromList ( @Users )
				     INNER JOIN ( SELECT Proposal_ID,
				                         Person_ID
				                  FROM T_EUS_Proposal_Users
				                  WHERE Proposal_ID = @Proposal ) TZ
				       ON Person_ID = Try_Convert(int, Item)
			End
			Else
			Begin
				SELECT @hits = COUNT(*)
				FROM T_EUS_Proposal_Users
				WHERE Proposal_ID = @Proposal And Person_ID = Try_Convert(int, @Users)
			End
			
			IF @hits = 0
				SET @Message = @Message + 'No users were listed for proposal' + ', '
		END
				
		RETURN @Message
	END

GO
GRANT VIEW DEFINITION ON [dbo].[CheckEMSLUsageItemValidity] TO [DDL_Viewer] AS [dbo]
GO
