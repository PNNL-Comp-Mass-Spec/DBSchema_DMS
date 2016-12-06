/****** Object:  StoredProcedure [dbo].[UpdateBionetHostStatus] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateBionetHostStatus
/****************************************************
**
**	Desc: 
**		Updates the Last_Online column in T_Bionet_Hosts
**		by looking for datasets associated with any instrument associated with the given host
**
**	Auth:	mem
**	Date:	12/02/2015 mem - Initial version
**    
*****************************************************/
(
	@infoOnly tinyint = 0
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	-----------------------------------------
	-- Validate the input parameters
	-----------------------------------------
	
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	-----------------------------------------
	-- Create some temporary tables
	-----------------------------------------
	
	CREATE TABLE #Tmp_Hosts (
		Host varchar(64) not null,		
		Instrument varchar(128) not null,
		MostRecentDataset smalldatetime not null
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_Hosts ON #Tmp_Hosts (Host, Instrument)
	
	-----------------------------------------
	-- Find the most recent dataset for each instrument associated with an entry in T_Bionet_Hosts
	-----------------------------------------

	INSERT INTO #Tmp_Hosts( Host,
	                        Instrument,
	                        MostRecentDataset )
	SELECT BionetHosts.Host,
	       Inst.IN_name,
	       MAX(DS.DS_created) AS MostRecentDataset
	FROM T_Storage_Path SPath
	     INNER JOIN T_Instrument_Name Inst
	       ON SPath.SP_path_ID = Inst.IN_source_path_ID
	     INNER JOIN T_Dataset DS
	       ON Inst.Instrument_ID = DS.DS_instrument_name_ID
	     CROSS JOIN T_Bionet_Hosts BionetHosts
	WHERE (SPath.SP_machine_name = BionetHosts.Host OR
	       SPath.SP_machine_name = BionetHosts.Host + '.bionet') AND
	      (SPath.SP_function LIKE '%inbox%') AND
	      (NOT (DS.DS_created IS NULL))
	GROUP BY BionetHosts.Host, Inst.IN_name
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
		
	If @infoOnly <> 0
	Begin
		-- Preview the new info
		--
		SELECT Target.Host,
		       Target.Last_Online,
		       Src.MostRecentDataset,
		       CASE WHEN Src.MostRecentDataset > IsNull(Target.Last_Online, '1/1/1970') 
		       THEN Src.MostRecentDataset
		       ELSE Null
		       END AS New_Last_Online
		FROM T_Bionet_Hosts Target
		     INNER JOIN ( SELECT Host,
		                         Max(MostRecentDataset) AS MostRecentDataset
		                  FROM #Tmp_Hosts
		                  GROUP BY Host ) Src
		       ON Target.Host = Src.Host
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
	End
	Else
	Begin
		-- Update Last_Online
		--		
		UPDATE T_Bionet_Hosts
		SET Last_Online = CASE WHEN Src.MostRecentDataset > IsNull(Target.Last_Online, '1/1/1970') 
		                  THEN Src.MostRecentDataset
		                  ELSE Target.Last_Online
		                  END
		FROM T_Bionet_Hosts Target
		     INNER JOIN ( SELECT Host,
		                         Max(MostRecentDataset) AS MostRecentDataset
		                  FROM #Tmp_Hosts
		                  GROUP BY Host ) Src
		       ON Target.Host = Src.Host
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
	End

	
Done:

	--
	Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateBionetHostStatus] TO [DDL_Viewer] AS [dbo]
GO
