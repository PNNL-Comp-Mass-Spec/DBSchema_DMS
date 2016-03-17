/****** Object:  StoredProcedure [dbo].[EditEMSLInstrumentUsageReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[EditEMSLInstrumentUsageReport]
/****************************************************
**
**  Desc: 
**    Updates selected EMSL instrument
**    usage report items
**
**  Parameters:
**
**  Auth:	grk
**  Date:	08/31/2012 grk - Initial release
**          09/11/2012 grk - fixed update SQL
**  
*****************************************************/
(
	@Year INT = 2012 ,
    @Month INT = 8 ,
    @Instrument VARCHAR(64) = '',
    @Type VARCHAR(32) = '',
    @Usage Varchar(32) = '',
    @Proposal VARCHAR(32) = '',
    @Users VARCHAR(512) = '',
    @Operator VARCHAR(32) = '',  
    @Comment VARCHAR(512) = '',
    @FieldName VARCHAR(32) = '' , -- Proposal, Usage,  Users,  Operator,  Comment, 
    @NewValue VARCHAR(512) = '',
    @DoUpdate TINYINT = 0
)	
AS
	SET NOCOUNT ON

	DECLARE @Message VARCHAR(4096) = ''

	---------------------------------------------------
	-- Temp table to hold keys to affected items
	---------------------------------------------------

	CREATE TABLE #TX (
		Seq int
	)

	---------------------------------------------------
	-- Get keys to affected items
	---------------------------------------------------

	INSERT INTO #TX ( Seq )
	SELECT  Seq
	FROM    T_EMSL_Instrument_Usage_Report
	WHERE   ( Month = @Month )
			AND ( Year = @Year )
			AND (( @Instrument = '' ) OR ( Instrument = @instrument ))
			AND (( @Type = '' ) OR ( Type = @Type ))
			AND (( @Usage = '' ) OR ( Usage = @Usage ))
			AND (( @Proposal = '' ) OR ( Proposal = @Proposal ))
			AND (( @Users = '' ) OR ( Users = @Users ))
			AND (( @Operator = '' ) OR ( Operator = @Operator ))

	---------------------------------------------------
	-- display affected items or make change
	---------------------------------------------------

	IF @DoUpdate = 0 
	BEGIN 
		SELECT * 
		FROM #TX INNER JOIN dbo.T_EMSL_Instrument_Usage_Report TD ON #TX.Seq = TD.Seq
	END 
	ELSE
		BEGIN
	 
		IF @FieldName = 'Proposal'
		BEGIN
			UPDATE TD
			SET Proposal = @NewValue
			FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
		END

		IF @FieldName = 'Usage'
		BEGIN
			UPDATE TD
			SET Usage = @NewValue
			FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
		END

		IF @FieldName = 'Users'
		BEGIN
			UPDATE TD
			SET Users = @NewValue
			FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
		END

		IF @FieldName = 'Operator'
		BEGIN
			UPDATE TD
			SET Operator = @NewValue
			FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
		END

		IF @FieldName = 'Comment'
		BEGIN
			UPDATE TD
			SET Comment = @NewValue
			FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
		END
	END


	---------------------------------------------------
	-- 
	---------------------------------------------------

	DROP TABLE #TX
	RETURN

GO
GRANT VIEW DEFINITION ON [dbo].[EditEMSLInstrumentUsageReport] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[EditEMSLInstrumentUsageReport] TO [PNL\D3M580] AS [dbo]
GO
