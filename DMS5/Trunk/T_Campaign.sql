/****** Object:  Table [dbo].[T_Campaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Campaign](
	[Campaign_Num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CM_Project_Num] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[CM_Proj_Mgr_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_PI_PRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_comment] [varchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[CM_created] [datetime] NOT NULL,
	[Campaign_ID] [int] IDENTITY(2100,1) NOT NULL,
 CONSTRAINT [PK_T_Campaign] PRIMARY KEY NONCLUSTERED 
(
	[Campaign_ID] ASC
)WITH FILLFACTOR = 90 ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Campaign_Campaign_Num] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Campaign_Campaign_Num] ON [dbo].[T_Campaign] 
(
	[Campaign_Num] ASC
) ON [PRIMARY]
GO
GRANT SELECT ON [dbo].[T_Campaign] TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([Campaign_Num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([Campaign_Num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_Project_Num]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_Project_Num]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_Proj_Mgr_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_Proj_Mgr_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_PI_PRN]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_PI_PRN]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_comment]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_comment]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([CM_created]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([CM_created]) TO [Limited_Table_Write]
GO
GRANT SELECT ON [dbo].[T_Campaign] ([Campaign_ID]) TO [Limited_Table_Write]
GO
GRANT UPDATE ON [dbo].[T_Campaign] ([Campaign_ID]) TO [Limited_Table_Write]
GO
ALTER TABLE [dbo].[T_Campaign]  WITH CHECK ADD  CONSTRAINT [FK_T_Campaign_T_Users] FOREIGN KEY([CM_PI_PRN])
REFERENCES [T_Users] ([U_PRN])
GO
