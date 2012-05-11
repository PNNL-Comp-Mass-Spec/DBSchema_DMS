/****** Object:  Table [dbo].[T_Users_Access_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Users_Access_List](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Users_Access_List] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT DELETE ON [dbo].[T_Users_Access_List] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Users_Access_List] TO [Limited_Table_Write] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[T_Users_Access_List] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Users_Access_List] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Users_Access_List] TO [Limited_Table_Write] AS [dbo]
GO
