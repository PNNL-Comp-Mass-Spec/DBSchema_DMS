/****** Object:  Synonym [dbo].[S_PostEmailAlert] ******/
CREATE SYNONYM [dbo].[S_PostEmailAlert] FOR [DMS5].[dbo].[PostEmailAlert]
GO
GRANT VIEW DEFINITION ON [dbo].[S_PostEmailAlert] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[S_PostEmailAlert] TO [DMS_SP_User] AS [dbo]
GO
