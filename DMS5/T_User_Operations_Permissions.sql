/****** Object:  Table [dbo].[T_User_Operations_Permissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_User_Operations_Permissions](
	[U_ID] [int] NOT NULL,
	[Op_ID] [int] NOT NULL,
 CONSTRAINT [PK_T_User_Operations_Permissions] PRIMARY KEY CLUSTERED 
(
	[U_ID] ASC,
	[Op_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_User_Operations_Permissions] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_User_Operations_Permissions]  WITH CHECK ADD  CONSTRAINT [FK_T_User_Operations_Permissions_T_User_Operations] FOREIGN KEY([Op_ID])
REFERENCES [dbo].[T_User_Operations] ([ID])
GO
ALTER TABLE [dbo].[T_User_Operations_Permissions] CHECK CONSTRAINT [FK_T_User_Operations_Permissions_T_User_Operations]
GO
ALTER TABLE [dbo].[T_User_Operations_Permissions]  WITH CHECK ADD  CONSTRAINT [FK_T_User_Operations_Permissions_T_Users] FOREIGN KEY([U_ID])
REFERENCES [dbo].[T_Users] ([ID])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[T_User_Operations_Permissions] CHECK CONSTRAINT [FK_T_User_Operations_Permissions_T_Users]
GO
