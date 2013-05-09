/****** Object:  Table [dbo].[T_Internal_Standards] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Internal_Standards](
	[Internal_Std_Mix_ID] [int] IDENTITY(1,1) NOT NULL,
	[Internal_Std_Parent_Mix_ID] [int] NULL,
	[Name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [char](1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_T_Internal_Standards] PRIMARY KEY CLUSTERED 
(
	[Internal_Std_Mix_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Internal_Standards] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Internal_Standards] ON [dbo].[T_Internal_Standards] 
(
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
GRANT ALTER ON [dbo].[T_Internal_Standards] TO [Limited_Table_Write] AS [dbo]
GO
GRANT DELETE ON [dbo].[T_Internal_Standards] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Internal_Standards] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Internal_Standards] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Internal_Standards] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[T_Internal_Standards] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Internal_Standards]  WITH CHECK ADD  CONSTRAINT [FK_T_Internal_Standards_T_Internal_Std_Mixes] FOREIGN KEY([Internal_Std_Parent_Mix_ID])
REFERENCES [T_Internal_Std_Parent_Mixes] ([Parent_Mix_ID])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Internal_Standards] CHECK CONSTRAINT [FK_T_Internal_Standards_T_Internal_Std_Mixes]
GO
ALTER TABLE [dbo].[T_Internal_Standards]  WITH CHECK ADD  CONSTRAINT [CK_T_Internal_Standards] CHECK  (([Type]='All' OR ([Type]='Postdigest' OR [Type]='Predigest')))
GO
ALTER TABLE [dbo].[T_Internal_Standards] CHECK CONSTRAINT [CK_T_Internal_Standards]
GO
ALTER TABLE [dbo].[T_Internal_Standards]  WITH CHECK ADD  CONSTRAINT [CK_T_Internal_Standards_1] CHECK  (([Active]='A' OR [Active]='I'))
GO
ALTER TABLE [dbo].[T_Internal_Standards] CHECK CONSTRAINT [CK_T_Internal_Standards_1]
GO
ALTER TABLE [dbo].[T_Internal_Standards] ADD  CONSTRAINT [DF_T_Internal_Standards_Active]  DEFAULT ('A') FOR [Active]
GO
