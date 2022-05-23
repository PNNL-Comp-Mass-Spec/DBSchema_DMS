/****** Object:  View [dbo].[V_Sample_Submission_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Sample_Submission_Entry
AS
SELECT SS.id,
       C.Campaign_Num AS campaign,
       U.U_PRN AS received_by,
       SS.description,
       SS.Container_List AS container_list,
       '' AS new_container_comment
FROM T_Sample_Submission SS
     INNER JOIN T_Campaign C
       ON SS.Campaign_ID = C.Campaign_ID
     INNER JOIN T_Users U
       ON SS.Received_By_User_ID = U.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Submission_Entry] TO [DDL_Viewer] AS [dbo]
GO
