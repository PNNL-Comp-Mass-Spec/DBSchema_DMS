/****** Object:  UserDefinedFunction [dbo].[CheckEMSLUsageItemValidity] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[CheckEMSLUsageItemValidity]
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
			@CallType VARCHAR(100) ,
			@ProposalStartDate DATETIME ,
			@ProposalEndDate DATETIME ,
			@LastAffected DATETIME 


		SELECT  @EMSLInstID = EMSL_Inst_ID ,
				@Instrument = Instrument ,
				@Type = Type ,
				@Start = Start ,
				@Minutes = Minutes ,
				@Proposal = Proposal ,
				@Usage = Usage ,
				@Users = Users ,
				@Operator = Operator ,
				@Comment = Comment ,
				@Year = Year ,
				@Month = Month ,
				@ID = ID
		FROM    T_EMSL_Instrument_Usage_Report
		WHERE   ( Seq = @Seq )

		IF @Usage = 'CAP_DEV' AND ISNULL(@Operator, '') = ''
			SET @Message = @Message + 'Capability Development requires an operator' + ', ' 

		IF NOT @Usage IN ('ONSITE', 'MAINTENANCE') AND ISNULL(@Comment, '') = ''
			SET @Message = @Message + 'Missing Comment' + ', ' 

		IF @Usage = 'OFFSITE' AND @Proposal = '' 
			SET @Message = @Message + 'Missing Proposal' + ', ' 

		/**/
		IF @Usage = 'ONSITE' AND ISNUMERIC(SUBSTRING(@Proposal, 1, 1)) = 0 
			SET @Message = @Message + 'Preliminary Proposal number' + ', '

		SELECT  @ProposalId = [PROPOSAL_ID] ,
				@Title = [TITLE] ,
				@StateID = [State_ID] ,
				@ImportDate = [Import_Date] ,
				@CallType = [Call_Type] ,
				@ProposalStartDate = [Proposal_Start_Date] ,
				@ProposalEndDate = [Proposal_End_Date] ,
				@LastAffected = [Last_Affected]
		FROM    T_EUS_Proposals
		WHERE   PROPOSAL_ID = @Proposal 

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
		   SELECT @hits = COUNT(*)
		   FROM dbo.MakeTableFromList(@Users)
					INNER JOIN ( SELECT Proposal_ID , Person_ID
								 FROM   T_EUS_Proposal_Users
								 WHERE  Proposal_ID = @Proposal
							   ) TZ ON Person_ID = CONVERT(INT, Item) 
			IF @hits = 0
				SET @Message = @Message + 'No users were listed for proposal' + ', '
		END
				
		RETURN @Message
	END

GO
