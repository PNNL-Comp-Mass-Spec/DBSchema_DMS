/****** Object:  View [dbo].[V_CV_Union] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_CV_Union]
AS
	SELECT 'BTO' AS Source,
	       Term_PK,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID
	FROM T_CV_BTO
    UNION
	SELECT 'CL' AS Source,
	       Term_PK,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID
	FROM T_CV_CL
	UNION
	SELECT 'GO' AS Source,
	       Term_PK,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID
	FROM T_CV_GO
	UNION
	SELECT 'PSI-MI' AS Source,
	       Term_PK,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID
	FROM T_CV_MI
	UNION
	SELECT 'PSI-Mod' AS Source,
	       Term_PK,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID
	FROM T_CV_MOD
	UNION
	SELECT 'PSI-MS' AS Source,
	       Term_PK,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID
	FROM T_CV_MS
	UNION
	SELECT 'NEWT' AS Source,
	       Term_PK,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID
	FROM T_CV_NEWT
	UNION
	SELECT 'PRIDE' AS Source,
	       Term_PK,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID
	FROM T_CV_PRIDE
	UNION
	SELECT 'DOID' AS Source,
	       Term_PK,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID
	FROM T_CV_DOID


GO
GRANT VIEW DEFINITION ON [dbo].[V_CV_Union] TO [DDL_Viewer] AS [dbo]
GO
