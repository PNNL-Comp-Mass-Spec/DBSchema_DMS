/****** Object:  StoredProcedure [dbo].[UpdateCachedBTONames] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateCachedBTONames
/****************************************************
**
**	Desc: Updates data in T_CV_BTO_Cached_Names
**
**	Auth:	mem
**	Date:	09/01/2017 mem - Initial version
**    
*****************************************************/
(
	@infoOnly tinyint = 1
)
As
	
	set nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0

	Set @infoOnly = IsNull(@infoOnly, 1)
	
	If @infoOnly = 0
	Begin
		---------------------------------------------------
		-- Update T_CV_BTO_Cached_Names
		---------------------------------------------------

		MERGE T_CV_BTO_Cached_Names AS t
		USING (SELECT identifier AS Identifier, Min(Term_Name) AS Term_Name
		       FROM T_CV_BTO
		       GROUP BY identifier) as s
		ON ( t.Identifier = s.Identifier AND t.Term_Name = s.Term_Name)
		WHEN NOT MATCHED BY TARGET THEN
			INSERT(Identifier, Term_Name)
			VALUES(s.Identifier, s.Term_Name)
		WHEN NOT MATCHED BY SOURCE THEN DELETE
		;
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
	End
	Else
	Begin
		---------------------------------------------------
		-- Preview rows to add or delete
		---------------------------------------------------
		
		SELECT 'Delete from cache' AS [Action],
		       target.*
		FROM T_CV_BTO_Cached_Names target
		     LEFT OUTER JOIN ( SELECT identifier AS Identifier,
		                              MIN(Term_Name) AS Term_Name
		                       FROM T_CV_BTO
		                       GROUP BY identifier ) Source
		       ON target.Identifier = Source.Identifier AND
		          target.Term_Name = Source.Term_Name
		WHERE (Source.Identifier IS NULL)
		UNION
		SELECT 'Add to cache' AS [Action],
		       Source.*
		FROM T_CV_BTO_Cached_Names target
		     RIGHT OUTER JOIN ( SELECT identifier AS Identifier,
		                               MIN(Term_Name) AS Term_Name
		                        FROM T_CV_BTO
		                        GROUP BY identifier ) Source
		       ON target.Identifier = Source.Identifier AND
		          target.Term_Name = Source.Term_Name
		WHERE (target.Identifier IS NULL)

	End
		
Done:
	return 0


GO
