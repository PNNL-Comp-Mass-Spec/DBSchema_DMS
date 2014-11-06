/****** Object:  UserDefinedFunction [dbo].[GetEMSLInstrumentUsageRollup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetEMSLInstrumentUsageRollup]
/****************************************************
**	Desc: 
**  Outputs contents of EMSL instrument usage report table as rollup
**
**	Return values: 
**
**	Parameters:
**	
**	Auth:	grk   
**	Date:	09/11/2012 grk - initial release
**    
*****************************************************/ 
( 
	@Year INT, 
	@Month INT 
)
RETURNS @TX TABLE
	(
		[Month] INT,
		[Day] INT,
		[EMSL_Inst_ID] [int] ,
		[DMS_Instrument] [varchar](64) ,
		[Proposal] [varchar](32) ,
		[Usage] [varchar](32) ,
		[Minutes] [int] 
	)
AS 
	BEGIN
		INSERT  INTO @TX ( 
				EMSL_Inst_ID ,
				DMS_Instrument,
				Proposal ,
				Usage ,
				Minutes,
				[Month],
				[Day]	 
			)
			SELECT  EMSL_Inst_ID ,
					DMS_Instrument ,
					Proposal ,
					Usage ,
					SUM(Minutes) AS [Minutes],
					[Month],
					[Day]
			FROM    ( SELECT    TEIUR.EMSL_Inst_ID ,
								TEIUR.Instrument AS DMS_Instrument,
								TEIUR.Proposal ,
								TEIUR.Usage ,
								TEIUR.Minutes,
								@Month AS [Month],
								DATEPART(DAY, TEIUR.Start) AS [Day]
						FROM      T_EMSL_Instrument_Usage_Report AS TEIUR
						WHERE     ( TEIUR.Year = @Year )
								AND ( TEIUR.Month = @Month )
					) AS TX
			GROUP BY EMSL_Inst_ID ,
					DMS_Instrument ,
					Proposal ,
					Usage ,
					[Month],
					[Day]
			ORDER BY EMSL_Inst_ID, DMS_Instrument, [Month], [Day], [Minutes] DESC
							
		RETURN
	END


GO
