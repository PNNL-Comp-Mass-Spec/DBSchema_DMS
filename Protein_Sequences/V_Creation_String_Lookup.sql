/****** Object:  View [dbo].[V_Creation_String_Lookup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Creation_String_Lookup
AS
SELECT     CASE WHEN dbo.T_Creation_Option_Values.Description IS NULL THEN (dbo.T_Creation_Option_Values.Display) 
                      ELSE dbo.T_Creation_Option_Values.Display + ' - ' + dbo.T_Creation_Option_Values.Description END AS Display_Value, 
                      dbo.T_Creation_Option_Keywords.Keyword + '=' + dbo.T_Creation_Option_Values.Value_String AS String_Element, 
                      dbo.T_Creation_Option_Keywords.Keyword, dbo.T_Creation_Option_Values.Value_String
FROM         dbo.T_Creation_Option_Keywords INNER JOIN
                      dbo.T_Creation_Option_Values ON dbo.T_Creation_Option_Keywords.Keyword_ID = dbo.T_Creation_Option_Values.Keyword_ID

GO
