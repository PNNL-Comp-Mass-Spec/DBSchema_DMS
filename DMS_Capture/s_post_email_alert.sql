/****** Object:  Synonym [dbo].[s_post_email_alert] ******/
CREATE SYNONYM [dbo].[s_post_email_alert] FOR [DMS5].[dbo].[post_email_alert]
GO
GRANT VIEW DEFINITION ON [dbo].[s_post_email_alert] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[s_post_email_alert] TO [DMS_SP_User] AS [dbo]
GO
