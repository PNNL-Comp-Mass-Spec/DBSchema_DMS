/****** Object:  StoredProcedure [dbo].[UpdateExperimentUsage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateExperimentUsage
/****************************************************
**
**	Desc:	Updates Last_Used in T_Experiments
**			That column is used by LcmsNetDMSTools when retrieving recent experiments
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	07/31/2015 mem - Initial version
**    
*****************************************************/
(
	@infoOnly tinyint = 0,
	@message varchar(512) = '' output
)
As
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	set @infoOnly = IsNull(@infoOnly, 1)
	set @message = ''
	
	If @infoOnly <> 0
	Begin
		---------------------------------------------------
		-- Preview the updates
		---------------------------------------------------
		--
		SELECT E.Exp_ID,
		       E.Last_Used,
		       LookupRR.MostRecentUse AS Last_Used_ReqRun,
		       LookupDS.MostRecentUse AS Last_Used_Dataset
		FROM T_Experiments E
		     LEFT OUTER JOIN ( SELECT E.Exp_ID,
		                              MAX(CAST(RR.RDS_created AS date)) AS MostRecentUse
		                       FROM T_Experiments E
		                            INNER JOIN T_Requested_Run RR
		                              ON E.Exp_ID = RR.Exp_ID
		                       GROUP BY E.Exp_ID 
		                     ) LookupRR
		       ON E.Exp_ID = LookupRR.Exp_ID
		     LEFT OUTER JOIN ( SELECT E.Exp_ID,
		                              MAX(CAST(DS.DS_created AS date)) AS MostRecentUse
		                       FROM T_Experiments E
		                            INNER JOIN T_Dataset DS
		                              ON E.Exp_ID = DS.Exp_ID
		                       GROUP BY E.Exp_ID 
		                     ) LookupDS
		       ON E.Exp_ID = LookupDS.Exp_ID
		WHERE LookupRR.MostRecentUse > E.Last_Used OR
		      LookupDS.MostRecentUse > E.Last_Used
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount


	End
	Else
	Begin
	
		---------------------------------------------------
		-- Update based on the most recent Requested Run 
		---------------------------------------------------
		--
		UPDATE T_Experiments
		SET Last_Used = MostRecentUse
		FROM T_Experiments E
		     INNER JOIN ( SELECT E.Exp_ID,
		                         MAX(CAST(RR.RDS_created AS date)) AS MostRecentUse
		                  FROM T_Experiments E
		                       INNER JOIN T_Requested_Run RR
		                         ON E.Exp_ID = RR.Exp_ID
		                  GROUP BY E.Exp_ID 
		                ) LookupQ
		       ON E.Exp_ID = LookupQ.Exp_ID
		WHERE LookupQ.MostRecentUse > E.Last_Used
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		---------------------------------------------------
		-- Update based on the most recent Dataset
		---------------------------------------------------
		--
		UPDATE T_Experiments
		SET Last_Used = MostRecentUse
		FROM T_Experiments E
		     INNER JOIN ( SELECT E.Exp_ID,
		                         MAX(CAST(DS.DS_created AS date)) AS MostRecentUse
		                  FROM T_Experiments E
		                       INNER JOIN T_Dataset DS
		                         ON E.Exp_ID = DS.Exp_ID
		                  GROUP BY E.Exp_ID 
		                  
		                  ) LookupQ
		       ON E.Exp_ID = LookupQ.Exp_ID
		WHERE LookupQ.MostRecentUse > E.Last_Used
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Print 'Updated Last_Used date for ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowcount, ' experiment',  ' experiments')
	End

	---------------------------------------------------
	-- Done
	---------------------------------------------------
	--
	
	return 0

GO
