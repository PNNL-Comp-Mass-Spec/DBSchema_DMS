/****** Object:  Table [dbo].[T_User_Status] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_User_Status](
	[User_Status] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Status_Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_User_Status] PRIMARY KEY CLUSTERED 
(
	[User_Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_User_Status] TO [DDL_Viewer] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_User_Status] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_User_Status] TO [Limited_Table_Write] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_User_Status] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_User_Status] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_User_Status] TO [Limited_Table_Write] AS [dbo]
GO
