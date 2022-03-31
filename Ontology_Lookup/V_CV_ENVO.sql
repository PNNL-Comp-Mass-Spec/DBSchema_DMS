/****** Object:  View [dbo].[V_CV_ENVO] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_CV_ENVO]
AS
SELECT Entry_ID,
       Term_Name,
       identifier,
       Is_Leaf,
       Parent_term_name,
       Parent_term_ID,
       Grandparent_term_name,
       Grandparent_term_ID,
       Synonyms AS Synonyms
FROM T_CV_ENVO


GO
