/****** Object:  UserDefinedFunction [dbo].[GetNearestPrecedingLogEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetNearestPrecedingLogEntry
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
**			04/11/2017 mem - Update for new fields DMS_Inst_ID and Usage_Type
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
		FROM    T_EMSL_Instrument_Usage_Report InstUsage
		     INNER JOIN T_Instrument_Name InstName
		       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
		     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
		       ON InstUsage.Usage_Type = InstUsageType.ID
		WHERE   ( Seq = @Seq )


		IF @Usage <> 'ONSITE' AND ISNULL(@Comment, '') = ''
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
