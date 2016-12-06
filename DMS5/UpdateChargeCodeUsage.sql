/****** Object:  StoredProcedure [dbo].[UpdateChargeCodeUsage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.UpdateChargeCodeUsage
/****************************************************
** 
**	Desc:	Updates the Usage columns in T_Charge_Code
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**	Auth:	mem
**	Date:	06/04/2013 mem - Initial version
**    
*****************************************************/
(
	@infoOnly tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	-----------------------------------------------------------
	-- Create the table to hold the data
	-----------------------------------------------------------


	If @infoOnly = 0
	Begin
	
		UPDATE T_Charge_Code
		SET Usage_SamplePrep = SPR_Usage
		FROM T_Charge_Code Target
			    INNER JOIN ( SELECT CC.Charge_Code,
			                        COUNT(*) AS SPR_Usage
			                FROM T_Sample_Prep_Request SPR
			                    INNER JOIN T_Charge_Code CC
			                        ON SPR.Work_Package_Number = CC.Charge_Code
			                GROUP BY CC.Charge_Code 
			               ) StatsQ
			    ON Target.Charge_Code = StatsQ.Charge_Code
		WHERE IsNull(Target.Usage_SamplePrep, 0) <> SPR_Usage
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


		UPDATE T_Charge_Code
		SET Usage_RequestedRun = RR_Usage
		FROM T_Charge_Code Target
			    INNER JOIN ( SELECT CC.Charge_Code,
			                        COUNT(*) AS RR_Usage
			                FROM T_Charge_Code CC
			                    INNER JOIN T_Requested_Run RR
			                        ON CC.Charge_Code = RR.RDS_WorkPackage
			                GROUP BY CC.Charge_Code 
			               ) StatsQ
			    ON Target.Charge_Code = StatsQ.Charge_Code
		WHERE IsNull(Target.Usage_RequestedRun, 0) <> RR_Usage
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

	End
	Else
	Begin

		SELECT ISNULL(A.Charge_Code, B.Charge_Code) AS Charge_Code,
		       A.SPR_Usage,
		       B.RR_Usage
		FROM ( SELECT CC.Charge_Code,
		              COUNT(*) AS SPR_Usage
		       FROM T_Sample_Prep_Request SPR
		            INNER JOIN T_Charge_Code CC
		              ON SPR.Work_Package_Number = CC.Charge_Code
		       GROUP BY CC.Charge_Code 
		     ) A
		     FULL OUTER JOIN ( SELECT CC.Charge_Code,
		                              COUNT(*) AS RR_Usage
		                       FROM T_Charge_Code CC
		                            INNER JOIN T_Requested_Run RR
		                              ON CC.Charge_Code = RR.RDS_WorkPackage
		                       GROUP BY CC.Charge_Code 
		     ) B
		       ON A.Charge_Code = B.Charge_Code
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

	End
	       
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateChargeCodeUsage] TO [DDL_Viewer] AS [dbo]
GO
