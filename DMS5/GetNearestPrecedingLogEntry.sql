/****** Object:  UserDefinedFunction [dbo].[GetNearestPrecedingLogEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GetNearestPrecedingLogEntry]
/****************************************************
**
**	Desc: 
**
**	Return value: nearest preceeding log message
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	08/28/2012
**    
*****************************************************/
(
	@Seq INT,
	@OmitText SMALLINT = 0
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


		IF @Usage != 'ONSITE' AND ISNULL(@Comment, '') = ''
		BEGIN 
			DECLARE @opNote VARCHAR(4096) = '', @opNoteTime DATETIME , @opNoteID INT = 0
			DECLARE @confNote VARCHAR(4096) = '', @confNoteTime DATETIME , @confNoteID INT = 0

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
			
		   SET @message = CASE WHEN @opNoteTime > @confNoteTime
							   THEN '[Op Log:' + CONVERT(VARCHAR(128), @opNoteID)
									+ '] ' + @opNote
							   ELSE '[Config Log:' + CONVERT(VARCHAR(128), @confNoteID)
									+ '] ' + @confNote
						  END 
		END 
		RETURN @Message
	END

GO
GRANT VIEW DEFINITION ON [dbo].[GetNearestPrecedingLogEntry] TO [DDL_Viewer] AS [dbo]
GO
